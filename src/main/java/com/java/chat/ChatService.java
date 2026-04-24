package com.java.chat;

import java.util.Locale;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Service;

@Service
public class ChatService {

    private final AiClient aiClient;

    private final Map<String, List<ChatMessage>> sessions = new ConcurrentHashMap<>();

    private static final String SYSTEM_PROMPT =
            "당신은 NEXT DEBUT 아이돌 육성 시뮬레이션 사이트의 친절한 안내 AI입니다. 한국어로 짧고 명확하게 답해주세요.";

    public ChatService(AiClient aiClient) {
        this.aiClient = aiClient;
    }

    public String ask(String sessionId, String userMessage) {
        List<ChatMessage> history = sessions.computeIfAbsent(sessionId, k -> {
            List<ChatMessage> list = new ArrayList<>();
            list.add(new ChatMessage("system", SYSTEM_PROMPT));
            return list;
        });

        history.add(new ChatMessage("user", userMessage));

        if (history.size() > 21) {
            history.subList(1, history.size() - 20).clear();
        }

        String reply;
        try {
            reply = aiClient.chat(history);
        } catch (Exception e) {
            reply = null;
        }
        if (shouldUseFallback(reply)) {
            reply = buildFallbackReply(userMessage);
        }
        history.add(new ChatMessage("assistant", reply));
        return reply;
    }

    public void clearSession(String sessionId) {
        sessions.remove(sessionId);
    }

    private boolean shouldUseFallback(String reply) {
        if (reply == null || reply.isBlank()) {
            return true;
        }
        return reply.contains("AI 응답 중 오류가 발생했습니다.")
                || reply.contains("AI 응답을 파싱할 수 없습니다.")
                || reply.contains("Gemini API 오류")
                || reply.contains("AI API 키가 설정되지 않았습니다.");
    }

