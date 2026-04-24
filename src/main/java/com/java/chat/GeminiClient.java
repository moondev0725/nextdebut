package com.java.chat;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

@Component
@Primary
public class GeminiClient implements AiClient {

    /**
     * {@link #generateStructuredResult} 결과. 게임 쪽은 {@link Kind#QUOTA_EXCEEDED}일 때만 DB 저장 지문 폴백을 쓴다.
     */
    public record StructuredGenerateResult(String rawText, Kind kind) {
        public enum Kind {
            /** 모델 텍스트 수신(빈 문자열일 수 있음 — 호출부에서 JSON 파싱 검증) */
            OK,
            /** API 키 없음 */
            NOT_CONFIGURED,
            /** 모든 키가 쿼터(HTTP 429·RESOURCE_EXHAUSTED 등)로만 막힘 */
            QUOTA_EXCEEDED,
            /** 그 외 HTTP 오류·빈 본문·모델 오류 등 */
            OTHER
        }
    }

    private static final Logger log = LoggerFactory.getLogger(GeminiClient.class);

    @Value("${gemini.api-key:}")
    private String apiKey;
    @Value("${gemini.api-key-2:}")
    private String apiKey2;

    /** 챗봇·게임 공통 Gemini 모델 id (예: gemini-2.5-flash). */
    @Value("${gemini.model:gemini-2.5-flash}")
    private String model = "gemini-2.5-flash";

    private HttpClient http = HttpClient.newHttpClient();
    private final ObjectMapper objectMapper;

