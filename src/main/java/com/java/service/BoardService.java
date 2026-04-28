package com.java.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.java.entity.Board;
import com.java.entity.BoardReport;
import com.java.entity.BoardComment;
import com.java.repository.BoardCommentRepository;
import com.java.repository.BoardLikeRepository;
import com.java.repository.BoardReportRepository;
import com.java.repository.BoardRepository;

@Service
public class BoardService {
	public static final String HANDLED_COMMENT_PREFIX = "[처리]";
	public static final String BLINDED_TITLE = "블라인드 처리 된 글";

	private static final int PLACE_NAME_MAX = 200;
	private static final int ADDRESS_MAX = 255;

	private static final Set<String> PARTICIPATION_CODES = Set.of("FIRST_COME", "LOTTERY", "CONTACT", "FREE");

	private static final List<String> NORMAL_BOARD_TYPES = List.of("free", "lounge", "guide", "map");

	private static final DateTimeFormatter DAY_FMT = DateTimeFormatter.ofPattern("MM/dd");

	private final BoardRepository boardRepository;
	private final BoardReportRepository boardReportRepository;
	private final BoardCommentRepository boardCommentRepository;
	private final BoardLikeRepository boardLikeRepository;

	public BoardService(BoardRepository boardRepository, BoardReportRepository boardReportRepository,
			BoardCommentRepository boardCommentRepository, BoardLikeRepository boardLikeRepository) {
		this.boardRepository = boardRepository;
		this.boardReportRepository = boardReportRepository;
		this.boardCommentRepository = boardCommentRepository;
		this.boardLikeRepository = boardLikeRepository;
	}

	public long getTotalBoardCount() {
		return boardRepository.count();
	}

	public long getNoticeCount() {
		return boardRepository.countByBoardType("notice");
	}

	public long getNormalBoardCount() {
		return boardRepository.findAll().stream()
				.filter(b -> NORMAL_BOARD_TYPES.contains(b.getBoardType()))
				.count();
	}

	public long getReportCount() {
		return boardReportRepository.count() + boardRepository.countByBoardType("report");
	}

	public long getBlindedCount() {
		return boardRepository.findAll().stream()
				.filter(b -> !b.isVisible())
				.count();
	}

	public List<Map<String, Object>> getRecentReports(int limit) {
		int safeLimit = Math.max(1, limit);
		List<BoardReport> reports = boardReportRepository.findAllByOrderByCreatedAtDesc();
		Map<Long, Board> boardById = boardRepository.findAllById(reports.stream()
				.filter(r -> "board".equalsIgnoreCase(r.getTargetType()))
				.map(BoardReport::getTargetId)
				.distinct()
				.collect(Collectors.toList())).stream()
				.collect(Collectors.toMap(Board::getId, b -> b));
		Map<Long, Long> reportCountByBoardId = boardReportRepository.findAll().stream()
				.filter(r -> "board".equalsIgnoreCase(r.getTargetType()))
				.collect(Collectors.groupingBy(BoardReport::getTargetId, Collectors.counting()));
		List<Map<String, Object>> rows = new ArrayList<>();
		for (BoardReport report : reports) {
			Board target = boardById.get(report.getTargetId());
			Map<String, Object> row = new LinkedHashMap<>();
			row.put("id", report.getId());
			row.put("reportedAt", report.getCreatedAtStr());
			row.put("reason", report.getReasonLabel());
			row.put("status", report.getStatus());
			row.put("boardId", report.getTargetId());
			row.put("boardTitle", target == null ? "(삭제되었거나 확인 불가)" : target.getTitle());
			row.put("authorNick", target == null ? "-" : target.getAuthorNick());
			row.put("detailPath",
					target == null ? "/admin" : "/boards/" + target.getBoardType() + "/" + target.getId());
			row.put("reportCount", reportCountByBoardId.getOrDefault(report.getTargetId(), 1L));
			row.put("visible", target == null || target.isVisible());
			boolean handled = target != null && isReportHandled(target);
			String workflowStatus = "pending";
			if (handled || "resolved".equalsIgnoreCase(report.getStatus())) {
				workflowStatus = "completed";
			} else if ("processing".equalsIgnoreCase(report.getStatus())) {
				workflowStatus = "processing";
			}
			row.put("workflowStatus", workflowStatus);
			rows.add(row);
		}
		{
			List<Board> reportBoards = boardRepository.findByBoardTypeOrderByCreatedAtDesc("report");
			for (Board reportBoard : reportBoards) {
				boolean handled = isReportHandled(reportBoard);
				Map<String, Object> row = new LinkedHashMap<>();
				row.put("id", reportBoard.getId());
				row.put("reportedAt", reportBoard.getCreatedAtStr());
				row.put("reason", "신고 게시판 접수");
				row.put("status", handled ? "resolved" : "pending");
				row.put("boardId", reportBoard.getId());
				row.put("boardTitle", reportBoard.getTitle());
				row.put("authorNick", reportBoard.getAuthorNick());
				row.put("detailPath", "/boards/report/" + reportBoard.getId());
				row.put("reportCount", 1L);
				row.put("visible", reportBoard.isVisible());
				row.put("workflowStatus", handled ? "completed" : "pending");
				rows.add(row);
			}
		}
		rows.sort((a, b) -> String.valueOf(b.get("reportedAt")).compareTo(String.valueOf(a.get("reportedAt"))));
		if (rows.size() > safeLimit) {
			return new ArrayList<>(rows.subList(0, safeLimit));
		}
		return rows;
	}

