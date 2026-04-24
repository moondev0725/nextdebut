package com.java.game.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Random;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import com.java.entity.MyTrainee;
import com.java.game.entity.GameRun;
import com.java.game.entity.GameRunMember;
import com.java.game.entity.GameScene;
import com.java.game.entity.GameTurnLog;
import com.java.game.entity.Gender;
import com.java.game.entity.GroupType;
import com.java.game.entity.Trainee;
import com.java.game.repository.GameRunMemberRepository;
import com.java.game.repository.GameRunRepository;
import com.java.game.repository.GameTurnLogRepository;
import com.java.game.repository.TraineeRepository;
import com.java.game.repository.GameSceneRepository;
import com.java.game.repository.GameChoiceRepository;
import com.java.repository.MyTraineeRepository;
import com.java.photocard.service.PhotoCardService;
import com.java.game.ml.ChatChoicePredictor;
import com.java.game.ml.ChatChoiceTrainingLogger;
import com.java.game.ml.MlSkipReason;
import com.java.game.ml.PredictionResult;

@Service
public class GameService {

	private static final Logger log = LoggerFactory.getLogger(GameService.class);

	private final TraineeRepository traineeRepository;
	private final MyTraineeRepository myTraineeRepository;
	private final GameRunRepository gameRunRepository;
	private final GameRunMemberRepository gameRunMemberRepository;
	private final GameSceneRepository sceneRepository;
	private final GameChoiceRepository choiceRepository;
	private final GameTurnLogRepository turnLogRepository;
	private final GameChatKeywordResolver chatKeywordResolver;
	private final GameAiNarrationService gameAiNarrationService;
	private final TransactionTemplate transactionTemplate;
	private final ChemistryService chemistryService;
	private final PhotoCardService photoCardService;
	private final ChatChoicePredictor chatChoicePredictor;
	private final ChatChoiceTrainingLogger trainingLogger;
	private final double mlThreshold;
	private final boolean mlAcceptIfMargin;
	private final double mlSecondaryMinConfidence;
	private final double mlSecondaryMinTopGap;
	private final double mlNonPrimaryThresholdDelta;

	public GameService(TraineeRepository traineeRepository, MyTraineeRepository myTraineeRepository,
			GameRunRepository gameRunRepository, GameRunMemberRepository gameRunMemberRepository,
			GameSceneRepository sceneRepository, GameChoiceRepository choiceRepository,
			GameTurnLogRepository turnLogRepository, GameChatKeywordResolver chatKeywordResolver,
			GameAiNarrationService gameAiNarrationService, TransactionTemplate transactionTemplate,
			ChemistryService chemistryService, PhotoCardService photoCardService,
			ChatChoicePredictor chatChoicePredictor,
			ChatChoiceTrainingLogger trainingLogger,
			@Value("${app.ml.threshold:0.22}") double mlThreshold,
			@Value("${app.ml.accept-if-margin:true}") boolean mlAcceptIfMargin,
			@Value("${app.ml.secondary-min-confidence:0.17}") double mlSecondaryMinConfidence,
			@Value("${app.ml.secondary-min-top-gap:0.022}") double mlSecondaryMinTopGap,
			@Value("${app.ml.threshold-non-primary-delta:0.02}") double mlNonPrimaryThresholdDelta) {
		this.traineeRepository = traineeRepository;
		this.myTraineeRepository = myTraineeRepository;
		this.gameRunRepository = gameRunRepository;
		this.gameRunMemberRepository = gameRunMemberRepository;
		this.sceneRepository = sceneRepository;
		this.choiceRepository = choiceRepository;
		this.turnLogRepository = turnLogRepository;
		this.chatKeywordResolver = chatKeywordResolver;
		this.gameAiNarrationService = gameAiNarrationService;
		this.transactionTemplate = transactionTemplate;
		this.chemistryService = chemistryService;
		this.photoCardService = photoCardService;
		this.chatChoicePredictor = chatChoicePredictor;
		this.trainingLogger = trainingLogger;
		this.mlThreshold = mlThreshold;
		this.mlAcceptIfMargin = mlAcceptIfMargin;
		this.mlSecondaryMinConfidence = mlSecondaryMinConfidence;
		this.mlSecondaryMinTopGap = mlSecondaryMinTopGap;
		this.mlNonPrimaryThresholdDelta = mlNonPrimaryThresholdDelta;
	}

	private final Random random = new Random();

	private static final String[] MINI_PENALTY_STATS = { "보컬", "댄스", "스타", "멘탈", "팀웍" };

	@Transactional
	public Long createRunAndPickRoster(GroupType groupType, Long memberId) {
		// 게임 실행 기록 저장
		GameRun run = gameRunRepository.save(new GameRun(groupType.name()));
		// groupType에 따라 4명 선발 (로그인 시: 보유 연습생만 풀)
		List<Trainee> picked = pickRoster(groupType, memberId);
		// 선발 순서 저장
		int order = 1;
		for (Trainee t : picked) {
			gameRunMemberRepository.save(new GameRunMember(run, t, order++));
		}
		return run.getRunId();
	}

	@Transactional(readOnly = true)
	public GameRunResult getRunResult(Long runId) {
		List<GameRunMember> members = gameRunMemberRepository.findRoster(runId);
		if (members.isEmpty()) {
			throw new IllegalArgumentException("존재하지 않는 RUN이거나 roster가 없습니다. runId=" + runId);
		}
		GameRun run = members.get(0).getRun();
		String groupType = run.getGroupType();
		boolean confirmed = run.isConfirmed();
		String phase = run.getPhase();

		Long playerMno = run.getPlayerMno();
		List<RosterItem> roster = members.stream().map(m -> toRosterItem(m, playerMno)).collect(Collectors.toList());

		return new GameRunResult(runId, groupType, roster, confirmed, phase);
	}

	// 선발 결과 확정
	@Transactional
	public void confirmRun(Long runId) {
		GameRun run = gameRunRepository.findById(runId)
				.orElseThrow(() -> new IllegalArgumentException("존재하지 않는 runId: " + runId));
		run.confirm();
	}

	/**
	 * 선택지(A/B/C/D) 적용: - 선발된 멤버 중 랜덤 1명 선택 - 선택지에 연관된 스탯을 ±1~3 범위로 조정 - GameRun
	 * phase 다음 단계로 전진 - 결과 반환
	 */
	@Transactional
	public StatChangeResult applyChoice(Long runId, String choiceKey) {
		return applyChoice(runId, choiceKey, Set.of(), false);
	}

	/**
	 * @param eliminatedTraineeIds 클라이언트·세션에서 탈락 처리된 연습생 ID — 턴 스탯 변화 대상에서 제외
	 */
	@Transactional
	public StatChangeResult applyChoice(Long runId, String choiceKey, Set<Long> eliminatedTraineeIds) {
		return applyChoice(runId, choiceKey, eliminatedTraineeIds, false);
	}

	/**
	 * @param statGrowth2x 테스트용: 턴당 능력치 상승량(양수 델타)만 2배
	 */
	@Transactional
	public StatChangeResult applyChoice(Long runId, String choiceKey, Set<Long> eliminatedTraineeIds,
			boolean statGrowth2x) {
		return applyChoice(runId, choiceKey, eliminatedTraineeIds, statGrowth2x, null);
	}

	@Transactional
	public StatChangeResult applyChoice(Long runId, String choiceKey, Set<Long> eliminatedTraineeIds,
			boolean statGrowth2x, Long preferredTraineeId) {
		GameRun run = gameRunRepository.findById(runId)
				.orElseThrow(() -> new IllegalArgumentException("존재하지 않는 runId: " + runId));

		String currentPhase = run.getPhase();
		String nextPhase = calcNextPhase(currentPhase);
		run.nextPhase();

		List<GameRunMember> members = gameRunMemberRepository.findRoster(runId);
		if (members.isEmpty()) {
			throw new IllegalStateException("roster가 없습니다.");
		}

		tickMemberStatuses(members);

		GameRunMember target = pickRandomEligibleMember(members, eliminatedTraineeIds, preferredTraineeId);
		Trainee trainee = target.getTrainee();
		String statName = resolveStatName(choiceKey);

		StatusEffect statusEffect = new StatusEffect();
		int delta = calcDelta(run, currentPhase, choiceKey);
		delta = applyExistingStatusModifier(target, trainee, statName, choiceKey, delta, statusEffect);
		if (statGrowth2x && delta > 0) {
			delta = delta * 2;
		}

		Long playerMno = run.getPlayerMno();
		int beforeVal = getStatValue(trainee, statName, playerMno);
		applyStatToTrainee(trainee, statName, delta);
		int afterVal = getStatValue(trainee, statName, playerMno);

		int fatigueDelta = calcFatigueDelta(choiceKey, run.getCurrentSceneId());
		run.setFatigue(run.getFatigue() + fatigueDelta);

		String bucket = calcSceneBucket(runId, currentPhase, run.getGroupType());
		Long sceneId = run.getCurrentSceneId();
		String eventType = null;
		if (sceneId != null) {
			eventType = sceneRepository.findById(sceneId).map(GameScene::getEventType).orElse(null);
		}
		int turnIndex = calcTurnIndex(currentPhase);
		turnLogRepository.save(new GameTurnLog(
				runId, turnIndex, currentPhase, bucket, sceneId, eventType,
				choiceKey, statName, afterVal - beforeVal, beforeVal, afterVal
		));

		FanChange fanChange = calculateFanChange(run, currentPhase, choiceKey, afterVal - beforeVal);
		fanChange = applyStatusFanModifier(target, fanChange, statusEffect);
		run.applyFanDelta(fanChange.domesticDelta(), fanChange.foreignDelta());
		String unlockedEvent = applyFanEventUnlock(run);

		applyNewStatus(run, target, trainee, choiceKey, afterVal - beforeVal, fanChange.totalDelta(), statusEffect);

		for (GameRunMember gm : members) {
			gameRunMemberRepository.save(gm);
		}
		traineeRepository.save(trainee);
		gameRunRepository.save(run);

		List<RosterItem> updatedRoster = members.stream().map(m -> toRosterItem(m, playerMno)).collect(Collectors.toList());

		return new StatChangeResult(
				trainee.getId(),
				trainee.getName(),
				statName,
				afterVal - beforeVal,
				beforeVal,
				afterVal,
				nextPhase,
				updatedRoster,
				fanChange.totalDelta(),
				fanChange.domesticDelta(),
				fanChange.foreignDelta(),
				0,
				run.getTotalFans(),
				run.getCoreFans(),
				run.getCasualFans(),
				run.getLightFans(),
				fanChange.reactionTitle(),
				fanChange.reactionDesc(),
				unlockedEvent,
				target.getStatusCode(),
				target.getStatusLabel(),
				target.getStatusDesc(),
				target.getStatusTurnsLeft(),
				statusEffect.toText()
		);
	}

