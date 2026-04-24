package com.java.controller;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeSet;
import java.util.stream.Collectors;
import java.io.IOException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.java.config.SessionConst;
import com.java.dto.CoinDistributionDto;
import com.java.dto.CoinAdjustRequest;
import com.java.dto.CoinFlowDto;
import com.java.dto.CoinKpiDto;
import com.java.dto.CoinTxnLogDto;
import com.java.dto.AdminEnhanceAdjustRequest;
import com.java.dto.LoginMember;
import com.java.dto.MemberOpsDetailDto;
import com.java.dto.MemberOpsSummaryDto;
import com.java.dto.PhotoCardGrantRequest;
import com.java.dto.UsageFlowDto;
import com.java.dto.UsageKpiDto;
import com.java.dto.UsageLogDto;
import com.java.dto.UsageRatioDto;
import com.java.entity.Board;
import com.java.entity.MemberSanction;
import com.java.entity.Member;
import com.java.entity.MemberRank;
import com.java.game.entity.GameChoice;
import com.java.game.entity.GameMiniQuiz;
import com.java.game.entity.GameRun;
import com.java.game.entity.GameScene;
import com.java.game.entity.Grade;
import com.java.game.entity.Trainee;
import com.java.game.repository.GameChoiceRepository;
import com.java.game.repository.GameMiniQuizRepository;
import com.java.game.repository.GameRunRepository;
import com.java.game.repository.GameSceneRepository;
import com.java.game.repository.TraineeRepository;
import com.java.photocard.entity.PhotoCardMaster;
import com.java.photocard.repository.PhotoCardMasterRepository;
import com.java.repository.BoardRepository;
import com.java.repository.FanMeetingParticipantRepository;
import com.java.repository.GachaPullLogRepository;
import com.java.repository.MemberRepository;
import com.java.repository.MemberSanctionRepository;
import com.java.service.BoardService;
import com.java.service.AdminMemberOpsService;
import com.java.service.JuminCryptoService;
import com.java.service.MarketService;
import com.java.service.UsageAnalyticsService;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/admin")
public class AdminController {

	private static final ZoneId GACHA_ADMIN_ZONE = ZoneId.of("Asia/Seoul");

	/** 관리자 대시보드 회원 목록 페이지 크기 */
	private static final int MEMBER_PAGE_SIZE = 10;

	/** 코인 사용 통계 · 최근 로그 페이지 크기 */
	private static final int USAGE_LOG_PAGE_SIZE = 10;

	/** 공지 운영 목록 페이지 크기 */
	private static final int NOTICE_PAGE_SIZE = 10;

	@Value("${app.ml.training-log-path:python-ml/data/chat_choice_training.jsonl}")
	private String mlTrainingLogPath;

	private final MemberRepository memberRepository;
	private final GameRunRepository gameRunRepository;
	private final GameSceneRepository gameSceneRepository;
	private final GameChoiceRepository gameChoiceRepository;
	private final GameMiniQuizRepository gameMiniQuizRepository;
	private final TraineeRepository traineeRepository;
	private final BoardRepository boardRepository;
	private final MarketService marketService;
	private final GachaPullLogRepository gachaPullLogRepository;
	private final BoardService boardService;
	private final UsageAnalyticsService usageAnalyticsService;
	private final JuminCryptoService juminCryptoService;
	private final AdminMemberOpsService adminMemberOpsService;
	private final PhotoCardMasterRepository photoCardMasterRepository;
	private final MemberSanctionRepository memberSanctionRepository;
	private final FanMeetingParticipantRepository fanMeetingParticipantRepository;

	public AdminController(MemberRepository memberRepository, GameRunRepository gameRunRepository,
			GameSceneRepository gameSceneRepository, GameChoiceRepository gameChoiceRepository,
			GameMiniQuizRepository gameMiniQuizRepository,
			TraineeRepository traineeRepository, BoardRepository boardRepository, MarketService marketService,
			GachaPullLogRepository gachaPullLogRepository, BoardService boardService,
			UsageAnalyticsService usageAnalyticsService, JuminCryptoService juminCryptoService,
			AdminMemberOpsService adminMemberOpsService, PhotoCardMasterRepository photoCardMasterRepository,
			MemberSanctionRepository memberSanctionRepository,
			FanMeetingParticipantRepository fanMeetingParticipantRepository) {
		this.memberRepository = memberRepository;
		this.gameRunRepository = gameRunRepository;
		this.gameSceneRepository = gameSceneRepository;
		this.gameChoiceRepository = gameChoiceRepository;
		this.gameMiniQuizRepository = gameMiniQuizRepository;
		this.traineeRepository = traineeRepository;
		this.boardRepository = boardRepository;
		this.marketService = marketService;
		this.gachaPullLogRepository = gachaPullLogRepository;
		this.boardService = boardService;
		this.usageAnalyticsService = usageAnalyticsService;
		this.juminCryptoService = juminCryptoService;
		this.adminMemberOpsService = adminMemberOpsService;
		this.photoCardMasterRepository = photoCardMasterRepository;
		this.memberSanctionRepository = memberSanctionRepository;
		this.fanMeetingParticipantRepository = fanMeetingParticipantRepository;
	}

