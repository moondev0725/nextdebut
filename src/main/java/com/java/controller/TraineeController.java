package com.java.controller;

import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.java.config.SessionConst;
import com.java.dto.LoginMember;
import com.java.dto.AdminPhotoCardDto;
import com.java.entity.MyTrainee;
import com.java.game.entity.GameRun;
import com.java.game.entity.Gender;
import com.java.game.entity.Grade;
import com.java.game.entity.Trainee;
import com.java.game.repository.GameRunRepository;
import com.java.game.repository.TraineeRepository;
import com.java.game.service.TraineeLikeService;
import com.java.game.util.LikeCountFormat;
import com.java.repository.MyTraineeRepository;
import com.java.photocard.service.PhotoCardService;
import com.java.photocard.entity.PhotoCardGrade;
import com.java.dto.TraineePhotoCardSummaryDto;
import com.java.service.TraineeGroupService;
import com.java.service.TraineeUnlockService;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/trainees")
public class TraineeController {

	private final TraineeRepository traineeRepository;
	private final MyTraineeRepository myTraineeRepository;
	private final TraineeLikeService traineeLikeService;
	private final GameRunRepository gameRunRepository;
	private final PhotoCardService photoCardService;
	private final TraineeGroupService traineeGroupService;
	private final TraineeUnlockService traineeUnlockService;

	public TraineeController(TraineeRepository traineeRepository, MyTraineeRepository myTraineeRepository,
			TraineeLikeService traineeLikeService, GameRunRepository gameRunRepository,
			PhotoCardService photoCardService, TraineeGroupService traineeGroupService,
			TraineeUnlockService traineeUnlockService) {
		this.traineeRepository = traineeRepository;
		this.myTraineeRepository = myTraineeRepository;
		this.traineeLikeService = traineeLikeService;
		this.gameRunRepository = gameRunRepository;
		this.photoCardService = photoCardService;
		this.traineeGroupService = traineeGroupService;
		this.traineeUnlockService = traineeUnlockService;
	}

