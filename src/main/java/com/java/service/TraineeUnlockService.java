package com.java.service;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.java.game.entity.GameRun;
import com.java.game.entity.Trainee;
import com.java.game.repository.GameRunRepository;

@Service
public class TraineeUnlockService {

	private final GameRunRepository gameRunRepository;

	public TraineeUnlockService(GameRunRepository gameRunRepository) {
		this.gameRunRepository = gameRunRepository;
	}

	public int resolveBestScore(Long memberId) {
		if (memberId == null) {
			return 0;
		}
		return gameRunRepository.findByPlayerMnoOrderByCreatedAtDesc(memberId).stream()
				.filter(run -> "FINISHED".equals(run.getPhase()))
				.map(GameRun::getScoreCache)
				.filter(score -> score != null)
				.mapToInt(Integer::intValue)
				.max()
				.orElse(0);
	}

	public boolean isUnlocked(Trainee trainee, int bestScore) {
		if (trainee == null) {
			return false;
		}
		Integer requiredScore = trainee.getUnlockScore();
		return requiredScore == null || requiredScore <= 0 || bestScore >= requiredScore;
	}

	public boolean isUnlockedForMember(Trainee trainee, Long memberId) {
		return isUnlocked(trainee, resolveBestScore(memberId));
	}

	public Set<Long> resolveLockedTraineeIds(List<Trainee> trainees, int bestScore) {
		Set<Long> lockedIds = new LinkedHashSet<>();
		if (trainees == null) {
			return lockedIds;
		}
		for (Trainee trainee : trainees) {
			if (trainee != null && trainee.getId() != null && !isUnlocked(trainee, bestScore)) {
				lockedIds.add(trainee.getId());
			}
		}
		return lockedIds;
	}
}
