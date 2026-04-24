package com.java.game.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.java.dto.MemberRankReward;
import com.java.game.entity.GameTurnLog;
import com.java.service.MemberService;

/**
 * 데뷔 엔딩 등급 계산 서비스
 * 스탯·케미로 기본 점수를 만든 뒤, <strong>진행 턴</strong>에 따라 가중(초반 단축 데뷔는 낮게, 후반은 풀에 가깝게)하여 0~1000 및 S~D 판정
 */
@Service
public class EndingService {

	/** 스탯만 합산했을 때의 이론 상한 */
	public static final int STAT_SUM_MAX = 2000;
	/** 결과·랭킹에 쓰는 만점 */
	public static final int DISPLAY_SCORE_MAX = 1000;
	public static final int DEBUT_GRADE_S_MIN = 800;
	public static final int DEBUT_GRADE_A_MIN = 700;
	public static final int DEBUT_GRADE_B_MIN = 600;
	public static final int DEBUT_GRADE_C_MIN = 500;
	public static final int DEBUT_GRADE_D_MIN = 400;
	/** 최종 데뷔 평가에 해당하는 턴 인덱스(게임 내 일수·페이즈와 동기) */
	public static final int ENDING_MAX_TURN_INDEX = 169;
	/**
	 * 진행도 0일 때(초반 단축 데뷔 등) 스탯점수에 곱하는 최소 비율. 턴이 {@value #ENDING_MAX_TURN_INDEX}에 가까울수록 1.0에 수렴.
	 */
	private static final double PROGRESS_SCORE_MIN_FACTOR = 0.14;

	/**
	 * 엔딩 화면용: 이번 플레이 최종 점수(만점 1000)가 어떻게 계산됐는지 단계별 수치.
	 */
	public record DebutScoreBreakdown(
			/** 멤버 능력치 원점(각 0~20) 전체 합, 이론상 최대 400 */
			int statSum,
			/** 능력치만 만점 1000으로 환산(케미·진행 보정 전) */
			int abilityOnlyDisplayScore,
			/** 케미 총 보너스 퍼센트 */
			int chemBonusPercent,
			/** 케미 반영 후 점수(진행 보정 전) */
			int rawDisplayAfterChem,
			/** 점수 산출에 쓴 턴 인덱스 */
			int effectiveTurnIndex,
			/** 진행 보정 배율(약 0.14~1.0) */
			double progressFactor,
			/** 최종 표시 점수 */
			int finalDisplayScore) {
	}

	public static DebutScoreBreakdown debutScoreBreakdown(int statSum, ChemistryResult chemistry, int effectiveTurn) {
		int bonusPct = chemistry == null ? 0 : Math.max(0, chemistry.getTotalBonus());
		double abilityScaled = statSum * (DISPLAY_SCORE_MAX / (double) STAT_SUM_MAX);
		int abilityOnly = (int) Math.round(abilityScaled);
		abilityOnly = Math.min(DISPLAY_SCORE_MAX, Math.max(0, abilityOnly));
		int raw = computeDebutDisplayScore(statSum, chemistry);
		double factor = progressFactorForTurn(effectiveTurn);
		int total = applyProgressToDisplayScore(raw, effectiveTurn);
		return new DebutScoreBreakdown(statSum, abilityOnly, bonusPct, raw, effectiveTurn, factor, total);
	}

	private final MemberService memberService;

	public EndingService(MemberService memberService) {
		this.memberService = memberService;
	}

	/**
	 * 스탯 합과 {@link ChemistryResult#getTotalBonus()} 퍼센트로 0~{@value #DISPLAY_SCORE_MAX} 최종 점수를 계산한다.
	 */
	public static int computeDebutDisplayScore(int statTotal, ChemistryResult chemistry) {
		int bonusPct = chemistry == null ? 0 : Math.max(0, chemistry.getTotalBonus());
		double scaled = statTotal * (DISPLAY_SCORE_MAX / (double) STAT_SUM_MAX) * (100.0 + bonusPct) / 100.0;
		int score = (int) Math.round(scaled);
		return Math.min(DISPLAY_SCORE_MAX, Math.max(0, score));
	}

	/**
	 * 스탯·케미로 산출한 점수에 <strong>진행 턴</strong> 비율을 반영한다.
	 * 초반에 데뷔만 눌러도 S가 나오지 않도록 하고, 후반(턴↑)일수록 풀 점수에 가깝게 맞춘다.
	 *
	 * @param effectiveTurn {@link GameService#resolveEffectiveTurnForScoring(Long, String)} 등으로 계산된 값(1~169 권장)
	 */
	public static int applyProgressToDisplayScore(int rawScore, int effectiveTurn) {
		double factor = progressFactorForTurn(effectiveTurn);
		int out = (int) Math.round(rawScore * factor);
		return Math.min(DISPLAY_SCORE_MAX, Math.max(0, out));
	}

