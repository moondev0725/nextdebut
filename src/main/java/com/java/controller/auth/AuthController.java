package com.java.controller.auth;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import org.springframework.util.StringUtils;

import com.java.config.SessionConst;
import com.java.dto.LoginMember;
import com.java.dto.MyItemDto;
import com.java.entity.Board;
import com.java.entity.Member;
import com.java.entity.MyTrainee;
import com.java.game.entity.Trainee;
import com.java.game.repository.TraineeRepository;
import com.java.game.service.GameRunResult;
import com.java.game.service.GameService;
import com.java.repository.MyTraineeRepository;
import com.java.service.AuthService;
import com.java.service.MarketService;
import com.java.repository.BoardRepository;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@Controller
public class AuthController {

    private final AuthService authService;
    private final GameService gameService;
    private final MarketService marketService;
    private final BoardRepository boardRepository;
    private final MyTraineeRepository myTraineeRepository;
    private final TraineeRepository traineeRepository;

    public AuthController(AuthService authService, GameService gameService, MarketService marketService,
                           BoardRepository boardRepository, MyTraineeRepository myTraineeRepository,
                           TraineeRepository traineeRepository) {
        this.authService = authService;
        this.gameService = gameService;
        this.marketService = marketService;
        this.boardRepository = boardRepository;
        this.myTraineeRepository = myTraineeRepository;
        this.traineeRepository = traineeRepository;
    }

