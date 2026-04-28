package com.java.config;

import java.util.HashMap;
import java.util.Map;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Optional;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.DefaultOAuth2AuthorizationRequestResolver;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizationRequestResolver;
import org.springframework.security.oauth2.core.endpoint.OAuth2AuthorizationRequest;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.SecurityFilterChain;

import com.java.dto.LoginMember;
import com.java.entity.Member;
import com.java.repository.MemberRepository;
import com.java.service.MarketService;

import jakarta.servlet.http.HttpSession;

@Configuration
public class SecurityConfig {

    private final CustomOAuth2UserService customOAuth2UserService;
    private final MemberRepository memberRepository;
    private final ClientRegistrationRepository clientRegistrationRepository;
    private final MarketService marketService;

    public SecurityConfig(CustomOAuth2UserService customOAuth2UserService,
            MemberRepository memberRepository,
            ClientRegistrationRepository clientRegistrationRepository,
            MarketService marketService) {
        this.customOAuth2UserService = customOAuth2UserService;
        this.memberRepository = memberRepository;
        this.clientRegistrationRepository = clientRegistrationRepository;
        this.marketService = marketService;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
                .oauth2Login(oauth -> oauth
                        .loginPage("/login")
                        .authorizationEndpoint(auth -> auth
                                .authorizationRequestResolver(kakaoAuthorizationRequestResolver()))
                        .userInfoEndpoint(userInfo -> userInfo
                                .userService(customOAuth2UserService))
                        .successHandler((request, response, authentication) -> {
                            OAuth2User oAuth2User = (OAuth2User) authentication.getPrincipal();
                            Object mnoObj = oAuth2User.getAttribute("app_mno");
                            if (mnoObj == null) {
                                response.sendRedirect(request.getContextPath() + "/login?error=oauth");
                                return;
                            }
                            long mno = (mnoObj instanceof Number n) ? n.longValue()
                                    : Long.parseLong(String.valueOf(mnoObj));
                            Member member = memberRepository.findById(mno).orElse(null);
                            if (member == null) {
                                response.sendRedirect(request.getContextPath() + "/login?error=oauth");
                                return;
                            }
                            marketService.ensureMinimumCoin(member.getMno(), MarketService.DEFAULT_MIN_COIN);
                            HttpSession session = request.getSession(true);
                            session.setAttribute(SessionConst.LOGIN_MEMBER, new LoginMember(
                                    member.getMno(),
                                    member.getMid(),
                                    member.getMname(),
                                    member.getNickname(),
                                    member.getRole()));
                            response.sendRedirect(request.getContextPath() + "/main");
                        })
                        .failureHandler((request, response, exception) -> {
                            exception.printStackTrace();
                            String message = Optional.ofNullable(exception.getCause())
                                    .map(Throwable::getMessage)
                                    .filter(m -> m != null && !m.isBlank())
                                    .orElseGet(() -> exception.getMessage() == null
                                            ? "oauth_login_failed"
                                            : exception.getMessage());
                            String encoded = URLEncoder.encode(message, StandardCharsets.UTF_8);
                            response.sendRedirect(request.getContextPath() + "/login?error=oauth&message=" + encoded);
                        }))
                .csrf(csrf -> csrf.disable())
                .headers(headers -> headers.frameOptions(frame -> frame.sameOrigin()))
                .formLogin(form -> form.disable());

        return http.build();
    }

    @Bean
    public OAuth2AuthorizationRequestResolver kakaoAuthorizationRequestResolver() {
        DefaultOAuth2AuthorizationRequestResolver defaultResolver =
                new DefaultOAuth2AuthorizationRequestResolver(
                        clientRegistrationRepository, "/oauth2/authorization");

        return new OAuth2AuthorizationRequestResolver() {
            @Override
            public OAuth2AuthorizationRequest resolve(jakarta.servlet.http.HttpServletRequest request) {
                OAuth2AuthorizationRequest authorizationRequest = defaultResolver.resolve(request);
                return customizeKakaoRequest(authorizationRequest);
            }

            @Override
            public OAuth2AuthorizationRequest resolve(jakarta.servlet.http.HttpServletRequest request,
                    String clientRegistrationId) {
                OAuth2AuthorizationRequest authorizationRequest =
                        defaultResolver.resolve(request, clientRegistrationId);
                return customizeKakaoRequest(authorizationRequest);
            }

            private OAuth2AuthorizationRequest customizeKakaoRequest(OAuth2AuthorizationRequest authorizationRequest) {
                if (authorizationRequest == null) {
                    return null;
                }
                Object registrationId = authorizationRequest.getAttributes().get("registration_id");
                if (!"kakao".equals(registrationId)) {
                    return authorizationRequest;
                }
                Map<String, Object> extra = new HashMap<>(authorizationRequest.getAdditionalParameters());
                extra.put("prompt", "login");
                return OAuth2AuthorizationRequest.from(authorizationRequest)
                        .additionalParameters(extra)
                        .build();
            }
        };
    }
}
