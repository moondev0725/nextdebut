package com.java.game.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import org.springframework.stereotype.Component;

import com.java.game.entity.ChatKeywordRule;
import com.java.game.repository.ChatKeywordRuleRepository;

/**
 * 유저 채팅 텍스트를 현재 턴의 선택지 키(A/B/C/D/SPECIAL)로 매핑한다.
 * DB statTarget·키워드·(간단) 선택지 문구 겹침을 사용한다.
 */
@Component
public class GameChatKeywordResolver {

	private final ChatKeywordRuleRepository chatKeywordRuleRepository;

	public GameChatKeywordResolver(ChatKeywordRuleRepository chatKeywordRuleRepository) {
		this.chatKeywordRuleRepository = chatKeywordRuleRepository;
	}

	private static final String[] VOCAL_KW = {
			"보컬", "발성", "노래", "라이브", "음정", "호흡", "가성", "파트", "후렴", "보이스", "보창", "싱잉", "vocal", "sing"
	};
	private static final String[] DANCE_KW = {
			"댄스", "안무", "춤", "동선", "퍼포", "제스처", "포인트", "댄브", "dance", "킥", "스텝", "칼군무", "군무", "안무합"
	};
	private static final String[] TEAM_KW = {
			"팀워크", "팀웍", "협업", "화합", "역할", "소통", "합의", "분배", "조율", "합", "호흡", "케미", "팀플", "유닛합"
	};
	private static final String[] MENTAL_KW = {
			"쉬", "쉬어", "휴식", "쉼", "포기", "그만", "멘탈", "컨디션", "회복", "스트레스", "무리", "번아웃",
			"잠", "쉬자", "맑게", "정리", "쉴래", "안정", "진정", "긴장", "부담", "집중력", "멘붕"
	};
	private static final String[] STAR_KW = {
			"스타", "카메라", "미디어", "노출", "존재감", "임팩트", "화제", "클립", "star", "한 컷", "비주얼", "센터", "직캠", "팬어필"
	};
	private static final String[] RISK_KW = {
			"승부수", "도전", "리스크", "올인", "한계", "파격", "과감", "승부", "무리해", "승부걸"
	};
	private static final String[] TRAIN_KW = {
			"훈련", "연습", "열심히", "드릴", "반복", "달리자", "집중", "포커스", "focus", "화이팅", "힘내", "잘해", "가자", "파이팅"
	};
	private static final String[] REST_KW = {
			"휴식", "쉼", "쉬어", "회복", "쉬자", "맑게", "포기", "그만", "번아웃", "스트레스", "컨디션"
	};
	private static final String[] HARD_TRAIN_KW = {
			"강훈련", "몰아", "한계", "올인", "밀어붙", "승부수", "과부하", "극한", "빡세게", "전력", "무리해", "과감"
	};

	private static final List<String> KEY_ORDER = List.of("A", "B", "C", "D", "SPECIAL");

	/**
	 * {@link #resolve}와 동일한 키 + 키워드/룰 매칭이 명확한지 여부.
	 * {@code strongKeywordMatch}가 true이면 Gemini 선택지 해석을 생략해도 된다(응답 지연 절감).
	 */
	public record ChoiceResolution(String key, boolean strongKeywordMatch) {
	}

	/**
	 * UI·대사 맥락용 훈련 강도 분류 (스탯 수치는 {@link #resolve} 결과로만 결정).
	 */
	public String categorizeTrainingStyle(String rawUserText) {
		String t = rawUserText == null ? "" : rawUserText.trim();
		if (t.isEmpty()) {
			return "조율";
		}
		String norm = t.toLowerCase(Locale.ROOT);
		int rest = countHits(norm, REST_KW);
		int hard = countHits(norm, HARD_TRAIN_KW);
		int train = countHits(norm, TRAIN_KW);
		int max = Math.max(Math.max(rest, hard), train);
		if (max == 0) {
			return "조율";
		}
		if (hard == max) {
			return "강훈련";
		}
		if (rest == max) {
			return "휴식";
		}
		return "훈련";
	}

	/**
	 * 빈 입력만 {@code NONE}. 그 외에는 점수가 없어도 첫 유효 선택지로 폴백해 턴이 스킵되지 않게 한다.
	 */
	public String resolve(String rawUserText, List<SceneResult.ChoiceItem> choices) {
		return resolveDetailed(rawUserText, choices).key();
	}

