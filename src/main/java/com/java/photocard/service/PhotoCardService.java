package com.java.photocard.service;

import java.util.Map;
import java.util.List;

import com.java.dto.PhotoCardBatchResultDto;
import com.java.dto.PhotoCardDrawResultDto;
import com.java.dto.TraineePhotoCardSummaryDto;
import com.java.dto.AdminPhotoCardDto;
import com.java.photocard.entity.PhotoCardGrade;
import org.springframework.web.multipart.MultipartFile;

public interface PhotoCardService {

	int PULL_COST_COIN = 100;

	/** 5회 묶음 가격 (연습생 뽑기 5회와 동일 톤) */
	int PHOTOCARD_PRICE_5 = 450;

	/** 10회 묶음 가격 */
	int PHOTOCARD_PRICE_10 = 850;

	/** 마스터 데이터가 없으면 시드(연습생 × 등급). */
	void ensureMastersInitialized();

	PhotoCardDrawResultDto pull(Long memberId);

	/** 5회·10회 묶음 (1회는 {@link #pull} 사용). 코인은 묶음 가격 1회 차감 후 각 줄을 처리합니다. */
	PhotoCardBatchResultDto pullBatch(Long memberId, int pulls);

	static int priceForPhotocardPulls(int pulls) {
		return switch (pulls) {
		case 1 -> PULL_COST_COIN;
		case 5 -> PHOTOCARD_PRICE_5;
		case 10 -> PHOTOCARD_PRICE_10;
		default -> throw new IllegalArgumentException("pulls must be 1, 5, or 10");
		};
	}

	/**
	 * 보유한 등급 카드만 장착 가능. 미보유면 실패.
	 */
	String equip(Long memberId, Long traineeId, PhotoCardGrade grade);

	TraineePhotoCardSummaryDto getSummary(Long memberId, Long traineeId);

	Map<Long, TraineePhotoCardSummaryDto> getSummariesForTrainees(Long memberId, Iterable<Long> traineeIds);

	AdminPhotoCardDto saveOrUpdateCard(Long traineeId, String grade, MultipartFile image);

	List<AdminPhotoCardDto> getCardsByTrainee(Long traineeId);

	int getEquippedBonusPercent(Long memberId, Long traineeId);

	/** 장착된 포토카드 등급 코드(R/SR/SSR) 또는 null */
	String getEquippedGradeCode(Long memberId, Long traineeId);

	static int applyPercentBonus(int baseStat, int bonusPercent) {
		if (bonusPercent <= 0 || baseStat <= 0) {
			return baseStat;
		}
		int add = (int) Math.round(baseStat * (bonusPercent / 100.0));
		return Math.max(0, Math.min(100, baseStat + add));
	}

	/**
	 * 등급별 포토카드 일러스트 경로. {@code 파일명_pc_SSR.jpg} 형태 — 없으면 클라이언트에서 기본 이미지로 대체.
	 */
	static String resolvePhotoCardImagePath(String baseTraineeImagePath, String gradeCode) {
		if (baseTraineeImagePath == null || baseTraineeImagePath.isBlank()) {
			return baseTraineeImagePath;
		}
		if (gradeCode == null || gradeCode.isBlank()) {
			return baseTraineeImagePath;
		}
		String g = gradeCode.trim().toUpperCase();
		int dot = baseTraineeImagePath.lastIndexOf('.');
		if (dot <= 0) {
			return baseTraineeImagePath + "_pc_" + g;
		}
		return baseTraineeImagePath.substring(0, dot) + "_pc_" + g + baseTraineeImagePath.substring(dot);
	}
}