	public boolean isReportHandled(Board board) {
		if (board == null) {
			return false;
		}
		if (!board.isVisible()) {
			return true;
		}
		List<BoardComment> comments = boardCommentRepository.findByBoardIdOrderByCreatedAtAsc(board.getId());
		return comments.stream().anyMatch(c -> {
			String content = c.getContent() == null ? "" : c.getContent().trim();
			String authorNick = c.getAuthorNick() == null ? "" : c.getAuthorNick().trim();
			return content.startsWith(HANDLED_COMMENT_PREFIX) || authorNick.contains("관리자");
		});
	}

	public List<Board> getNoticeList(int limit) {
		return boardRepository.findByBoardTypeOrderByCreatedAtDesc("notice").stream()
				.limit(Math.max(1, limit))
				.collect(Collectors.toList());
	}

	public Map<String, Long> getBoardTrend(int days) {
		int safeDays = Math.max(1, days);
		LocalDate today = LocalDate.now();
		Map<String, Long> trend = new LinkedHashMap<>();
		for (int i = safeDays - 1; i >= 0; i--) {
			trend.put(today.minusDays(i).format(DAY_FMT), 0L);
		}
		LocalDateTime from = today.minusDays(safeDays - 1).atStartOfDay();
		boardRepository.findAll().stream()
				.filter(b -> !"report".equalsIgnoreCase(b.getBoardType()))
				.filter(b -> b.getCreatedAt() != null && !b.getCreatedAt().isBefore(from))
				.sorted(Comparator.comparing(Board::getCreatedAt))
				.forEach(b -> trend.computeIfPresent(b.getCreatedAt().toLocalDate().format(DAY_FMT), (k, v) -> v + 1));
		return trend;
	}

	public Map<String, Long> getReportTrend(int days) {
		int safeDays = Math.max(1, days);
		LocalDate today = LocalDate.now();
		Map<String, Long> trend = new LinkedHashMap<>();
		for (int i = safeDays - 1; i >= 0; i--) {
			trend.put(today.minusDays(i).format(DAY_FMT), 0L);
		}
		LocalDateTime from = today.minusDays(safeDays - 1).atStartOfDay();
		boardReportRepository.findAll().stream()
				.filter(r -> r.getCreatedAt() != null && !r.getCreatedAt().isBefore(from))
				.forEach(r -> trend.computeIfPresent(r.getCreatedAt().toLocalDate().format(DAY_FMT), (k, v) -> v + 1));
		boardRepository.findByBoardTypeOrderByCreatedAtDesc("report").stream()
				.filter(b -> b.getCreatedAt() != null && !b.getCreatedAt().isBefore(from))
				.forEach(b -> trend.computeIfPresent(b.getCreatedAt().toLocalDate().format(DAY_FMT), (k, v) -> v + 1));
		return trend;
	}

