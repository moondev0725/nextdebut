package com.java.controller;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.time.LocalDate;

import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.java.config.SessionConst;
import com.java.dto.AdminPhotoCardDto;
import com.java.dto.TraineeCreateRequest;
import com.java.dto.TraineeStatsUpdateRequest;
import com.java.dto.TraineeUpdateRequest;
import com.java.game.entity.Gender;
import com.java.game.entity.Grade;
import com.java.game.entity.Trainee;
import com.java.photocard.service.PhotoCardService;
import com.java.service.TraineeService;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/admin")
public class AdminTraineeController {

	private final TraineeService traineeService;
	private final PhotoCardService photoCardService;

	public AdminTraineeController(TraineeService traineeService, PhotoCardService photoCardService) {
		this.traineeService = traineeService;
		this.photoCardService = photoCardService;
	}

	@GetMapping("/trainees")
	public String trainees(
			@RequestParam(name = "keyword", required = false) String keyword,
			@RequestParam(name = "gender", defaultValue = "ALL") String gender,
			@RequestParam(name = "grade", defaultValue = "ALL") String grade,
			@RequestParam(name = "sort", defaultValue = "name") String sort,
			@RequestParam(name = "traineeId", required = false) Long traineeId,
			Model model,
			HttpSession session) {
		if (session.getAttribute(SessionConst.LOGIN_MEMBER) == null) {
			return "redirect:/login?redirect=/admin/trainees";
		}
		Gender genderFilter = parseGender(gender);
		Grade gradeFilter = parseGrade(grade);
		List<Trainee> trainees = traineeService.searchForAdmin(keyword, genderFilter, gradeFilter, sort);
		Map<Long, Map<String, Boolean>> cardConfiguredMap = new HashMap<>();
		for (Trainee t : trainees) {
			Map<String, Boolean> gradeMap = new HashMap<>();
			gradeMap.put("R", false);
			gradeMap.put("SR", false);
			gradeMap.put("SSR", false);
			for (AdminPhotoCardDto card : photoCardService.getCardsByTrainee(t.getId())) {
				gradeMap.put(card.grade(), card.configured());
			}
			cardConfiguredMap.put(t.getId(), gradeMap);
		}

		Trainee selected = null;
		if (traineeId != null) {
			selected = trainees.stream().filter(t -> t.getId().equals(traineeId)).findFirst().orElse(null);
			if (selected == null) {
				List<Trainee> onlyOne = traineeService.searchForAdmin(null, null, null, "name").stream()
						.filter(t -> t.getId().equals(traineeId))
						.toList();
				selected = onlyOne.isEmpty() ? null : onlyOne.get(0);
			}
		}
		if (selected == null && !trainees.isEmpty()) {
			selected = trainees.get(0);
		}
		List<AdminPhotoCardDto> selectedCards = selected == null ? List.of() : photoCardService.getCardsByTrainee(selected.getId());

		model.addAttribute("trainees", trainees);
		model.addAttribute("keyword", keyword == null ? "" : keyword);
		model.addAttribute("selectedGender", (gender == null ? "ALL" : gender.toUpperCase(Locale.ROOT)));
		model.addAttribute("selectedGrade", (grade == null ? "ALL" : grade.toUpperCase(Locale.ROOT)));
		model.addAttribute("selectedSort", StringUtils.hasText(sort) ? sort : "name");
		model.addAttribute("cardConfiguredMap", cardConfiguredMap);
		model.addAttribute("selectedTrainee", selected);
		model.addAttribute("selectedCards", selectedCards);
		return "admin/trainees";
	}

	@GetMapping("/trainees/new")
	public String newTraineeForm(HttpSession session) {
		if (session.getAttribute(SessionConst.LOGIN_MEMBER) == null) {
			return "redirect:/login?redirect=/admin/trainees/new";
		}
		return "admin/trainee-create";
	}