	/**
	 * 도감 GET /trainees?gender=ALL|MALE|FEMALE&grade=ALL|N|R|SR|SSR&q=이름
	 */
	@GetMapping
	public String list(@RequestParam(name = "gender", defaultValue = "ALL") String gender,
			@RequestParam(name = "grade", defaultValue = "ALL") String grade,
			@RequestParam(name = "group", defaultValue = "ALL") String group,
			@RequestParam(name = "q", required = false) String q,
			Model model,
			HttpSession session) {

		Gender genderFilter = parseGenderFilter(gender);
		Grade gradeFilter = parseGradeFilter(grade);
		String nameQ = normalizeTraineeNameQuery(q);

		List<Trainee> trainees = loadTrainees(genderFilter, gradeFilter);
		if (StringUtils.hasText(nameQ)) {
			String needle = nameQ.toLowerCase(Locale.KOREAN);
			trainees = trainees.stream()
					.filter(t -> t.getName() != null && t.getName().toLowerCase(Locale.KOREAN).contains(needle))
					.toList();
		} else {
			trainees = trainees.stream().sorted(Comparator.comparing(Trainee::getName, String.CASE_INSENSITIVE_ORDER))
					.toList();
		}
		String selectedGroup = traineeGroupService.normalizeGroupFilter(group);
		if (!"ALL".equals(selectedGroup)) {
			trainees = trainees.stream()
					.filter(t -> selectedGroup.equals(traineeGroupService.resolveTraineeGroup(t.getName())))
					.toList();
		}

		LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		boolean loggedIn = loginMember != null;
		int bestScore = loggedIn ? traineeUnlockService.resolveBestScore(loginMember.mno()) : 0;
		Set<Long> ownedTraineeIds = Collections.emptySet();
		Map<Long, Integer> ownedTraineeQtyMap = Collections.emptyMap();
		Map<Long, Integer> ownedEnhanceLevelMap = Collections.emptyMap();
		if (loginMember != null) {
			ownedTraineeIds = loadOwnedIds(loginMember.mno());
			ownedTraineeQtyMap = loadOwnedQuantityMap(loginMember.mno());
			ownedEnhanceLevelMap = loadOwnedEnhanceLevelMap(loginMember.mno());
		}
		Set<Long> finalOwnedTraineeIds = ownedTraineeIds;
		Set<Long> lockedTraineeIds = traineeUnlockService.resolveLockedTraineeIds(trainees, bestScore).stream()
				.filter(id -> !finalOwnedTraineeIds.contains(id))
				.collect(Collectors.toCollection(HashSet::new));

		model.addAttribute("trainees", trainees);
		model.addAttribute("selectedGender", gender.toUpperCase(Locale.ROOT));
		model.addAttribute("selectedGrade", grade.toUpperCase(Locale.ROOT));
		model.addAttribute("selectedGroup", selectedGroup);
		model.addAttribute("searchQ", nameQ);
		model.addAttribute("totalCount", trainees.size());
		model.addAttribute("loggedIn", loggedIn);
		model.addAttribute("ownedTraineeIds", ownedTraineeIds);
		model.addAttribute("ownedTraineeQtyMap", ownedTraineeQtyMap);
		model.addAttribute("ownedEnhanceLevelMap", ownedEnhanceLevelMap);
		model.addAttribute("memberBestScore", bestScore);
		model.addAttribute("lockedTraineeIds", lockedTraineeIds);
		Map<Long, String> traineeGroups = new HashMap<>();
		for (Trainee t : trainees) {
			traineeGroups.put(t.getId(), traineeGroupService.resolveTraineeGroup(t.getName()));
		}
		model.addAttribute("traineeGroups", traineeGroups);
		model.addAttribute("groupedTrainees", buildGroupedTrainees(trainees, traineeGroups));

		List<Long> allIds = trainees.stream().map(Trainee::getId).toList();
		Map<Long, Long> likeCounts = traineeLikeService.countByTraineeIds(allIds);
		model.addAttribute("traineeLikeCounts", likeCounts);
		Map<Long, String> likeLabels = new HashMap<>();
		for (Long id : allIds) {
			likeLabels.put(id, LikeCountFormat.compact(likeCounts.getOrDefault(id, 0L)));
		}
		model.addAttribute("traineeLikeLabels", likeLabels);
		Set<Long> likedTraineeIds = Collections.emptySet();
		if (loginMember != null && loginMember.mno() != null) {
			likedTraineeIds = traineeLikeService.likedTraineeIdsEver(loginMember.mno(), allIds);
		}
		model.addAttribute("likedTraineeIds", likedTraineeIds);

		if (loginMember != null && loginMember.mno() != null) {
			Map<Long, TraineePhotoCardSummaryDto> pcMap = photoCardService.getSummariesForTrainees(loginMember.mno(),
					trainees.stream().map(Trainee::getId).toList());
			model.addAttribute("photoCardSummaries", pcMap);
			Map<Long, Map<String, String>> photoCardImageMap = new HashMap<>();
			for (Trainee t : trainees) {
				Map<String, String> byGrade = new HashMap<>();
				for (AdminPhotoCardDto card : photoCardService.getCardsByTrainee(t.getId())) {
					if (StringUtils.hasText(card.imageUrl())) {
						byGrade.put(card.grade(), card.imageUrl());
					}
				}
				photoCardImageMap.put(t.getId(), byGrade);
			}
			model.addAttribute("photoCardImageMap", photoCardImageMap);
		} else {
			model.addAttribute("photoCardSummaries", Map.of());
			model.addAttribute("photoCardImageMap", Map.of());
		}

		return "trainees/list";
	}

