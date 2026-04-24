package com.java.service;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import com.java.dto.TraineeCreateRequest;
import com.java.dto.TraineeStatsUpdateRequest;
import com.java.dto.TraineeUpdateRequest;
import com.java.game.entity.Gender;
import com.java.game.entity.Grade;
import com.java.game.entity.Trainee;
import com.java.game.repository.GameRunMemberRepository;
import com.java.game.repository.TraineeMemberLikeRepository;
import com.java.game.repository.TraineeRepository;
import com.java.photocard.repository.EquippedPhotoCardRepository;
import com.java.photocard.repository.PhotoCardMasterRepository;
import com.java.photocard.repository.UserPhotoCardRepository;
import com.java.repository.MyTraineeRepository;

@Service
public class TraineeServiceImpl implements TraineeService {

	private final TraineeRepository traineeRepository;
	private final MyTraineeRepository myTraineeRepository;
	private final TraineeMemberLikeRepository traineeMemberLikeRepository;
	private final GameRunMemberRepository gameRunMemberRepository;
	private final PhotoCardMasterRepository photoCardMasterRepository;
	private final UserPhotoCardRepository userPhotoCardRepository;
	private final EquippedPhotoCardRepository equippedPhotoCardRepository;

	public TraineeServiceImpl(TraineeRepository traineeRepository,
			MyTraineeRepository myTraineeRepository,
			TraineeMemberLikeRepository traineeMemberLikeRepository,
			GameRunMemberRepository gameRunMemberRepository,
			PhotoCardMasterRepository photoCardMasterRepository,
			UserPhotoCardRepository userPhotoCardRepository,
			EquippedPhotoCardRepository equippedPhotoCardRepository) {
		this.traineeRepository = traineeRepository;
		this.myTraineeRepository = myTraineeRepository;
		this.traineeMemberLikeRepository = traineeMemberLikeRepository;
		this.gameRunMemberRepository = gameRunMemberRepository;
		this.photoCardMasterRepository = photoCardMasterRepository;
		this.userPhotoCardRepository = userPhotoCardRepository;
		this.equippedPhotoCardRepository = equippedPhotoCardRepository;
	}

	@Override
	@Transactional
	public Trainee createTrainee(TraineeCreateRequest request) {
		if (request == null || !StringUtils.hasText(request.getName()) || request.getGender() == null) {
			throw new IllegalArgumentException("연습생 이름과 성별은 필수입니다.");
		}
		Trainee trainee = new Trainee(
				request.getName().trim(),
				request.getGender(),
				Grade.N,
				clamp(request.getVocal()),
				clamp(request.getDance()),
				clamp(request.getStar()),
				clamp(request.getMental()),
				clamp(request.getTeamwork()),
				request.getImagePath());
		return traineeRepository.save(trainee);
	}

	@Override
	@Transactional
	public Trainee updateTrainee(Long traineeId, TraineeUpdateRequest request) {
		Trainee trainee = getTrainee(traineeId);
		if (request != null && StringUtils.hasText(request.getName())) {
			trainee.setName(request.getName().trim());
		}
		if (request != null && request.getGender() != null) {
			trainee.setGender(request.getGender());
		}
		if (request != null && request.getGrade() != null) {
			trainee.setGrade(request.getGrade());
		}
		if (request != null) {
			trainee.setAge(request.getAge());
			trainee.setBirthday(request.getBirthday());
			trainee.setHeight(request.getHeight());
			trainee.setHobby(trimToNull(request.getHobby()));
			trainee.setInstagram(trimToNull(request.getInstagram()));
		}
		return trainee;
	}

	@Override
	@Transactional
	public Trainee updateStats(Long traineeId, TraineeStatsUpdateRequest request) {
		Trainee trainee = getTrainee(traineeId);
		if (request == null) {
			return trainee;
		}
		trainee.setVocal(clamp(request.getVocal()));
		trainee.setDance(clamp(request.getDance()));
		trainee.setStar(clamp(request.getStar()));
		trainee.setMental(clamp(request.getMental()));
		trainee.setTeamwork(clamp(request.getTeamwork()));
		return trainee;
	}

	@Override
	@Transactional
	public Trainee updateImage(Long traineeId, String imagePath) {
		Trainee trainee = getTrainee(traineeId);
		trainee.setImagePath(imagePath);
		return trainee;
	}

	@Override
	@Transactional
	public void deleteTrainee(Long traineeId) {
		Trainee trainee = getTrainee(traineeId);
		myTraineeRepository.deleteByTraineeId(traineeId);
		traineeMemberLikeRepository.deleteByTraineeId(traineeId);
		gameRunMemberRepository.deleteByTrainee_Id(traineeId);
		equippedPhotoCardRepository.deleteByTrainee_Id(traineeId);
		List<Long> photoCardMasterIds = photoCardMasterRepository.findByTrainee_Id(traineeId).stream()
				.map(c -> c.getId())
				.collect(Collectors.toList());
		if (!photoCardMasterIds.isEmpty()) {
			userPhotoCardRepository.deleteByPhotoCardMaster_IdIn(photoCardMasterIds);
			equippedPhotoCardRepository.deleteByPhotoCardMaster_IdIn(photoCardMasterIds);
			photoCardMasterRepository.deleteByIdIn(photoCardMasterIds);
		}
		photoCardMasterRepository.deleteByTrainee_Id(traineeId);
		traineeRepository.delete(trainee);
	}

	@Override
	@Transactional(readOnly = true)
	public List<Trainee> searchForAdmin(String keyword, Gender gender, Grade grade, String sort) {
		List<Trainee> rows = traineeRepository.searchForAdmin(keyword == null ? "" : keyword.trim(), gender, grade);
		String sortKey = (sort == null ? "name" : sort.trim().toLowerCase());
		if ("ability".equals(sortKey)) {
			return rows.stream()
					.sorted(Comparator.comparingInt(Trainee::getAverageAbilityScore).reversed()
							.thenComparing(Trainee::getName, String.CASE_INSENSITIVE_ORDER))
					.toList();
		}
		return rows.stream().sorted(Comparator.comparing(Trainee::getName, String.CASE_INSENSITIVE_ORDER)).toList();
	}

	private Trainee getTrainee(Long traineeId) {
		return traineeRepository.findById(traineeId)
				.orElseThrow(() -> new IllegalArgumentException("연습생을 찾을 수 없습니다. id=" + traineeId));
	}

	private int clamp(Integer value) {
		if (value == null) {
			return 0;
		}
		return Math.max(0, Math.min(100, value));
	}

	private String trimToNull(String value) {
		if (!StringUtils.hasText(value)) {
			return null;
		}
		return value.trim();
	}
}
