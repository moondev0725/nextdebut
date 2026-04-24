package com.java.service;

import java.util.Objects;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.java.dto.MemberRankReward;
import com.java.entity.Member;
import com.java.entity.MemberRank;
import com.java.game.entity.GameRun;
import com.java.game.repository.GameRunMemberRepository;
import com.java.game.repository.GameRunRepository;
import com.java.repository.MemberRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class MemberService {

	private final MemberRepository memberRepository;
	private final GameRunRepository gameRunRepository;
	private final GameRunMemberRepository gameRunMemberRepository;
	private final TraineeGroupService traineeGroupService;

	@PersistenceContext
	private EntityManager entityManager;

	public MemberService(MemberRepository memberRepository, GameRunRepository gameRunRepository,
			GameRunMemberRepository gameRunMemberRepository, TraineeGroupService traineeGroupService) {
		this.memberRepository = memberRepository;
		this.gameRunRepository = gameRunRepository;
		this.gameRunMemberRepository = gameRunMemberRepository;
		this.traineeGroupService = traineeGroupService;
	}

	/**
	 * 획득 팬 수 기준으로 rankExp를 누적하고, 누적 경험치에 맞춰 등급을 갱신한다.
	 * rankExp += floor(fan / 10)
	 */
	public void addFan(Member member, int fan) {
		Objects.requireNonNull(member, "member");
		int gain = MemberRank.fanToRankExpDelta(fan);
		member.setRankExp(member.getRankExp() + gain);
		member.setMemberRankCode(MemberRank.getRankByExp(member.getRankExp()).name());
	}

	/**
	 * FINISHED 플레이 1회당, 해당 런의 총 팬 수로 계정 경험치를 반영한다. (중복 방지)
	 *
	 * @param phaseHint {@link com.java.game.service.GameService#getRunResult(Long)} 에서 읽은 phase (동기화 확인용)
	 */
	@Transactional
	public MemberRankReward applyFanRewardForFinishedRun(Long runId, String phaseHint) {
		if (runId == null) {
			return MemberRankReward.notFinishedRun();
		}
		GameRun run = gameRunRepository.findById(runId).orElse(null);
		if (run == null) {
			return MemberRankReward.notFinishedRun();
		}
		String ph = trimPhase(run.getPhase());
		String hint = trimPhase(phaseHint);
		if (!"FINISHED".equals(ph) && "FINISHED".equals(hint)) {
			entityManager.refresh(run);
			ph = trimPhase(run.getPhase());
		}
		int totalFans = run.getTotalFans();
		if (!"FINISHED".equals(ph)) {
			return MemberRankReward.phasePending(totalFans);
		}
		Long mno = run.getPlayerMno();
		if (mno == null) {
			return MemberRankReward.notLoggedIn(totalFans);
		}
		Member member = memberRepository.findById(mno).orElse(null);
		if (member == null) {
			return MemberRankReward.notLoggedIn(totalFans);
		}
		applyGroupUnlockByRunAverage(member, runId);

		syncRankCodeFromExp(member);

		if (run.isFanRewardApplied()) {
			MemberRank current = MemberRank.fromCode(member.getMemberRankCode());
			return new MemberRankReward(
					true,
					totalFans,
					0,
					member.getRankExp(),
					member.getRankExp(),
					current.name(),
					current.displayName(),
					true,
					null);
		}

		int before = member.getRankExp();
		addFan(member, totalFans);
		int after = member.getRankExp();

		run.setFanRewardApplied(true);
		gameRunRepository.save(run);
		memberRepository.save(member);

		MemberRank rank = MemberRank.fromCode(member.getMemberRankCode());
		return new MemberRankReward(
				true,
				totalFans,
				after - before,
				before,
				after,
				rank.name(),
				rank.displayName(),
				false,
				null);
	}

	private static String trimPhase(String phase) {
		return phase == null ? null : phase.trim();
	}

	private void syncRankCodeFromExp(Member member) {
		String expected = MemberRank.getRankByExp(member.getRankExp()).name();
		if (!expected.equals(member.getMemberRankCode())) {
			member.setMemberRankCode(expected);
		}
	}

	private void applyGroupUnlockByRunAverage(Member member, Long runId) {
		if (member == null || runId == null) {
			return;
		}
		var roster = gameRunMemberRepository.findRoster(runId);
		if (roster == null || roster.isEmpty()) {
			return;
		}
		double avg = roster.stream()
				.map(m -> m.getTrainee())
				.filter(java.util.Objects::nonNull)
				.mapToInt(t -> t.getVocal() + t.getDance() + t.getStar() + t.getMental() + t.getTeamwork())
				.average()
				.orElse(0.0);
		boolean hasPerfectMember = roster.stream()
				.map(m -> m.getTrainee())
				.filter(java.util.Objects::nonNull)
				.anyMatch(t -> t.getVocal() >= 100
						&& t.getDance() >= 100
						&& t.getStar() >= 100
						&& t.getMental() >= 100
						&& t.getTeamwork() >= 100);
		int beforeMask = member.getGroupUnlockMask();
		int afterMask = traineeGroupService.applyUnlockByProgress(beforeMask, avg, hasPerfectMember);
		if (afterMask != beforeMask) {
			member.setGroupUnlockMask(afterMask);
		}
	}
}