	/**
	 * 도감에서 포토카드 등급 장착 (보유한 등급만).
	 */
	@PostMapping("/{id}/photocard/equip")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> equipPhotoCard(@PathVariable("id") Long traineeId,
			@RequestParam("grade") String grade,
			HttpSession session) {
		LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (loginMember == null || loginMember.mno() == null) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("ok", false, "error", "login_required"));
		}
		PhotoCardGrade g;
		try {
			g = PhotoCardGrade.valueOf(grade.trim().toUpperCase(Locale.ROOT));
		} catch (Exception e) {
			return ResponseEntity.badRequest().body(Map.of("ok", false, "error", "invalid_grade"));
		}
		String r = photoCardService.equip(loginMember.mno(), traineeId, g);
		if (!"ok".equals(r)) {
			return ResponseEntity.badRequest().body(Map.of("ok", false, "error", r));
		}
		TraineePhotoCardSummaryDto sum = photoCardService.getSummary(loginMember.mno(), traineeId);
		return ResponseEntity.ok(Map.of("ok", true, "summary", Map.of(
				"ownedR", sum.ownedR(),
				"ownedSr", sum.ownedSr(),
				"ownedSsr", sum.ownedSsr(),
				"equippedGrade", sum.equippedGrade() != null ? sum.equippedGrade() : "",
				"equippedBonusPercent", sum.equippedBonusPercent())));
	}

	/**
	 * 연습생 좋아요 (로그인 필요). 같은 게임 런(runId)에서 연습생당 1회만 가능, 플레이마다 누적.
	 * 응답: ok, added, alreadyLikedThisRun, totalLikes
	 */
	@PostMapping("/{id}/like")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> addLike(@PathVariable("id") Long id,
			@RequestParam("runId") Long runId,
			HttpSession session) {
		LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (loginMember == null || loginMember.mno() == null) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
					.body(Map.of("ok", false, "error", "login_required"));
		}
		GameRun run = gameRunRepository.findById(runId).orElse(null);
		if (run == null) {
			return ResponseEntity.notFound().build();
		}
		if (!"FINISHED".equals(run.getPhase())) {
			return ResponseEntity.badRequest().body(Map.of("ok", false, "error", "invalid_run"));
		}
		if (!Objects.equals(run.getPlayerMno(), loginMember.mno())) {
			return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("ok", false, "error", "forbidden"));
		}
		try {
			TraineeLikeService.LikeAddResult r = traineeLikeService.addLike(loginMember.mno(), id, runId);
			return ResponseEntity.ok(Map.of(
					"ok", true,
					"added", r.added(),
					"alreadyLikedThisRun", r.alreadyLikedThisRun(),
					"totalLikes", r.totalLikes()));
		} catch (IllegalArgumentException e) {
			return ResponseEntity.notFound().build();
		}
	}

	/**
	 * 연습생 카드 강화.
	 * - 최대 +5
	 * - n -> n+1 은 (n+1)장 소모
	 */
	@PostMapping("/{id}/enhance")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> enhanceTraineeCard(@PathVariable("id") Long traineeId, HttpSession session) {
		LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
		if (loginMember == null || loginMember.mno() == null) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("ok", false, "message", "로그인이 필요합니다."));
		}
		MyTrainee owned = myTraineeRepository.findByMemberIdAndTraineeId(loginMember.mno(), traineeId).orElse(null);
		if (owned == null || owned.getQuantity() <= 0) {
			return ResponseEntity.ok(Map.of("ok", false, "message", "보유 중인 연습생이 아닙니다."));
		}
		int level = Math.max(0, owned.getEnhanceLevel());
		if (level >= 5) {
			return ResponseEntity.ok(Map.of("ok", false, "message", "이미 최대 강화입니다."));
		}
		int need = level + 1;
		if (owned.getQuantity() < need) {
			return ResponseEntity.ok(Map.of("ok", false, "message", "강화 재료가 부족합니다."));
		}
		owned.setQuantity(owned.getQuantity() - need);
		owned.setEnhanceLevel(level + 1);
		myTraineeRepository.save(owned);
		return ResponseEntity.ok(Map.of(
				"ok", true,
				"message", "강화가 완료되었습니다.",
				"enhanceLevel", owned.getEnhanceLevel(),
				"quantity", owned.getQuantity()));
	}

	private static Gender parseGenderFilter(String gender) {
		if (!StringUtils.hasText(gender)) {
			return null;
		}
		return switch (gender.trim().toUpperCase(Locale.ROOT)) {
			case "MALE" -> Gender.MALE;
			case "FEMALE" -> Gender.FEMALE;
			default -> null;
		};
	}

	private static Grade parseGradeFilter(String grade) {
		if (!StringUtils.hasText(grade)) {
			return null;
		}
		String g = grade.trim().toUpperCase(Locale.ROOT);
		if ("ALL".equals(g)) {
			return null;
		}
		try {
			return Grade.valueOf(g);
		} catch (IllegalArgumentException e) {
			return null;
		}
	}

	private static String normalizeTraineeNameQuery(String q) {
		if (!StringUtils.hasText(q)) {
			return "";
		}
		String t = q.strip();
		if (t.length() > 40) {
			t = t.substring(0, 40);
		}
		return t;
	}

	private List<Trainee> loadTrainees(Gender genderFilter, Grade gradeFilter) {
		if (genderFilter != null && gradeFilter != null) {
			return traineeRepository.findByGenderAndGrade(genderFilter, gradeFilter);
		}
		if (genderFilter != null) {
			return traineeRepository.findByGender(genderFilter);
		}
		if (gradeFilter != null) {
			return traineeRepository.findByGrade(gradeFilter);
		}
		return traineeRepository.findAll();
	}

	private static Map<String, List<Trainee>> buildGroupedTrainees(List<Trainee> trainees, Map<Long, String> traineeGroups) {
		Map<String, List<Trainee>> grouped = new LinkedHashMap<>();
		grouped.put("RIIZE", trainees.stream()
				.filter(t -> "RIIZE".equals(traineeGroups.getOrDefault(t.getId(), "OTHER")))
				.toList());
		grouped.put("EXO", trainees.stream()
				.filter(t -> "EXO".equals(traineeGroups.getOrDefault(t.getId(), "OTHER")))
				.toList());
		grouped.put("HEARTS2HEARTS", trainees.stream()
				.filter(t -> "HEARTS2HEARTS".equals(traineeGroups.getOrDefault(t.getId(), "OTHER")))
				.toList());
		grouped.put("AESPA", trainees.stream()
				.filter(t -> "AESPA".equals(traineeGroups.getOrDefault(t.getId(), "OTHER")))
				.toList());
		grouped.put("REDVELVET", trainees.stream()
				.filter(t -> "REDVELVET".equals(traineeGroups.getOrDefault(t.getId(), "OTHER")))
				.toList());
		grouped.put("HIDDEN", trainees.stream()
				.filter(t -> "HIDDEN".equals(traineeGroups.getOrDefault(t.getId(), "OTHER")))
				.toList());
		grouped.put("OTHER", trainees.stream()
				.filter(t -> "OTHER".equals(traineeGroups.getOrDefault(t.getId(), "OTHER")))
				.toList());
		return grouped;
	}

	private Set<Long> loadOwnedIds(Long mno) {
		if (mno == null) {
			return new HashSet<>();
		}
		return myTraineeRepository.findByMemberIdOrderByIdDesc(mno).stream()
				.filter(m -> m.getQuantity() > 0)
				.map(MyTrainee::getTraineeId)
				.collect(Collectors.toSet());
	}

	private Map<Long, Integer> loadOwnedQuantityMap(Long mno) {
		if (mno == null) {
			return Collections.emptyMap();
		}
		Map<Long, Integer> map = new HashMap<>();
		for (MyTrainee row : myTraineeRepository.findByMemberIdOrderByIdDesc(mno)) {
			if (row.getQuantity() > 0) {
				map.put(row.getTraineeId(), row.getQuantity());
			}
		}
		return map;
	}

	private Map<Long, Integer> loadOwnedEnhanceLevelMap(Long mno) {
		if (mno == null) {
			return Collections.emptyMap();
		}
		Map<Long, Integer> map = new HashMap<>();
		for (MyTrainee row : myTraineeRepository.findByMemberIdOrderByIdDesc(mno)) {
			if (row.getQuantity() > 0) {
				map.put(row.getTraineeId(), Math.max(0, row.getEnhanceLevel()));
			}
		}
		return map;
	}
}