	public String handleReportAction(Long reportId, String action) {
		if (reportId == null || !StringUtils.hasText(action)) {
			return null;
		}
		BoardReport report = boardReportRepository.findById(reportId).orElse(null);
		Board board = null;
		if (report != null) {
			board = boardRepository.findById(report.getTargetId()).orElse(null);
		} else {
			board = boardRepository.findById(reportId).orElse(null);
			if (board == null || !"report".equalsIgnoreCase(board.getBoardType())) {
				return null;
			}
		}
		String normalized = action.trim().toLowerCase();
		switch (normalized) {
		case "toggleblind" -> {
			if (board != null) {
				boolean nextVisible = !board.isVisible();
				board.setVisible(nextVisible);
				boardRepository.save(board);
				if (report != null) {
					report.setStatus(nextVisible ? "pending" : "resolved");
					boardReportRepository.save(report);
					syncSiblingBoardReports(report, nextVisible ? "pending" : "resolved");
				}
				if (report == null) {
					if (nextVisible) {
						clearAutoHandledMarker(board);
					} else {
						markReportBoardHandled(board);
					}
				}
				return nextVisible ? "게시글 블라인드를 해제했습니다." : "신고 대상 게시글을 블라인드 처리했습니다.";
			}
			return null;
		}
		case "blind" -> {
			if (board != null) {
				board.setVisible(false);
				boardRepository.save(board);
			}
			if (report != null) {
				report.setStatus("resolved");
				boardReportRepository.save(report);
				syncSiblingBoardReports(report, "resolved");
			}
			if (report == null && board != null) {
				clearAutoHandledMarker(board);
			}
			return "신고 대상 게시글을 블라인드 처리했습니다.";
		}
		case "release" -> {
			if (board != null) {
				board.setVisible(true);
				boardRepository.save(board);
			}
			if (report != null) {
				report.setStatus("pending");
				boardReportRepository.save(report);
				syncSiblingBoardReports(report, "pending");
			}
			if (report == null && board != null) {
				markReportBoardHandled(board);
			}
			return "블라인드 게시글을 다시 노출했습니다.";
		}
		case "detail" -> {
			if (report != null) {
				report.setStatus("processing");
				boardReportRepository.save(report);
			}
			return "신고 상세를 확인하세요.";
		}
		case "delete" -> {
			if (board != null && "report".equalsIgnoreCase(board.getBoardType())) {
				return deleteReportBoardPost(board.getId());
			}
			return null;
		}
		default -> {
			return null;
		}
		}
	}

	private void syncSiblingBoardReports(BoardReport anchor, String status) {
		if (anchor == null || !StringUtils.hasText(status) || anchor.getTargetId() == null
				|| !StringUtils.hasText(anchor.getTargetType())) {
			return;
		}
		boardReportRepository.findByTargetTypeAndTargetIdOrderByCreatedAtDesc(anchor.getTargetType(), anchor.getTargetId())
				.stream()
				.filter(sibling -> sibling.getId() != null && !sibling.getId().equals(anchor.getId()))
				.forEach(sibling -> sibling.setStatus(status));
	}

	/**
	 * 관리자 신고 게시판에서 글 삭제 — 댓글·좋아요·해당 게시글로 접수된 신고(BoardReport) 정리 후 삭제합니다.
	 */
	public String deleteReportBoardPost(Long reportBoardId) {
		if (reportBoardId == null) {
			return null;
		}
		Board board = boardRepository.findById(reportBoardId).orElse(null);
		if (board == null || !"report".equalsIgnoreCase(board.getBoardType())) {
			return null;
		}
		boardCommentRepository.deleteByBoardId(reportBoardId);
		boardLikeRepository.deleteByBoardId(reportBoardId);
		boardReportRepository.findByTargetTypeAndTargetIdOrderByCreatedAtDesc("board", reportBoardId)
				.forEach(boardReportRepository::delete);
		boardRepository.delete(board);
		return "신고 게시글을 삭제했습니다.";
	}

	public String maskedBoardTitle(Board board, boolean handled) {
		if (board == null) {
			return "(삭제되었거나 확인 불가)";
		}
		if (!board.isVisible() || handled) {
			return BLINDED_TITLE;
		}
		return board.getTitle();
	}

