package com.java.game.ml;

/**
 * 채팅 선택지 ML 미적용(또는 예측기 실패) 사유. 로그·JSONL·관리 지표에서 동일 코드로 집계한다.
 */
public enum MlSkipReason {
	/** app.ml.enabled=false */
	ML_DISABLED,
	/** app.ml.predict-url 비어 있음 */
	ML_PREDICT_URL_MISSING,
	/** HTTP 예외·타임아웃·역직렬화 실패 등 */
	ML_HTTP_OR_PARSE_ERROR,
	/** ML 응답 본문 없음 */
	ML_RESPONSE_EMPTY,
	/** 예측 키가 비어 있거나 파싱 불가 */
	ML_INVALID_PREDICTED_KEY,
	/** 모델이 NONE·모호함으로 RULE 유도 (Python ambiguity 등) */
	ML_AMBIGUOUS_OR_NONE,
	/** 현재 턴 선택지 목록이 비어 있음 */
	CANDIDATES_EMPTY,
	/** 예측 키가 현재 씬 선택지에 없음 */
	PREDICTED_KEY_NOT_IN_SCENE,
	/** 유저 문장에 명시된 스탯 의도와 ML 키가 충돌 */
	EXPLICIT_INTENT_CONFLICT,
	/** 최고 확률·top1-top2 마진 정책을 모두 통과하지 못함 (GameService 설정값 조합) */
	CONFIDENCE_POLICY_REJECT,
	/** 예측 단계에서 분류되지 않은 기타 (방어용) */
	UNKNOWN
}