	private GameRunMember pickRandomEligibleMember(List<GameRunMember> members, Set<Long> eliminatedTraineeIds,
			Long preferredTraineeId) {
		if (eliminatedTraineeIds == null || eliminatedTraineeIds.isEmpty()) {
			if (preferredTraineeId != null) {
				for (GameRunMember member : members) {
					if (member != null && member.getTrainee() != null
							&& preferredTraineeId.equals(member.getTrainee().getId())) {
						return member;
					}
				}
			}
			return members.get(random.nextInt(members.size()));
		}
		List<GameRunMember> pool = members.stream()
				.filter(m -> m.getTrainee() != null && !eliminatedTraineeIds.contains(m.getTrainee().getId()))
				.collect(Collectors.toList());
		if (pool.isEmpty()) {
			if (preferredTraineeId != null) {
				for (GameRunMember member : members) {
					if (member != null && member.getTrainee() != null
							&& preferredTraineeId.equals(member.getTrainee().getId())) {
						return member;
					}
				}
			}
			return members.get(random.nextInt(members.size()));
		}
		if (preferredTraineeId != null) {
			for (GameRunMember member : pool) {
				if (member != null && member.getTrainee() != null
						&& preferredTraineeId.equals(member.getTrainee().getId())) {
					return member;
				}
			}
		}
		return pool.get(random.nextInt(pool.size()));
	}

	/**
	 * 채팅 입력을 키워드로 해석해 {@link #applyChoice(Long, String)}와 동일하게 턴을 진행한다.
	 * 지문·멤버 대사는 {@link GameAiNarrationService}: Gemini 우선, 쿼터 초과 시에만 DB 저장 지문, 그 외는 최소 지문.
	 * {@code miniGameFailed}가 true이면 턴 적용 후 픽 순 1~4 멤버 중 한 명의 스탯이 -1~-3 추가 감소한다.
	 */
	public ChatApplyOutcome applyChatFromText(Long runId, String userText, boolean miniGameFailed,
			Set<Long> eliminatedTraineeIds) {
		return applyChatFromText(runId, userText, miniGameFailed, eliminatedTraineeIds, false);
	}

	public ChatApplyOutcome applyChatFromText(Long runId, String userText, boolean miniGameFailed,
			Set<Long> eliminatedTraineeIds, boolean statGrowth2x) {
		Set<Long> elim = eliminatedTraineeIds == null ? Set.of() : eliminatedTraineeIds;
		ChatTurnDbSnapshot snap = transactionTemplate.execute(
				status -> executeChatTurnDb(runId, userText, miniGameFailed, elim, statGrowth2x));
		Objects.requireNonNull(snap, "채팅 턴 처리 실패");
		Optional<GameAiNarrationService.ReactionNarrationBundle> aiReact = gameAiNarrationService.tryReactionBundle(
				runId,
				snap.sceneId(),
				snap.statResult().updatedRoster(),
				snap.sceneTitle(),
				snap.sceneDescription(),
				snap.userText(),
				snap.resolvedKey(),
				snap.trainingCategory(),
				snap.statResult(),
				elim);
		if (aiReact.isPresent()) {
			GameAiNarrationService.ReactionNarrationBundle bundle = aiReact.get();
			IdolDialogueBlock b = bundle.block();
			return new ChatApplyOutcome(
					snap.resolvedKey(),
					snap.trainingCategory(),
					snap.statResult(),
					b.situation(),
					bundle.resultNarration(),
					b.lines(),
					snap.miniGamePenalty(),
					snap.predictedKey(),
					snap.predictionConfidence(),
					snap.predictionScores(),
					snap.usedFallback(),
					snap.resolverType());
		}
		StatChangeResult sr = snap.statResult();
		return new ChatApplyOutcome(
				snap.resolvedKey(),
				snap.trainingCategory(),
				sr,
				"",
				minimalTurnNarrationWithoutAi(sr),
				List.of(),
				snap.miniGamePenalty(),
				snap.predictedKey(),
				snap.predictionConfidence(),
				snap.predictionScores(),
				snap.usedFallback(),
				snap.resolverType());
	}

	/** Gemini 미응답 시 UI용 한 줄(스탯 수치만). */
	private static String minimalTurnNarrationWithoutAi(StatChangeResult r) {
		if (r == null) {
			return "훈련이 반영되었습니다.";
		}
		if (r.traineeName() != null && r.statName() != null) {
			return r.traineeName() + "의 " + r.statName() + "이(가) "
					+ (r.delta() >= 0 ? "+" : "") + r.delta() + " 변화했습니다.";
		}
		return "훈련이 반영되었습니다.";
	}

	private ChatTurnDbSnapshot executeChatTurnDb(Long runId, String userText, boolean miniGameFailed,
			Set<Long> eliminatedTraineeIds, boolean statGrowth2x) {
		GameRun run = gameRunRepository.findById(runId)
				.orElseThrow(() -> new IllegalArgumentException("없는 runId: " + runId));
		String phase = run.getPhase();
		if ("FINISHED".equals(phase)) {
			throw new IllegalStateException("이미 종료된 런입니다.");
		}
		if ("MID_EVAL".equals(phase)) {
			throw new IllegalStateException("중간 평가 구간에서는 적용할 수 없습니다.");
		}

		String bucket = calcSceneBucket(runId, phase, run.getGroupType());
		java.util.List<SceneResult.ChoiceItem> choices;
		GameScene sceneEntity;
		Long sid = run.getCurrentSceneId();
		if (sid == null) {
			SceneResult sr = getScene(runId, phase);
			choices = sr.getChoices();
			run = gameRunRepository.findById(runId).orElseThrow();
			sceneEntity = sceneRepository.findById(run.getCurrentSceneId())
					.orElseThrow(() -> new IllegalStateException("씬을 찾을 수 없습니다."));
		} else {
			sceneEntity = sceneRepository.findById(sid)
					.orElseThrow(() -> new IllegalStateException("씬을 찾을 수 없습니다. 페이지를 새로고침하세요."));
			choices = buildChoiceItems(bucket, sceneEntity);
		}

		List<GameRunMember> members = gameRunMemberRepository.findRoster(runId);
		Long preferredTraineeId = resolvePreferredTraineeIdFromText(userText, members, eliminatedTraineeIds);
		PredictionResult prediction = chatChoicePredictor.predict(userText, choices, sceneEntity.getId(), phase);
		String predictedKey = normalizeChoiceKey(prediction.predictedKey());
		double predictionConfidence = prediction.confidence();
		Map<String, Double> predictionScores = prediction.scoreByKey() == null ? Map.of() : prediction.scoreByKey();
		double scoreMargin = topTwoScoreMargin(predictionScores);
		MlSkipReason mlSkipReason = classifyMlSkip(userText, prediction, choices, predictedKey, predictionConfidence,
				scoreMargin);

		boolean usedFallback = true;
		String resolverType = "RULE";
		String key = null;

		if (mlSkipReason == null) {
			key = predictedKey;
			usedFallback = false;
			resolverType = "ML";
			log.debug(
					"chat.choice.resolver ML runId={}, sceneId={}, key={}, conf={}, margin={}, threshold={}, secGap={}",
					runId, sceneEntity.getId(), predictedKey, predictionConfidence, scoreMargin, mlThreshold,
					mlSecondaryMinTopGap);
		} else {
			GameChatKeywordResolver.ChoiceResolution kw = chatKeywordResolver.resolveDetailed(userText, choices);
			key = kw.key();
			log.info(
					"chat.choice.resolver RULE runId={}, sceneId={}, mlSkipReason={}, predictedKey={}, conf={}, margin={}, threshold={}",
					runId, sceneEntity.getId(), mlSkipReason.name(), predictedKey, predictionConfidence, scoreMargin,
					mlThreshold);
		}
		String category = chatKeywordResolver.categorizeTrainingStyle(userText);
		String sceneTitle = sceneEntity.getTitle();
		String sceneDesc = formatDescription(sceneEntity);
		if ("NONE".equalsIgnoreCase(key)) {
			StatChangeResult noop = buildChatNoOpStatResult(runId, eliminatedTraineeIds, preferredTraineeId);
			trainingLogger.recordSample(
					userText,
					sceneEntity.getId(),
					phase,
					choices,
					"NONE",
					resolverType,
					predictedKey,
					predictionConfidence,
					usedFallback,
					mlDecisionReasonLabel(resolverType, mlSkipReason),
					Double.valueOf(scoreMargin));
			return new ChatTurnDbSnapshot(
					"NONE", category, noop, sceneTitle, sceneDesc, sceneEntity.getId(), userText, null,
					predictedKey, predictionConfidence, predictionScores, usedFallback, resolverType);
		}
		StatChangeResult stat = applyChoice(runId, key, eliminatedTraineeIds, statGrowth2x, preferredTraineeId);
		MiniGamePenalty penalty = null;
		if (miniGameFailed) {
			penalty = applyMiniGameFailurePenalty(runId, eliminatedTraineeIds);
			Long pno = gameRunRepository.findById(runId).map(GameRun::getPlayerMno).orElse(null);
			List<RosterItem> roster = gameRunMemberRepository.findRoster(runId).stream().map(m -> toRosterItem(m, pno))
					.collect(Collectors.toList());
			stat = withUpdatedRoster(stat, roster);
		}
		trainingLogger.recordSample(
				userText,
				sceneEntity.getId(),
				phase,
				choices,
				key,
				resolverType,
				predictedKey,
				predictionConfidence,
				usedFallback,
				mlDecisionReasonLabel(resolverType, mlSkipReason),
				Double.valueOf(scoreMargin));
		return new ChatTurnDbSnapshot(
				key, category, stat, sceneTitle, sceneDesc, sceneEntity.getId(), userText, penalty,
				predictedKey, predictionConfidence, predictionScores, usedFallback, resolverType);
	}

