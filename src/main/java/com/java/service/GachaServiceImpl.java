package com.java.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.java.dto.GachaPullLineDto;
import com.java.dto.GachaPullResultDto;
import com.java.dto.MyTraineeSummaryDto;
import com.java.entity.Board;
import com.java.entity.CastingEventEffectType;
import com.java.entity.CastingSpotBuff;
import com.java.entity.GachaPullLog;
import com.java.entity.Member;
import com.java.entity.MyTrainee;
import com.java.game.config.GachaConfig;
import com.java.game.entity.Grade;
import com.java.game.entity.Trainee;
import com.java.game.repository.TraineeRepository;
import com.java.repository.BoardRepository;
import com.java.repository.CastingSpotBuffRepository;
import com.java.repository.GachaPullLogRepository;
import com.java.repository.MemberRepository;
import com.java.repository.MyTraineeRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class GachaServiceImpl implements GachaService {

	private final TraineeRepository traineeRepository;
	private final MyTraineeRepository myTraineeRepository;
	private final GachaPullLogRepository gachaPullLogRepository;
	private final BoardRepository boardRepository;
	private final CastingSpotBuffRepository castingSpotBuffRepository;
	private final MarketService marketService;
	private final MemberRepository memberRepository;
	private final TraineeGroupService traineeGroupService;
	private final TraineeUnlockService traineeUnlockService;

	@PersistenceContext
	private EntityManager em;

	public GachaServiceImpl(TraineeRepository traineeRepository, MyTraineeRepository myTraineeRepository,
			GachaPullLogRepository gachaPullLogRepository, BoardRepository boardRepository,
			CastingSpotBuffRepository castingSpotBuffRepository, MarketService marketService,
			MemberRepository memberRepository, TraineeGroupService traineeGroupService,
			TraineeUnlockService traineeUnlockService) {
		this.traineeRepository = traineeRepository;
		this.myTraineeRepository = myTraineeRepository;
		this.gachaPullLogRepository = gachaPullLogRepository;
		this.boardRepository = boardRepository;
		this.castingSpotBuffRepository = castingSpotBuffRepository;
		this.marketService = marketService;
		this.memberRepository = memberRepository;
		this.traineeGroupService = traineeGroupService;
		this.traineeUnlockService = traineeUnlockService;
	}

	@Override
	@Transactional
	public GachaPullResultDto pull(Long memberId, int pulls, String poolId, Long eventId) {
		if (memberId == null) {
			return GachaPullResultDto.fail("회원 정보가 없습니다.");
		}
		if (pulls != 1 && pulls != 5 && pulls != 10) {
			return GachaPullResultDto.fail("뽑기 횟수가 올바르지 않습니다.");
		}
		String pid = poolId == null || poolId.isBlank() ? GachaConfig.DEFAULT_POOL_ID : poolId.trim();

		EventContext ctx = resolveEventContext(memberId, eventId, pulls, true);
		if (ctx.errorMessage != null) {
			return GachaPullResultDto.fail(ctx.errorMessage);
		}

		int price = ctx.price;
		int updated = em.createNativeQuery(
				"UPDATE MEMBER SET COIN = COIN - :price WHERE MNO = :mid AND COIN >= :price")
				.setParameter("price", price)
				.setParameter("mid", memberId)
				.executeUpdate();

		if (updated <= 0) {
			return GachaPullResultDto.lack(marketService.getCurrentCoin(memberId));
		}

		Map<Grade, List<Trainee>> byGrade = buildGradePools(memberId);
		List<GachaPullLineDto> lines = new ArrayList<>(ctx.physicalPulls);

		for (int i = 0; i < ctx.physicalPulls; i++) {
			Grade rolled = rollGrade(ctx.gradeWeights);
			Trainee picked = pickTrainee(rolled, byGrade, ctx.positionCode);
			long tid = picked.getId();

			var opt = myTraineeRepository.findByMemberIdAndTraineeId(memberId, tid);
			int beforeQty = opt.map(MyTrainee::getQuantity).orElse(0);
			if (opt.isPresent()) {
				MyTrainee row = opt.get();
				row.setQuantity(row.getQuantity() + 1);
				myTraineeRepository.save(row);
			} else {
				myTraineeRepository.save(new MyTrainee(memberId, tid, 1));
			}

			int afterQty = beforeQty + 1;
			String gradeStr = picked.getGrade() != null ? picked.getGrade().name() : rolled.name();

			gachaPullLogRepository.save(new GachaPullLog(memberId, tid, gradeStr, pid));

			lines.add(new GachaPullLineDto(
					tid,
					picked.getName(),
					gradeStr,
					picked.getImagePath(),
					beforeQty > 0,
					afterQty));
		}

		int coinAfter = marketService.getCurrentCoin(memberId);
		return GachaPullResultDto.success(coinAfter, lines);
	}

	private static final class EventContext {
		final Map<Grade, Integer> gradeWeights;
		final int price;
		final int physicalPulls;
		final String positionCode;
		final String errorMessage;

		EventContext(Map<Grade, Integer> gradeWeights, int price, int physicalPulls, String positionCode,
				String errorMessage) {
			this.gradeWeights = gradeWeights;
			this.price = price;
			this.physicalPulls = physicalPulls;
			this.positionCode = positionCode;
			this.errorMessage = errorMessage;
		}
	}

	/**
	 * @param strictPull true면 이벤트가 유효하지 않을 때 오류(뽑기 실패). false면 이벤트만 무시하고 맵 버프만 반영(UI).
	 */
	private EventContext resolveEventContext(Long memberId, Long eventId, int pulls, boolean strictPull) {
		Map<Grade, Integer> w = new LinkedHashMap<>(GachaConfig.getGradeWeightsBasisPoints());
		int physicalPulls = pulls;
		int price = GachaConfig.priceForPulls(pulls);
		String positionCode = null;

		if (eventId != null) {
			Board board = boardRepository.findById(eventId).orElse(null);
			if (board == null) {
				if (strictPull) {
					return new EventContext(w, price, physicalPulls, positionCode, "이벤트를 찾을 수 없습니다.");
				}
			} else if (!isBoardEligibleForGachaEvent(board)) {
				if (strictPull) {
					return new EventContext(w, price, physicalPulls, positionCode, "적용할 수 없는 이벤트입니다.");
				}
			} else {
				CastingEventEffectType et = CastingEventEffectType.fromDb(board.getEffectType());
				if (et == null) {
					if (strictPull) {
						return new EventContext(w, price, physicalPulls, positionCode, "이벤트 효과가 설정되지 않았습니다.");
					}
				} else {
					int bp = board.parseEffectBasisPoints();
					switch (et) {
					case SSR_UP:
						shiftWeightFromN(w, Grade.SSR, bp);
						break;
					case SR_UP:
						shiftWeightFromN(w, Grade.SR, bp);
						break;
					case POSITION_PICKUP:
						positionCode = normalizePositionCode(board.getEffectValue());
						break;
					case DISCOUNT_PULL:
						price = applyDiscount(price, board.parseDiscountPercent());
						break;
					case BONUS_PULL:
						if (pulls == 5 || pulls == 10) {
							physicalPulls = pulls + 1;
						}
						break;
					default:
						break;
					}
				}
			}
		}

		if (memberId != null) {
			int[] priceBox = { price };
			int[] pullsBox = { physicalPulls };
			castingSpotBuffRepository
					.findFirstByMemberIdAndExpireAtAfterOrderByExpireAtDesc(memberId, LocalDateTime.now())
					.ifPresent(buff -> applyCastingSpotBuff(w, priceBox, pullsBox, buff, pulls));
			price = priceBox[0];
			physicalPulls = pullsBox[0];
		}

		return new EventContext(w, price, physicalPulls, positionCode, null);
	}

	private void applyCastingSpotBuff(Map<Grade, Integer> w, int[] priceBox, int[] pullsBox, CastingSpotBuff buff,
			int pulls) {
		CastingEventEffectType et = buff.getEffectTypeEnum();
		if (et == null) {
			return;
		}
		switch (et) {
		case SSR_UP:
			shiftWeightFromN(w, Grade.SSR, buff.parseEffectBasisPoints());
			break;
		case SR_UP:
			shiftWeightFromN(w, Grade.SR, buff.parseEffectBasisPoints());
			break;
		case DISCOUNT_PULL:
			priceBox[0] = applyDiscount(priceBox[0], buff.parseDiscountPercent());
			break;
		case BONUS_PULL:
			if (pulls == 5 || pulls == 10) {
				pullsBox[0] += 1;
			}
			break;
		default:
			break;
		}
	}

	private static boolean isBoardEligibleForGachaEvent(Board b) {
		if (!"map".equals(b.getBoardType()) || !b.isVisible() || !b.isFanMeetApproved()) {
			return false;
		}
		if (!b.isEventActive()) {
			return false;
		}
		if (b.getEventStartAt() == null || b.getEventEndAt() == null) {
			return false;
		}
		if (CastingEventEffectType.fromDb(b.getEffectType()) == null) {
			return false;
		}
		var now = java.time.LocalDateTime.now();
		return !now.isBefore(b.getEventStartAt()) && !now.isAfter(b.getEventEndAt());
	}

	/** 배너·상점 UI용 — 풀 효과는 적용 중일 때만 표시 */
	public static boolean isBoardForGachaDisplay(Board b) {
		if (b == null || !b.isBannerEnabled()) {
			return false;
		}
		if (!b.isEventActive() || CastingEventEffectType.fromDb(b.getEffectType()) == null) {
			return false;
		}
		if (b.getEventStartAt() == null || b.getEventEndAt() == null) {
			return false;
		}
		var now = java.time.LocalDateTime.now();
		return now.isBefore(b.getEventEndAt());
	}

	private static void shiftWeightFromN(Map<Grade, Integer> w, Grade target, int bp) {
		if (bp <= 0) {
			return;
		}
		int n = w.getOrDefault(Grade.N, 0);
		int d = Math.min(bp, Math.max(0, n - 1));
		if (d <= 0) {
			return;
		}
		w.put(Grade.N, n - d);
		w.put(target, w.getOrDefault(target, 0) + d);
	}

	private static int applyDiscount(int price, int discountPercent) {
		if (discountPercent <= 0) {
			return price;
		}
		int p = price * (100 - discountPercent) / 100;
		return Math.max(1, p);
	}

	private static String normalizePositionCode(String raw) {
		if (raw == null || raw.isBlank()) {
			return "VOCAL";
		}
		String u = raw.trim().toUpperCase();
		return switch (u) {
		case "VOCAL", "DANCE", "STAR", "MENTAL", "TEAMWORK" -> u;
		default -> "VOCAL";
		};
	}

	private Map<Grade, List<Trainee>> buildGradePools(Long memberId) {
		int unlockMask = resolveUnlockMask(memberId);
		int bestScore = traineeUnlockService.resolveBestScore(memberId);
		Map<Grade, List<Trainee>> map = new HashMap<>();
		for (Grade g : Grade.values()) {
			List<Trainee> list = traineeRepository.findByGrade(g).stream()
					.filter(t -> traineeGroupService.isUnlocked(unlockMask, traineeGroupService.resolveTraineeGroup(t.getName())))
					.filter(t -> traineeUnlockService.isUnlocked(t, bestScore))
					.toList();
			map.put(g, list == null ? List.of() : list);
		}
		return map;
	}

	private int resolveUnlockMask(Long memberId) {
		if (memberId == null) {
			return TraineeGroupService.DEFAULT_UNLOCK_MASK;
		}
		Member member = memberRepository.findById(memberId).orElse(null);
		if (member == null) {
			return TraineeGroupService.DEFAULT_UNLOCK_MASK;
		}
		int mask = member.getGroupUnlockMask();
		return mask > 0 ? mask : TraineeGroupService.DEFAULT_UNLOCK_MASK;
	}

	private Grade rollGrade(Map<Grade, Integer> weights) {
		int r = ThreadLocalRandom.current().nextInt(10_000);
		int acc = 0;
		for (Map.Entry<Grade, Integer> e : weights.entrySet()) {
			acc += e.getValue();
			if (r < acc) {
				return e.getKey();
			}
		}
		return Grade.N;
	}

	private Trainee pickTrainee(Grade rolled, Map<Grade, List<Trainee>> byGrade, String positionCode) {
		List<Trainee> pool = byGrade.getOrDefault(rolled, List.of());
		if (pool.isEmpty()) {
			pool = byGrade.values().stream()
					.flatMap(List::stream)
					.toList();
		}
		if (pool.isEmpty()) {
			throw new IllegalStateException("해금된 연습생 데이터가 없습니다.");
		}
		if (positionCode == null || pool.size() == 1) {
			return pool.get(ThreadLocalRandom.current().nextInt(pool.size()));
		}
		return weightedPickByPosition(pool, positionCode);
	}

	private static Trainee weightedPickByPosition(List<Trainee> pool, String positionCode) {
		int[] weights = new int[pool.size()];
		int total = 0;
		for (int i = 0; i < pool.size(); i++) {
			int w = 1;
			if (positionCode.equals(dominantPositionCode(pool.get(i)))) {
				w = 2;
			}
			weights[i] = w;
			total += w;
		}
		int r = ThreadLocalRandom.current().nextInt(total);
		int acc = 0;
		for (int i = 0; i < pool.size(); i++) {
			acc += weights[i];
			if (r < acc) {
				return pool.get(i);
			}
		}
		return pool.get(pool.size() - 1);
	}

	static String dominantPositionCode(Trainee t) {
		int v = t.getVocal();
		int d = t.getDance();
		int s = t.getStar();
		int m = t.getMental();
		int tw = t.getTeamwork();
		int max = Math.max(Math.max(Math.max(v, d), Math.max(s, m)), tw);
		if (v == max) {
			return "VOCAL";
		}
		if (d == max) {
			return "DANCE";
		}
		if (s == max) {
			return "STAR";
		}
		if (m == max) {
			return "MENTAL";
		}
		return "TEAMWORK";
	}

	@Override
	@Transactional(readOnly = true)
	public List<MyTraineeSummaryDto> listOwnedTrainees(Long memberId) {
		if (memberId == null) {
			return List.of();
		}
		List<MyTrainee> rows = myTraineeRepository.findByMemberIdOrderByIdDesc(memberId);
		List<MyTraineeSummaryDto> out = new ArrayList<>();
		for (MyTrainee mt : rows) {
			traineeRepository.findById(mt.getTraineeId()).ifPresent(t -> out.add(new MyTraineeSummaryDto(
					t.getId(),
					t.getName(),
					t.getGrade() != null ? t.getGrade().name() : "",
					t.getImagePath(),
					mt.getQuantity(),
					mt.getEnhanceLevel())));
		}
		return out;
	}

	@Override
	public Map<String, Object> getPublicSettings(Long eventId, Long memberId) {
		Map<String, Object> m = new LinkedHashMap<>();
		EventContext ctx1 = resolveEventContext(memberId, eventId, 1, false);
		EventContext ctx5 = resolveEventContext(memberId, eventId, 5, false);
		EventContext ctx10 = resolveEventContext(memberId, eventId, 10, false);
		m.put("poolId", GachaConfig.DEFAULT_POOL_ID);
		m.put("priceSingle", ctx1.price);
		m.put("priceMulti", ctx5.price);
		m.put("multiCount", GachaConfig.MULTI_PULL_COUNT);
		m.put("price10", ctx10.price);
		m.put("count10", GachaConfig.PULL_COUNT_10);
		m.put("gradeProbabilities", toGradeProbMap(ctx1.gradeWeights));
		m.put("castingEventActive", false);
		m.put("castingSpotBuffActive", false);

		if (eventId != null) {
			boardRepository.findById(eventId).ifPresent(b -> {
				if (isBoardForGachaDisplay(b)) {
					m.put("castingEventActive", true);
					m.put("castingEventId", b.getId());
					m.put("castingEventTitle", b.getTitle());
					m.put("castingEventEffectLine", b.getCastingEffectSummaryLine());
					m.put("castingEventRemaining", b.getCastingEventRemainingShort());
					m.put("castingEventStatus", b.getCastingEventStatusLabel());
				}
			});
		}

		if (memberId != null) {
			castingSpotBuffRepository
					.findFirstByMemberIdAndExpireAtAfterOrderByExpireAtDesc(memberId, LocalDateTime.now())
					.ifPresent(buff -> {
						m.put("castingSpotBuffActive", true);
						m.put("castingSpotBuffTitle", buff.getSpotLabel());
						m.put("castingSpotBuffEffectLine", buff.getEffectSummaryLine());
						m.put("castingSpotBuffExpireAt", buff.getExpireAt().toString());
					});
		}

		int extra5 = ctx5.physicalPulls - 5;
		if (extra5 > 0) {
			m.put("multiBonusNote", "5+" + extra5 + " 보너스");
		}
		int extra10 = ctx10.physicalPulls - 10;
		if (extra10 > 0) {
			m.put("multi10BonusNote", "10+" + extra10 + " 보너스");
		}
		return m;
	}

	private static Map<String, String> toGradeProbMap(Map<Grade, Integer> bp) {
		Map<String, String> out = new LinkedHashMap<>();
		for (var e : bp.entrySet()) {
			out.put(e.getKey().name(), String.format("%.2f", e.getValue() / 100.0));
		}
		return out;
	}
}
