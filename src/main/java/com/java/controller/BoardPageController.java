package com.java.controller;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.java.config.SessionConst;
import com.java.dto.LoginMember;
import com.java.entity.Board;
import com.java.entity.BoardComment;
import com.java.entity.BoardLike;
import com.java.entity.BoardReport;
import com.java.entity.FanMeetingParticipant;
import com.java.repository.BoardCommentRepository;
import com.java.repository.BoardLikeRepository;
import com.java.repository.BoardReportRepository;
import com.java.repository.BoardRepository;
import com.java.repository.FanMeetingParticipantRepository;
import com.java.casting.CastingMapBoardUi;
import com.java.casting.CastingMapRegions;
import com.java.game.entity.Grade;
import com.java.game.entity.Trainee;
import com.java.game.repository.TraineeRepository;
import com.java.service.BoardService;
import com.java.service.CastingMapService;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/boards")
public class BoardPageController {

	private final BoardRepository boardRepository;
	private final BoardCommentRepository commentRepository;
	private final BoardLikeRepository likeRepository;
	private final BoardReportRepository reportRepository;
	private final FanMeetingParticipantRepository fanMeetingParticipantRepository;
	private final BoardService boardService;
	private final CastingMapService castingMapService;
	private final TraineeRepository traineeRepository;

	public BoardPageController(BoardRepository boardRepository, BoardCommentRepository commentRepository,
			BoardLikeRepository likeRepository, BoardReportRepository reportRepository,
			FanMeetingParticipantRepository fanMeetingParticipantRepository, BoardService boardService,
			CastingMapService castingMapService, TraineeRepository traineeRepository) {
		this.boardRepository = boardRepository;
		this.commentRepository = commentRepository;
		this.likeRepository = likeRepository;
		this.reportRepository = reportRepository;
		this.fanMeetingParticipantRepository = fanMeetingParticipantRepository;
		this.boardService = boardService;
		this.castingMapService = castingMapService;
		this.traineeRepository = traineeRepository;
	}

	private static final Set<String> VALID_TYPES = Set.of("notice", "free", "map", "fanmeeting", "report", "lounge",
			"guide");

	/** /boards/free 목록 — 전체 */
	private static final List<String> COMMUNITY_TYPES_ALL = List.of("free", "lounge", "guide");

	/** 필터: 자유 (구 free + lounge) */
	private static final List<String> COMMUNITY_TYPES_FREE = List.of("free", "lounge");

	/** 필터: 공략 */
	private static final List<String> COMMUNITY_TYPES_GUIDE = List.of("guide");

	private static final int PAGE_SIZE = 10;

	private static final DateTimeFormatter ICS_UTC = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'")
			.withZone(ZoneOffset.UTC);
	private static final DateTimeFormatter ICS_LOCAL = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss");

	@Value("${kakao.map.javascript-key:}")
	private String kakaoMapJavascriptKey;

	@ModelAttribute
	public void addKakaoMapKey(Model model) {
		model.addAttribute("kakaoMapJavascriptKey", kakaoMapJavascriptKey);
	}

	private static final Set<String> IMAGE_EXTS = Set.of("jpg", "jpeg", "jfif", "png", "gif", "webp", "bmp", "svg");

	/** Spring 6에서 제거된 `StringUtils.trimWhitespace` 대체 */
	private static String trimWs(String s) {
		return s == null ? null : s.strip();
	}

	private static final Map<String, String> BOARD_TITLES = Map.of("notice", "공지사항/이벤트", "free", "자유게시판",
			"lounge", "자유게시판", "guide", "공략게시판", "map", "길거리 캐스팅", "fanmeeting", "팬미팅", "report", "버그/신고");

	private static String escapeJsonString(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
	}

