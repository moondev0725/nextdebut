package com.java.chat;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 기본 비활성. {@code anthropic.enabled=true} 일 때만 등록(챗봇은 {@link GeminiClient}가 @Primary).
 */
@Component
@ConditionalOnProperty(name = "anthropic.enabled", havingValue = "true")
public class ClaudeClient implements AiClient {

    @Value("${anthropic.api-key:}")
    private String apiKey;

    private static final String MODEL = "claude-haiku-4-5-20251001";
    private final HttpClient http = HttpClient.newHttpClient();

    @Override
    public String chat(List<ChatMessage> messages) {
        if (apiKey == null || apiKey.isBlank()) {
            return "Anthropic API 키가 설정되지 않았습니다.";
        }

        String body = buildRequestBody(messages);
        try {
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create("https://api.anthropic.com/v1/messages"))
                    .header("Content-Type", "application/json")
                    .header("x-api-key", apiKey)
                    .header("anthropic-version", "2023-06-01")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
            return parseContent(res.body());
        } catch (Exception e) {
            return "AI 응답 중 오류가 발생했습니다.";
        }
    }

    private String buildRequestBody(List<ChatMessage> messages) {
        String systemPrompt = "";
        StringBuilder msgs = new StringBuilder();
        boolean first = true;

        for (ChatMessage m : messages) {
            if ("system".equals(m.role())) {
                systemPrompt = escapeJson(m.content());
                continue;
            }
            if (!first) {
                msgs.append(",");
            }
            msgs.append("{\"role\":\"").append(m.role())
                    .append("\",\"content\":\"").append(escapeJson(m.content())).append("\"}");
            first = false;
        }

        return "{"
                + "\"model\":\"" + MODEL + "\","
                + "\"max_tokens\":1024,"
                + "\"system\":\"" + systemPrompt + "\","
                + "\"messages\":[" + msgs + "]"
                + "}";
    }

    private String parseContent(String json) {
        int idx = json.indexOf("\"text\":");
        if (idx == -1) {
            return "응답을 파싱할 수 없습니다.";
        }
        int start = json.indexOf("\"", idx + 7) + 1;
        int end = json.indexOf("\"", start);
        while (end > 0 && json.charAt(end - 1) == '\\') {
            end = json.indexOf("\"", end + 1);
        }
        return json.substring(start, end)
                .replace("\\n", "\n")
                .replace("\\\"", "\"");
    }

    private String escapeJson(String s) {
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }
}
