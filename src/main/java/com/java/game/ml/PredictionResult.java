package com.java.game.ml;

import java.util.Map;

public record PredictionResult(
		String predictedKey,
		double confidence,
		Map<String, Double> scoreByKey,
		boolean fallbackRecommended,
		String resolverType,
		MlSkipReason predictorFailureReason
) {
	/**
	 * 예측 서비스 비활성·오류 등으로 ML 출력을 쓸 수 없을 때.
	 */
	public static PredictionResult predictorUnavailable(MlSkipReason reason) {
		return new PredictionResult(null, 0.0, Map.of(), true, "RULE", reason);
	}
}