	private static String mlDecisionReasonLabel(String resolverType, MlSkipReason mlSkipReason) {
		if ("ML".equalsIgnoreCase(resolverType)) {
			return "ML_APPLIED";
		}
		return mlSkipReason != null ? mlSkipReason.name() : MlSkipReason.UNKNOWN.name();
	}

	private MlSkipReason classifyMlSkip(String userText, PredictionResult prediction, List<SceneResult.ChoiceItem> choices,
			String predictedKey, double confidence, double margin) {
		if (choices == null || choices.isEmpty()) {
			return MlSkipReason.CANDIDATES_EMPTY;
		}
		if (prediction.predictorFailureReason() != null) {
			return prediction.predictorFailureReason();
		}
		if (prediction.fallbackRecommended()) {
			return MlSkipReason.ML_AMBIGUOUS_OR_NONE;
		}
		if (predictedKey == null) {
			return MlSkipReason.ML_INVALID_PREDICTED_KEY;
		}
		if (!isChoiceKeyInSceneChoices(predictedKey, choices)) {
			return MlSkipReason.PREDICTED_KEY_NOT_IN_SCENE;
		}
		String explicitIntentKey = normalizeChoiceKey(chatKeywordResolver.resolveExplicitIntentKey(userText, choices));
		if (explicitIntentKey != null && !explicitIntentKey.equals(predictedKey)) {
			return MlSkipReason.EXPLICIT_INTENT_CONFLICT;
		}
		if (passesMlConfidencePolicy(predictedKey, confidence, margin)) {
			return null;
		}
		return MlSkipReason.CONFIDENCE_POLICY_REJECT;
	}

	private boolean passesMlConfidencePolicy(String predictedKey, double confidence, double margin) {
		if (confidence >= effectiveMlThreshold(predictedKey)) {
			return true;
		}
		if (!mlAcceptIfMargin) {
			return false;
		}
		return margin >= mlSecondaryMinTopGap && confidence >= mlSecondaryMinConfidence;
	}

	private double effectiveMlThreshold(String predictedKey) {
		// C/D/SPECIAL은 데이터 희소 구간이라 소폭 완화해 ML 적용률 편향(A/B 쏠림)을 줄인다.
		if ("C".equals(predictedKey) || "D".equals(predictedKey) || "SPECIAL".equals(predictedKey)) {
			return Math.max(0.0, mlThreshold - mlNonPrimaryThresholdDelta);
		}
		return mlThreshold;
	}

	private static double topTwoScoreMargin(Map<String, Double> scores) {
		if (scores == null || scores.isEmpty()) {
			return 0.0;
		}
		List<Double> vals = scores.values().stream()
				.filter(v -> v != null && Double.isFinite(v.doubleValue()))
				.sorted(Comparator.reverseOrder())
				.limit(2)
				.toList();
		if (vals.size() < 2) {
			return vals.isEmpty() ? 0.0 : 1.0;
		}
		return vals.get(0).doubleValue() - vals.get(1).doubleValue();
	}

	private boolean isChoiceKeyInSceneChoices(String key, List<SceneResult.ChoiceItem> choices) {
		if (key == null || choices == null || choices.isEmpty()) {
			return false;
		}
		for (SceneResult.ChoiceItem choice : choices) {
			String choiceKey = normalizeChoiceKey(choice == null ? null : choice.getKey());
			if (key.equals(choiceKey)) {
				return true;
			}
		}
		return false;
	}

	private String normalizeChoiceKey(String key) {
		if (key == null) {
			return null;
		}
		String normalized = key.trim().toUpperCase(Locale.ROOT);
		return normalized.isBlank() ? null : normalized;
	}

	/**
	 * 채팅이 키워드에 걸리지 않았을 때: 페이즈·스탯·팬·턴로그 없이 현재 스냅샷만 반환.
	 */
	private StatChangeResult buildChatNoOpStatResult(Long runId, Set<Long> eliminatedTraineeIds,
			Long preferredTraineeId) {
		GameRun run = gameRunRepository.findById(runId)
				.orElseThrow(() -> new IllegalArgumentException("없는 runId: " + runId));
		List<GameRunMember> members = gameRunMemberRepository.findRoster(runId);
		if (members.isEmpty()) {
			throw new IllegalStateException("roster가 없습니다.");
		}
		Long pno = run.getPlayerMno();
		List<RosterItem> roster = members.stream().map(m -> toRosterItem(m, pno)).collect(Collectors.toList());
		GameRunMember target = pickRandomEligibleMember(members, eliminatedTraineeIds, preferredTraineeId);
		Trainee trainee = target.getTrainee();
		String phase = run.getPhase();
		return new StatChangeResult(
				trainee.getId(),
				trainee.getName(),
				"-",
				0,
				0,
				0,
				phase,
				roster,
				0,
				0,
				0,
				0,
				run.getTotalFans(),
				run.getCoreFans(),
				run.getCasualFans(),
				run.getLightFans(),
				null,
				null,
				null,
				target.getStatusCode(),
				target.getStatusLabel(),
				target.getStatusDesc(),
				target.getStatusTurnsLeft(),
				null);
	}

	private Long resolvePreferredTraineeIdFromText(String userText, List<GameRunMember> members,
			Set<Long> eliminatedTraineeIds) {
		if (userText == null || userText.isBlank() || members == null || members.isEmpty()) {
			return null;
		}
		String norm = userText.trim().toLowerCase(Locale.ROOT);
		if (norm.isBlank()) {
			return null;
		}
		List<GameRunMember> candidates = members.stream()
				.filter(m -> m != null && m.getTrainee() != null && m.getTrainee().getName() != null)
				.filter(m -> eliminatedTraineeIds == null || eliminatedTraineeIds.isEmpty()
						|| !eliminatedTraineeIds.contains(m.getTrainee().getId()))
				.sorted(Comparator
						.comparingInt((GameRunMember m) -> m.getTrainee().getName().trim().length())
						.reversed()
						.thenComparingInt(GameRunMember::getPickOrder))
				.toList();
		List<Long> matchedIds = new ArrayList<>();
		for (GameRunMember member : candidates) {
			String traineeName = member.getTrainee().getName();
			String cleanName = traineeName == null ? "" : traineeName.trim().toLowerCase(Locale.ROOT);
			if (cleanName.isBlank()) {
				continue;
			}
			if (norm.contains(cleanName)) {
				matchedIds.add(member.getTrainee().getId());
			}
		}
		if (matchedIds.size() != 1) {
			return null;
		}
		return matchedIds.get(0);
	}

	private StatChangeResult withUpdatedRoster(StatChangeResult stat, List<RosterItem> roster) {
		return new StatChangeResult(
				stat.traineeId(),
				stat.traineeName(),
				stat.statName(),
				stat.delta(),
				stat.beforeVal(),
				stat.afterVal(),
				stat.nextPhase(),
				roster,
				stat.fanDelta(),
				stat.coreFanDelta(),
				stat.casualFanDelta(),
				stat.lightFanDelta(),
				stat.totalFans(),
				stat.coreFans(),
				stat.casualFans(),
				stat.lightFans(),
				stat.fanReactionTitle(),
				stat.fanReactionDesc(),
				stat.unlockedEvent(),
				stat.activeStatusCode(),
				stat.activeStatusLabel(),
				stat.activeStatusDesc(),
				stat.activeStatusTurnsLeft(),
				stat.statusEffectText());
	}

	/**
	 * 미니게임 실패 시: 픽 순서 1~4 중 한 명, 다섯 스탯 중 하나가 -1~-3 (클램프 적용).
	 */
	private MiniGamePenalty applyMiniGameFailurePenalty(Long runId, Set<Long> eliminatedTraineeIds) {
		List<GameRunMember> members = new ArrayList<>(gameRunMemberRepository.findRoster(runId));
		members.sort(Comparator.comparingInt(GameRunMember::getPickOrder));
		if (members.isEmpty()) {
			return null;
		}
		List<GameRunMember> pool = members;
		if (eliminatedTraineeIds != null && !eliminatedTraineeIds.isEmpty()) {
			pool = members.stream()
					.filter(m -> m.getTrainee() != null && !eliminatedTraineeIds.contains(m.getTrainee().getId()))
					.collect(Collectors.toList());
		}
		if (pool.isEmpty()) {
			return null;
		}
		GameRunMember target = pool.get(random.nextInt(pool.size()));
		String statName = MINI_PENALTY_STATS[random.nextInt(MINI_PENALTY_STATS.length)];
		int delta = -(1 + random.nextInt(3));
		Trainee trainee = target.getTrainee();
		Long pno = gameRunRepository.findById(runId).map(GameRun::getPlayerMno).orElse(null);
		int beforeVal = getStatValue(trainee, statName, pno);
		applyStatToTrainee(trainee, statName, delta);
		traineeRepository.save(trainee);
		int afterVal = getStatValue(trainee, statName, pno);
		return new MiniGamePenalty(
				trainee.getId(),
				trainee.getName(),
				target.getPickOrder(),
				statName,
				delta,
				beforeVal,
				afterVal);
	}