    public GeminiClient(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    void setHttpClientForTest(HttpClient httpClient) {
        if (httpClient != null) {
            this.http = httpClient;
        }
    }

    /** Gemini API 키만 본다. */
    public boolean isConfigured() {
        return !configuredKeys().isEmpty();
    }

    /**
     * 단발 프롬프트(시스템+유저). {@code jsonMimeType}이면 응답을 JSON으로 강제.
     */
    public String generateStructured(String systemInstruction, String userMessage, double temperature, boolean jsonMimeType) {
        return generateStructured(systemInstruction, userMessage, temperature, jsonMimeType, 8192);
    }

    /**
     * {@code maxOutputTokens}로 출력 상한을 줄이면 짧은 JSON(선택지 키 등) 응답이 더 빨리 끝나는 경우가 많다.
     */
    public String generateStructured(String systemInstruction, String userMessage, double temperature, boolean jsonMimeType,
            int maxOutputTokens) {
        return generateStructuredResult(systemInstruction, userMessage, temperature, jsonMimeType, maxOutputTokens).rawText();
    }

    /**
     * 성공/쿼터/기타 실패를 구분한다. 게임 내레이션은 {@link StructuredGenerateResult.Kind#QUOTA_EXCEEDED}일 때만 DB 폴백을 쓴다.
     */
    public StructuredGenerateResult generateStructuredResult(String systemInstruction, String userMessage, double temperature,
            boolean jsonMimeType, int maxOutputTokens) {
        if (!isConfigured()) {
            return new StructuredGenerateResult("", StructuredGenerateResult.Kind.NOT_CONFIGURED);
        }
        int cap = Math.max(16, Math.min(maxOutputTokens, 8192));
        String sys = systemInstruction == null ? "" : systemInstruction;
        String usr = userMessage == null ? "" : userMessage;
        String systemPart = sys.isBlank() ? "" :
                "\"systemInstruction\":{\"parts\":[{\"text\":\"" + escapeJson(sys) + "\"}]},";
        StringBuilder gen = new StringBuilder();
        gen.append("\"generationConfig\":{\"maxOutputTokens\":").append(cap).append(",\"temperature\":").append(temperature);
        if (jsonMimeType) {
            gen.append(",\"responseMimeType\":\"application/json\"");
        }
        gen.append("}");
        String reqBody = "{" + systemPart + "\"contents\":[{\"role\":\"user\",\"parts\":[{\"text\":\""
                + escapeJson(usr) + "\"}]}]," + gen + "}";
        List<String> keys = configuredKeys();
        boolean anyQuota = false;
        boolean anyNonQuotaFailure = false;
        for (int i = 0; i < keys.size(); i++) {
            String key = keys.get(i);
            try {
                String url = "https://generativelanguage.googleapis.com/v1beta/models/"
                        + model + ":generateContent?key=" + key;
                HttpRequest req = HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(reqBody))
                        .build();
                HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
                int code = res.statusCode();
                String resBody = res.body();

                if (code == 429) {
                    logQuotaExceededKo(i + 1, keys.size());
                    anyQuota = true;
                    continue;
                }

                if (code != 200) {
                    log.warn("Gemini generateStructured HTTP {} — {}", code,
                            resBody != null && resBody.length() > 400 ? resBody.substring(0, 400) + "…" : resBody);
                    anyNonQuotaFailure = true;
                    continue;
                }

                /*
                 * 루트에 candidates가 없고 error 객체만 있을 때만 API 오류로 본다.
                 * (본문 어디에든 "\"error\"" 문자열이 있으면 오인 — 모델이 생성한 JSON/대사에 "error"가 들어가면
                 * 실제로는 200 성공인데 요청을 버리고 DB·최소 폴백으로 가던 버그)
                 */
                try {
                    JsonNode root = objectMapper.readTree(resBody);
                    JsonNode cand = root.path("candidates");
                    boolean hasCandidates = cand.isArray() && !cand.isEmpty();
                    if (!hasCandidates && root.path("error").isObject()) {
                        if (isQuotaErrorPayload(resBody)) {
                            logQuotaExceededKo(i + 1, keys.size());
                            anyQuota = true;
                            continue;
                        }
                        log.warn("Gemini generateStructured: 루트 error 객체 (key {})", i + 1);
                        anyNonQuotaFailure = true;
                        continue;
                    }
                } catch (Exception parseHead) {
                    log.debug("Gemini generateStructured: 응답 JSON 선검사 생략 — {}", parseHead.getMessage());
                }

                String out = parseContent(resBody);
                if (out == null || out.isBlank() || isUnparseableOrErrorOutput(out)) {
                    log.warn("Gemini generateStructured: empty or unparseable model text. Body snippet: {}",
                            resBody != null && resBody.length() > 500 ? resBody.substring(0, 500) + "…" : resBody);
                    anyNonQuotaFailure = true;
                    continue;
                }
                return new StructuredGenerateResult(out, StructuredGenerateResult.Kind.OK);
            } catch (Exception e) {
                log.warn("Gemini generateStructured request failed(key {}): {}", i + 1, e.getMessage());
                anyNonQuotaFailure = true;
            }
        }
        if (anyQuota && !anyNonQuotaFailure) {
            log.warn("Gemini generateStructured: 모든 키 쿼터 초과 — 게임 쪽은 DB 저장 지문 폴백만 사용합니다.");
            return new StructuredGenerateResult("", StructuredGenerateResult.Kind.QUOTA_EXCEEDED);
        }
        log.warn("Gemini generateStructured: 모든 키 시도 후 유효 응답 없음 — DB 저장 지문은 사용하지 않습니다.");
        return new StructuredGenerateResult("", StructuredGenerateResult.Kind.OTHER);
    }

    /** HTTP 200 본문의 루트 error 객체가 쿼터/할당량 관련인지 */
    private boolean isQuotaErrorPayload(String json) {
        if (json == null || json.isBlank()) {
            return false;
        }
        try {
            JsonNode root = objectMapper.readTree(json);
            JsonNode err = root.path("error");
            if (err.isMissingNode() || err.isNull() || !err.isObject()) {
                return false;
            }
            if (json.contains("RESOURCE_EXHAUSTED")) {
                return true;
            }
            int code = err.path("code").asInt(0);
            if (code == 429) {
                return true;
            }
            String status = err.path("status").asString("");
            if (status.contains("RESOURCE_EXHAUSTED")) {
                return true;
            }
            String msg = err.path("message").asString("");
            if (msg.contains("RESOURCE_EXHAUSTED") || msg.contains("quota") || msg.contains("Quota")) {
                return true;
            }
        } catch (Exception ignored) {
        }
        return json.contains("\"code\":429") || json.contains("\"code\": 429");
    }