	/* ─────────────── 대시보드 ─────────────── */
	@GetMapping({ "", "/", "/members" })
	public String adminDashboard(HttpSession session, Model model,
			@RequestParam(name = "q", required = false) String q,
			@RequestParam(name = "page", defaultValue = "1") int memberPageParam,
			@RequestParam(name = "coinPage", defaultValue = "1") int coinPageParam,
			@RequestParam(name = "noticePage", defaultValue = "1") int noticePageParam,
			@RequestParam(name = "fanMeetingPage", defaultValue = "1") int fanMeetingPageParam,
			@RequestParam(name = "fanMeetingStatus", defaultValue = "all") String fanMeetingStatus) {

		// 로그인 체크
		Object loginMember = session.getAttribute("LOGIN_MEMBER");
		if (loginMember == null) {
			return "redirect:/login?redirect=/admin";
		}

		/* ── 회원 통계 ── */
		List<Member> members = memberRepository.findAll(Sort.by("createdAt").descending());
		long totalMembers = members.size();

		String query = q == null ? "" : q.trim();
		List<Member> filteredMembers = members;
		if (!query.isBlank()) {
			String qq = query.toLowerCase();
			filteredMembers = members.stream().filter(m -> {
				String mid = m.getMid() == null ? "" : m.getMid();
				String name = m.getMname() == null ? "" : m.getMname();
				String nick = m.getNickname() == null ? "" : m.getNickname();
				String email = m.getEmail() == null ? "" : m.getEmail();
				return mid.toLowerCase().contains(qq) || name.toLowerCase().contains(qq) || nick.toLowerCase().contains(qq)
						|| email.toLowerCase().contains(qq);
			}).collect(Collectors.toList());
		}

		int totalFiltered = filteredMembers.size();
		Map<String, Long> memberAgeBuckets = initMemberAgeBuckets();
		for (Member m : filteredMembers) {
			String plainJumin = juminCryptoService.decrypt(m.getJumin());
			int birthYear = parseBirthYearFromJumin(plainJumin);
			String bucket = toAgeBucketLabel(birthYear, LocalDate.now(GACHA_ADMIN_ZONE).getYear());
			memberAgeBuckets.merge(bucket, 1L, Long::sum);
		}
		int totalPages = totalFiltered == 0 ? 1 : (int) Math.ceil(totalFiltered / (double) MEMBER_PAGE_SIZE);
		int memberPage = memberPageParam;
		if (memberPage < 1) {
			memberPage = 1;
		}
		if (memberPage > totalPages) {
			memberPage = totalPages;
		}
		int fromIndex = (memberPage - 1) * MEMBER_PAGE_SIZE;
		List<Member> pagedMembers = fromIndex >= totalFiltered ? List.of()
				: filteredMembers.subList(fromIndex, Math.min(fromIndex + MEMBER_PAGE_SIZE, totalFiltered));
		Map<Long, String> maskedJuminByMno = new LinkedHashMap<>();
		List<Long> pagedMemberIds = new ArrayList<>();
		for (Member m : pagedMembers) {
			maskedJuminByMno.put(m.getMno(), juminCryptoService.mask(juminCryptoService.decrypt(m.getJumin())));
			pagedMemberIds.add(m.getMno());
		}
		Map<Long, MemberOpsSummaryDto> memberOpsSummaryByMno = adminMemberOpsService.getMemberSummaries(pagedMemberIds);
		int memberPageRowFrom = totalFiltered == 0 ? 0 : fromIndex + 1;
		int memberPageRowTo = fromIndex + pagedMembers.size();

		List<Integer> memberPageNumbers = new ArrayList<>();
		if (totalPages > 0) {
			int window = 7;
			int half = window / 2;
			int start = Math.max(1, memberPage - half);
			int end = Math.min(totalPages, start + window - 1);
			start = Math.max(1, end - window + 1);
			for (int i = start; i <= end; i++) {
				memberPageNumbers.add(i);
			}
		}

		// 최근 7일 가입자 날짜별
		DateTimeFormatter dayFmt = DateTimeFormatter.ofPattern("MM/dd");
		Map<String, Long> joinByDay = new LinkedHashMap<>();
		for (int i = 6; i >= 0; i--) {
			joinByDay.put(LocalDateTime.now().minusDays(i).format(dayFmt), 0L);
		}
		for (Member m : members) {
			if (m.getCreatedAt() != null && m.getCreatedAt().isAfter(LocalDateTime.now().minusDays(7))) {
				joinByDay.merge(m.getCreatedAt().format(dayFmt), 1L, (a, b) -> Long.sum(a, b));
			}
		}
		long joinMax7 = joinByDay.values().stream().mapToLong(v -> v == null ? 0L : v.longValue()).max().orElse(0L);
		if (joinMax7 <= 0L)
			joinMax7 = 1L;

		/* ── 게임 통계 ── */
		List<GameRun> gameRuns = gameRunRepository.findAll();
		long totalGames = gameRuns.size();
		long finishedGames = gameRuns.stream().filter(g -> "FINISHED".equals(g.getPhase())).count();
		long activeGames = totalGames - finishedGames;
		long finishRate = totalGames > 0 ? finishedGames * 100 / totalGames : 0;
		long finishRatePct = finishRate;
		Map<String, Object> mlChoiceStats = collectMlChoiceStats();

		// 그룹 타입별 플레이 수
		Map<String, Long> groupTypeCnt = gameRuns.stream().collect(Collectors
				.groupingBy(g -> g.getGroupType() == null ? "UNKNOWN" : g.getGroupType(), Collectors.counting()));
		long groupMax = groupTypeCnt.values().stream().mapToLong(v -> v == null ? 0L : v.longValue()).max().orElse(0L);
		if (groupMax <= 0L)
			groupMax = 1L;
		// 가장 많이 선택된 그룹
		String topGroup = groupTypeCnt.entrySet().stream().max(Map.Entry.comparingByValue()).map(Map.Entry::getKey)
				.orElse("-");

		/* ── 연습생 통계 ── */
		List<Trainee> trainees = traineeRepository.findAll();
		long totalTrainees = trainees.size();
		List<Trainee> topTrainees = trainees.stream()
				.sorted(Comparator.comparingInt((Trainee t) -> t.getVocal() + t.getDance() + t.getStar()
						+ t.getMental() + t.getTeamwork()).reversed())
				.limit(5)
				.collect(Collectors.toList());
		long cntN = trainees.stream().filter(t -> t.getGrade() == Grade.N).count();
		long cntR = trainees.stream().filter(t -> t.getGrade() == Grade.R).count();
		long cntSr = trainees.stream().filter(t -> t.getGrade() == Grade.SR).count();
		long cntSsr = trainees.stream().filter(t -> t.getGrade() == Grade.SSR).count();
		List<GameScene> gameScenes = gameSceneRepository.findAllByOrderByPhaseAscIdAsc();
		List<GameChoice> gameChoices = gameChoiceRepository.findAllByOrderByPhaseAscSortOrderAsc();
		long totalGameScenes = gameScenes.size();
		long totalGameChoices = gameChoices.size();
		long totalGameMiniQuizzes = gameMiniQuizRepository.count();
		long activeGameMiniQuizzes = gameMiniQuizRepository.findByEnabledTrueOrderBySortOrderAscIdAsc().size();
		long distinctScenePhases = gameScenes.stream()
				.map(GameScene::getPhase)
				.filter(s -> s != null && !s.isBlank())
				.distinct()
				.count();
		long distinctChoicePhases = gameChoices.stream()
				.map(GameChoice::getPhase)
				.filter(s -> s != null && !s.isBlank())
				.distinct()
				.count();
		TreeSet<String> gamePhaseSuggestionSet = new TreeSet<>();
		for (GameScene s : gameScenes) {
			if (s.getPhase() != null && !s.getPhase().isBlank()) {
				gamePhaseSuggestionSet.add(s.getPhase().trim());
			}
		}
		for (GameChoice c : gameChoices) {
			if (c.getPhase() != null && !c.getPhase().isBlank()) {
				gamePhaseSuggestionSet.add(c.getPhase().trim());
			}
		}
		TreeSet<String> gameEventTypeSuggestionSet = new TreeSet<>();
		for (GameScene s : gameScenes) {
			if (s.getEventType() != null && !s.getEventType().isBlank()) {
				gameEventTypeSuggestionSet.add(s.getEventType().trim());
			}
		}

		/* ── 게시판 통계 ── */
		List<Board> allPosts = boardRepository.findAll();
		long totalPosts = allPosts.size();
		long noticePosts = allPosts.stream().filter(b -> "notice".equals(b.getBoardType())).count();
		long freePosts = allPosts.stream()
				.filter(b -> {
					String t = b.getBoardType();
					return "free".equals(t) || "lounge".equals(t) || "guide".equals(t);
				})
				.count();
		long reportPosts = allPosts.stream().filter(b -> "report".equals(b.getBoardType())).count();
		long mapPosts = allPosts.stream().filter(b -> "map".equals(b.getBoardType())).count();
		long fanMeetingPosts = allPosts.stream().filter(b -> "fanmeeting".equals(b.getBoardType())).count();
		int fanMeetingPage = Math.max(1, fanMeetingPageParam);
		int fanMeetingPageSize = 5;
		String fanMeetingStatusKeyRaw = fanMeetingStatus == null ? "all" : fanMeetingStatus.trim().toLowerCase();
		if (!"all".equals(fanMeetingStatusKeyRaw) && !"recruiting".equals(fanMeetingStatusKeyRaw)
				&& !"done".equals(fanMeetingStatusKeyRaw)) {
			fanMeetingStatusKeyRaw = "all";
		}
		final String fanMeetingStatusKey = fanMeetingStatusKeyRaw;
		List<Board> fanMeetingFiltered = boardRepository.findByBoardTypeOrderByCreatedAtDesc("fanmeeting").stream()
				.filter(post -> {
					if ("recruiting".equals(fanMeetingStatusKey)) {
						return "RECRUITING".equalsIgnoreCase(post.getRecruitStatus())
								|| "OPEN".equalsIgnoreCase(post.getRecruitStatus());
					}
					if ("done".equals(fanMeetingStatusKey)) {
						return "DONE".equalsIgnoreCase(post.getRecruitStatus())
								|| "CLOSED".equalsIgnoreCase(post.getRecruitStatus());
					}
					return true;
				})
				.toList();
		long fanMeetingTotalCount = fanMeetingFiltered.size();
		int fanMeetingTotalPages = Math.max(1, (int) Math.ceil(fanMeetingTotalCount / (double) fanMeetingPageSize));
		if (fanMeetingPage > fanMeetingTotalPages) {
			fanMeetingPage = fanMeetingTotalPages;
		}
		int fanMeetingFrom = (fanMeetingPage - 1) * fanMeetingPageSize;
		int fanMeetingTo = Math.min(fanMeetingFrom + fanMeetingPageSize, fanMeetingFiltered.size());
		List<Board> recentFanMeetingPosts = fanMeetingFrom >= fanMeetingFiltered.size() ? List.of()
				: fanMeetingFiltered.subList(fanMeetingFrom, fanMeetingTo);
		int fanMeetingRowFrom = fanMeetingTotalCount == 0 ? 0 : (fanMeetingPage - 1) * fanMeetingPageSize + 1;
		int fanMeetingRowTo = (int) Math.min(fanMeetingTotalCount, (long) fanMeetingPage * fanMeetingPageSize);
		List<Integer> fanMeetingPageNumbers = new ArrayList<>();
		int fmWindow = 5;
		int fmHalf = fmWindow / 2;
		int fmStart = Math.max(1, fanMeetingPage - fmHalf);
		int fmEnd = Math.min(fanMeetingTotalPages, fmStart + fmWindow - 1);
		fmStart = Math.max(1, fmEnd - fmWindow + 1);
		for (int i = fmStart; i <= fmEnd; i++) {
			fanMeetingPageNumbers.add(i);
		}
		Map<Long, Long> fanMeetingApplicantCount = new LinkedHashMap<>();
		for (Board b : recentFanMeetingPosts) {
			fanMeetingApplicantCount.put(b.getId(), fanMeetingParticipantRepository.countByPostId(b.getId()));
		}
		long totalBoardCount = boardService.getTotalBoardCount();
		long noticeCount = boardService.getNoticeCount();
		long normalBoardCount = boardService.getNormalBoardCount();
		long reportCount = boardService.getReportCount();
		long blindedCount = boardService.getBlindedCount();
		Map<String, Long> boardTrend = boardService.getBoardTrend(7);
		Map<String, Long> reportTrend = boardService.getReportTrend(7);
		List<Map<String, Object>> recentReports = boardService.getRecentReports(10);
		int noticePage = Math.max(1, noticePageParam);
		Page<Board> noticePageData = boardRepository.findByBoardTypeOrderByCreatedAtDesc("notice",
				PageRequest.of(noticePage - 1, NOTICE_PAGE_SIZE));
		int noticeTotalPages = Math.max(1, noticePageData.getTotalPages());
		if (noticePage > noticeTotalPages) {
			noticePage = noticeTotalPages;
			noticePageData = boardRepository.findByBoardTypeOrderByCreatedAtDesc("notice",
					PageRequest.of(noticePage - 1, NOTICE_PAGE_SIZE));
		}
		List<Board> noticeList = noticePageData.getContent();
		long noticeTotalCount = noticePageData.getTotalElements();
		int noticeRowFrom = noticeTotalCount == 0 ? 0 : (noticePage - 1) * NOTICE_PAGE_SIZE + 1;
		int noticeRowTo = (int) Math.min(noticeTotalCount, (long) noticePage * NOTICE_PAGE_SIZE);
		List<Integer> noticePageNumbers = new ArrayList<>();
		if (noticeTotalPages > 0) {
			int window = 10;
			int half = window / 2;
			int start = Math.max(1, noticePage - half);
			int end = Math.min(noticeTotalPages, start + window - 1);
			start = Math.max(1, end - window + 1);
			for (int i = start; i <= end; i++) {
				noticePageNumbers.add(i);
			}
		}

		// 최근 게시글 5개
		List<Board> recentPosts = allPosts.stream()
				.sorted(Comparator.comparing(Board::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
				.limit(5).collect(Collectors.toList());

		/* ── 최근 가입 회원 5명 ── */
		List<Member> recentMembers = members.stream()
				.sorted(Comparator.comparing(Member::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
				.limit(5).collect(Collectors.toList());

		/* ── 공지/신고 최신 ── */
		List<Board> recentNotices = boardRepository.findByBoardTypeOrderByCreatedAtDesc("notice").stream().limit(5)
				.collect(Collectors.toList());

		/* ── 최근 게임 런 ── */
		List<GameRun> recentRuns = gameRunRepository.findTop50ByOrderByCreatedAtDesc().stream().limit(12)
				.collect(Collectors.toList());

		/* ── 최근 30일 가입자 (일자별) ── */
		Map<String, Long> joinByDay30 = new LinkedHashMap<>();
		for (int i = 29; i >= 0; i--) {
			joinByDay30.put(LocalDateTime.now().minusDays(i).format(dayFmt), 0L);
		}
		for (Member m : members) {
			if (m.getCreatedAt() != null && m.getCreatedAt().isAfter(LocalDateTime.now().minusDays(30))) {
				joinByDay30.merge(m.getCreatedAt().format(dayFmt), 1L, (a, b) -> Long.sum(a, b));
			}
		}
		long joinMax30 = joinByDay30.values().stream().mapToLong(v -> v == null ? 0L : v.longValue()).max().orElse(0L);
		if (joinMax30 <= 0L)
			joinMax30 = 1L;

		/* ── 게임 차트 데이터(기간별/시간대/이탈) ── */
		LocalDateTime now = LocalDateTime.now();
		DateTimeFormatter dayLabelFmt = DateTimeFormatter.ofPattern("MM/dd");
		DateTimeFormatter weekLabelFmt = DateTimeFormatter.ofPattern("MM/dd");
		DateTimeFormatter monthLabelFmt = DateTimeFormatter.ofPattern("yyyy-MM");

		// 최근 14일 일간
		Map<String, Long> gamesByDay14 = new LinkedHashMap<>();
		for (int i = 13; i >= 0; i--) {
			gamesByDay14.put(now.minusDays(i).format(dayLabelFmt), 0L);
		}
		for (GameRun g : gameRuns) {
			if (g.getCreatedAt() != null && g.getCreatedAt().isAfter(now.minusDays(14))) {
				gamesByDay14.merge(g.getCreatedAt().format(dayLabelFmt), 1L, Long::sum);
			}
		}

		// 최근 12주 주간 (월요일 시작)
		Map<String, Long> gamesByWeek12 = new LinkedHashMap<>();
		LocalDate currentWeekStart = now.toLocalDate().with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
		for (int i = 11; i >= 0; i--) {
			LocalDate ws = currentWeekStart.minusWeeks(i);
			String label = ws.format(weekLabelFmt) + "~";
			gamesByWeek12.put(label, 0L);
		}
		for (GameRun g : gameRuns) {
			LocalDateTime createdAt = g.getCreatedAt();
			if (createdAt == null) {
				continue;
			}
			LocalDate ws = createdAt.toLocalDate().with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
			String label = ws.format(weekLabelFmt) + "~";
			if (gamesByWeek12.containsKey(label)) {
				gamesByWeek12.merge(label, 1L, Long::sum);
			}
		}

		// 최근 12개월 월간
		Map<String, Long> gamesByMonth12 = new LinkedHashMap<>();
		LocalDate currentMonth = now.toLocalDate().withDayOfMonth(1);
		for (int i = 11; i >= 0; i--) {
			LocalDate month = currentMonth.minusMonths(i);
			gamesByMonth12.put(month.format(monthLabelFmt), 0L);
		}
		for (GameRun g : gameRuns) {
			LocalDateTime createdAt = g.getCreatedAt();
			if (createdAt == null) {
				continue;
			}
			String label = createdAt.toLocalDate().withDayOfMonth(1).format(monthLabelFmt);
			if (gamesByMonth12.containsKey(label)) {
				gamesByMonth12.merge(label, 1L, Long::sum);
			}
		}

		// 최근 플레이(일/주/월) 공통 최대값
		long gameDailyMax = 1L;
		for (Long v : gamesByDay14.values()) {
			if (v != null && v > gameDailyMax) {
				gameDailyMax = v;
			}
		}
		for (Long v : gamesByWeek12.values()) {
			if (v != null && v > gameDailyMax) {
				gameDailyMax = v;
			}
		}
		for (Long v : gamesByMonth12.values()) {
			if (v != null && v > gameDailyMax) {
				gameDailyMax = v;
			}
		}

		// phase 분포 (일/주/월)
		List<GameRun> phaseDailyRuns = gameRuns.stream()
				.filter(g -> g.getCreatedAt() != null && g.getCreatedAt().isAfter(now.minusDays(1)))
				.collect(Collectors.toList());
		List<GameRun> phaseWeeklyRuns = gameRuns.stream()
				.filter(g -> g.getCreatedAt() != null && g.getCreatedAt().isAfter(now.minusDays(7)))
				.collect(Collectors.toList());
		List<GameRun> phaseMonthlyRuns = gameRuns.stream()
				.filter(g -> g.getCreatedAt() != null && g.getCreatedAt().isAfter(now.minusDays(30)))
				.collect(Collectors.toList());
		Map<String, List<Object>> phaseDaily = topPhaseChartData(phaseDailyRuns, 10);
		Map<String, List<Object>> phaseWeekly = topPhaseChartData(phaseWeeklyRuns, 10);
		Map<String, List<Object>> phaseMonthly = topPhaseChartData(phaseMonthlyRuns, 10);

		// 시간대별 플레이(일/주/월)
		Map<String, Long> hourlyPlayDaily = initHourlyMap();
		Map<String, Long> hourlyPlayWeekly = initHourlyMap();
		Map<String, Long> hourlyPlayMonthly = initHourlyMap();
		for (GameRun g : gameRuns) {
			LocalDateTime createdAt = g.getCreatedAt();
			if (createdAt == null) {
				continue;
			}
			String hourLabel = String.format("%02d시", createdAt.getHour());
			if (createdAt.isAfter(now.minusDays(1))) {
				hourlyPlayDaily.merge(hourLabel, 1L, Long::sum);
			}
			if (createdAt.isAfter(now.minusDays(7))) {
				hourlyPlayWeekly.merge(hourLabel, 1L, Long::sum);
			}
			if (createdAt.isAfter(now.minusDays(30))) {
				hourlyPlayMonthly.merge(hourLabel, 1L, Long::sum);
			}
		}

		// 이탈 구간(일/주/월, 현재 phase 기준, FINISHED 제외)
		Map<String, Long> dropOffDaily = initDropOffMap();
		Map<String, Long> dropOffWeekly = initDropOffMap();
		Map<String, Long> dropOffMonthly = initDropOffMap();
		for (GameRun g : gameRuns) {
			LocalDateTime createdAt = g.getCreatedAt();
			if (createdAt == null) {
				continue;
			}
			String bucket = dropOffBucket(g.getPhase());
			if ("FINISHED".equals(bucket)) {
				continue;
			}
			if (createdAt.isAfter(now.minusDays(1))) {
				dropOffDaily.merge(bucket, 1L, Long::sum);
			}
			if (createdAt.isAfter(now.minusDays(7))) {
				dropOffWeekly.merge(bucket, 1L, Long::sum);
			}
			if (createdAt.isAfter(now.minusDays(30))) {
				dropOffMonthly.merge(bucket, 1L, Long::sum);
			}
		}

		/* ── Model 전달 ── */
		model.addAttribute("totalMembers", totalMembers);
		model.addAttribute("totalGames", totalGames);
		model.addAttribute("finishedGames", finishedGames);
		model.addAttribute("activeGames", activeGames);
		model.addAttribute("finishRate", finishRate);
		model.addAttribute("finishRatePct", finishRatePct);
		model.addAttribute("topGroup", topGroup);
		model.addAttribute("totalTrainees", totalTrainees);
		model.addAttribute("gameScenes", gameScenes);
		model.addAttribute("gameChoices", gameChoices);
		model.addAttribute("totalGameScenes", totalGameScenes);
		model.addAttribute("totalGameChoices", totalGameChoices);
		model.addAttribute("totalGameMiniQuizzes", totalGameMiniQuizzes);
		model.addAttribute("activeGameMiniQuizzes", activeGameMiniQuizzes);
		model.addAttribute("mlChoiceStats", mlChoiceStats);
		model.addAttribute("distinctScenePhases", distinctScenePhases);
		model.addAttribute("distinctChoicePhases", distinctChoicePhases);
		model.addAttribute("gamePhaseSuggestions", new ArrayList<>(gamePhaseSuggestionSet));
		model.addAttribute("gameEventTypeSuggestions", new ArrayList<>(gameEventTypeSuggestionSet));
		model.addAttribute("joinByDayKeys", new ArrayList<>(joinByDay.keySet()));
		model.addAttribute("joinByDayVals", new ArrayList<>(joinByDay.values()));
		model.addAttribute("joinMax7", joinMax7);
		model.addAttribute("groupTypeCnt", groupTypeCnt);
		model.addAttribute("groupMax", groupMax);
		model.addAttribute("cntN", cntN);
		model.addAttribute("cntR", cntR);
		model.addAttribute("cntSr", cntSr);
		model.addAttribute("cntSsr", cntSsr);
		model.addAttribute("recentMembers", recentMembers);
		model.addAttribute("q", query);
		model.addAttribute("allMembers", pagedMembers);
		model.addAttribute("maskedJuminByMno", maskedJuminByMno);
		model.addAttribute("allMembersTotal", members.size());
		model.addAttribute("filteredMembersTotal", totalFiltered);
		model.addAttribute("memberPage", memberPage);
		model.addAttribute("memberPageSize", MEMBER_PAGE_SIZE);
		model.addAttribute("memberPageTotalPages", totalPages);
		model.addAttribute("memberPageNumbers", memberPageNumbers);
		model.addAttribute("memberPageRowFrom", memberPageRowFrom);
		model.addAttribute("memberPageRowTo", memberPageRowTo);
		model.addAttribute("memberOpsSummaryByMno", memberOpsSummaryByMno);
		model.addAttribute("memberAgeBucketLabelsJson", jsonStringArray(new ArrayList<>(memberAgeBuckets.keySet())));
		model.addAttribute("memberAgeBucketValuesJson", jsonLongArray(new ArrayList<>(memberAgeBuckets.values())));
		model.addAttribute("totalPosts", totalPosts);
		model.addAttribute("noticePosts", noticePosts);
		model.addAttribute("freePosts", freePosts);
		model.addAttribute("reportPosts", reportPosts);
		model.addAttribute("recentPosts", recentPosts);
		model.addAttribute("allTrainees", trainees);
		model.addAttribute("topTrainees", topTrainees);
		model.addAttribute("recentNotices", recentNotices);
		model.addAttribute("recentRuns", recentRuns);
		model.addAttribute("joinByDay30Keys", new ArrayList<>(joinByDay30.keySet()));
		model.addAttribute("joinByDay30Vals", new ArrayList<>(joinByDay30.values()));
		model.addAttribute("joinMax30", joinMax30);
		model.addAttribute("mapPosts", mapPosts);
		model.addAttribute("fanMeetingPosts", fanMeetingPosts);
		model.addAttribute("recentFanMeetingPosts", recentFanMeetingPosts);
		model.addAttribute("fanMeetingApplicantCount", fanMeetingApplicantCount);
		model.addAttribute("fanMeetingPage", fanMeetingPage);
		model.addAttribute("fanMeetingPageSize", fanMeetingPageSize);
		model.addAttribute("fanMeetingTotalCount", fanMeetingTotalCount);
		model.addAttribute("fanMeetingTotalPages", fanMeetingTotalPages);
		model.addAttribute("fanMeetingRowFrom", fanMeetingRowFrom);
		model.addAttribute("fanMeetingRowTo", fanMeetingRowTo);
		model.addAttribute("fanMeetingPageNumbers", fanMeetingPageNumbers);
		model.addAttribute("fanMeetingStatus", fanMeetingStatusKey);
		model.addAttribute("totalBoardCount", totalBoardCount);
		model.addAttribute("noticeCount", noticeCount);
		model.addAttribute("normalBoardCount", normalBoardCount);
		model.addAttribute("reportCount", reportCount);
		model.addAttribute("blindedCount", blindedCount);
		model.addAttribute("recentReports", recentReports);
		model.addAttribute("noticeList", noticeList);
		model.addAttribute("noticePage", noticePage);
		model.addAttribute("noticePageSize", NOTICE_PAGE_SIZE);
		model.addAttribute("noticeTotalCount", noticeTotalCount);
		model.addAttribute("noticeTotalPages", noticeTotalPages);
		model.addAttribute("noticeRowFrom", noticeRowFrom);
		model.addAttribute("noticeRowTo", noticeRowTo);
		model.addAttribute("noticePageNumbers", noticePageNumbers);
		model.addAttribute("boardTrend", boardTrend);
		model.addAttribute("reportTrend", reportTrend);
		model.addAttribute("boardTrendKeysJson", jsonStringArray(new ArrayList<>(boardTrend.keySet())));
		model.addAttribute("boardTrendValsJson", jsonLongArray(new ArrayList<>(boardTrend.values())));
		model.addAttribute("reportTrendKeysJson", jsonStringArray(new ArrayList<>(reportTrend.keySet())));
		model.addAttribute("reportTrendValsJson", jsonLongArray(new ArrayList<>(reportTrend.values())));
		model.addAttribute("gameDailyKeys", new ArrayList<>(gamesByDay14.keySet()));
		model.addAttribute("gameDailyVals", new ArrayList<>(gamesByDay14.values()));
		model.addAttribute("gameDailyMax", gameDailyMax);
		model.addAttribute("gameWeeklyKeys", new ArrayList<>(gamesByWeek12.keySet()));
		model.addAttribute("gameWeeklyVals", new ArrayList<>(gamesByWeek12.values()));
		model.addAttribute("gameMonthlyKeys", new ArrayList<>(gamesByMonth12.keySet()));
		model.addAttribute("gameMonthlyVals", new ArrayList<>(gamesByMonth12.values()));
		model.addAttribute("gamePhaseLabels", phaseMonthly.get("labels"));
		model.addAttribute("gamePhaseValues", phaseMonthly.get("values"));
		model.addAttribute("gameDailyKeysJson", jsonStringArray(new ArrayList<>(gamesByDay14.keySet())));
		model.addAttribute("gameDailyValsJson", jsonLongArray(new ArrayList<>(gamesByDay14.values())));
		model.addAttribute("gameWeeklyKeysJson", jsonStringArray(new ArrayList<>(gamesByWeek12.keySet())));
		model.addAttribute("gameWeeklyValsJson", jsonLongArray(new ArrayList<>(gamesByWeek12.values())));
		model.addAttribute("gameMonthlyKeysJson", jsonStringArray(new ArrayList<>(gamesByMonth12.keySet())));
		model.addAttribute("gameMonthlyValsJson", jsonLongArray(new ArrayList<>(gamesByMonth12.values())));
		model.addAttribute("gamePhaseDailyLabelsJson", jsonStringArray(castStringList(phaseDaily.get("labels"))));
		model.addAttribute("gamePhaseDailyValuesJson", jsonLongArray(castLongList(phaseDaily.get("values"))));
		model.addAttribute("gamePhaseWeeklyLabelsJson", jsonStringArray(castStringList(phaseWeekly.get("labels"))));
		model.addAttribute("gamePhaseWeeklyValuesJson", jsonLongArray(castLongList(phaseWeekly.get("values"))));
		model.addAttribute("gamePhaseMonthlyLabelsJson", jsonStringArray(castStringList(phaseMonthly.get("labels"))));
		model.addAttribute("gamePhaseMonthlyValuesJson", jsonLongArray(castLongList(phaseMonthly.get("values"))));
		model.addAttribute("hourlyPlayDailyLabelsJson", jsonStringArray(new ArrayList<>(hourlyPlayDaily.keySet())));
		model.addAttribute("hourlyPlayDailyValuesJson", jsonLongArray(new ArrayList<>(hourlyPlayDaily.values())));
		model.addAttribute("hourlyPlayWeeklyLabelsJson", jsonStringArray(new ArrayList<>(hourlyPlayWeekly.keySet())));
		model.addAttribute("hourlyPlayWeeklyValuesJson", jsonLongArray(new ArrayList<>(hourlyPlayWeekly.values())));
		model.addAttribute("hourlyPlayMonthlyLabelsJson", jsonStringArray(new ArrayList<>(hourlyPlayMonthly.keySet())));
		model.addAttribute("hourlyPlayMonthlyValuesJson", jsonLongArray(new ArrayList<>(hourlyPlayMonthly.values())));
		model.addAttribute("dropOffDailyLabelsJson", jsonStringArray(new ArrayList<>(dropOffDaily.keySet())));
		model.addAttribute("dropOffDailyValuesJson", jsonLongArray(new ArrayList<>(dropOffDaily.values())));
		model.addAttribute("dropOffWeeklyLabelsJson", jsonStringArray(new ArrayList<>(dropOffWeekly.keySet())));
		model.addAttribute("dropOffWeeklyValuesJson", jsonLongArray(new ArrayList<>(dropOffWeekly.values())));
		model.addAttribute("dropOffMonthlyLabelsJson", jsonStringArray(new ArrayList<>(dropOffMonthly.keySet())));
		model.addAttribute("dropOffMonthlyValuesJson", jsonLongArray(new ArrayList<>(dropOffMonthly.values())));

		enrichShopAdmin(model, totalMembers);
		enrichGachaAdminSummary(model);
		enrichCoinOps(model, query, memberPage, coinPageParam);

		return "admin/dashboard";
	}

	private void enrichCoinOps(Model model, String query, int memberPage, int coinPageParam) {
		LocalDateTime dayStart = LocalDate.now(GACHA_ADMIN_ZONE).atStartOfDay();
		LocalDateTime coinLogFrom = LocalDateTime.now(GACHA_ADMIN_ZONE).minusMonths(1);
		final int coinLogPageSize = 10;
		int coinLogPage = Math.max(1, coinPageParam);
		long coinLogTotal = marketService.countRecentCoinTxnLogs(coinLogFrom);
		int coinLogTotalPages = coinLogTotal == 0 ? 1 : (int) Math.ceil(coinLogTotal / (double) coinLogPageSize);
		if (coinLogPage > coinLogTotalPages) {
			coinLogPage = coinLogTotalPages;
		}
		int coinLogRowFrom = coinLogTotal == 0 ? 0 : (coinLogPage - 1) * coinLogPageSize + 1;
		int coinLogRowTo = (int) Math.min(coinLogTotal, (long) coinLogPage * coinLogPageSize);

		CoinKpiDto coinKpi = marketService.getCoinOpsKpi(dayStart);
		List<CoinFlowDto> coinFlowDaily = marketService.getCoinFlowDaily(14);
		List<CoinFlowDto> coinFlowWeekly = marketService.getCoinFlowWeekly(12);
		List<CoinFlowDto> coinFlowMonthly = marketService.getCoinFlowMonthly(12);
		List<CoinDistributionDto> coinDistribution = marketService.getCoinDistribution();
		List<CoinTxnLogDto> coinRecentLogs = marketService.getRecentCoinTxnLogs(coinLogFrom, coinLogPage, coinLogPageSize);

		model.addAttribute("coinKpi", coinKpi);
		model.addAttribute("coinRecentLogs", coinRecentLogs);
		model.addAttribute("coinDistribution", coinDistribution);
		model.addAttribute("coinLogPage", coinLogPage);
		model.addAttribute("coinLogPageSize", coinLogPageSize);
		model.addAttribute("coinLogTotal", coinLogTotal);
		model.addAttribute("coinLogTotalPages", coinLogTotalPages);
		model.addAttribute("coinLogRowFrom", coinLogRowFrom);
		model.addAttribute("coinLogRowTo", coinLogRowTo);
		model.addAttribute("coinLogFromDays", 30);
		model.addAttribute("coinQueryForPager", query == null ? "" : query);
		model.addAttribute("coinMemberPageForPager", memberPage);

		model.addAttribute("coinFlowDailyLabelsJson", jsonStringArray(coinFlowDaily.stream().map(CoinFlowDto::label).collect(Collectors.toList())));
		model.addAttribute("coinFlowDailyChargeJson", jsonLongArray(coinFlowDaily.stream().map(CoinFlowDto::chargeCoins).collect(Collectors.toList())));
		model.addAttribute("coinFlowDailyUsedJson", jsonLongArray(coinFlowDaily.stream().map(CoinFlowDto::usedCoins).collect(Collectors.toList())));
		model.addAttribute("coinFlowDailyNetJson", jsonLongArray(coinFlowDaily.stream().map(CoinFlowDto::netIncreaseCoins).collect(Collectors.toList())));

		model.addAttribute("coinFlowWeeklyLabelsJson", jsonStringArray(coinFlowWeekly.stream().map(CoinFlowDto::label).collect(Collectors.toList())));
		model.addAttribute("coinFlowWeeklyChargeJson", jsonLongArray(coinFlowWeekly.stream().map(CoinFlowDto::chargeCoins).collect(Collectors.toList())));
		model.addAttribute("coinFlowWeeklyUsedJson", jsonLongArray(coinFlowWeekly.stream().map(CoinFlowDto::usedCoins).collect(Collectors.toList())));
		model.addAttribute("coinFlowWeeklyNetJson", jsonLongArray(coinFlowWeekly.stream().map(CoinFlowDto::netIncreaseCoins).collect(Collectors.toList())));

		model.addAttribute("coinFlowMonthlyLabelsJson", jsonStringArray(coinFlowMonthly.stream().map(CoinFlowDto::label).collect(Collectors.toList())));
		model.addAttribute("coinFlowMonthlyChargeJson", jsonLongArray(coinFlowMonthly.stream().map(CoinFlowDto::chargeCoins).collect(Collectors.toList())));
		model.addAttribute("coinFlowMonthlyUsedJson", jsonLongArray(coinFlowMonthly.stream().map(CoinFlowDto::usedCoins).collect(Collectors.toList())));
		model.addAttribute("coinFlowMonthlyNetJson", jsonLongArray(coinFlowMonthly.stream().map(CoinFlowDto::netIncreaseCoins).collect(Collectors.toList())));

		model.addAttribute("coinDistributionLabelsJson", jsonStringArray(coinDistribution.stream().map(CoinDistributionDto::rangeLabel).collect(Collectors.toList())));
		model.addAttribute("coinDistributionValuesJson", jsonLongArray(coinDistribution.stream().map(CoinDistributionDto::memberCount).collect(Collectors.toList())));
	}

	/** 관리자 대시보드용: 뽑기 누적 건수·참여 회원 수 */
	private void enrichGachaAdminSummary(Model model) {
		model.addAttribute("gachaTotalPulls", gachaPullLogRepository.count());
		model.addAttribute("gachaDistinctPullers", gachaPullLogRepository.countDistinctMembers());
	}


	/** 관리자 대시보드·상점 화면 공통: 마켓(코인·인벤토리) 집계 */
	private void enrichShopAdmin(Model model, long totalMembers) {
		long shopTotalCoins = marketService.sumAllMemberCoins();
		long shopTotalItemQty = marketService.sumAllItemQuantities();
		long shopMembersWithInventory = marketService.countMembersWithMyItems();
		long shopAvgCoin = totalMembers > 0 ? shopTotalCoins / totalMembers : 0L;
		model.addAttribute("shopTotalCoins", shopTotalCoins);
		model.addAttribute("shopTotalItemQty", shopTotalItemQty);
		model.addAttribute("shopMembersWithInventory", shopMembersWithInventory);
		model.addAttribute("shopAvgCoin", shopAvgCoin);
		model.addAttribute("shopTopItems", marketService.topItemsByTotalQuantity(12));
		model.addAttribute("shopTopCoinMembers", marketService.topMembersByCoin(10));

		LocalDateTime nowSeoul = LocalDateTime.now(GACHA_ADMIN_ZONE);
		LocalDate todaySeoul = LocalDate.now(GACHA_ADMIN_ZONE);
		LocalDateTime shopDayStart = todaySeoul.atStartOfDay();
		LocalDateTime shopWeekStart = nowSeoul.minusDays(7);
		LocalDateTime shopMonthStart = todaySeoul.withDayOfMonth(1).atStartOfDay();
		model.addAttribute("shopChargeDay", marketService.sumChargedCoinsSince(shopDayStart));
		model.addAttribute("shopChargeWeek", marketService.sumChargedCoinsSince(shopWeekStart));
		model.addAttribute("shopChargeMonth", marketService.sumChargedCoinsSince(shopMonthStart));
		model.addAttribute("shopTopPurchaseItems", marketService.topPurchaseCountsByItem(12));
	}

	@GetMapping("/shop")
	public String adminShop(HttpSession session, Model model) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login?redirect=/admin/shop";
		}
		return "redirect:/admin/analytics/usage";
	}

	@GetMapping("/gacha")
	public String adminGacha(HttpSession session, Model model) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login?redirect=/admin/gacha";
		}
		return "redirect:/admin/analytics/usage";
	}