	@Transactional
	public java.util.List<RosterItem> rerollRun(Long runId) {
		GameRun run = gameRunRepository.findById(runId)
				.orElseThrow(() -> new IllegalArgumentException("존재하지 않는 runId: " + runId));
		// 선발 가능 여부를 먼저 검증한 뒤 기존 로스터를 교체 (실패 시 빈 로스터 방지)
		List<Trainee> picked = pickRoster(GroupType.valueOf(run.getGroupType()), run.getPlayerMno());
		gameRunMemberRepository.deleteByRunRunId(runId);
		int order = 1;
		for (Trainee t : picked) {
			gameRunMemberRepository.save(new GameRunMember(run, t, order++));
		}
		Long pno = run.getPlayerMno();
		return gameRunMemberRepository.findRoster(runId).stream().map(m -> toRosterItem(m, pno)).collect(Collectors.toList());
	}

	@Transactional(readOnly = true)
	public int calculateRosterScore(Long runId) {
		GameRun run = gameRunRepository.findById(runId).orElse(null);
		String phase = run != null && run.getPhase() != null ? run.getPhase() : "FINISHED";
		Long pno = run != null ? run.getPlayerMno() : null;
		List<RosterItem> roster = gameRunMemberRepository.findRoster(runId).stream()
				.map(m -> toRosterItem(m, pno))
				.collect(Collectors.toList());
		int statSum = roster.stream()
				.mapToInt(r -> r.vocal() + r.dance() + r.star() + r.mental() + r.teamwork())
				.sum();
		ChemistryResult chemistry = chemistryService.analyze(roster);
		int raw = EndingService.computeDebutDisplayScore(statSum, chemistry);
		int effectiveTurn = resolveEffectiveTurnForScoring(runId, phase);
		return EndingService.applyProgressToDisplayScore(raw, effectiveTurn);
	}

	/**
	 * 랭킹/대시보드 표시 점수: SCORE_CACHE 우선, 없으면 계산 후(종료 런인 경우) 캐시에 저장.
	 */
	@Transactional
	public int getRankingScore(Long runId) {
		if (runId == null) {
			return 0;
		}
		GameRun run = gameRunRepository.findById(runId).orElse(null);
		if (run == null) {
			return 0;
		}
		Integer cached = run.getScoreCache();
		if (cached != null) {
			// 과거 비정상 상태(빈 로스터 등)에서 0으로 캐시된 값을 복구:
			// FINISHED + 로스터가 존재하는데 score_cache<=0 이면 재계산 후 캐시 갱신
			if ("FINISHED".equals(run.getPhase()) && cached <= 0 && !gameRunMemberRepository.findRoster(runId).isEmpty()) {
				int repaired = calculateRosterScore(runId);
				run.setScoreCache(repaired);
				gameRunRepository.save(run);
				return repaired;
			}
			return Math.max(0, Math.min(EndingService.DISPLAY_SCORE_MAX, cached));
		}
		int computed = calculateRosterScore(runId);
		if ("FINISHED".equals(run.getPhase())) {
			run.setScoreCache(computed);
			gameRunRepository.save(run);
		}
		return computed;
	}

	/** 랭킹 카드용: 해당 런 로스터 능력치 합 + 멤버 수(한 번에 조회). */
	@Transactional(readOnly = true)
	public RosterStatBundle getRosterStatBundle(Long runId) {
		if (runId == null) {
			return new RosterStatBundle(new RosterStatSums(0, 0, 0, 0, 0), 0);
		}
		Long pno = gameRunRepository.findById(runId).map(GameRun::getPlayerMno).orElse(null);
		List<RosterItem> roster = gameRunMemberRepository.findRoster(runId).stream()
				.map(m -> toRosterItem(m, pno))
				.toList();
		int n = roster.size();
		if (n == 0) {
			return new RosterStatBundle(new RosterStatSums(0, 0, 0, 0, 0), 0);
		}
		return new RosterStatBundle(
				new RosterStatSums(
						roster.stream().mapToInt(RosterItem::vocal).sum(),
						roster.stream().mapToInt(RosterItem::dance).sum(),
						roster.stream().mapToInt(RosterItem::star).sum(),
						roster.stream().mapToInt(RosterItem::mental).sum(),
						roster.stream().mapToInt(RosterItem::teamwork).sum()),
				n);
	}

	@Transactional(readOnly = true)
	public RosterStatSums getRosterStatSums(Long runId) {
		return getRosterStatBundle(runId).sums();
	}

	/**
	 * 엔딩/랭킹 점수용: 현재 페이즈(또는 FINISHED)와 턴 로그 중 더 진행된 쪽을 턴 인덱스로 본다.
	 */
	@Transactional(readOnly = true)
	public int resolveEffectiveTurnForScoring(Long runId, String phaseHint) {
		if (runId == null) {
			return 1;
		}
		int maxLog = turnLogRepository.findMaxTurnIndexByRunId(runId);
		if (phaseHint != null && !phaseHint.isBlank() && !"FINISHED".equals(phaseHint)) {
			return Math.max(safeTurnIndexFromPhase(phaseHint), maxLog);
		}
		return Math.max(1, maxLog);
	}

	private int safeTurnIndexFromPhase(String phase) {
		if (phase == null || phase.isBlank()) {
			return 1;
		}
		if ("MID_EVAL".equals(phase)) {
			return 112;
		}
		if ("DEBUT_EVAL".equals(phase)) {
			return 169;
		}
		try {
			return calcTurnIndex(phase);
		} catch (RuntimeException e) {
			return 1;
		}
	}

	@Transactional(readOnly = true)
	public java.util.List<GameRun> getFinishedRuns() {
		return gameRunRepository.findAll().stream()
				.filter(run -> "FINISHED".equals(run.getPhase()))
				.sorted(java.util.Comparator.comparing(GameRun::getCreatedAt).reversed())
				.collect(Collectors.toList());
	}

	/**
	 * FINISHED 런 중 기간에 해당하는 것만. FINISHED_AT 이 없으면 CREATED_AT 으로 대체(레거시 행).
	 */
	@Transactional(readOnly = true)
	public java.util.List<GameRun> getFinishedRunsForRankingPeriod(RankingPeriod period) {
		java.util.List<GameRun> finished = getFinishedRuns();
		if (period == null || period == RankingPeriod.ALL) {
			return finished;
		}
		java.time.ZoneId z = java.time.ZoneId.of("Asia/Seoul");
		java.time.LocalDate today = java.time.LocalDate.now(z);
		java.time.LocalDateTime startInclusive;
		if (period == RankingPeriod.WEEK) {
			java.time.LocalDate monday = today.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
			startInclusive = monday.atStartOfDay(z).toLocalDateTime();
		} else {
			java.time.LocalDate first = today.withDayOfMonth(1);
			startInclusive = first.atStartOfDay(z).toLocalDateTime();
		}
		return finished.stream()
				.filter(run -> {
					java.time.LocalDateTime ref = run.getFinishedAt() != null ? run.getFinishedAt() : run.getCreatedAt();
					return ref != null && !ref.isBefore(startInclusive);
				})
				.collect(Collectors.toList());
	}

	/** playerMno 연동 */
	@Transactional
	public void setPlayerMno(Long runId, Long mno) {
		GameRun run = gameRunRepository.findById(runId).orElse(null);
		if (run != null) {
			run.setPlayerMno(mno);
			gameRunRepository.save(run);
		}
	}

	/**
	 * 데모 시드 전용: 런을 FINISHED 로 두고 가입·클리어 시각을 과거로 맞춘다.
	 */
	@Transactional
	public void applyDemoSeedFinishedRun(Long runId, java.time.LocalDateTime runCreatedAt,
			java.time.LocalDateTime finishedAt) {
		GameRun run = gameRunRepository.findById(runId)
				.orElseThrow(() -> new IllegalArgumentException("존재하지 않는 runId: " + runId));
		run.setPhase("FINISHED");
		run.setCreatedAt(runCreatedAt);
		run.setFinishedAt(finishedAt);
		run.setScoreCache(calculateRosterScore(runId));
		gameRunRepository.save(run);
	}

	/**
	 * 데모 시드용: 최종 표시 점수가 만점(1000)이 되지 않도록 로스터 스탯을 소폭 낮춘다.
	 */
	@Transactional
	public void clampDemoSeedRunScoreBelowPerfect(Long runId) {
		final int maxInclusive = EndingService.DISPLAY_SCORE_MAX - 1;
		final String[] STATS = { "보컬", "댄스", "스타", "멘탈", "팀웍" };
		for (int attempt = 0; attempt < 2500; attempt++) {
			if (calculateRosterScore(runId) <= maxInclusive) {
				return;
			}
			List<GameRunMember> members = gameRunMemberRepository.findRoster(runId);
			if (members.isEmpty()) {
				return;
			}
			GameRunMember pick = members.get(random.nextInt(members.size()));
			Trainee t = pick.getTrainee();
			if (t == null) {
				continue;
			}
			String stat = STATS[random.nextInt(STATS.length)];
			if (getStatValue(t, stat, null) <= 0) {
				continue;
			}
			applyStatToTrainee(t, stat, -1);
			traineeRepository.save(t);
		}
	}

	/**
	 * 비로그인으로 시작한 런에 로그인 사용자를 연결할 때 사용. (이미 다른 회원이 붙은 런은 변경하지 않음)
	 */
	@Transactional
	public void ensurePlayerMnoIfMissing(Long runId, Long mno) {
		if (runId == null || mno == null) {
			return;
		}
		GameRun run = gameRunRepository.findById(runId).orElse(null);
		if (run == null) {
			return;
		}
		if (run.getPlayerMno() == null) {
			run.setPlayerMno(mno);
			gameRunRepository.save(run);
		}
	}

	/**
	 * 엔딩 페이지 직접 진입(단축 데뷔 등) 시 phase가 FINISHED가 아니면 클리어로 확정한다.
	 */
	@Transactional
	public void ensureRunFinishedForEnding(Long runId) {
		if (runId == null) {
			return;
		}
		GameRun run = gameRunRepository.findById(runId).orElse(null);
		if (run == null) {
			return;
		}
		if ("FINISHED".equals(run.getPhase())) {
			if (run.getScoreCache() == null) {
				run.setScoreCache(calculateRosterScore(runId));
				gameRunRepository.save(run);
			}
			return;
		}
		run.forceFinishForEnding();
		run.setScoreCache(calculateRosterScore(runId));
		gameRunRepository.save(run);
	}

