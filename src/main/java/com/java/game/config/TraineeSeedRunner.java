package com.java.game.config;

import java.util.Comparator;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;
import java.time.LocalDate;

import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.java.game.entity.Gender;
import com.java.game.entity.Grade;
import com.java.game.entity.Trainee;
import com.java.game.repository.TraineeRepository;
import com.java.game.service.IdolPersonality;

@Component
@Order(1)
public class TraineeSeedRunner implements CommandLineRunner {

	private final TraineeRepository traineeRepository;

	public TraineeSeedRunner(TraineeRepository traineeRepository) {
		this.traineeRepository = traineeRepository;
	}

	/* ── 남자 연습생 이름 (1차 10명) ── */
	private static final String[] MALE_NAMES = { "이준혁", "박시우", "김민호", "최태준", "정현우", "강준서", "윤재원", "송유진", "한석우", "임도현" };

	/* ── 남자 연습생 이름 (2차 10명) ── */
	private static final String[] MALE_NAMES2 = { "서제이", "강도윤", "은우진", "한결", "신이안", "차승현", "윤태오", "임세준", "권하준", "백시우" };

	/* ── 여자 연습생 이름 (1차 10명) ── */
	private static final String[] FEMALE_NAMES = { "김소연", "박민지", "이유라", "최하은", "정지연", "강나은", "윤은지", "송채린", "한소미",
			"임예은" };

	/* ── 여자 연습생 이름 (2차 10명) ── */
	private static final String[] FEMALE_NAMES2 = { "민서아", "이채린", "서유나", "박지수", "안하은", "유해나", "성주아", "최로아", "한예슬", "정다인" };

	/* 랜덤 데이터 풀 */
	private static final String[] HOBBIES = { "노래 듣기", "춤 연습", "독서", "요리", "드라이브", "게임", "수영", "그림 그리기", "영화 감상", "쇼핑",
			"유튜브 보기", "산책", "헬스", "카페 탐방", "사진 찍기" };

	private static final String[] MOTTOS = { "하루하루 최선을 다하자", "포기하지 않으면 반드시 이긴다", "꿈꾸는 자만이 이룰 수 있다", "나를 믿자",
			"오늘의 나는 어제보다 성장했다", "웃으면 복이 온다", "열정이 재능을 이긴다", "지금 이 순간을 즐겨라", "작은 것에도 감사하자", "두려움 없이 도전하자", "진심은 반드시 통한다",
			"빛나는 순간을 위해" };

	private static final String[] MALE_INSTA = { "jun_star_", "minho.official", "siwoo_shine", "hyun_debut", "taejun.x",
			"kangmin_idol", "yujin_trainee", "seokwoo_mv", "dahun_stage", "ryunix_" };

	private static final String[] FEMALE_INSTA = { "soyeon.g", "minji_bloom", "yura_sparkle", "haeun_official",
			"jiyeon_star", "naeun.shine", "eunji_debut", "chaerin_x", "somi_trainee", "yeeun_idol" };

	private static final String[] MALE_INSTA2 = { "sejay_stage", "doyun_daily", "woojin.vocal", "hangyul_x", "ian_shine",
			"seunghyun_mv", "taeo_trainee", "sejun_official", "hajun.debut", "siwoo_bloom" };

	private static final String[] FEMALE_INSTA2 = { "seoa_archive", "chaerin_spark", "yuna_daily", "jisuu_stage",
			"haeun_soft", "haena_trainee", "jua_shine", "roa_debut", "yesul_mv", "dain_x" };