    @ResponseBody
    @PostMapping("/api/auth/send-email-code")
    public ResponseEntity<Map<String, Object>> sendEmailCode(@RequestParam("email") String email) {
        try {
            authService.sendEmailCode(email);
            return ResponseEntity.ok(Map.of("sent", true));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("sent", false, "message", e.getMessage()));
        }
    }

    @ResponseBody
    @PostMapping("/api/auth/verify-email-code")
    public ResponseEntity<Map<String, Object>> verifyEmailCode(
            @RequestParam("email") String email,
            @RequestParam("code") String code) {
        try {
            boolean ok = authService.verifyEmailCode(email, code);
            return ResponseEntity.ok(Map.of("verified", ok));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.ok(Map.of("verified", false, "message", e.getMessage()));
        }
    }

    @ResponseBody
    @GetMapping("/api/auth/check-mid")
    public ResponseEntity<Map<String, Object>> checkMid(@RequestParam("mid") String mid) {
        return ResponseEntity.ok(Map.of("available", authService.isMidAvailable(mid)));
    }

    @ResponseBody
    @GetMapping("/api/auth/check-nickname")
    public ResponseEntity<Map<String, Object>> checkNickname(@RequestParam("nickname") String nickname) {
        return ResponseEntity.ok(Map.of("available", authService.isNicknameAvailable(nickname)));
    }

    @GetMapping("/signup")
    public String signupSelect() {
        return "auth/signup-select";
    }

    @GetMapping("/signup/form")
    public String signupForm() {
        return "auth/signup";
    }

    @PostMapping("/signup")
    public String signup(
            @RequestParam("username") String username,
            @RequestParam("password1") String password1,
            @RequestParam("password2") String password2,
            @RequestParam("real_name") String realName,
            @RequestParam("nickname") String nickname,
            @RequestParam("email") String email,
            @RequestParam("jumin") String jumin,
            @RequestParam(value = "phone", required = false) String phone,
            @RequestParam("address") String address,
            @RequestParam(value = "address_detail", required = false) String addressDetail,
            HttpServletRequest request,
            RedirectAttributes ra) {
        try {
            if (password1 == null || !password1.equals(password2)) {
                throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
            }
            Member member = authService.signup(new AuthService.SignupRequest(
                    username,
                    password1,
                    realName,
                    nickname,
                    email,
                    phone,
                    address,
                    addressDetail,
                    jumin));

            marketService.ensureMinimumCoin(member.getMno(), MarketService.DEFAULT_MIN_COIN);
            HttpSession session = request.getSession(true);
            session.setAttribute(SessionConst.LOGIN_MEMBER, new LoginMember(
                    member.getMno(),
                    member.getMid(),
                    member.getMname(),
                    member.getNickname(),
                    member.getRole()));

            ra.addFlashAttribute("toast", "회원가입이 완료되었습니다. 자동 로그인되었습니다.");
            return "redirect:/main";
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("error", e.getMessage());
            ra.addFlashAttribute("prev_username", username);
            ra.addFlashAttribute("prev_real_name", realName);
            ra.addFlashAttribute("prev_nickname", nickname);
            ra.addFlashAttribute("prev_email", email);
            ra.addFlashAttribute("prev_phone", phone);
            ra.addFlashAttribute("prev_address", address);
            ra.addFlashAttribute("prev_address_detail", addressDetail);
            return "redirect:/signup/form";
        }
    }

    @PostMapping("/login")
    public String login(
            @RequestParam("username") String username,
            @RequestParam("password") String password,
            @RequestParam(value = "redirect", required = false) String redirect,
            HttpServletRequest request,
            Model model) {
        Member member = authService.login(username, password);
        if (member == null) {
            model.addAttribute("loginError", "아이디 또는 비밀번호가 올바르지 않습니다.");
            model.addAttribute("prev_username", username);
            if (StringUtils.hasText(redirect)) {
                model.addAttribute("redirect", redirect);
            }
            return "auth/login";
        }
        if (member.isSuspendedNow()) {
            model.addAttribute("loginError", "정지된 계정입니다. 해제 예정: " + member.getSuspendedUntilStr());
            model.addAttribute("prev_username", username);
            if (StringUtils.hasText(redirect)) {
                model.addAttribute("redirect", redirect);
            }
            return "auth/login";
        }

        marketService.ensureMinimumCoin(member.getMno(), MarketService.DEFAULT_MIN_COIN);

        HttpSession session = request.getSession(true);
        session.setAttribute(SessionConst.LOGIN_MEMBER, new LoginMember(
                member.getMno(),
                member.getMid(),
                member.getMname(),
                member.getNickname(),
                member.getRole()));

        if (redirect != null && redirect.startsWith("/")) {
            return "redirect:" + redirect;
        }
        return "redirect:/main";
    }

    @PostMapping("/logout")
    public String logout(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        return "redirect:/main";
    }

    @GetMapping("/mypage")
    public String mypage(HttpSession session, Model model) {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return "redirect:/login?redirect=/mypage";
        }
        authService.syncMemberRankFromExp(loginMember.mno());

        Set<Long> ownedTraineeIds = myTraineeRepository.findByMemberIdOrderByIdDesc(loginMember.mno()).stream()
                .filter(mt -> mt.getQuantity() > 0)
                .map(MyTrainee::getTraineeId)
                .collect(Collectors.toSet());
        authService.sanitizeMypageTraineeSelections(loginMember.mno(), ownedTraineeIds);

        Member member = authService.getMember(loginMember.mno());
        model.addAttribute("member", member);

        List<Trainee> ownedForMypage = ownedTraineeIds.isEmpty() ? List.of()
                : StreamSupport.stream(traineeRepository.findAllById(ownedTraineeIds).spliterator(), false)
                        .sorted(Comparator.comparing(Trainee::getName, String.CASE_INSENSITIVE_ORDER))
                        .toList();
        model.addAttribute("ownedTraineesForMypage", ownedForMypage);
        if (member != null && !ownedTraineeIds.isEmpty()) {
            Long repId = member.getMypageRepTraineeId();
            if (repId != null && ownedTraineeIds.contains(repId)) {
                traineeRepository.findById(repId).ifPresent(t -> model.addAttribute("mypageRepTrainee", t));
            }
            Long cardId = member.getMypageCardTraineeId();
            if (cardId != null && ownedTraineeIds.contains(cardId)) {
                traineeRepository.findById(cardId).ifPresent(t -> model.addAttribute("mypageCardTrainee", t));
            }
        }

        // 2) 내 게임 기록(더보기/그래프)
        List<GameRunResult> history = gameService.getPlayerHistory(loginMember.mno());
        model.addAttribute("gameHistory", history);

        Map<String, Long> groupCounts = history == null ? Map.of()
                : history.stream().collect(Collectors.groupingBy(r -> r.groupType() == null ? "UNKNOWN" : r.groupType(), Collectors.counting()));
        String topGroupType = groupCounts.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("-");
        model.addAttribute("topGroupType", topGroupType);

        Map<String, Long> phaseCounts = history == null ? Map.of()
                : history.stream().collect(Collectors.groupingBy(r -> r.phase() == null ? "UNKNOWN" : r.phase(), Collectors.counting()));
        model.addAttribute("phaseCounts", phaseCounts);

        // 차트용 데이터 (최근 최대 10개)
        List<Long> recentRunIds = new java.util.ArrayList<>();
        List<Integer> recentRunScores = new java.util.ArrayList<>();
        List<String> recentRunPhases = new java.util.ArrayList<>();
        if (history != null) {
            for (GameRunResult run : history) {
                int runScore = 0;
                if (run.roster() != null) {
                    for (var m : run.roster()) {
                        if (m != null) {
                            runScore += m.vocal() + m.dance() + m.star() + m.mental() + m.teamwork();
                        }
                    }
                }
                recentRunIds.add(run.runId());
                recentRunScores.add(runScore);
                recentRunPhases.add(run.phase() == null ? "UNKNOWN" : run.phase());
            }
        }
        model.addAttribute("recentRunIds", recentRunIds);
        model.addAttribute("recentRunScores", recentRunScores);
        model.addAttribute("recentRunPhases", recentRunPhases);

        // 1) 상점(코인/인벤토리)
        long coin = marketService.getCurrentCoin(loginMember.mno());
        model.addAttribute("currentCoin", coin);
        List<MyItemDto> myItems = marketService.getMyItems(loginMember.mno());
        model.addAttribute("myItems", myItems);

        int myItemTotalQty = myItems == null ? 0 : myItems.stream().mapToInt(MyItemDto::getQuantity).sum();
        model.addAttribute("myItemTotalQty", myItemTotalQty);

        List<MyItemDto> myTopItems = (myItems == null) ? List.of()
                : myItems.stream()
                .sorted((a, b) -> Integer.compare(b.getQuantity(), a.getQuantity()))
                .limit(3)
                .collect(Collectors.toList());
        model.addAttribute("myTopItems", myTopItems);

        MyItemDto repItem = (myTopItems != null && !myTopItems.isEmpty()) ? myTopItems.get(0) : null;
        model.addAttribute("repItemName", repItem != null ? repItem.getItemName() : null);
        model.addAttribute("repItemEffect", repItem != null ? repItem.getItemEffect() : null);
        model.addAttribute("repItemImagePath", repItem != null ? repItem.getImagePath() : null);
        model.addAttribute("repItemQty", repItem != null ? repItem.getQuantity() : 0);

        // 4) 커뮤니티 활동(내 글)
        String myNick = member != null ? member.getNickname() : loginMember.nickname();
        List<Board> myRecentPosts = boardRepository.findTop5ByAuthorNickAndVisibleTrueOrderByCreatedAtDesc(myNick);
        model.addAttribute("myRecentPosts", myRecentPosts);

        // 5) 알림/공지(최근 공지)
        List<Board> recentNotices = boardRepository.findTop3ByBoardTypeAndVisibleTrueOrderByCreatedAtDesc("notice");
        model.addAttribute("recentNotices", recentNotices);

        return "auth/mypage";
    }

    @PostMapping("/mypage/rep-trainee")
    public String setMypageRepTrainee(
            @RequestParam(value = "traineeId", required = false) Long traineeId,
            HttpSession session,
            RedirectAttributes ra) {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return "redirect:/login?redirect=/mypage";
        }
        try {
            authService.updateMypageRepTrainee(loginMember.mno(), traineeId);
            ra.addFlashAttribute("toast", "대표 캐릭터가 저장되었습니다.");
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/mypage";
    }

    @PostMapping("/mypage/card-trainee")
    public String setMypageCardTrainee(
            @RequestParam(value = "traineeId", required = false) Long traineeId,
            HttpSession session,
            RedirectAttributes ra) {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return "redirect:/login?redirect=/mypage";
        }
        try {
            authService.updateMypageCardTrainee(loginMember.mno(), traineeId);
            ra.addFlashAttribute("toast", "프로필 카드 연습생이 저장되었습니다.");
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/mypage";
    }

    @PostMapping("/mypage/profile-image")
    public String uploadProfileImage(
            @RequestParam("file") MultipartFile file,
            HttpSession session,
            RedirectAttributes ra) throws IOException {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return "redirect:/login";
        }
        if (file == null || file.isEmpty()) {
            ra.addFlashAttribute("error", "파일을 선택해주세요.");
            return "redirect:/mypage";
        }

        String ext = StringUtils.getFilenameExtension(file.getOriginalFilename());
        String saved = UUID.randomUUID().toString().replace("-", "") + (ext == null ? "" : "." + ext);
        Path dir = Paths.get(System.getProperty("user.dir"), "uploads", "profiles");
        Files.createDirectories(dir);
        Files.copy(file.getInputStream(), dir.resolve(saved));
        authService.updateProfileImage(loginMember.mno(), saved);

        ra.addFlashAttribute("toast", "프로필 이미지가 변경되었습니다.");
        return "redirect:/mypage";
    }

    @PostMapping("/mypage/nickname")
    public String updateNickname(
            @RequestParam("nickname") String nickname,
            HttpSession session,
            RedirectAttributes ra) {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return "redirect:/login";
        }
        try {
            authService.updateNickname(loginMember.mno(), nickname);
            session.setAttribute(SessionConst.LOGIN_MEMBER,
                    new LoginMember(loginMember.mno(), loginMember.mid(), loginMember.mname(), nickname.trim(), loginMember.role()));
            ra.addFlashAttribute("toast", "닉네임이 변경되었습니다.");
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/mypage";
    }

    @PostMapping("/mypage/email")
    public String updateEmail(
            @RequestParam("currentPw") String currentPw,
            @RequestParam("newEmail") String newEmail,
            HttpSession session,
            RedirectAttributes ra) {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return "redirect:/login";
        }
        try {
            authService.updateEmail(loginMember.mno(), currentPw, newEmail);
            ra.addFlashAttribute("toast", "이메일이 변경되었습니다.");
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/mypage";
    }

    @PostMapping("/mypage/password")
    public String updatePassword(
            @RequestParam("currentPw") String currentPw,
            @RequestParam("newPw1") String newPw1,
            @RequestParam("newPw2") String newPw2,
            HttpSession session,
            RedirectAttributes ra) {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return "redirect:/login";
        }
        if (!newPw1.equals(newPw2)) {
            ra.addFlashAttribute("error", "새 비밀번호가 일치하지 않습니다.");
            return "redirect:/mypage";
        }
        try {
            authService.updatePassword(loginMember.mno(), currentPw, newPw1);
            ra.addFlashAttribute("toast", "비밀번호가 변경되었습니다.");
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/mypage";
    }

    @PostMapping("/mypage/delete")
    public String deleteMember(
            @RequestParam("password") String password,
            HttpSession session,
            RedirectAttributes ra) {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return "redirect:/login";
        }
        try {
            authService.deleteMember(loginMember.mno(), password);
            session.invalidate();
            ra.addFlashAttribute("toast", "회원탈퇴가 완료되었습니다.");
            return "redirect:/main";
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("error", e.getMessage());
            return "redirect:/mypage";
        }
    }

    @GetMapping("/profile-image/{filename}")
    @ResponseBody
    public ResponseEntity<Resource> profileImage(@PathVariable("filename") String filename) {
        if (!filename.matches("^[a-zA-Z0-9._-]+$")) {
            return ResponseEntity.badRequest().build();
        }
        Path path = Paths.get(System.getProperty("user.dir"), "uploads", "profiles", filename);
        FileSystemResource resource = new FileSystemResource(path.toFile());
        if (!resource.exists()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
                .contentType(MediaType.IMAGE_JPEG)
                .body(resource);
    }

    @PostMapping("/mypage/profile-image/ajax")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> uploadProfileImageAjax(
            @RequestParam("file") MultipartFile file,
            HttpSession session) throws IOException {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return ResponseEntity.status(401).build();
        }
        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        String ext = StringUtils.getFilenameExtension(file.getOriginalFilename());
        String saved = UUID.randomUUID().toString().replace("-", "") + (ext == null ? "" : "." + ext);
        Path dir = Paths.get(System.getProperty("user.dir"), "uploads", "profiles");
        Files.createDirectories(dir);
        Files.copy(file.getInputStream(), dir.resolve(saved));
        authService.updateProfileImage(loginMember.mno(), saved);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("storedFilename", saved);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/mypage/info")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> mypageInfo(HttpSession session) {
        LoginMember loginMember = (LoginMember) session.getAttribute(SessionConst.LOGIN_MEMBER);
        if (loginMember == null) {
            return ResponseEntity.status(401).build();
        }

        Member member = authService.getMember(loginMember.mno());
        List<GameRunResult> history = gameService.getPlayerHistory(loginMember.mno());
        long totalPlays = history.size();
        long finishedPlays = history.stream().filter(r -> "FINISHED".equals(r.phase())).count();
        List<Map<String, Object>> recentGames = history.stream()
                .limit(2)
                .map(r -> {
                    Map<String, Object> game = new LinkedHashMap<>();
                    game.put("groupType", r.groupType() != null ? r.groupType() : "UNKNOWN");
                    game.put("phase", r.phase());
                    game.put("runId", r.runId());
                    return game;
                })
                .collect(Collectors.toList());

        Map<String, Object> map = new LinkedHashMap<>();
        map.put("nickname", member != null ? member.getNickname() : loginMember.nickname());
        map.put("mid", loginMember.mid());
        map.put("email", member != null ? member.getEmail() : null);
        map.put("profileImage", member != null ? member.getProfileImage() : null);
        map.put("totalPlays", totalPlays);
        map.put("finishedPlays", finishedPlays);
        map.put("coin", member != null ? marketService.getCurrentCoin(member.getMno()) : 0);
        map.put("createdAt", member != null && member.getCreatedAt() != null ? member.getCreatedAtDay() : "-");
        map.put("recentGames", recentGames);
        return ResponseEntity.ok(map);
    }

    @GetMapping("/find-id")
    public String findIdPage() {
        return "auth/find-id";
    }

    @PostMapping("/find-id")
    public String findId(
            @RequestParam("mname") String mname,
            @RequestParam("email") String email,
            RedirectAttributes ra) {
        String mid = authService.findMid(mname, email);
        if (mid == null) {
            ra.addFlashAttribute("error", "일치하는 회원 정보가 없습니다.");
            ra.addFlashAttribute("prev_mname", mname);
            ra.addFlashAttribute("prev_email", email);
        } else {
            String masked = mid.length() > 3 ? mid.substring(0, 3) + "*".repeat(mid.length() - 3) : mid;
            ra.addFlashAttribute("foundId", masked);
        }
        return "redirect:/find-id";
    }

    @GetMapping("/find-pw")
    public String findPwPage() {
        return "auth/find-pw";
    }

    @PostMapping("/find-pw")
    public String findPw(
            @RequestParam("mid") String mid,
            @RequestParam("mname") String mname,
            @RequestParam("email") String email,
            @RequestParam("newPassword1") String newPassword1,
            @RequestParam("newPassword2") String newPassword2,
            RedirectAttributes ra) {
        if (newPassword1 == null || newPassword1.length() < 6) {
            ra.addFlashAttribute("error", "비밀번호는 6자 이상이어야 합니다.");
            ra.addFlashAttribute("prev_mid", mid);
            ra.addFlashAttribute("prev_mname", mname);
            ra.addFlashAttribute("prev_email", email);
            return "redirect:/find-pw";
        }
        if (!newPassword1.equals(newPassword2)) {
            ra.addFlashAttribute("error", "새 비밀번호가 일치하지 않습니다.");
            ra.addFlashAttribute("prev_mid", mid);
            ra.addFlashAttribute("prev_mname", mname);
            ra.addFlashAttribute("prev_email", email);
            return "redirect:/find-pw";
        }

        boolean ok = authService.resetPassword(mid, mname, email, newPassword1);
        if (!ok) {
            ra.addFlashAttribute("error", "아이디, 이름, 이메일이 일치하는 회원이 없습니다.");
            ra.addFlashAttribute("prev_mid", mid);
            ra.addFlashAttribute("prev_mname", mname);
            ra.addFlashAttribute("prev_email", email);
            return "redirect:/find-pw";
        }

        ra.addFlashAttribute("toast", "비밀번호가 변경되었습니다. 새 비밀번호로 로그인해주세요.");
        return "redirect:/login";
    }
}