	/** 회원 게임 기록 조회 (최신 10개) */
	@Transactional(readOnly = true)
	public java.util.List<GameRunResult> getPlayerHistory(Long mno) {
		return gameRunRepository.findByPlayerMnoOrderByCreatedAtDesc(mno).stream().limit(10).map(run -> {
			java.util.List<com.java.game.entity.GameRunMember> members = gameRunMemberRepository
					.findRoster(run.getRunId());
			Long pno = run.getPlayerMno();
			java.util.List<RosterItem> roster = members.stream().map(m -> toRosterItem(m, pno))
					.collect(java.util.stream.Collectors.toList());
			return new GameRunResult(run.getRunId(), run.getGroupType(), roster, run.isConfirmed(), run.getPhase());
		}).collect(java.util.stream.Collectors.toList());
	}

	@Transactional(readOnly = true)
	public java.util.List<GameTurnLog> getTurnLogs(Long runId) {
		return turnLogRepository.findByRunIdOrderByTurnIndexAsc(runId);
	}

	/** MID_EVAL에서 다음 페이즈로 진행 */
	@Transactional
	public void advanceEval(Long runId) {
		GameRun run = gameRunRepository.findById(runId)
				.orElseThrow(() -> new IllegalArgumentException("존재하지 않는 runId: " + runId));

		// MID_EVAL이면 결과 티어를 저장하고, 다음 7턴 동안 효과 적용
		if ("MID_EVAL".equals(run.getPhase())) {
			int total = gameRunMemberRepository.findRoster(runId).stream()
					.map(GameRunMember::getTrainee)
					.mapToInt(t -> t.getVocal() + t.getDance() + t.getStar() + t.getMental() + t.getTeamwork())
					.sum();
			String tier = midEvalTierByTotal(total);
			run.setMidEvalTier(tier);
			run.setMidEvalEffectUntilTurn(119); // 113~119 (7턴)
		}
		run.nextPhase();
		gameRunRepository.save(run);
	}


	private FanChange calculateFanChange(GameRun run, String currentPhase, String choiceKey, int statDelta) {
		String key = choiceKey == null ? "" : choiceKey.trim().toUpperCase();
		int core = 0;
		int casual = 0;
		int light = 0;

		switch (key) {
			case "A" -> { core += 10; casual += 6; light -= 2; }
			case "B" -> { core -= 4; casual += 8; light += 18; }
			case "C" -> { core += 4; casual -= 7; light -= 10; }
			case "D" -> { core -= 6; casual -= 8; light += 3; }
			default -> { casual += 2; }
		}

		if (statDelta > 0) {
			core += Math.min(8, statDelta * 2);
			casual += Math.min(10, statDelta * 3);
			light += Math.min(12, statDelta * 4);
		} else if (statDelta < 0) {
			int loss = Math.abs(statDelta);
			core -= 4 + loss;
			casual -= 6 + (loss * 2);
			light -= 10 + (loss * 3);
		}

		if (run.getFatigue() >= 65) {
			casual -= 3;
			light -= 5;
		}
		if (currentPhase != null && currentPhase.endsWith("EVENING") && "D".equals(key)) {
			casual -= 4;
			light -= 4;
		}

		int domestic = core;
		int foreign = casual + light;
		int total = domestic + foreign;
		String title;
		String desc;
		if (total >= 25) {
			title = "팬 반응 폭발";
			desc = "퍼포먼스와 화제성이 살아나며 신규 팬 유입이 늘었습니다.";
		} else if (total >= 8) {
			title = "팬 반응 상승";
			desc = "조금씩 입소문이 쌓이며 팬층이 넓어지고 있습니다.";
		} else if (total > 0) {
			title = "조용한 호감";
			desc = "큰 화제는 아니지만 긍정적인 반응이 누적되고 있습니다.";
		} else if (total <= -20) {
			title = "팬 이탈 발생";
			desc = "완성도와 팀 분위기에 대한 아쉬움이 커지며 팬이 빠져나갔습니다.";
		} else if (total < 0) {
			title = "반응 하락";
			desc = "선택의 여파로 일부 팬 반응이 조심스러워졌습니다.";
		} else {
			title = "팬 변화 없음";
			desc = "이번 선택은 팬층에 큰 파장을 만들지 않았습니다.";
		}
		return new FanChange(domestic, foreign, title, desc);
	}

	private String applyFanEventUnlock(GameRun run) {
		int flags = run.getFanEventFlags();
		int total = run.getTotalFans();
		String unlocked = null;

		if ((flags & 1) == 0 && total >= 45) {
			flags |= 1;
			unlocked = append(unlocked,
					"첫 응원 댓글이 모이기 시작했습니다.|커뮤니티 반응이 살아나며 팀을 꾸준히 언급하는 팬이 늘고 있습니다.");
		}

		if ((flags & 2) == 0 && run.getForeignFans() >= 55) {
			flags |= 2;
			unlocked = append(unlocked,
					"입덕 직전 팬층이 늘었습니다.|가볍게 지켜보던 해외·일반 팬들이 점점 고정 관심층으로 바뀌고 있습니다.");
		}

		if ((flags & 4) == 0 && run.getForeignFans() >= 70) {
			flags |= 4;
			unlocked = append(unlocked,
					"짧은 클립이 퍼지기 시작했습니다.|해외 팬 유입이 붙으며 팀 이름이 빠르게 노출되고 있습니다.");
		}

		if ((flags & 8) == 0 && total >= 110) {
			flags |= 8;
			unlocked = append(unlocked,
					"캐스팅 이벤트 제안이 도착했습니다.|팬들과 직접 만날 기회가 생기며 충성도가 상승합니다.");
		}

		if ((flags & 16) == 0 && run.getCoreFans() >= 80) {
			flags |= 16;
			unlocked = append(unlocked,
					"코어 팬덤 결속 이벤트가 열렸습니다.|핵심 팬층이 단단해지며 안정적인 지지를 확보합니다.");
		}

		if ((flags & 32) == 0 && run.getForeignFans() >= 160) {
			flags |= 32;
			unlocked = append(unlocked,
					"바이럴 클립 확산 이벤트가 열렸습니다.|SNS에서 퍼지며 해외·신규 유입이 크게 증가합니다.");
		}

		if ((flags & 64) == 0 && total >= 220) {
			flags |= 64;
			unlocked = append(unlocked,
					"화제성 급상승 이벤트가 발생했습니다.|온라인 커뮤니티에서 언급량이 폭증하며 팀 이름이 빠르게 퍼지고 있습니다.");
		}

		if ((flags & 128) == 0 && run.getForeignFans() >= 140) {
			flags |= 128;
			unlocked = append(unlocked,
					"팬아트 유행이 시작됐습니다.|2차 창작과 캡처 이미지가 돌면서 관심도가 눈에 띄게 커졌습니다.");
		}

		if ((flags & 256) == 0 && run.getCoreFans() >= 135) {
			flags |= 256;
			unlocked = append(unlocked,
					"응원 슬로건이 생겼습니다.|팬덤 내부 결속이 올라가며 코어 팬층의 잔존력이 더 높아졌습니다.");
		}

		if ((flags & 512) == 0 && run.getForeignFans() >= 235) {
			flags |= 512;
			unlocked = append(unlocked,
					"직캠 조회수가 폭발했습니다.|개별 멤버 인지도가 급상승하며 해외 유입이 크게 늘었습니다.");
		}

		run.setFanEventFlags(flags);
		return unlocked;
	}
	
	private String append(String base, String add) {
		return base == null ? add : base + "||" + add;
	}

	/** 국내(CORE) / 해외(CASUAL+구 LIGHT 합산) 델타 */
	private record FanChange(int domesticDelta, int foreignDelta, String reactionTitle, String reactionDesc) {
		int totalDelta() { return domesticDelta + foreignDelta; }
	}

	private void tickMemberStatuses(List<GameRunMember> members) {
		if (members == null) return;
		members.forEach(GameRunMember::tickStatus);
	}

	private int applyExistingStatusModifier(GameRunMember member, Trainee trainee, String statName, String choiceKey, int delta, StatusEffect statusEffect) {
		if (member == null || !member.hasActiveStatus()) return delta;
		String code = member.getStatusCode();
		String key = choiceKey == null ? "" : choiceKey.trim().toUpperCase();
		if ("BURNOUT".equals(code) && delta > 0 && !"멘탈".equals(statName)) {
			statusEffect.add("번아웃 영향으로 성장량이 1 감소했습니다.");
			return Math.max(0, delta - 1);
		}
		if ("INJURY".equals(code) && "댄스".equals(statName)) {
			statusEffect.add("부상 영향으로 댄스 효율이 1 감소했습니다.");
			return delta - 1;
		}
		if ("CONFIDENCE".equals(code) && delta > 0) {
			statusEffect.add("자신감 상승 효과로 성장량이 1 추가되었습니다.");
			return delta + 1;
		}
		if ("HARMONY".equals(code) && ("팀웍".equals(statName) || "멘탈".equals(statName))) {
			statusEffect.add("팀 합이 올라 팀웍/멘탈 상승량이 1 추가되었습니다.");
			return delta + 1;
		}
		if ("SLUMP".equals(code) && delta > 0 && !"멘탈".equals(statName)) {
			statusEffect.add("슬럼프 영향으로 일반 성장량이 1 감소했습니다.");
			return Math.max(0, delta - 1);
		}
		if ("SPOTLIGHT".equals(code) && ("스타".equals(statName) || "SPECIAL".equals(key)) && delta > 0) {
			statusEffect.add("주목도 상승으로 스타 관련 성장량이 1 추가되었습니다.");
			return delta + 1;
		}
		if ("FANDOM".equals(code) && "D".equalsIgnoreCase(key) && delta > 0) {
			statusEffect.add("팬덤의 응원으로 멘탈 회복 효과가 더 안정적으로 들어갔습니다.");
		}
		return delta;
	}