	@Override
	@Transactional
	public void run(String... args) throws Exception {
		Random rnd = new Random();

		List<Trainee> all = traineeRepository.findAll();
		long maleCount = all.stream().filter(t -> t.getGender() == Gender.MALE).count();
		long femaleCount = all.stream().filter(t -> t.getGender() == Gender.FEMALE).count();
		if (!all.isEmpty() && maleCount == 10 && femaleCount == 10) {
			seedSecondBatch(rnd);
			all = traineeRepository.findAll();
			System.out.println("✅ 연습생 2차 배치 추가 완료: 남자 10명, 여자 10명 (이미지 m11~m20, f11~f20)");
		}

		boolean needsProfile = all.stream().anyMatch(t -> t.getAge() == null || t.getBirthday() == null);
		boolean needsNameUpdate = all.stream().anyMatch(
				t -> t.getName() != null && (t.getName().startsWith("남연습생") || t.getName().startsWith("여연습생")));

		boolean needsStatUpdate = all.stream().anyMatch(t ->
				t.getVocal() < 0 || t.getVocal() > 20
				|| t.getDance() < 0 || t.getDance() > 20
				|| t.getStar() < 0 || t.getStar() > 20
				|| t.getMental() < 0 || t.getMental() > 20
				|| t.getTeamwork() < 0 || t.getTeamwork() > 20);
		boolean allZeroStats = !all.isEmpty() && all.stream().allMatch(t ->
				t.getVocal() == 0 && t.getDance() == 0 && t.getStar() == 0 && t.getMental() == 0 && t.getTeamwork() == 0);

		boolean needsTierMigration = !all.isEmpty() && all.stream().anyMatch(t -> t.getGrade() == null);

		if (!needsProfile && !needsNameUpdate && !needsStatUpdate && !allZeroStats && !needsTierMigration && !all.isEmpty()) {
			return;
		}

		if (all.isEmpty()) {
			seedInitial(rnd);
			return;
		}

		List<Trainee> males = all.stream().filter(t -> t.getGender() == Gender.MALE)
				.sorted(Comparator.comparing(Trainee::getId)).collect(Collectors.toList());
		List<Trainee> females = all.stream().filter(t -> t.getGender() == Gender.FEMALE)
				.sorted(Comparator.comparing(Trainee::getId)).collect(Collectors.toList());

		if (needsTierMigration) {
			for (int i = 0; i < males.size(); i++) {
				Trainee t = males.get(i);
				Grade g = i < 10 ? gradeForMaleIndex(i) : gradeForSecondBatchIndex(i - 10);
				t.setGrade(g);
				applyStatsForGrade(rnd, t, g);
			}
			for (int i = 0; i < females.size(); i++) {
				Trainee t = females.get(i);
				Grade g = i < 10 ? gradeForFemaleIndex(i) : gradeForSecondBatchIndex(i - 10);
				t.setGrade(g);
				applyStatsForGrade(rnd, t, g);
			}
		} else {
			for (Trainee t : all) {
				if (needsStatUpdate || allZeroStats) {
					t.setVocal(randBaseStat(rnd));
					t.setDance(randBaseStat(rnd));
					t.setStar(randBaseStat(rnd));
					t.setMental(randBaseStat(rnd));
					t.setTeamwork(randBaseStat(rnd));
				}
			}
		}

		int mIdx = 0;
		for (Trainee t : males) {
			if (t.getName() != null && t.getName().startsWith("남연습생")) {
				if (mIdx < MALE_NAMES.length) t.setName(MALE_NAMES[mIdx]);
				else if (mIdx - MALE_NAMES.length < MALE_NAMES2.length) t.setName(MALE_NAMES2[mIdx - MALE_NAMES.length]);
			}
			String insta = mIdx < 10 ? MALE_INSTA[mIdx] : MALE_INSTA2[mIdx - 10];
			fillProfile(t, rnd, insta);
			mIdx++;
			traineeRepository.save(t);
		}
		int fIdx = 0;
		for (Trainee t : females) {
			if (t.getName() != null && t.getName().startsWith("여연습생")) {
				if (fIdx < FEMALE_NAMES.length) t.setName(FEMALE_NAMES[fIdx]);
				else if (fIdx - FEMALE_NAMES.length < FEMALE_NAMES2.length) {
					t.setName(FEMALE_NAMES2[fIdx - FEMALE_NAMES.length]);
				}
			}
			String insta = fIdx < 10 ? FEMALE_INSTA[fIdx] : FEMALE_INSTA2[fIdx - 10];
			fillProfile(t, rnd, insta);
			fIdx++;
			traineeRepository.save(t);
		}
		System.out.println("✅ 연습생 이름 + 프로필 + 스탯(등급) 업데이트 완료");
	}

	/** 남자 10명: 등급별 5명씩 분배 (N×2, R×3, SR×2, SSR×3) */
	private static Grade gradeForMaleIndex(int i) {
		return switch (i) {
			case 0, 1 -> Grade.N;
			case 2, 3, 4 -> Grade.R;
			case 5, 6 -> Grade.SR;
			default -> Grade.SSR;
		};
	}

	/** 여자 10명: 등급별 5명씩 분배 (N×3, R×2, SR×3, SSR×2) */
	private static Grade gradeForFemaleIndex(int i) {
		return switch (i) {
			case 0, 1, 2 -> Grade.N;
			case 3, 4 -> Grade.R;
			case 5, 6, 7 -> Grade.SR;
			default -> Grade.SSR;
		};
	}

	/** 2차 10명(남·여 공통): N×2, R×3, SR×3, SSR×2 */
	private static Grade gradeForSecondBatchIndex(int i) {
		return switch (i) {
			case 0, 1 -> Grade.N;
			case 2, 3, 4 -> Grade.R;
			case 5, 6, 7 -> Grade.SR;
			default -> Grade.SSR;
		};
	}