	private static String buildCastMapRegionsJson() {
		var list = CastingMapRegions.all();
		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < list.size(); i++) {
			var r = list.get(i);
			if (i > 0) {
				sb.append(',');
			}
			sb.append("{\"id\":\"").append(escapeJsonString(r.id())).append("\",");
			sb.append("\"label\":\"").append(escapeJsonString(r.label())).append("\",");
			sb.append("\"catchCopy\":\"").append(escapeJsonString(r.catchCopy())).append("\",");
			sb.append("\"vibe\":\"").append(escapeJsonString(r.vibe())).append("\",");
			sb.append("\"focusLabel\":\"").append(escapeJsonString(r.focusLabel())).append("\",");
			sb.append("\"pickupType\":\"").append(escapeJsonString(r.pickupType())).append("\",");
			sb.append("\"tip\":\"").append(escapeJsonString(r.tip())).append("\",");
			sb.append("\"lat\":").append(r.lat()).append(",\"lng\":").append(r.lng()).append("}");
		}
		sb.append("]");
		return sb.toString();
	}

	private static String fanMeetingStatusKey(Board b) {
		String rs = b.getRecruitStatus();
		if (rs == null) {
			return "RECRUITING";
		}
		return switch (rs.toUpperCase()) {
			case "PLANNED" -> "PLANNED";
			case "DONE", "CLOSED" -> "DONE";
			case "RECRUITING", "OPEN" -> "RECRUITING";
			default -> "RECRUITING";
		};
	}

	private static String buildFanMeetingMapPostsJson(List<Board> posts, Map<Long, Trainee> traineeMap) {
		if (posts == null || posts.isEmpty()) {
			return "[]";
		}
		StringBuilder sb = new StringBuilder("[");
		boolean first = true;
		for (Board b : posts) {
			if (!b.isHasMapLocation()) {
				continue;
			}
			if (!first) {
				sb.append(',');
			}
			first = false;
			Trainee t = b.getTraineeId() == null ? null : traineeMap.get(b.getTraineeId());
			String thumb = t != null && StringUtils.hasText(t.getImagePath()) ? t.getImagePath() : "";
			sb.append("{\"id\":").append(b.getId())
					.append(",\"lat\":").append(b.getLat())
					.append(",\"lng\":").append(b.getLng())
					.append(",\"traineeId\":").append(b.getTraineeId() == null ? "null" : b.getTraineeId())
					.append(",\"title\":\"").append(escapeJsonString(b.getTitle())).append("\"")
					.append(",\"placeName\":\"").append(escapeJsonString(b.getPlaceName())).append("\"")
					.append(",\"status\":\"").append(escapeJsonString(b.getRecruitStatusLabel())).append("\"")
					.append(",\"statusKey\":\"").append(fanMeetingStatusKey(b)).append("\"")
					.append(",\"date\":\"").append(escapeJsonString(b.getEventAtStr())).append("\"")
					.append(",\"traineeName\":\"").append(escapeJsonString(t != null ? t.getName() : "미지정"))
					.append("\",\"profileImage\":\"").append(escapeJsonString(thumb)).append("\"}");
		}
		sb.append("]");
		return sb.toString();
	}

	@GetMapping("/map/calendar")
	public String fanMeetCalendar(@RequestParam(name = "year", required = false) Integer year,
			@RequestParam(name = "month", required = false) Integer month, Model model) {
		LocalDate now = LocalDate.now();
		int y = year != null ? year : now.getYear();
		int m = month != null ? month : now.getMonthValue();
		if (m < 1) {
			m = 1;
		}
		if (m > 12) {
			m = 12;
		}
		LocalDate first = LocalDate.of(y, m, 1);
		LocalDateTime rangeStart = first.atStartOfDay();
		LocalDateTime rangeEnd = first.plusMonths(1).atStartOfDay();
		List<Board> monthPosts = boardRepository.findMapEventsBetween(rangeStart, rangeEnd);
		Map<String, List<Board>> byDay = monthPosts.stream()
				.filter(b -> b.getEventAt() != null)
				.collect(Collectors.groupingBy(b -> b.getEventAt().toLocalDate().toString(), LinkedHashMap::new,
						Collectors.toList()));

		int leading = first.getDayOfWeek().getValue() - 1;
		List<String> dayKeys = new ArrayList<>();
		for (int d = 1; d <= first.lengthOfMonth(); d++) {
			dayKeys.add(first.withDayOfMonth(d).toString());
		}

		model.addAttribute("boardType", "map");
		model.addAttribute("boardTitle", resolveTitle("map"));
		model.addAttribute("calendarYear", y);
		model.addAttribute("calendarMonth", m);
		model.addAttribute("calendarLeadingBlanks", leading);
		model.addAttribute("calendarDayKeys", dayKeys);
		model.addAttribute("fanMeetByDay", byDay);
		model.addAttribute("fanMeetMonthPosts", monthPosts);
		return "boards/fanmeet-calendar";
	}

	@PostMapping("/map/explore")
	@ResponseBody
	public Map<String, Object> castingMapExplore(@RequestBody(required = false) Map<String, Object> body,
			HttpSession session) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		Long mno = lm != null ? lm.mno() : null;
		String regionId = null;
		if (body != null && body.get("regionId") instanceof String) {
			regionId = (String) body.get("regionId");
		}
		return castingMapService.explore(mno, regionId);
	}

	@GetMapping("/map/{id}/fanmeet.ics")
	public ResponseEntity<String> fanMeetIcs(@PathVariable("id") Long id) {
		return fanMeetIcsForBoard(boardRepository.findById(id).orElse(null), id, "map");
	}

	@GetMapping("/fanmeeting/{id}/fanmeet.ics")
	public ResponseEntity<String> fanMeetIcsFanmeeting(@PathVariable("id") Long id) {
		return fanMeetIcsForBoard(boardRepository.findById(id).orElse(null), id, "fanmeeting");
	}

	private ResponseEntity<String> fanMeetIcsForBoard(Board b, Long id, String expectedType) {
		if (b == null || !expectedType.equals(b.getBoardType()) || b.getEventAt() == null || !b.isFanMeetApproved()
				|| !b.isVisible()) {
			return ResponseEntity.notFound().build();
		}
		String body = buildFanMeetIcs(b);
		return ResponseEntity.ok()
				.header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"fanmeet-" + id + ".ics\"")
				.contentType(MediaType.parseMediaType("text/calendar;charset=UTF-8"))
				.body(body);
	}

	/* 목록 — /boards/search 는 {type}=search 로 매핑되므로, 아래에서 분기 처리 (리다이렉트 방지) */
	@GetMapping("/{type}")
	public String list(@PathVariable("type") String type, @RequestParam(value = "page", defaultValue = "0") int page,
			@RequestParam(value = "filter", required = false) String filter,
			@RequestParam(value = "reportStatus", required = false) String reportStatus,
			@RequestParam(value = "fmStatus", required = false) String fmStatus,
			@RequestParam(value = "q", required = false) String q,
			@RequestParam(value = "scope", required = false) String scope,
			HttpSession session, Model model) {
		if ("search".equals(type)) {
			return renderUnifiedSearch(q, scope, page, session, model);
		}
		int safePageEarly = Math.max(page, 0);
		if ("lounge".equals(type) || "guide".equals(type)) {
			String redirectSuffix = buildFreeListQuery(safePageEarly, filter, q);
			return "redirect:/boards/free" + redirectSuffix;
		}
		if (!VALID_TYPES.contains(type)) {
			return "redirect:/boards/free";
		}
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		boolean admin = isAdmin(lm);

		if ("map".equals(type)) {
			List<Board> posts = boardRepository.findPublicMapBoards("map");
			model.addAttribute("boardType", type);
			model.addAttribute("boardTitle", resolveTitle(type));
			model.addAttribute("posts", posts);
			model.addAttribute("isAdmin", admin);
			model.addAttribute("regions", CastingMapRegions.all());
			model.addAttribute("cmUi", CastingMapBoardUi.KO);
			model.addAttribute("castMapRegionsJson", buildCastMapRegionsJson());
			model.addAttribute("boardSearchQ", "");
			if (lm != null) {
				model.addAttribute("castMap", castingMapService.status(lm.mno()));
			} else {
				model.addAttribute("castMap", Map.of("loggedIn", false));
			}
			return "boards/list";
		}

		if ("fanmeeting".equals(type)) {
			Long traineeFilter = null;
			if (StringUtils.hasText(filter)) {
				try {
					traineeFilter = Long.valueOf(filter.trim());
				} catch (NumberFormatException ignored) {
					traineeFilter = null;
				}
			}
			String sortKey = "popular".equalsIgnoreCase(scope) ? "popular" : "latest";
			if (!isPublicTraineeId(traineeFilter)) {
				traineeFilter = null;
			}
			List<Board> allFiltered = boardRepository.findLocationBoardsForUi("fanmeeting", traineeFilter, sortKey).stream()
					.filter(p -> isPublicTraineeId(p.getTraineeId()))
					.filter(p -> {
						if (!StringUtils.hasText(fmStatus) || "all".equalsIgnoreCase(fmStatus)) {
							return true;
						}
						if ("recruiting".equalsIgnoreCase(fmStatus)) {
							return !"DONE".equalsIgnoreCase(p.getRecruitStatus()) && !"CLOSED".equalsIgnoreCase(p.getRecruitStatus());
						}
						if ("done".equalsIgnoreCase(fmStatus)) {
							return "DONE".equalsIgnoreCase(p.getRecruitStatus()) || "CLOSED".equalsIgnoreCase(p.getRecruitStatus());
						}
						return true;
					})
					.toList();
			int fmPageSize = 5;
			int fmTotal = allFiltered.size();
			int fmTotalPages = Math.max(1, (int) Math.ceil(fmTotal / (double) fmPageSize));
			int fmPage = Math.min(Math.max(safePageEarly, 0), fmTotalPages - 1);
			int fmFrom = fmPage * fmPageSize;
			int fmTo = Math.min(fmFrom + fmPageSize, fmTotal);
			List<Board> posts = fmFrom >= fmTotal ? List.of() : allFiltered.subList(fmFrom, fmTo);
			List<Trainee> trainees = traineeRepository.findAll().stream()
					.filter(this::isPublicTrainee)
					.sorted((a, b) -> {
						if (a.getName() == null && b.getName() == null) {
							return 0;
						}
						if (a.getName() == null) {
							return 1;
						}
						if (b.getName() == null) {
							return -1;
						}
						return a.getName().compareToIgnoreCase(b.getName());
					})
					.toList();
			Map<Long, Trainee> traineeMap = trainees.stream()
					.collect(Collectors.toMap(Trainee::getId, t -> t));
			model.addAttribute("boardType", type);
			model.addAttribute("boardTitle", resolveTitle(type));
			model.addAttribute("posts", posts);
			model.addAttribute("isAdmin", admin);
			model.addAttribute("mapSort", sortKey);
			model.addAttribute("mapTraineeFilter", traineeFilter);
			model.addAttribute("fanMeetingStatusFilter", StringUtils.hasText(fmStatus) ? fmStatus.toLowerCase() : "all");
			model.addAttribute("trainees", trainees);
			model.addAttribute("traineeMap", traineeMap);
			model.addAttribute("fanMeetingMapJson", buildFanMeetingMapPostsJson(posts, traineeMap));
			model.addAttribute("currentPage", fmPage);
			model.addAttribute("totalPages", fmTotalPages);
			model.addAttribute("totalItems", (long) fmTotal);
			model.addAttribute("pageSize", fmPageSize);
			model.addAttribute("loginMember", lm);
			if (lm != null) {
				model.addAttribute("castMap", castingMapService.status(lm.mno()));
			} else {
				model.addAttribute("castMap", Map.of("loggedIn", false));
			}
			return "boards/list";
		}

		String kw = normalizeBoardSearchKeyword(q);
		boolean searching = StringUtils.hasText(kw);

		int safePage = Math.max(page, 0);
		Pageable pageable = PageRequest.of(safePage, PAGE_SIZE);
		Page<Board> boardPage;
		if ("free".equals(type)) {
			List<String> communitySlice = resolveCommunityTypes(filter);
			String filterAttr = resolveCommunityFilterKey(filter);
			model.addAttribute("communityFilter", filterAttr);
			if (searching) {
				boardPage = searchBoardPage(kw, communitySlice, admin, lm, pageable);
			} else if (admin) {
				boardPage = boardRepository.findByBoardTypeInOrderByCreatedAtDesc(communitySlice, pageable);
			} else if (lm != null) {
				boardPage = boardRepository.findVisibleByBoardTypesIn(communitySlice, lm.mno(), pageable);
			} else {
				boardPage = boardRepository.findByBoardTypeInAndSecretFalseOrderByCreatedAtDesc(communitySlice, pageable);
			}
		} else if (searching) {
			boardPage = searchBoardPage(kw, List.of(type), admin, lm, pageable);
		} else if ("report".equals(type) && StringUtils.hasText(reportStatus)
				&& ("pending".equalsIgnoreCase(reportStatus) || "completed".equalsIgnoreCase(reportStatus))) {
			String sf = reportStatus.trim().toLowerCase();
			List<Board> allReport = boardRepository.findByBoardTypeOrderByCreatedAtDesc(type);
			List<Board> filtered = allReport.stream()
					.filter(b -> {
						boolean h = boardService.isReportHandled(b);
						return "pending".equals(sf) ? !h : h;
					})
					.collect(Collectors.toList());
			long total = filtered.size();
			int from = safePage * PAGE_SIZE;
			int to = Math.min(from + PAGE_SIZE, (int) total);
			List<Board> slice = from >= total ? List.of() : filtered.subList(from, to);
			boardPage = new PageImpl<>(slice, pageable, total);
		} else if (admin) {
			boardPage = boardRepository.findByBoardTypeOrderByCreatedAtDesc(type, pageable);
		} else if (lm != null) {
			boardPage = boardRepository.findVisibleByBoardType(type, lm.mno(), pageable);
		} else {
			boardPage = boardRepository.findByBoardTypeAndSecretFalseOrderByCreatedAtDesc(type, pageable);
		}

		model.addAttribute("boardType", type);
		model.addAttribute("boardTitle", resolveTitle(type));
		model.addAttribute("posts", boardPage.getContent());
		model.addAttribute("currentPage", boardPage.getNumber());
		model.addAttribute("totalPages", boardPage.getTotalPages());
		model.addAttribute("totalItems", boardPage.getTotalElements());
		model.addAttribute("pageSize", PAGE_SIZE);
		model.addAttribute("isAdmin", admin);
		model.addAttribute("loginMember", lm);
		model.addAttribute("boardSearchQ", searching ? kw : "");
		if ("report".equals(type)) {
			String statusFilter = "all";
			if ("pending".equalsIgnoreCase(reportStatus) || "completed".equalsIgnoreCase(reportStatus)) {
				statusFilter = reportStatus.toLowerCase();
			}
			Map<Long, Boolean> reportHandledMap = new LinkedHashMap<>();
			Map<Long, String> reportDisplayTitleMap = new LinkedHashMap<>();
			for (Board p : boardPage.getContent()) {
				boolean handled = boardService.isReportHandled(p);
				reportHandledMap.put(p.getId(), handled);
				reportDisplayTitleMap.put(p.getId(), boardService.maskedBoardTitle(p, handled));
			}
			model.addAttribute("reportHandledMap", reportHandledMap);
			model.addAttribute("reportDisplayTitleMap", reportDisplayTitleMap);
			model.addAttribute("reportStatusFilter", statusFilter);
		}
		return "boards/list";
	}

	/** 통합 검색 — /boards/search → {type}=search 로 들어오므로 list 에서 호출 */
	private String renderUnifiedSearch(String q, String scope, int page, HttpSession session, Model model) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		boolean admin = isAdmin(lm);
		String kw = normalizeBoardSearchKeyword(q);
		int safePage = Math.max(page, 0);
		Pageable pageable = PageRequest.of(safePage, PAGE_SIZE);
		List<String> types = resolveSearchScopeTypes(scope);

		model.addAttribute("boardType", "search");
		model.addAttribute("boardTitle", "통합 검색");
		model.addAttribute("searchScope", resolveSearchScopeKey(scope));
		model.addAttribute("communityFilter", "all");
		model.addAttribute("isAdmin", admin);
		model.addAttribute("loginMember", lm);
		model.addAttribute("boardSearchQ", kw);

		if (!StringUtils.hasText(kw)) {
			model.addAttribute("posts", List.of());
			model.addAttribute("currentPage", 0);
			model.addAttribute("totalPages", 0);
			model.addAttribute("totalItems", 0L);
			model.addAttribute("pageSize", PAGE_SIZE);
			return "boards/list";
		}

		Page<Board> boardPage = searchBoardPage(kw, types, admin, lm, pageable);
		model.addAttribute("posts", boardPage.getContent());
		model.addAttribute("currentPage", boardPage.getNumber());
		model.addAttribute("totalPages", boardPage.getTotalPages());
		model.addAttribute("totalItems", boardPage.getTotalElements());
		model.addAttribute("pageSize", PAGE_SIZE);
		return "boards/list";
	}

	private static String buildFreeListQuery(int page, String filter, String searchKeyword) {
		StringBuilder sb = new StringBuilder();
		boolean hasParam = false;
		if (page > 0) {
			sb.append(hasParam ? '&' : '?').append("page=").append(page);
			hasParam = true;
		}
		String fk = resolveCommunityFilterKey(filter);
		if (!"all".equals(fk)) {
			sb.append(hasParam ? '&' : '?').append("filter=").append(fk);
			hasParam = true;
		}
		String skw = normalizeBoardSearchKeyword(searchKeyword);
		if (StringUtils.hasText(skw)) {
			sb.append(hasParam ? '&' : '?').append("q=").append(URLEncoder.encode(skw, StandardCharsets.UTF_8));
		}
		return sb.toString();
	}

	/** filter 요청값 → all | free | guide */
	private static String resolveCommunityFilterKey(String filter) {
		if (!StringUtils.hasText(filter)) {
			return "all";
		}
		String f = filter.trim().toLowerCase();
		if ("guide".equals(f) || "공략".equals(filter.trim())) {
			return "guide";
		}
		if ("free".equals(f) || "lounge".equals(f) || "자유".equals(filter.trim())) {
			return "free";
		}
		return "all";
	}

	private static List<String> resolveCommunityTypes(String filter) {
		return switch (resolveCommunityFilterKey(filter)) {
			case "free" -> COMMUNITY_TYPES_FREE;
			case "guide" -> COMMUNITY_TYPES_GUIDE;
			default -> COMMUNITY_TYPES_ALL;
		};
	}

	/* 글쓰기 폼 */
	@GetMapping("/{type}/write")
	public String writeForm(@PathVariable("type") String type, HttpSession session, Model model) {
		if ("lounge".equals(type) || "guide".equals(type)) {
			return "redirect:/boards/free/write";
		}
		if (!VALID_TYPES.contains(type)) {
			return "redirect:/boards/free";
		}
		if (session.getAttribute(SessionConst.LOGIN_MEMBER) == null) {
			return "redirect:/login?redirect=/boards/" + type + "/write";
		}
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if ("notice".equals(type) && !isAdmin(lm)) {
			return "redirect:/boards/notice?error=관리자만 공지사항을 작성할 수 있습니다.";
		}
		model.addAttribute("boardType", type);
		model.addAttribute("boardTitle", resolveTitle(type));
		model.addAttribute("isAdmin", isAdmin(lm));
		if ("map".equals(type) || "fanmeeting".equals(type)) {
			model.addAttribute("trainees", loadPublicTrainees());
		}
		return "boards/write";
	}

	/* 글쓰기 제출 */
	@PostMapping("/{type}/write")
	public String writeSubmit(@PathVariable("type") String type, @RequestParam("title") String title,
			@RequestParam("content") String content,
			@RequestParam(value = "category", required = false) String category,
			@RequestParam(value = "communityKind", required = false) String communityKind,
			@RequestParam(value = "secret", defaultValue = "false") boolean secret,
			@RequestParam(value = "file", required = false) MultipartFile file,
			@RequestParam(value = "traineeId", required = false) String traineeIdParam,
			@RequestParam(value = "placeName", required = false) String placeName,
			@RequestParam(value = "address", required = false) String address,
			@RequestParam(value = "lat", required = false) String lat,
			@RequestParam(value = "lng", required = false) String lng,
			@RequestParam(value = "eventAt", required = false) String eventAtParam,
			@RequestParam(value = "recruitStatus", required = false) String recruitStatus,
			@RequestParam(value = "maxCapacity", required = false) String maxCapacityParam,
			@RequestParam(value = "participationType", required = false) String participationType,
			HttpSession session, RedirectAttributes ra) throws IOException {
		if (!VALID_TYPES.contains(type)) {
			return "redirect:/boards/free";
		}
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login?redirect=/boards/" + type + "/write";
		}
		if ("notice".equals(type) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "관리자만 공지사항을 작성할 수 있습니다.");
			return "redirect:/boards/notice";
		}

		String safeTitle = trimWs(title);
		String safeContent = trimWs(content);
		if (!StringUtils.hasText(safeTitle)) {
			ra.addFlashAttribute("error", "제목을 입력해주세요.");
			return "redirect:/boards/" + type + "/write";
		}
		if (!StringUtils.hasText(safeContent)) {
			ra.addFlashAttribute("error", "내용을 입력해주세요.");
			return "redirect:/boards/" + type + "/write";
		}

		String originalFilename = null;
		String storedFilename = null;
		boolean image = false;
		if (file != null && !file.isEmpty()) {
			originalFilename = sanitizeFilename(file.getOriginalFilename());
			storedFilename = storeUpload(file, originalFilename);
			String ext = StringUtils.getFilenameExtension(originalFilename);
			image = ext != null && IMAGE_EXTS.contains(ext.toLowerCase());
		}

		if (!"map".equals(type) && !"fanmeeting".equals(type)) {
			String safeCategory = null;
			if ("report".equals(type) && StringUtils.hasText(category)) {
				safeCategory = Set.of("bug", "report").contains(category) ? category : null;
			}
			String storageType = type;
			if ("free".equals(type)) {
				String kind = communityKind == null ? "lounge" : trimWs(communityKind);
				storageType = "guide".equals(kind) ? "guide" : "lounge";
			}
			boolean useSecret = secret && !"notice".equals(type);
			boardRepository.save(new Board(storageType, safeCategory, safeTitle, safeContent, originalFilename, storedFilename,
					image, lm.nickname(), lm.mno(), useSecret));
			ra.addFlashAttribute("success", "글이 등록되었습니다.");
			return "redirect:/boards/" + ("free".equals(type) ? "free" : type);
		}

		Board board = new Board(type, safeTitle, safeContent, originalFilename, storedFilename, image, lm.nickname());
		board.setAuthorMno(lm.mno());
		boardService.applyOptionalLocation(board, placeName, address, lat, lng);
		if (StringUtils.hasText(traineeIdParam)) {
			try {
				board.setTraineeId(Long.valueOf(traineeIdParam.trim()));
			} catch (NumberFormatException ignored) {
				board.setTraineeId(null);
			}
		}
		if (board.getTraineeId() != null && !isPublicTraineeId(board.getTraineeId())) {
			board.setTraineeId(null);
		}

		LocalDateTime ev = boardService.parseEventAtParam(eventAtParam);
		if (ev == null) {
			ra.addFlashAttribute("error", "모임 일시를 입력해주세요.");
			return "redirect:/boards/" + type + "/write";
		}
		if (!board.isHasMapLocation()) {
			ra.addFlashAttribute("error", "장소를 검색하여 선택해주세요.");
			return "redirect:/boards/" + type + "/write";
		}
		if ("fanmeeting".equals(type) && board.getTraineeId() == null) {
			ra.addFlashAttribute("error", "연습생을 선택해주세요.");
			return "redirect:/boards/" + type + "/write";
		}
		boardService.applyFanMeetFields(board, ev, recruitStatus, maxCapacityParam, participationType);
		if ("fanmeeting".equals(type)) {
			// 팬미팅은 등록 즉시 목록/지도 노출
			board.setFanMeetApproved(true);
		} else {
			board.setFanMeetApproved(false);
		}

		boardRepository.save(board);
		if ("fanmeeting".equals(type)) {
			ra.addFlashAttribute("success", "팬미팅 글이 등록되었습니다.");
		} else {
			ra.addFlashAttribute("success", "등록되었습니다. 관리자 승인 후 목록에 공개됩니다.");
		}
		return "redirect:/boards/" + type;
	}

	/* 상세보기 (조회수 증가) */
	@GetMapping("/{type}/{id}")
	@Transactional
	public String view(@PathVariable("type") String type, @PathVariable("id") Long id, HttpSession session, Model model,
			RedirectAttributes ra) {
		Board post = boardRepository.findById(id).orElse(null);
		if (post == null || !post.getBoardType().equals(type)) {
			model.addAttribute("error", "게시글을 찾을 수 없습니다.");
			model.addAttribute("boardType", type);
			model.addAttribute("boardTitle", resolveTitle(type));
			return "boards/list";
		}

		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		boolean admin = isAdmin(lm);
		if (!"map".equals(type) && !"fanmeeting".equals(type) && post.isSecret()) {
			boolean isAuthor = lm != null && lm.mno() != null && lm.mno().equals(post.getAuthorMno());
			if (!isAuthor && !admin) {
				ra.addFlashAttribute("error", "비밀글은 작성자 본인 또는 관리자만 열람할 수 있습니다.");
				return "redirect:/boards/" + type;
			}
		}
		if (!canAccessBoardPost(post, lm)) {
			String err = "fanmeeting".equals(post.getBoardType())
					? "승인 대기 중이거나 비공개인 팬미팅 글입니다."
					: ("map".equals(post.getBoardType())
							? "승인 대기 중이거나 비공개인 캐스팅 이벤트 글입니다."
							: "블라인드 처리되었거나 비공개인 게시글입니다.");
			ra.addFlashAttribute("error", err);
			return "redirect:/boards/" + type;
		}

		post.incrementViewCount();
		boardRepository.save(post);

		List<BoardComment> comments = commentRepository.findByBoardIdOrderByCreatedAtAsc(id);
		boolean liked = lm != null && likeRepository.existsByBoardIdAndMno(id, lm.mno());

		model.addAttribute("boardType", type);
		model.addAttribute("boardTitle", resolveTitle(type));
		model.addAttribute("post", post);
		model.addAttribute("comments", comments);
		model.addAttribute("liked", liked);
		model.addAttribute("loginMember", lm);
		model.addAttribute("isAdmin", admin);
		if ("fanmeeting".equals(type)) {
			List<FanMeetingParticipant> participants = fanMeetingParticipantRepository.findByPostIdOrderByCreatedAtAsc(id);
			long pickedCount = participants.stream().filter(p -> "PICKED".equalsIgnoreCase(p.getStatus())).count();
			model.addAttribute("fanMeetingParticipants", participants);
			model.addAttribute("fanMeetingPickedCount", pickedCount);
			model.addAttribute("fanMeetingAppliedCount", participants.size());
			model.addAttribute("fanMeetingHost", isFanMeetingHost(post, lm));
		}
		if (("map".equals(type) || "fanmeeting".equals(type)) && post.getTraineeId() != null) {
			model.addAttribute("postTrainee", traineeRepository.findById(post.getTraineeId())
					.filter(this::isPublicTrainee)
					.orElse(null));
		}
		return "boards/detail";
	}

	@PostMapping("/fanmeeting/{id}/participants/apply")
	@Transactional
	public String applyFanMeeting(@PathVariable("id") Long id, HttpSession session, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login?redirect=/boards/fanmeeting/" + id;
		}
		Board post = boardRepository.findById(id).orElse(null);
		if (post == null || !"fanmeeting".equals(post.getBoardType())) {
			ra.addFlashAttribute("error", "팬미팅 글을 찾을 수 없습니다.");
			return "redirect:/boards/fanmeeting";
		}
		if ("DONE".equalsIgnoreCase(post.getRecruitStatus()) || "CLOSED".equalsIgnoreCase(post.getRecruitStatus())) {
			ra.addFlashAttribute("error", "마감된 팬미팅입니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		if (fanMeetingParticipantRepository.existsByPostIdAndUserId(id, lm.mno())) {
			ra.addFlashAttribute("error", "이미 참여 신청한 팬미팅입니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		long applied = fanMeetingParticipantRepository.countByPostId(id);
		if ("FIRST_COME".equalsIgnoreCase(post.getParticipationType()) && post.getMaxCapacity() != null
				&& applied >= post.getMaxCapacity()) {
			ra.addFlashAttribute("error", "현재 정원이 가득 찼습니다. 호스트가 정리 후 다시 모집할 수 있습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		String initialStatus = "CONTACT".equalsIgnoreCase(post.getParticipationType()) ? "WAITING" : "APPLIED";
		fanMeetingParticipantRepository.save(new FanMeetingParticipant(id, lm.mno(), lm.nickname(), initialStatus));
		ra.addFlashAttribute("success", "참여 신청이 완료되었습니다.");
		return "redirect:/boards/fanmeeting/" + id;
	}

	@PostMapping("/fanmeeting/{id}/lottery-draw")
	@Transactional
	public String drawFanMeetingLottery(@PathVariable("id") Long id, HttpSession session, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login?redirect=/boards/fanmeeting/" + id;
		}
		Board post = boardRepository.findById(id).orElse(null);
		if (post == null || !"fanmeeting".equals(post.getBoardType())) {
			ra.addFlashAttribute("error", "팬미팅 글을 찾을 수 없습니다.");
			return "redirect:/boards/fanmeeting";
		}
		if (!isFanMeetingHost(post, lm) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "글쓴이 또는 관리자만 추첨할 수 있습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		if (!"LOTTERY".equalsIgnoreCase(post.getParticipationType())) {
			ra.addFlashAttribute("error", "추첨 방식 글에서만 일괄 추첨할 수 있습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		List<FanMeetingParticipant> participants = fanMeetingParticipantRepository.findByPostIdOrderByCreatedAtAsc(id);
		List<FanMeetingParticipant> candidates = participants.stream()
				.filter(p -> !"PICKED".equalsIgnoreCase(p.getStatus()))
				.collect(Collectors.toCollection(ArrayList::new));
		if (candidates.isEmpty()) {
			ra.addFlashAttribute("error", "추첨할 신청자가 없습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		Collections.shuffle(candidates);
		int pickCount = post.getMaxCapacity() != null && post.getMaxCapacity() > 0
				? Math.min(post.getMaxCapacity(), candidates.size())
				: candidates.size();
		for (int i = 0; i < candidates.size(); i++) {
			candidates.get(i).setStatus(i < pickCount ? "PICKED" : "APPLIED");
		}
		fanMeetingParticipantRepository.saveAll(candidates);
		ra.addFlashAttribute("success", "일괄 추첨 완료: " + pickCount + "명 선정");
		return "redirect:/boards/fanmeeting/" + id;
	}

	@PostMapping("/fanmeeting/{id}/participants/{pid}/pick")
	@Transactional
	public String pickFanMeetingParticipant(@PathVariable("id") Long id, @PathVariable("pid") Long pid,
			HttpSession session, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login?redirect=/boards/fanmeeting/" + id;
		}
		Board post = boardRepository.findById(id).orElse(null);
		FanMeetingParticipant participant = fanMeetingParticipantRepository.findById(pid).orElse(null);
		if (post == null || participant == null || !"fanmeeting".equals(post.getBoardType())
				|| !id.equals(participant.getPostId())) {
			ra.addFlashAttribute("error", "참여 신청 정보를 찾을 수 없습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		if (!isFanMeetingHost(post, lm) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "글쓴이 또는 관리자만 참여자를 선정할 수 있습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		participant.setStatus("PICKED");
		fanMeetingParticipantRepository.save(participant);
		ra.addFlashAttribute("success", "참여자를 선정했습니다.");
		return "redirect:/boards/fanmeeting/" + id;
	}

	@PostMapping("/fanmeeting/{id}/participants/{pid}/approve")
	@Transactional
	public String approveFanMeetingParticipant(@PathVariable("id") Long id, @PathVariable("pid") Long pid,
			HttpSession session, RedirectAttributes ra) {
		return updateContactParticipantStatus(id, pid, "APPROVED", session, ra);
	}

	@PostMapping("/fanmeeting/{id}/participants/{pid}/wait")
	@Transactional
	public String waitFanMeetingParticipant(@PathVariable("id") Long id, @PathVariable("pid") Long pid,
			HttpSession session, RedirectAttributes ra) {
		return updateContactParticipantStatus(id, pid, "WAITING", session, ra);
	}

	private String updateContactParticipantStatus(Long id, Long pid, String status, HttpSession session,
			RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login?redirect=/boards/fanmeeting/" + id;
		}
		Board post = boardRepository.findById(id).orElse(null);
		FanMeetingParticipant participant = fanMeetingParticipantRepository.findById(pid).orElse(null);
		if (post == null || participant == null || !"fanmeeting".equals(post.getBoardType())
				|| !id.equals(participant.getPostId())) {
			ra.addFlashAttribute("error", "참여 신청 정보를 찾을 수 없습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		if (!"CONTACT".equalsIgnoreCase(post.getParticipationType())) {
			ra.addFlashAttribute("error", "문의형 글에서만 승인/대기 처리를 할 수 있습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		if (!isFanMeetingHost(post, lm) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "글쓴이 또는 관리자만 처리할 수 있습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		participant.setStatus(status);
		fanMeetingParticipantRepository.save(participant);
		ra.addFlashAttribute("success", "참여 상태를 변경했습니다.");
		return "redirect:/boards/fanmeeting/" + id;
	}

	@PostMapping("/fanmeeting/{id}/participants/{pid}/delete")
	@Transactional
	public String deleteFanMeetingParticipant(@PathVariable("id") Long id, @PathVariable("pid") Long pid,
			HttpSession session, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login?redirect=/boards/fanmeeting/" + id;
		}
		Board post = boardRepository.findById(id).orElse(null);
		FanMeetingParticipant participant = fanMeetingParticipantRepository.findById(pid).orElse(null);
		if (post == null || participant == null || !"fanmeeting".equals(post.getBoardType())
				|| !id.equals(participant.getPostId())) {
			ra.addFlashAttribute("error", "참여 신청 정보를 찾을 수 없습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		boolean selfDelete = lm.mno().equals(participant.getUserId());
		if (!selfDelete && !isFanMeetingHost(post, lm) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "삭제 권한이 없습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		fanMeetingParticipantRepository.delete(participant);
		ra.addFlashAttribute("success", selfDelete ? "참여 신청을 취소했습니다." : "참여자를 명단에서 제외했습니다.");
		return "redirect:/boards/fanmeeting/" + id;
	}

	@PostMapping("/fanmeeting/{id}/close")
	@Transactional
	public String closeFanMeetingRecruit(@PathVariable("id") Long id, HttpSession session, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login?redirect=/boards/fanmeeting/" + id;
		}
		Board post = boardRepository.findById(id).orElse(null);
		if (post == null || !"fanmeeting".equals(post.getBoardType())) {
			ra.addFlashAttribute("error", "팬미팅 글을 찾을 수 없습니다.");
			return "redirect:/boards/fanmeeting";
		}
		if (!isFanMeetingHost(post, lm) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "글쓴이 또는 관리자만 마감 처리할 수 있습니다.");
			return "redirect:/boards/fanmeeting/" + id;
		}
		post.setRecruitStatus("DONE");
		boardRepository.save(post);
		ra.addFlashAttribute("success", "팬미팅 모집을 마감 처리했습니다.");
		return "redirect:/boards/fanmeeting/" + id;
	}

	/* 글 수정 폼 */
	@GetMapping("/{type}/{id}/edit")
	public String editForm(@PathVariable("type") String type, @PathVariable("id") Long id, HttpSession session,
			Model model, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login";
		}

		Board post = boardRepository.findById(id).orElse(null);
		if (post == null || !post.getBoardType().equals(type)) {
			ra.addFlashAttribute("error", "게시글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if ("notice".equals(type) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "공지사항은 관리자만 수정할 수 있습니다.");
			return "redirect:/boards/notice/" + id;
		}
		if (!post.getAuthorNick().equals(lm.nickname()) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "본인 글만 수정할 수 있습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}

		model.addAttribute("boardType", type);
		model.addAttribute("boardTitle", resolveTitle(type));
		model.addAttribute("post", post);
		model.addAttribute("isAdmin", isAdmin(lm));
		if ("map".equals(type) || "fanmeeting".equals(type)) {
			model.addAttribute("trainees", loadPublicTrainees());
		}
		return "boards/edit";
	}

	/* 글 수정 제출 */
	@PostMapping("/{type}/{id}/edit")
	@Transactional
	public String editSubmit(@PathVariable("type") String type, @PathVariable("id") Long id,
			@RequestParam("title") String title, @RequestParam("content") String content,
			@RequestParam(value = "secret", defaultValue = "false") boolean secret,
			@RequestParam(value = "traineeId", required = false) String traineeIdParam,
			@RequestParam(value = "placeName", required = false) String placeName,
			@RequestParam(value = "address", required = false) String address,
			@RequestParam(value = "lat", required = false) String lat,
			@RequestParam(value = "lng", required = false) String lng,
			@RequestParam(value = "eventAt", required = false) String eventAtParam,
			@RequestParam(value = "recruitStatus", required = false) String recruitStatus,
			@RequestParam(value = "maxCapacity", required = false) String maxCapacityParam,
			@RequestParam(value = "participationType", required = false) String participationType,
			HttpSession session, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login";
		}

		Board post = boardRepository.findById(id).orElse(null);
		if (post == null) {
			ra.addFlashAttribute("error", "게시글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if (!type.equals(post.getBoardType())) {
			ra.addFlashAttribute("error", "게시글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if ("notice".equals(type) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "공지사항은 관리자만 수정할 수 있습니다.");
			return "redirect:/boards/notice/" + id;
		}
		if (!post.getAuthorNick().equals(lm.nickname()) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "본인 글만 수정할 수 있습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}

		String safeTitle = trimWs(title);
		String safeContent = trimWs(content);
		if (!StringUtils.hasText(safeTitle)) {
			ra.addFlashAttribute("error", "제목을 입력해주세요.");
			return "redirect:/boards/" + type + "/" + id + "/edit";
		}
		if (!StringUtils.hasText(safeContent)) {
			ra.addFlashAttribute("error", "내용을 입력해주세요.");
			return "redirect:/boards/" + type + "/" + id + "/edit";
		}

		post.setTitle(safeTitle);
		post.setContent(safeContent);
		if (!"map".equals(type) && !"fanmeeting".equals(type)) {
			post.setSecret(secret && !"notice".equals(type));
		}
		boardService.applyOptionalLocation(post, placeName, address, lat, lng);
		if (StringUtils.hasText(traineeIdParam)) {
			try {
				post.setTraineeId(Long.valueOf(traineeIdParam.trim()));
			} catch (NumberFormatException ignored) {
				post.setTraineeId(null);
			}
		}
		if (post.getTraineeId() != null && !isPublicTraineeId(post.getTraineeId())) {
			post.setTraineeId(null);
		}

		if ("map".equals(type) || "fanmeeting".equals(type)) {
			LocalDateTime ev = boardService.parseEventAtParam(eventAtParam);
			if (ev == null) {
				ra.addFlashAttribute("error", "모임 일시를 입력해주세요.");
				return "redirect:/boards/" + type + "/" + id + "/edit";
			}
			if (!post.isHasMapLocation()) {
				ra.addFlashAttribute("error", "장소를 검색하여 선택해주세요.");
				return "redirect:/boards/" + type + "/" + id + "/edit";
			}
			if ("fanmeeting".equals(type) && post.getTraineeId() == null) {
				ra.addFlashAttribute("error", "연습생을 선택해주세요.");
				return "redirect:/boards/" + type + "/" + id + "/edit";
			}
			boardService.applyFanMeetFields(post, ev, recruitStatus, maxCapacityParam, participationType);
			if ("fanmeeting".equals(type)) {
				post.setFanMeetApproved(true);
			} else {
				post.setFanMeetApproved(false);
			}
		}

		boardRepository.save(post);
		if ("fanmeeting".equals(type)) {
			ra.addFlashAttribute("success", "수정되었습니다.");
		} else if ("map".equals(type)) {
			ra.addFlashAttribute("success", "수정되었습니다. 관리자 재승인 후 다시 공개됩니다.");
		} else {
			ra.addFlashAttribute("success", "글이 수정되었습니다.");
		}
		return "redirect:/boards/" + type + "/" + id;
	}

	/* 글 삭제 */
	@PostMapping("/{type}/{id}/delete")
	@Transactional
	public String delete(@PathVariable("type") String type, @PathVariable("id") Long id, HttpSession session,
			RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login";
		}

		Board post = boardRepository.findById(id).orElse(null);
		if (post == null) {
			ra.addFlashAttribute("error", "게시글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if (!type.equals(post.getBoardType())) {
			ra.addFlashAttribute("error", "게시글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if ("notice".equals(type) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "공지사항은 관리자만 삭제할 수 있습니다.");
			return "redirect:/boards/notice/" + id;
		}
		if (!post.getAuthorNick().equals(lm.nickname()) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "본인 글만 삭제할 수 있습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}

		commentRepository.deleteByBoardId(id);
		likeRepository.deleteByBoardId(id);
		boardRepository.delete(post);
		ra.addFlashAttribute("success", "글이 삭제되었습니다.");
		return "redirect:/boards/" + type;
	}

	/* 댓글 작성 */
	@PostMapping("/{type}/{id}/comments")
	@Transactional
	public String addComment(@PathVariable("type") String type, @PathVariable("id") Long id,
			@RequestParam("content") String content, HttpSession session, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login";
		}

		Board post = boardRepository.findById(id).orElse(null);
		if (post == null) {
			ra.addFlashAttribute("error", "게시글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if (!type.equals(post.getBoardType())) {
			ra.addFlashAttribute("error", "게시글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if (!canAccessBoardPost(post, lm)) {
			ra.addFlashAttribute("error", "이 글에 댓글을 달 수 없습니다.");
			return "redirect:/boards/" + type;
		}

		String safeContent = trimWs(content);
		if (!StringUtils.hasText(safeContent) || safeContent.length() > 500) {
			ra.addFlashAttribute("error", "댓글은 1~500자로 입력해주세요.");
			return "redirect:/boards/" + type + "/" + id;
		}

		commentRepository.save(new BoardComment(post, safeContent, lm.nickname(), lm.mno()));
		return "redirect:/boards/" + type + "/" + id + "#comments";
	}

	/* 댓글 수정 */
	@PostMapping("/{type}/{id}/comments/{cid}/edit")
	@Transactional
	public String editComment(@PathVariable("type") String type, @PathVariable("id") Long id,
			@PathVariable("cid") Long cid, @RequestParam("content") String content, HttpSession session,
			RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login";
		}

		BoardComment comment = commentRepository.findById(cid).orElse(null);
		if (comment == null || comment.getBoard() == null || !id.equals(comment.getBoard().getId())) {
			ra.addFlashAttribute("error", "댓글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}
		if (!type.equals(comment.getBoard().getBoardType())) {
			ra.addFlashAttribute("error", "댓글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}
		if (!canAccessBoardPost(comment.getBoard(), lm)) {
			ra.addFlashAttribute("error", "이 글의 댓글을 수정할 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if (!lm.mno().equals(comment.getAuthorMno()) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "본인 댓글만 수정할 수 있습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}

		String safeContent = trimWs(content);
		if (!StringUtils.hasText(safeContent) || safeContent.length() > 500) {
			ra.addFlashAttribute("error", "댓글은 1~500자로 입력해주세요.");
			return "redirect:/boards/" + type + "/" + id + "#comments";
		}

		comment.setContent(safeContent);
		commentRepository.save(comment);
		ra.addFlashAttribute("success", "댓글이 수정되었습니다.");
		return "redirect:/boards/" + type + "/" + id + "#comments";
	}

	/* 댓글 삭제 */
	@PostMapping("/{type}/{id}/comments/{cid}/delete")
	@Transactional
	public String deleteComment(@PathVariable("type") String type, @PathVariable("id") Long id,
			@PathVariable("cid") Long cid, HttpSession session, RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login";
		}

		BoardComment comment = commentRepository.findById(cid).orElse(null);
		if (comment == null || comment.getBoard() == null || !id.equals(comment.getBoard().getId())) {
			ra.addFlashAttribute("error", "댓글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}
		if (!type.equals(comment.getBoard().getBoardType())) {
			ra.addFlashAttribute("error", "댓글을 찾을 수 없습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}
		if (!canAccessBoardPost(comment.getBoard(), lm)) {
			ra.addFlashAttribute("error", "이 글의 댓글을 삭제할 수 없습니다.");
			return "redirect:/boards/" + type;
		}
		if (!lm.mno().equals(comment.getAuthorMno()) && !isAdmin(lm)) {
			ra.addFlashAttribute("error", "본인 댓글만 삭제할 수 있습니다.");
			return "redirect:/boards/" + type + "/" + id;
		}

		commentRepository.delete(comment);
		return "redirect:/boards/" + type + "/" + id + "#comments";
	}

	/* 좋아요 토글 (AJAX) */
	@PostMapping("/{type}/{id}/like")
	@ResponseBody
	@Transactional
	public ResponseEntity<Map<String, Object>> toggleLike(@PathVariable("type") String type,
			@PathVariable("id") Long id, HttpSession session) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return ResponseEntity.status(401).body(Map.of("error", "로그인이 필요합니다."));
		}

		Board post = boardRepository.findById(id).orElse(null);
		if (post == null) {
			return ResponseEntity.status(404).body(Map.of("error", "게시글을 찾을 수 없습니다."));
		}
		if (!type.equals(post.getBoardType())) {
			return ResponseEntity.status(404).body(Map.of("error", "게시글을 찾을 수 없습니다."));
		}
		if (!"map".equals(post.getBoardType()) && post.isSecret()) {
			boolean isAuthor = lm.mno() != null && lm.mno().equals(post.getAuthorMno());
			if (!isAuthor && !isAdmin(lm)) {
				return ResponseEntity.status(403).body(Map.of("error", "이 글에 좋아요를 할 수 없습니다."));
			}
		}
		if (!canAccessBoardPost(post, lm)) {
			return ResponseEntity.status(403).body(Map.of("error", "이 글에 좋아요를 할 수 없습니다."));
		}

		Optional<BoardLike> existingLike = likeRepository.findByBoardIdAndMno(id, lm.mno());
		boolean liked;
		if (existingLike.isPresent()) {
			likeRepository.delete(existingLike.get());
			post.decrementLikeCount();
			liked = false;
		} else {
			likeRepository.save(new BoardLike(id, lm.mno()));
			post.incrementLikeCount();
			liked = true;
		}

		boardRepository.save(post);
		return ResponseEntity.ok(Map.of("liked", liked, "likeCount", post.getLikeCount()));
	}

	@PostMapping("/{type}/{id}/report")
	@ResponseBody
	@Transactional
	public ResponseEntity<Map<String, Object>> reportPost(@PathVariable("type") String type,
			@PathVariable("id") Long id, @RequestParam("reason") String reason,
			@RequestParam(value = "description", required = false) String description, HttpSession session) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return ResponseEntity.status(401).body(Map.of("error", "로그인이 필요합니다."));
		}
		Board post = boardRepository.findById(id).orElse(null);
		if (post == null) {
			return ResponseEntity.status(404).body(Map.of("error", "게시글을 찾을 수 없습니다."));
		}
		if (!type.equals(post.getBoardType())) {
			return ResponseEntity.status(404).body(Map.of("error", "게시글을 찾을 수 없습니다."));
		}
		if (!canAccessBoardPost(post, lm)) {
			return ResponseEntity.status(403).body(Map.of("error", "이 글은 신고할 수 없습니다."));
		}
		if (lm.mno() != null && lm.mno().equals(post.getAuthorMno())) {
			return ResponseEntity.badRequest().body(Map.of("error", "본인 게시글은 신고할 수 없습니다."));
		}
		if (reportRepository.existsByTargetTypeAndTargetIdAndReporterMno("board", id, lm.mno())) {
			return ResponseEntity.badRequest().body(Map.of("error", "이미 신고한 게시글입니다."));
		}
		Set<String> validReasons = Set.of("spam", "obscene", "abuse", "illegal", "other");
		if (!validReasons.contains(reason)) {
			return ResponseEntity.badRequest().body(Map.of("error", "올바른 신고 사유를 선택해주세요."));
		}
		String safeDesc = StringUtils.hasText(description)
				? trimWs(description).substring(0, Math.min(description.length(), 500))
				: null;
		reportRepository.save(new BoardReport("board", id, lm.mno(), lm.nickname(), reason, safeDesc));
		return ResponseEntity.ok(Map.of("success", true, "message", "신고가 접수되었습니다. 검토 후 조치하겠습니다."));
	}

	@PostMapping("/{type}/{id}/comments/{cid}/report")
	@ResponseBody
	@Transactional
	public ResponseEntity<Map<String, Object>> reportComment(@PathVariable("type") String type,
			@PathVariable("id") Long id, @PathVariable("cid") Long cid, @RequestParam("reason") String reason,
			@RequestParam(value = "description", required = false) String description, HttpSession session) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return ResponseEntity.status(401).body(Map.of("error", "로그인이 필요합니다."));
		}
		BoardComment comment = commentRepository.findById(cid).orElse(null);
		if (comment == null) {
			return ResponseEntity.status(404).body(Map.of("error", "댓글을 찾을 수 없습니다."));
		}
		if (comment.getBoard() == null || !id.equals(comment.getBoard().getId())
				|| !type.equals(comment.getBoard().getBoardType())) {
			return ResponseEntity.status(404).body(Map.of("error", "댓글을 찾을 수 없습니다."));
		}
		if (lm.mno().equals(comment.getAuthorMno())) {
			return ResponseEntity.badRequest().body(Map.of("error", "본인 댓글은 신고할 수 없습니다."));
		}
		if (reportRepository.existsByTargetTypeAndTargetIdAndReporterMno("comment", cid, lm.mno())) {
			return ResponseEntity.badRequest().body(Map.of("error", "이미 신고한 댓글입니다."));
		}
		Set<String> validReasons = Set.of("spam", "obscene", "abuse", "illegal", "other");
		if (!validReasons.contains(reason)) {
			return ResponseEntity.badRequest().body(Map.of("error", "올바른 신고 사유를 선택해주세요."));
		}
		String safeDesc = StringUtils.hasText(description)
				? trimWs(description).substring(0, Math.min(description.length(), 500))
				: null;
		reportRepository.save(new BoardReport("comment", cid, lm.mno(), lm.nickname(), reason, safeDesc));
		return ResponseEntity.ok(Map.of("success", true, "message", "댓글 신고가 접수되었습니다."));
	}

	/* 파일 서빙 */
	@GetMapping("/files/{storedName}")
	public ResponseEntity<Resource> serveFile(@PathVariable("storedName") String storedName,
			@RequestParam(value = "inline", defaultValue = "false") boolean inline) {
		if (!StringUtils.hasText(storedName) || !storedName.matches("^[a-zA-Z0-9._-]+$")) {
			return ResponseEntity.badRequest().build();
		}

		Path path = Paths.get(System.getProperty("user.dir"), "uploads", storedName).normalize();
		FileSystemResource resource = new FileSystemResource(path.toFile());
		if (!resource.exists()) {
			return ResponseEntity.notFound().build();
		}

		MediaType mediaType = detectMediaType(storedName);
		String disposition = inline ? "inline" : "attachment; filename=\"" + storedName + "\"";
		return ResponseEntity.ok()
				.header(HttpHeaders.CONTENT_DISPOSITION, disposition)
				.contentType(mediaType)
				.body(resource);
	}

	private static String normalizeBoardSearchKeyword(String q) {
		if (!StringUtils.hasText(q)) {
			return "";
		}
		String t = q.strip();
		if (t.length() > 80) {
			t = t.substring(0, 80);
		}
		return t.replace("%", "").replace("_", "");
	}

	private static List<String> resolveSearchScopeTypes(String scope) {
		if (!StringUtils.hasText(scope)) {
			return List.of("notice", "free", "lounge", "guide", "map", "report");
		}
		return switch (scope.trim().toLowerCase()) {
			case "notice" -> List.of("notice");
			case "community" -> List.copyOf(COMMUNITY_TYPES_ALL);
			case "map" -> List.of("map");
			case "report" -> List.of("report");
			default -> List.of("notice", "free", "lounge", "guide", "map", "report");
		};
	}

	private static String resolveSearchScopeKey(String scope) {
		if (!StringUtils.hasText(scope)) {
			return "all";
		}
		String s = scope.trim().toLowerCase();
		if ("notice".equals(s) || "community".equals(s) || "map".equals(s) || "report".equals(s)) {
			return s;
		}
		return "all";
	}

	private Page<Board> searchBoardPage(String keyword, List<String> types, boolean admin, LoginMember lm,
			Pageable pageable) {
		if (admin) {
			return boardRepository.searchBoardsAdmin(types, keyword, pageable);
		}
		if (lm != null) {
			return boardRepository.searchBoardsForMember(types, keyword, lm.mno(), pageable);
		}
		return boardRepository.searchBoardsPublic(types, keyword, pageable);
	}

	private static boolean isAdmin(LoginMember lm) {
		return lm != null && "ADMIN".equals(lm.role());
	}

	private List<Trainee> loadPublicTrainees() {
		return traineeRepository.findAll().stream()
				.filter(this::isPublicTrainee)
				.sorted((a, b) -> {
					if (a.getName() == null && b.getName() == null) {
						return 0;
					}
					if (a.getName() == null) {
						return 1;
					}
					if (b.getName() == null) {
						return -1;
					}
					return a.getName().compareToIgnoreCase(b.getName());
				})
				.toList();
	}

	private boolean isPublicTraineeId(Long traineeId) {
		if (traineeId == null) {
			return false;
		}
		return traineeRepository.findById(traineeId)
				.map(this::isPublicTrainee)
				.orElse(false);
	}

	private boolean isPublicTrainee(Trainee trainee) {
		return trainee != null && trainee.getId() != null && trainee.getGrade() != Grade.HIDDEN;
	}

	private static boolean isFanMeetingHost(Board post, LoginMember lm) {
		if (post == null || lm == null || lm.mno() == null) {
			return false;
		}
		if (post.getAuthorMno() != null) {
			return post.getAuthorMno().equals(lm.mno());
		}
		return lm.nickname() != null && lm.nickname().equals(post.getAuthorNick());
	}

	private static boolean canAccessBoardPost(Board post, LoginMember lm) {
		if (post == null) {
			return false;
		}
		if (!post.isVisible()) {
			return lm != null && "ADMIN".equals(lm.role());
		}
		return canAccessFanMeetPost(post, lm);
	}

	private static boolean canAccessFanMeetPost(Board post, LoginMember lm) {
		if (!"map".equals(post.getBoardType()) && !"fanmeeting".equals(post.getBoardType())) {
			return true;
		}
		if (post.isFanMeetApproved()) {
			return true;
		}
		if (lm == null) {
			return false;
		}
		if ("ADMIN".equals(lm.role())) {
			return true;
		}
		return lm.nickname() != null && lm.nickname().equals(post.getAuthorNick());
	}

	private static String icsTextEscape(String raw) {
		if (raw == null) {
			return "";
		}
		return raw.replace("\\", "\\\\").replace("\r\n", "\n").replace("\n", "\\n").replace(",", "\\,").replace(";",
				"\\;");
	}

	private String buildFanMeetIcs(Board b) {
		String nl = "\r\n";
		String uid = "fanmeet-" + b.getId() + "@unitx";
		String dtstamp = ICS_UTC.format(Instant.now());
		String dtstart = b.getEventAt().format(ICS_LOCAL);
		String summary = icsTextEscape(b.getTitle());
		String loc = icsTextEscape(b.getPlaceName() != null ? b.getPlaceName() : "");
		String descBody = b.getContent() == null ? "" : b.getContent();
		if (descBody.length() > 400) {
			descBody = descBody.substring(0, 400) + "…";
		}
		String desc = icsTextEscape(descBody);
		return "BEGIN:VCALENDAR" + nl + "VERSION:2.0" + nl + "PRODID:-//UNITX//FanMeet//KO" + nl + "CALSCALE:GREGORIAN"
				+ nl + "METHOD:PUBLISH" + nl + "BEGIN:VEVENT" + nl + "UID:" + uid + nl + "DTSTAMP:" + dtstamp + nl
				+ "DTSTART:" + dtstart + nl + "SUMMARY:" + summary + nl
				+ (StringUtils.hasText(loc) ? "LOCATION:" + loc + nl : "") + "DESCRIPTION:" + desc + nl + "END:VEVENT" + nl
				+ "END:VCALENDAR" + nl;
	}

	private static String resolveTitle(String type) {
		return Optional.ofNullable(BOARD_TITLES.get(type)).orElse("게시판");
	}

	private static String sanitizeFilename(String filename) {
		if (!StringUtils.hasText(filename)) {
			return "file";
		}
		String normalized = filename.replaceAll("[\\\\/\\r\\n]", "_");
		return normalized.length() > 120 ? normalized.substring(normalized.length() - 120) : normalized;
	}

	private static String storeUpload(MultipartFile file, String originalFilename) throws IOException {
		String ext = StringUtils.getFilenameExtension(originalFilename);
		String saved = UUID.randomUUID().toString().replace("-", "") + (ext == null ? "" : "." + ext);
		Path dir = Paths.get(System.getProperty("user.dir"), "uploads");
		Files.createDirectories(dir);
		Files.copy(file.getInputStream(), dir.resolve(saved).normalize());
		return saved;
	}

	private static MediaType detectMediaType(String filename) {
		String ext = StringUtils.getFilenameExtension(filename);
		if (ext == null) {
			return MediaType.APPLICATION_OCTET_STREAM;
		}

		return switch (ext.toLowerCase()) {
		case "jpg", "jpeg" -> MediaType.IMAGE_JPEG;
		case "png" -> MediaType.IMAGE_PNG;
		case "gif" -> MediaType.IMAGE_GIF;
		case "webp" -> MediaType.parseMediaType("image/webp");
		default -> MediaType.APPLICATION_OCTET_STREAM;
		};
	}
}