	private FanChange applyStatusFanModifier(GameRunMember member, FanChange fanChange, StatusEffect statusEffect) {
		if (member == null || fanChange == null || !member.hasActiveStatus()) return fanChange;
		String code = member.getStatusCode();
		int domestic = fanChange.domesticDelta();
		int foreign = fanChange.foreignDelta();
		if ("FANDOM".equals(code) && fanChange.totalDelta() > 0) {
			domestic += 4;
			foreign += 20;
			statusEffect.add("팬덤 형성 효과로 팬 유입이 추가 상승했습니다.");
		} else if ("BURNOUT".equals(code)) {
			foreign -= 8;
			statusEffect.add("번아웃 영향으로 팬 반응이 조금 둔화됐습니다.");
		} else if ("INJURY".equals(code)) {
			foreign -= 2;
			statusEffect.add("부상 여파로 화제성 팬 유입이 소폭 줄었습니다.");
		} else if ("CONFIDENCE".equals(code) && fanChange.totalDelta() >= 0) {
			domestic += 2;
			foreign += 5;
			statusEffect.add("자신감 상승 효과로 팬 반응이 추가 상승했습니다.");
		} else if ("HARMONY".equals(code) && fanChange.totalDelta() >= 0) {
			domestic += 3;
			foreign += 3;
			statusEffect.add("팀 합 상승 효과로 팬들의 몰입감이 높아졌습니다.");
		} else if ("SLUMP".equals(code)) {
			foreign -= 5;
			statusEffect.add("슬럼프 영향으로 팬 반응이 살짝 둔화됐습니다.");
		} else if ("SPOTLIGHT".equals(code) && fanChange.totalDelta() > 0) {
			foreign += 10;
			statusEffect.add("주목도 상승 효과로 해외 팬 유입이 크게 늘었습니다.");
		}
		return new FanChange(domestic, foreign, fanChange.reactionTitle(), fanChange.reactionDesc());
	}

	private void applyNewStatus(GameRun run, GameRunMember member, Trainee trainee, String choiceKey, int statDelta, int fanDelta, StatusEffect statusEffect) {
		if (member == null || trainee == null) return;
		String key = choiceKey == null ? "" : choiceKey.trim().toUpperCase();

		if ("BURNOUT".equals(member.getStatusCode()) && "D".equals(key) && statDelta > 0) {
			member.clearStatus();
			statusEffect.add("휴식 선택으로 번아웃이 해소되었습니다.");
			return;
		}
		if ("SLUMP".equals(member.getStatusCode()) && "D".equals(key) && statDelta > 0) {
			member.clearStatus();
			statusEffect.add("회복 선택으로 슬럼프가 해소되었습니다.");
			return;
		}

		if ((("B".equals(key) || "SPECIAL".equals(key)) && run.getFatigue() >= 68 && (statDelta <= 0 || trainee.getDance() <= 55))) {
			member.setStatus("INJURY", "부상", "2턴 동안 댄스 성장 효율이 낮아지고 화제성 팬 유입이 줄어듭니다.", 2);
			statusEffect.add(trainee.getName() + "에게 부상 상태가 2턴 적용되었습니다.");
			return;
		}
		if (!"D".equals(key) && run.getFatigue() >= 78 && trainee.getMental() <= 55) {
			member.setStatus("BURNOUT", "번아웃", "3턴 동안 멘탈 관리 전까지 일반 성장과 팬 반응이 둔화됩니다.", 3);
			statusEffect.add(trainee.getName() + "에게 번아웃 상태가 3턴 적용되었습니다.");
			return;
		}
		if (statDelta >= 1 && (trainee.getMental() >= 55 || trainee.getStar() >= 55)) {
			member.setStatus("CONFIDENCE", "자신감 상승", "2턴 동안 모든 긍정 성장량이 1 추가되고 팬 반응이 소폭 상승합니다.", 2);
			statusEffect.add(trainee.getName() + "이(가) 자신감 상승 상태에 들어갔습니다.");
			return;
		}
		if (("C".equals(key) || "D".equals(key)) && statDelta > 0 && fanDelta >= 8) {
			member.setStatus("HARMONY", "팀 합 상승", "2턴 동안 팀웍/멘탈 성장량이 1 추가되고 팬 몰입도가 상승합니다.", 2);
			statusEffect.add(trainee.getName() + "이(가) 팀 합 상승 상태에 들어갔습니다.");
			return;
		}
		// 주목도 상승 (조건 완화 + 더 자주 뜨게)
		if ((fanDelta >= 10 && statDelta >= 1) || ("SPECIAL".equals(key) && fanDelta >= 8)) {
			member.setStatus("SPOTLIGHT", "주목도 상승", "2턴 동안 스타 관련 성장과 해외 팬 유입이 강화됩니다.", 2);
			statusEffect.add(trainee.getName() + "이(가) 주목도 상승 상태에 들어갔습니다.");
			return;
		}
		if (statDelta <= -1 && fanDelta <= -8) {
			member.setStatus("SLUMP", "슬럼프", "2턴 동안 일반 성장과 팬 반응이 살짝 둔화되지만 휴식 선택으로 회복할 수 있습니다.", 2);
			statusEffect.add(trainee.getName() + "에게 슬럼프 상태가 2턴 적용되었습니다.");
			return;
		}
		if (fanDelta >= 20 && trainee.getStar() >= 55) {
			member.setStatus("FANDOM", "팬덤 형성", "3턴 동안 긍정적인 턴에서 팬 유입 보너스를 받습니다.", 3);
			statusEffect.add(trainee.getName() + "이(가) 팬덤 형성 상태에 들어갔습니다.");
		}
	}

	private static final class StatusEffect {
		private final java.util.List<String> messages = new java.util.ArrayList<>();
		void add(String message) {
			if (message != null && !message.isBlank() && !messages.contains(message)) messages.add(message);
		}
		String toText() {
			return messages.isEmpty() ? null : String.join(" ", messages);
		}
	}

	private String midEvalTierByTotal(int total) {
		if (total >= 1200) return "S";
		if (total >= 1000) return "A";
		if (total >= 800) return "B";
		if (total >= 600) return "C";
		return "D";
	}

	/**
	 * runId 기반 씬 조회.
	 * - DAY1(아침/저녁): 고정 씬 (항상 동일)
	 * - DAY2 이후: GameRun에 저장된 씬 ID 사용, 없으면 랜덤 선택 후 저장 (해당 페이즈 내 고정)
	 */
	@Transactional
	public SceneResult getScene(Long runId, String phase) {
		GameRun run = gameRunRepository.findById(runId)
				.orElseThrow(() -> new IllegalArgumentException("없는 runId: " + runId));

		String bucket = calcSceneBucket(runId, phase, run.getGroupType());
		List<GameScene> pool = sceneRepository.findAllByPhase(bucket);
		if (pool.isEmpty()) throw new IllegalArgumentException("씬 풀 없음: " + bucket + " (phase=" + phase + ")");

		// 매 턴 랜덤 + 반복 방지(직전 씬/최근 eventType 반복 최소화)
		java.util.List<GameTurnLog> recent = turnLogRepository.findTop8ByRunIdOrderByTurnIndexDesc(runId);
		java.util.Set<String> recentEventTypes = recent.stream()
				.map(GameTurnLog::getEventType)
				.filter(s -> s != null && !s.isBlank())
				.collect(java.util.stream.Collectors.toSet());
		java.util.Set<Long> recentSceneIds = recent.stream()
				.map(GameTurnLog::getSceneId)
				.filter(id -> id != null)
				.collect(java.util.stream.Collectors.toSet());

		GameScene scene = pickAvoidingRecent(pool, run.getCurrentSceneId(), recentSceneIds, recentEventTypes);
		run.setCurrentSceneId(scene.getId());

		java.util.List<SceneResult.ChoiceItem> choices = buildChoiceItems(bucket, scene);

		return new SceneResult(
				phase,
				scene.getId(),
				scene.getEventType(),
				scene.getTitle(),
				formatDescription(scene),
				choices);
	}

	private java.util.List<SceneResult.ChoiceItem> buildChoiceItems(String bucket, GameScene scene) {
		return choiceRepository.findByPhaseOrderBySortOrder(bucket).stream()
				.map(c -> new SceneResult.ChoiceItem(
						c.getChoiceKey(),
						buildChoiceText(bucket, scene, c.getChoiceKey(), c.getStatTarget(), c.getChoiceText()),
						c.getStatTarget()))
				.collect(Collectors.toList());
	}

	private String formatDescription(GameScene scene) {
		return scene.getDescription() == null ? "" : scene.getDescription().trim();
	}