	@GetMapping("/analytics/usage")
	public String usageAnalytics(HttpSession session, Model model,
			@RequestParam(name = "period", defaultValue = "daily") String period,
			@RequestParam(name = "logPage", defaultValue = "1") int logPageParam) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login?redirect=/admin/analytics/usage";
		}

		String normalizedPeriod = switch (period == null ? "" : period.toLowerCase()) {
		case "weekly" -> "weekly";
		case "monthly" -> "monthly";
		default -> "daily";
		};

		LocalDate nowDate = LocalDate.now(GACHA_ADMIN_ZONE);
		LocalDateTime nowTime = LocalDateTime.now(GACHA_ADMIN_ZONE);
		LocalDateTime rangeFrom = switch (normalizedPeriod) {
		case "weekly" -> nowDate.minusDays(6).atStartOfDay();
		case "monthly" -> nowDate.withDayOfMonth(1).atStartOfDay();
		default -> nowDate.atStartOfDay();
		};

		UsageKpiDto kpi = usageAnalyticsService.getTodayKpi();
		UsageRatioDto usageRatio = usageAnalyticsService.getUsageRatio(rangeFrom, nowTime);

		long usageLogTotal = usageAnalyticsService.countUsageLogs(rangeFrom, nowTime);
		int usageLogTotalPages = usageLogTotal == 0 ? 1 : (int) Math.ceil(usageLogTotal / (double) USAGE_LOG_PAGE_SIZE);
		int usageLogPage = Math.max(1, Math.min(logPageParam, usageLogTotalPages));
		List<UsageLogDto> usageLogs = usageAnalyticsService.getUsageLogsPage(rangeFrom, nowTime, usageLogPage,
				USAGE_LOG_PAGE_SIZE);
		int usageLogRowFrom = usageLogTotal == 0 ? 0 : (usageLogPage - 1) * USAGE_LOG_PAGE_SIZE + 1;
		int usageLogRowTo = (int) Math.min(usageLogTotal, (long) usageLogPage * USAGE_LOG_PAGE_SIZE);

		List<Integer> usageLogPageNumbers = new ArrayList<>();
		if (usageLogTotalPages > 0) {
			int window = 10;
			int half = window / 2;
			int start = Math.max(1, usageLogPage - half);
			int end = Math.min(usageLogTotalPages, start + window - 1);
			start = Math.max(1, end - window + 1);
			for (int i = start; i <= end; i++) {
				usageLogPageNumbers.add(i);
			}
		}

		List<UsageFlowDto> flowDaily = usageAnalyticsService.getUsageFlow(nowDate.minusDays(13), nowDate);
		LocalDate weeklyStart = nowDate.with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY)).minusWeeks(11);
		List<UsageFlowDto> flowWeeklyRaw = usageAnalyticsService.getUsageFlow(weeklyStart, nowDate);
		List<UsageFlowDto> flowWeekly = aggregateWeeklyFlow(flowWeeklyRaw, 12);
		List<UsageFlowDto> flowMonthlyRaw = usageAnalyticsService
				.getUsageFlow(nowDate.withDayOfMonth(1).minusMonths(11), nowDate);
		List<UsageFlowDto> flowMonthly = aggregateMonthlyFlow(flowMonthlyRaw, 12);

		model.addAttribute("usagePeriod", normalizedPeriod);
		model.addAttribute("kpi", kpi);
		model.addAttribute("usageRatio", usageRatio);
		model.addAttribute("shopTopList", usageAnalyticsService.getShopUsageTop(rangeFrom, nowTime, 8));
		model.addAttribute("gachaTopList", usageAnalyticsService.getGachaUsageTop(rangeFrom, nowTime, 8));
		model.addAttribute("usageLogs", usageLogs);
		model.addAttribute("usageLogPage", usageLogPage);
		model.addAttribute("usageLogPageSize", USAGE_LOG_PAGE_SIZE);
		model.addAttribute("usageLogTotal", usageLogTotal);
		model.addAttribute("usageLogTotalPages", usageLogTotalPages);
		model.addAttribute("usageLogRowFrom", usageLogRowFrom);
		model.addAttribute("usageLogRowTo", usageLogRowTo);
		model.addAttribute("usageLogPageNumbers", usageLogPageNumbers);
		model.addAttribute("flowChartData",
				switch (normalizedPeriod) {
				case "weekly" -> flowWeekly;
				case "monthly" -> flowMonthly;
				default -> flowDaily;
				});

		model.addAttribute("flowDailyLabelsJson",
				jsonStringArray(flowDaily.stream().map(UsageFlowDto::label).collect(Collectors.toList())));
		model.addAttribute("flowDailyTotalJson",
				jsonLongArray(flowDaily.stream().map(UsageFlowDto::total).collect(Collectors.toList())));
		model.addAttribute("flowDailyShopJson",
				jsonLongArray(flowDaily.stream().map(UsageFlowDto::shop).collect(Collectors.toList())));
		model.addAttribute("flowDailyGachaJson",
				jsonLongArray(flowDaily.stream().map(UsageFlowDto::gacha).collect(Collectors.toList())));

		model.addAttribute("flowWeeklyLabelsJson",
				jsonStringArray(flowWeekly.stream().map(UsageFlowDto::label).collect(Collectors.toList())));
		model.addAttribute("flowWeeklyTotalJson",
				jsonLongArray(flowWeekly.stream().map(UsageFlowDto::total).collect(Collectors.toList())));
		model.addAttribute("flowWeeklyShopJson",
				jsonLongArray(flowWeekly.stream().map(UsageFlowDto::shop).collect(Collectors.toList())));
		model.addAttribute("flowWeeklyGachaJson",
				jsonLongArray(flowWeekly.stream().map(UsageFlowDto::gacha).collect(Collectors.toList())));

		model.addAttribute("flowMonthlyLabelsJson",
				jsonStringArray(flowMonthly.stream().map(UsageFlowDto::label).collect(Collectors.toList())));
		model.addAttribute("flowMonthlyTotalJson",
				jsonLongArray(flowMonthly.stream().map(UsageFlowDto::total).collect(Collectors.toList())));
		model.addAttribute("flowMonthlyShopJson",
				jsonLongArray(flowMonthly.stream().map(UsageFlowDto::shop).collect(Collectors.toList())));
		model.addAttribute("flowMonthlyGachaJson",
				jsonLongArray(flowMonthly.stream().map(UsageFlowDto::gacha).collect(Collectors.toList())));

		model.addAttribute("ratioShop", usageRatio.shop());
		model.addAttribute("ratioGacha", usageRatio.gacha());
		model.addAttribute("ratioEtc", usageRatio.etc());

		return "admin/usage-analytics";
	}

	/* ─────────────── 회원 강제탈퇴 ─────────────── */
	@PostMapping("/members/{mno}/delete")
	@Transactional
	public String deleteMember(@PathVariable("mno") Long mno, HttpSession session, RedirectAttributes ra) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		memberRepository.findById(mno).ifPresent(memberRepository::delete);
		ra.addFlashAttribute("success", "회원이 강제 탈퇴 처리되었습니다.");
		return "redirect:/admin";
	}

	@PostMapping("/members/{mno}/suspend")
	@Transactional
	public String suspendMember(@PathVariable("mno") Long mno,
			@RequestParam("days") int days,
			@RequestParam(name = "reason", required = false) String reason,
			HttpSession session,
			RedirectAttributes ra) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		int safeDays = Math.max(1, Math.min(days, 365));
		LoginMember admin = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		memberRepository.findById(mno).ifPresent(member -> {
			LocalDateTime until = LocalDateTime.now().plusDays(safeDays);
			member.setSuspendedUntil(until);
			memberRepository.save(member);
			memberSanctionRepository.save(new MemberSanction(
					member.getMno(),
					admin == null ? null : admin.mno(),
					admin == null ? "관리자" : admin.nickname(),
					safeDays,
					reason == null ? "" : reason.trim(),
					until));
		});
		ra.addFlashAttribute("success", "회원을 " + safeDays + "일 정지 처리했습니다.");
		return "redirect:/admin#members";
	}

	/* ─────────────── 연습생 수정 ─────────────── */
	@PostMapping("/trainees/{id}/edit")
	@Transactional
	public String editTrainee(@PathVariable("id") Long id, @RequestParam("name") String name,
			@RequestParam("grade") String grade,
			@RequestParam("vocal") int vocal, @RequestParam("dance") int dance,
			@RequestParam("star") int star, @RequestParam("mental") int mental, @RequestParam("teamwork") int teamwork,
			HttpSession session, RedirectAttributes ra) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		traineeRepository.findById(id).ifPresent(t -> {
			t.setName(name);
			// 스탯 스케일: 0~20
			t.setVocal(Math.max(0, Math.min(100, vocal)));
			t.setDance(Math.max(0, Math.min(100, dance)));
			t.setStar(Math.max(0, Math.min(100, star)));
			t.setMental(Math.max(0, Math.min(100, mental)));
			t.setTeamwork(Math.max(0, Math.min(100, teamwork)));
			try {
				t.setGrade(grade != null && !grade.isBlank() ? Grade.valueOf(grade.trim()) : null);
			} catch (IllegalArgumentException ignored) {
				t.setGrade(null);
			}
		});
		ra.addFlashAttribute("success", "연습생 정보가 수정되었습니다.");
		return "redirect:/admin#trainees";
	}

	/* ─────────────── 연습생 삭제 ─────────────── */
	@PostMapping("/trainees/{id}/delete")
	@Transactional
	public String deleteTrainee(@PathVariable("id") Long id, HttpSession session, RedirectAttributes ra) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		traineeRepository.deleteById(id);
		ra.addFlashAttribute("success", "연습생이 삭제되었습니다.");
		return "redirect:/admin#trainees";
	}

	/* ─────────────── 신고 게시글 목록 ─────────────── */
	@GetMapping("/reports")
	public String reportList(HttpSession session, Model model) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		List<Board> reportedPosts = boardRepository.findByBoardTypeOrderByCreatedAtDesc("report");
		Map<Long, Boolean> reportHandledMap = new LinkedHashMap<>();
		for (Board b : reportedPosts) {
			reportHandledMap.put(b.getId(), boardService.isReportHandled(b));
		}
		model.addAttribute("reportedPosts", reportedPosts);
		model.addAttribute("reportHandledMap", reportHandledMap);
		return "admin/reports";
	}

	/* ─────────────── 신고 게시글 처리 ─────────────── */
	@PostMapping("/reports/{id}/handle")
	@Transactional
	public String handleReport(@PathVariable("id") Long id, @RequestParam("action") String action,
			@RequestParam(value = "from", required = false) String from,
			HttpSession session, RedirectAttributes ra) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		if ("detail".equalsIgnoreCase(action)) {
			return "redirect:" + boardService.resolveReportDetailPath(id);
		}
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		String message;
		if ("complete".equalsIgnoreCase(action) && lm != null) {
			message = boardService.completeReportBoardByAdmin(id, lm.nickname(), lm.mno());
		} else {
			message = boardService.handleReportAction(id, action);
		}
		ra.addFlashAttribute("success", message == null ? "신고 처리 요청이 반영되지 않았습니다." : message);
		return "reports".equalsIgnoreCase(from) ? "redirect:/admin/reports" : "redirect:/admin";
	}

	@PostMapping("/reports/{id}/comment")
	@Transactional
	public String addReportHandlingComment(@PathVariable("id") Long id,
			@RequestParam("content") String content,
			HttpSession session,
			RedirectAttributes ra) {
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (lm == null) {
			return "redirect:/login";
		}
		String message = boardService.addAdminHandlingComment(id, content, lm.nickname(), lm.mno());
		ra.addFlashAttribute("success", message == null ? "처리 코멘트 등록에 실패했습니다. (1~500자 확인)" : message);
		return "redirect:/admin";
	}

	/* ─────────────── 게임 상세 통계 ─────────────── */
	@GetMapping("/game-stats")
	public String gameStats(HttpSession session, Model model) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		List<GameRun> runs = gameRunRepository.findAll();

		Map<String, Long> phaseCounts = runs.stream()
				.collect(Collectors.groupingBy(g -> g.getPhase() == null ? "UNKNOWN" : g.getPhase(),
						Collectors.counting()));

		Map<Boolean, Long> confirmedCounts = runs.stream()
				.collect(Collectors.groupingBy(GameRun::isConfirmed, Collectors.counting()));
		Map<String, Object> mlChoiceStats = collectMlChoiceStats();

		model.addAttribute("phaseCounts", phaseCounts);
		model.addAttribute("confirmedCounts", confirmedCounts);
		model.addAttribute("mlChoiceStats", mlChoiceStats);
		return "admin/game-stats";
	}

	@GetMapping("/game-scenes")
	public String gameScenesPage(HttpSession session, Model model) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin/game-scenes";
		}
		List<GameScene> gameScenes = gameSceneRepository.findAllByOrderByPhaseAscIdAsc();
		TreeSet<String> gamePhaseSuggestionSet = new TreeSet<>();
		TreeSet<String> gameEventTypeSuggestionSet = new TreeSet<>();
		for (GameScene s : gameScenes) {
			if (s.getPhase() != null && !s.getPhase().isBlank()) {
				gamePhaseSuggestionSet.add(s.getPhase().trim());
			}
			if (s.getEventType() != null && !s.getEventType().isBlank()) {
				gameEventTypeSuggestionSet.add(s.getEventType().trim());
			}
		}
		for (GameChoice c : gameChoiceRepository.findAllByOrderByPhaseAscSortOrderAsc()) {
			if (c.getPhase() != null && !c.getPhase().isBlank()) {
				gamePhaseSuggestionSet.add(c.getPhase().trim());
			}
		}
		model.addAttribute("gameScenes", gameScenes);
		model.addAttribute("gamePhaseSuggestions", new ArrayList<>(gamePhaseSuggestionSet));
		model.addAttribute("gameEventTypeSuggestions", new ArrayList<>(gameEventTypeSuggestionSet));
		return "admin/game-scenes";
	}

	@GetMapping("/game-choices")
	public String gameChoicesPage(HttpSession session, Model model) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin/game-choices";
		}
		List<GameChoice> gameChoices = gameChoiceRepository.findAllByOrderByPhaseAscSortOrderAsc();
		TreeSet<String> gamePhaseSuggestionSet = new TreeSet<>();
		for (GameScene s : gameSceneRepository.findAllByOrderByPhaseAscIdAsc()) {
			if (s.getPhase() != null && !s.getPhase().isBlank()) {
				gamePhaseSuggestionSet.add(s.getPhase().trim());
			}
		}
		for (GameChoice c : gameChoices) {
			if (c.getPhase() != null && !c.getPhase().isBlank()) {
				gamePhaseSuggestionSet.add(c.getPhase().trim());
			}
		}
		model.addAttribute("gameChoices", gameChoices);
		model.addAttribute("gamePhaseSuggestions", new ArrayList<>(gamePhaseSuggestionSet));
		return "admin/game-choices";
	}

	@GetMapping("/game-events")
	public String gameEventsPage(HttpSession session, Model model) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin/game-events";
		}
		if (gameMiniQuizRepository.count() == 0) {
			gameMiniQuizRepository.saveAll(defaultMiniQuizSeedRows());
		}
		model.addAttribute("gameMiniQuizzes", gameMiniQuizRepository.findAllByOrderBySortOrderAscIdAsc());
		return "admin/game-events";
	}

	/* ─────────────── 공지사항 목록 ─────────────── */
	@GetMapping("/notices")
	public String noticeList(HttpSession session, Model model) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		List<Board> notices = boardRepository.findByBoardTypeOrderByCreatedAtDesc("notice");
		model.addAttribute("notices", notices);
		return "admin/notices";
	}

	/* ─────────────── 공지사항 등록 ─────────────── */
	@PostMapping("/notices")
	@Transactional
	public String createNotice(@RequestParam("title") String title, @RequestParam("content") String content,
			@RequestParam(name = "popup", defaultValue = "false") boolean popup,
			HttpSession session, RedirectAttributes ra) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		Long adminMno = extractMno(lm);
		Board notice = new Board("notice", null, title, content, null, null, false, "관리자", adminMno, false);
		notice.setPopup(popup);
		boardRepository.save(notice);
		ra.addFlashAttribute("success", "공지사항이 등록되었습니다.");
		return "redirect:/admin";
	}

	@PostMapping("/notices/{id}/pin")
	@Transactional
	public String toggleNoticePin(@PathVariable("id") Long id, HttpSession session, RedirectAttributes ra) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		String message = boardService.toggleNoticePin(id);
		ra.addFlashAttribute("success", message == null ? "공지 상태를 변경하지 못했습니다." : message);
		return "redirect:/admin";
	}

	@PostMapping("/notices/{id}/delete")
	@Transactional
	public String deleteNotice(@PathVariable("id") Long id, HttpSession session, RedirectAttributes ra) {
		if (session.getAttribute("LOGIN_MEMBER") == null) {
			return "redirect:/login";
		}
		boolean deleted = boardService.deleteNotice(id);
		ra.addFlashAttribute("success", deleted ? "공지사항을 삭제했습니다." : "삭제할 공지를 찾지 못했습니다.");
		return "redirect:/admin";
	}

	@PostMapping("/fanmeeting/{id}/visibility")
	@Transactional
	public String toggleFanMeetingVisibility(@PathVariable("id") Long id,
			@RequestParam(name = "visible", required = false) String visible,
			@RequestParam(name = "fanMeetingPage", defaultValue = "1") int fanMeetingPage,
			@RequestParam(name = "fanMeetingStatus", defaultValue = "all") String fanMeetingStatus,
			@RequestParam(name = "page", defaultValue = "1") int memberPage,
			@RequestParam(name = "coinPage", defaultValue = "1") int coinPage,
			@RequestParam(name = "noticePage", defaultValue = "1") int noticePage,
			@RequestParam(name = "q", required = false) String q,
			HttpSession session, RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin";
		}
		Board post = boardRepository.findById(id).orElse(null);
		if (post == null || !"fanmeeting".equalsIgnoreCase(post.getBoardType())) {
			ra.addFlashAttribute("error", "팬미팅 게시글을 찾을 수 없습니다.");
		} else {
			boolean nextVisible = !"false".equalsIgnoreCase(visible);
			post.setVisible(nextVisible);
			boardRepository.save(post);
			ra.addFlashAttribute("success", nextVisible ? "팬미팅 글 블라인드를 해제했습니다." : "팬미팅 글을 블라인드 처리했습니다.");
		}
		String safeQ = q == null ? "" : q.trim();
		String safeStatus = fanMeetingStatus == null ? "all" : fanMeetingStatus.trim().toLowerCase();
		return "redirect:/admin?page=" + Math.max(1, memberPage)
				+ "&coinPage=" + Math.max(1, coinPage)
				+ "&noticePage=" + Math.max(1, noticePage)
				+ "&fanMeetingPage=" + Math.max(1, fanMeetingPage)
				+ "&fanMeetingStatus=" + safeStatus
				+ (safeQ.isBlank() ? "" : "&q=" + safeQ)
				+ "#board-ops";
	}

	/* ─────────────── 회원 상세 (AJAX) ─────────────── */
	@GetMapping("/members/{mno}/detail")
	@Transactional(readOnly = true)
	@ResponseBody
	public ResponseEntity<Map<String, Object>> memberDetail(@PathVariable("mno") Long mno, HttpSession session) {
		if (!isAdminSession(session)) {
			return ResponseEntity.status(401).body(Map.of("error", "로그인이 필요합니다."));
		}
		Member m = memberRepository.findById(mno).orElse(null);
		if (m == null) {
			return ResponseEntity.status(404).body(Map.of("error", "회원을 찾을 수 없습니다."));
		}

		List<GameRun> runs = gameRunRepository.findByPlayerMnoOrderByCreatedAtDesc(mno).stream().limit(5)
				.collect(Collectors.toList());
		List<Map<String, Object>> runRows = runs.stream().map(r -> {
			Map<String, Object> row = new LinkedHashMap<>();
			row.put("runId", r.getRunId());
			row.put("groupType", r.getGroupType());
			row.put("phase", r.getPhase());
			row.put("createdAt", r.getCreatedAt() == null ? "" : r.getCreatedAt().toString());
			return row;
		}).collect(Collectors.toList());

		MemberRank effectiveRank = MemberRank.getRankByExp(m.getRankExp());
		List<Map<String, String>> rankOptions = Arrays.stream(MemberRank.values()).map(rank -> {
			Map<String, String> opt = new LinkedHashMap<>();
			opt.put("code", rank.name());
			opt.put("label", rank.displayName());
			return opt;
		}).collect(Collectors.toList());

		Map<String, Object> body = new LinkedHashMap<>();
		body.put("mno", m.getMno());
		body.put("mid", nz(m.getMid()));
		body.put("name", nz(m.getMname()));
		body.put("nickname", nz(m.getNickname()));
		body.put("email", nz(m.getEmail()));
		body.put("phone", nz(m.getPhone()));
		body.put("address", nz(m.getAddress()));
		body.put("addressDetail", nz(m.getAddressDetail()));
		String plainJumin = juminCryptoService.decrypt(m.getJumin());
		body.put("jumin", nz(juminCryptoService.mask(plainJumin)));
		body.put("profileImage", nz(m.getProfileImage()));
		body.put("role", nz(m.getRole()));
		body.put("accountStatus", m.getAccountStatusLabel());
		body.put("suspendedUntil", m.getSuspendedUntilStr());
		body.put("suspendRemainingDays", m.getSuspendRemainingDays());
		body.put("createdAt", m.getCreatedAtStr());
		body.put("rerollRemaining", m.getRerollRemaining());
		body.put("rerollLastAt", m.getRerollLastAt() == null ? "" : m.getRerollLastAt().toString());
		body.put("rankExp", m.getRankExp());
		body.put("memberRankCode", nz(m.getMemberRankCode()));
		body.put("effectiveRankCode", effectiveRank.name());
		body.put("effectiveRankLabel", effectiveRank.displayName());
		body.put("rankOptions", rankOptions);
		body.put("recentRuns", runRows);
		MemberOpsDetailDto ops = adminMemberOpsService.getMemberOpsDetail(mno);
		body.put("coin", ops.coin());
		body.put("traineeCount", ops.traineeCount());
		body.put("photoCardCount", ops.photoCardCount());
		body.put("ownedTrainees", ops.traineeNames());
		body.put("ownedTraineeRows", adminMemberOpsService.getOwnedTraineeRows(mno));
		body.put("ownedPhotoCards", ops.photoCards());
		body.put("recentActivities", adminMemberOpsService.getRecentActivities(mno));
		body.put("recentSanctions", memberSanctionRepository.findTop10ByMemberMnoOrderByCreatedAtDesc(mno).stream()
				.map(s -> {
					Map<String, Object> row = new LinkedHashMap<>();
					row.put("days", s.getSanctionDays());
					row.put("adminNick", nz(s.getAdminNick()));
					row.put("reason", nz(s.getReason()));
					row.put("createdAt", s.getCreatedAtStr());
					row.put("expiresAt", s.getExpiresAtStr());
					return row;
				}).collect(Collectors.toList()));
		body.put("allTrainees", traineeRepository.findAll().stream().map(t -> {
			Map<String, Object> row = new LinkedHashMap<>();
			row.put("id", t.getId());
			row.put("name", t.getName());
			return row;
		}).collect(Collectors.toList()));
		List<Map<String, Object>> photoCardMasterOptions = new ArrayList<>();
		for (PhotoCardMaster master : photoCardMasterRepository.findAll()) {
			Map<String, Object> row = new LinkedHashMap<>();
			row.put("traineeId", master.getTrainee().getId());
			row.put("traineeName", master.getTrainee().getName());
			row.put("grade", master.getGrade().name());
			photoCardMasterOptions.add(row);
		}
		body.put("photoCardMasterOptions", photoCardMasterOptions);
		return ResponseEntity.ok(body);
	}

	/** Map.of / JSON 등에 넣을 때 null 대신 빈 문자열 (Map.of는 null 값 불가) */
	private static String nz(String s) {
		return s == null ? "" : s;
	}

	/**
	 * LoginMember가 record(mno()) 혹은 일반 클래스(getMno())일 때 모두 호환.
	 */
	private static Long extractMno(Object loginMember) {
		if (loginMember == null) {
			return null;
		}
		try {
			Object value = loginMember.getClass().getMethod("mno").invoke(loginMember);
			if (value instanceof Number n) {
				return n.longValue();
			}
		} catch (ReflectiveOperationException ignored) {
			// no-op
		}
		try {
			Object value = loginMember.getClass().getMethod("getMno").invoke(loginMember);
			if (value instanceof Number n) {
				return n.longValue();
			}
		} catch (ReflectiveOperationException ignored) {
			// no-op
		}
		return null;
	}

	/** 관리자: 회원 팬 등급(티어) 지정 — 선택 등급의 최소 경험치로 맞춰 실제 표시 등급과 일치시킨다. */
	@PostMapping("/members/{mno}/grade")
	@Transactional
	@ResponseBody
	public ResponseEntity<Map<String, Object>> updateMemberGrade(@PathVariable("mno") Long mno,
			@RequestParam("memberRankCode") String memberRankCode, HttpSession session) {
		if (session.getAttribute(SessionConst.LOGIN_MEMBER) == null) {
			return ResponseEntity.status(401).body(Map.of("error", "로그인이 필요합니다."));
		}
		Member member = memberRepository.findById(mno).orElse(null);
		if (member == null) {
			return ResponseEntity.status(404).body(Map.of("error", "회원을 찾을 수 없습니다."));
		}
		MemberRank rank = MemberRank.fromCode(memberRankCode);
		member.setRankExp(rank.minExp());
		member.setMemberRankCode(rank.name());
		memberRepository.save(member);
		Map<String, Object> ok = new LinkedHashMap<>();
		ok.put("ok", true);
		ok.put("memberRankCode", rank.name());
		ok.put("rankLabel", rank.displayName());
		ok.put("rankExp", member.getRankExp());
		ok.put("effectiveRankLabel", rank.displayName());
		return ResponseEntity.ok(ok);
	}

	@PostMapping("/member/{id}/coin")
	@Transactional
	@ResponseBody
	public ResponseEntity<Map<String, Object>> adjustMemberCoin(@PathVariable("id") Long id,
			@RequestBody CoinAdjustRequest request, HttpSession session) {
		if (!isAdminSession(session)) {
			return ResponseEntity.status(401).body(Map.of("error", "관리자 권한이 필요합니다."));
		}
		try {
			long after = adminMemberOpsService.adjustCoin(id, request == null ? null : request.getType(),
					request == null ? 0L : request.getAmount(),
					request == null ? null : request.getReason());
			return ResponseEntity.ok(Map.of("ok", true, "coin", after));
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
		}
	}

	@PostMapping("/member/{id}/trainee")
	@Transactional
	@ResponseBody
	public ResponseEntity<Map<String, Object>> addMemberTrainee(@PathVariable("id") Long id,
			@RequestParam(name = "traineeIds", required = false) List<Long> traineeIds,
			@RequestParam(name = "traineeId", required = false) Long traineeId,
			HttpSession session) {
		if (!isAdminSession(session)) {
			return ResponseEntity.status(401).body(Map.of("error", "관리자 권한이 필요합니다."));
		}
		try {
			List<Long> selectedIds = new ArrayList<>();
			if (traineeIds != null) {
				selectedIds.addAll(traineeIds);
			}
			if (traineeId != null) {
				selectedIds.add(traineeId);
			}
			Map<String, Integer> result = adminMemberOpsService.addTraineesToMember(id, selectedIds);
			return ResponseEntity.ok(Map.of(
					"ok", true,
					"addedCount", result.getOrDefault("addedCount", 0),
					"skippedCount", result.getOrDefault("skippedCount", 0)));
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
		}
	}

	@PostMapping("/member/{id}/photocard")
	@Transactional
	@ResponseBody
	public ResponseEntity<Map<String, Object>> grantMemberPhotoCard(@PathVariable("id") Long id,
			@RequestBody PhotoCardGrantRequest request, HttpSession session) {
		if (!isAdminSession(session)) {
			return ResponseEntity.status(401).body(Map.of("error", "관리자 권한이 필요합니다."));
		}
		try {
			List<Long> selectedIds = new ArrayList<>();
			if (request != null && request.getTraineeIds() != null) {
				selectedIds.addAll(request.getTraineeIds());
			}
			if (request != null && request.getTraineeId() != null) {
				selectedIds.add(request.getTraineeId());
			}
			Map<String, Integer> result = adminMemberOpsService.grantPhotoCards(id, selectedIds,
					request == null ? null : request.getGrade());
			return ResponseEntity.ok(Map.of(
					"ok", true,
					"grantedCount", result.getOrDefault("grantedCount", 0),
					"skippedCount", result.getOrDefault("skippedCount", 0)));
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
		}
	}

	@PostMapping("/member/{id}/enhance")
	@Transactional
	@ResponseBody
	public ResponseEntity<Map<String, Object>> adjustMemberEnhance(@PathVariable("id") Long id,
			@RequestBody AdminEnhanceAdjustRequest request, HttpSession session) {
		if (!isAdminSession(session)) {
			return ResponseEntity.status(401).body(Map.of("error", "관리자 권한이 필요합니다."));
		}
		if (request == null || request.getTraineeId() == null) {
			return ResponseEntity.badRequest().body(Map.of("error", "traineeId는 필수입니다."));
		}
		try {
			LoginMember login = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
			String actor = (login == null || login.nickname() == null || login.nickname().isBlank())
					? "관리자"
					: login.nickname();
			Map<String, Object> result = adminMemberOpsService.adjustMemberEnhance(
					id,
					request.getTraineeId(),
					request.getEnhanceLevel(),
					request.getQuantity(),
					actor);
			Map<String, Object> ok = new LinkedHashMap<>();
			ok.put("ok", true);
			ok.putAll(result);
			return ResponseEntity.ok(ok);
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
		}
	}

	@PostMapping("/game-scenes")
	@Transactional
	public String createGameScene(@RequestParam("phase") String phase,
			@RequestParam("eventType") String eventType,
			@RequestParam("title") String title,
			@RequestParam("description") String description,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin";
		}
		String normalizedPhase = trimToNull(phase);
		String normalizedEventType = trimToNull(eventType);
		String normalizedTitle = trimToNull(title);
		String normalizedDescription = trimToNull(description);
		if (normalizedPhase == null || normalizedEventType == null || normalizedTitle == null || normalizedDescription == null) {
			ra.addFlashAttribute("success", "게임 지문 등록에 필요한 값을 모두 입력해주세요.");
			return "redirect:/admin/game-scenes";
		}
		gameSceneRepository.save(new GameScene(normalizedPhase, normalizedEventType, normalizedTitle, normalizedDescription));
		ra.addFlashAttribute("success", "게임 지문을 추가했습니다.");
		return "redirect:/admin/game-scenes";
	}

	@PostMapping("/game-scenes/{id}")
	@Transactional
	public String updateGameScene(@PathVariable("id") Long id,
			@RequestParam("phase") String phase,
			@RequestParam("eventType") String eventType,
			@RequestParam("title") String title,
			@RequestParam("description") String description,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin";
		}
		GameScene scene = gameSceneRepository.findById(id).orElse(null);
		if (scene == null) {
			ra.addFlashAttribute("success", "수정할 게임 지문을 찾지 못했습니다.");
			return "redirect:/admin/game-scenes";
		}
		String normalizedPhase = trimToNull(phase);
		String normalizedEventType = trimToNull(eventType);
		String normalizedTitle = trimToNull(title);
		String normalizedDescription = trimToNull(description);
		if (normalizedPhase == null || normalizedEventType == null || normalizedTitle == null || normalizedDescription == null) {
			ra.addFlashAttribute("success", "게임 지문 수정에 필요한 값을 모두 입력해주세요.");
			return "redirect:/admin/game-scenes";
		}
		scene.setPhase(normalizedPhase);
		scene.setEventType(normalizedEventType);
		scene.setTitle(normalizedTitle);
		scene.setDescription(normalizedDescription);
		gameSceneRepository.save(scene);
		ra.addFlashAttribute("success", "게임 지문을 수정했습니다.");
		return "redirect:/admin/game-scenes";
	}

	@PostMapping("/game-scenes/{id}/delete")
	@Transactional
	public String deleteGameScene(@PathVariable("id") Long id,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin";
		}
		if (!gameSceneRepository.existsById(id)) {
			ra.addFlashAttribute("success", "삭제할 게임 지문을 찾지 못했습니다.");
			return "redirect:/admin/game-scenes";
		}
		gameSceneRepository.deleteById(id);
		ra.addFlashAttribute("success", "게임 지문을 삭제했습니다.");
		return "redirect:/admin/game-scenes";
	}

	@PostMapping("/game-choices")
	@Transactional
	public String createGameChoice(@RequestParam("phase") String phase,
			@RequestParam("choiceKey") String choiceKey,
			@RequestParam("choiceText") String choiceText,
			@RequestParam("statTarget") String statTarget,
			@RequestParam("sortOrder") int sortOrder,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin";
		}
		String normalizedPhase = trimToNull(phase);
		String normalizedChoiceKey = trimToNull(choiceKey);
		String normalizedChoiceText = trimToNull(choiceText);
		String normalizedStatTarget = trimToNull(statTarget);
		if (normalizedPhase == null || normalizedChoiceKey == null || normalizedChoiceText == null || normalizedStatTarget == null) {
			ra.addFlashAttribute("success", "퀴즈/이벤트 선택지 등록에 필요한 값을 모두 입력해주세요.");
			return "redirect:/admin/game-choices";
		}
		if (gameChoiceRepository.existsByPhaseAndChoiceKey(normalizedPhase, normalizedChoiceKey)) {
			ra.addFlashAttribute("success", "같은 phase와 choiceKey 조합의 선택지가 이미 있습니다.");
			return "redirect:/admin/game-choices";
		}
		gameChoiceRepository.save(new GameChoice(normalizedPhase, normalizedChoiceKey, normalizedChoiceText,
				normalizedStatTarget, Math.max(1, sortOrder)));
		ra.addFlashAttribute("success", "퀴즈/이벤트 선택지를 추가했습니다.");
		return "redirect:/admin/game-choices";
	}

	@PostMapping("/game-choices/{id}")
	@Transactional
	public String updateGameChoice(@PathVariable("id") Long id,
			@RequestParam("phase") String phase,
			@RequestParam("choiceKey") String choiceKey,
			@RequestParam("choiceText") String choiceText,
			@RequestParam("statTarget") String statTarget,
			@RequestParam("sortOrder") int sortOrder,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin";
		}
		GameChoice choice = gameChoiceRepository.findById(id).orElse(null);
		if (choice == null) {
			ra.addFlashAttribute("success", "수정할 퀴즈/이벤트 선택지를 찾지 못했습니다.");
			return "redirect:/admin/game-choices";
		}
		String normalizedPhase = trimToNull(phase);
		String normalizedChoiceKey = trimToNull(choiceKey);
		String normalizedChoiceText = trimToNull(choiceText);
		String normalizedStatTarget = trimToNull(statTarget);
		if (normalizedPhase == null || normalizedChoiceKey == null || normalizedChoiceText == null || normalizedStatTarget == null) {
			ra.addFlashAttribute("success", "퀴즈/이벤트 선택지 수정에 필요한 값을 모두 입력해주세요.");
			return "redirect:/admin/game-choices";
		}
		Optional<GameChoice> duplicate = gameChoiceRepository.findByPhaseAndChoiceKey(normalizedPhase, normalizedChoiceKey);
		if (duplicate.isPresent() && !duplicate.get().getId().equals(id)) {
			ra.addFlashAttribute("success", "같은 phase와 choiceKey 조합의 선택지가 이미 있습니다.");
			return "redirect:/admin/game-choices";
		}
		choice.setPhase(normalizedPhase);
		choice.setChoiceKey(normalizedChoiceKey);
		choice.setChoiceText(normalizedChoiceText);
		choice.setStatTarget(normalizedStatTarget);
		choice.setSortOrder(Math.max(1, sortOrder));
		gameChoiceRepository.save(choice);
		ra.addFlashAttribute("success", "퀴즈/이벤트 선택지를 수정했습니다.");
		return "redirect:/admin/game-choices";
	}

	@PostMapping("/game-choices/{id}/delete")
	@Transactional
	public String deleteGameChoice(@PathVariable("id") Long id,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin";
		}
		if (!gameChoiceRepository.existsById(id)) {
			ra.addFlashAttribute("success", "삭제할 선택지를 찾지 못했습니다.");
			return "redirect:/admin/game-choices";
		}
		gameChoiceRepository.deleteById(id);
		ra.addFlashAttribute("success", "퀴즈/이벤트 선택지를 삭제했습니다.");
		return "redirect:/admin/game-choices";
	}

	@PostMapping("/game-events")
	@Transactional
	public String createGameEvent(@RequestParam("hint") String hint,
			@RequestParam("answer") String answer,
			@RequestParam(name = "sortOrder", defaultValue = "1") int sortOrder,
			@RequestParam(name = "enabled", defaultValue = "false") boolean enabled,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin/game-events";
		}
		String normalizedHint = trimToNull(hint);
		String normalizedAnswer = trimToNull(answer);
		if (normalizedHint == null || normalizedAnswer == null) {
			ra.addFlashAttribute("success", "이벤트 등록에 필요한 값을 모두 입력해주세요.");
			return "redirect:/admin/game-events";
		}
		gameMiniQuizRepository.save(new GameMiniQuiz(normalizedHint, normalizedAnswer, Math.max(1, sortOrder), enabled));
		ra.addFlashAttribute("success", "미니게임 이벤트를 추가했습니다.");
		return "redirect:/admin/game-events";
	}

	@PostMapping("/game-events/{id}")
	@Transactional
	public String updateGameEvent(@PathVariable("id") Long id,
			@RequestParam("hint") String hint,
			@RequestParam("answer") String answer,
			@RequestParam(name = "sortOrder", defaultValue = "1") int sortOrder,
			@RequestParam(name = "enabled", defaultValue = "false") boolean enabled,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin/game-events";
		}
		GameMiniQuiz quiz = gameMiniQuizRepository.findById(id).orElse(null);
		if (quiz == null) {
			ra.addFlashAttribute("success", "수정할 미니게임 이벤트를 찾지 못했습니다.");
			return "redirect:/admin/game-events";
		}
		String normalizedHint = trimToNull(hint);
		String normalizedAnswer = trimToNull(answer);
		if (normalizedHint == null || normalizedAnswer == null) {
			ra.addFlashAttribute("success", "이벤트 수정에 필요한 값을 모두 입력해주세요.");
			return "redirect:/admin/game-events";
		}
		quiz.setHint(normalizedHint);
		quiz.setAnswer(normalizedAnswer);
		quiz.setSortOrder(Math.max(1, sortOrder));
		quiz.setEnabled(enabled);
		gameMiniQuizRepository.save(quiz);
		ra.addFlashAttribute("success", "미니게임 이벤트를 수정했습니다.");
		return "redirect:/admin/game-events";
	}

	@PostMapping("/game-events/{id}/delete")
	@Transactional
	public String deleteGameEvent(@PathVariable("id") Long id,
			HttpSession session,
			RedirectAttributes ra) {
		if (!isAdminSession(session)) {
			return "redirect:/login?redirect=/admin/game-events";
		}
		if (!gameMiniQuizRepository.existsById(id)) {
			ra.addFlashAttribute("success", "삭제할 미니게임 이벤트를 찾지 못했습니다.");
			return "redirect:/admin/game-events";
		}
		gameMiniQuizRepository.deleteById(id);
		ra.addFlashAttribute("success", "미니게임 이벤트를 삭제했습니다.");
		return "redirect:/admin/game-events";
	}

	private static String escapeJsonString(String s) {
		if (s == null) {
			return "";
		}
		StringBuilder sb = new StringBuilder(s.length() + 8);
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			switch (c) {
			case '\\' -> sb.append("\\\\");
			case '"' -> sb.append("\\\"");
			case '\n' -> sb.append("\\n");
			case '\r' -> sb.append("\\r");
			case '\t' -> sb.append("\\t");
			default -> {
				if (c < 0x20) {
					sb.append(String.format("\\u%04x", (int) c));
				} else {
					sb.append(c);
				}
			}
			}
		}
		return sb.toString();
	}

	private static List<UsageFlowDto> aggregateWeeklyFlow(List<UsageFlowDto> daily, int weekLimit) {
		if (daily == null || daily.isEmpty()) {
			return List.of();
		}
		Map<String, long[]> agg = new LinkedHashMap<>();
		LocalDate now = LocalDate.now();
		LocalDate startWeek = now.with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
				.minusWeeks(Math.max(0, weekLimit - 1));
		DateTimeFormatter keyFmt = DateTimeFormatter.ofPattern("MM/dd");
		for (int i = 0; i < weekLimit; i++) {
			LocalDate ws = startWeek.plusWeeks(i);
			agg.put(ws.format(keyFmt) + "~", new long[] { 0L, 0L, 0L });
		}
		LocalDate cursor = now.minusDays(daily.size() - 1L);
		for (UsageFlowDto row : daily) {
			LocalDate ws = cursor.with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
			String key = ws.format(keyFmt) + "~";
			long[] vals = agg.get(key);
			if (vals != null) {
				vals[0] += row.total();
				vals[1] += row.shop();
				vals[2] += row.gacha();
			}
			cursor = cursor.plusDays(1);
		}
		List<UsageFlowDto> out = new ArrayList<>();
		for (Map.Entry<String, long[]> e : agg.entrySet()) {
			out.add(new UsageFlowDto(e.getKey(), e.getValue()[0], e.getValue()[1], e.getValue()[2]));
		}
		return out;
	}

	private static List<UsageFlowDto> aggregateMonthlyFlow(List<UsageFlowDto> daily, int monthLimit) {
		if (daily == null || daily.isEmpty()) {
			return List.of();
		}
		Map<String, long[]> agg = new LinkedHashMap<>();
		LocalDate now = LocalDate.now().withDayOfMonth(1);
		DateTimeFormatter keyFmt = DateTimeFormatter.ofPattern("yyyy-MM");
		LocalDate startMonth = now.minusMonths(Math.max(0, monthLimit - 1));
		for (int i = 0; i < monthLimit; i++) {
			LocalDate ms = startMonth.plusMonths(i);
			agg.put(ms.format(keyFmt), new long[] { 0L, 0L, 0L });
		}
		LocalDate cursor = LocalDate.now().minusDays(daily.size() - 1L);
		for (UsageFlowDto row : daily) {
			String key = cursor.withDayOfMonth(1).format(keyFmt);
			long[] vals = agg.get(key);
			if (vals != null) {
				vals[0] += row.total();
				vals[1] += row.shop();
				vals[2] += row.gacha();
			}
			cursor = cursor.plusDays(1);
		}
		List<UsageFlowDto> out = new ArrayList<>();
		for (Map.Entry<String, long[]> e : agg.entrySet()) {
			out.add(new UsageFlowDto(e.getKey(), e.getValue()[0], e.getValue()[1], e.getValue()[2]));
		}
		return out;
	}

	private static String jsonStringArray(List<String> list) {
		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < list.size(); i++) {
			if (i > 0) {
				sb.append(',');
			}
			sb.append('"').append(escapeJsonString(list.get(i))).append('"');
		}
		sb.append(']');
		return sb.toString();
	}

	private static String jsonLongArray(List<Long> list) {
		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < list.size(); i++) {
			if (i > 0) {
				sb.append(',');
			}
			Long v = list.get(i);
			sb.append(v == null ? 0 : v.longValue());
		}
		sb.append(']');
		return sb.toString();
	}

	private static Map<String, List<Object>> topPhaseChartData(List<GameRun> runs, int limit) {
		Map<String, Long> cnt = runs.stream().collect(Collectors.groupingBy(
				g -> Optional.ofNullable(g.getPhase()).orElse("UNKNOWN"), Collectors.counting()));
		List<Object> labels = new ArrayList<>();
		List<Object> values = new ArrayList<>();
		cnt.entrySet().stream().sorted(Map.Entry.<String, Long>comparingByValue().reversed()).limit(limit).forEach(e -> {
			labels.add(e.getKey());
			values.add(e.getValue());
		});
		Map<String, List<Object>> out = new LinkedHashMap<>();
		out.put("labels", labels);
		out.put("values", values);
		return out;
	}

	private static List<String> castStringList(List<Object> src) {
		if (src == null) {
			return List.of();
		}
		List<String> out = new ArrayList<>(src.size());
		for (Object o : src) {
			out.add(o == null ? "UNKNOWN" : String.valueOf(o));
		}
		return out;
	}

	private static List<Long> castLongList(List<Object> src) {
		if (src == null) {
			return List.of();
		}
		List<Long> out = new ArrayList<>(src.size());
		for (Object o : src) {
			if (o instanceof Number n) {
				out.add(n.longValue());
			} else {
				try {
					out.add(Long.parseLong(String.valueOf(o)));
				} catch (Exception e) {
					out.add(0L);
				}
			}
		}
		return out;
	}

	private static String dropOffBucket(String phase) {
		if (phase == null || phase.isBlank()) {
			return "UNKNOWN";
		}
		if ("FINISHED".equals(phase)) {
			return "FINISHED";
		}
		if ("MID_EVAL".equals(phase)) {
			return "MID_EVAL";
		}
		if ("DEBUT_EVAL".equals(phase)) {
			return "DEBUT_EVAL";
		}
		if (!phase.startsWith("DAY")) {
			return "UNKNOWN";
		}
		try {
			int us = phase.indexOf('_');
			if (us <= 3) {
				return "UNKNOWN";
			}
			int day = Integer.parseInt(phase.substring(3, us));
			if (day <= 14) {
				return "DAY1~14";
			}
			if (day <= 28) {
				return "DAY15~28";
			}
			if (day <= 42) {
				return "DAY29~42";
			}
			if (day <= 56) {
				return "DAY43~56";
			}
			if (day <= 70) {
				return "DAY57~70";
			}
			if (day <= 84) {
				return "DAY71~84";
			}
			return "UNKNOWN";
		} catch (Exception e) {
			return "UNKNOWN";
		}
	}

	private static Map<String, Long> initHourlyMap() {
		Map<String, Long> out = new LinkedHashMap<>();
		for (int h = 0; h < 24; h++) {
			out.put(String.format("%02d시", h), 0L);
		}
		return out;
	}

	private static Map<String, Long> initDropOffMap() {
		Map<String, Long> out = new LinkedHashMap<>();
		out.put("DAY1~14", 0L);
		out.put("DAY15~28", 0L);
		out.put("DAY29~42", 0L);
		out.put("DAY43~56", 0L);
		out.put("MID_EVAL", 0L);
		out.put("DAY57~70", 0L);
		out.put("DAY71~84", 0L);
		out.put("DEBUT_EVAL", 0L);
		out.put("UNKNOWN", 0L);
		return out;
	}

	private static Map<String, Long> initMemberAgeBuckets() {
		Map<String, Long> out = new LinkedHashMap<>();
		out.put("10대 이하", 0L);
		out.put("20대", 0L);
		out.put("30대", 0L);
		out.put("40대", 0L);
		out.put("50대", 0L);
		out.put("60대 이상", 0L);
		out.put("미확인", 0L);
		return out;
	}

	private static int parseBirthYearFromJumin(String plainJumin) {
		if (plainJumin == null || plainJumin.isBlank()) {
			return -1;
		}
		String digits = plainJumin.replaceAll("[^0-9]", "");
		if (digits.length() != 13) {
			return -1;
		}
		try {
			int yy = Integer.parseInt(digits.substring(0, 2));
			int code = Integer.parseInt(digits.substring(6, 7));
			return switch (code) {
			case 1, 2, 5, 6 -> 1900 + yy;
			case 3, 4, 7, 8 -> 2000 + yy;
			case 9, 0 -> 1800 + yy;
			default -> -1;
			};
		} catch (Exception e) {
			return -1;
		}
	}

	private static String toAgeBucketLabel(int birthYear, int currentYear) {
		if (birthYear <= 0 || birthYear > currentYear) {
			return "미확인";
		}
		int age = currentYear - birthYear + 1;
		if (age <= 19) {
			return "10대 이하";
		}
		if (age <= 29) {
			return "20대";
		}
		if (age <= 39) {
			return "30대";
		}
		if (age <= 49) {
			return "40대";
		}
		if (age <= 59) {
			return "50대";
		}
		return "60대 이상";
	}

	private static String trimToNull(String value) {
		if (value == null) {
			return null;
		}
		String trimmed = value.trim();
		return trimmed.isEmpty() ? null : trimmed;
	}

	private static List<GameMiniQuiz> defaultMiniQuizSeedRows() {
		List<GameMiniQuiz> out = new ArrayList<>();
		int sort = 1;
		out.add(new GameMiniQuiz("SM 소속 · 4인조 걸그룹 · \"Black Mamba\" 데뷔", "에스파", sort++, true));
		out.add(new GameMiniQuiz("SM 소속 · 5인조 보이그룹 · \"누난 너무 예뻐\"", "샤이니", sort++, true));
		out.add(new GameMiniQuiz("SM 소속 · 9인조 걸그룹 · \"Gee\"", "소녀시대", sort++, true));
		out.add(new GameMiniQuiz("SM 소속 · 13인조 보이그룹 · \"Sorry Sorry\"", "슈퍼주니어", sort++, true));
		out.add(new GameMiniQuiz("SM 소속 · 9인조 보이그룹 · \"으르렁\"", "엑소", sort++, true));
		out.add(new GameMiniQuiz("SM 소속 · 5인조 걸그룹 · \"빨간 맛\"", "레드벨벳", sort++, true));
		out.add(new GameMiniQuiz("SM 소속 · NCT 유닛 · \"영웅\"", "엔시티127", sort++, true));
		out.add(new GameMiniQuiz("SM 소속 · NCT 유닛 · \"맛\"", "엔시티드림", sort++, true));
		out.add(new GameMiniQuiz("SM 소속 · 2023 데뷔 보이그룹 · \"Get A Guitar\"", "라이즈", sort++, true));
		out.add(new GameMiniQuiz("JYP 소속 · 8인조 보이그룹 · \"God's Menu\"", "스트레이키즈", sort++, true));
		out.add(new GameMiniQuiz("JYP 소속 · 9인조 걸그룹 · \"CHEER UP\"", "트와이스", sort++, true));
		out.add(new GameMiniQuiz("JYP 소속 · 5인조 걸그룹 · \"달라달라\"", "있지", sort++, true));
		out.add(new GameMiniQuiz("JYP 소속 · 6인조 보이그룹 · \"Congratulations\"", "데이식스", sort++, true));
		out.add(new GameMiniQuiz("JYP 소속 · 6인조 걸그룹 · \"O.O\"", "엔믹스", sort++, true));
		out.add(new GameMiniQuiz("YG 소속 · 4인조 걸그룹 · \"DDU-DU DDU-DU\"", "블랙핑크", sort++, true));
		out.add(new GameMiniQuiz("YG 소속 · 4인조 보이그룹 · \"거짓말\"", "빅뱅", sort++, true));
		out.add(new GameMiniQuiz("YG 소속 · 6인조 보이그룹 · \"사랑을 했다\"", "아이콘", sort++, true));
		out.add(new GameMiniQuiz("YG 소속 · 7인조 보이그룹 · \"JIKJIN\"", "트레저", sort++, true));
		out.add(new GameMiniQuiz("HYBE 산하 · 5인조 걸그룹 · \"Fearless\"", "르세라핌", sort++, true));
		out.add(new GameMiniQuiz("HYBE 산하 · 7인조 보이그룹 · \"Dynamite\"", "방탄소년단", sort++, true));
		out.add(new GameMiniQuiz("HYBE 산하 · 13인조 보이그룹 · \"아주 NICE\"", "세븐틴", sort++, true));
		out.add(new GameMiniQuiz("HYBE 산하 · 7인조 걸그룹 · \"SUPER SHY\"", "뉴진스", sort++, true));
		out.add(new GameMiniQuiz("HYBE 산하 · 6인조 보이그룹 · \"Given-Taken\"", "엔하이픈", sort++, true));
		out.add(new GameMiniQuiz("스타쉽 소속 · 6인조 걸그룹 · \"LOVE DIVE\"", "아이브", sort++, true));
		out.add(new GameMiniQuiz("스타쉽 소속 · 6인조 보이그룹 · \"DRAMARAMA\"", "몬스타엑스", sort++, true));
		out.add(new GameMiniQuiz("큐브 소속 · 5인조 걸그룹 · \"TOMBOY\"", "여자아이들", sort++, true));
		out.add(new GameMiniQuiz("RBW 소속 · 4인조 걸그룹 · \"HIP\"", "마마무", sort++, true));
		out.add(new GameMiniQuiz("IST 소속 · 11인조 보이그룹 · \"THRILL RIDE\"", "더보이즈", sort++, true));
		out.add(new GameMiniQuiz("WM 소속 · 6인조 걸그룹 · \"살짝 설렜어\"", "오마이걸", sort++, true));
		out.add(new GameMiniQuiz("KQ 소속 · 8인조 보이그룹 · \"BOUNCY\"", "에이티즈", sort++, true));
		return out;
	}

	private static boolean isAdminSession(HttpSession session) {
		Object raw = session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (raw instanceof LoginMember lm) {
			return "ADMIN".equalsIgnoreCase(lm.role());
		}
		return false;
	}

	private Map<String, Object> collectMlChoiceStats() {
		long total = 0L;
		long ml = 0L;
		long rule = 0L;
		long fallback = 0L;
		double confSum = 0.0;
		Map<String, Long> mlDecisionReasonCounts = new LinkedHashMap<>();

		Path p = resolveMlTrainingLogPath();
		if (p == null || !Files.exists(p)) {
			return mlChoiceStatsMap(total, ml, rule, fallback, confSum, mlDecisionReasonCounts);
		}

		try (var lines = Files.lines(p)) {
			for (String line : (Iterable<String>) lines::iterator) {
				String raw = line == null ? "" : line.trim();
				if (raw.isEmpty()) {
					continue;
				}
				total++;
				String resolverType = extractJsonString(raw, "resolverType");
				if ("ML".equalsIgnoreCase(resolverType)) {
					ml++;
				} else if ("RULE".equalsIgnoreCase(resolverType)) {
					rule++;
				}
				Boolean usedFallback = extractJsonBoolean(raw, "usedFallback");
				if (Boolean.TRUE.equals(usedFallback)) {
					fallback++;
				}
				confSum += extractJsonDouble(raw, "predictionConfidence");
				String mlDecisionReason = extractJsonString(raw, "mlDecisionReason");
				if (!mlDecisionReason.isBlank()) {
					mlDecisionReasonCounts.merge(mlDecisionReason, 1L, Long::sum);
				}
			}
		} catch (IOException ignored) {
			// 관리 페이지 지표는 부가 정보이므로 읽기 실패 시 빈 통계 반환
		}
		return mlChoiceStatsMap(total, ml, rule, fallback, confSum, mlDecisionReasonCounts);
	}

	private Path resolveMlTrainingLogPath() {
		String raw = mlTrainingLogPath == null ? "" : mlTrainingLogPath.trim();
		if (raw.isBlank()) {
			return null;
		}
		Path p = Paths.get(raw);
		if (p.isAbsolute()) {
			return p.normalize();
		}
		return Paths.get(System.getProperty("user.dir")).resolve(p).normalize();
	}

	private static Map<String, Object> mlChoiceStatsMap(long total, long ml, long rule, long fallback, double confSum,
			Map<String, Long> mlDecisionReasonCounts) {
		Map<String, Object> out = new LinkedHashMap<>();
		out.put("total", total);
		out.put("ml", ml);
		out.put("rule", rule);
		out.put("fallback", fallback);
		double avgConf = total > 0 ? confSum / total : 0.0;
		double mlRate = total > 0 ? (ml * 100.0) / total : 0.0;
		double fallbackRate = total > 0 ? (fallback * 100.0) / total : 0.0;
		out.put("avgConfidence", avgConf);
		out.put("mlRate", mlRate);
		out.put("fallbackRate", fallbackRate);
		out.put("mlDecisionReasonCounts", mlDecisionReasonCounts == null ? Map.of() : mlDecisionReasonCounts);
		return out;
	}

	private static String extractJsonString(String jsonLine, String key) {
		if (jsonLine == null || jsonLine.isBlank() || key == null || key.isBlank()) {
			return "";
		}
		String needle = "\"" + key + "\":";
		int from = jsonLine.indexOf(needle);
		if (from < 0) {
			return "";
		}
		int startQ = jsonLine.indexOf('"', from + needle.length());
		if (startQ < 0) {
			return "";
		}
		int endQ = jsonLine.indexOf('"', startQ + 1);
		if (endQ < 0) {
			return "";
		}
		return jsonLine.substring(startQ + 1, endQ);
	}

	private static Boolean extractJsonBoolean(String jsonLine, String key) {
		if (jsonLine == null || jsonLine.isBlank() || key == null || key.isBlank()) {
			return null;
		}
		String needle = "\"" + key + "\":";
		int from = jsonLine.indexOf(needle);
		if (from < 0) {
			return null;
		}
		int start = from + needle.length();
		int end = start;
		while (end < jsonLine.length() && Character.isLetter(jsonLine.charAt(end))) {
			end++;
		}
		if (end <= start) {
			return null;
		}
		String token = jsonLine.substring(start, end).trim();
		if ("true".equalsIgnoreCase(token)) {
			return true;
		}
		if ("false".equalsIgnoreCase(token)) {
			return false;
		}
		return null;
	}

	private static double extractJsonDouble(String jsonLine, String key) {
		if (jsonLine == null || jsonLine.isBlank() || key == null || key.isBlank()) {
			return 0.0;
		}
		String needle = "\"" + key + "\":";
		int from = jsonLine.indexOf(needle);
		if (from < 0) {
			return 0.0;
		}
		int start = from + needle.length();
		int end = start;
		while (end < jsonLine.length()) {
			char c = jsonLine.charAt(end);
			if ((c >= '0' && c <= '9') || c == '.' || c == '-') {
				end++;
			} else {
				break;
			}
		}
		if (end <= start) {
			return 0.0;
		}
		try {
			return Double.parseDouble(jsonLine.substring(start, end));
		} catch (NumberFormatException e) {
			return 0.0;
		}
	}

	/* 접속 로그/팝업 설정 기능은 DB 변경이 필요해서 제외 */
}
