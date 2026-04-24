package com.java.game.ml;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.time.Instant;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.java.game.service.SceneResult;

@Component
public class ChatChoiceTrainingLogger {

	private static final Logger log = LoggerFactory.getLogger(ChatChoiceTrainingLogger.class);

	private final Object lock = new Object();
	private final boolean enabled;
	private final Path filePath;

	public ChatChoiceTrainingLogger(
			@Value("${app.ml.training-log-enabled:true}") boolean enabled,
			@Value("${app.ml.training-log-path:python-ml/data/chat_choice_training.jsonl}") String filePath) {
		this.enabled = enabled;
		this.filePath = Paths.get(filePath).toAbsolutePath().normalize();
	}

	public void recordSample(
			String userText,
			Long sceneId,
			String phase,
			List<SceneResult.ChoiceItem> choices,
			String resolvedKey,
			String resolverType,
			String predictedKey,
			double predictionConfidence,
			boolean usedFallback,
			String mlDecisionReason,
			Double scoreMargin) {
		if (!enabled) {
			return;
		}
		try {
			String line = toJsonLine(
					userText,
					sceneId,
					phase,
					choices,
					resolvedKey,
					resolverType,
					predictedKey,
					predictionConfidence,
					usedFallback,
					mlDecisionReason,
					scoreMargin);
			synchronized (lock) {
				Path parent = filePath.getParent();
				if (parent != null) {
					Files.createDirectories(parent);
				}
				Files.writeString(filePath, line, StandardCharsets.UTF_8,
						StandardOpenOption.CREATE, StandardOpenOption.APPEND);
			}
		} catch (Exception ex) {
			log.warn("학습 데이터 로그 저장 실패: {}", ex.getMessage());
		}
	}

	private static String toJsonLine(
			String userText,
			Long sceneId,
			String phase,
			List<SceneResult.ChoiceItem> choices,
			String resolvedKey,
			String resolverType,
			String predictedKey,
			double predictionConfidence,
			boolean usedFallback,
			String mlDecisionReason,
			Double scoreMargin) {
		StringBuilder sb = new StringBuilder(512);
		sb.append('{');
		appendJsonField(sb, "timestamp", Instant.now().toString()).append(',');
		appendJsonField(sb, "userText", safe(userText)).append(',');
		appendJsonNumberField(sb, "sceneId", sceneId).append(',');
		appendJsonField(sb, "phase", safe(phase)).append(',');
		appendJsonField(sb, "resolvedKey", safe(resolvedKey)).append(',');
		appendJsonField(sb, "resolverType", safe(resolverType)).append(',');
		appendJsonField(sb, "predictedKey", safe(predictedKey)).append(',');
		sb.append("\"predictionConfidence\":").append(predictionConfidence).append(',');
		sb.append("\"usedFallback\":").append(usedFallback).append(',');
		appendJsonField(sb, "mlDecisionReason", safe(mlDecisionReason)).append(',');
		if (scoreMargin == null || !Double.isFinite(scoreMargin)) {
			sb.append("\"scoreMargin\":null").append(',');
		} else {
			sb.append("\"scoreMargin\":").append(scoreMargin).append(',');
		}
		sb.append("\"choices\":").append(toChoicesJson(choices));
		sb.append('}').append(System.lineSeparator());
		return sb.toString();
	}

	private static String toChoicesJson(List<SceneResult.ChoiceItem> choices) {
		if (choices == null || choices.isEmpty()) {
			return "[]";
		}
		StringBuilder sb = new StringBuilder();
		sb.append('[');
		for (int i = 0; i < choices.size(); i++) {
			SceneResult.ChoiceItem choice = choices.get(i);
			if (i > 0) {
				sb.append(',');
			}
			sb.append('{');
			appendJsonField(sb, "key", choice == null ? "" : safe(choice.getKey())).append(',');
			appendJsonField(sb, "text", choice == null ? "" : safe(choice.getText())).append(',');
			appendJsonField(sb, "statTarget", choice == null ? "" : safe(choice.getStatTarget()));
			sb.append('}');
		}
		sb.append(']');
		return sb.toString();
	}

	private static StringBuilder appendJsonField(StringBuilder sb, String key, String value) {
		sb.append('"').append(escapeJson(key)).append('"').append(':')
				.append('"').append(escapeJson(value)).append('"');
		return sb;
	}

	private static StringBuilder appendJsonNumberField(StringBuilder sb, String key, Number value) {
		sb.append('"').append(escapeJson(key)).append('"').append(':');
		if (value == null) {
			sb.append("null");
		} else {
			sb.append(value);
		}
		return sb;
	}

	private static String escapeJson(String value) {
		if (value == null) {
			return "";
		}
		StringBuilder out = new StringBuilder(value.length() + 8);
		for (int i = 0; i < value.length(); i++) {
			char c = value.charAt(i);
			switch (c) {
				case '\\' -> out.append("\\\\");
				case '"' -> out.append("\\\"");
				case '\n' -> out.append("\\n");
				case '\r' -> out.append("\\r");
				case '\t' -> out.append("\\t");
				default -> {
					if (c < 0x20) {
						out.append(String.format("\\u%04x", (int) c));
					} else {
						out.append(c);
					}
				}
			}
		}
		return out.toString();
	}

	private static String safe(String value) {
		return value == null ? "" : value;
	}
}
