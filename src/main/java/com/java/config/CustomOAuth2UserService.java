package com.java.config;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.java.entity.Member;
import com.java.repository.MemberRepository;
import com.java.service.StarterTraineeGrantService;

@Service
public class CustomOAuth2UserService implements OAuth2UserService<OAuth2UserRequest, OAuth2User> {

    private static final String NICK_REGEX = "^[A-Za-z0-9\\uAC00-\\uD7A3]{3,12}$";

    private final DefaultOAuth2UserService delegate = new DefaultOAuth2UserService();
    private final MemberRepository memberRepository;
    private final StarterTraineeGrantService starterTraineeGrantService;

    public CustomOAuth2UserService(MemberRepository memberRepository,
            StarterTraineeGrantService starterTraineeGrantService) {
        this.memberRepository = memberRepository;
        this.starterTraineeGrantService = starterTraineeGrantService;
    }

    @Override
    @Transactional
    @SuppressWarnings("unchecked")
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User loaded = delegate.loadUser(userRequest);
        String registrationId = userRequest.getClientRegistration().getRegistrationId();
        Map<String, Object> attributes = new HashMap<>(loaded.getAttributes());

        String externalId;
        String email;
        String displayName;

        if ("kakao".equals(registrationId)) {
            Map<String, Object> kakaoAccount = (Map<String, Object>) attributes.get("kakao_account");
            Map<String, Object> profile = kakaoAccount != null
                    ? (Map<String, Object>) kakaoAccount.get("profile")
                    : null;
            externalId = String.valueOf(attributes.get("id"));
            displayName = profile != null && profile.get("nickname") != null
                    ? String.valueOf(profile.get("nickname"))
                    : "kakao_" + externalId;
            email = null;
            if (kakaoAccount != null && kakaoAccount.get("email") != null) {
                email = String.valueOf(kakaoAccount.get("email"));
            }
        } else if ("google".equals(registrationId)) {
            externalId = String.valueOf(attributes.get("sub"));
            email = attributes.get("email") != null ? String.valueOf(attributes.get("email")) : null;
            displayName = attributes.get("name") != null ? String.valueOf(attributes.get("name")) : "googleUser";
        } else if ("facebook".equals(registrationId)) {
            externalId = String.valueOf(attributes.get("id"));
            email = attributes.get("email") != null ? String.valueOf(attributes.get("email")) : null;
            displayName = attributes.get("name") != null ? String.valueOf(attributes.get("name")) : "fbUser";
        } else if ("naver".equals(registrationId)) {
            Map<String, Object> response = (Map<String, Object>) attributes.get("response");
            if (response == null) {
                throw new OAuth2AuthenticationException(new OAuth2Error("invalid_user_info"),
                        "Naver user-info: missing response");
            }
            externalId = String.valueOf(response.get("id"));
            email = response.get("email") != null ? String.valueOf(response.get("email")) : null;
            displayName = response.get("name") != null ? String.valueOf(response.get("name")) : "naverUser";
        } else {
            throw new OAuth2AuthenticationException(new OAuth2Error("unsupported_registration"),
                    "Unsupported provider: " + registrationId);
        }

        if (externalId == null || externalId.isBlank() || "null".equals(externalId)) {
            throw new OAuth2AuthenticationException(new OAuth2Error("invalid_user_info"), "Missing OAuth subject id");
        }

        String mid = registrationId + "_" + externalId.replaceAll("[^A-Za-z0-9._-]", "_");
        if (mid.length() > 50) {
            mid = mid.substring(0, 50);
        }

        Member member = memberRepository.findByMid(mid).orElse(null);
        if (member == null) {
            String resolvedEmail = (email != null && !email.isBlank()) ? email.trim() : (mid + "@oauth.local");
            if (memberRepository.existsByEmail(resolvedEmail)) {
                resolvedEmail = mid + "@oauth.local";
            }
            String nickname = oauthNickname(displayName, externalId, registrationId);
            member = new Member();
            member.setMid(mid);
            member.setMpw(UUID.randomUUID().toString());
            member.setMname(displayName.length() > 50 ? displayName.substring(0, 50) : displayName);
            member.setNickname(nickname);
            member.setEmail(resolvedEmail);
            member.setRole("USER");
            member = memberRepository.save(member);
            starterTraineeGrantService.grantStarterGroupsForMember(member.getMno());
        }

        Map<String, Object> out = new HashMap<>(attributes);
        out.put("oauth_uid", member.getMid());
        out.put("app_mid", member.getMid());
        out.put("app_mno", member.getMno());
        out.put("app_nickname", member.getNickname());
        out.put("app_role", member.getRole());
        out.put("app_mname", member.getMname());

        String role = member.getRole() != null ? member.getRole() : "USER";
        return new DefaultOAuth2User(
                List.of(new SimpleGrantedAuthority("ROLE_" + role)),
                out,
                "oauth_uid");
    }

    private String oauthNickname(String displayName, String externalId, String registrationId) {
        String cand = displayName == null ? "" : displayName.replaceAll("\\s+", "");
        if (cand.length() > 12) {
            cand = cand.substring(0, 12);
        }
        if (cand.length() >= 3 && cand.matches(NICK_REGEX) && !memberRepository.existsByNickname(cand)) {
            return cand;
        }
        String digits = externalId.replaceAll("\\D", "");
        if (digits.length() > 6) {
            digits = digits.substring(digits.length() - 6);
        }
        String prefix = registrationId.length() >= 2 ? registrationId.substring(0, 2) : "ou";
        String base = (prefix + digits).toLowerCase();
        if (base.length() < 3) {
            base = base + "usr";
        }
        if (base.length() > 12) {
            base = base.substring(0, 12);
        }
        String n = base;
        int i = 0;
        while (memberRepository.existsByNickname(n)) {
            String suffix = String.valueOf(i++);
            n = base.substring(0, Math.min(12 - suffix.length(), base.length())) + suffix;
            if (n.length() < 3) {
                n = base + "x";
            }
        }
        return n;
    }
}