	private String buildChoiceText(String bucket, GameScene scene, String choiceKey, String statTarget, String fallback) {
		// 선택지는 statTarget은 유지하되, 문구만 랜덤으로 바꿔 "매번 똑같음"을 제거한다.
		// (DB 값이 없거나 특수 상황이면 fallback 사용)
		String k = choiceKey == null ? "" : choiceKey.toUpperCase();
		String et = scene != null && scene.getEventType() != null ? scene.getEventType() : "";

		String[] vocal = {
				"발성 루틴을 다시 잡는다",
				"후렴 라이브를 집중 교정한다",
				"호흡/음정 체크로 안정감을 만든다",
				"파트별 톤을 통일한다"
		};
		String[] dance = {
				"동선부터 다시 맞춘다",
				"포인트 안무를 강하게 찍는다",
				"거울 없이도 각을 맞추는 훈련을 한다",
				"표정+제스처까지 합쳐 완성도를 올린다"
		};
		String[] teamwork = {
				"파트 분배를 재조정한다",
				"호흡/큐 사인을 통일한다",
				"갈등 포인트를 정리하고 합의한다",
				"서로의 약점을 메우는 전략을 짠다"
		};
		String[] mental = {
				"무리한 루틴을 줄이고 회복한다",
				"짧게 쉬고 집중을 재정렬한다",
				"컨디션 체크 후 리스크를 낮춘다",
				"멘탈 케어로 팀 텐션을 안정시킨다"
		};
		String[] star = {
				"카메라 리허설로 존재감을 올린다",
				"한 방 포인트를 만든다",
				"미디어용 컷을 노린다",
				"무대 동선을 '보이게' 바꾼다"
		};

		String prefix = "";
		if (et.contains("MEDIA")) prefix = "미디어 · ";
		else if (et.contains("CONDITION")) prefix = "관리 · ";
		else if (et.contains("CHOREOGRAPHY")) prefix = "수정 · ";
		else if (et.contains("TRAINER")) prefix = "피드백 · ";

		String pick;
		switch (k) {
		case "A" -> pick = prefix + vocal[random.nextInt(vocal.length)];
		case "B" -> pick = prefix + dance[random.nextInt(dance.length)];
		case "C" -> pick = prefix + teamwork[random.nextInt(teamwork.length)];
		case "D" -> pick = prefix + mental[random.nextInt(mental.length)];
		default -> pick = prefix + star[random.nextInt(star.length)];
		}

		// SPECIAL은 도전/리스크가 보이게 문구를 조금 다르게
		if ("SPECIAL".equals(k)) {
			String[] sp = {
					"승부수: 카메라 테스트로 분위기를 뒤집는다",
					"승부수: 난이도를 올려 한계를 넘긴다",
					"승부수: 즉흥 연출로 임팩트를 만든다",
					"승부수: 완성 대신 '한 컷'을 노린다"
			};
			pick = sp[random.nextInt(sp.length)];
		}

		return (pick == null || pick.isBlank()) ? (fallback == null ? "" : fallback) : pick;
	}

	private GameScene pickAvoidingRecent(
			List<GameScene> pool,
			Long lastId,
			java.util.Set<Long> recentSceneIds,
			java.util.Set<String> recentEventTypes
	) {
		if (pool.size() == 1) return pool.get(0);

		GameScene picked = null;
		for (int i = 0; i < 14; i++) {
			GameScene cand = pool.get(random.nextInt(pool.size()));
			Long id = cand.getId();
			if (id != null && lastId != null && id.equals(lastId)) continue;
			if (id != null && recentSceneIds != null && recentSceneIds.contains(id)) continue;
			String et = cand.getEventType();
			if (et != null && recentEventTypes != null && recentEventTypes.contains(et) && pool.size() >= 3) {
				// 풀에 여유가 있을 때만 eventType 반복을 강하게 회피
				continue;
			}
			picked = cand;
			break;
		}
		return picked != null ? picked : pool.get(random.nextInt(pool.size()));
	}

	/* ── DB의 statTarget(영문)을 한글로 변환 ── */
	private String resolveStatName(String choiceKey) {
		if (choiceKey == null || choiceKey.isBlank()) {
			return "스타";
		}
		return switch (choiceKey.toUpperCase()) {
		case "A" -> "보컬";
		case "B" -> "댄스";
		case "C" -> "팀웍";
		case "D" -> "멘탈";
		default -> "스타";
		};
	}

	/* ── 변화량 계산: 대부분 +1~3, 가끔 -1~-2 ── */
	private int calcDelta(GameRun run, String currentPhase, String choiceKey) {
		// 선택지 힌트/밸런스:
		// - A/B/C/D: 안정(대부분 +1~2, 가끔 -1)
		// - SPECIAL: 도전(+0~4, 가끔 -2)
		String k = choiceKey == null ? "" : choiceKey.toUpperCase();

		// MID_EVAL 결과 버프/패널티(다음 7턴) 적용
		int turn = calcTurnIndex(currentPhase);
		String tier = (run == null ? null : run.getMidEvalTier());
		Integer until = (run == null ? null : run.getMidEvalEffectUntilTurn());
		boolean effectOn = (tier != null && until != null && turn > 112 && turn <= until);

		// 피로도가 높으면 하락 확률 증가, 낮으면 안정 성장
		int fatigue = (run == null ? 0 : run.getFatigue());

		if ("SPECIAL".equals(k)) {
			int roll = random.nextInt(10);
			// 피로가 높을수록 실패 확률↑
			if (fatigue >= 70 && roll <= 1) return -2;   // 20% 실패
			if (roll == 0) return -2;                    // 기본 10% 실패
			if (roll <= 2) return 0;             // 20% 무효
			return random.nextInt(4) + 1;        // 70% +1~4
		}

		int roll = random.nextInt(10);
		if (effectOn) {
			if ("S".equals(tier) || "A".equals(tier)) {
				// 하락 확률 10% → 4%
				if (roll == 0) roll = 1;
				// +2 확률 살짝 증가
				if (roll >= 7) return 2;
			} else if ("D".equals(tier) || "C".equals(tier)) {
				// 하락 확률 10% → 18%
				if (roll <= 1) return -1;
			}
		}

		// 피로 패널티/보너스
		if (fatigue >= 85) {            // 매우 피곤: 하락↑, +2 거의 안뜸
			if (roll <= 2) return -1;    // 30%
			return 1;                    // 70% +1
		}
		if (fatigue >= 70) {            // 피곤: 하락↑
			if (roll <= 1) return -1;    // 20%
			return random.nextInt(2) + 1;
		}
		if (fatigue <= 25) {            // 컨디션 좋음: 하락↓, +2↑
			if (roll == 0) roll = 1;     // 10% → 0% 수준
			if (roll >= 7) return 2;
		}

		if (roll == 0) return -1;               // 기본 10% 하락
		return random.nextInt(2) + 1;           // 기본 90% +1~2
	}

	private int calcFatigueDelta(String choiceKey, Long sceneId) {
		// 기본: 행동하면 피로 +3~6, SPECIAL은 더 큼. 컨디션 이벤트면 추가.
		String k = choiceKey == null ? "" : choiceKey.toUpperCase();
		int base = "SPECIAL".equals(k) ? 8 : 5;
		int jitter = random.nextInt(4) - 1; // -1..+2
		int extra = 0;
		if (sceneId != null) {
			String et = sceneRepository.findById(sceneId).map(GameScene::getEventType).orElse("");
			if (et != null && et.contains("CONDITION")) extra += 4;
			if (et != null && et.contains("CHOREOGRAPHY")) extra += 3;
			if (et != null && et.contains("MEDIA")) extra += 2;
		}
		// D(멘탈/컨디션) 선택지는 피로 감소
		if ("D".equals(k)) return -(6 + random.nextInt(3)); // -6~-8
		return base + jitter + extra;
	}

	/* ── 스탯명으로 현재 값 조회 (playerMno 가 있으면 포토카드 퍼센트 보너스 적용) ── */
	private int getStatValue(Trainee t, String statName, Long playerMno) {
		int base = switch (statName) {
		case "보컬" -> t.getVocal();
		case "댄스" -> t.getDance();
		case "스타" -> t.getStar();
		case "멘탈" -> t.getMental();
		case "팀웍" -> t.getTeamwork();
		default -> 0;
		};
		if (playerMno == null) {
			return base;
		}
		int pct = photoCardService.getEquippedBonusPercent(playerMno, t.getId());
		int enhanced = PhotoCardService.applyPercentBonus(base, pct);
		return enhanced + getEnhanceBonusFor(playerMno, t.getId());
	}

	/* ── 스탯 적용 ── */
	private void applyStatToTrainee(Trainee t, String statName, int delta) {
		switch (statName) {
		case "보컬" -> t.applyVocal(delta);
		case "댄스" -> t.applyDance(delta);
		case "스타" -> t.applyStar(delta);
		case "멘탈" -> t.applyMental(delta);
		case "팀웍" -> t.applyTeamwork(delta);
		}
	}

	/* ── 다음 phase 문자열만 미리 계산 (run.nextPhase() 호출 전) ── */
	private String calcNextPhase(String current) {
		if ("MID_EVAL".equals(current)) return "DAY57_MORNING";
		if ("DEBUT_EVAL".equals(current)) return "FINISHED";
		PhaseParts p = parseOrThrow(current);
		if (p.day == 56 && p.isEvening) return "MID_EVAL";
		if (p.day == 84 && p.isEvening) return "DEBUT_EVAL";
		if (!p.isEvening) return "DAY" + p.day + "_EVENING";
		return "DAY" + (p.day + 1) + "_MORNING";
	}

	private PhaseParts parseOrThrow(String phase) {
		if ("DEBUT_EVAL".equals(phase)) return new PhaseParts(84, true);
		if ("MID_EVAL".equals(phase)) return new PhaseParts(56, true);
		if (phase == null || !phase.startsWith("DAY")) throw new IllegalArgumentException("잘못된 phase: " + phase);
		int us = phase.indexOf('_');
		if (us <= 3) throw new IllegalArgumentException("잘못된 phase: " + phase);
		String dayStr = phase.substring(3, us);
		String part = phase.substring(us + 1);
		try {
			int day = Integer.parseInt(dayStr);
			boolean isEvening = "EVENING".equals(part);
			boolean isMorning = "MORNING".equals(part);
			if (!isEvening && !isMorning) throw new IllegalArgumentException("잘못된 phase: " + phase);
			return new PhaseParts(day, isEvening);
		} catch (Exception e) {
			throw new IllegalArgumentException("잘못된 phase: " + phase);
		}
	}

	private static class PhaseParts {
		final int day;
		final boolean isEvening;
		PhaseParts(int day, boolean isEvening) { this.day = day; this.isEvening = isEvening; }
	}