	/**
	 * 턴 1 → 약 0.14, 턴 {@value #ENDING_MAX_TURN_INDEX} → 1.0
	 */
	public static double progressFactorForTurn(int effectiveTurn) {
		int t = Math.max(1, Math.min(ENDING_MAX_TURN_INDEX, effectiveTurn));
		double progress = (t - 1) / (double) (ENDING_MAX_TURN_INDEX - 1);
		return PROGRESS_SCORE_MIN_FACTOR + (1.0 - PROGRESS_SCORE_MIN_FACTOR) * progress;
	}

	/**
	 * @param runPhase {@link com.java.game.service.GameService#getRunResult(Long)} 와 동일한 phase (DB 동기화 힌트)
	 * @param effectiveTurn 엔딩 직전 진행 턴(페이즈·턴 로그 기준)
	 */
	public EndingResult calculate(Long runId, String groupType, List<RosterItem> roster, ChemistryResult chemistry,
			List<GameTurnLog> logs, String runPhase, int effectiveTurn) {
		int statSum = roster.stream().mapToInt(r ->
				r.vocal() + r.dance() + r.star() + r.mental() + r.teamwork()
		).sum();
		int raw = computeDebutDisplayScore(statSum, chemistry);
		int total = applyProgressToDisplayScore(raw, effectiveTurn);

		String grade, label, desc, color;

		if (total >= DEBUT_GRADE_S_MIN) {
			grade = "S";
			label = "월드클래스 데뷔";
			desc = "압도적인 실력으로 데뷔 즉시 전 세계를 강타했습니다. 역사에 남을 그룹이 탄생했습니다.";
			color = "#fbbf24";
		} else if (total >= DEBUT_GRADE_A_MIN) {
			grade = "A";
			label = "성공적인 데뷔";
			desc = "뛰어난 기량으로 데뷔 무대를 완벽하게 소화했습니다. 차세대 대표 그룹으로 주목받고 있습니다.";
			color = "#e9b0c4";
		} else if (total >= DEBUT_GRADE_B_MIN) {
			grade = "B";
			label = "기대되는 데뷔";
			desc = "안정적인 실력으로 무대를 마쳤습니다. 꾸준한 성장으로 더 큰 무대를 노려볼 수 있습니다.";
			color = "#cbbad8";
		} else if (total >= DEBUT_GRADE_C_MIN) {
			grade = "C";
			label = "평범한 데뷔";
			desc = "아직 부족한 부분이 있지만 가능성은 충분합니다. 더 많은 훈련이 필요합니다.";
			color = "#baccd8";
		} else {
			grade = "D";
			label = "아쉬운 데뷔";
			desc = "많은 훈련이 필요합니다. 포기하지 말고 다시 도전해보세요!";
			color = "rgba(255,255,255,0.4)";
		}

		int specialSuccess = 0;
		if (logs != null) {
			specialSuccess = (int) logs.stream()
					.filter(l -> "SPECIAL".equalsIgnoreCase(l.getChoiceKey()))
					.filter(l -> l.getDelta() > 0)
					.count();
		}
		int starTotal = roster.stream().mapToInt(RosterItem::star).sum();
		double starAvg = roster.isEmpty() ? 0 : (starTotal / (double) roster.size());
		String chemGrade = (chemistry == null ? "D" : chemistry.getChemGrade());

		String route = "RESTART";
		String title = "재도전";
		String reason = "데이터 기반으로 다음 플레이에서 개선점을 찾을 수 있습니다.";

		if (("S".equals(grade) || "A".equals(grade)) && ("S".equals(chemGrade) || "A".equals(chemGrade)) && specialSuccess >= 6) {
			route = "WORLD_TOUR";
			title = "월드 투어 확정";
			reason = "높은 총점 + 강한 케미 + 스페셜 성공이 결합되어 폭발적인 데뷔를 만들었습니다.";
		} else if (("A".equals(grade) || "B".equals(grade)) && starAvg >= 15 && specialSuccess >= 4) {
			route = "VIRAL_HIT";
			title = "바이럴 히트";
			reason = "스타 평균과 스페셜 성공이 ‘한 방 장면’을 만들며 대중 반응이 터졌습니다.";
		} else if ("C".equals(grade) || "D".equals(grade)) {
			route = "FAIL";
			title = "탈락 위기";
			reason = "완성도와 안정성이 부족해 최종 평가에서 밀렸습니다. 훈련 루틴을 재정비하세요.";
		}

		MemberRankReward rankReward = memberService.applyFanRewardForFinishedRun(runId, runPhase);
		return new EndingResult(runId, groupType, roster, total, grade, label, desc, color, route, title, reason,
				rankReward);
	}
}
