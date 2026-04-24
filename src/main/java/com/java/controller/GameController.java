package com.java.controller;

import com.java.game.service.ChemistryResult;
import com.java.game.service.ChemistryService;
import com.java.game.service.EndingResult;
import com.java.game.service.EndingService;
import com.java.game.service.GameRunResult;
import com.java.game.service.GameAiNarrationService;
import com.java.game.service.IdolDialogueBlock;
import com.java.game.service.GameService;
import com.java.game.service.RankingPeriod;
import com.java.game.service.IdolPersonality;
import com.java.game.service.SceneResult;
import com.java.service.MarketService;
import com.java.dto.MyItemDto;
import com.java.game.service.ChatApplyOutcome;
import com.java.game.service.IdolChatLine;
import com.java.game.service.StatChangeResult;
import com.java.game.entity.GroupType;
import com.java.game.entity.GameMiniQuiz;
import com.java.config.SessionConst;
import com.java.dto.LoginMember;
import com.java.game.repository.GameRunRepository;
import com.java.game.repository.GameMiniQuizRepository;
import com.java.game.repository.TraineeRepository;
import com.java.repository.MemberRepository;
import com.java.entity.Member;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Comparator;
import java.util.Map;
import java.util.Objects;
import java.util.Random;
import com.java.game.service.RankingRow;
import com.java.game.service.RosterItem;
import com.java.game.service.TraineeLikeService;
import com.java.game.util.LikeCountFormat;
import com.java.entity.MemberRank;
import com.java.dto.MemberRankReward;
import com.java.game.entity.GameRun;
import java.util.List;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/game")
public class GameController {

    /** 훈련 스케줄 달력 시작일 (DAY 1 = 이 날짜) */
    /** 게임 내 달력: DAY 1 = 2026-01-01, 일차마다 하루씩 진행(요일은 실제 달력과 동일) */
    private static final LocalDate TRAINING_CALENDAR_START = LocalDate.of(2026, 1, 1);
    private static final int TRAINING_PLAN_TOTAL_DAYS = 84;

    private final GameService gameService;
    private final GameRunRepository gameRunRepository;
    private final MemberRepository memberRepository;
    private final ChemistryService chemistryService;
    private final EndingService endingService;
    private final MarketService marketService;
    private final GameAiNarrationService gameAiNarrationService;
    private final TraineeLikeService traineeLikeService;
    private final TraineeRepository traineeRepository;
    private final GameMiniQuizRepository gameMiniQuizRepository;

    public GameController(GameService gameService,
                          GameRunRepository gameRunRepository,
                          MemberRepository memberRepository,
                          ChemistryService chemistryService,
                          EndingService endingService,
                          MarketService marketService,
                          GameAiNarrationService gameAiNarrationService,
                          TraineeLikeService traineeLikeService,
                          TraineeRepository traineeRepository,
                          GameMiniQuizRepository gameMiniQuizRepository) {
        this.gameService = gameService;
        this.gameRunRepository = gameRunRepository;
        this.memberRepository = memberRepository;
        this.chemistryService = chemistryService;
        this.endingService = endingService;
        this.marketService = marketService;
        this.gameAiNarrationService = gameAiNarrationService;
        this.traineeLikeService = traineeLikeService;
        this.traineeRepository = traineeRepository;
        this.gameMiniQuizRepository = gameMiniQuizRepository;
    }

    // 게임 홈 진입 시 메인 모달 오픈
    @GetMapping
    public String gameHome() {
        return "redirect:/main?openGameModal=1";
    }

    /** 플레이 화면 UI (game.jsp). 데모 단독 / 이후 scene·runId 모델 확장 가능 */
    @GetMapping("/screen")
    public String gamePlayScreen() {
        return "game/game";
    }

@GetMapping("/continue")
public String continueLatestRun(@RequestParam(name = "runId", required = false) Long requestedRunId,
                                HttpSession session) {
    LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);

    if (requestedRunId != null) {
        GameRun requested = gameRunRepository.findById(requestedRunId).orElse(null);
        if (requested != null && canAccessRun(requested, lm)) {
            if ("FINISHED".equals(requested.getPhase())) {
                return "redirect:/main?openGameModal=1&noContinue=1";
            }
            return redirectToRunProgress(requested, true);
        }
    }

    if (lm != null && lm.mno() != null) {
        try {
            List<GameRun> myRuns = gameRunRepository.findByPlayerMnoOrderByCreatedAtDesc(lm.mno());
            GameRun candidate = pickBestContinueRun(myRuns);
            if (candidate != null) {
                return redirectToRunProgress(candidate, false);
            }
        } catch (Exception ignored) {
        }
    }

    if (lm != null && lm.mno() != null) {
        return "redirect:/main?openGameModal=1&noContinue=1";
    }
    return "redirect:/main?openGameModal=1";
}