	@PostMapping("/trainee")
	@Transactional
	public String createTrainee(
			@RequestParam("name") String name,
			@RequestParam("gender") String gender,
			@RequestParam(name = "grade", defaultValue = "N") String grade,
			@RequestParam(name = "age", required = false) Integer age,
			@RequestParam(name = "birthday", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate birthday,
			@RequestParam(name = "height", required = false) Integer height,
			@RequestParam(name = "hobby", required = false) String hobby,
			@RequestParam(name = "instagram", required = false) String instagram,
			@RequestParam(name = "unlockScore", required = false) Integer unlockScore,
			@RequestParam(name = "image", required = false) MultipartFile image,
			@RequestParam("vocal") Integer vocal,
			@RequestParam("dance") Integer dance,
			@RequestParam("star") Integer star,
			@RequestParam("mental") Integer mental,
			@RequestParam("teamwork") Integer teamwork,
			RedirectAttributes ra) {
		TraineeCreateRequest request = new TraineeCreateRequest();
		request.setName(name);
		request.setGender(parseGenderRequired(gender));
		request.setGrade(parseGradeRequired(grade));
		request.setAge(age);
		request.setBirthday(birthday);
		request.setHeight(height);
		request.setHobby(hobby);
		request.setInstagram(instagram);
		Integer normalizedUnlockScore = normalizeUnlockScore(unlockScore);
		request.setUnlockScore(normalizedUnlockScore);
		request.setUnlockCondition(normalizedUnlockScore == null ? null : "최종 점수 " + normalizedUnlockScore + "점 이상");
		request.setVocal(vocal);
		request.setDance(dance);
		request.setStar(star);
		request.setMental(mental);
		request.setTeamwork(teamwork);
		request.setImagePath(storeTraineeImage(image));
		Trainee created = traineeService.createTrainee(request);
		ra.addFlashAttribute("success", "연습생이 추가되었습니다.");
		return "redirect:/admin/trainees?traineeId=" + created.getId();
	}

	@PostMapping("/trainees/{id}/basic")
	public String updateBasic(@PathVariable("id") Long traineeId,
			@RequestParam("name") String name,
			@RequestParam("gender") String gender,
			@RequestParam("grade") String grade,
			@RequestParam(name = "age", required = false) Integer age,
			@RequestParam(name = "birthday", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate birthday,
			@RequestParam(name = "height", required = false) Integer height,
			@RequestParam(name = "hobby", required = false) String hobby,
			@RequestParam(name = "instagram", required = false) String instagram,
			@RequestParam(name = "unlockScore", required = false) Integer unlockScore,
			RedirectAttributes ra) {
		TraineeUpdateRequest request = new TraineeUpdateRequest();
		request.setName(name);
		request.setGender(parseGenderRequired(gender));
		request.setGrade(parseGradeRequired(grade));
		request.setAge(age);
		request.setBirthday(birthday);
		request.setHeight(height);
		request.setHobby(hobby);
		request.setInstagram(instagram);
		Integer normalizedUnlockScore = normalizeUnlockScore(unlockScore);
		request.setUnlockScore(normalizedUnlockScore);
		request.setUnlockCondition(normalizedUnlockScore == null ? null : "최종 점수 " + normalizedUnlockScore + "점 이상");
		traineeService.updateTrainee(traineeId, request);
		ra.addFlashAttribute("success", "기본 정보가 수정되었습니다.");
		return "redirect:/admin/trainees?traineeId=" + traineeId;
	}

	@PostMapping("/trainees/{id}/stats")
	public String updateStats(@PathVariable("id") Long traineeId,
			@RequestParam("vocal") Integer vocal,
			@RequestParam("dance") Integer dance,
			@RequestParam("star") Integer star,
			@RequestParam("mental") Integer mental,
			@RequestParam("teamwork") Integer teamwork,
			RedirectAttributes ra) {
		TraineeStatsUpdateRequest request = new TraineeStatsUpdateRequest();
		request.setVocal(vocal);
		request.setDance(dance);
		request.setStar(star);
		request.setMental(mental);
		request.setTeamwork(teamwork);
		traineeService.updateStats(traineeId, request);
		ra.addFlashAttribute("success", "능력치가 수정되었습니다.");
		return "redirect:/admin/trainees?traineeId=" + traineeId;
	}

	@PostMapping("/trainees/{id}/image")
	public String updateImage(@PathVariable("id") Long traineeId,
			@RequestParam("image") MultipartFile image,
			RedirectAttributes ra) {
		String imagePath = storeTraineeImage(image);
		traineeService.updateImage(traineeId, imagePath);
		ra.addFlashAttribute("success", "대표 이미지가 수정되었습니다.");
		return "redirect:/admin/trainees?traineeId=" + traineeId;
	}

	@PostMapping("/trainees/{id}/photocards/{grade}")
	public String updatePhotoCard(@PathVariable("id") Long traineeId,
			@PathVariable("grade") String grade,
			@RequestParam("image") MultipartFile image,
			RedirectAttributes ra) {
		photoCardService.saveOrUpdateCard(traineeId, grade, image);
		ra.addFlashAttribute("success", "포토카드(" + grade.toUpperCase(Locale.ROOT) + ")가 저장되었습니다.");
		return "redirect:/admin/trainees?traineeId=" + traineeId;
	}

	@PostMapping("/trainees/{id}/ops-delete")
	public String deleteTrainee(@PathVariable("id") Long traineeId, RedirectAttributes ra) {
		traineeService.deleteTrainee(traineeId);
		ra.addFlashAttribute("success", "연습생이 삭제되었습니다.");
		return "redirect:/admin/trainees";
	}

	private Gender parseGender(String gender) {
		if (!StringUtils.hasText(gender) || "ALL".equalsIgnoreCase(gender.trim())) {
			return null;
		}
		return parseGenderRequired(gender);
	}

	private Gender parseGenderRequired(String gender) {
		if ("MALE".equalsIgnoreCase(gender)) {
			return Gender.MALE;
		}
		if ("FEMALE".equalsIgnoreCase(gender)) {
			return Gender.FEMALE;
		}
		throw new IllegalArgumentException("성별 값이 올바르지 않습니다.");
	}

	private Grade parseGrade(String grade) {
		if (!StringUtils.hasText(grade) || "ALL".equalsIgnoreCase(grade.trim())) {
			return null;
		}
		return parseGradeRequired(grade);
	}

	private Grade parseGradeRequired(String grade) {
		if (!StringUtils.hasText(grade)) {
			throw new IllegalArgumentException("등급 값이 올바르지 않습니다.");
		}
		try {
			return Grade.valueOf(grade.trim().toUpperCase(Locale.ROOT));
		} catch (IllegalArgumentException ex) {
			throw new IllegalArgumentException("등급 값이 올바르지 않습니다.");
		}
	}

	private String storeTraineeImage(MultipartFile file) {
		if (file == null || file.isEmpty()) {
			return null;
		}
		String ext = StringUtils.getFilenameExtension(file.getOriginalFilename());
		String safeExt = StringUtils.hasText(ext) ? "." + ext.toLowerCase(Locale.ROOT) : ".jpg";
		String saved = UUID.randomUUID().toString().replace("-", "") + safeExt;
		try {
			Path dir = Paths.get(System.getProperty("user.dir"), "uploads", "trainees");
			Files.createDirectories(dir);
			Files.copy(file.getInputStream(), dir.resolve(saved));
			return "/uploads/trainees/" + saved;
		} catch (IOException e) {
			throw new IllegalStateException("연습생 이미지를 저장하지 못했습니다.", e);
		}
	}

	private Integer normalizeUnlockScore(Integer unlockScore) {
		if (unlockScore == null || unlockScore <= 0) {
			return null;
		}
		return Math.max(0, Math.min(1000, unlockScore));
	}
}