	/**
	 * 현재 진행 phase(DAYn_MORNING/EVENING, DEBUT_EVAL)를 "지문 풀(버킷)"로 매핑.
	 * - 첫날 튜토리얼: 시간(아침/저녁) × 그룹(혼성/남/여) 각각 별도 풀
	 * - 이후: 월차(1/2/3) × 전반/후반(2주 단위) × 시간(아침/저녁) 별도 풀
	 */
	private String calcSceneBucket(Long runId, String phase, String groupType) {
		if ("MID_EVAL".equals(phase)) return calcMidEvalBucket(runId);
		if ("DEBUT_EVAL".equals(phase)) return calcDebutEvalBucket(runId);
		PhaseParts p = parseOrThrow(phase);
		String time = p.isEvening ? "EVENING" : "MORNING";
		int day = p.day; // 1..84

		if (day == 1) {
			// groupType은 기존 값(예: MIXED/MALE/FEMALE)을 그대로 사용
			String gt = (groupType == null || groupType.isBlank()) ? "MIXED" : groupType.trim().toUpperCase();
			return "TUTORIAL_" + time + "_" + gt;
		}

		// day 2..84 => 3개월(각 28일)
		int month = ((day - 1) / 28) + 1;          // 1..3
		int dayInMonth = ((day - 1) % 28) + 1;     // 1..28
		String half = (dayInMonth <= 14) ? "H1" : "H2"; // 전반/후반(2주 단위)

		// 1개월차는 "첫날 제외" 요구 때문에, dayInMonth==1은 튜토리얼로 이미 처리.
		return "M" + month + "_" + half + "_" + time;
	}

	private String calcMidEvalBucket(Long runId) {
		List<GameRunMember> members = gameRunMemberRepository.findRoster(runId);
		int total = members.stream()
				.map(GameRunMember::getTrainee)
				.mapToInt(t -> t.getVocal() + t.getDance() + t.getStar() + t.getMental() + t.getTeamwork())
				.sum();
		// 중간평가: 절반 시점(112턴)이라 기준을 조금 완화
		if (total >= 1200) return "MID_EVAL_S";
		if (total >= 1000) return "MID_EVAL_A";
		if (total >= 800) return "MID_EVAL_B";
		if (total >= 600) return "MID_EVAL_C";
		return "MID_EVAL_D";
	}

	private String calcDebutEvalBucket(Long runId) {
		List<GameRunMember> members = gameRunMemberRepository.findRoster(runId);
		Long pno = gameRunRepository.findById(runId).map(GameRun::getPlayerMno).orElse(null);
		List<RosterItem> roster = members.stream().map(m -> toRosterItem(m, pno)).collect(Collectors.toList());
		int statSum = roster.stream()
				.mapToInt(r -> r.vocal() + r.dance() + r.star() + r.mental() + r.teamwork())
				.sum();
		ChemistryResult chemistry = chemistryService.analyze(roster);
		int score = EndingService.computeDebutDisplayScore(statSum, chemistry);
		if (score >= EndingService.DEBUT_GRADE_S_MIN) return "DEBUT_EVAL_S";
		if (score >= EndingService.DEBUT_GRADE_A_MIN) return "DEBUT_EVAL_A";
		if (score >= EndingService.DEBUT_GRADE_B_MIN) return "DEBUT_EVAL_B";
		if (score >= EndingService.DEBUT_GRADE_C_MIN) return "DEBUT_EVAL_C";
		return "DEBUT_EVAL_D";
	}

	private int calcTurnIndex(String phase) {
		if ("MID_EVAL".equals(phase)) return 112;
		if ("DEBUT_EVAL".equals(phase)) return 169;
		PhaseParts p = parseOrThrow(phase);
		// DAYn_MORNING= (n-1)*2 + 1, DAYn_EVENING= (n-1)*2 + 2
		return (p.day - 1) * 2 + (p.isEvening ? 2 : 1);
	}

	/* ── GameRunMember → RosterItem 변환 (playerMno: 포토카드 능력치·등급 표시) ── */
	private RosterItem toRosterItem(GameRunMember m, Long playerMno) {
		Trainee t = m.getTrainee();
		String code = t.getPersonalityCode();
		if (code == null || code.isBlank()) {
			code = IdolPersonality.forPickOrder(m.getPickOrder()).name();
		}
		int pct = playerMno == null ? 0 : photoCardService.getEquippedBonusPercent(playerMno, t.getId());
		String pcg = pct > 0 ? photoCardService.getEquippedGradeCode(playerMno, t.getId()) : null;
		int enhanceLevel = resolveEnhanceLevel(playerMno, t.getId());
		int enhanceBonus = enhanceBonusByLevel(enhanceLevel);
		int v = PhotoCardService.applyPercentBonus(t.getVocal(), pct) + enhanceBonus;
		int d = PhotoCardService.applyPercentBonus(t.getDance(), pct) + enhanceBonus;
		int s = PhotoCardService.applyPercentBonus(t.getStar(), pct) + enhanceBonus;
		int me = PhotoCardService.applyPercentBonus(t.getMental(), pct) + enhanceBonus;
		int tm = PhotoCardService.applyPercentBonus(t.getTeamwork(), pct) + enhanceBonus;
		String rosterImg = t.getImagePath();
		if (pcg != null) {
			rosterImg = PhotoCardService.resolvePhotoCardImagePath(t.getImagePath(), pcg);
		}
		return new RosterItem(t.getId(), t.getName(), t.getGender(), t.getGrade() != null ? t.getGrade().name() : "",
				v, d, s, me, tm, rosterImg,
				m.getPickOrder(), code, t.getAge(),
				m.getStatusCode(), m.getStatusLabel(), m.getStatusDesc(), m.getStatusTurnsLeft(), enhanceLevel,
				pcg, pct);
	}

	private int resolveEnhanceLevel(Long playerMno, Long traineeId) {
		if (playerMno == null || traineeId == null) {
			return 0;
		}
		return myTraineeRepository.findByMemberIdAndTraineeId(playerMno, traineeId)
				.map(MyTrainee::getEnhanceLevel)
				.orElse(0);
	}

	private int getEnhanceBonusFor(Long playerMno, Long traineeId) {
		return enhanceBonusByLevel(resolveEnhanceLevel(playerMno, traineeId));
	}

	private int enhanceBonusByLevel(int level) {
		int lv = Math.max(0, level);
		return switch (lv) {
		case 1 -> 1;
		case 2 -> 2;
		case 3 -> 3;
		case 4 -> 4;
		case 5 -> 7;
		default -> 0;
		};
	}

	@Transactional
	public java.util.List<RosterItem> updateRosterPersonality(Long runId, Long traineeId, String personalityCode) {
		if (runId == null || traineeId == null) {
			throw new IllegalArgumentException("runId/traineeId는 필수입니다.");
		}
		IdolPersonality p = IdolPersonality.fromCodeOrNull(personalityCode);
		if (p == null) {
			throw new IllegalArgumentException("잘못된 personalityCode: " + personalityCode);
		}
		java.util.List<GameRunMember> members = gameRunMemberRepository.findRoster(runId);
		GameRunMember target = members.stream()
				.filter(m -> m.getTrainee() != null && traineeId.equals(m.getTrainee().getId()))
				.findFirst()
				.orElseThrow(() -> new IllegalArgumentException("로스터에 없는 연습생입니다. runId=" + runId + ", traineeId=" + traineeId));

		Trainee trainee = target.getTrainee();
		trainee.setPersonalityCode(p.name());
		traineeRepository.save(trainee);

		Long pno = members.get(0).getRun().getPlayerMno();
		return members.stream().map(m -> toRosterItem(m, pno)).collect(java.util.stream.Collectors.toList());
	}

	/**
	 * @param memberId 로그인 회원 mno. null이면 전체 연습생 풀(비로그인 게스트). 지정 시 MY_TRAINEE 보유분만 사용.
	 */
	private List<Trainee> pickRoster(GroupType groupType, Long memberId) {
		List<Trainee> all = traineeRepository.findAll();
		List<Trainee> males = all.stream().filter(t -> t.getGender() == Gender.MALE).collect(Collectors.toList());
		List<Trainee> females = all.stream().filter(t -> t.getGender() == Gender.FEMALE).collect(Collectors.toList());

		if (memberId != null) {
			Set<Long> owned = loadOwnedTraineeIds(memberId);
			males = males.stream().filter(t -> owned.contains(t.getId())).collect(Collectors.toList());
			females = females.stream().filter(t -> owned.contains(t.getId())).collect(Collectors.toList());
		}

		Collections.shuffle(males);
		Collections.shuffle(females);

		List<Trainee> result = new ArrayList<>(4);
		switch (groupType) {
		case MIXED -> {
			if (males.size() < 2 || females.size() < 2) {
				throw new IllegalStateException(memberId != null
						? "혼성 로스터를 만들려면 보유한 남자 연습생 2명 이상, 여자 연습생 2명 이상이 필요합니다. 도감에서 뽑기로 멤버를 확보해 주세요."
						: "혼성 구성에 필요한 연습생이 부족합니다.");
			}
			result.add(males.get(0));
			result.add(males.get(1));
			result.add(females.get(0));
			result.add(females.get(1));
		}
		case MALE -> {
			if (males.size() < 4) {
				throw new IllegalStateException(memberId != null
						? "남자 로스터(4명)를 만들려면 보유한 남자 연습생이 4명 이상 필요합니다."
						: "남자 연습생이 4명 미만입니다.");
			}
			result.addAll(males.subList(0, 4));
		}
		case FEMALE -> {
			if (females.size() < 4) {
				throw new IllegalStateException(memberId != null
						? "여자 로스터(4명)를 만들려면 보유한 여자 연습생이 4명 이상 필요합니다."
						: "여자 연습생이 4명 미만입니다.");
			}
			result.addAll(females.subList(0, 4));
		}
		default -> throw new IllegalArgumentException("지원하지 않는 groupType: " + groupType);
		}
		return result;
	}

	private Set<Long> loadOwnedTraineeIds(Long memberId) {
		if (memberId == null) {
			return new HashSet<>();
		}
		List<MyTrainee> rows = myTraineeRepository.findByMemberIdOrderByIdDesc(memberId);
		return rows.stream().filter(m -> m.getQuantity() > 0).map(MyTrainee::getTraineeId).collect(Collectors.toSet());
	}
}