    private static boolean isUnparseableOrErrorOutput(String out) {
        if (out == null || out.isBlank()) {
            return true;
        }
        if ("응답을 파싱할 수 없습니다.".equals(out)) {
            return true;
        }
        return "Gemini API 오류가 반환되었습니다.".equals(out);
    }

    /** 무료 티어 RPM 등 한도 초과 시 */
    private static void logQuotaExceededKo(int keyOrder, int totalKeys) {
        log.warn(
                "Gemini API {}번 키 할량(쿼터) 초과 — HTTP 429. 총 {}개 키 중 다음 키로 전환합니다. "
                        + "무료 티어는 generate_content 요청 수에 엄격한 제한이 있습니다. "
                        + "인트로·채팅·선택지 해석 등 호출이 겹치면 금방 찹니다. "
                        + "1~2분 뒤 재시도하거나, Google AI Studio에서 유료 플랜·사용량을 확인하세요. "
                        + "https://ai.google.dev/gemini-api/docs/rate-limits",
                keyOrder, totalKeys);
    }

    @Override
    public String chat(List<ChatMessage> messages) {
        List<String> keys = configuredKeys();
        if (keys.isEmpty()) {
            return "AI API 키가 설정되지 않았습니다. application-local.properties에 gemini.api-key를 설정해 주세요.";
        }

        String body = buildRequestBody(messages);
        for (int i = 0; i < keys.size(); i++) {
            String key = keys.get(i);
            try {
                String url = "https://generativelanguage.googleapis.com/v1beta/models/"
                        + model + ":generateContent?key=" + key;

                HttpRequest req = HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(body))
                        .build();

                HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
                if (res.statusCode() == 429) {
                    logQuotaExceededKo(i + 1, keys.size());
                    continue;
                }
                if (res.statusCode() != 200) {
                    return "AI 응답 중 오류가 발생했습니다.";
                }
                return parseContent(res.body());
            } catch (Exception e) {
                log.warn("Gemini chat request failed(key {}): {}", i + 1, e.getMessage());
            }
        }
        return "AI 응답 중 오류가 발생했습니다.";
    }

    private List<String> configuredKeys() {
        List<String> keys = new ArrayList<>();
        if (apiKey != null && !apiKey.isBlank()) {
            keys.add(apiKey.trim());
        }
        if (apiKey2 != null && !apiKey2.isBlank()) {
            keys.add(apiKey2.trim());
        }
        return keys;
    }

    private String buildRequestBody(List<ChatMessage> messages) {
        String systemPrompt = "";
        StringBuilder parts = new StringBuilder();
        boolean first = true;

        for (ChatMessage m : messages) {
            if ("system".equals(m.role())) {
                systemPrompt = escapeJson(m.content());
                continue;
            }
            String geminiRole = "assistant".equals(m.role()) ? "model" : "user";
            if (!first) {
                parts.append(",");
            }
            parts.append("{\"role\":\"").append(geminiRole)
                    .append("\",\"parts\":[{\"text\":\"").append(escapeJson(m.content())).append("\"}]}");
            first = false;
        }

        String systemPart = systemPrompt.isBlank() ? "" :
                "\"systemInstruction\":{\"parts\":[{\"text\":\"" + systemPrompt + "\"}]},";

        // 대사·지문이 길어 잘리면 [대사] 블록이 비어 파싱 실패하므로 토큰 상한을 넉넉히 둔다.
        String gen = "\"generationConfig\":{\"maxOutputTokens\":4096,\"temperature\":0.85}";

        return "{" + systemPart + "\"contents\":[" + parts + "]," + gen + "}";
    }

    private String parseContent(String json) {
        if (json == null || json.isBlank()) {
            return "응답을 파싱할 수 없습니다.";
        }
        try {
            JsonNode root = objectMapper.readTree(json);
            JsonNode candidates = root.path("candidates");
            if (candidates.isArray() && !candidates.isEmpty()) {
                JsonNode parts = candidates.get(0).path("content").path("parts");
                if (parts.isArray()) {
                    StringBuilder sb = new StringBuilder();
                    for (JsonNode p : parts) {
                        if (p.has("text")) {
                            JsonNode textNode = p.get("text");
                            if (textNode != null && !textNode.isNull()) {
                                String text = textNode.toString();
                                if (text != null) {
                                    if (text.startsWith("\"") && text.endsWith("\"") && text.length() >= 2) {
                                        text = text.substring(1, text.length() - 1);
                                    }
                                    text = text.replace("\\n", "\n").replace("\\\"", "\"");
                                    sb.append(text);
                                }
                            }
                        }
                    }
                    if (sb.length() > 0) {
                        return sb.toString();
                    }
                }
            }
            JsonNode err = root.path("error");
            if (err.isObject() && !err.isEmpty()) {
                String msg = tryExtractErrorMessage(json);
                return msg != null ? msg : "Gemini API 오류가 반환되었습니다.";
            }
        } catch (Exception ignored) {
        }
        return legacyExtractText(json);
    }

    private static String tryExtractErrorMessage(String json) {
        try {
            int idx = json.indexOf("\"message\"");
            if (idx < 0) {
                return null;
            }
            int colon = json.indexOf(':', idx);
            if (colon < 0) {
                return null;
            }
            int start = json.indexOf('"', colon + 1);
            if (start < 0) {
                return null;
            }
            start++;
            StringBuilder out = new StringBuilder();
            for (int i = start; i < json.length(); i++) {
                char c = json.charAt(i);
                if (c == '"' && json.charAt(i - 1) != '\\') {
                    break;
                }
                if (c == '\\' && i + 1 < json.length()) {
                    char n = json.charAt(i + 1);
                    if (n == 'n') {
                        out.append('\n');
                        i++;
                        continue;
                    }
                    if (n == '"' || n == '\\') {
                        out.append(n);
                        i++;
                        continue;
                    }
                }
                out.append(c);
            }
            String s = out.toString().trim();
            return s.isEmpty() ? null : s;
        } catch (Exception e) {
            return null;
        }
    }

    /** 첫 번째 "text" 값 (중첩 JSON에서 잘못된 첫 매칭 방지용 보조) */
    private static String legacyExtractText(String json) {
        int anchor = json.indexOf("\"parts\"");
        int idx = anchor >= 0 ? json.indexOf("\"text\":", anchor) : json.indexOf("\"text\":");
        if (idx == -1) {
            return "응답을 파싱할 수 없습니다.";
        }
        int start = json.indexOf("\"", idx + 7) + 1;
        if (start <= 0) {
            return "응답을 파싱할 수 없습니다.";
        }
        StringBuilder out = new StringBuilder();
        for (int i = start; i < json.length(); i++) {
            char c = json.charAt(i);
            if (c == '"' && (i == start || json.charAt(i - 1) != '\\')) {
                break;
            }
            if (c == '\\' && i + 1 < json.length()) {
                char n = json.charAt(i + 1);
                if (n == 'n') {
                    out.append('\n');
                    i++;
                    continue;
                }
                if (n == '"' || n == '\\') {
                    out.append(n);
                    i++;
                    continue;
                }
            }
            out.append(c);
        }
        return out.length() > 0 ? out.toString() : "응답을 파싱할 수 없습니다.";
    }

    private String escapeJson(String s) {
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }
}
