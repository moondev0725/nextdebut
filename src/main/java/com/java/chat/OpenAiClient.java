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
 * 기본 비활성. {@code openai.enabled=true} 일 때만 등록(챗봇은 {@link GeminiClient}가 @Primary).
 */
@Component
@ConditionalOnProperty(name = "openai.enabled", havingValue = "true")
public class OpenAiClient implements AiClient {

    @Value("${openai.api-key:}")
    private String apiKey;

    @Value("${openai.model:gpt-4o-mini}")
    private String model;

    private final HttpClient http = HttpClient.newHttpClient();

    @Override
    public String chat(List<ChatMessage> messages) {
        if (apiKey == null || apiKey.isBlank()) {
            return "API 키가 설정되지 않았습니다. application.properties에 openai.api-key를 설정해주세요.";
        }

        String body = buildRequestBody(messages);
        try {
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create("https://api.openai.com/v1/chat/completions"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer " + apiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
            return parseContent(res.body());
        } catch (Exception e) {
            return "AI 응답 중 오류가 발생했습니다.";
        }
    }

    private String buildRequestBody(List<ChatMessage> messages) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"model\":\"").append(model).append("\",\"messages\":[");
        for (int i = 0; i < messages.size(); i++) {
            ChatMessage m = messages.get(i);
            sb.append("{\"role\":\"").append(m.role())
                    .append("\",\"content\":\"").append(escapeJson(m.content())).append("\"}");
            if (i < messages.size() - 1) {
                sb.append(",");
            }
        }
        sb.append("]}");
        return sb.toString();
    }

    private String parseContent(String json) {
        int idx = json.indexOf("\"content\":");
        if (idx == -1) {
            return "응답을 파싱할 수 없습니다.";
        }
        int start = json.indexOf("\"", idx + 10) + 1;
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