	/**
	 * @see #resolve
	 */
	public ChoiceResolution resolveDetailed(String rawUserText, List<SceneResult.ChoiceItem> choices) {
		if (choices == null || choices.isEmpty()) {
			return new ChoiceResolution("NONE", false);
		}
		String t = rawUserText == null ? "" : rawUserText.trim();
		if (t.isEmpty()) {
			return new ChoiceResolution("NONE", false);
		}
		String norm = t.toLowerCase(Locale.ROOT);
		String directKey = resolveDirectStatCommandKey(norm, choices);
		if (directKey != null) {
			return new ChoiceResolution(directKey, true);
		}
		if (isMeaninglessUtterance(norm)) {
			return new ChoiceResolution(randomNoneOrFirstChoice(choices), false);
		}

		// 1) DB 룰 우선 적용 (운영/밸런싱 편의). 매칭되면 곧장 choiceKey 반환.
		try {
			List<ChatKeywordRule> rules = chatKeywordRuleRepository.findByActiveTrueOrderByPriorityDescIdAsc();
			if (rules != null && !rules.isEmpty()) {
				for (ChatKeywordRule r : rules) {
					if (r == null) continue;
					String kw = r.getKeyword();
					String key = normalizeKey(r.getChoiceKey());
					if (kw == null || kw.isBlank() || key == null) continue;
					if (norm.contains(kw.toLowerCase(Locale.ROOT))) {
						// 현재 턴에 존재하는 선택지만 허용
						for (SceneResult.ChoiceItem ch : choices) {
							if (key.equals(normalizeKey(ch.getKey()))) {
								return new ChoiceResolution(key, true);
							}
						}
					}
				}
			}
		} catch (Exception ignored) {
		}

		Map<String, Integer> scores = new LinkedHashMap<>();
		for (SceneResult.ChoiceItem ch : choices) {
			String k = normalizeKey(ch.getKey());
			if (k == null) {
				continue;
			}
			int s = scoreStatTarget(ch.getStatTarget(), norm);
			if ("SPECIAL".equals(k)) {
				s += countHits(norm, RISK_KW) * 5;
			}
			s += overlapScore(norm, ch.getText());
			Integer prev = scores.get(k);
			scores.put(k, (prev == null ? 0 : prev) + s);
		}

		if (countHits(norm, TRAIN_KW) > 0) {
			bumpIfPresent(scores, "A", 2);
			bumpIfPresent(scores, "B", 2);
			bumpIfPresent(scores, "C", 2);
		}

		String best = firstAvailableKey(choices, "A");
		int bestScore = -1;
		for (String k : KEY_ORDER) {
			if (!scores.containsKey(k)) {
				continue;
			}
			int sc = scores.get(k);
			if (sc > bestScore) {
				bestScore = sc;
				best = k;
			}
		}
		if (bestScore <= 0) {
			return new ChoiceResolution(randomNoneOrFirstChoice(choices), false);
		}
		return new ChoiceResolution(best, true);
	}

	private static String resolveDirectStatCommandKey(String norm, List<SceneResult.ChoiceItem> choices) {
		if (containsAny(norm, "none", "없음", "무응답", "패스", "스킵", "아무거나", "모르겠")) {
			return "NONE";
		}
		if (containsAny(norm, "보컬", "vocal") && isChoicePresent("A", choices)) {
			return "A";
		}
		if (containsAny(norm, "댄스", "dance") && isChoicePresent("B", choices)) {
			return "B";
		}
		if (containsAny(norm, "팀웍", "팀워크", "teamwork", "team") && isChoicePresent("C", choices)) {
			return "C";
		}
		if (containsAny(norm, "멘탈", "mental") && isChoicePresent("D", choices)) {
			return "D";
		}
		if (containsAny(norm, "스타성", "스타", "star") && isChoicePresent("SPECIAL", choices)) {
			return "SPECIAL";
		}
		return null;
	}

	private static boolean isMeaninglessUtterance(String norm) {
		if (norm == null || norm.isBlank()) {
			return true;
		}
		String compact = norm.replaceAll("\\s+", "");
		if (compact.length() <= 2) {
			return true;
		}
		if (compact.matches("^[ㄱ-ㅎㅏ-ㅣ]+$")) {
			return true;
		}
		if (compact.matches("^(.)\\1{2,}$")) {
			return true;
		}
		return compact.matches("^[a-z0-9]+$") && compact.length() <= 4;
	}

	private static String randomNoneOrFirstChoice(List<SceneResult.ChoiceItem> choices) {
		if (ThreadLocalRandom.current().nextBoolean()) {
			return "NONE";
		}
		return firstAvailableKey(choices, "A");
	}