	private void markReportBoardHandled(Board board) {
		if (board == null || !"report".equalsIgnoreCase(board.getBoardType())) {
			return;
		}
		boolean alreadyHandled = boardCommentRepository.findByBoardIdOrderByCreatedAtAsc(board.getId()).stream()
				.anyMatch(comment -> {
					String content = comment.getContent() == null ? "" : comment.getContent().trim();
					return content.startsWith(HANDLED_COMMENT_PREFIX);
				});
		if (alreadyHandled) {
			return;
		}
		boardCommentRepository.save(new BoardComment(board, HANDLED_COMMENT_PREFIX + " 블라인드 처리", "관리자", null));
	}

	/**
	 * 신고 게시판 글에 [처리] 댓글을 남겨 사용자 목록에서 처리완료로 표시합니다.
	 */
	private void clearAutoHandledMarker(Board board) {
		if (board == null || !"report".equalsIgnoreCase(board.getBoardType())) {
			return;
		}
		boardCommentRepository.findByBoardIdOrderByCreatedAtAsc(board.getId()).stream()
				.filter(comment -> comment.getAuthorMno() == null)
				.filter(comment -> {
					String content = comment.getContent() == null ? "" : comment.getContent().trim();
					return content.startsWith(HANDLED_COMMENT_PREFIX);
				})
				.forEach(boardCommentRepository::delete);
	}

	public String completeReportBoardByAdmin(Long reportBoardId, String adminNick, Long adminMno) {
		if (reportBoardId == null) {
			return null;
		}
		Board board = boardRepository.findById(reportBoardId).orElse(null);
		if (board == null || !"report".equalsIgnoreCase(board.getBoardType())) {
			return null;
		}
		if (isReportHandled(board)) {
			return "이미 처리 완료로 표시된 글입니다.";
		}
		String nick = StringUtils.hasText(adminNick) ? adminNick.trim() : "관리자";
		String line = HANDLED_COMMENT_PREFIX + " 접수 건 처리를 완료했습니다.";
		boardCommentRepository.save(new BoardComment(board, line, nick, adminMno));
		return "처리 코멘트를 등록했습니다.";
	}

	public String addAdminHandlingComment(Long reportId, String content, String adminNick, Long adminMno) {
		if (reportId == null || !StringUtils.hasText(content) || content.trim().length() > 500) {
			return null;
		}
		BoardReport report = boardReportRepository.findById(reportId).orElse(null);
		Board board = null;
		if (report != null) {
			board = boardRepository.findById(report.getTargetId()).orElse(null);
		} else {
			board = boardRepository.findById(reportId).orElse(null);
		}
		if (board == null) {
			return null;
		}
		String nick = StringUtils.hasText(adminNick) ? adminNick.trim() : "관리자";
		String safe = content.trim();
		if (!safe.startsWith(HANDLED_COMMENT_PREFIX)) {
			safe = HANDLED_COMMENT_PREFIX + " " + safe;
		}
		boardCommentRepository.save(new BoardComment(board, safe, nick, adminMno));
		if (report != null && "pending".equalsIgnoreCase(report.getStatus())) {
			report.setStatus("processing");
			boardReportRepository.save(report);
		}
		return "처리 코멘트를 등록했습니다.";
	}

	public String resolveReportDetailPath(Long reportId) {
		BoardReport report = reportId == null ? null : boardReportRepository.findById(reportId).orElse(null);
		Board board = null;
		if (report != null) {
			board = boardRepository.findById(report.getTargetId()).orElse(null);
		} else if (reportId != null) {
			board = boardRepository.findById(reportId).orElse(null);
		}
		if (board == null || !StringUtils.hasText(board.getBoardType())) {
			return "/admin";
		}
		return "/boards/" + board.getBoardType() + "/" + board.getId();
	}

	public String toggleNoticePin(Long noticeId) {
		Board notice = noticeId == null ? null : boardRepository.findById(noticeId).orElse(null);
		if (notice == null || !"notice".equalsIgnoreCase(notice.getBoardType())) {
			return null;
		}
		notice.setPopup(!notice.isPopup());
		boardRepository.save(notice);
		return notice.isPopup() ? "공지를 상단 고정했습니다." : "공지 상단 고정을 해제했습니다.";
	}