	/**
	 * 등급별 평균 능력치(합계) 구간: N 50~60, R 60~70, SR 70~80, SSR 80~90.
	 * 각 스탯 0~20, 합은 위 구간의 임의 값이 되도록 분배한다.
	 */
	private static void applyStatsForGrade(Random rnd, Trainee t, Grade g) {
		int minSum = switch (g) {
		case N -> 50;
		case R -> 60;
		case SR -> 70;
		case SSR -> 80;
		case HIDDEN -> 90;
		};
		int maxSum = switch (g) {
		case N -> 60;
		case R -> 70;
		case SR -> 80;
		case SSR -> 90;
		case HIDDEN -> 100;
		};
		randomStatsWithSum(rnd, t, minSum, maxSum);
	}

	private static void randomStatsWithSum(Random rnd, Trainee t, int minSum, int maxSum) {
		int target = minSum + rnd.nextInt(maxSum - minSum + 1);
		int[] v = new int[5];
		int added = 0;
		while (added < target) {
			int i = rnd.nextInt(5);
			if (v[i] < 100) {
				v[i]++;
				added++;
			}
		}
		t.setVocal(v[0]);
		t.setDance(v[1]);
		t.setStar(v[2]);
		t.setMental(v[3]);
		t.setTeamwork(v[4]);
	}

	private int randBaseStat(Random rnd) {
		return 4 + rnd.nextInt(9);
	}

	private void fillProfile(Trainee t, Random rnd, String insta) {
		int age = 19 + rnd.nextInt(5);
		t.setAge(age);
		t.setBirthday(randomBirthdayFromAge(rnd, age));
		if (t.getGender() == Gender.MALE) {
			t.setHeight(173 + rnd.nextInt(13));
			t.setWeight(60 + rnd.nextInt(21));
		} else {
			t.setHeight(158 + rnd.nextInt(12));
			t.setWeight(45 + rnd.nextInt(16));
		}
		t.setHobby(HOBBIES[rnd.nextInt(HOBBIES.length)]);
		t.setMotto(MOTTOS[rnd.nextInt(MOTTOS.length)]);
		t.setInstagram(insta);
		if (t.getPersonalityCode() == null || t.getPersonalityCode().isBlank()) {
			IdolPersonality[] p = IdolPersonality.values();
			t.setPersonalityCode(p[rnd.nextInt(p.length)].name());
		}
	}

	private LocalDate randomBirthdayFromAge(Random rnd, int age) {
		LocalDate now = LocalDate.now();
		LocalDate yearBase = now.minusYears(age);
		int month = 1 + rnd.nextInt(12);
		int day = 1 + rnd.nextInt(28);
		return LocalDate.of(yearBase.getYear(), month, day);
	}

	private void seedSecondBatch(Random rnd) {
		for (int i = 0; i < 10; i++) {
			String img = "/images/trainee/m" + (11 + i) + ".jpg";
			Grade g = gradeForSecondBatchIndex(i);
			Trainee t = new Trainee(MALE_NAMES2[i], Gender.MALE, g, 0, 0, 0, 0, 0, img);
			applyStatsForGrade(rnd, t, g);
			fillProfile(t, rnd, MALE_INSTA2[i]);
			traineeRepository.save(t);
		}
		for (int i = 0; i < 10; i++) {
			String img = "/images/trainee/f" + (11 + i) + ".jpg";
			Grade g = gradeForSecondBatchIndex(i);
			Trainee t = new Trainee(FEMALE_NAMES2[i], Gender.FEMALE, g, 0, 0, 0, 0, 0, img);
			applyStatsForGrade(rnd, t, g);
			fillProfile(t, rnd, FEMALE_INSTA2[i]);
			traineeRepository.save(t);
		}
	}

	private void seedInitial(Random rnd) {
		for (int i = 0; i < 10; i++) {
			String img = "/images/trainee/m" + String.format("%02d", i + 1) + ".jpg";
			Grade g = gradeForMaleIndex(i);
			Trainee t = new Trainee(MALE_NAMES[i], Gender.MALE, g, 0, 0, 0, 0, 0, img);
			applyStatsForGrade(rnd, t, g);
			fillProfile(t, rnd, MALE_INSTA[i]);
			traineeRepository.save(t);
		}

		for (int i = 0; i < 10; i++) {
			String img = "/images/trainee/f" + String.format("%02d", i + 1) + ".jpg";
			Grade g = gradeForFemaleIndex(i);
			Trainee t = new Trainee(FEMALE_NAMES[i], Gender.FEMALE, g, 0, 0, 0, 0, 0, img);
			applyStatsForGrade(rnd, t, g);
			fillProfile(t, rnd, FEMALE_INSTA[i]);
			traineeRepository.save(t);
		}

		seedSecondBatch(rnd);

		System.out.println("✅ 연습생 시드 데이터 + 등급/프로필 생성 완료: 남자 20명, 여자 20명");
	}
}