// 그룹 선택 후 랜덤 선발 실행
    @PostMapping("/run")
    public String createRun(@RequestParam(name = "groupType") GroupType groupType,
                            HttpSession session,
                            RedirectAttributes redirectAttributes) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        try {
            Long runId = gameService.createRunAndPickRoster(groupType, lm != null ? lm.mno() : null);
            if (lm != null) {
                gameService.setPlayerMno(runId, lm.mno());
            }
            return "redirect:/game/run/" + runId + "/roster";
        } catch (IllegalStateException ex) {
            redirectAttributes.addFlashAttribute("rosterError", ex.getMessage());
            return "redirect:/main?openGameModal=1";
        }
    }


    // 그룹 선택 + 선발 결과 미리보기 (AJAX)
    @ResponseBody
    @PostMapping("/run/preview")
    public ResponseEntity<Map<String, Object>> previewRun(@RequestParam(name = "groupType") GroupType groupType,
                                                           HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        try {
            Long runId = gameService.createRunAndPickRoster(groupType, lm != null ? lm.mno() : null);
            if (lm != null) {
                gameService.setPlayerMno(runId, lm.mno());
            }

            GameRunResult result = gameService.getRunResult(runId);

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("runId", result.runId());
            body.put("groupType", result.groupType());
            body.put("confirmed", result.confirmed());
            body.put("phase", result.phase());
            body.put("roster", result.roster());
            return ResponseEntity.ok(body);
        } catch (IllegalStateException ex) {
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("error", ex.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // 선발 결과 화면
    @GetMapping("/run/{runId}/roster")
    public String roster(@PathVariable(name = "runId") Long runId, Model model, HttpSession session) {
        GameRunResult result = gameService.getRunResult(runId);
        GameRun run = gameRunRepository.findById(runId).orElse(null);
        if (run == null) {
            return "redirect:/main?openGameModal=1";
        }
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (!isRunAccessible(run, lm)) {
            return loginRedirectForPath("/game/run/" + runId + "/roster");
        }
        ChemistryResult chemistry = chemistryService.analyze(result.roster());
        model.addAttribute("result", result);
        model.addAttribute("chemistry", chemistry);
        model.addAttribute("personalityOptions", IdolPersonality.values());
        model.addAttribute("rerollRemaining", getRerollRemaining(runId, lm));
        List<MyItemDto> myItems = (lm == null) ? List.of() : marketService.getMyItems(lm.mno());
        model.addAttribute("myItems", myItems);
        return "game/roster";
    }

    @ResponseBody
    @PostMapping("/run/{runId}/roster/personality")
    public ResponseEntity<Map<String, Object>> updateRosterPersonality(
            @PathVariable(name = "runId") Long runId,
            @RequestBody(required = false) Map<String, Object> body) {
        try {
            Long traineeId = null;
            String personalityCode = null;
            if (body != null) {
                Object tid = body.get("traineeId");
                if (tid != null) {
                    try { traineeId = Long.valueOf(String.valueOf(tid)); } catch (Exception ignored) {}
                }
                Object pc = body.get("personalityCode");
                if (pc != null) {
                    personalityCode = String.valueOf(pc);
                }
            }
            var roster = gameService.updateRosterPersonality(runId, traineeId, personalityCode);
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("message", "성격을 저장했습니다.");
            out.put("roster", roster);
            return ResponseEntity.ok(out);
        } catch (Exception e) {
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("error", e.getMessage() == null ? "성격 저장에 실패했습니다." : e.getMessage());
            return ResponseEntity.badRequest().body(out);
        }
    }

    // 선발 확정 처리
    @PostMapping("/run/{runId}/confirm")
    public String confirmRun(@PathVariable(name = "runId") Long runId) {
        gameService.confirmRun(runId);
        return "redirect:/game/run/" + runId + "/roster";
    }


    @ResponseBody
    @PostMapping("/run/{runId}/reroll")
    public ResponseEntity<Map<String, Object>> rerollRun(@PathVariable(name = "runId") Long runId, HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        int remaining = getRerollRemaining(runId, lm);

        if (remaining <= 0) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("error", "다시뽑기 횟수를 모두 사용했습니다.");
            body.put("rerollRemaining", remaining);
            return ResponseEntity.badRequest().body(body);
        }

        try {
            var roster = gameService.rerollRun(runId);
            if (!consumeReroll(runId, lm)) {
                Map<String, Object> body = new LinkedHashMap<>();
                body.put("error", "다시뽑기 처리에 실패했습니다.");
                body.put("rerollRemaining", getRerollRemaining(runId, lm));
                return ResponseEntity.badRequest().body(body);
            }
            int nextRemaining = getRerollRemaining(runId, lm);

            ChemistryResult chemistry = chemistryService.analyze(roster);

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("message", "로스터를 다시 선발했습니다.");
            body.put("roster", roster);
            body.put("chemistry", chemistry);
            body.put("rerollRemaining", nextRemaining);
            putRerollTiming(body, runId, lm);
            return ResponseEntity.ok(body);
        } catch (IllegalStateException ex) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("error", ex.getMessage());
            body.put("rerollRemaining", getRerollRemaining(runId, lm));
            return ResponseEntity.badRequest().body(body);
        }
    }

    @ResponseBody
    @GetMapping("/run/{runId}/reroll/status")
    public ResponseEntity<Map<String, Object>> rerollStatus(@PathVariable(name = "runId") Long runId, HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("rerollRemaining", getRerollRemaining(runId, lm));
        putRerollTiming(body, runId, lm);
        return ResponseEntity.ok(body);
    }

    @ResponseBody
    @PostMapping("/run/{runId}/items/apply")
    public ResponseEntity<Map<String, Object>> applyItemsAjax(@PathVariable(name = "runId") Long runId,
                                                              @RequestBody Map<String, Object> body,
                                                              HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        Map<String, Object> res = new LinkedHashMap<>();
        if (lm == null) {
            res.put("result", "logout");
            return ResponseEntity.ok(res);
        }
        Object elimCsv = body.get("eliminatedTids");
        if (elimCsv != null) {
            mergeEliminatedTidsIntoSession(session, runId, String.valueOf(elimCsv));
        }
        Object raw = body.get("itemIds");
        List<Long> ids = new ArrayList<>();
        if (raw instanceof List<?> list) {
            for (Object o : list) {
                if (o == null) continue;
                try { ids.add(Long.valueOf(String.valueOf(o))); } catch (Exception ignore) {}
            }
        }
        String appliedItemSessionKey = "APPLIED_ITEMS_RUN_" + runId;
        String itemGlowSessionKey = "ITEM_GLOW_ONCE_RUN_" + runId;
        if (ids.isEmpty()) {
            res.put("result", "empty");
            return ResponseEntity.ok(res);
        }
        List<Long> limitedItemIds = ids.stream().distinct().limit(6).toList();
        List<MyItemDto> newItems = marketService.getMyItemsByIds(lm.mno(), limitedItemIds);
        @SuppressWarnings("unchecked")
        List<MyItemDto> existingAppliedItems = (List<MyItemDto>) session.getAttribute(appliedItemSessionKey);
        if (existingAppliedItems == null) existingAppliedItems = new ArrayList<>();
        else existingAppliedItems = new ArrayList<>(existingAppliedItems);
        int remain = Math.max(0, 6 - existingAppliedItems.size());
        if (remain <= 0) {
            res.put("result", "limit");
            return ResponseEntity.ok(res);
        }
        if (newItems.size() > remain) newItems = new ArrayList<>(newItems.subList(0, remain));
        existingAppliedItems.addAll(newItems);
        session.setAttribute(appliedItemSessionKey, existingAppliedItems);
        session.setAttribute("LATEST_APPLIED_ITEMS_RUN_" + runId, newItems);
        session.setAttribute(itemGlowSessionKey, Boolean.TRUE);
        marketService.useItems(lm.mno(), newItems.stream().map(MyItemDto::getId).toList());
        res.put("result", "success");
        res.put("appliedCount", existingAppliedItems.size());
        res.put("latestItemNames", newItems.stream().map(MyItemDto::getItemName).toList());
        res.put("items", marketService.getMyItems(lm.mno()));
        res.put("currentCoin", marketService.getCurrentCoin(lm.mno()));
        return ResponseEntity.ok(res);
    }

    // 데뷔 엔딩 화면 (FINISHED 상태일 때)
    @GetMapping("/run/{runId}/ending")
    public String ending(@PathVariable(name = "runId") Long runId, Model model, HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        GameRun runCheck = gameRunRepository.findById(runId).orElse(null);
        if (runCheck == null) {
            return "redirect:/main?openGameModal=1";
        }
        if (!isRunAccessible(runCheck, lm)) {
            return loginRedirectForPath("/game/run/" + runId + "/ending");
        }
        if (lm != null && lm.mno() != null) {
            gameService.ensurePlayerMnoIfMissing(runId, lm.mno());
        }

        GameRun runBeforeFinish = gameRunRepository.findById(runId).orElse(null);
        String phaseBeforeEnding = runBeforeFinish != null ? runBeforeFinish.getPhase() : null;

        gameService.ensureRunFinishedForEnding(runId);

        GameRunResult result = gameService.getRunResult(runId);
        ChemistryResult chemistry = chemistryService.analyze(result.roster());
        var logs = gameService.getTurnLogs(runId);

        int effectiveTurn = gameService.resolveEffectiveTurnForScoring(runId, phaseBeforeEnding);

        EndingResult ending = endingService.calculate(
                runId,
                result.groupType(),
                result.roster(),
                chemistry,
                logs,
                result.phase(),
                effectiveTurn);

        GameRun gameRun = gameRunRepository.findById(runId).orElse(null);
        int rewardFanTotal = gameRun != null ? Math.max(0, gameRun.getTotalFans()) : 0;
        /** {@link MemberService#addFan} / 엔딩 지급과 동일: ⌊팬÷10⌋ */
        int rewardExpFromFans = MemberRank.fanToRankExpDelta(rewardFanTotal);
        int gainedFans = rewardFanTotal;
        int gainedExp = 0;

        List<GameRun> finishedRuns = gameService.getFinishedRuns();
        var scored = finishedRuns.stream()
                .map(run -> Map.entry(run, gameService.getRankingScore(run.getRunId())))
                .sorted((a, b) -> Integer.compare(b.getValue(), a.getValue()))
                .toList();

        int topScore = 0;
        if (!scored.isEmpty()) {
            Integer v = scored.get(0).getValue();
            topScore = (v == null) ? 0 : v;
        }

        int myScore = gameService.getRankingScore(runId);
        Integer myRank = null;
        for (int i = 0; i < scored.size(); i++) {
            if (scored.get(i).getKey().getRunId().equals(runId)) {
                myRank = i + 1;
                break;
            }
        }

        MemberRankReward mr = ending.getMemberRankReward();
        if (mr != null) {
            gainedExp = Math.max(0, mr.getRankExpDelta());
        }

        model.addAttribute("ending", ending);
        model.addAttribute("chemistry", chemistry);

        @SuppressWarnings("unchecked")
        List<MyItemDto> endingSessionItems =
                (List<MyItemDto>) session.getAttribute("APPLIED_ITEMS_RUN_" + runId);
        List<MyItemDto> endingAppliedItems = endingSessionItems != null ? endingSessionItems : List.of();
        Map<String, Integer> endingItemStatBonusMap = createEmptyItemStatBonusMap();
        for (MyItemDto item : endingAppliedItems) {
            if (item == null || item.getItemName() == null) {
                continue;
            }
            String statKey = getItemStatKey(item.getItemName());
            int bonus = getItemStartBonus(item.getItemName());
            if (statKey != null && bonus > 0) {
                endingItemStatBonusMap.put(statKey, endingItemStatBonusMap.getOrDefault(statKey, 0) + bonus);
            }
        }
        Set<Long> endingEliminatedTraineeIds = copyEliminatedTraineeIds(session, runId);
        List<RosterItem> rosterItemsDisplay = ending.getRoster() == null ? List.of()
                : ending.getRoster().stream()
                        .map(m -> applyItemBonusToRosterItem(m, endingItemStatBonusMap, endingEliminatedTraineeIds))
                        .toList();

        List<RosterItem> endingTopFour = rosterItemsDisplay.isEmpty() ? List.of()
                : rosterItemsDisplay.stream()
                        .sorted(Comparator.comparingInt(
                                (RosterItem r) -> r.vocal() + r.dance() + r.star() + r.mental() + r.teamwork())
                                .reversed())
                        .limit(4)
                        .toList();
        model.addAttribute("endingTopFour", endingTopFour);

        int rosterN = rosterItemsDisplay.size();
        if (rosterN > 0) {
            model.addAttribute("teamAvgVocal",
                    rosterItemsDisplay.stream().mapToInt(RosterItem::vocal).average().orElse(0));
            model.addAttribute("teamAvgDance",
                    rosterItemsDisplay.stream().mapToInt(RosterItem::dance).average().orElse(0));
            model.addAttribute("teamAvgStar",
                    rosterItemsDisplay.stream().mapToInt(RosterItem::star).average().orElse(0));
            model.addAttribute("teamAvgMental",
                    rosterItemsDisplay.stream().mapToInt(RosterItem::mental).average().orElse(0));
            model.addAttribute("teamAvgTeamwork",
                    rosterItemsDisplay.stream().mapToInt(RosterItem::teamwork).average().orElse(0));
        } else {
            model.addAttribute("teamAvgVocal", 0.0);
            model.addAttribute("teamAvgDance", 0.0);
            model.addAttribute("teamAvgStar", 0.0);
            model.addAttribute("teamAvgMental", 0.0);
            model.addAttribute("teamAvgTeamwork", 0.0);
        }

        Object[] globalRow = traineeRepository.averageAbilityStats();
        double gV = 10.0;
        double gD = 10.0;
        double gS = 10.0;
        double gM = 10.0;
        double gT = 10.0;
        if (globalRow != null && globalRow.length >= 5) {
            for (int i = 0; i < 5; i++) {
                if (globalRow[i] == null) {
                    continue;
                }
                double v = ((Number) globalRow[i]).doubleValue();
                switch (i) {
                    case 0 -> gV = v;
                    case 1 -> gD = v;
                    case 2 -> gS = v;
                    case 3 -> gM = v;
                    case 4 -> gT = v;
                    default -> {
                    }
                }
            }
        }
        model.addAttribute("globalAvgVocal", gV);
        model.addAttribute("globalAvgDance", gD);
        model.addAttribute("globalAvgStar", gS);
        model.addAttribute("globalAvgMental", gM);
        model.addAttribute("globalAvgTeamwork", gT);

        boolean endingLikeLoggedIn = lm != null && lm.mno() != null;
        model.addAttribute("endingLikeLoggedIn", endingLikeLoggedIn);
        List<Long> endingTopTraineeIds = endingTopFour.stream().map(RosterItem::traineeId).filter(Objects::nonNull).toList();
        Map<Long, Long> endingLikeCounts = traineeLikeService.countByTraineeIds(endingTopTraineeIds);
        model.addAttribute("endingLikeCounts", endingLikeCounts);
        Map<Long, String> endingLikeLabels = new HashMap<>();
        for (Long tid : endingTopTraineeIds) {
            endingLikeLabels.put(tid, LikeCountFormat.compact(endingLikeCounts.getOrDefault(tid, 0L)));
        }
        model.addAttribute("endingLikeLabels", endingLikeLabels);
        if (endingLikeLoggedIn && !endingTopFour.isEmpty()) {
            model.addAttribute("endingLikedTraineeIds",
                    traineeLikeService.likedTraineeIdsInRun(lm.mno(), endingTopTraineeIds, runId));
        } else {
            model.addAttribute("endingLikedTraineeIds", Set.of());
        }

        model.addAttribute("myScore", myScore);
        model.addAttribute("myRank", myRank == null ? 0 : myRank);
        model.addAttribute("topScore", topScore);
        model.addAttribute("runId", runId);

        model.addAttribute("rewardFanTotal", rewardFanTotal);
        model.addAttribute("rewardExpFromFans", rewardExpFromFans);
        model.addAttribute("gainedFans", gainedFans);
        model.addAttribute("gainedExp", gainedExp);

        if (mr != null && mr.isEligible() && mr.getRankExpDelta() > 0 && !mr.isAlreadyApplied()) {
            int before = mr.getRankExpBefore();
            int after = mr.getRankExpAfter();
            MemberRank.NextTierProgress pb = MemberRank.nextTierProgress(before);
            MemberRank.NextTierProgress pa = MemberRank.nextTierProgress(after);
            model.addAttribute("navRankGainAnim", Boolean.TRUE);
            model.addAttribute("navRankBarFromPct", pb.barPercent());
            model.addAttribute("navRankBarToPct", pa.barPercent());
            model.addAttribute("navRankExpFrom", before);
            model.addAttribute("navRankExpTo", after);
            model.addAttribute("navRankExpDeltaUi", mr.getRankExpDelta());
        }

        /*
         * MemberRankModelAdvice는 핸들러보다 먼저 실행되어, 엔딩에서 방금 반영된 rankExp보다
         * 한 단계 이전 값이 모델에 남는다. 상단 네비 경험치 바/메타는 DB 기준 최신으로 맞춘다.
         */
        if (lm != null && lm.mno() != null) {
            memberRepository.findById(lm.mno()).ifPresent(m -> {
                MemberRank rank = MemberRank.getRankByExp(m.getRankExp());
                MemberRank.NextTierProgress prog = MemberRank.nextTierProgress(m.getRankExp());
                model.addAttribute("memberRankCode", rank.name());
                model.addAttribute("memberRankLabel", rank.displayName());
                model.addAttribute("memberRankExp", m.getRankExp());
                model.addAttribute("memberRankBarPercent", prog.barPercent());
                model.addAttribute("memberRankExpUntilNext", prog.expUntilNext());
                model.addAttribute("memberRankMaxTier", prog.maxTier());
                model.addAttribute("memberRankNextLabel", prog.nextTierLabel());
            });
        }

        return "game/ending";
    }

    // 게임 시작 화면 (현재 phase의 씬+선택지도 DB에서 로드)
    @GetMapping("/run/{runId}/start")
    public String gameStart(@PathVariable(name = "runId") Long runId,
                            @RequestParam(name = "itemIds", required = false) List<Long> itemIds,
                            @RequestParam(name = "eliminatedTids", required = false) String eliminatedTids,
                            Model model,
                            HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (lm != null && lm.mno() != null) {
            gameService.ensurePlayerMnoIfMissing(runId, lm.mno());
        }
        String appliedItemSessionKey = "APPLIED_ITEMS_RUN_" + runId;
        String itemGlowSessionKey = "ITEM_GLOW_ONCE_RUN_" + runId;

        mergeEliminatedTidsIntoSession(session, runId, eliminatedTids);

        if (lm != null && itemIds != null && !itemIds.isEmpty()) {
            List<Long> limitedItemIds = itemIds.stream().limit(6).toList();
            List<MyItemDto> newItems = marketService.getMyItemsByIds(lm.mno(), limitedItemIds);

            @SuppressWarnings("unchecked")
            List<MyItemDto> existingAppliedItems =
                    (List<MyItemDto>) session.getAttribute(appliedItemSessionKey);

            if (existingAppliedItems == null) {
                existingAppliedItems = new ArrayList<>();
            } else {
                existingAppliedItems = new ArrayList<>(existingAppliedItems);
            }

            existingAppliedItems.addAll(newItems);

            if (existingAppliedItems.size() > 6) {
                existingAppliedItems = new ArrayList<>(existingAppliedItems.subList(0, 6));
            }

            session.setAttribute(appliedItemSessionKey, existingAppliedItems);
            session.setAttribute("LATEST_APPLIED_ITEMS_RUN_" + runId, newItems);
            session.setAttribute(itemGlowSessionKey, Boolean.TRUE);

            marketService.useItems(lm.mno(), limitedItemIds);
            return "redirect:/game/run/" + runId + "/start";
        }

        @SuppressWarnings("unchecked")
        List<MyItemDto> sessionItems = (List<MyItemDto>) session.getAttribute(appliedItemSessionKey);
        List<MyItemDto> appliedItemsBase = (sessionItems != null) ? sessionItems : new ArrayList<>();

        Boolean itemGlowOnce = (Boolean) session.getAttribute(itemGlowSessionKey);
        boolean itemGlowEnabled = Boolean.TRUE.equals(itemGlowOnce);
        if (itemGlowEnabled) {
            session.setAttribute(itemGlowSessionKey, Boolean.FALSE);
        }

        GameRunResult baseResult = gameService.getRunResult(runId);
        if ("FINISHED".equals(baseResult.phase())) {
            return "redirect:/game/run/" + runId + "/ending";
        }
        GameRun run = gameRunRepository.findById(runId).orElse(null);
        if (run == null) {
            return "redirect:/main?openGameModal=1";
        }
        if (!isRunAccessible(run, lm)) {
            return loginRedirectForPath("/game/run/" + runId + "/start");
        }

        final List<MyItemDto> appliedItems = appliedItemsBase.stream()
                .filter(item -> item != null && item.getItemName() != null)
                .toList();
        model.addAttribute("appliedItems", appliedItems);

        Map<String, Integer> itemStatBonusMap = createEmptyItemStatBonusMap();
        for (MyItemDto item : appliedItems) {
            String statKey = getItemStatKey(item.getItemName());
            int bonus = getItemStartBonus(item.getItemName());
            if (statKey != null && bonus > 0) {
                itemStatBonusMap.put(statKey, itemStatBonusMap.getOrDefault(statKey, 0) + bonus);
            }
        }

        @SuppressWarnings("unchecked")
        List<MyItemDto> latestAppliedItems =
                (List<MyItemDto>) session.getAttribute("LATEST_APPLIED_ITEMS_RUN_" + runId);
        if (latestAppliedItems == null) {
            latestAppliedItems = List.of();
        }

        Map<String, Integer> latestItemStatBonusMap = createEmptyItemStatBonusMap();
        for (MyItemDto item : latestAppliedItems) {
            String statKey = getItemStatKey(item.getItemName());
            int bonus = getItemStartBonus(item.getItemName());
            if (statKey != null && bonus > 0) {
                latestItemStatBonusMap.put(statKey, latestItemStatBonusMap.getOrDefault(statKey, 0) + bonus);
            }
        }

        List<String> activeItemStatKeys = itemStatBonusMap.entrySet().stream()
                .filter(e -> e.getValue() != null && e.getValue() > 0)
                .map(Map.Entry::getKey)
                .toList();

        List<String> latestActiveItemStatKeys = latestItemStatBonusMap.entrySet().stream()
                .filter(e -> e.getValue() != null && e.getValue() > 0)
                .map(Map.Entry::getKey)
                .toList();

        Set<Long> eliminatedTraineeIds = copyEliminatedTraineeIds(session, runId);

        List<RosterItem> boostedRoster = baseResult.roster().stream()
                .map(m -> applyItemBonusToRosterItem(m, itemStatBonusMap, eliminatedTraineeIds))
                .toList();

        GameRunResult result = new GameRunResult(
                baseResult.runId(),
                baseResult.groupType(),
                boostedRoster,
                baseResult.confirmed(),
                baseResult.phase()
        );

        model.addAttribute("result", result);
        model.addAttribute("eliminatedTraineeIds", eliminatedTraineeIds);
        model.addAttribute("activeItemStatKeys", activeItemStatKeys);
        model.addAttribute("activeItemStatKeysCsv", String.join(",", activeItemStatKeys));
        model.addAttribute("latestActiveItemStatKeysCsv", String.join(",", latestActiveItemStatKeys));
        model.addAttribute("itemGlowEnabled", itemGlowEnabled);
        model.addAttribute("itemStatBonusMap", itemStatBonusMap);
        model.addAttribute("latestItemStatBonusMap", latestItemStatBonusMap);
        model.addAttribute("runId", runId);
        int teamTotal = result.roster().stream()
                .mapToInt(m -> m.vocal() + m.dance() + m.star() + m.mental() + m.teamwork())
                .sum();
        model.addAttribute("teamTotal", teamTotal);
        model.addAttribute("chemistry", chemistryService.analyze(result.roster()));
        model.addAttribute("totalFans", run != null ? run.getTotalFans() : 0);
        model.addAttribute("coreFans", run != null ? run.getCoreFans() : 0);
        model.addAttribute("casualFans", run != null ? run.getCasualFans() : 0);
        model.addAttribute("lightFans", run != null ? run.getLightFans() : 0);
        int currentCoin = (lm == null) ? 0 : marketService.getCurrentCoin(lm.mno());
        model.addAttribute("currentCoin", currentCoin);
        List<MyItemDto> myItems = (lm == null) ? List.of() : marketService.getMyItems(lm.mno());
        model.addAttribute("myItems", myItems);

        if ("MID_EVAL".equals(result.phase())) {
            return "redirect:/game/run/" + runId + "/eval/mid";
        }

        int dayNum = 1;
        boolean isMorning = true;
        boolean isDebutEval = false;
        try {
            String p = result.phase();
            if ("DEBUT_EVAL".equals(p)) {
                isDebutEval = true;
                dayNum = 84;
                isMorning = false;
            } else if (p != null && p.startsWith("DAY")) {
                int us = p.indexOf('_');
                if (us > 3) {
                    dayNum = Integer.parseInt(p.substring(3, us));
                    String part = p.substring(us + 1);
                    isMorning = "MORNING".equals(part);
                }
            }
        } catch (Exception ignored) {}
        if (dayNum < 1) dayNum = 1;
        if (dayNum > 84) dayNum = 84;

        int monthNum = ((dayNum - 1) / 28) + 1;
        int monthProgressPct = ((dayNum - 1) * 100) / 83;
        int dayInMonth = ((dayNum - 1) % 28) + 1;
        int weekNum = ((dayNum - 1) / 7) + 1;
        int dayInWeek = ((dayNum - 1) % 7) + 1;
        int weekInMonth = ((dayInMonth - 1) / 7) + 1;

        model.addAttribute("monthNum", monthNum);
        model.addAttribute("monthProgressPct", monthProgressPct);
        model.addAttribute("dayInMonth", dayInMonth);
        model.addAttribute("weekInMonth", weekInMonth);
        model.addAttribute("weekNum", weekNum);
        model.addAttribute("dayInWeek", dayInWeek);

        LocalDate scheduleDate = TRAINING_CALENDAR_START.plusDays(dayNum - 1L);
        String weekDayName = koreanDayOfWeek(scheduleDate.getDayOfWeek());
        model.addAttribute("weekDayName", weekDayName);
        String scheduleDatePretty =
                scheduleDate.format(DateTimeFormatter.ofPattern("yyyy년 M월 d일", Locale.KOREA));
        model.addAttribute("scheduleDatePretty", scheduleDatePretty);

        String scheduleTimeLabel = randomScheduleTimeLabel(runId, dayNum, isMorning);
        model.addAttribute("scheduleTimeLabel", scheduleTimeLabel);
        model.addAttribute("timeLabel", scheduleTimeLabel);

        int planDayReverse = TRAINING_PLAN_TOTAL_DAYS - dayNum + 1;
        model.addAttribute("planDayReverse", planDayReverse);
        model.addAttribute("myLiveRank", calculateLiveRank(runId));
        model.addAttribute("isDebutEval", isDebutEval);

        if (!"FINISHED".equals(result.phase())) {
            SceneResult scene = gameService.getScene(runId, result.phase());
            model.addAttribute("scene", scene);
            List<GameMiniQuiz> enabledQuizPool = gameMiniQuizRepository.findByEnabledTrueOrderBySortOrderAscIdAsc();
            if (enabledQuizPool == null || enabledQuizPool.isEmpty()) {
                enabledQuizPool = gameMiniQuizRepository.findAllByOrderBySortOrderAscIdAsc();
            }
            model.addAttribute("miniGameQuizPoolJson", toMiniQuizPoolJson(enabledQuizPool));
            IdolDialogueBlock introDialogue = gameAiNarrationService
                    .tryIntroDialogue(runId, scene.getSceneId(), result.roster(), scene.getTitle(),
                            scene.getDescription(), new HashSet<>(eliminatedTraineeIds))
                    .orElse(new IdolDialogueBlock(
                            "인트로를 준비하지 못했습니다. 로스터가 비어 있거나 잠시 오류입니다. 새로고침해 보세요.",
                            List.of()));
            model.addAttribute("introDialogue", introDialogue);
        }
        return "game/gamestart";
    }

    /**
     * 풀 페이지 리로드 없이 다음 씬 상태를 JSON으로 받을 때 사용 (goNext SPA 갱신).
     */
    @GetMapping("/run/{runId}/play-state")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> playState(
            @PathVariable(name = "runId") Long runId,
            @RequestParam(name = "eliminatedTids", required = false) String eliminatedTids,
            @RequestParam(name = "skipIntroDialogue", defaultValue = "false") boolean skipIntroDialogue,
            HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        GameRun run = gameRunRepository.findById(runId).orElse(null);
        if (run == null) {
            Map<String, Object> deny = new LinkedHashMap<>();
            deny.put("ok", false);
            deny.put("redirect", "/main?openGameModal=1");
            return ResponseEntity.ok(deny);
        }
        if (!isRunAccessible(run, lm)) {
            Map<String, Object> deny = new LinkedHashMap<>();
            deny.put("ok", false);
            try {
                deny.put("redirect", "/login?redirect="
                        + URLEncoder.encode("/game/run/" + runId + "/start", StandardCharsets.UTF_8));
            } catch (Exception e) {
                deny.put("redirect", "/login");
            }
            return ResponseEntity.ok(deny);
        }
        if (lm != null && lm.mno() != null) {
            gameService.ensurePlayerMnoIfMissing(runId, lm.mno());
        }
        mergeEliminatedTidsIntoSession(session, runId, eliminatedTids);
        Map<String, Object> body = buildPlayStateMap(runId, session, lm, skipIntroDialogue);
        return ResponseEntity.ok(body);
    }

    /**
     * {@link #gameStart}와 동일한 데이터를 Map으로 구성 (뷰 없음).
     *
     * @param skipIntroDialogue true면 인트로 지문을 만들지 않음. gamestart.jsp에 이미 그려진 뒤 goNext로 호출할 때
     *                          Gemini/폴백을 한 번 더 타지 않게 한다.
     */
    private Map<String, Object> buildPlayStateMap(Long runId, HttpSession session, LoginMember lm,
            boolean skipIntroDialogue) {
        String appliedItemSessionKey = "APPLIED_ITEMS_RUN_" + runId;
        String itemGlowSessionKey = "ITEM_GLOW_ONCE_RUN_" + runId;

        @SuppressWarnings("unchecked")
        List<MyItemDto> sessionItems = (List<MyItemDto>) session.getAttribute(appliedItemSessionKey);
        List<MyItemDto> appliedItemsBase = (sessionItems != null) ? sessionItems : new ArrayList<>();

        Boolean itemGlowOnce = (Boolean) session.getAttribute(itemGlowSessionKey);
        boolean itemGlowEnabled = Boolean.TRUE.equals(itemGlowOnce);
        if (itemGlowEnabled) {
            session.setAttribute(itemGlowSessionKey, Boolean.FALSE);
        }

        GameRunResult baseResult = gameService.getRunResult(runId);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("ok", true);

        if ("FINISHED".equals(baseResult.phase())) {
            out.put("redirect", "/game/run/" + runId + "/ending");
            return out;
        }
        GameRun run = gameRunRepository.findById(runId).orElse(null);

        final List<MyItemDto> appliedItems = appliedItemsBase.stream()
                .filter(item -> item != null && item.getItemName() != null)
                .toList();

        Map<String, Integer> itemStatBonusMap = createEmptyItemStatBonusMap();
        for (MyItemDto item : appliedItems) {
            String statKey = getItemStatKey(item.getItemName());
            int bonus = getItemStartBonus(item.getItemName());
            if (statKey != null && bonus > 0) {
                itemStatBonusMap.put(statKey, itemStatBonusMap.getOrDefault(statKey, 0) + bonus);
            }
        }

        Set<Long> eliminatedTraineeIds = copyEliminatedTraineeIds(session, runId);

        List<RosterItem> boostedRoster = baseResult.roster().stream()
                .map(m -> applyItemBonusToRosterItem(m, itemStatBonusMap, eliminatedTraineeIds))
                .toList();

        GameRunResult result = new GameRunResult(
                baseResult.runId(),
                baseResult.groupType(),
                boostedRoster,
                baseResult.confirmed(),
                baseResult.phase());

        if ("MID_EVAL".equals(result.phase())) {
            out.put("redirect", "/game/run/" + runId + "/eval/mid");
            return out;
        }

        int teamTotal = result.roster().stream()
                .mapToInt(m -> m.vocal() + m.dance() + m.star() + m.mental() + m.teamwork())
                .sum();
        ChemistryResult chemistry = chemistryService.analyze(result.roster());

        int dayNum = 1;
        boolean isMorning = true;
        boolean isDebutEval = false;
        try {
            String p = result.phase();
            if ("DEBUT_EVAL".equals(p)) {
                isDebutEval = true;
                dayNum = 84;
                isMorning = false;
            } else if (p != null && p.startsWith("DAY")) {
                int us = p.indexOf('_');
                if (us > 3) {
                    dayNum = Integer.parseInt(p.substring(3, us));
                    String part = p.substring(us + 1);
                    isMorning = "MORNING".equals(part);
                }
            }
        } catch (Exception ignored) {
        }
        if (dayNum < 1) {
            dayNum = 1;
        }
        if (dayNum > 84) {
            dayNum = 84;
        }

        int monthNum = ((dayNum - 1) / 28) + 1;
        int monthProgressPct = ((dayNum - 1) * 100) / 83;
        int dayInMonth = ((dayNum - 1) % 28) + 1;
        int weekNum = ((dayNum - 1) / 7) + 1;
        int dayInWeek = ((dayNum - 1) % 7) + 1;
        int weekInMonth = ((dayInMonth - 1) / 7) + 1;

        LocalDate scheduleDate = TRAINING_CALENDAR_START.plusDays(dayNum - 1L);
        String weekDayName = koreanDayOfWeek(scheduleDate.getDayOfWeek());
        String scheduleDatePretty =
                scheduleDate.format(DateTimeFormatter.ofPattern("yyyy년 M월 d일", Locale.KOREA));
        String scheduleTimeLabel = randomScheduleTimeLabel(runId, dayNum, isMorning);
        int planDayReverse = TRAINING_PLAN_TOTAL_DAYS - dayNum + 1;

        String dockDateLine;
        if (isDebutEval) {
            dockDateLine = scheduleDatePretty + " · 최종 데뷔 평가 🔥 " + scheduleTimeLabel;
        } else {
            dockDateLine = scheduleDatePretty + " · " + weekDayName + " " + scheduleTimeLabel;
        }

        SceneResult scene = gameService.getScene(runId, result.phase());

        List<Long> elimList = new ArrayList<>(eliminatedTraineeIds);

        Map<String, Object> intro = new LinkedHashMap<>();
        if (skipIntroDialogue) {
            intro.put("situation", "");
            intro.put("lines", List.of());
        } else {
            IdolDialogueBlock introDialogue = gameAiNarrationService
                    .tryIntroDialogue(runId, scene.getSceneId(), result.roster(), scene.getTitle(),
                            scene.getDescription(), new HashSet<>(eliminatedTraineeIds))
                    .orElse(new IdolDialogueBlock(
                            "인트로를 준비하지 못했습니다. 로스터가 비어 있거나 잠시 오류입니다. 새로고침해 보세요.",
                            List.of()));
            intro.put("situation", introDialogue.situation());
            List<Map<String, Object>> lineMaps = new ArrayList<>();
            for (IdolChatLine line : introDialogue.lines()) {
                Map<String, Object> lineMap = new LinkedHashMap<>();
                lineMap.put("traineeId", line.traineeId());
                lineMap.put("name", line.name());
                lineMap.put("personalityLabel", line.personalityLabel());
                lineMap.put("text", line.text());
                lineMaps.add(lineMap);
            }
            intro.put("lines", lineMaps);
        }

        Map<String, Object> sceneJson = new LinkedHashMap<>();
        sceneJson.put("sceneId", scene.getSceneId());
        sceneJson.put("title", scene.getTitle());
        sceneJson.put("description", scene.getDescription());
        sceneJson.put("eventType", scene.getEventType());

        out.put("phase", result.phase());
        out.put("runId", runId);
        out.put("groupType", result.groupType());
        out.put("confirmed", result.confirmed());
        out.put("roster", result.roster());
        out.put("chemistry", chemistry);
        out.put("teamTotal", teamTotal);
        out.put("totalFans", run != null ? run.getTotalFans() : 0);
        out.put("coreFans", run != null ? run.getCoreFans() : 0);
        out.put("casualFans", run != null ? run.getCasualFans() : 0);
        out.put("lightFans", run != null ? run.getLightFans() : 0);
        out.put("monthNum", monthNum);
        out.put("monthProgressPct", monthProgressPct);
        out.put("weekNum", weekNum);
        out.put("dayInMonth", dayInMonth);
        out.put("weekInMonth", weekInMonth);
        out.put("dayInWeek", dayInWeek);
        out.put("scheduleDatePretty", scheduleDatePretty);
        out.put("scheduleTimeLabel", scheduleTimeLabel);
        out.put("weekDayName", weekDayName);
        out.put("planDayReverse", planDayReverse);
        out.put("dockDateLine", dockDateLine);
        out.put("isDebutEval", isDebutEval);
        out.put("myLiveRank", calculateLiveRank(runId));
        out.put("introDialogue", intro);
        out.put("scene", sceneJson);
        out.put("eliminatedTraineeIds", elimList);
        out.put("appliedItemCount", appliedItems.size());
        return out;
    }

    @GetMapping("/run/{runId}/eval/mid")
    public String midEval(@PathVariable(name = "runId") Long runId, Model model, HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        GameRun run = gameRunRepository.findById(runId).orElse(null);
        if (run == null) {
            return "redirect:/main?openGameModal=1";
        }
        if (!isRunAccessible(run, lm)) {
            return loginRedirectForPath("/game/run/" + runId + "/eval/mid");
        }
        GameRunResult result = gameService.getRunResult(runId);
        var logs = gameService.getTurnLogs(runId);
        int total = result.roster().stream().mapToInt(m -> m.vocal() + m.dance() + m.star() + m.mental() + m.teamwork()).sum();
        ChemistryResult chemistry = chemistryService.analyze(result.roster());

        model.addAttribute("runId", runId);
        model.addAttribute("total", total);
        model.addAttribute("chemistry", chemistry);
        model.addAttribute("logCount", logs.size());
        int from = Math.max(0, logs.size() - 20);
        model.addAttribute("recentLogs", logs.subList(from, logs.size()));
        return "game/mid-eval";
    }

    @GetMapping("/run/{runId}/eval/mid/continue")
    public String continueAfterMidEval(@PathVariable(name = "runId") Long runId, HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        GameRun run = gameRunRepository.findById(runId).orElse(null);
        if (run == null || !isRunAccessible(run, lm)) {
            return loginRedirectForPath("/game/run/" + runId + "/start");
        }
        gameService.advanceEval(runId); // MID_EVAL → DAY57_MORNING
        return "redirect:/game/run/" + runId + "/start";
    }

    @GetMapping("/run/{runId}/replay")
    public String replay(@PathVariable(name = "runId") Long runId, Model model, HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        GameRun run = gameRunRepository.findById(runId).orElse(null);
        if (run == null) {
            return "redirect:/main?openGameModal=1";
        }
        if (!isRunAccessible(run, lm)) {
            return loginRedirectForPath("/game/run/" + runId + "/replay");
        }
        GameRunResult result = gameService.getRunResult(runId);
        var logs = gameService.getTurnLogs(runId);
        int total = result.roster().stream().mapToInt(m -> m.vocal() + m.dance() + m.star() + m.mental() + m.teamwork()).sum();
        ChemistryResult chemistry = chemistryService.analyze(result.roster());

        model.addAttribute("runId", runId);
        model.addAttribute("logs", logs);
        model.addAttribute("logCount", logs.size());
        model.addAttribute("total", total);
        model.addAttribute("chemistry", chemistry);
        return "game/replay";
    }


    @GetMapping("/run/{runId}/ranking")
    public String ranking(@PathVariable(name = "runId") Long runId,
                          @RequestParam(name = "period", required = false) String periodParam,
                          @RequestParam(name = "from", required = false) String fromParam,
                          Model model,
                          HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        GameRun accessRun = gameRunRepository.findById(runId).orElse(null);
        if (accessRun == null) {
            return "redirect:/main?openGameModal=1";
        }
        if (!isRunAccessible(accessRun, lm)) {
            String q = buildRankingUrlQuery(periodParam, fromParam);
            return loginRedirectForPath("/game/run/" + runId + "/ranking" + q);
        }
        RankingPeriod period = RankingPeriod.fromParam(periodParam);
        List<GameRun> finishedRuns = gameService.getFinishedRunsForRankingPeriod(period);
        Map<Long, String> nickByMno = loadNicknameMapForRuns(finishedRuns);
        List<RankingRow> rankingRows = new ArrayList<>();

        var scored = finishedRuns.stream()
                .map(run -> Map.entry(run, gameService.getRankingScore(run.getRunId())))
                .sorted((a, b) -> Integer.compare(b.getValue(), a.getValue()))
                .toList();

        int topScore = 0;
        if (!scored.isEmpty()) {
            Integer v = scored.get(0).getValue();
            topScore = (v == null) ? 0 : v;
        }
        Integer prevScore = null;
        Integer myScore = null;
        Integer myRank = null;

        for (int i = 0; i < scored.size(); i++) {
            GameRun run = scored.get(i).getKey();
            Integer scoreObj = scored.get(i).getValue();
            int score = scoreObj == null ? 0 : scoreObj;
            int rank = i + 1;
            int gapFromTop = topScore - score;
            int gapFromPrev = prevScore == null ? 0 : prevScore - score;
            boolean me = run.getRunId().equals(runId);
            String label = buildRankingPlayerLabel(run, nickByMno);
            String playedAtLabel = formatRankingPlayedAt(run);
            var rosterStats = gameService.getRosterStatBundle(run.getRunId());
            rankingRows.add(new RankingRow(rank, run.getRunId(), label, score, gapFromTop, gapFromPrev, me,
                    playedAtLabel, rosterStats.sums(), rosterStats.rosterMemberCount()));
            if (me) { myScore = score; myRank = rank; }
            prevScore = score;
        }

        model.addAttribute("rankingRows", rankingRows.stream().limit(10).toList());
        model.addAttribute("myScore", myScore == null ? 0 : myScore);
        model.addAttribute("myRank", myRank == null ? 0 : myRank);
        model.addAttribute("myPlayedAtLabel", formatRankingPlayedAt(accessRun));
        model.addAttribute("topScore", topScore);
        model.addAttribute("runId", runId);
        model.addAttribute("rankingPeriod", switch (period) {
            case WEEK -> "week";
            case MONTH -> "month";
            default -> "all";
        });
        boolean rankingFromMain = "main".equalsIgnoreCase(fromParam);
        Object hubPending = session.getAttribute(SessionConst.RANKING_HUB_PENDING_RUN_ID);
        if (hubPending instanceof Long hubRunId) {
            session.removeAttribute(SessionConst.RANKING_HUB_PENDING_RUN_ID);
            if (hubRunId.equals(runId)) {
                rankingFromMain = true;
            }
        }
        model.addAttribute("rankingFromMain", rankingFromMain);
        return "game/ranking";
    }

    /** period·from 쿼리를 합쳐 로그인 리다이렉트·링크에 사용 */
    private String buildRankingUrlQuery(String periodParam, String fromParam) {
        List<String> parts = new ArrayList<>();
        if (periodParam != null && !periodParam.isBlank()) {
            parts.add("period=" + urlEncode(periodParam));
        }
        if ("main".equalsIgnoreCase(fromParam)) {
            parts.add("from=main");
        }
        if (parts.isEmpty()) {
            return "";
        }
        return "?" + String.join("&", parts);
    }

    private static String urlEncode(String raw) {
        if (raw == null) {
            return "";
        }
        return URLEncoder.encode(raw, StandardCharsets.UTF_8);
    }

    private Map<Long, String> loadNicknameMapForRuns(List<GameRun> runs) {
        Set<Long> mnos = new HashSet<>();
        for (GameRun run : runs) {
            if (run.getPlayerMno() != null) {
                mnos.add(run.getPlayerMno());
            }
        }
        Map<Long, String> out = new HashMap<>();
        if (mnos.isEmpty()) {
            return out;
        }
        for (Member m : memberRepository.findAllById(mnos)) {
            String nick = m.getNickname();
            if (nick != null && !nick.isBlank()) {
                out.put(m.getMno(), nick);
            }
        }
        return out;
    }

    private static String buildRankingPlayerLabel(GameRun run, Map<Long, String> nickByMno) {
        Long mno = run.getPlayerMno();
        if (mno != null) {
            String nick = nickByMno.get(mno);
            return (nick != null && !nick.isBlank()) ? nick : ("USER-" + mno);
        }
        return "RUN-" + run.getRunId();
    }

    private static String formatRankingPlayedAt(GameRun run) {
        if (run == null) {
            return "";
        }
        LocalDateTime ref = run.getFinishedAt() != null ? run.getFinishedAt() : run.getCreatedAt();
        if (ref == null) {
            return "";
        }
        return ref.format(DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm", Locale.KOREA));
    }

private String redirectToRunProgress(GameRun run, boolean explicitRequest) {
    try {
        if (run == null) return "redirect:/main?openGameModal=1";
        String phase = run.getPhase();
        if ("MID_EVAL".equals(phase)) return "redirect:/game/run/" + run.getRunId() + "/eval/mid";
        if ("FINISHED".equals(phase)) return "redirect:/game/run/" + run.getRunId() + "/ending";
        if ("DEBUT_EVAL".equals(phase) || (phase != null && phase.startsWith("DAY"))) {
            if (explicitRequest || run.isConfirmed() || !"DAY1_MORNING".equals(phase)) {
                return "redirect:/game/run/" + run.getRunId() + "/start";
            }
        }
        return "redirect:/game/run/" + run.getRunId() + "/roster";
    } catch (Exception ignored) {
        return "redirect:/main?openGameModal=1";
    }
}

/**
 * 회원에게 귀속된 런(playerMno 있음)은 해당 회원 로그인 시에만 접근.
 * 게스트 런(playerMno 없음)은 비로그인 플레이 허용.
 * 관리자(ADMIN)는 다른 회원 런(랭킹·리플레이 등) 열람을 위해 예외 허용.
 */
private boolean isRunAccessible(GameRun run, LoginMember lm) {
    if (run == null) {
        return false;
    }
    if (lm != null && lm.role() != null && "ADMIN".equalsIgnoreCase(lm.role())) {
        return true;
    }
    Long owner = run.getPlayerMno();
    if (owner == null) {
        return true;
    }
    return lm != null && lm.mno() != null && owner.equals(lm.mno());
}

private boolean canAccessRun(GameRun run, LoginMember lm) {
    return isRunAccessible(run, lm);
}

private String loginRedirectForPath(String relativePath) {
    try {
        return "redirect:/login?redirect=" + URLEncoder.encode(relativePath, StandardCharsets.UTF_8);
    } catch (Exception e) {
        return "redirect:/login";
    }
}

/** JSON 응답용 로그인 URL (프론트에서 location 이동) */
private String loginRedirectJsonPath(String relativePath) {
    try {
        return "/login?redirect=" + URLEncoder.encode(relativePath, StandardCharsets.UTF_8);
    } catch (Exception e) {
        return "/login";
    }
}

private GameRun pickBestContinueRun(List<GameRun> runs) {
    if (runs == null || runs.isEmpty()) return null;

    for (GameRun run : runs) {
        if (run == null || "FINISHED".equals(run.getPhase())) continue;
        if (run.isConfirmed()) return run;
    }
    for (GameRun run : runs) {
        if (run == null || "FINISHED".equals(run.getPhase())) continue;
        String phase = run.getPhase();
        if (phase != null && !"DAY1_MORNING".equals(phase)) return run;
    }
    for (GameRun run : runs) {
        if (run == null || "FINISHED".equals(run.getPhase())) continue;
        return run;
    }
    return null;
}

private void putRerollTiming(Map<String, Object> body, Long runId, LoginMember lm) {
        LocalDateTime now = LocalDateTime.now();

        if (lm != null && lm.mno() != null) {
            try {
                Member member = memberRepository.findById(lm.mno()).orElse(null);
                if (member != null) {
                    body.put("nextChargeInSeconds", member.getSecondsUntilNextReroll(now));
                    LocalDateTime nextAt = member.getNextRerollChargeAt(now);
                    body.put("nextChargeAt", nextAt != null ? nextAt.toString() : null);
                    return;
                }
            } catch (Exception ignored) {
            }
        }

        try {
            GameRun run = gameRunRepository.findById(runId).orElse(null);
            if (run != null) {
                body.put("nextChargeInSeconds", run.getSecondsUntilNextReroll(now));
                LocalDateTime nextAt = run.getNextRerollChargeAt(now);
                body.put("nextChargeAt", nextAt != null ? nextAt.toString() : null);
                return;
            }
        } catch (Exception ignored) {
        }

        body.put("nextChargeInSeconds", 0L);
        body.put("nextChargeAt", null);
    }

    private int getRerollRemaining(Long runId, LoginMember lm) {
        if (lm != null && lm.mno() != null) {
            try {
                Member member = memberRepository.findById(lm.mno()).orElse(null);
                if (member == null) return 0;
                boolean changed = member.rechargeRerollIfNeeded(LocalDateTime.now());
                if (changed) memberRepository.save(member);
                return member.getRerollRemaining();
            } catch (Exception ignored) {
                return 0;
            }
        }

        try {
            GameRun run = gameRunRepository.findById(runId).orElse(null);
            if (run == null) return 0;
            boolean changed = run.rechargeRerollIfNeeded(LocalDateTime.now());
            if (changed) gameRunRepository.save(run);
            return run.getRerollRemaining();
        } catch (Exception ignored) {
            return 0;
        }
    }

    private boolean consumeReroll(Long runId, LoginMember lm) {
        if (lm != null && lm.mno() != null) {
            try {
                Member member = memberRepository.findById(lm.mno()).orElse(null);
                if (member == null) return false;
                boolean ok = member.consumeReroll(LocalDateTime.now());
                if (ok) memberRepository.save(member);
                return ok;
            } catch (Exception ignored) {
                return false;
            }
        }

        try {
            GameRun run = gameRunRepository.findById(runId).orElse(null);
            if (run == null) return false;
            boolean ok = run.consumeReroll(LocalDateTime.now());
            if (ok) gameRunRepository.save(run);
            return ok;
        } catch (Exception ignored) {
            return false;
        }
    }

    /**
     * 선택지 적용 API (AJAX)
     * POST /game/run/{runId}/choice?key=A
     * → StatChangeResult JSON 반환
     */
    @ResponseBody
    @PostMapping("/run/{runId}/choice")
    public ResponseEntity<Map<String, Object>> applyChoice(
            @PathVariable(name = "runId") Long runId,
            @RequestParam(name = "key") String key,
            @RequestParam(name = "statGrowth2x", defaultValue = "false") boolean statGrowth2x,
            HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        GameRun run = gameRunRepository.findById(runId).orElse(null);
        if (run == null || !isRunAccessible(run, lm)) {
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("error", "로그인이 필요합니다.");
            err.put("redirect", loginRedirectJsonPath("/game/run/" + runId + "/start"));
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(err);
        }
        Set<Long> eliminated = new HashSet<>(copyEliminatedTraineeIds(session, runId));
        StatChangeResult result = gameService.applyChoice(runId, key, eliminated, statGrowth2x);
        return ResponseEntity.ok(statChangeResultToJson(result, runId, session));
    }

    /**
     * 채팅 입력 → 키워드 매핑 → 기존 선택 적용과 동일한 JSON.
     */
    @ResponseBody
    @PostMapping("/run/{runId}/choice/chat")
    public ResponseEntity<Map<String, Object>> applyChatChoice(
            @PathVariable(name = "runId") Long runId,
            @RequestBody(required = false) Map<String, Object> body,
            HttpSession session) {
        LoginMember lm = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        GameRun run = gameRunRepository.findById(runId).orElse(null);
        if (run == null || !isRunAccessible(run, lm)) {
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("error", "로그인이 필요합니다.");
            err.put("chatFailed", true);
            err.put("redirect", loginRedirectJsonPath("/game/run/" + runId + "/start"));
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(err);
        }
        String text = "";
        if (body != null && body.get("text") != null) {
            text = String.valueOf(body.get("text"));
        }
        boolean miniGameFailed = false;
        if (body != null && body.get("miniGameFailed") != null) {
            Object mg = body.get("miniGameFailed");
            if (mg instanceof Boolean) {
                miniGameFailed = (Boolean) mg;
            } else {
                miniGameFailed = Boolean.parseBoolean(String.valueOf(mg));
            }
        }
        Object elimChat = body != null ? body.get("eliminatedTids") : null;
        if (elimChat != null) {
            mergeEliminatedTidsIntoSession(session, runId, String.valueOf(elimChat));
        }
        boolean statGrowth2x = false;
        if (body != null && body.get("statGrowth2x") != null) {
            Object sg = body.get("statGrowth2x");
            if (sg instanceof Boolean) {
                statGrowth2x = (Boolean) sg;
            } else {
                statGrowth2x = Boolean.parseBoolean(String.valueOf(sg));
            }
        }
        Set<Long> eliminatedChat = new HashSet<>(copyEliminatedTraineeIds(session, runId));
        try {
            ChatApplyOutcome out = gameService.applyChatFromText(runId, text, miniGameFailed, eliminatedChat,
                    statGrowth2x);
            Map<String, Object> json = statChangeResultToJson(out.result(), runId, session);
            json.put("miniGameFailed", miniGameFailed);
            json.put("resolvedKey", out.resolvedKey());
            json.put("chatNoEffect", "NONE".equalsIgnoreCase(out.resolvedKey()));
            json.put("trainingCategory", out.trainingCategory());
            json.put("dialogueSituation", out.dialogueSituation());
            json.put("resultNarration", out.resultNarration());
            json.put("characterLines", idolChatLinesToJson(out.characterResponses()));
            json.put("predictedKey", out.predictedKey());
            json.put("predictionConfidence", out.predictionConfidence());
            json.put("predictionScores", out.predictionScores());
            json.put("usedFallback", out.usedFallback());
            json.put("resolverType", out.resolverType());
            if (out.miniGamePenalty() != null) {
                var p = out.miniGamePenalty();
                Map<String, Object> pen = new java.util.LinkedHashMap<>();
                pen.put("traineeId", p.traineeId());
                pen.put("traineeName", p.traineeName());
                pen.put("pickOrder", p.pickOrder());
                pen.put("statName", p.statName());
                pen.put("delta", p.delta());
                pen.put("beforeVal", p.beforeVal());
                pen.put("afterVal", p.afterVal());
                json.put("miniGamePenalty", pen);
            }
            return ResponseEntity.ok(json);
        } catch (IllegalStateException | IllegalArgumentException e) {
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("error", e.getMessage() != null ? e.getMessage() : "요청을 처리할 수 없습니다.");
            err.put("chatFailed", true);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(err);
        }
    }

    private static List<Map<String, Object>> idolChatLinesToJson(List<IdolChatLine> lines) {
        if (lines == null) {
            return List.of();
        }
        List<Map<String, Object>> list = new ArrayList<>();
        for (IdolChatLine line : lines) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("traineeId", line.traineeId());
            m.put("name", line.name());
            m.put("personality", line.personalityLabel());
            m.put("text", line.text());
            list.add(m);
        }
        return list;
    }

    private Map<String, Object> statChangeResultToJson(StatChangeResult result, Long runId, HttpSession session) {
        @SuppressWarnings("unchecked")
        List<MyItemDto> sessionItems =
                (List<MyItemDto>) session.getAttribute("APPLIED_ITEMS_RUN_" + runId);
        List<MyItemDto> appliedItems = (sessionItems != null) ? sessionItems : List.of();

        Map<String, Integer> itemStatBonusMap = createEmptyItemStatBonusMap();
        for (MyItemDto item : appliedItems) {
            if (item == null || item.getItemName() == null) {
                continue;
            }
            String statKey = getItemStatKey(item.getItemName());
            int bonus = getItemStartBonus(item.getItemName());
            if (statKey != null && bonus > 0) {
                itemStatBonusMap.put(statKey, itemStatBonusMap.getOrDefault(statKey, 0) + bonus);
            }
        }

        Set<Long> eliminatedTraineeIds = copyEliminatedTraineeIds(session, runId);
        List<RosterItem> boostedRoster = result.updatedRoster().stream()
                .map(m -> applyItemBonusToRosterItem(m, itemStatBonusMap, eliminatedTraineeIds))
                .toList();

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("traineeId", result.traineeId());
        body.put("traineeName", result.traineeName());
        body.put("statName", result.statName());
        body.put("delta", result.delta());
        body.put("beforeVal", result.beforeVal());
        body.put("afterVal", result.afterVal());
        body.put("nextPhase", result.nextPhase());
        body.put("updatedRoster", boostedRoster);
        body.put("fanDelta", result.fanDelta());
        body.put("coreFanDelta", result.coreFanDelta());
        body.put("casualFanDelta", result.casualFanDelta());
        body.put("lightFanDelta", result.lightFanDelta());
        body.put("totalFans", result.totalFans());
        body.put("coreFans", result.coreFans());
        body.put("casualFans", result.casualFans());
        body.put("lightFans", result.lightFans());
        body.put("domesticFanDelta", result.coreFanDelta());
        body.put("foreignFanDelta", result.casualFanDelta());
        body.put("domesticFans", result.coreFans());
        body.put("foreignFans", result.casualFans() + result.lightFans());
        body.put("fanReactionTitle", result.fanReactionTitle());
        body.put("fanReactionDesc", result.fanReactionDesc());
        body.put("unlockedEvent", result.unlockedEvent());
        body.put("activeStatusCode", result.activeStatusCode());
        body.put("activeStatusLabel", result.activeStatusLabel());
        body.put("activeStatusDesc", result.activeStatusDesc());
        body.put("activeStatusTurnsLeft", result.activeStatusTurnsLeft());
        body.put("statusEffectText", result.statusEffectText());
        body.put("itemStatBonusMap", itemStatBonusMap);
        body.put("chemistry", chemistryService.analyze(boostedRoster));
        return body;
    }

    private static String koreanDayOfWeek(DayOfWeek d) {
        return switch (d) {
            case MONDAY -> "월요일";
            case TUESDAY -> "화요일";
            case WEDNESDAY -> "수요일";
            case THURSDAY -> "목요일";
            case FRIDAY -> "금요일";
            case SATURDAY -> "토요일";
            case SUNDAY -> "일요일";
        };
    }

    /**
     * 같은 일차·같은 턴에서는 새로고침해도 동일한 시각이 나오도록 runId + dayNum + 아침/저녁으로 시드.
     * 아침: AM 6:00~10:55(5분 단위), 저녁: PM 19:00~22:55(5분 단위, 24시 표기).
     */
    private static String randomScheduleTimeLabel(long runId, int dayNum, boolean isMorning) {
        Random rnd = new Random(Objects.hash(runId, dayNum, isMorning));
        int minute = rnd.nextInt(12) * 5;
        if (isMorning) {
            int hour = 6 + rnd.nextInt(5);
            int h12 = hour % 12;
            if (h12 == 0) {
                h12 = 12;
            }
            return String.format("AM %d:%02d", h12, minute);
        }
        int hour = 19 + rnd.nextInt(4);
        return String.format("PM %d:%02d", hour, minute);
    }

    /**
     * 현재 run의 점수를 기준으로 "실시간 내 랭킹"을 계산한다.
     * - 기준 집합: 종료 런 점수 + 현재 런 점수
     * - 동점은 같은 순위(competition ranking)로 처리
     */
    private int calculateLiveRank(Long runId) {
        if (runId == null) {
            return 0;
        }
        int myScore = gameService.getRankingScore(runId);
        List<GameRun> finishedRuns = gameService.getFinishedRuns();
        int higher = 0;
        if (finishedRuns != null) {
            for (GameRun run : finishedRuns) {
                if (run == null || run.getRunId() == null) {
                    continue;
                }
                if (runId.equals(run.getRunId())) {
                    continue; // 현재 run은 아래에서 한 번만 반영
                }
                int score = gameService.getRankingScore(run.getRunId());
                if (score > myScore) {
                    higher++;
                }
            }
        }
        return higher + 1;
    }

    /** 인벤토리 행(id)마다 실제 적용 시작 게임 일차 — 리스트 DTO만으로는 세션 직렬화 시 날짜가 빠지는 경우가 있어 별도 보관 */




    /**
     * 적용한 날부터 게임 일(DAY 번호)이 하루 지날 때마다 보너스가 +1씩 증가.
     * 예: 7일 아이템이면 1일차 +1 … 7일차 +7(고정 +1이 아님).
     */


    private static final String ELIMINATED_TRAINEE_IDS_SESSION_PREFIX = "ELIMINATED_TRAINEE_IDS_RUN_";

    private void mergeEliminatedTidsIntoSession(HttpSession session, Long runId, String eliminatedTidsCsv) {
        if (session == null || runId == null || eliminatedTidsCsv == null || eliminatedTidsCsv.isBlank()) {
            return;
        }
        Set<Long> set = getOrCreateEliminatedSet(session, runId);
        for (Long id : parseLongCsv(eliminatedTidsCsv)) {
            if (id != null) {
                set.add(id);
            }
        }
    }

    private List<Long> parseLongCsv(String csv) {
        if (csv == null || csv.isBlank()) {
            return List.of();
        }
        List<Long> out = new ArrayList<>();
        for (String part : csv.split(",")) {
            String t = part == null ? "" : part.trim();
            if (t.isEmpty()) {
                continue;
            }
            try {
                out.add(Long.valueOf(t));
            } catch (NumberFormatException ignored) {
                // skip
            }
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    private Set<Long> getOrCreateEliminatedSet(HttpSession session, Long runId) {
        String key = ELIMINATED_TRAINEE_IDS_SESSION_PREFIX + runId;
        Set<Long> set = (Set<Long>) session.getAttribute(key);
        if (set == null) {
            set = new HashSet<>();
            session.setAttribute(key, set);
        }
        return set;
    }

    private Set<Long> copyEliminatedTraineeIds(HttpSession session, Long runId) {
        if (session == null || runId == null) {
            return Set.of();
        }
        String key = ELIMINATED_TRAINEE_IDS_SESSION_PREFIX + runId;
        @SuppressWarnings("unchecked")
        Set<Long> raw = (Set<Long>) session.getAttribute(key);
        if (raw == null || raw.isEmpty()) {
            return Set.of();
        }
        return Set.copyOf(raw);
    }

    /**
     * 탈락한 연습생에는 인벤토리 스탯 보너스를 적용하지 않는다.
     */
    private RosterItem applyItemBonusToRosterItem(RosterItem m, Map<String, Integer> itemStatBonusMap,
                                                    Set<Long> eliminatedTraineeIds) {
        if (m.traineeId() != null && eliminatedTraineeIds != null && eliminatedTraineeIds.contains(m.traineeId())) {
            return m;
        }
        return new RosterItem(
                m.traineeId(),
                m.name(),
                m.gender(),
                m.grade(),
                m.vocal() + itemStatBonusMap.getOrDefault("v", 0),
                m.dance() + itemStatBonusMap.getOrDefault("d", 0),
                m.star() + itemStatBonusMap.getOrDefault("s", 0),
                m.mental() + itemStatBonusMap.getOrDefault("m", 0),
                m.teamwork() + itemStatBonusMap.getOrDefault("t", 0),
                m.imagePath(),
                m.pickOrder(),
                m.personalityCode(),
                m.age(),
                m.statusCode(),
                m.statusLabel(),
                m.statusDesc(),
                m.statusTurnsLeft(),
                m.enhanceLevel(),
                m.photoCardGrade(),
                m.photoCardBonusPct()
        );
    }

    private Map<String, Integer> createEmptyItemStatBonusMap() {
        Map<String, Integer> map = new LinkedHashMap<>();
        map.put("v", 0);
        map.put("d", 0);
        map.put("s", 0);
        map.put("m", 0);
        map.put("t", 0);
        return map;
    }

    private String getItemStatKey(String itemName) {
        if (itemName == null) {
            return null;
        }

        return switch (itemName) {
            case "보컬 워터", "호흡 컨트롤 북" -> "v";
            case "댄스 슈즈", "퍼포먼스 밴드" -> "d";
            case "팬레터", "라이브 방송 세트" -> "s";
            case "릴렉스 캔디", "명상 키트" -> "m";
            case "팀 스낵 박스", "유닛 워크북" -> "t";
            default -> null;
        };
    }

    private int getItemStartBonus(String itemName) {
        if (itemName == null) {
            return 0;
        }

        return switch (itemName) {
            case "보컬 워터", "댄스 슈즈", "팬레터", "릴렉스 캔디", "팀 스낵 박스" -> 10;
            case "호흡 컨트롤 북", "퍼포먼스 밴드", "라이브 방송 세트", "명상 키트", "유닛 워크북" -> 20;
            default -> 0;
        };
    }

    private static String toMiniQuizPoolJson(List<GameMiniQuiz> quizList) {
        if (quizList == null || quizList.isEmpty()) {
            return "[]";
        }
        StringBuilder sb = new StringBuilder("[");
        boolean first = true;
        for (GameMiniQuiz quiz : quizList) {
            if (quiz == null) {
                continue;
            }
            String hint = quiz.getHint();
            String answer = quiz.getAnswer();
            if (hint == null || hint.isBlank() || answer == null || answer.isBlank()) {
                continue;
            }
            if (!first) {
                sb.append(',');
            }
            sb.append("{\"hint\":\"")
                    .append(escapeJsonString(hint))
                    .append("\",\"answer\":\"")
                    .append(escapeJsonString(answer))
                    .append("\"}");
            first = false;
        }
        sb.append(']');
        return sb.toString();
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

}