	public boolean deleteNotice(Long noticeId) {
		Board notice = noticeId == null ? null : boardRepository.findById(noticeId).orElse(null);
		if (notice == null || !"notice".equalsIgnoreCase(notice.getBoardType())) {
			return false;
		}
		boardRepository.delete(notice);
		return true;
	}

	public LocalDateTime parseEventAtParam(String raw) {
		if (!StringUtils.hasText(raw)) {
			return null;
		}
		try {
			return LocalDateTime.parse(raw.trim());
		} catch (Exception e) {
			return null;
		}
	}

	/** 팬미팅 목록 지도용 마커 JSON (빈 배열 가능) */
	public String buildFanMeetMarkersJson(List<Board> posts) {
		if (posts == null || posts.isEmpty()) {
			return "[]";
		}
		StringBuilder sb = new StringBuilder("[");
		boolean first = true;
		for (Board p : posts) {
			if (!p.isHasMapLocation()) {
				continue;
			}
			if (!first) {
				sb.append(',');
			}
			first = false;
			sb.append("{\"id\":").append(p.getId()).append(",\"lat\":").append(p.getLat()).append(",\"lng\":")
					.append(p.getLng()).append(",\"title\":\"").append(jsonStringEscape(p.getTitle())).append("\"}");
		}
		sb.append(']');
		return sb.toString();
	}

	private static String jsonStringEscape(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "").replace("\n", " ");
	}

	public void applyFanMeetFields(Board board, LocalDateTime eventAt, String recruitStatus, String maxCapParam,
			String participationType) {
		if (board == null) {
			return;
		}
		board.setEventAt(eventAt);
		String status = "RECRUITING";
		if (StringUtils.hasText(recruitStatus)) {
			String normalized = recruitStatus.trim().toUpperCase();
			if ("PLANNED".equals(normalized) || "DONE".equals(normalized) || "RECRUITING".equals(normalized)
					|| "OPEN".equals(normalized) || "CLOSED".equals(normalized)) {
				status = "OPEN".equals(normalized) ? "RECRUITING" : ("CLOSED".equals(normalized) ? "DONE" : normalized);
			}
		}
		board.setRecruitStatus(status);
		if (StringUtils.hasText(maxCapParam)) {
			try {
				int n = Integer.parseInt(maxCapParam.trim());
				board.setMaxCapacity(n > 0 ? Integer.valueOf(n) : null);
			} catch (NumberFormatException e) {
				board.setMaxCapacity(null);
			}
		} else {
			board.setMaxCapacity(null);
		}
		if (StringUtils.hasText(participationType)) {
			String p = participationType.trim().toUpperCase();
			board.setParticipationType(PARTICIPATION_CODES.contains(p) ? p : "FREE");
		} else {
			board.setParticipationType("FREE");
		}
	}

	/**
	 * 장소명·위경도를 게시글에 반영합니다. 값이 비어 있거나 좌표가 유효하지 않으면 장소 필드를 비웁니다.
	 */
	public void applyOptionalLocation(Board board, String placeName, String address, String latStr, String lngStr) {
		if (board == null) {
			return;
		}
		if (!StringUtils.hasText(latStr) || !StringUtils.hasText(lngStr)) {
			board.clearLocation();
			return;
		}
		try {
			double lat = Double.parseDouble(latStr.trim().replace(',', '.'));
			double lng = Double.parseDouble(lngStr.trim().replace(',', '.'));
			if (!isValidLatLng(lat, lng)) {
				board.clearLocation();
				return;
			}
			String name = placeName == null ? "" : placeName.trim();
			if (!StringUtils.hasText(name)) {
				name = "선택한 위치";
			}
			if (name.length() > PLACE_NAME_MAX) {
				name = name.substring(0, PLACE_NAME_MAX);
			}
			String safeAddr = address == null ? "" : address.trim();
			if (safeAddr.length() > ADDRESS_MAX) {
				safeAddr = safeAddr.substring(0, ADDRESS_MAX);
			}
			board.setPlaceName(name);
			board.setAddress(StringUtils.hasText(safeAddr) ? safeAddr : null);
			board.setLat(lat);
			board.setLng(lng);
		} catch (NumberFormatException e) {
			board.clearLocation();
		}
	}

	private static boolean isValidLatLng(double lat, double lng) {
		return Double.isFinite(lat) && Double.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
	}
}