	/**
	 * 문장에 명시적으로 드러난 스탯 의도를 키(A/B/C/D/SPECIAL)로 추정한다.
	 * ML 결과와 충돌할 때 가드레일 용도로만 사용한다.
	 */
	public String resolveExplicitIntentKey(String rawUserText, List<SceneResult.ChoiceItem> choices) {
		if (choices == null || choices.isEmpty()) {
			return null;
		}
		String t = rawUserText == null ? "" : rawUserText.trim();
		if (t.isEmpty()) {
			return null;
		}
		String norm = t.toLowerCase(Locale.ROOT);
		// 유저가 스탯명을 직접 말한 경우는 가장 강한 의도로 본다.
		if (containsAny(norm, "보컬", "vocal", "싱잉") && isChoicePresent("A", choices)) return "A";
		if (containsAny(norm, "댄스", "dance", "안무", "춤") && isChoicePresent("B", choices)) return "B";
		if (containsAny(norm, "팀워크", "팀웍", "협업", "teamwork", "team") && isChoicePresent("C", choices)) return "C";
		if (containsAny(norm, "멘탈", "회복", "휴식", "컨디션", "mental") && isChoicePresent("D", choices)) return "D";
		if (containsAny(norm, "스타", "스타성", "카메라", "비주얼", "star") && isChoicePresent("SPECIAL", choices)) return "SPECIAL";

		Map<String, Integer> intentScores = new LinkedHashMap<>();
		intentScores.put("A", countHits(norm, VOCAL_KW));
		intentScores.put("B", countHits(norm, DANCE_KW));
		intentScores.put("C", countHits(norm, TEAM_KW));
		intentScores.put("D", countHits(norm, MENTAL_KW));
		intentScores.put("SPECIAL", countHits(norm, STAR_KW));
		int max = 0;
		int second = 0;
		String bestKey = null;
		for (Map.Entry<String, Integer> e : intentScores.entrySet()) {
			int score = e.getValue() == null ? 0 : e.getValue();
			if (score > max) {
				second = max;
				max = score;
				bestKey = e.getKey();
			} else if (score > second) {
				second = score;
			}
		}
		if (max <= 0) {
			return null;
		}
		// 너무 약한 신호(단일 키워드 1회)는 ML을 막지 않도록 한다.
		if (max < 2) {
			return null;
		}
		// 동점/근접 점수 문장은 의도가 모호하다고 보고 강제 보정을 하지 않는다.
		if (max - second < 2) {
			return null;
		}
		if (bestKey != null && isChoicePresent(bestKey, choices)) {
			return bestKey;
		}
		return null;
	}

	private static boolean containsAny(String text, String... keywords) {
		if (text == null || text.isBlank() || keywords == null || keywords.length == 0) {
			return false;
		}
		for (String kw : keywords) {
			if (kw != null && !kw.isBlank() && text.contains(kw.toLowerCase(Locale.ROOT))) {
				return true;
			}
		}
		return false;
	}

	private static void bumpIfPresent(Map<String, Integer> scores, String key, int d) {
		if (scores.containsKey(key)) {
			Integer prev = scores.get(key);
			scores.put(key, (prev == null ? 0 : prev) + d);
		}
	}

	private static String firstAvailableKey(List<SceneResult.ChoiceItem> choices, String fallback) {
		for (String k : KEY_ORDER) {
			for (SceneResult.ChoiceItem ch : choices) {
				String nk = normalizeKey(ch.getKey());
				if (k.equals(nk)) {
					return k;
				}
			}
		}
		return fallback;
	}

	private static boolean isChoicePresent(String key, List<SceneResult.ChoiceItem> choices) {
		for (SceneResult.ChoiceItem ch : choices) {
			String nk = normalizeKey(ch == null ? null : ch.getKey());
			if (key.equals(nk)) {
				return true;
			}
		}
		return false;
	}

	private static String normalizeKey(String key) {
		if (key == null) {
			return null;
		}
		String k = key.trim().toUpperCase(Locale.ROOT);
		if ("A".equals(k) || "B".equals(k) || "C".equals(k) || "D".equals(k) || "SPECIAL".equals(k)) {
			return k;
		}
		return null;
	}

	private static int scoreStatTarget(String statTarget, String norm) {
		if (statTarget == null) {
			return 0;
		}
		return switch (statTarget.trim().toUpperCase(Locale.ROOT)) {
			case "VOCAL" -> countHits(norm, VOCAL_KW) * 4;
			case "DANCE" -> countHits(norm, DANCE_KW) * 4;
			case "TEAMWORK" -> countHits(norm, TEAM_KW) * 4;
			case "MENTAL" -> countHits(norm, MENTAL_KW) * 4;
			case "STAR" -> countHits(norm, STAR_KW) * 4;
			default -> 0;
		};
	}

	private static int countHits(String norm, String[] kws) {
		int n = 0;
		for (String kw : kws) {
			if (kw != null && !kw.isBlank() && norm.contains(kw.toLowerCase(Locale.ROOT))) {
				n++;
			}
		}
		return n;
	}

	private static int overlapScore(String norm, String choiceText) {
		if (choiceText == null || choiceText.isBlank()) {
			return 0;
		}
		String cleaned = choiceText.replaceFirst("^(가이드\\s*·|미디어\\s*·|관리\\s*·|수정\\s*·|피드백\\s*·)\\s*", "");
		List<String> tokens = tokenize(cleaned);
		int bonus = 0;
		for (String tok : tokens) {
			if (tok.length() >= 2 && norm.contains(tok)) {
				bonus += 2;
			}
		}
		return Math.min(bonus, 8);
	}

	private static List<String> tokenize(String s) {
		List<String> out = new ArrayList<>();
		if (s == null) {
			return out;
		}
		for (String part : s.split("[\\s·,，.!?…。]+")) {
			String p = part.trim().toLowerCase(Locale.ROOT);
			if (p.length() >= 2) {
				out.add(p);
			}
		}
		return out;
	}
}