    private String buildFallbackReply(String userMessage) {
        String msg = userMessage == null ? "" : userMessage.trim();
        String normalized = msg.toLowerCase(Locale.ROOT);

        if (normalized.isBlank()) {
            return "안녕하세요. NEXT DEBUT 안내 도우미예요. 게임 진행, 도감, 캐스팅, 뽑기, 상점, 팬미팅, 랭킹 같은 기능을 물어보시면 바로 설명해드릴게요.";
        }

        if (containsAny(normalized, "안녕", "hi", "hello", "반가", "처음")) {
            return "안녕하세요. NEXT DEBUT 안내 도우미예요. 연습생 육성, 도감, 길거리 캐스팅, 뽑기, 상점, 팬미팅, 랭킹, 마이페이지 중 궁금한 기능을 말씀해 주세요.";
        }

        if (containsAny(normalized, "인게임", "게임", "플레이", "육성", "진행")) {
            return "인게임은 그룹 선택 → 로스터 구성 → 대화 입력 기반 진행으로 이어집니다. 입력한 문장은 예측 로직을 거쳐 스탯과 컨디션 변화에 반영되니, 보컬·댄스·멘탈·팀워크를 균형 있게 관리하는 것이 중요해요.";
        }

        if (containsAny(normalized, "탈락", "컨디션", "피로", "스트레스", "팀워크")) {
            return "탈락을 피하려면 컨디션과 팀워크를 먼저 안정적으로 관리하는 것이 좋아요. 스트레스가 높거나 컨디션이 크게 떨어진 멤버가 있으면 무리한 선택보다 회복 쪽 플레이를 섞어 주는 편이 안전합니다.";
        }

        if (containsAny(normalized, "도감", "연습생", "카드", "해금")) {
            return "도감에서는 연습생 카드의 등급, 성별, 그룹, 능력치를 확인할 수 있어요. 아직 획득하지 못한 연습생은 잠금 상태로 보이고, 해금한 카드만 상세 프로필과 강화 흐름까지 확인할 수 있습니다.";
        }

        if (containsAny(normalized, "포토카드", "강화", "장착")) {
            return "포토카드는 뽑기로 획득한 뒤 연습생에게 장착할 수 있고, 등급에 따라 능력치 보정이 적용됩니다. 중복 카드나 보유 카드를 활용해 강화하면 수집이 성장 요소로 이어져요.";
        }

        if (containsAny(normalized, "캐스팅", "길거리")) {
            return "길거리 캐스팅은 새 연습생을 확보하는 탐색형 콘텐츠예요. 지역을 선택해 탐색하고, 획득한 결과가 이후 도감과 팀 구성 흐름으로 연결됩니다.";
        }

        if (containsAny(normalized, "가챠", "뽑기", "가차")) {
            return "뽑기에서는 연습생과 포토카드를 각각 획득할 수 있어요. 1회, 5회, 10회 뽑기처럼 여러 단위를 지원하고, 결과는 도감과 보유 목록에 바로 반영됩니다.";
        }

        if (containsAny(normalized, "상점", "코인", "카카오페이", "결제", "충전")) {
            return "상점에서는 보컬, 댄스, 스타성, 멘탈, 팀워크에 연결된 아이템을 구매할 수 있어요. 코인은 카카오페이 충전과 연결되어 있고, 아이템 구매와 뽑기 재화로 함께 사용됩니다.";
        }

        if (containsAny(normalized, "팬미팅", "지도", "캘린더", "위치")) {
            return "팬미팅 게시판은 일반 게시판이 아니라 위치와 일정이 함께 관리되는 이벤트형 구조예요. 지도와 캘린더를 통해 모집 상태와 참여 흐름을 한눈에 볼 수 있습니다.";
        }

        if (containsAny(normalized, "랭킹", "순위", "점수")) {
            return "랭킹은 플레이 결과를 점수 기반으로 비교하는 콘텐츠예요. 엔딩 결과와 연결되어 반복 플레이 동기를 주고, 상위 기록을 통해 성장 성과를 확인할 수 있습니다.";
        }

        if (containsAny(normalized, "로그인", "회원가입", "가입", "oauth", "카카오", "구글", "네이버")) {
            return "회원 기능은 일반 회원가입과 로그인뿐 아니라 카카오, 구글, 네이버 소셜 로그인도 지원해요. 회원가입 과정에서는 중복 확인과 이메일 인증, 주소 입력 보조 기능도 함께 제공합니다.";
        }

        if (containsAny(normalized, "마이페이지", "프로필", "내 정보")) {
            return "마이페이지에서는 프로필 정보 수정, 대표 연습생 설정, 보유 코인과 아이템 확인, 최근 플레이 기록 조회까지 한 번에 할 수 있어요.";
        }

        if (containsAny(normalized, "게시판", "공지", "자유", "공략", "신고", "커뮤니티")) {
            return "게시판은 공지, 자유게시판, 공략, 팬미팅, 신고 게시판까지 통합 구조로 운영돼요. 검색과 카테고리 분리가 가능해서 원하는 정보를 빠르게 찾을 수 있습니다.";
        }

        if (containsAny(normalized, "관리자", "admin", "운영")) {
            return "관리자 페이지에서는 회원 상태, 게임 데이터, 연습생/포토카드 자산, 공지와 신고, 팬미팅 운영 현황까지 통합 관리할 수 있어요.";
        }

        return "지금은 게임 전용 안내 모드로 응답하고 있어요. NEXT DEBUT의 인게임, 도감, 캐스팅, 뽑기, 상점, 팬미팅, 랭킹, 마이페이지, 회원가입/로그인 중 궁금한 기능을 구체적으로 적어주시면 그 기능 기준으로 설명해드릴게요.";
    }

    private boolean containsAny(String source, String... keywords) {
        for (String keyword : keywords) {
            if (source.contains(keyword)) {
                return true;
            }
        }
        return false;
    }
}
