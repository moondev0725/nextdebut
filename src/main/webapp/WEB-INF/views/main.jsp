<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="loggedIn" value="${not empty sessionScope.LOGIN_MEMBER}" />
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>NEXT DEBUT</title>
  <%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
  <link rel="stylesheet" href="${ctx}/css/pages/main.css?v=main-reference-20260408u" />
  <link rel="stylesheet" href="${ctx}/css/main.css?v=main-reference-modal-20260408b" />
  <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@600;700;800;900&display=swap" rel="stylesheet">
  <style>
    body.page-main-reference {
      margin: 0;
      overflow-x: hidden;
      overflow-y: auto;
      /* 보라 그라데이션이 메인 뒤로 비치면 전체가 칙칙해 보임 → 거의 무색에 가깝게 */
      background: #fbf9fc;
      color: #3a2752;
    }
    body.page-main-reference .site-footer { display: block; }
    body.page-main-reference main.main-reference {
      padding-top: var(--nav-h, 72px);
      box-sizing: border-box;
    }
    .ref-main {
      position: relative;
      min-height: calc(100vh - 12px);
      height: auto;
      overflow: hidden;
      padding: 18px 0 18px;
    }
    .ref-main__overlay,
    .ref-main__spark {
      position: absolute;
      inset: 0;
    }
    .ref-main__bg {
      position: absolute;
      inset: 0;
      z-index: 0;
      overflow: hidden;
    }
    .ref-main__bg img {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;
      object-position: center 32%;
      display: block;
      /* 전체 화면 업스케일 시 서브픽셀 합성 안정화(선명도 본질은 원본 해상도에 좌우) */
      transform: translateZ(0);
      backface-visibility: hidden;
    }
    .ref-main__overlay {
      background: linear-gradient(180deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.08) 100%), radial-gradient(circle at center, rgba(255,255,255,0.08), rgba(255,255,255,0.02) 58%, rgba(245,233,255,0.16) 100%);
    }
    .ref-main__spark--left { background: radial-gradient(circle at 14% 48%, rgba(255,255,255,0.28), transparent 20%); }
    .ref-main__spark--right { background: radial-gradient(circle at 86% 38%, rgba(255,255,255,0.32), transparent 18%); }
    .ref-shell {
      position: relative;
      z-index: 1;
      width: min(1360px, calc(100vw - 26px));
      margin: 0 auto;
    }
    .ref-stage {
      min-height: calc(100vh - var(--nav-h, 72px) - 40px);
      height: auto;
      display: grid;
      grid-template-rows: auto auto;
      gap: 12px;
      align-content: start;
    }
    .ref-hero-card,
    .ref-quick-strip,
    .ref-panel {
      backdrop-filter: blur(18px);
      -webkit-backdrop-filter: blur(18px);
    }
    .ref-hero-card {
      position: relative;
      display: grid;
      grid-template-columns: minmax(0, 1fr) 290px;
      align-items: center;
      gap: 28px;
      padding: clamp(26px, 3vw, 38px);
      border-radius: 36px;
      background: linear-gradient(180deg, rgba(255,255,255,0.18), rgba(255,255,255,0.08));
      border: 1px solid rgba(255,255,255,0.32);
      box-shadow: inset 0 0 0 1px rgba(255,255,255,0.1), 0 28px 80px rgba(149, 110, 188, 0.22);
    }
    .ref-hero-card__center {
      text-align: center;
      padding: 18px 12px;
    }
    .ref-kicker {
      margin: 0 0 14px;
      font-family: "Orbitron", sans-serif;
      font-size: clamp(0.8rem, 1vw, 1rem);
      font-weight: 800;
      letter-spacing: 0.34em;
      color: rgba(255,255,255,0.92);
    }
    .ref-title {
      margin: 0;
      font-family: "Orbitron", sans-serif;
      font-size: clamp(3.4rem, 7.4vw, 7rem);
      line-height: 0.94;
      letter-spacing: -0.06em;
      color: #ffd2fb;
      text-shadow: 0 8px 24px rgba(231, 146, 255, 0.26), 0 1px 0 rgba(255,255,255,0.9);
    }
    .ref-subtitle {
      max-width: 720px;
      margin: 20px auto 0;
      font-size: clamp(1rem, 1.5vw, 1.35rem);
      line-height: 1.6;
      font-weight: 700;
      color: rgba(255,255,255,0.95);
    }
    .ref-actions {
      display: flex;
      justify-content: center;
      gap: 14px;
      flex-wrap: wrap;
      margin-top: 28px;
    }
    .ref-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 56px;
      padding: 0 34px;
      border-radius: 999px;
      text-decoration: none;
      font-family: "Orbitron", sans-serif;
      font-size: 0.98rem;
      font-weight: 800;
      letter-spacing: 0.12em;
    }
    .ref-btn--primary { color: #fff; background: linear-gradient(90deg, #f79fba 0%, #cb9cff 100%); }
    .ref-btn--secondary { color: #4b3b6a; background: rgba(255,255,255,0.88); }
    .ref-live-pick {
      --ref-live-pick-tilt: perspective(1600px) rotateY(-9deg) rotateX(1.1deg);
      align-self: stretch;
      border-radius: 28px;
      padding: 14px;
      background: linear-gradient(180deg, rgba(255,255,255,0.7), rgba(255,255,255,0.48));
      border: 1px solid rgba(255,255,255,0.44);
      box-shadow: 0 24px 40px rgba(183, 131, 232, 0.16);
      display: grid;
      grid-template-rows: auto auto 1fr;
      gap: 12px;
      transform-origin: right center;
      transform-style: preserve-3d;
      backface-visibility: hidden;
      transform: var(--ref-live-pick-tilt) translate3d(0, 0, 0);
    }
    .ref-live-pick__badge {
      justify-self: start;
      padding: 8px 14px;
      border-radius: 999px;
      background: linear-gradient(90deg, #f79fb7, #f5b2d6);
      color: #fff;
      font-family: "Orbitron", sans-serif;
      font-size: 0.78rem;
      font-weight: 800;
    }
    .ref-live-pick__thumb { border-radius: 22px; overflow: hidden; aspect-ratio: 0.92; background: rgba(255,255,255,0.55); }
    .ref-live-pick__thumb img { width: 100%; height: 100%; object-fit: cover; display: block; }
    .ref-live-pick__body { display: grid; gap: 10px; }
    .ref-live-pick__name { font-size: 1.55rem; font-weight: 900; color: #2f2148; }
    .ref-stat-list { display: grid; gap: 10px; }
    .ref-stat-row { display: grid; grid-template-columns: 52px minmax(0, 1fr) 32px; align-items: center; gap: 8px; font-size: 0.82rem; font-weight: 700; }
    .ref-stat-row__bar { height: 8px; border-radius: 999px; background: rgba(203, 156, 255, 0.22); overflow: hidden; }
    .ref-stat-row__bar b { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, #b883ff, #f58bb4); }
    .ref-live-pick__action { display: inline-flex; justify-content: center; align-items: center; min-height: 44px; border-radius: 999px; background: linear-gradient(90deg, #f6a7bf, #cba3ff); color: #fff; font-weight: 800; text-decoration: none; }
    .ref-live-pick__carousel { position: relative; min-width: 0; }
    .ref-live-pick__slides { position: relative; overflow: hidden; border-radius: 22px; }
    .ref-live-pick__slide { display: none; grid-template-rows: auto 1fr; gap: 10px; }
    .ref-live-pick__slide.is-active { display: grid; animation: refLivePickFade 0.5s ease; }
    @keyframes refLivePickFade { from { opacity: 0.4; } to { opacity: 1; } }
    .ref-live-pick__dots { display: flex; justify-content: center; align-items: center; gap: 4px; margin-top: 6px; flex-wrap: wrap; }
    .ref-live-pick__dot {
      box-sizing: content-box;
      width: 5px;
      height: 5px;
      border-radius: 50%;
      border: 0;
      padding: 3px;
      margin: 0;
      background: rgba(141, 104, 191, 0.35);
      background-clip: content-box;
      cursor: pointer;
      transition: transform 0.15s ease, background 0.15s ease;
    }
    .ref-live-pick__dot.is-active {
      background: linear-gradient(90deg, #f79fb7, #b883ff);
      background-clip: content-box;
      transform: scale(1.1);
    }
    .ref-live-pick__meta { font-size: 0.88rem; font-weight: 800; color: rgba(47, 33, 72, 0.88); }
    .ref-live-pick__like-pill { display: inline-flex; align-items: center; gap: 4px; font-size: 0.82rem; font-weight: 800; color: #e85a9a; }
    /* LIVE PICK 캐러셀: 장식(::after)보다 위에 두어 클릭·자동 슬라이드가 동작하도록 */
    .ref-live-pick::after { z-index: 0; }
    .ref-live-pick > .ref-live-pick__badge {
      position: relative;
      z-index: 2;
    }
    #refLivePickCarousel {
      position: relative;
      z-index: 3;
      pointer-events: auto;
    }
    #refLivePickCarousel .ref-live-pick__slides,
    #refLivePickCarousel .ref-live-pick__dots {
      position: relative;
      z-index: 1;
    }
    /* 메인 하단: TOP 랭킹·인기 게시글·인기 아이템 자동 슬라이드 */
    .ref-dashboard-carousel { position: relative; min-width: 0; }
    .ref-dashboard-carousel__slides { position: relative; overflow: hidden; border-radius: 16px; }
    .ref-dashboard-carousel__slide { display: none; text-decoration: none; color: inherit; }
    .ref-dashboard-carousel__slide.is-active { display: block; animation: refLivePickFade 0.45s ease; }
    /* 한 슬라이드에 항목 3개를 세로로 배치 */
    .ref-dashboard-carousel__slide--rank .ref-feed--dashboard-triple,
    .ref-dashboard-carousel__slide--board .ref-feed--dashboard-triple {
      display: grid;
      grid-template-columns: minmax(0, 1fr);
      grid-auto-rows: auto;
      gap: 10px;
      align-items: stretch;
    }
    .ref-dashboard-carousel__slide--rank .ref-feed--dashboard-triple .ref-feed-item,
    .ref-dashboard-carousel__slide--board .ref-feed--dashboard-triple .ref-feed-item {
      margin: 0;
    }
    .ref-dashboard-carousel__slide--items .ref-item-list {
      grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
      gap: 10px !important;
      align-items: stretch !important;
    }
    .ref-dashboard-carousel__dots {
      display: flex; justify-content: center; align-items: center; gap: 4px; margin-top: 8px; flex-wrap: wrap;
    }
    .ref-dashboard-carousel__dot {
      box-sizing: content-box;
      width: 5px;
      height: 5px;
      border-radius: 50%;
      border: 0;
      padding: 3px;
      margin: 0;
      background: rgba(141, 104, 191, 0.35);
      background-clip: content-box;
      cursor: pointer;
      transition: transform 0.15s ease, background 0.15s ease;
    }
    .ref-dashboard-carousel__dot.is-active {
      background: linear-gradient(90deg, #f79fb7, #b883ff);
      background-clip: content-box;
      transform: scale(1.1);
    }
    .ref-quick-strip {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 12px;
      padding: 10px 14px;
      border-radius: 999px;
      background: rgba(255,255,255,0.44);
      border: 1px solid rgba(255,255,255,0.36);
    }
    .ref-quick-pill {
      min-width: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 10px;
      padding: 10px 14px;
      border-radius: 999px;
      background: rgba(255,255,255,0.58);
      font-size: 0.92rem;
      font-weight: 800;
    }
    .ref-dashboard {
      display: grid;
      grid-template-columns: 1.22fr 2.2fr 1.22fr;
      gap: 14px;
    }
    .ref-panel {
      min-height: 0;
      padding: 16px 18px;
      border-radius: 24px;
      background: linear-gradient(180deg, rgba(255,255,255,0.62), rgba(255,255,255,0.42));
      border: 1px solid rgba(255,255,255,0.38);
      box-shadow: 0 16px 34px rgba(181, 142, 230, 0.12);
    }
    .ref-panel__head { display: flex; justify-content: space-between; align-items: center; gap: 10px; margin-bottom: 14px; }
    .ref-panel__head h2 { margin: 0; font-size: 1.02rem; font-weight: 900; }
    .ref-panel__head a, .ref-panel__head span { font-size: 0.78rem; font-weight: 800; color: #8d68bf; text-decoration: none; }
    .ref-trainee-row { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; }
    .ref-trainee-mini { text-decoration: none; text-align: center; color: inherit; }
    .ref-trainee-mini__avatar { position: relative; display: block; width: 62px; height: 62px; margin: 0 auto 8px; border-radius: 50%; overflow: visible; border: 3px solid rgba(255,255,255,0.68); }
    .ref-trainee-mini__avatar img { width: 100%; height: 100%; object-fit: cover; border-radius: 50%; display: block; }
    .ref-trainee-mini strong, .ref-list-item strong, .ref-feed-item strong, .ref-item-row strong { display: block; font-size: 0.88rem; font-weight: 900; }
    .ref-trainee-mini small, .ref-list-item small { display: block; margin-top: 4px; font-size: 0.74rem; font-weight: 800; color: #8d68bf; }
    .ref-score-box { display: flex; align-items: baseline; gap: 4px; justify-content: center; margin-top: 10px; }
    .ref-score-box strong { font-family: "Orbitron", sans-serif; font-size: clamp(2.8rem, 4vw, 4rem); color: #ef6db3; line-height: 1; }
    .ref-score-box span { font-size: 1.1rem; font-weight: 800; }
    .ref-score-copy { margin: 10px 0 0; text-align: center; font-size: 0.84rem; line-height: 1.6; color: rgba(83, 61, 118, 0.74); }
    .ref-list, .ref-feed, .ref-item-list { display: grid; gap: 10px; }
    .ref-list-item, .ref-feed-item, .ref-item-row { display: grid; gap: 4px; padding: 10px 12px; border-radius: 16px; background: rgba(255,255,255,0.54); border: 1px solid rgba(255,255,255,0.36); text-decoration: none; color: inherit; }
    .ref-list-item span, .ref-feed-item span { font-family: "Orbitron", sans-serif; font-size: 0.74rem; color: #b26de4; font-weight: 800; }
    .ref-item-row { grid-template-columns: minmax(0, 1fr) auto; align-items: center; gap: 12px; }
    .ref-chip-btn { min-width: 78px; min-height: 34px; border: 0; border-radius: 999px; background: linear-gradient(90deg, #f7aac6, #caa2ff); color: #fff; font-family: "Orbitron", sans-serif; font-size: 0.76rem; font-weight: 800; cursor: pointer; }
    .ref-list-empty { padding: 18px 12px; text-align: center; border-radius: 16px; background: rgba(255,255,255,0.5); color: rgba(83, 61, 118, 0.74); font-size: 0.82rem; }
    @media (max-width: 1280px) {
      .ref-hero-card { grid-template-columns: 1fr 250px; }
      .ref-dashboard { grid-template-columns: repeat(3, minmax(0, 1fr)); }
    }
    @media (max-width: 980px) {
      body.page-main-reference { overflow: auto; }
      body.page-main-reference .site-footer { display: block; }
      .ref-main { min-height: auto; padding-bottom: 20px; }
      .ref-stage { min-height: auto; grid-template-rows: auto; }
      .ref-hero-card { grid-template-columns: 1fr; }
      .ref-title { font-size: clamp(2.5rem, 9vw, 4.8rem); }
      .ref-quick-strip, .ref-dashboard { grid-template-columns: 1fr; }
      .ref-panel--trainees { grid-column: auto; }
      .ref-live-pick {
        --ref-live-pick-tilt: perspective(1400px) rotateY(-7deg) rotateX(1deg);
      }
    }
    @media (max-width: 640px) {
      .ref-shell { width: min(100vw - 14px, 1000px); }
      .ref-main { padding-top: 10px; }
      .ref-hero-card { padding: 18px 14px; border-radius: 24px; }
      .ref-subtitle { font-size: 0.94rem; }
      .ref-actions { gap: 10px; }
      .ref-btn { width: 100%; }
      .ref-trainee-row:not(.ref-trainee-row--carousel) { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      .ref-quick-pill { flex-direction: column; text-align: center; }
      .ref-live-pick {
        --ref-live-pick-tilt: perspective(1200px) rotateY(-5deg) rotateX(0.7deg);
      }
    }

    .ref-main__overlay {
      background: linear-gradient(180deg, rgba(255,255,255,0.02) 0%, rgba(255,255,255,0.03) 100%), radial-gradient(circle at center, rgba(255,255,255,0.02), rgba(255,255,255,0.01) 58%, rgba(245,233,255,0.08) 100%);
    }
    .ref-stage {
      min-height: calc(100vh - var(--nav-h, 72px) - 28px);
      grid-template-rows: auto auto;
      gap: 8px;
      align-content: start;
    }
    .ref-hero-card {
      gap: 20px;
      padding: clamp(18px, 2.1vw, 26px);
      border-radius: 30px;
      background: linear-gradient(180deg, rgba(255,255,255,0.10), rgba(255,255,255,0.04));
      border: 1px solid rgba(255,255,255,0.26);
    }
    .ref-kicker {
      margin-bottom: 10px;
      font-size: clamp(0.72rem, 0.8vw, 0.88rem);
      letter-spacing: 0.42em;
      color: rgba(255,255,255,0.96);
      text-shadow: 0 2px 12px rgba(75, 16, 130, 0.26);
    }
    .ref-title {
      font-size: clamp(4rem, 7.8vw, 7.2rem);
      line-height: 0.9;
      font-weight: 900;
      letter-spacing: -0.08em;
      color: #ffc7f6;
      -webkit-text-stroke: 2px rgba(255, 228, 248, 0.92);
      text-shadow: 0 0 24px rgba(255, 146, 232, 0.28), 0 10px 30px rgba(215, 111, 231, 0.24), 0 2px 0 rgba(255,255,255,0.95);
    }
    .ref-subtitle {
      max-width: none;
      white-space: nowrap;
      margin-top: 14px;
      font-size: clamp(0.92rem, 1.15vw, 1.18rem);
      line-height: 1.35;
      text-shadow: 0 2px 14px rgba(91, 33, 182, 0.22);
    }
    .ref-actions {
      margin-top: 22px;
    }
    .ref-btn {
      min-height: 52px;
      padding: 0 30px;
      box-shadow: 0 10px 26px rgba(201, 140, 255, 0.18);
    }
    .ref-live-pick {
      padding: 12px;
      border-radius: 24px;
      background: linear-gradient(180deg, rgba(255,255,255,0.78), rgba(255,255,255,0.58));
    }
    .ref-live-pick__thumb {
      aspect-ratio: 0.86;
    }
    .ref-live-pick__name {
      font-size: 1.42rem;
    }
    .ref-quick-strip {
      gap: 10px;
      padding: 8px 10px;
      background: rgba(255,255,255,0.34);
    }
    .ref-quick-pill {
      min-height: 56px;
      padding: 8px 12px;
      background: rgba(255,255,255,0.66);
    }
    .ref-quick-pill--ticker {
      justify-content: flex-start;
    }
    .ref-rank-ticker {
      position: relative;
      flex: 1;
      min-height: 24px;
      overflow: hidden;
    }
    .ref-rank-ticker__item,
    .ref-rank-ticker__empty {
      position: absolute;
      inset: 0;
      display: grid;
      grid-template-columns: auto minmax(0, 1fr) auto;
      align-items: center;
      gap: 8px;
      text-decoration: none;
      color: inherit;
      opacity: 0;
      transform: translateY(105%);
      transition: transform 0.35s ease, opacity 0.35s ease;
    }
    .ref-rank-ticker__item.is-active {
      opacity: 1;
      transform: translateY(0);
    }
    .ref-rank-ticker__rank,
    .ref-rank-ticker__score {
      font-family: "Orbitron", sans-serif;
      font-size: 0.8rem;
      font-weight: 800;
      color: #9f5ce4;
    }
    .ref-rank-ticker__name {
      min-width: 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      font-size: 0.9rem;
      font-weight: 900;
      color: #4c3270;
    }
    .ref-quick-links {
      display: flex;
      align-items: center;
      gap: 6px;
      flex-wrap: wrap;
      justify-content: center;
    }
    .ref-quick-links a {
      padding: 6px 10px;
      border-radius: 999px;
      background: rgba(255,255,255,0.72);
      color: #6e49a9;
      text-decoration: none;
      font-size: 0.85rem;
      font-weight: 900;
    }
    .ref-dashboard {
      grid-template-columns: 1.1fr 2.1fr 1.1fr;
      gap: 10px;
    }
    .ref-panel {
      padding: 12px 14px;
      border-radius: 20px;
      background: linear-gradient(180deg, rgba(255,255,255,0.66), rgba(255,255,255,0.48));
    }
    .ref-panel__head {
      margin-bottom: 10px;
    }
    .ref-panel__head h2 {
      font-size: 0.95rem;
    }
    .ref-trainee-row {
      gap: 8px;
    }
    .ref-trainee-mini__avatar {
      width: 54px;
      height: 54px;
      margin-bottom: 6px;
    }
    .ref-trainee-mini strong,
    .ref-list-item strong,
    .ref-feed-item strong,
    .ref-item-row strong {
      font-size: 0.82rem;
    }
    .ref-score-box strong {
      font-size: clamp(2.2rem, 3vw, 3.3rem);
    }
    .ref-score-copy {
      font-size: 0.78rem;
      line-height: 1.45;
    }
    .ref-list, .ref-feed, .ref-item-list {
      gap: 8px;
    }
    .ref-list-item, .ref-feed-item, .ref-item-row {
      padding: 8px 10px;
      border-radius: 14px;
    }
    @media (max-width: 980px) {
      .ref-subtitle {
        white-space: normal;
      }
      .ref-rank-ticker__item,
      .ref-rank-ticker__empty {
        position: relative;
        opacity: 1;
        transform: none;
      }
    }

    .ref-shell {
      width: min(1420px, calc(100vw - 20px));
    }
    .ref-main {
      padding: 10px 0 10px;
    }
    .ref-main__overlay {
      background: linear-gradient(180deg, rgba(255,255,255,0.01) 0%, rgba(255,255,255,0.015) 100%), radial-gradient(circle at center, rgba(255,255,255,0.015), rgba(255,255,255,0.008) 62%, rgba(245,233,255,0.04) 100%);
    }
    .ref-main__spark--left,
    .ref-main__spark--right {
      opacity: 0.45;
    }
    .ref-stage {
      min-height: calc(100vh - var(--nav-h, 72px) - 16px);
      grid-template-rows: auto auto;
      gap: 6px;
      align-content: start;
    }
    .ref-hero-card {
      grid-template-columns: minmax(0, 1fr) 232px;
      gap: 14px;
      min-height: 0;
      padding: 16px 18px 14px;
      border-radius: 28px;
      background: linear-gradient(180deg, rgba(255,255,255,0.08), rgba(255,255,255,0.025));
      border: 1px solid rgba(255,255,255,0.22);
      box-shadow: inset 0 0 0 1px rgba(255,255,255,0.09), 0 18px 60px rgba(149, 110, 188, 0.16);
    }
    .ref-hero-card::before {
      inset: 8px;
      border-radius: 22px;
      border-color: rgba(255,255,255,0.14);
    }
    .ref-hero-card__center {
      display: flex;
      min-height: 0;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 8px 10px 10px;
    }
    .ref-kicker {
      margin-bottom: 12px;
      font-size: clamp(0.75rem, 0.85vw, 0.96rem);
      letter-spacing: 0.52em;
      color: rgba(255,255,255,0.98);
      text-shadow: 0 2px 16px rgba(91, 33, 182, 0.25), 0 0 24px rgba(255,255,255,0.24);
    }
    .ref-title {
      font-size: clamp(4.8rem, 8.8vw, 8.2rem);
      line-height: 0.82;
      font-weight: 900;
      letter-spacing: -0.09em;
      color: #ffc1f1;
      -webkit-text-stroke: 2.6px rgba(255, 238, 250, 0.98);
      text-shadow: 0 0 18px rgba(255, 173, 233, 0.35), 0 10px 30px rgba(217, 106, 227, 0.28), 0 3px 0 rgba(255,255,255,0.98);
      filter: drop-shadow(0 10px 28px rgba(239, 116, 194, 0.16));
    }
    .ref-subtitle {
      max-width: none;
      white-space: nowrap;
      margin-top: 16px;
      font-size: clamp(1rem, 1.18vw, 1.22rem);
      line-height: 1.2;
      font-weight: 800;
      color: rgba(255,255,255,0.97);
      text-shadow: 0 2px 16px rgba(91, 33, 182, 0.18);
    }
    .ref-actions {
      margin-top: 24px;
      gap: 12px;
    }
    .ref-btn {
      min-height: 50px;
      padding: 0 30px;
      font-size: 0.94rem;
      letter-spacing: 0.14em;
      box-shadow: 0 10px 24px rgba(201, 140, 255, 0.14);
    }
    .ref-btn--primary {
      background: linear-gradient(90deg, #f48db2 0%, #bf92ff 100%);
    }
    .ref-live-pick {
      width: 232px;
      justify-self: end;
      align-self: center;
      padding: 10px;
      border-radius: 24px;
      background: linear-gradient(180deg, rgba(255,255,255,0.82), rgba(255,255,255,0.64));
      box-shadow: 0 12px 34px rgba(183, 131, 232, 0.14);
      gap: 10px;
    }
    .ref-live-pick__badge {
      padding: 7px 12px;
      font-size: 0.72rem;
    }
    .ref-live-pick__thumb {
      aspect-ratio: 0.9;
      border-radius: 18px;
    }
    .ref-live-pick__name {
      font-size: 1.22rem;
    }
    .ref-live-pick__meta {
      font-size: 0.8rem;
    }
    .ref-stat-list {
      gap: 8px;
    }
    .ref-stat-row {
      grid-template-columns: 46px minmax(0, 1fr) 26px;
      gap: 6px;
      font-size: 0.74rem;
    }
    .ref-live-pick__action {
      min-height: 40px;
      font-size: 0.86rem;
    }
    .ref-dashboard {
      align-items: stretch;
      grid-template-columns: 1.14fr 2.14fr 1.14fr;
      gap: 7px;
    }
    .ref-panel {
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
      padding: 8px 10px;
      border-radius: 16px;
      background: linear-gradient(180deg, rgba(255,255,255,0.74), rgba(255,255,255,0.56));
      box-shadow: 0 8px 18px rgba(181, 142, 230, 0.08);
    }
    .ref-panel__head {
      margin-bottom: 6px;
    }
    .ref-panel__head h2 {
      font-size: 0.84rem;
      line-height: 1.05;
    }
    .ref-panel__head a,
    .ref-panel__head span {
      font-size: 0.66rem;
    }
    .ref-trainee-row {
      gap: 5px;
      height: 100%;
    }
    .ref-trainee-mini__avatar {
      width: 42px;
      height: 42px;
      margin-bottom: 4px;
      border-width: 2px;
    }
    .ref-trainee-mini strong,
    .ref-list-item strong,
    .ref-feed-item strong,
    .ref-item-row strong {
      font-size: 0.75rem;
      line-height: 1.1;
    }
    .ref-trainee-mini small,
    .ref-list-item small,
    .ref-feed-item small,
    .ref-item-row small {
      font-size: 0.63rem;
    }
    .ref-score-box {
      margin-top: 2px;
    }
    .ref-score-box strong {
      font-size: clamp(1.7rem, 2.2vw, 2.5rem);
    }
    .ref-score-box span {
      font-size: 0.82rem;
    }
    .ref-score-copy {
      margin-top: 4px;
      font-size: 0.66rem;
      line-height: 1.28;
    }
    .ref-list,
    .ref-feed,
    .ref-item-list {
      gap: 5px;
    }
    .ref-list-item,
    .ref-feed-item,
    .ref-item-row {
      padding: 6px 7px;
      border-radius: 10px;
    }
    .ref-list-item span,
    .ref-feed-item span {
      font-size: 0.62rem;
    }
    .ref-item-row {
      grid-template-columns: minmax(0, 1fr) 58px;
      gap: 7px;
    }
    .ref-chip-btn {
      min-width: 58px;
      min-height: 26px;
      font-size: 0.62rem;
    }
    @media (max-width: 1280px) {
      .ref-stage {
        grid-template-rows: auto auto;
      }
      .ref-hero-card {
        grid-template-columns: 1fr 220px;
      }
      .ref-dashboard {
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 10px;
      }
      .ref-subtitle {
        white-space: normal;
      }
    }
    @media (max-width: 980px) {
      body.page-main-reference {
        overflow: auto;
      }
      body.page-main-reference .site-footer {
        display: block;
      }
      .ref-main {
        min-height: auto;
        padding-bottom: 18px;
      }
      .ref-stage {
        min-height: auto;
        grid-template-rows: auto;
      }
      .ref-hero-card {
        grid-template-columns: 1fr;
      }
      .ref-live-pick {
        width: min(260px, 100%);
        justify-self: center;
      }
      .ref-dashboard {
        grid-template-columns: 1fr;
      }
      .ref-panel--trainees {
        grid-column: auto;
      }
      .ref-subtitle {
        white-space: normal;
      }
    }


    .ref-shell {
      width: min(1460px, calc(100vw - 18px));
    }
    .ref-main {
      padding: 8px 0 8px;
    }
    .ref-main__overlay {
      background:
        linear-gradient(180deg, rgba(255,255,255,0.005) 0%, rgba(255,255,255,0.01) 100%),
        radial-gradient(circle at center, rgba(255,255,255,0.012), rgba(255,255,255,0.004) 64%, rgba(245,233,255,0.03) 100%);
    }
    .ref-stage {
      min-height: calc(100vh - var(--nav-h, 72px) - 14px);
      height: auto;
      grid-template-rows: auto auto;
      gap: 4px;
      align-content: start;
    }
    .ref-hero-card {
      grid-template-columns: minmax(0, 1fr) 214px;
      gap: 10px;
      padding: 12px 16px 10px;
      border-radius: 26px;
      background: linear-gradient(180deg, rgba(255,255,255,0.06), rgba(255,255,255,0.02));
      border: 1px solid rgba(255,255,255,0.2);
      box-shadow: inset 0 0 0 1px rgba(255,255,255,0.06), 0 18px 52px rgba(152, 101, 210, 0.12);
    }
    .ref-hero-card::before {
      inset: 6px;
      border-radius: 20px;
      border-color: rgba(255,255,255,0.1);
    }
    .ref-hero-card__center {
      justify-content: center;
      padding: 0 6px;
    }
    .ref-kicker {
      margin-bottom: 12px;
      font-size: clamp(0.78rem, 0.9vw, 1rem);
      letter-spacing: 0.56em;
      font-weight: 900;
      color: rgba(255,255,255,0.98);
      text-shadow: 0 2px 18px rgba(89, 24, 129, 0.22);
    }
    .ref-title {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 2px;
      margin: 0;
      font-family: "Orbitron", sans-serif;
      font-weight: 900;
      letter-spacing: -0.08em;
      color: #ffc1f0;
      filter: drop-shadow(0 16px 34px rgba(236, 72, 153, 0.14));
    }
    .ref-title__line {
      display: block;
      font-size: clamp(5.4rem, 9vw, 8.6rem);
      line-height: 0.82;
      -webkit-text-stroke: 2.8px rgba(255, 245, 251, 0.98);
      text-shadow:
        0 0 18px rgba(255, 190, 239, 0.28),
        0 10px 28px rgba(217, 98, 213, 0.28),
        0 2px 0 rgba(255,255,255,0.98);
    }
    .ref-title__line--second {
      letter-spacing: -0.1em;
    }
    .ref-subtitle {
      margin-top: 14px;
      font-size: clamp(1.02rem, 1.15vw, 1.26rem);
      line-height: 1.15;
      font-weight: 800;
      color: rgba(255,255,255,0.98);
      text-shadow: 0 2px 14px rgba(91, 33, 182, 0.16);
      white-space: nowrap;
    }
    .ref-actions {
      margin-top: 22px;
      gap: 10px;
    }
    .ref-btn {
      min-height: 48px;
      padding: 0 28px;
      font-size: 0.9rem;
      font-weight: 900;
      letter-spacing: 0.16em;
      box-shadow: 0 10px 24px rgba(194, 116, 225, 0.12);
    }
    .ref-live-pick {
      width: 214px;
      padding: 9px;
      border-radius: 22px;
      background: linear-gradient(180deg, rgba(255,255,255,0.86), rgba(255,255,255,0.68));
      box-shadow: 0 10px 28px rgba(183, 131, 232, 0.1);
      gap: 8px;
    }
    .ref-live-pick__badge {
      padding: 6px 11px;
      font-size: 0.68rem;
      letter-spacing: 0.08em;
    }
    .ref-live-pick__thumb {
      aspect-ratio: 0.88;
      border-radius: 16px;
    }
    .ref-live-pick__name {
      font-size: 1.12rem;
      line-height: 1;
    }
    .ref-live-pick__meta {
      font-size: 0.72rem;
    }
    .ref-stat-list {
      gap: 6px;
    }
    .ref-stat-row {
      grid-template-columns: 42px minmax(0, 1fr) 24px;
      gap: 6px;
      font-size: 0.68rem;
    }
    .ref-live-pick__action {
      min-height: 36px;
      font-size: 0.8rem;
      border-radius: 999px;
    }
    .ref-dashboard {
      grid-template-columns: 1.06fr 1.99fr 1.06fr;
      gap: 6px;
      align-items: stretch;
    }
    .ref-panel {
      padding: 8px 9px;
      border-radius: 15px;
      background: linear-gradient(180deg, rgba(255,255,255,0.76), rgba(255,255,255,0.58));
      border: 1px solid rgba(255,255,255,0.34);
      box-shadow: 0 7px 16px rgba(183, 131, 232, 0.08);
    }
    .ref-panel__head {
      margin-bottom: 5px;
      gap: 6px;
    }
    .ref-panel__head h2 {
      font-size: 0.8rem;
      font-weight: 900;
      letter-spacing: -0.03em;
    }
    .ref-panel__head a,
    .ref-panel__head span {
      font-size: 0.62rem;
    }
    .ref-trainee-row {
      gap: 4px;
    }
    .ref-trainee-mini__avatar {
      width: 38px;
      height: 38px;
      margin-bottom: 3px;
    }
    .ref-trainee-mini strong,
    .ref-list-item strong,
    .ref-feed-item strong,
    .ref-item-row strong {
      font-size: 0.71rem;
      line-height: 1.05;
    }
    .ref-trainee-mini small,
    .ref-list-item small,
    .ref-feed-item small,
    .ref-item-row small {
      font-size: 0.58rem;
      line-height: 1.1;
    }
    .ref-score-box strong {
      font-size: clamp(1.55rem, 2vw, 2.25rem);
    }
    .ref-score-box span {
      font-size: 0.74rem;
    }
    .ref-score-copy {
      margin-top: 3px;
      font-size: 0.6rem;
      line-height: 1.18;
    }
    .ref-list,
    .ref-feed,
    .ref-item-list {
      gap: 4px;
    }
    .ref-list-item,
    .ref-feed-item,
    .ref-item-row {
      padding: 5px 6px;
      border-radius: 9px;
      gap: 2px;
    }
    .ref-list-item span,
    .ref-feed-item span {
      font-size: 0.56rem;
    }
    .ref-item-row {
      grid-template-columns: minmax(0, 1fr) 54px;
      gap: 6px;
    }
    .ref-chip-btn {
      min-width: 54px;
      min-height: 24px;
      font-size: 0.56rem;
      letter-spacing: 0.04em;
    }
    @media (max-width: 1280px) {
      .ref-stage {
        grid-template-rows: auto auto;
      }
      .ref-hero-card {
        grid-template-columns: 1fr 208px;
      }
      .ref-title__line {
        font-size: clamp(4.2rem, 10vw, 6.4rem);
      }
      .ref-subtitle {
        white-space: normal;
      }
      .ref-dashboard {
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 8px;
      }
    }
    @media (max-width: 980px) {
      body.page-main-reference {
        overflow: auto;
      }
      body.page-main-reference .site-footer {
        display: block;
      }
      .ref-stage {
        min-height: auto;
        grid-template-rows: auto;
      }
      .ref-hero-card {
        grid-template-columns: 1fr;
      }
      .ref-live-pick {
        width: min(240px, 100%);
        justify-self: center;
      }
      .ref-dashboard {
        grid-template-columns: 1fr;
      }
      .ref-panel--trainees {
        grid-column: auto;
      }
      .ref-subtitle {
        white-space: normal;
      }
    }


    .ref-title {
      position: relative;
      isolation: isolate;
    }
    .ref-title::after {
      content: "";
      position: absolute;
      inset: 18% 10% 6%;
      z-index: -1;
      border-radius: 999px;
      background: radial-gradient(circle, rgba(255, 170, 225, 0.34), rgba(208, 137, 255, 0.16) 45%, transparent 72%);
      filter: blur(24px);
    }
    .ref-title__line {
      background: linear-gradient(180deg, #fff8ff 0%, #ffd6f6 22%, #ffb7ea 52%, #ffa2e1 74%, #ffeefe 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      position: relative;
    }
    .ref-title__line::after {
      content: "";
      position: absolute;
      left: 12%;
      right: 12%;
      top: 12%;
      height: 16%;
      border-radius: 999px;
      background: linear-gradient(90deg, rgba(255,255,255,0), rgba(255,255,255,0.72), rgba(255,255,255,0));
      opacity: 0.7;
      filter: blur(3px);
    }
    .ref-panel {
      position: relative;
      overflow: hidden;
    }
    .ref-panel::before {
      content: "";
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 3px;
      opacity: 0.92;
    }
    .ref-panel--trainees::before { background: linear-gradient(90deg, #f88fc0, #ffb5d8); }
    .ref-panel--score-rank::before { background: linear-gradient(90deg, #ff87b3 0%, #c68cff 45%, #8fb8ff 100%); }
    .ref-panel--board::before { background: linear-gradient(90deg, #ff9bc7, #ffd1e5); }
    .ref-panel--items::before { background: linear-gradient(90deg, #f7b2ff, #d5b8ff); }
    .ref-panel__head h2 {
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .ref-panel__head h2 i {
      width: 18px;
      height: 18px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      border-radius: 999px;
      font-size: 0.62rem;
      color: #fff;
      background: linear-gradient(135deg, #f08fc1, #bb8eff);
      box-shadow: 0 4px 10px rgba(207, 122, 226, 0.22);
    }
    .ref-panel__head a,
    .ref-panel__head span {
      padding: 3px 6px;
      border-radius: 999px;
      background: rgba(255,255,255,0.58);
    }
    .ref-list-item,
    .ref-feed-item,
    .ref-item-row,
    .ref-trainee-mini {
      transition: transform 0.18s ease, box-shadow 0.18s ease, background 0.18s ease;
    }
    .ref-list-item:hover,
    .ref-feed-item:hover,
    .ref-item-row:hover,
    .ref-trainee-mini:hover {
      transform: translateY(-1px);
      box-shadow: 0 8px 18px rgba(201, 147, 236, 0.12);
      background: rgba(255,255,255,0.84);
    }
    .ref-trainee-mini__avatar {
      box-shadow: 0 6px 14px rgba(214, 149, 237, 0.18);
    }
    .ref-chip-btn {
      box-shadow: 0 6px 12px rgba(211, 136, 230, 0.14);
    }
    .ref-chip-btn:hover {
      transform: translateY(-1px);
      box-shadow: 0 10px 18px rgba(211, 136, 230, 0.18);
    }


    .ref-hero-card,
    .ref-panel,
    .ref-live-pick {
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
    }

    .ref-hero-card {
      overflow: hidden;
    }
    /* 히어로 딤 레이어 제거 ? 배경 일러스트가 원본에 가깝게 보이도록 */
    .ref-hero-card::after {
      content: none !important;
      display: none !important;
    }
    .ref-hero-card__center,
    .ref-live-pick {
      position: relative;
      z-index: 1;
    }
    .ref-kicker {
      margin-bottom: 14px;
      color: rgba(255,255,255,0.98);
      text-shadow: 0 4px 18px rgba(35, 12, 56, 0.62), 0 0 24px rgba(255,255,255,0.12);
    }
    .ref-title {
      position: relative;
      font-size: clamp(4.9rem, 8.9vw, 8.35rem);
      letter-spacing: -0.085em;
      color: #ffe4fa;
      -webkit-text-stroke: 2px rgba(255, 244, 252, 0.96);
      text-shadow:
        0 3px 0 rgba(255,255,255,0.96),
        0 14px 34px rgba(72, 16, 99, 0.46),
        0 0 22px rgba(255, 171, 229, 0.42);
      filter: drop-shadow(0 12px 28px rgba(102, 31, 139, 0.34));
    }
    .ref-title::before {
      content: "";
      position: absolute;
      left: 50%;
      top: 50%;
      width: min(88%, 820px);
      height: 78%;
      transform: translate(-50%, -50%);
      background: radial-gradient(circle, rgba(255,255,255,0.18) 0%, rgba(255,214,247,0.12) 26%, rgba(87,26,123,0.08) 50%, rgba(87,26,123,0) 76%);
      filter: blur(8px);
      z-index: -1;
      pointer-events: none;
    }
    .ref-title__line {
      display: block;
    }
    .ref-title__line--second {
      margin-top: -0.06em;
    }
    .ref-subtitle {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      max-width: min(92%, 980px);
      min-height: 54px;
      margin: 18px auto 0;
      padding: 0 28px;
      border-radius: 999px;
      white-space: nowrap;
      font-size: clamp(1rem, 1.14vw, 1.2rem);
      line-height: 1;
      color: rgba(255,255,255,0.99);
      background: linear-gradient(90deg, rgba(45, 14, 69, 0.42) 0%, rgba(68, 20, 104, 0.26) 20%, rgba(68, 20, 104, 0.26) 80%, rgba(45, 14, 69, 0.42) 100%);
      border: 1px solid rgba(255,255,255,0.24);
      box-shadow: 0 14px 30px rgba(43, 12, 68, 0.18);
      text-shadow: 0 2px 12px rgba(28, 9, 46, 0.54);
    }
    @media (max-width: 980px) {
      .ref-hero-card::after {
        content: none !important;
        display: none !important;
      }
      .ref-title {
        font-size: clamp(3.6rem, 11vw, 5.6rem);
        -webkit-text-stroke: 1.4px rgba(255, 244, 252, 0.96);
      }
      .ref-subtitle {
        white-space: normal;
        min-height: auto;
        padding: 12px 18px;
        border-radius: 20px;
        line-height: 1.45;
      }
    }

    .ref-hero-card {
      position: relative;
      isolation: isolate;
    }
    .ref-hero-card::before {
      content: "";
      position: absolute;
      inset: 10px;
      border-radius: 22px;
      border: 1px solid rgba(255,255,255,0.16);
      background: linear-gradient(180deg, rgba(255,255,255,0.08), rgba(255,255,255,0));
      pointer-events: none;
      z-index: 0;
    }
    .ref-title {
      background: linear-gradient(180deg, #fff8ff 0%, #ffe4fa 28%, #ffc7f3 62%, #ffb5ec 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      color: transparent;
      text-shadow: none;
      filter: drop-shadow(0 4px 0 rgba(255,255,255,0.95)) drop-shadow(0 14px 34px rgba(83, 19, 112, 0.44)) drop-shadow(0 0 22px rgba(255, 177, 231, 0.36));
    }
    .ref-title__line {
      position: relative;
      padding: 0 0.03em;
    }
    .ref-title__line::after {
      content: "";
      position: absolute;
      left: 0.12em;
      right: 0.12em;
      top: 0.16em;
      height: 0.18em;
      border-radius: 999px;
      background: linear-gradient(90deg, rgba(255,255,255,0.8), rgba(255,255,255,0));
      opacity: 0.5;
      pointer-events: none;
    }
    .ref-subtitle {
      letter-spacing: -0.01em;
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
    }
    .ref-btn {
      border: 1px solid rgba(255,255,255,0.32);
    }
    .ref-btn--primary {
      box-shadow: 0 14px 28px rgba(208, 113, 203, 0.28), inset 0 1px 0 rgba(255,255,255,0.32);
    }
    .ref-btn--secondary {
      box-shadow: 0 12px 22px rgba(71, 39, 116, 0.12), inset 0 1px 0 rgba(255,255,255,0.72);
    }
    .ref-live-pick,
    .ref-panel {
      position: relative;
      overflow: hidden;
      border: 1px solid rgba(255,255,255,0.42);
    }
    .ref-live-pick::before,
    .ref-panel::before {
      content: "";
      position: absolute;
      left: 0;
      right: 0;
      top: 0;
      height: 4px;
      background: linear-gradient(90deg, #ff9bc8 0%, #d5a5ff 55%, #9ec4ff 100%);
      opacity: 0.95;
      pointer-events: none;
    }
    .ref-live-pick::after {
      content: "";
      position: absolute;
      inset: 0;
      z-index: 0;
      background: linear-gradient(160deg, rgba(255,255,255,0.28), rgba(255,255,255,0) 42%);
      pointer-events: none;
    }
    .ref-live-pick__badge {
      background: linear-gradient(90deg, #ff9abc 0%, #e39dfc 100%);
      box-shadow: 0 10px 18px rgba(218, 129, 207, 0.22);
    }
    .ref-live-pick__name,
    .ref-panel__head h2,
    .ref-list-item strong,
    .ref-feed-item strong,
    .ref-item-row strong,
    .ref-trainee-mini strong {
      color: #35214d;
      letter-spacing: -0.01em;
    }
    .ref-panel__head {
      padding-bottom: 6px;
      border-bottom: 1px solid rgba(213, 176, 244, 0.24);
    }
    .ref-panel__head a,
    .ref-panel__head span {
      color: #9a63d8;
    }
    .ref-list-item,
    .ref-feed-item,
    .ref-item-row,
    .ref-trainee-mini {
      transition: transform 0.18s ease, box-shadow 0.18s ease, background-color 0.18s ease;
    }
    .ref-list-item:hover,
    .ref-feed-item:hover,
    .ref-item-row:hover,
    .ref-trainee-mini:hover {
      transform: translateY(-2px);
      box-shadow: 0 12px 20px rgba(165, 121, 212, 0.14);
      background: rgba(255,255,255,0.78);
    }
    .ref-panel--score-rank .ref-score-box strong {
      background: linear-gradient(180deg, #ff6db8 0%, #cf7eff 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      color: transparent;
      text-shadow: none;
    }
    .ref-panel--board::before { background: linear-gradient(90deg, #ff9fbe 0%, #ffc7a8 100%); }
    .ref-panel--items::before { background: linear-gradient(90deg, #ff92be 0%, #b798ff 100%); }
    .ref-panel--trainees::before { background: linear-gradient(90deg, #ff9cc8 0%, #d9a2ff 100%); }
    @media (max-width: 980px) {
      .ref-title__line::after {
        opacity: 0.35;
      }
      .ref-panel__head {
        padding-bottom: 4px;
      }
    }

    .ref-title {
      flex-direction: row;
      justify-content: center;
      align-items: baseline;
      gap: 0.12em;
      flex-wrap: nowrap;
    }
    .ref-title__line {
      font-size: clamp(4.05rem, 6.9vw, 6.6rem);
      line-height: 0.92;
    }
    .ref-title__line--second {
      margin-top: 0;
      letter-spacing: -0.08em;
    }
    .ref-subtitle {
      background: transparent !important;
      border: 0 !important;
      box-shadow: none !important;
      border-radius: 0 !important;
      padding: 0 !important;
      min-height: 0 !important;
      max-width: min(96%, 1100px);
    }
    .ref-panel--trainees {
      justify-content: center;
    }
    .ref-panel--trainees .ref-trainee-row {
      grid-template-columns: repeat(3, minmax(58px, 1fr));
      align-items: start;
      align-content: center;
      justify-items: center;
      height: auto;
      min-height: 88px;
      gap: 8px;
      padding: 4px 6px 2px;
    }
    .ref-panel--trainees .ref-trainee-mini {
      width: 100%;
      max-width: 74px;
    }
    .ref-panel--trainees .ref-trainee-mini__avatar {
      width: 48px;
      height: 48px;
      margin-bottom: 5px;
    }
    .ref-panel--trainees .ref-trainee-mini strong {
      font-size: 0.78rem;
    }
    @media (max-width: 980px) {
      .ref-title {
        flex-wrap: wrap;
        gap: 0;
      }
      .ref-title__line {
        font-size: clamp(3.4rem, 11vw, 5.4rem);
      }
      .ref-subtitle {
        max-width: 100%;
      }
      .ref-panel--trainees .ref-trainee-row:not(.ref-trainee-row--carousel) {
        grid-template-columns: repeat(2, minmax(0, 1fr));
        min-height: 0;
      }
    }


    @keyframes refHeroFadeUp {
      from {
        opacity: 0;
        transform: translate3d(0, 24px, 0);
      }
      to {
        opacity: 1;
        transform: translate3d(0, 0, 0);
      }
    }
    @keyframes refLivePickReveal {
      from {
        opacity: 0;
        transform: var(--ref-live-pick-tilt) translate3d(18px, 24px, 0);
      }
      to {
        opacity: 1;
        transform: var(--ref-live-pick-tilt) translate3d(0, 0, 0);
      }
    }
    @keyframes refLiveFloat {
      0%, 100% {
        transform: var(--ref-live-pick-tilt) translate3d(0, 0, 0);
      }
      50% {
        transform: var(--ref-live-pick-tilt) translate3d(0, -8px, 0);
      }
    }
    @keyframes refSoftGlow {
      0%, 100% {
        opacity: 0.42;
      }
      50% {
        opacity: 0.68;
      }
    }
    .ref-kicker,
    .ref-title-stack,
    .ref-subtitle,
    .ref-actions {
      opacity: 0;
      animation: refHeroFadeUp 0.72s cubic-bezier(.22,1,.36,1) forwards;
      will-change: transform, opacity;
    }
    .ref-kicker { animation-delay: 0.08s; }
    .ref-title-stack { animation-delay: 0.18s; }
    .ref-subtitle { animation-delay: 0.28s; }
    .ref-actions { animation-delay: 0.38s; }
    .ref-live-pick {
      animation: refLivePickReveal 0.78s cubic-bezier(.22,1,.36,1) 0.24s both, refLiveFloat 4.8s ease-in-out 1.1s infinite;
      will-change: transform, opacity;
    }
    .ref-title::before {
      animation: refSoftGlow 4.2s ease-in-out infinite;
    }
    .ref-btn,
    .ref-list-item,
    .ref-feed-item,
    .ref-item-row,
    .ref-trainee-mini,
    .ref-live-pick {
      transition: transform 0.22s ease, box-shadow 0.22s ease, background-color 0.22s ease;
    }
    .ref-btn:hover {
      transform: translateY(-2px);
    }
    .ref-live-pick:hover {
      transform: var(--ref-live-pick-tilt) translate3d(0, -10px, 0);
      box-shadow: 0 16px 30px rgba(183, 131, 232, 0.16);
    }
    @media (prefers-reduced-motion: reduce) {
      .ref-kicker,
      .ref-title-stack,
      .ref-title,
      .ref-title-eyebrow,
      .ref-subtitle,
      .ref-actions,
      .ref-live-pick,
      .ref-title::before {
        animation: none !important;
        opacity: 1 !important;
        transform: none !important;
      }
      .ref-btn,
      .ref-list-item,
      .ref-feed-item,
      .ref-item-row,
      .ref-trainee-mini,
      .ref-live-pick {
        transition: none !important;
      }
    }

    .ref-hero-card {
      grid-template-columns: minmax(0, 1fr) 226px;
      padding: 14px 18px 12px;
      border-radius: 28px;
      background: linear-gradient(180deg, rgba(255,255,255,0.05), rgba(255,255,255,0.018));
      box-shadow: inset 0 0 0 1px rgba(255,255,255,0.08), 0 22px 58px rgba(138, 88, 204, 0.14);
    }
    .ref-hero-card::after {
      content: none !important;
      display: none !important;
    }
    .ref-hero-card__center {
      padding: 0 12px;
    }
    .ref-kicker {
      margin-bottom: 10px;
      letter-spacing: 0.58em;
      font-size: clamp(0.76rem, 0.82vw, 0.9rem);
      text-transform: uppercase;
      text-shadow: 0 2px 14px rgba(62, 19, 99, 0.34), 0 0 18px rgba(255,255,255,0.12);
    }
    .ref-title {
      gap: 0.08em;
      letter-spacing: -0.075em;
      transform: translateX(-6px);
      filter: drop-shadow(0 18px 32px rgba(136, 48, 149, 0.12));
    }
    .ref-title__line {
      font-size: clamp(4.25rem, 7.1vw, 6.9rem);
      line-height: 0.9;
      -webkit-text-stroke: 2.2px rgba(255, 245, 251, 0.96);
      text-shadow:
        0 0 14px rgba(255, 210, 244, 0.25),
        0 10px 24px rgba(197, 76, 204, 0.22),
        0 2px 0 rgba(255,255,255,0.97);
    }
    .ref-title__line::after {
      left: 0.1em;
      right: 0.1em;
      top: 0.14em;
      height: 0.14em;
      opacity: 0.42;
    }
    .ref-subtitle {
      margin-top: 12px;
      max-width: min(96%, 960px);
      font-size: clamp(1.02rem, 1.08vw, 1.15rem);
      line-height: 1.08;
      letter-spacing: -0.018em;
      text-shadow: 0 2px 10px rgba(55, 19, 85, 0.22);
    }
    .ref-actions {
      margin-top: 20px;
      gap: 12px;
    }
    .ref-btn {
      min-height: 50px;
      padding: 0 30px;
      border-radius: 999px;
      font-size: 0.92rem;
      letter-spacing: 0.15em;
    }
    .ref-btn--primary {
      background: linear-gradient(90deg, #ff8eb9 0%, #cb92ff 100%);
      box-shadow: 0 14px 28px rgba(205, 104, 192, 0.22), inset 0 1px 0 rgba(255,255,255,0.28);
    }
    .ref-btn--secondary {
      background: rgba(255,255,255,0.92);
      color: #5a3d83;
    }
    .ref-live-pick {
      width: 226px;
      padding: 11px;
      border-radius: 24px;
      background: linear-gradient(180deg, rgba(255,255,255,0.90), rgba(255,255,255,0.74));
      box-shadow: 0 16px 34px rgba(173, 117, 232, 0.16);
      border: 1px solid rgba(255,255,255,0.52);
    }
    .ref-live-pick::before {
      height: 5px;
      background: linear-gradient(90deg, #ff9dc8 0%, #cf9cff 54%, #9ec0ff 100%);
    }
    .ref-live-pick__badge {
      padding: 7px 12px;
      font-size: 0.7rem;
      letter-spacing: 0.1em;
    }
    .ref-live-pick__thumb {
      aspect-ratio: 0.9;
      border-radius: 18px;
      box-shadow: 0 10px 20px rgba(131, 89, 198, 0.12);
    }
    .ref-live-pick__body {
      gap: 8px;
    }
    .ref-live-pick__name {
      font-size: 1.18rem;
      letter-spacing: -0.02em;
    }
    .ref-live-pick__meta {
      font-size: 0.72rem;
      color: rgba(88, 60, 126, 0.68);
    }
    .ref-stat-list {
      gap: 7px;
    }
    .ref-stat-row {
      grid-template-columns: 44px minmax(0, 1fr) 24px;
      gap: 7px;
      font-size: 0.69rem;
    }
    .ref-stat-row__bar {
      height: 7px;
      background: rgba(203, 156, 255, 0.18);
    }
    .ref-live-pick__action {
      min-height: 38px;
      font-size: 0.82rem;
      box-shadow: inset 0 1px 0 rgba(255,255,255,0.28);
    }
    .ref-dashboard {
      gap: 7px;
      align-items: stretch;
    }
    .ref-panel {
      padding: 9px 10px;
      border-radius: 16px;
      background: linear-gradient(180deg, rgba(255,255,255,0.78), rgba(255,255,255,0.58));
      border: 1px solid rgba(255,255,255,0.40);
      box-shadow: 0 9px 18px rgba(171, 123, 226, 0.08);
    }
    .ref-panel::before {
      height: 3px;
      opacity: 1;
    }
    .ref-panel__head {
      margin-bottom: 6px;
      padding-bottom: 5px;
      border-bottom: 1px solid rgba(213, 176, 244, 0.22);
    }
    .ref-panel__head h2 {
      font-size: 0.82rem;
      letter-spacing: -0.02em;
    }
    .ref-panel__head a,
    .ref-panel__head span {
      font-size: 0.63rem;
      letter-spacing: -0.01em;
    }
    .ref-trainee-mini__avatar {
      box-shadow: 0 8px 14px rgba(174, 120, 222, 0.10);
    }
    .ref-list-item,
    .ref-feed-item,
    .ref-item-row {
      background: rgba(255,255,255,0.62);
      border: 1px solid rgba(255,255,255,0.30);
    }
    .ref-list-item:hover,
    .ref-feed-item:hover,
    .ref-item-row:hover,
    .ref-trainee-mini:hover {
      transform: translateY(-2px);
      box-shadow: 0 12px 18px rgba(169, 122, 218, 0.12);
      background: rgba(255,255,255,0.82);
    }
    .ref-panel-split--ranking .ref-list-item:first-child {
      background: linear-gradient(90deg, rgba(255, 243, 251, 0.95), rgba(242, 233, 255, 0.92));
      border-color: rgba(229, 170, 248, 0.38);
      box-shadow: 0 10px 18px rgba(190, 141, 231, 0.12);
    }
    .ref-panel-split--ranking .ref-list-item:first-child span,
    .ref-panel-split--ranking .ref-list-item:first-child strong,
    .ref-panel-split--ranking .ref-list-item:first-child small {
      color: #8a45d1;
    }
    .ref-panel--score-rank .ref-score-box strong {
      filter: drop-shadow(0 8px 16px rgba(224, 96, 173, 0.16));
    }
    @media (max-width: 1280px) {
      .ref-hero-card {
        grid-template-columns: 1fr 214px;
      }
      .ref-title {
        transform: none;
      }
      .ref-title__line {
        font-size: clamp(3.9rem, 9vw, 6rem);
      }
    }
    @media (max-width: 980px) {
      .ref-hero-card {
        grid-template-columns: 1fr;
      }
      .ref-title {
        transform: none;
        justify-content: center;
      }
      .ref-title__line {
        font-size: clamp(3.2rem, 10vw, 5rem);
      }
      .ref-live-pick {
        width: min(248px, 100%);
      }
    }


    .ref-title {
      letter-spacing: -0.072em;
      filter: drop-shadow(0 10px 18px rgba(184, 92, 214, 0.16));
    }
    .ref-title__line {
      background: linear-gradient(90deg, #ff9fda 0%, #f58ee8 34%, #df8fff 68%, #b986ff 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      color: transparent;
      -webkit-text-stroke: 1.8px rgba(247, 190, 244, 0.72);
      text-shadow:
        0 6px 14px rgba(205, 108, 205, 0.14),
        0 14px 22px rgba(143, 86, 210, 0.10);
      filter: drop-shadow(0 6px 10px rgba(188, 102, 224, 0.10));
    }
    .ref-title__line::after {
      background: none;
      opacity: 0;
    }
    .ref-title__line--second {
      letter-spacing: -0.088em;
    }
    @media (max-width: 980px) {
      .ref-title__line {
        -webkit-text-stroke: 1.3px rgba(247, 190, 244, 0.72);
      }
    }

    .ref-title {
      filter: drop-shadow(0 8px 18px rgba(177, 105, 219, 0.10));
      transform: none;
    }
    .ref-title::after {
      inset: 24% 14% 12%;
      background: radial-gradient(circle, rgba(233, 138, 220, 0.16), rgba(182, 129, 255, 0.08) 48%, transparent 76%);
      filter: blur(20px);
    }
    .ref-title__line {
      background: linear-gradient(90deg, #ff8fcf 0%, #f197e8 42%, #b992ff 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      color: transparent;
      -webkit-text-stroke: 1.2px rgba(255, 214, 242, 0.38);
      text-shadow: 0 6px 16px rgba(176, 105, 217, 0.10);
      filter: none;
    }
    .ref-title__line::after {
      content: none;
    }
    .ref-title__line--second {
      letter-spacing: -0.082em;
    }
    @media (max-width: 980px) {
      .ref-title__line {
        -webkit-text-stroke: 0.9px rgba(255, 214, 242, 0.34);
      }
    }

    .ref-title {
      perspective: 1200px;
    }
    .ref-title__line {
      position: relative;
      transform: translateZ(0);
      text-shadow:
        0 1px 0 rgba(255, 214, 242, 0.32),
        0 2px 0 rgba(238, 173, 246, 0.24),
        0 3px 0 rgba(215, 144, 241, 0.18),
        0 10px 18px rgba(173, 103, 217, 0.12);
    }
    .ref-title__line::before {
      content: attr(data-text);
      position: absolute;
      inset: 0;
      z-index: -1;
      background: linear-gradient(90deg, rgba(210, 118, 228, 0.92) 0%, rgba(175, 118, 243, 0.92) 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      color: transparent;
      transform: translate3d(0, 4px, 0);
      opacity: 0.55;
      filter: blur(0.4px);
      pointer-events: none;
    }
    @media (max-width: 980px) {
      .ref-title__line {
        text-shadow:
          0 1px 0 rgba(255, 214, 242, 0.26),
          0 2px 0 rgba(238, 173, 246, 0.18),
          0 8px 14px rgba(173, 103, 217, 0.10);
      }
      .ref-title__line::before {
        transform: translate3d(0, 3px, 0);
      }
    }

    .ref-hero-card {
      background: transparent !important;
      border: 0 !important;
      box-shadow: none !important;
    }
    .ref-hero-card::before {
      content: none !important;
    }
    .ref-hero-card::after {
      content: none !important;
      display: none !important;
    }

    .ref-hero-card {
      grid-template-columns: minmax(0, 1fr) 238px;
      gap: 14px;
      padding: 8px 18px 6px;
    }
    .ref-hero-card::after {
      content: none !important;
      display: none !important;
    }
    .ref-hero-card__center {
      padding: 0 18px 8px;
    }
    .ref-kicker {
      margin-bottom: 10px;
      font-size: clamp(0.72rem, 0.78vw, 0.84rem);
      letter-spacing: 0.5em;
      opacity: 0.96;
    }
    .ref-title {
      gap: 0.12em;
      letter-spacing: -0.078em;
      filter: drop-shadow(0 10px 18px rgba(174, 98, 219, 0.10));
    }
    .ref-title__line {
      font-size: clamp(4.7rem, 7.35vw, 7rem);
      line-height: 0.9;
      background: linear-gradient(90deg, #ff97d4 0%, #f3a0ee 46%, #be9dff 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      color: transparent;
      -webkit-text-stroke: 1px rgba(255, 218, 244, 0.26);
      text-shadow:
        0 1px 0 rgba(255, 223, 245, 0.16),
        0 5px 12px rgba(183, 111, 223, 0.12),
        0 12px 22px rgba(137, 91, 210, 0.08);
    }
    .ref-title__line::before {
      transform: translate3d(0, 3px, 0);
      opacity: 0.32;
      filter: blur(0.2px);
      background: linear-gradient(90deg, rgba(217, 108, 223, 0.88) 0%, rgba(171, 110, 241, 0.88) 100%);
    }
    .ref-title__line::after {
      content: none;
    }
    .ref-subtitle {
      margin-top: 10px;
      max-width: 960px;
      min-height: 0;
      padding: 0;
      border: 0;
      background: none;
      box-shadow: none;
      font-size: clamp(1rem, 1.05vw, 1.12rem);
      line-height: 1.12;
      letter-spacing: -0.02em;
      text-shadow: 0 2px 10px rgba(60, 21, 96, 0.18);
    }
    .ref-actions {
      margin-top: 18px;
      gap: 12px;
    }
    .ref-btn {
      min-height: 50px;
      padding: 0 32px;
      font-size: 0.9rem;
      letter-spacing: 0.14em;
      border-radius: 999px;
    }
    .ref-btn--primary {
      background: linear-gradient(90deg, #ff8fbf 0%, #c992ff 100%);
      box-shadow: 0 12px 22px rgba(213, 116, 205, 0.18), inset 0 1px 0 rgba(255,255,255,0.2);
    }
    .ref-btn--secondary {
      background: rgba(255,255,255,0.94);
      color: #5d3f87;
      box-shadow: 0 10px 18px rgba(91, 56, 140, 0.08);
    }
    .ref-live-pick {
      width: 238px;
      padding: 12px;
      border-radius: 26px;
      background: linear-gradient(180deg, rgba(255,255,255,0.92), rgba(255,255,255,0.78));
      border: 1px solid rgba(255,255,255,0.62);
      box-shadow: 0 16px 28px rgba(169, 117, 232, 0.14);
      gap: 10px;
    }
    .ref-live-pick::after {
      content: "";
      position: absolute;
      inset: 0;
      z-index: 0;
      border-radius: inherit;
      background: linear-gradient(160deg, rgba(255,255,255,0.28), rgba(255,255,255,0) 34%);
      pointer-events: none;
    }
    .ref-live-pick__badge {
      padding: 7px 13px;
      font-size: 0.7rem;
      letter-spacing: 0.08em;
      background: linear-gradient(90deg, #ff9bc5 0%, #dea1ff 100%);
      box-shadow: 0 8px 16px rgba(220, 142, 220, 0.16);
    }
    .ref-live-pick__thumb {
      aspect-ratio: 0.9;
      border-radius: 18px;
      box-shadow: 0 10px 18px rgba(144, 102, 205, 0.12);
    }
    .ref-live-pick__name {
      font-size: 1.24rem;
      letter-spacing: -0.025em;
      color: #37224e;
    }
    .ref-live-pick__meta {
      font-size: 0.74rem;
      color: rgba(92, 63, 132, 0.64);
    }
    .ref-stat-list {
      gap: 7px;
    }
    .ref-stat-row {
      grid-template-columns: 48px minmax(0, 1fr) 28px;
      gap: 7px;
      font-size: 0.7rem;
    }
    .ref-stat-row__bar {
      height: 7px;
      background: rgba(202, 158, 255, 0.18);
    }
    .ref-live-pick__action {
      min-height: 40px;
      font-size: 0.82rem;
      background: linear-gradient(90deg, #f7a1c5 0%, #cd9cff 100%);
      box-shadow: inset 0 1px 0 rgba(255,255,255,0.18);
    }
    .ref-dashboard {
      gap: 8px;
      grid-template-columns: 0.92fr 1.72fr 0.94fr;
    }
    .ref-panel {
      padding: 10px 11px;
      border-radius: 18px;
      background: linear-gradient(180deg, rgba(255,255,255,0.82), rgba(255,255,255,0.64));
      border: 1px solid rgba(255,255,255,0.44);
      box-shadow: 0 10px 18px rgba(171, 124, 226, 0.07);
    }
    .ref-panel__head {
      margin-bottom: 7px;
      padding-bottom: 6px;
      border-bottom: 1px solid rgba(224, 194, 248, 0.28);
    }
    .ref-panel__head h2 {
      font-size: 0.82rem;
      letter-spacing: -0.02em;
      color: #4b326e;
    }
    .ref-panel__head a,
    .ref-panel__head span {
      padding: 2px 7px;
      font-size: 0.6rem;
      color: #9b6ad7;
      background: rgba(255,255,255,0.72);
    }
    .ref-trainee-mini__avatar {
      width: 42px;
      height: 42px;
      box-shadow: 0 8px 14px rgba(184, 130, 225, 0.12);
    }
    .ref-trainee-mini strong,
    .ref-list-item strong,
    .ref-feed-item strong,
    .ref-item-row strong {
      color: #41295f;
    }
    .ref-list-item,
    .ref-feed-item,
    .ref-item-row {
      padding: 7px 8px;
      border-radius: 12px;
      background: rgba(255,255,255,0.68);
      border: 1px solid rgba(255,255,255,0.34);
    }
    .ref-panel-split--ranking .ref-list-item:first-child {
      background: linear-gradient(90deg, rgba(255, 239, 248, 0.96), rgba(243, 235, 255, 0.94));
      border-color: rgba(230, 177, 246, 0.42);
      box-shadow: 0 8px 14px rgba(188, 141, 230, 0.10);
    }
    .ref-panel-split--ranking .ref-list-item:first-child span,
    .ref-panel-split--ranking .ref-list-item:first-child strong,
    .ref-panel-split--ranking .ref-list-item:first-child small {
      color: #8d55d1;
    }
    .ref-feed-item strong,
    .ref-item-row strong {
      display: -webkit-box;
      -webkit-line-clamp: 1;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }
    .ref-chip-btn {
      min-width: 60px;
      min-height: 28px;
      font-size: 0.6rem;
      background: linear-gradient(90deg, #f4a8c9 0%, #cf9dff 100%);
      box-shadow: 0 6px 12px rgba(206, 134, 225, 0.12);
    }
    .ref-list-item:hover,
    .ref-feed-item:hover,
    .ref-item-row:hover,
    .ref-trainee-mini:hover {
      transform: translateY(-2px);
      box-shadow: 0 12px 18px rgba(189, 138, 228, 0.12);
      background: rgba(255,255,255,0.86);
    }
    @media (max-width: 1280px) {
      .ref-hero-card {
        grid-template-columns: 1fr 220px;
      }
      .ref-title__line {
        font-size: clamp(4rem, 9vw, 5.9rem);
      }
      .ref-dashboard {
        grid-template-columns: repeat(3, minmax(0, 1fr));
      }
    }
    @media (max-width: 980px) {
      .ref-hero-card {
        grid-template-columns: 1fr;
        padding: 6px 10px 0;
      }
      .ref-hero-card__center {
        padding: 0 2px 4px;
      }
      .ref-title__line {
        font-size: clamp(3.2rem, 10vw, 4.9rem);
      }
      .ref-subtitle {
        white-space: normal;
      }
      .ref-live-pick {
        width: min(250px, 100%);
      }
    }

    body.page-main-reference .game-modal {
      position: fixed;
      inset: 0;
      z-index: 10040;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    body.page-main-reference .game-modal.is-open {
      display: flex;
    }
    body.page-main-reference .game-modal__dim {
      position: absolute;
      inset: 0;
      background: rgba(16, 4, 30, 0.6);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
    }
    body.page-main-reference .game-modal__panel {
      position: relative;
      z-index: 1;
      width: min(880px, 100%);
      padding: 32px;
      border-radius: 28px;
      background: linear-gradient(180deg, rgba(255,255,255,0.98), rgba(249,245,255,0.96));
      border: 1px solid rgba(236, 72, 153, 0.12);
      box-shadow: 0 30px 90px rgba(16, 4, 30, 0.26);
    }
    body.page-main-reference .game-modal__close {
      position: absolute;
      top: 18px;
      right: 18px;
      width: 42px;
      height: 42px;
      border: 0;
      border-radius: 14px;
      background: rgba(139, 92, 246, 0.08);
      color: #4c1d95;
      font-size: 22px;
      cursor: pointer;
    }
    body.page-main-reference .game-modal__head {
      text-align: center;
    }
    body.page-main-reference .game-modal__eyebrow {
      font-family: "Orbitron", sans-serif;
      font-size: 11px;
      letter-spacing: 0.22em;
      color: #db2777;
    }
    body.page-main-reference .game-modal__title {
      margin: 14px 0 10px;
      font-size: clamp(1.4rem, 3vw, 2rem);
      font-weight: 900;
      color: #241432;
    }
    body.page-main-reference .game-modal__desc,
    body.page-main-reference .game-modal__status {
      color: rgba(58, 35, 79, 0.72);
      line-height: 1.7;
    }
    body.page-main-reference .game-select-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 16px;
      margin-top: 24px;
    }
    body.page-main-reference .group-option {
      position: relative;
      display: block;
      padding: 24px 18px;
      border-radius: 22px;
      background: rgba(255,255,255,0.92);
      border: 1px solid rgba(139, 92, 246, 0.1);
      text-align: center;
      cursor: pointer;
      transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
    }
    body.page-main-reference .group-option:hover,
    body.page-main-reference .group-option.is-selected {
      transform: translateY(-2px);
      border-color: rgba(236, 72, 153, 0.28);
      box-shadow: 0 18px 42px rgba(168, 85, 247, 0.14);
    }
    body.page-main-reference .group-option input {
      position: absolute;
      opacity: 0;
      pointer-events: none;
    }
    body.page-main-reference .group-option__badge {
      width: 56px;
      height: 56px;
      margin: 0 auto 14px;
      border-radius: 50%;
      display: grid;
      place-items: center;
      background: linear-gradient(135deg, rgba(244, 114, 182, 0.16), rgba(139, 92, 246, 0.18));
      color: #7c3aed;
      font-family: "Orbitron", sans-serif;
      font-weight: 900;
    }
    body.page-main-reference .group-option__name {
      font-size: 1.05rem;
      font-weight: 900;
      color: #241432;
    }
    body.page-main-reference .group-option__meta,
    body.page-main-reference .group-option__hint {
      margin-top: 8px;
      font-size: 13px;
      line-height: 1.65;
      color: rgba(58, 35, 79, 0.72);
    }
    body.page-main-reference .group-option__chip {
      display: inline-flex;
      margin-top: 14px;
      padding: 8px 12px;
      border-radius: 999px;
      background: rgba(244, 114, 182, 0.08);
      color: #db2777;
      font-family: "Orbitron", sans-serif;
      font-size: 10px;
      letter-spacing: 0.14em;
    }
    body.page-main-reference .game-modal__actions {
      margin-top: 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }
    body.page-main-reference .game-modal__btns {
      display: flex;
      gap: 10px;
    }
    body.page-main-reference .gm-btn {
      min-height: 46px;
      padding: 0 18px;
      border-radius: 999px;
      border: 0;
      font-weight: 800;
      cursor: pointer;
    }
    body.page-main-reference .gm-btn--ghost {
      background: rgba(139, 92, 246, 0.08);
      color: #4c1d95;
    }
    body.page-main-reference .gm-btn--primary {
      background: linear-gradient(135deg, #f472b6, #8b5cf6);
      color: #fff;
    }
    @media (max-width: 820px) {
      body.page-main-reference .game-select-grid {
        grid-template-columns: 1fr;
      }
      body.page-main-reference .game-modal__actions {
        flex-direction: column;
        align-items: stretch;
      }
      body.page-main-reference .game-modal__btns {
        justify-content: stretch;
      }
      body.page-main-reference .gm-btn {
        width: 100%;
      }
    }


    .ref-title__line::before {
      content: none !important;
      display: none !important;
    }
    .ref-title__line {
      filter: none !important;
      text-shadow: 0 6px 14px rgba(176, 105, 217, 0.10) !important;
    }

    .ref-hero-card__center {
      transform: translateY(96px);
    }
    @media (max-width: 980px) {
      .ref-hero-card__center {
        transform: translateY(40px);
      }
    }

    .ref-title {
      letter-spacing: -0.076em;
      filter: drop-shadow(0 10px 20px rgba(176, 103, 220, 0.12));
    }
    .ref-title__line {
      -webkit-text-stroke: 1.35px rgba(255, 226, 246, 0.34) !important;
      text-shadow:
        0 1px 0 rgba(255, 229, 247, 0.34),
        0 2px 0 rgba(248, 194, 246, 0.24),
        0 3px 0 rgba(228, 160, 244, 0.18),
        0 10px 18px rgba(171, 101, 216, 0.14),
        0 18px 26px rgba(143, 91, 211, 0.08) !important;
      filter: drop-shadow(0 4px 10px rgba(203, 129, 226, 0.08)) !important;
    }
    .ref-title__line::before {
      content: none !important;
      display: none !important;
    }
    .ref-title__line::after {
      content: "" !important;
      display: block !important;
      position: absolute;
      left: 0.14em;
      right: 0.14em;
      top: 0.14em;
      height: 0.11em;
      border-radius: 999px;
      background: linear-gradient(90deg, rgba(255,255,255,0.40), rgba(255,255,255,0.10) 52%, rgba(255,255,255,0));
      opacity: 0.26;
      pointer-events: none;
    }
    .ref-kicker {
      text-shadow: 0 2px 10px rgba(67, 23, 105, 0.30);
    }
    .ref-subtitle {
      color: rgba(255,255,255,0.99);
      text-shadow: 0 2px 10px rgba(49, 18, 76, 0.30), 0 0 12px rgba(255,255,255,0.08);
    }
    @media (max-width: 980px) {
      .ref-title__line {
        -webkit-text-stroke: 1px rgba(255, 226, 246, 0.32) !important;
        text-shadow:
          0 1px 0 rgba(255, 229, 247, 0.28),
          0 2px 0 rgba(248, 194, 246, 0.18),
          0 8px 14px rgba(171, 101, 216, 0.12) !important;
      }
    }

    .ref-title {
      background: none !important;
      -webkit-text-fill-color: initial !important;
      color: inherit !important;
      filter: none !important;
      text-shadow: none !important;
    }
    .ref-title__line {
      display: inline-block !important;
      padding: 0 !important;
      -webkit-text-stroke: 0.8px rgba(255, 226, 244, 0.28) !important;
      text-shadow:
        0 1px 0 rgba(255, 220, 244, 0.28),
        0 2px 0 rgba(239, 187, 244, 0.18),
        0 3px 6px rgba(178, 110, 219, 0.14) !important;
      filter: none !important;
    }
    .ref-title__line::before,
    .ref-title__line::after,
    .ref-title::before,
    .ref-title::after {
      content: none !important;
      display: none !important;
      background: none !important;
    }
    @media (max-width: 980px) {
      .ref-title__line {
        -webkit-text-stroke: 0.6px rgba(255, 226, 244, 0.24) !important;
        text-shadow:
          0 1px 0 rgba(255, 220, 244, 0.22),
          0 2px 4px rgba(178, 110, 219, 0.12) !important;
      }
    }


    .ref-title {
      perspective: 1200px;
      transform-style: preserve-3d;
    }
    .ref-title__line {
      position: relative;
      display: inline-block !important;
      transform: translateZ(0);
      -webkit-text-stroke: 0.9px rgba(255, 225, 246, 0.30) !important;
      text-shadow:
        0 1px 0 rgba(255, 232, 248, 0.38),
        0 2px 0 rgba(244, 196, 246, 0.30),
        0 3px 0 rgba(229, 169, 244, 0.24),
        0 4px 0 rgba(212, 144, 241, 0.18),
        0 10px 18px rgba(166, 100, 214, 0.18) !important;
      filter: none !important;
    }
    .ref-title__line::before {
      content: attr(data-text) !important;
      position: absolute;
      inset: 0;
      z-index: -1;
      background: linear-gradient(180deg, rgba(205, 112, 224, 0.96) 0%, rgba(164, 101, 225, 0.96) 100%) !important;
      -webkit-background-clip: text !important;
      background-clip: text !important;
      -webkit-text-fill-color: transparent !important;
      color: transparent !important;
      transform: translate3d(0, 4px, -1px);
      opacity: 0.88;
      filter: blur(0.25px);
      pointer-events: none;
    }
    .ref-title__line::after {
      content: "" !important;
      position: absolute;
      left: 0.14em;
      right: 0.14em;
      top: 0.12em;
      height: 0.10em;
      border-radius: 999px;
      background: linear-gradient(90deg, rgba(255,255,255,0.34), rgba(255,255,255,0.08) 58%, rgba(255,255,255,0));
      opacity: 0.24;
      pointer-events: none;
    }
    @media (max-width: 980px) {
      .ref-title__line {
        -webkit-text-stroke: 0.7px rgba(255, 225, 246, 0.26) !important;
        text-shadow:
          0 1px 0 rgba(255, 232, 248, 0.30),
          0 2px 0 rgba(244, 196, 246, 0.22),
          0 3px 0 rgba(229, 169, 244, 0.16),
          0 8px 14px rgba(166, 100, 214, 0.14) !important;
      }
      .ref-title__line::before {
        transform: translate3d(0, 3px, -1px);
      }
    }

    /* LIVE PICK만 살짝 아래로 / 히어로~하단 카드 간격은 .ref-stage gap + page-main-reference 오버라이드 */
    @media (min-width: 981px) {
      .ref-live-pick {
        margin-top: clamp(38px, 4.8vh, 70px);
      }
      .ref-dashboard {
        margin-top: clamp(30px, 4.2vh, 68px);
      }
      body.page-main-reference .ref-dashboard {
        margin-top: 0 !important;
      }
    }
    @media (max-width: 980px) {
      .ref-live-pick {
        margin-top: clamp(26px, 4vh, 46px);
      }
      .ref-dashboard {
        margin-top: clamp(18px, 3.2vh, 34px);
      }
      body.page-main-reference .ref-dashboard {
        margin-top: 0 !important;
      }
    }

    .ref-main__overlay,
    .ref-main__spark {
      display: none !important;
    }
    .ref-main__bg img {
      position: absolute !important;
      inset: 0 !important;
      filter: none !important;
      -webkit-filter: none !important;
      width: 100% !important;
      height: 100% !important;
      object-fit: cover !important;
      object-position: center 32% !important;
      transform: translateZ(0) !important;
      backface-visibility: hidden !important;
    }

    /*
      레퍼런스(2번) 정합: 135deg 대각 (#f9b4c4 → #d1b3f0), 타이트 트래킹, 얇은 라이트 스트로크,
      아래로 번지는 보라 그림자, 글자 살짝 투명해 배경 비침, NEXT의 「T」우상단 스파클
    */
    body.page-main-reference .ref-title-stack {
      --ref-title-pink-1: #f7b2d7;
      --ref-title-pink-2: #f3a4d6;
      --ref-title-lilac-1: #e4a7e8;
      --ref-title-lilac-2: #c99be7;
      --ref-title-purple-deep: #8f63b8;
      --ref-title-flare: rgba(255, 248, 255, 0.96);
      --ref-title-flare-pink: rgba(243, 110, 214, 0.74);
      position: relative;
      z-index: 2;
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      width: 100%;
      max-width: min(100%, 980px);
      margin: 0 auto;
      gap: 14px;
    }
    body.page-main-reference .ref-title-stack::before {
      content: "";
      position: absolute;
      inset: -26px -38px -22px;
      z-index: -2;
      border-radius: 999px;
      background:
        radial-gradient(circle at 50% 46%, rgba(66, 33, 97, 0.22) 0%, rgba(66, 33, 97, 0.16) 34%, rgba(66, 33, 97, 0.08) 56%, rgba(66, 33, 97, 0) 78%);
      filter: blur(12px);
      opacity: 0.85;
      pointer-events: none;
    }
    /* THE / NEXT / DEBUT 글자 뒤: 큰 blur+무한 애니메이션은 GPU 부담 → 정적 후광만 */
    body.page-main-reference .ref-title-stack::after {
      content: "";
      position: absolute;
      left: 50%;
      top: 62%;
      width: min(96%, 800px);
      height: clamp(150px, 24vh, 280px);
      transform: translate(-50%, -50%);
      z-index: -1;
      pointer-events: none;
      border-radius: 50%;
      background:
        radial-gradient(ellipse 52% 58% at 50% 50%, rgba(255, 255, 255, 0.62) 0%, rgba(255, 224, 248, 0.42) 18%, rgba(232, 196, 255, 0.28) 38%, rgba(160, 110, 210, 0.12) 58%, rgba(80, 40, 120, 0) 78%);
      filter: blur(22px);
      opacity: 0.9;
    }
    /* 타이틀 뒤 글로우가 카드 박스·contain에 잘리지 않도록 */
    body.page-main-reference .ref-hero-card {
      overflow: visible;
      contain: layout style;
    }
    body.page-main-reference .ref-hero-card__center {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: flex-start;
      min-height: clamp(360px, 56vh, 520px);
      padding-top: clamp(56px, 9vh, 112px);
      padding-bottom: clamp(28px, 5vh, 56px);
    }
    body.page-main-reference .ref-title-eyebrow {
      margin: 0;
      padding: 0;
      font-family: "Montserrat", system-ui, sans-serif;
      font-weight: 700;
      font-size: clamp(0.68rem, 1vw, 0.82rem);
      letter-spacing: 0.44em;
      text-indent: 0.44em;
      text-transform: uppercase;
      color: rgba(255, 252, 255, 0.92);
      text-shadow:
        0 1px 0 rgba(255, 255, 255, 0.42),
        0 2px 0 rgba(120, 80, 160, 0.18),
        0 3px 8px rgba(45, 28, 78, 0.35),
        0 0 28px rgba(255, 200, 245, 0.22);
      opacity: 0;
      transform: translateY(18px);
      animation: refTitleEntrance 0.95s ease-out 0.08s forwards;
    }
    body.page-main-reference .ref-title {
      margin: 0 !important;
      padding: 0 !important;
      display: block !important;
      text-align: center !important;
      font-family: "Montserrat", system-ui, sans-serif !important;
      font-weight: 900 !important;
      letter-spacing: -0.03em !important;
      line-height: 1 !important;
      text-transform: uppercase !important;
      background: none !important;
      perspective: none !important;
      transform-style: flat !important;
      -webkit-font-smoothing: antialiased;
      isolation: isolate;
      filter: none !important;
      opacity: 0;
      transform: translateY(22px);
      animation: refTitleEntrance 1.05s ease-out 0.16s forwards;
      white-space: nowrap !important;
      position: relative !important;
    }
    body.page-main-reference .ref-title__line--full {
      position: relative !important;
      display: inline-block !important;
      z-index: 2 !important;
    }
    body.page-main-reference .ref-title__line--full::after {
      content: none !important;
      display: none !important;
    }
    body.page-main-reference .ref-title__line {
      display: inline !important;
      font-family: "Montserrat", system-ui, sans-serif !important;
      font-weight: 900 !important;
      font-size: clamp(3.65rem, 8.5vw, 7.5rem) !important;
      line-height: 1.05 !important;
      letter-spacing: -0.015em !important;
      text-transform: uppercase !important;
      /* 밝고 선명한 핑크 계열(명도 유지) — 진한 로즈/짙은 그림자 제거로 칙칙함 방지 */
      background:
        linear-gradient(
          180deg,
          #ffffff 0%,
          #fff2f8 3%,
          rgb(255, 155, 200) 10%,
          rgb(255, 130, 185) 20%,
          rgb(252, 165, 205) 34%,
          rgb(248, 175, 210) 46%,
          rgb(242, 165, 200) 58%,
          rgb(245, 185, 215) 70%,
          rgb(252, 215, 232) 84%,
          rgb(255, 248, 252) 95%,
          #ffffff 100%
        ) !important;
      background-repeat: no-repeat !important;
      background-size: 100% 100% !important;
      background-position: center center !important;
      -webkit-background-clip: text !important;
      background-clip: text !important;
      -webkit-text-fill-color: transparent !important;
      color: transparent !important;
      paint-order: stroke fill;
      -webkit-text-stroke: 0.45px rgba(220, 100, 150, 0.22) !important;
      /* 입체: 블러 글로우 제거 → 블러 0으로만 층 쌓기 + 위쪽 1px 하이라이트 */
      text-shadow:
        0 -1px 0 rgba(255, 255, 255, 0.75),
        0 1px 0 rgba(235, 145, 180, 0.55),
        0 2px 0 rgba(218, 128, 168, 0.48),
        0 3px 0 rgba(200, 112, 152, 0.4),
        0 4px 0 rgba(185, 98, 138, 0.32),
        0 5px 0 rgba(165, 82, 118, 0.2) !important;
      filter: none !important;
      opacity: 1 !important;
    }
    /* 전광판 LED: 글자 순차 점등(색은 위 그라데이션 유지) */
    body.page-main-reference .ref-title__line--led {
      text-shadow: none !important;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led {
      display: inline-block;
      animation: refJumbotronLed 6s linear infinite;
      text-shadow:
        0 -1px 0 rgba(255, 255, 255, 0.68),
        0 0 14px rgba(255, 215, 235, 0.48),
        0 0 24px rgba(255, 188, 215, 0.34),
        0 2px 0 rgba(235, 160, 190, 0.4) !important;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(1) {
      animation-delay: 0s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(2) {
      animation-delay: 0.2s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(3) {
      animation-delay: 0.4s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(4) {
      animation-delay: 0.6s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(5) {
      animation-delay: 0.8s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(6) {
      animation-delay: 1s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(7) {
      animation-delay: 1.2s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(8) {
      animation-delay: 1.4s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(9) {
      animation-delay: 1.6s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(10) {
      animation-delay: 1.8s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(11) {
      animation-delay: 2s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(12) {
      animation-delay: 2.2s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(13) {
      animation-delay: 2.4s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(14) {
      animation-delay: 2.6s;
    }
    body.page-main-reference .ref-title__line--led .ref-title__led:nth-child(15) {
      animation-delay: 2.8s;
    }
    @keyframes refJumbotronLed {
      /* 켜짐: 전체적으로 한 단계 낮춤 */
      0%,
      1.5%,
      5%,
      76%,
      81%,
      89%,
      94%,
      100% {
        filter: brightness(1.09) saturate(1.05);
        text-shadow:
          0 -1px 0 rgba(255, 255, 255, 0.68),
          0 0 14px rgba(255, 215, 235, 0.48),
          0 0 24px rgba(255, 188, 215, 0.34),
          0 2px 0 rgba(235, 160, 190, 0.4) !important;
      }
      2.5% {
        filter: brightness(1.15) saturate(1.07);
        text-shadow:
          0 -1px 0 rgba(255, 255, 255, 0.78),
          0 0 17px rgba(255, 222, 240, 0.55),
          0 0 28px rgba(255, 195, 220, 0.4),
          0 2px 0 rgba(235, 165, 192, 0.44) !important;
      }
      /* 깜빡임: 구간을 넓혀 천천히(6초 기준 약 0.12~0.18초 유지) */
      77%,
      78%,
      79.5% {
        filter: brightness(0.78) saturate(0.95);
        text-shadow:
          0 -1px 0 rgba(255, 255, 255, 0.46),
          0 1px 0 rgba(190, 125, 158, 0.32),
          0 2px 0 rgba(175, 110, 145, 0.22) !important;
      }
      90%,
      91%,
      92.2% {
        filter: brightness(0.78) saturate(0.95);
        text-shadow:
          0 -1px 0 rgba(255, 255, 255, 0.46),
          0 1px 0 rgba(190, 125, 158, 0.32),
          0 2px 0 rgba(175, 110, 145, 0.22) !important;
      }
    }
    @media (prefers-reduced-motion: reduce) {
      body.page-main-reference .ref-title__line--led .ref-title__led {
        animation: none !important;
        filter: none !important;
      }
      body.page-main-reference .ref-title__line--led {
        text-shadow:
          0 -1px 0 rgba(255, 255, 255, 0.75),
          0 1px 0 rgba(235, 145, 180, 0.55),
          0 2px 0 rgba(218, 128, 168, 0.48),
          0 3px 0 rgba(200, 112, 152, 0.4),
          0 4px 0 rgba(185, 98, 138, 0.32),
          0 5px 0 rgba(165, 82, 118, 0.2) !important;
      }
    }
    body.page-main-reference .ref-title::before,
    body.page-main-reference .ref-title::after {
      content: none !important;
      display: none !important;
    }
    body.page-main-reference .ref-title__flare {
      display: none !important;
    }
    body.page-main-reference .ref-title__line:not(.ref-title__line--full)::before,
    body.page-main-reference .ref-title__line:not(.ref-title__line--full)::after {
      content: none !important;
      display: none !important;
    }
    @keyframes refTitleEntrance {
      from {
        opacity: 0;
        transform: translateY(22px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    @media (prefers-reduced-motion: reduce) {
      body.page-main-reference .ref-title-stack::after {
        opacity: 0.82;
        transform: translate(-50%, -50%);
      }
    }
    @media (max-width: 980px) {
      body.page-main-reference .ref-title-stack::before {
        inset: -18px -18px -14px;
        filter: blur(14px);
      }
      body.page-main-reference .ref-title-stack::after {
        top: 64%;
        width: min(100%, 560px);
        height: clamp(120px, 20vh, 200px);
        filter: blur(18px);
      }
      body.page-main-reference .ref-hero-card__center {
        min-height: auto;
        padding-top: clamp(32px, 7vh, 64px);
        padding-bottom: clamp(24px, 5vh, 42px);
      }
      body.page-main-reference .ref-title-eyebrow {
        letter-spacing: 0.32em;
        text-indent: 0.32em;
        font-size: clamp(0.58rem, 2.8vw, 0.72rem);
      }
      body.page-main-reference .ref-title__line {
        font-size: clamp(2.2rem, 9vw, 4.4rem) !important;
        letter-spacing: -0.02em !important;
      }
    }

    body.page-main-reference .ref-hero-card__center .ref-subtitle {
      margin-top: clamp(28px, 3.6vh, 48px) !important;
      margin-bottom: 0 !important;
      margin-left: auto !important;
      margin-right: auto !important;
      padding: 0 !important;
      max-width: min(96%, 820px) !important;
      min-height: 0 !important;
      border: 0 !important;
      border-radius: 0 !important;
      background: transparent !important;
      box-shadow: none !important;
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
      color: rgba(255, 255, 255, 0.98) !important;
      font-size: clamp(1.18rem, 2vw, 1.72rem) !important;
      font-weight: 700 !important;
      line-height: 1.55 !important;
      text-shadow:
        0 0 2px rgba(0, 0, 0, 0.85),
        0 1px 3px rgba(0, 0, 0, 0.75),
        0 2px 10px rgba(0, 0, 0, 0.55),
        0 4px 22px rgba(20, 6, 42, 0.5),
        0 0 32px rgba(35, 12, 58, 0.45) !important;
    }
    body.page-main-reference .ref-hero-card__center .ref-subtitle + .ref-subtitle {
      margin-top: 6px !important;
      font-size: clamp(1.42rem, 2.9vw, 2.3rem) !important;
      line-height: 1.54 !important;
      color: rgba(255, 255, 255, 0.94) !important;
    }
    body.page-main-reference .ref-subtitle--typewriter {
      position: relative;
      min-height: calc(1.5em * 3);
    }
    body.page-main-reference .ref-typewriter__line {
      display: block;
    }
    body.page-main-reference .ref-typewriter__chunk {
      white-space: pre;
    }
    body.page-main-reference .ref-typewriter__caret {
      display: inline-block;
      width: 0.08em;
      height: 1em;
      margin-left: 0.08em;
      vertical-align: -0.08em;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.9);
      box-shadow: 0 0 10px rgba(255, 255, 255, 0.28);
      animation: refTypeCaretBlink 0.9s step-end infinite;
    }
    body.page-main-reference .ref-subtitle--typewriter.is-complete .ref-typewriter__caret {
      opacity: 0;
      animation: none;
    }
    body.page-main-reference .ref-subtitle-em {
      display: inline-block;
      margin: 0 0.04em;
      padding: 0;
      font-size: 1em;
      font-weight: 800;
      line-height: inherit;
      color: rgba(255, 255, 255, 0.98);
      background: none;
      -webkit-background-clip: border-box;
      background-clip: border-box;
      -webkit-text-fill-color: currentColor;
      text-shadow:
        0 0 2px rgba(0, 0, 0, 0.85),
        0 1px 3px rgba(0, 0, 0, 0.75),
        0 2px 10px rgba(0, 0, 0, 0.55),
        0 4px 22px rgba(20, 6, 42, 0.5);
      vertical-align: baseline;
    }
    @keyframes refTypeCaretBlink {
      0%, 45% {
        opacity: 1;
      }
      46%, 100% {
        opacity: 0;
      }
    }

    body.page-main-reference .ref-actions {
      margin-top: clamp(20px, 3.2vh, 30px) !important;
      gap: 16px !important;
    }
    body.page-main-reference .ref-btn {
      position: relative;
      isolation: isolate;
      min-width: clamp(204px, 17vw, 236px) !important;
      min-height: 56px !important;
      padding: 0 30px !important;
      border: 1px solid rgba(255,255,255,0.58) !important;
      border-radius: 999px !important;
      overflow: hidden;
      font-family: "Orbitron", sans-serif !important;
      font-size: 0.96rem !important;
      font-weight: 800 !important;
      letter-spacing: 0.09em !important;
      text-transform: uppercase;
      backdrop-filter: blur(12px) saturate(120%);
      -webkit-backdrop-filter: blur(12px) saturate(120%);
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.82),
        inset 0 -1px 0 rgba(255,255,255,0.12),
        0 0 0 2px rgba(255, 214, 246, 0.18),
        0 12px 28px rgba(205, 131, 221, 0.2) !important;
      transition: transform 0.22s ease, box-shadow 0.22s ease, filter 0.22s ease !important;
    }
    body.page-main-reference .ref-btn::before,
    body.page-main-reference .ref-btn::after {
      content: "";
      position: absolute;
      pointer-events: none;
      inset: 0;
      border-radius: inherit;
    }
    body.page-main-reference .ref-btn::before {
      inset: 2px;
      background:
        linear-gradient(180deg, rgba(255,255,255,0.38), rgba(255,255,255,0.04) 42%, rgba(255,255,255,0.14) 100%),
        radial-gradient(circle at 20% 18%, rgba(255,255,255,0.55), transparent 26%);
      z-index: -1;
    }
    body.page-main-reference .ref-btn::after {
      inset: 3px auto 3px 12px;
      width: 42%;
      background: linear-gradient(105deg, rgba(255,255,255,0.34), rgba(255,255,255,0.06) 54%, rgba(255,255,255,0) 100%);
      transform: skewX(-18deg);
      opacity: 0.8;
      z-index: 0;
    }
    body.page-main-reference .ref-btn--primary {
      color: #fff !important;
      background:
        linear-gradient(90deg, rgba(255,150,201,0.96) 0%, rgba(221,150,255,0.98) 52%, rgba(190,150,255,0.94) 100%) !important;
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.84),
        inset 0 -1px 0 rgba(255,255,255,0.12),
        0 0 0 2px rgba(255, 218, 245, 0.18),
        0 14px 30px rgba(219, 121, 210, 0.28),
        0 0 28px rgba(232, 162, 244, 0.2) !important;
    }
    body.page-main-reference .ref-btn--secondary {
      color: #fff !important;
      background:
        linear-gradient(90deg, rgba(204,164,255,0.95) 0%, rgba(194,151,255,0.98) 48%, rgba(224,167,255,0.92) 100%) !important;
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.8),
        inset 0 -1px 0 rgba(255,255,255,0.1),
        0 0 0 2px rgba(225, 208, 255, 0.16),
        0 14px 28px rgba(172, 122, 231, 0.24),
        0 0 24px rgba(208, 181, 255, 0.18) !important;
    }
    body.page-main-reference .ref-btn:hover {
      transform: translateY(-3px) scale(1.01) !important;
      filter: brightness(1.04);
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.9),
        inset 0 -1px 0 rgba(255,255,255,0.14),
        0 0 0 2px rgba(255, 227, 248, 0.22),
        0 18px 34px rgba(213, 132, 226, 0.3),
        0 0 34px rgba(240, 193, 255, 0.22) !important;
    }
    body.page-main-reference .ref-btn span,
    body.page-main-reference .ref-btn {
      text-shadow: 0 1px 0 rgba(255,255,255,0.18), 0 2px 10px rgba(128, 56, 165, 0.2);
    }
    @media (max-width: 980px) {
      body.page-main-reference .ref-actions {
        gap: 12px !important;
      }
      body.page-main-reference .ref-btn {
        min-width: clamp(180px, 42vw, 220px) !important;
        min-height: 52px !important;
        font-size: 0.88rem !important;
        letter-spacing: 0.08em !important;
      }
    }
    @media (max-width: 640px) {
      body.page-main-reference .ref-btn {
        min-width: 100% !important;
        min-height: 50px !important;
        padding: 0 22px !important;
        font-size: 0.82rem !important;
      }
    }

    @keyframes refAmbientTwinkle {
      0%, 100% {
        opacity: 0.48;
        transform: scale(1) translate3d(0, 0, 0);
      }
      50% {
        opacity: 0.9;
        transform: scale(1.06) translate3d(0, -4px, 0);
      }
    }
    @keyframes refShineSweep {
      0% {
        opacity: 0;
        transform: translate3d(-18%, -8%, 0) rotate(-12deg);
      }
      20% {
        opacity: 0.18;
      }
      55% {
        opacity: 0.34;
      }
      100% {
        opacity: 0;
        transform: translate3d(18%, 10%, 0) rotate(-12deg);
      }
    }

    body.page-main-reference .ref-main::before,
    body.page-main-reference .ref-main::after {
      content: "";
      position: absolute;
      inset: 0;
      pointer-events: none;
      z-index: 1;
    }
    body.page-main-reference .ref-main::before {
      background:
        radial-gradient(circle at 9% 18%, rgba(255,255,255,0.92) 0 1.5px, transparent 3px),
        radial-gradient(circle at 18% 54%, rgba(255,240,255,0.9) 0 1px, transparent 3px),
        radial-gradient(circle at 31% 22%, rgba(255,255,255,0.78) 0 1px, transparent 2.5px),
        radial-gradient(circle at 44% 68%, rgba(255,236,252,0.88) 0 1.4px, transparent 3px),
        radial-gradient(circle at 57% 18%, rgba(255,255,255,0.9) 0 1.2px, transparent 3px),
        radial-gradient(circle at 72% 42%, rgba(255,240,250,0.86) 0 1px, transparent 2.5px),
        radial-gradient(circle at 83% 17%, rgba(255,255,255,0.92) 0 1.6px, transparent 3px),
        radial-gradient(circle at 92% 76%, rgba(255,244,252,0.82) 0 1.2px, transparent 3px);
      /* 배경 일러스트 위 스파클: 너무 진하면 디테일이 뭉개져 보임 */
      opacity: 0.42;
      mix-blend-mode: screen;
      animation: refAmbientTwinkle 5.8s ease-in-out infinite;
    }
    body.page-main-reference .ref-main::after {
      background:
        radial-gradient(circle at 14% 34%, rgba(255,255,255,0.26), transparent 16%),
        radial-gradient(circle at 84% 26%, rgba(255,232,249,0.22), transparent 18%),
        radial-gradient(circle at 68% 78%, rgba(255,255,255,0.2), transparent 16%);
      opacity: 0.55;
    }

    body.page-main-reference .ref-live-pick {
      isolation: isolate;
      overflow: visible !important;
      width: 254px !important;
      padding: 8px 10px 9px !important;
      border-radius: 30px !important;
      background:
        linear-gradient(180deg, rgba(255,255,255,0.96), rgba(255,255,255,0.8) 54%, rgba(249,240,255,0.72) 100%) !important;
      border: 1px solid rgba(255,255,255,0.82) !important;
      box-shadow:
        16px -10px 0 rgba(255, 222, 247, 0.34),
        28px -18px 0 rgba(228, 182, 255, 0.2),
        0 18px 34px rgba(169, 117, 232, 0.16) !important;
    }
    body.page-main-reference .ref-live-pick::before {
      left: 12px;
      right: 12px;
      top: 6px;
      height: 26px;
      border-radius: 999px;
      background: linear-gradient(90deg, rgba(255,157,212,0.95) 0%, rgba(229,163,255,0.96) 54%, rgba(190,178,255,0.92) 100%);
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.65),
        0 0 18px rgba(239, 164, 255, 0.3);
    }
    body.page-main-reference .ref-live-pick::after {
      border-radius: inherit;
      background:
        linear-gradient(160deg, rgba(255,255,255,0.3), rgba(255,255,255,0) 34%),
        radial-gradient(circle at 86% 10%, rgba(255,255,255,0.82) 0 2px, transparent 8px),
        radial-gradient(circle at 12% 82%, rgba(255,244,252,0.28), transparent 24%);
    }
    body.page-main-reference .ref-live-pick > * {
      position: relative;
      z-index: 2;
    }
    body.page-main-reference .ref-live-pick__badge {
      justify-self: stretch !important;
      min-height: 26px;
      padding: 0 14px !important;
      display: inline-flex !important;
      align-items: center !important;
      border-radius: 999px !important;
      background: transparent !important;
      box-shadow: none !important;
      color: #fff !important;
      font-size: 0.84rem !important;
      letter-spacing: 0.08em !important;
      z-index: 3 !important;
    }
    body.page-main-reference .ref-live-pick__carousel {
      margin-top: 0;
    }
    body.page-main-reference .ref-live-pick__slide {
      gap: 8px !important;
    }
    body.page-main-reference .ref-live-pick__carousel::before,
    body.page-main-reference .ref-live-pick__carousel::after {
      content: "";
      position: absolute;
      pointer-events: none;
      z-index: 4;
      border-radius: 999px;
    }
    body.page-main-reference .ref-live-pick__carousel::before {
      top: 2%;
      right: -8%;
      width: 56%;
      height: 22%;
      background: linear-gradient(120deg, rgba(255,255,255,0.06), rgba(255,255,255,0.34), rgba(255,255,255,0.04));
      filter: blur(2px);
      transform: rotate(-10deg);
      opacity: 0.55;
      animation: refShineSweep 4.8s ease-in-out infinite;
    }
    body.page-main-reference .ref-live-pick__carousel::after {
      left: -10%;
      bottom: 16%;
      width: 34%;
      height: 18%;
      background: radial-gradient(circle, rgba(255,255,255,0.32) 0%, rgba(255,255,255,0) 72%);
      filter: blur(6px);
      opacity: 0.8;
    }
    @media (max-width: 980px) {
      body.page-main-reference .ref-live-pick {
        margin-top: clamp(34px, 4.4vh, 56px) !important;
        width: 236px !important;
        padding: 8px 9px 9px !important;
        box-shadow:
          11px -7px 0 rgba(255, 222, 247, 0.28),
          19px -12px 0 rgba(228, 182, 255, 0.16),
          0 16px 28px rgba(169, 117, 232, 0.14) !important;
      }
    }
    @media (max-width: 640px) {
      body.page-main-reference .ref-live-pick {
        width: min(100%, 232px) !important;
        padding: 7px 8px 8px !important;
        box-shadow:
          8px -5px 0 rgba(255, 222, 247, 0.24),
          14px -9px 0 rgba(228, 182, 255, 0.12),
          0 14px 24px rgba(169, 117, 232, 0.12) !important;
      }
    }
    body.page-main-reference .ref-live-pick__thumb {
      position: relative;
      aspect-ratio: 0.78 !important;
      border-radius: 19px !important;
      box-shadow: 0 16px 30px rgba(171, 114, 223, 0.18);
    }
    body.page-main-reference .ref-live-pick__thumb::after {
      content: "";
      position: absolute;
      inset: 0;
      background:
        linear-gradient(138deg, rgba(255,255,255,0.22), rgba(255,255,255,0) 32%),
        radial-gradient(circle at 86% 18%, rgba(255,255,255,0.92) 0 2px, transparent 8px);
      mix-blend-mode: screen;
      pointer-events: none;
    }
    body.page-main-reference .ref-live-pick__thumb img {
      object-position: center 24% !important;
    }
    body.page-main-reference .ref-live-pick__body {
      gap: 4px !important;
      padding: 0 3px 0 !important;
    }
    body.page-main-reference .ref-live-pick__name {
      font-size: 1.42rem !important;
      line-height: 1 !important;
      letter-spacing: -0.04em !important;
      color: #40305d !important;
    }
    body.page-main-reference .ref-live-pick__meta {
      font-size: 0.66rem !important;
      font-weight: 700 !important;
      color: rgba(95, 69, 131, 0.74) !important;
    }
    body.page-main-reference .ref-live-pick__like-pill {
      gap: 5px !important;
      font-size: 0.82rem !important;
      font-weight: 900 !important;
      color: #ff6bae !important;
      margin-top: 0;
    }
    body.page-main-reference .ref-stat-list {
      gap: 4px !important;
      margin-top: 0;
    }
    body.page-main-reference .ref-stat-row {
      grid-template-columns: 42px minmax(0, 1fr) 26px !important;
      gap: 5px !important;
      font-size: 0.66rem !important;
      color: #775798 !important;
    }
    body.page-main-reference .ref-stat-row__bar {
      height: 5px !important;
      background: rgba(210, 184, 243, 0.42) !important;
    }
    body.page-main-reference .ref-stat-row__bar b {
      background: linear-gradient(90deg, #d47fff 0%, #ff8fc4 100%) !important;
      box-shadow: 0 0 10px rgba(229, 135, 220, 0.18);
    }
    body.page-main-reference .ref-live-pick__action {
      min-height: 34px !important;
      margin-top: 2px;
      border-radius: 999px !important;
      background: linear-gradient(90deg, #f39cc7 0%, #c590ff 100%) !important;
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.55),
        0 12px 22px rgba(201, 132, 224, 0.2) !important;
      font-family: "Orbitron", sans-serif !important;
      font-size: 0.8rem !important;
      letter-spacing: 0.05em !important;
      text-transform: uppercase;
    }
    body.page-main-reference .ref-live-pick__dots {
      margin-top: 5px !important;
      gap: 6px !important;
    }
    body.page-main-reference .ref-live-pick__dot {
      width: 5px !important;
      height: 5px !important;
      padding: 4px !important;
      background: rgba(194, 157, 231, 0.4) !important;
      background-clip: content-box !important;
    }
    body.page-main-reference .ref-live-pick__dot.is-active {
      background: linear-gradient(90deg, #f7a2ca 0%, #ca98ff 100%) !important;
      background-clip: content-box !important;
      transform: scale(1.08) !important;
    }
    @media (max-width: 980px) {
      body.page-main-reference .ref-live-pick__name {
        font-size: 1.26rem !important;
      }
    }
    @media (max-width: 640px) {
      body.page-main-reference .ref-live-pick::before {
        height: 24px;
      }
      body.page-main-reference .ref-live-pick__badge {
        min-height: 24px;
        font-size: 0.72rem !important;
      }
      body.page-main-reference .ref-live-pick__name {
        font-size: 1.12rem !important;
      }
      body.page-main-reference .ref-live-pick__action {
        min-height: 32px !important;
        font-size: 0.76rem !important;
      }
    }

    body.page-main-reference .ref-panel {
      isolation: isolate;
      overflow: hidden !important;
      box-shadow: 0 16px 30px rgba(181, 136, 227, 0.14) !important;
    }
    body.page-main-reference .ref-panel::after {
      border-radius: inherit;
      background:
        linear-gradient(160deg, rgba(255,255,255,0.28), rgba(255,255,255,0) 34%),
        radial-gradient(circle at 88% 10%, rgba(255,255,255,0.58) 0 2px, transparent 8px),
        radial-gradient(circle at 12% 82%, rgba(255, 239, 250, 0.30), transparent 24%);
    }
    body.page-main-reference .ref-panel > * {
      position: relative;
      z-index: 2;
    }
    body.page-main-reference .ref-panel--items {
      isolation: isolate;
      overflow: visible !important;
      box-shadow:
        10px -7px 0 rgba(255, 228, 248, 0.3),
        18px -12px 0 rgba(226, 190, 255, 0.14),
        0 16px 30px rgba(181, 136, 227, 0.14) !important;
    }
    @media (max-width: 980px) {
      body.page-main-reference .ref-panel--items {
        box-shadow:
          7px -5px 0 rgba(255, 228, 248, 0.24),
          13px -9px 0 rgba(226, 190, 255, 0.11),
          0 14px 26px rgba(181, 136, 227, 0.12) !important;
      }
    }
    @media (max-width: 640px) {
      body.page-main-reference .ref-panel--items {
        box-shadow:
          5px -4px 0 rgba(255, 228, 248, 0.18),
          9px -7px 0 rgba(226, 190, 255, 0.08),
          0 12px 22px rgba(181, 136, 227, 0.1) !important;
      }
    }

    body.page-main-reference .ref-panel--items .ref-item-list {
      grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
      gap: 10px !important;
      align-items: stretch !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-row__shop-link {
      display: contents;
      color: inherit;
      text-decoration: none;
    }
    body.page-main-reference .ref-dashboard-carousel__slide--items .ref-item-list {
      align-items: stretch !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-row {
      display: flex !important;
      flex-direction: column !important;
      align-items: center !important;
      align-self: stretch !important;
      justify-content: flex-start !important;
      box-sizing: border-box !important;
      width: 100% !important;
      gap: 5px !important;
      min-height: 226px !important;
      padding: 10px 8px 10px !important;
      text-align: center !important;
      border-radius: 22px !important;
      background:
        linear-gradient(180deg, rgba(255,255,255,0.88), rgba(255,255,255,0.58)),
        radial-gradient(circle at top, rgba(255, 214, 244, 0.55), rgba(255,255,255,0) 60%) !important;
      box-shadow: inset 0 1px 0 rgba(255,255,255,0.85), 0 10px 22px rgba(195, 141, 233, 0.16) !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-card__media {
      flex: 0 0 auto !important;
      width: 104px !important;
      height: 104px !important;
      min-width: 104px !important;
      min-height: 104px !important;
      max-width: 100% !important;
      display: grid !important;
      place-items: center !important;
      overflow: hidden !important;
      border-radius: 20px !important;
      background: linear-gradient(180deg, rgba(255,255,255,0.96), rgba(249, 236, 255, 0.78)) !important;
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.95),
        0 8px 20px rgba(213, 165, 235, 0.16) !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-card__media img {
      max-width: 88% !important;
      max-height: 88% !important;
      width: auto !important;
      height: auto !important;
      object-fit: contain !important;
      filter: drop-shadow(0 10px 16px rgba(206, 145, 226, 0.28));
      transform: rotate(-4deg) translateY(-1px);
    }
    body.page-main-reference .ref-panel--items .ref-item-card__body {
      flex: 0 0 auto !important;
      min-width: 0 !important;
      width: 100% !important;
      min-height: 0 !important;
      display: flex !important;
      flex-direction: column !important;
      align-items: center !important;
      justify-content: flex-start !important;
      gap: 3px !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-card__title {
      display: -webkit-box !important;
      -webkit-box-orient: vertical !important;
      -webkit-line-clamp: 2 !important;
      line-clamp: 2 !important;
      overflow: hidden !important;
      max-width: 100% !important;
      font-size: 1.06rem !important;
      line-height: 1.3 !important;
      font-weight: 900 !important;
      word-break: keep-all !important;
      color: #4a2f68 !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-card__effect {
      display: block !important;
      max-width: 100% !important;
      font-size: 0.78rem !important;
      line-height: 1.38 !important;
      font-weight: 700 !important;
      letter-spacing: -0.02em !important;
      color: #8b63b8 !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-card__price {
      position: relative !important;
      z-index: 2 !important;
      pointer-events: auto !important;
      flex: 0 0 auto !important;
      margin-top: 14px !important;
      min-width: 72px !important;
      min-height: 36px !important;
      width: auto !important;
      max-width: calc(100% - 10px) !important;
      display: inline-flex !important;
      align-items: center !important;
      justify-content: center !important;
      gap: 6px !important;
      border-radius: 999px !important;
      padding: 0 14px !important;
      background: linear-gradient(90deg, #f5a5ca 0%, #d097ff 100%) !important;
      box-shadow: 0 8px 18px rgba(214, 128, 205, 0.22) !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-card__price i {
      color: #ffe27a;
      font-size: 0.85rem;
    }
    body.page-main-reference .ref-panel--items .ref-item-card__price span {
      font-family: "Orbitron", sans-serif;
      font-size: 0.85rem;
      font-weight: 800;
      letter-spacing: 0.02em;
      color: #fff;
    }
    @media (max-width: 980px) {
      body.page-main-reference .ref-panel--items .ref-item-list {
        grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
        gap: 8px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-row {
        gap: 4px !important;
        min-height: 214px !important;
        padding: 9px 7px 9px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__media {
        width: 92px !important;
        height: 92px !important;
        min-width: 92px !important;
        min-height: 92px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__title {
        font-size: 0.98rem !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__effect {
        font-size: 0.72rem !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__price {
        margin-top: 12px !important;
        min-height: 32px !important;
        min-width: 66px !important;
        padding: 0 12px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__price span {
        font-size: 0.8rem !important;
      }
    }
    @media (max-width: 640px) {
      body.page-main-reference .ref-panel--items .ref-item-list {
        grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
        gap: 8px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-row {
        gap: 4px !important;
        min-height: 204px !important;
        border-radius: 18px !important;
        padding: 8px 6px 9px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__media {
        width: 80px !important;
        height: 80px !important;
        min-width: 80px !important;
        min-height: 80px !important;
        border-radius: 16px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__title {
        max-width: 96%;
        font-size: 0.88rem !important;
        line-height: 1.28 !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__effect {
        font-size: 0.66rem !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__price {
        margin-top: 11px !important;
        min-width: 60px !important;
        min-height: 30px !important;
        padding: 0 10px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__price span {
        font-size: 0.78rem;
      }
    }

    body.page-main-reference .ref-dashboard {
      overflow: visible !important;
      grid-template-columns: 1.04fr 1.36fr 1.08fr !important;
      gap: 18px !important;
      align-items: stretch;
    }
    body.page-main-reference .ref-panel {
      min-height: 190px;
      padding: 16px 18px 18px !important;
      border-radius: 28px !important;
      background:
        linear-gradient(180deg, rgba(255,255,255,0.76), rgba(255,255,255,0.50) 54%, rgba(249,240,255,0.30) 100%) !important;
      border: 1px solid rgba(255,255,255,0.48) !important;
      backdrop-filter: blur(18px) saturate(120%);
      -webkit-backdrop-filter: blur(18px) saturate(120%);
    }
    body.page-main-reference .ref-panel__head {
      margin-bottom: 22px !important;
      padding-top: 7px !important;
      padding-bottom: 7px !important;
    }
    body.page-main-reference .ref-panel__head h2 {
      font-size: 1.3rem !important;
      color: #4e2f72 !important;
      letter-spacing: -0.03em;
    }
    body.page-main-reference .ref-panel__head a,
    body.page-main-reference .ref-panel__head span {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 24px;
      padding: 0 10px;
      border-radius: 999px;
      background: rgba(255,255,255,0.36);
      color: #a36ada !important;
      font-size: 0.68rem !important;
      font-weight: 800 !important;
      letter-spacing: 0.02em;
      text-decoration: none;
    }

    body.page-main-reference .ref-panel--trainees {
      padding-bottom: 14px !important;
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-carousel {
      display: grid;
      gap: 14px;
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-carousel__viewport {
      overflow: hidden;
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-carousel__track {
      display: flex !important;
      width: calc(var(--ft-slides, 1) * 100%);
      transition: transform 0.45s ease;
      will-change: transform;
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-carousel__slide {
      display: block;
      flex: 0 0 calc(100% / var(--ft-slides, 1));
      min-width: 0;
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-row {
      gap: 14px !important;
      align-items: start;
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-mini {
      display: grid;
      justify-items: center;
      gap: 4px;
      padding: 6px 0 0;
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-mini__avatar {
      width: 66px !important;
      height: 66px !important;
      margin-bottom: 4px !important;
      border: 2px solid rgba(255,255,255,0.78) !important;
      box-shadow: 0 10px 22px rgba(169, 109, 223, 0.18);
      background: rgba(255,255,255,0.16);
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-mini__rank {
      top: -6px;
      right: -6px;
      min-width: 24px;
      height: 24px;
      padding: 0 6px;
      border-radius: 999px;
      background: linear-gradient(180deg, #ef8dd6 0%, #b67cff 100%);
      color: #fff;
      font-size: 0.78rem;
      font-weight: 900;
      box-shadow: 0 6px 16px rgba(208, 120, 216, 0.24);
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-mini strong {
      font-size: 0.95rem !important;
      color: #40295d !important;
    }
    body.page-main-reference .ref-trainee-mini__meta {
      font-style: normal;
      font-size: 0.68rem;
      font-weight: 700;
      color: rgba(132, 94, 178, 0.88);
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-mini small {
      margin-top: 0 !important;
      font-size: 0.75rem !important;
      color: #a05fe1 !important;
    }
    body.page-main-reference .ref-trainee-carousel__dots {
      justify-content: center;
      gap: 8px !important;
      margin-top: 2px !important;
    }
    body.page-main-reference .ref-trainee-carousel__dot {
      width: 6px;
      height: 6px;
      padding: 4px;
      border-radius: 999px;
      background: rgba(188, 152, 228, 0.34);
      background-clip: content-box;
      border: 0;
    }
    body.page-main-reference .ref-trainee-carousel__dot.is-active {
      background: linear-gradient(90deg, #f1a1cf, #cb97ff);
      background-clip: content-box;
      transform: scale(1.06);
    }

    body.page-main-reference .ref-panel--score-rank {
      --ref-score-shift: 190px;
      display: grid;
      grid-template-rows: auto 1fr;
      align-content: start;
      justify-items: center;
      text-align: center;
    }
    body.page-main-reference .ref-panel--score-rank .ref-panel__head {
      width: min(calc(100% - 8px), 520px);
      margin-left: auto;
      margin-right: auto;
      transform: translateX(var(--ref-score-shift));
    }
    body.page-main-reference .ref-score-center {
      width: min(calc(100% - 8px), 520px);
      margin: 0 auto;
      display: grid;
      justify-items: center;
      align-content: start;
      text-align: center;
      transform: translateX(var(--ref-score-shift));
    }
    body.page-main-reference .ref-score-stage {
      display: grid;
      width: 100%;
      justify-items: center;
      justify-content: center;
      text-align: center;
      gap: 8px;
      padding: 4px 6px 12px;
      margin-left: auto;
      margin-right: auto;
    }
    body.page-main-reference .ref-score-hero {
      display: inline-flex;
      align-items: flex-end;
      justify-content: center;
      gap: 6px;
      margin-left: auto;
      margin-right: auto;
      text-align: center;
    }
    body.page-main-reference .ref-score-hero strong {
      font-family: "Orbitron", sans-serif;
      font-size: clamp(3.4rem, 4.6vw, 4.6rem);
      line-height: 0.9;
      color: #be73ff;
      text-shadow: 0 0 22px rgba(208, 151, 255, 0.22);
    }
    body.page-main-reference .ref-score-hero span {
      font-size: 1.35rem;
      font-weight: 800;
      color: #6c4f92;
      padding-bottom: 0.45rem;
    }
    body.page-main-reference .ref-score-copy {
      margin: 0 !important;
      width: 100%;
      text-align: center !important;
      font-size: 0.74rem !important;
      line-height: 1.4 !important;
      color: rgba(120, 91, 163, 0.76) !important;
    }
    body.page-main-reference .ref-score-rank-grid {
      width: 100%;
      margin: 0 auto;
      display: grid;
      gap: 8px;
      justify-self: center;
      align-self: start;
    }
    body.page-main-reference .ref-score-rank-card {
      display: grid;
      gap: 4px;
      padding: 10px 12px;
      text-decoration: none;
      color: inherit;
      text-align: left;
      background: linear-gradient(180deg, rgba(255,255,255,0.4), rgba(255,255,255,0.18));
      border: 1px solid rgba(255,255,255,0.42);
      border-radius: 16px;
      box-shadow: inset 0 1px 0 rgba(255,255,255,0.52);
    }
    body.page-main-reference .ref-score-rank-card span {
      display: block;
      font-family: "Orbitron", sans-serif;
      font-size: 0.72rem;
      font-weight: 800;
      color: #b27ae8;
      text-align: left;
    }
    body.page-main-reference .ref-score-rank-card strong {
      display: block;
      min-width: 0;
      font-size: 0.82rem;
      font-weight: 900;
      color: #624183;
      text-align: left;
      line-height: 1.2;
      letter-spacing: -0.01em;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    body.page-main-reference .ref-score-rank-card small {
      display: block;
      width: auto;
      white-space: nowrap;
      font-size: 0.68rem;
      font-weight: 800;
      color: #9168c8;
      text-align: left;
    }

    body.page-main-reference .ref-panel--items .ref-panel__head {
      margin-bottom: 20px !important;
    }
    body.page-main-reference .ref-panel--items .ref-item-list {
      align-items: start !important;
    }
    body.page-main-reference .ref-panel--board .ref-feed {
      gap: 8px !important;
    }
    body.page-main-reference .ref-panel--board .ref-feed-item.ref-feed-item--board-main {
      display: grid !important;
      grid-template-columns: 1fr !important;
      gap: 6px !important;
      align-content: start !important;
      padding: 10px 12px !important;
      border-radius: 16px !important;
      background: linear-gradient(180deg, rgba(255,255,255,0.4), rgba(255,255,255,0.18)) !important;
    }
    body.page-main-reference .ref-panel--board .ref-feed-item.ref-feed-item--board-main > span:first-child {
      font-size: 0.84rem !important;
    }
    body.page-main-reference .ref-panel--board .ref-feed-item__title-row {
      display: flex !important;
      align-items: flex-start !important;
      justify-content: space-between !important;
      gap: 12px !important;
      width: 100% !important;
      min-width: 0 !important;
    }
    body.page-main-reference .ref-panel--board .ref-feed-item__title-row strong {
      flex: 1 1 auto !important;
      min-width: 0 !important;
      font-size: 1.06rem !important;
      line-height: 1.3 !important;
      color: #4b2e6e !important;
    }
    body.page-main-reference .ref-panel--board .ref-feed-item__title-row small {
      flex: 0 0 auto !important;
      margin-left: auto !important;
      white-space: nowrap !important;
      font-size: 0.78rem !important;
      color: #9365cb !important;
    }
    body.page-main-reference .ref-panel--rank .ref-feed {
      gap: 8px !important;
    }
    body.page-main-reference .ref-panel--rank .ref-feed-item.ref-feed-item--rank-main {
      display: grid !important;
      grid-template-columns: 1fr !important;
      gap: 6px !important;
      align-content: start !important;
      padding: 10px 12px !important;
      border-radius: 16px !important;
      background: linear-gradient(180deg, rgba(255,255,255,0.4), rgba(255,255,255,0.18)) !important;
      border: 1px solid rgba(255,255,255,0.34) !important;
      box-shadow: inset 0 1px 0 rgba(255,255,255,0.46) !important;
    }
    body.page-main-reference .ref-panel--rank .ref-feed-item.ref-feed-item--rank-main > span:first-child {
      font-size: 0.84rem !important;
    }
    body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__title-row {
      display: flex !important;
      align-items: flex-start !important;
      justify-content: space-between !important;
      gap: 12px !important;
      width: 100% !important;
      min-width: 0 !important;
    }
    body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__title-row strong {
      flex: 1 1 auto !important;
      min-width: 0 !important;
      font-size: 1.06rem !important;
      line-height: 1.3 !important;
      color: #4b2e6e !important;
    }
    body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__score-wrap {
      display: inline-flex !important;
      align-items: center !important;
      justify-content: flex-end !important;
      flex: 0 0 auto !important;
      gap: 8px !important;
      margin-left: auto !important;
      min-width: 0 !important;
    }
    body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__title-row small {
      flex: 0 0 auto !important;
      white-space: nowrap !important;
      font-size: 0.78rem !important;
      color: #9365cb !important;
    }
    body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__group {
      display: inline-block !important;
      flex-shrink: 0 !important;
      padding: 3px 9px !important;
      border-radius: 999px !important;
      font-size: 0.72rem !important;
      font-weight: 800 !important;
      letter-spacing: 0.02em !important;
      color: #7a4fa8 !important;
      background: rgba(203, 156, 255, 0.22) !important;
      border: 1px solid rgba(255, 255, 255, 0.45) !important;
    }

    @media (max-width: 1280px) {
      body.page-main-reference .ref-dashboard {
        grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
      }
    }
    @media (max-width: 980px) {
      body.page-main-reference .ref-stage {
        gap: clamp(8px, 1.85vh, 18px) !important;
      }
      body.page-main-reference .ref-dashboard {
        grid-template-columns: 1fr !important;
        gap: 14px !important;
      }
      body.page-main-reference .ref-panel {
        min-height: 0;
      }
      body.page-main-reference .ref-panel--trainees .ref-trainee-mini__avatar {
        width: 60px !important;
        height: 60px !important;
      }
    }
    @media (max-width: 640px) {
      body.page-main-reference .ref-panel {
        padding: 14px 14px 16px !important;
        border-radius: 24px !important;
      }
      body.page-main-reference .ref-panel__head h2 {
        font-size: 1.2rem !important;
      }
      body.page-main-reference .ref-panel__head {
        margin-bottom: 24px !important;
        padding-top: 6px !important;
        padding-bottom: 6px !important;
      }
      body.page-main-reference .ref-panel--trainees .ref-trainee-row {
        gap: 10px !important;
      }
      body.page-main-reference .ref-panel--trainees .ref-trainee-mini__avatar {
        width: 54px !important;
        height: 54px !important;
      }
      body.page-main-reference .ref-panel--trainees .ref-trainee-mini strong {
        font-size: 0.82rem !important;
      }
      body.page-main-reference .ref-score-hero strong {
        font-size: 2.8rem;
      }
      body.page-main-reference .ref-score-rank-card {
        padding: 11px 6px 10px;
      }
      body.page-main-reference .ref-score-rank-card strong {
        font-size: 0.76rem;
      }
      body.page-main-reference .ref-score-rank-card small {
        font-size: 0.7rem;
      }
    }

    @media (min-width: 981px) {
      body.page-main-reference .ref-main {
        padding-top: 8px !important;
        padding-bottom: 8px !important;
      }
      body.page-main-reference .ref-stage {
        min-height: calc(100vh - var(--nav-h, 72px) - 14px) !important;
        gap: clamp(12px, 2.2vh, 28px) !important;
      }
      body.page-main-reference .ref-hero-card {
        gap: 10px !important;
        padding: 4px 12px 2px !important;
        align-items: start !important;
      }
      body.page-main-reference .ref-hero-card__center {
        padding: 190px 10px 0 !important;
      }
      body.page-main-reference .ref-title {
        font-size: clamp(3.7rem, 6.5vw, 5.9rem) !important;
      }
      body.page-main-reference .ref-subtitle,
      body.page-main-reference .ref-hero-card__center .ref-subtitle {
        margin-top: 22px !important;
        font-size: clamp(0.96rem, 1.18vw, 1.2rem) !important;
        line-height: 1.24 !important;
      }
      body.page-main-reference .ref-actions {
        margin-top: 14px !important;
        gap: 12px !important;
      }
      body.page-main-reference .ref-btn {
        min-height: 48px !important;
      }
      body.page-main-reference .ref-live-pick {
        margin-top: clamp(30px, 3.6vh, 52px) !important;
      }
      body.page-main-reference .ref-panel {
        min-height: 138px !important;
        padding: 10px 12px 12px !important;
        border-radius: 24px !important;
      }
      body.page-main-reference .ref-panel__head {
        margin-bottom: 14px !important;
        padding-top: 6px !important;
        padding-bottom: 6px !important;
      }
      body.page-main-reference .ref-panel__head h2 {
        font-size: 1.22rem !important;
      }
      body.page-main-reference .ref-panel__head a,
      body.page-main-reference .ref-panel__head span {
        min-height: 20px;
        padding: 0 7px;
        font-size: 0.58rem !important;
      }
      body.page-main-reference .ref-panel--trainees .ref-trainee-row {
        gap: 8px !important;
      }
      body.page-main-reference .ref-panel--trainees .ref-trainee-mini__avatar {
        width: 48px !important;
        height: 48px !important;
      }
      body.page-main-reference .ref-panel--trainees .ref-trainee-mini strong {
        font-size: 0.76rem !important;
      }
      body.page-main-reference .ref-trainee-mini__meta {
        font-size: 0.58rem !important;
      }
      body.page-main-reference .ref-panel--trainees .ref-trainee-mini small {
        font-size: 0.62rem !important;
      }
      body.page-main-reference .ref-score-stage {
        gap: 2px;
        padding: 0 2px 6px;
      }
      body.page-main-reference .ref-score-center {
        width: min(calc(100% - 8px), 430px);
      }
      body.page-main-reference .ref-panel--score-rank {
        --ref-score-shift: 128px;
      }
      body.page-main-reference .ref-score-hero strong {
        font-size: clamp(2.35rem, 3.2vw, 3rem);
      }
      body.page-main-reference .ref-score-hero span {
        font-size: 0.9rem;
        padding-bottom: 0.22rem;
      }
      body.page-main-reference .ref-score-copy {
        font-size: 0.6rem !important;
      }
      body.page-main-reference .ref-score-rank-grid {
        width: 100%;
        gap: 6px;
      }
      body.page-main-reference .ref-score-rank-card {
        gap: 3px;
        padding: 8px 10px;
      }
      body.page-main-reference .ref-score-rank-card span {
        font-size: 0.64rem;
      }
      body.page-main-reference .ref-score-rank-card strong {
        font-size: 0.74rem;
      }
      body.page-main-reference .ref-score-rank-card small {
        font-size: 0.62rem;
      }
      body.page-main-reference .ref-panel--items .ref-item-list {
        gap: 6px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-row {
        gap: 4px !important;
        min-height: 196px !important;
        padding: 7px 5px 7px !important;
        border-radius: 16px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__media {
        width: 74px !important;
        height: 74px !important;
        min-width: 74px !important;
        min-height: 74px !important;
        border-radius: 15px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__title {
        font-size: 0.82rem !important;
        line-height: 1.22 !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__effect {
        font-size: 0.62rem !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__price {
        margin-top: 10px !important;
        min-width: 56px !important;
        min-height: 28px !important;
        padding: 0 9px !important;
      }
      body.page-main-reference .ref-panel--items .ref-item-card__price span {
        font-size: 0.7rem !important;
      }
      body.page-main-reference .ref-panel--board .ref-feed-item.ref-feed-item--board-main {
        padding: 7px 8px !important;
      }
      body.page-main-reference .ref-panel--board .ref-feed-item.ref-feed-item--board-main > span:first-child {
        font-size: 0.76rem !important;
      }
      body.page-main-reference .ref-panel--board .ref-feed-item__title-row strong {
        font-size: 0.92rem !important;
      }
      body.page-main-reference .ref-panel--board .ref-feed-item__title-row small {
        font-size: 0.7rem !important;
      }
      body.page-main-reference .ref-panel--rank .ref-feed-item.ref-feed-item--rank-main {
        padding: 7px 8px !important;
      }
      body.page-main-reference .ref-panel--rank .ref-feed-item.ref-feed-item--rank-main > span:first-child {
        font-size: 0.76rem !important;
      }
      body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__title-row strong {
        font-size: 0.92rem !important;
      }
      body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__title-row small {
        font-size: 0.7rem !important;
      }
      body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__group {
        font-size: 0.64rem !important;
        padding: 2px 7px !important;
      }
      body.page-main-reference .ref-panel--rank .ref-feed-item--rank-main .ref-feed-item__score-wrap {
        gap: 6px !important;
      }
    }

    /* 전체 화면 스파클(::before/::after)은 mix-blend + 그라데이션 합성 비용 큼 → 메인에서 비표시 */
    body.page-main-reference .ref-main::before,
    body.page-main-reference .ref-main::after {
      content: none !important;
      animation: none !important;
      filter: none !important;
    }
    body.page-main-reference .ref-panel,
    body.page-main-reference .ref-btn,
    body.page-main-reference .ref-item-card__media,
    body.page-main-reference .ref-feed-item,
    body.page-main-reference .ref-item-row {
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
    }
    body.page-main-reference .ref-panel {
      box-shadow: 0 8px 18px rgba(181, 136, 227, 0.1) !important;
    }
    body.page-main-reference .ref-panel::after {
      opacity: 0.48 !important;
    }
    body.page-main-reference .ref-btn::before,
    body.page-main-reference .ref-btn::after {
      opacity: 0.42 !important;
    }
    body.page-main-reference .ref-live-pick__thumb img,
    body.page-main-reference .ref-panel--items .ref-item-card__media img {
      filter: none !important;
    }
    body.page-main-reference .ref-btn:hover,
    body.page-main-reference .ref-list-item:hover,
    body.page-main-reference .ref-feed-item:hover,
    body.page-main-reference .ref-item-row:hover,
    body.page-main-reference .ref-trainee-mini:hover {
      transform: none !important;
    }
    body.page-main-reference .ref-kicker,
    body.page-main-reference .ref-title-stack,
    body.page-main-reference .ref-subtitle,
    body.page-main-reference .ref-actions {
      will-change: auto !important;
    }
    body.page-main-reference .ref-main,
    body.page-main-reference .ref-dashboard,
    body.page-main-reference .ref-panel {
      contain: layout paint;
    }
    body.page-main-reference .ref-hero-card {
      contain: layout style;
    }
    body.page-main-reference .ref-live-pick {
      animation: none !important;
    }

    /* 성능: 메인에서 시각적 이득 대비 합성 비용 큰 요소 끄기 */
    body.page-main-reference .ref-title-stack::before,
    body.page-main-reference .ref-title-stack::after {
      content: none !important;
    }
    body.page-main-reference .ref-title-eyebrow,
    body.page-main-reference .ref-title,
    body.page-main-reference .ref-subtitle,
    body.page-main-reference .ref-actions {
      animation: none !important;
      opacity: 1 !important;
      transform: none !important;
    }
    body.page-main-reference .ref-typewriter__caret {
      animation: none !important;
      opacity: 0.82;
    }
    body.page-main-reference .ref-live-pick__carousel::before,
    body.page-main-reference .ref-live-pick__carousel::after {
      content: none !important;
    }
    body.page-main-reference .ref-live-pick__thumb::after {
      content: none !important;
    }
    body.page-main-reference .ref-main {
      contain: layout;
    }
    body.page-main-reference .ref-panel--trainees .ref-trainee-carousel__track {
      will-change: auto !important;
    }

    /* 성능 블록 이후: 타이틀 LED만 애니 유지 */
    body.page-main-reference .ref-title__line--led .ref-title__led {
      animation: refJumbotronLed 6s linear infinite !important;
    }

    /* 메인 카드 톤 상향: 전체적으로 조금 더 화이트 */
    body.page-main-reference .ref-panel,
    body.page-main-reference .ref-live-pick {
      background: linear-gradient(180deg, rgba(255,255,255,0.86), rgba(255,255,255,0.74)) !important;
      border-color: rgba(255,255,255,0.54) !important;
      box-shadow: 0 8px 20px rgba(181, 142, 230, 0.07) !important;
    }
    body.page-main-reference .ref-list-item,
    body.page-main-reference .ref-feed-item,
    body.page-main-reference .ref-item-row,
    body.page-main-reference .ref-trainee-mini,
    body.page-main-reference .ref-list-empty {
      background: rgba(255,255,255,0.9) !important;
      border-color: rgba(255,255,255,0.52) !important;
    }
    body.page-main-reference .ref-list-item:hover,
    body.page-main-reference .ref-feed-item:hover,
    body.page-main-reference .ref-item-row:hover,
    body.page-main-reference .ref-trainee-mini:hover {
      background: rgba(255,255,255,0.96) !important;
    }

  </style>
</head>
<body class="page-main page-main-reference min-h-screen flex flex-col">
  <div class="topnav-shell">
    <%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>
  </div>

  <main class="main-reference flex-1">
    <section class="ref-main" aria-label="메인 무대 화면">
      <div class="ref-main__bg" aria-hidden="true">
        <img src="${ctx}/images/main-hero-bg.png?v=20260414" width="1024" height="682" alt="" fetchpriority="high" decoding="async">
      </div>

      <div class="ref-shell">
        <div class="ref-stage" data-stage>
          <section class="ref-hero-card">
            <div class="ref-hero-card__center">
              <div class="ref-title-stack">
                <p class="ref-title-eyebrow">THE NEXT DEBUT</p>
                <h1 class="ref-title">
                  <span class="ref-title__line ref-title__line--full ref-title__line--led" aria-label="THE NEXT DEBUT">
                    <span class="ref-title__led">T</span><span class="ref-title__led">H</span><span class="ref-title__led">E</span><span class="ref-title__led">&nbsp;</span><span class="ref-title__led">N</span><span class="ref-title__led">E</span><span class="ref-title__led">X</span><span class="ref-title__led">T</span><span class="ref-title__led">&nbsp;</span><span class="ref-title__led">D</span><span class="ref-title__led">E</span><span class="ref-title__led">B</span><span class="ref-title__led">U</span><span class="ref-title__led">T</span>
                  </span>
                </h1>
              </div>
              <p class="ref-subtitle ref-subtitle--typewriter" id="heroTypeSubtitle" aria-label="연습생을 선택하고, 성장을 설계하고, 데뷔 무대까지 이끄는 프로듀서가 되어 보세요.">
                <span class="ref-typewriter__line">
                  <span class="ref-typewriter__chunk">연습생을 선택하고, </span>
                </span>
                <span class="ref-typewriter__line">
                  <span class="ref-subtitle-em ref-typewriter__chunk">성장을</span>
                  <span class="ref-typewriter__chunk"> 설계하고, </span>
                </span>
                <span class="ref-typewriter__line">
                  <span class="ref-subtitle-em ref-typewriter__chunk">데뷔</span>
                  <span class="ref-typewriter__chunk"> 무대까지 이끄는 프로듀서가 되어 보세요.</span>
                  <span class="ref-typewriter__caret" aria-hidden="true"></span>
                </span>
              </p>

              <div class="ref-actions">
                <c:choose>
                  <c:when test="${loggedIn}">
                    <a href="${ctx}/game" class="ref-btn ref-btn--primary js-open-game-modal" data-li="true">ENTER THE STAGE</a>
                    <a href="${ctx}/guide" class="ref-btn ref-btn--secondary">GAME GUIDE</a>
                    <a href="${ctx}/game/continue" class="ref-btn ref-btn--secondary">CONTINUE</a>
                  </c:when>
                  <c:otherwise>
                    <a href="${ctx}/game" class="ref-btn ref-btn--primary js-open-game-modal" data-li="false">ENTER THE STAGE</a>
                    <a href="${ctx}/guide" class="ref-btn ref-btn--secondary">GAME GUIDE</a>
                  </c:otherwise>
                </c:choose>
              </div>
            </div>

            <aside class="ref-live-pick" id="refLivePickRoot">
              <div class="ref-live-pick__badge">LIVE PICK</div>
              <c:choose>
                <c:when test="${not empty livePickTopByLikes}">
                  <div class="ref-live-pick__carousel" id="refLivePickCarousel">
                    <div class="ref-live-pick__slides">
                      <c:forEach var="pick" items="${livePickTopByLikes}" varStatus="st">
                        <c:if test="${pick.grade ne 'HIDDEN'}">
                          <div class="ref-live-pick__slide${st.first ? ' is-active' : ''}" data-slide="${st.index}">
                            <div class="ref-live-pick__thumb">
                              <img src="${ctx}${pick.imagePath}" alt="${pick.name} 연습생 이미지" loading="${st.first ? 'eager' : 'lazy'}">
                            </div>
                            <div class="ref-live-pick__body">
                              <strong class="ref-live-pick__name"><c:out value="${pick.name}" /></strong>
                              <span class="ref-live-pick__meta"><c:out value="${pick.grade}" /> · 좋아요 상위 ${st.index + 1}위</span>
                              <span class="ref-live-pick__like-pill" title="누적 좋아요"><i class="fas fa-heart" aria-hidden="true"></i> <c:out value="${pick.likeLabel}" /></span>
                              <div class="ref-stat-list">
                                <div class="ref-stat-row">
                                  <span>퍼포먼스</span>
                                  <div class="ref-stat-row__bar"><b style="width:${pick.dance}%"></b></div>
                                  <strong>${pick.dance}</strong>
                                </div>
                                <div class="ref-stat-row">
                                  <span>스타성</span>
                                  <div class="ref-stat-row__bar"><b style="width:${pick.star}%"></b></div>
                                  <strong>${pick.star}</strong>
                                </div>
                                <div class="ref-stat-row">
                                  <span>종합</span>
                                  <div class="ref-stat-row__bar"><b style="width:${pick.totalScore}%"></b></div>
                                  <strong>${pick.totalScore}</strong>
                                </div>
                              </div>
                              <a href="${ctx}/trainees" class="ref-live-pick__action">상세보기</a>
                            </div>
                          </div>
                        </c:if>
                      </c:forEach>
                    </div>
                    <c:if test="${fn:length(livePickTopByLikes) > 1}">
                      <div class="ref-live-pick__dots" role="tablist" aria-label="연습생 슬라이드">
                        <c:forEach var="pick" items="${livePickTopByLikes}" varStatus="st">
                          <c:if test="${pick.grade ne 'HIDDEN'}">
                            <button type="button" class="ref-live-pick__dot${st.first ? ' is-active' : ''}" data-dot="${st.index}" aria-label="슬라이드 ${st.index + 1}" aria-selected="${st.first}"></button>
                          </c:if>
                        </c:forEach>
                      </div>
                    </c:if>
                  </div>
                </c:when>
                <c:otherwise>
                  <div class="ref-live-pick__empty">좋아요 데이터가 쌓이면 이 영역에 인기 연습생이 표시됩니다.</div>
                </c:otherwise>
              </c:choose>
            </aside>
          </section>

          <section class="ref-dashboard">
            <article class="ref-panel ref-panel--rank">
              <div class="ref-panel__head">
                <h2>TOP 랭킹</h2>
                <a href="${ctx}/game/run/ranking">전체 랭킹</a>
              </div>
              <c:choose>
                <c:when test="${not empty liveTop9}">
                  <div class="ref-dashboard-carousel" id="refRankCarousel">
                    <div class="ref-dashboard-carousel__slides">
                      <c:forEach var="row" items="${liveTop9}" varStatus="st">
                        <c:if test="${st.index % 3 == 0}">
                          <div class="ref-dashboard-carousel__slide ref-dashboard-carousel__slide--rank${st.index == 0 ? ' is-active' : ''}">
                            <div class="ref-feed ref-feed--dashboard-triple">
                        </c:if>
                              <a href="${ctx}/game/run/${row.runId}/ranking?from=main" class="ref-feed-item ref-feed-item--rank-main">
                                <span>TOP ${st.index + 1}</span>
                                <div class="ref-feed-item__title-row">
                                  <strong><c:out value="${row.label}" /></strong>
                                  <span class="ref-feed-item__score-wrap">
                                    <c:if test="${not empty row.groupLabel}">
                                      <span class="ref-feed-item__group"><c:out value="${row.groupLabel}" /></span>
                                    </c:if>
                                    <small>${row.score} PT</small>
                                  </span>
                                </div>
                              </a>
                        <c:if test="${st.index % 3 == 2 or st.last}">
                            </div>
                          </div>
                        </c:if>
                      </c:forEach>
                    </div>
                    <c:if test="${rankDashboardSlideCount > 1}">
                      <div class="ref-dashboard-carousel__dots" role="tablist" aria-label="랭킹 슬라이드">
                        <c:forEach var="dotIdx" begin="0" end="${rankDashboardSlideCount - 1}">
                          <button type="button" class="ref-dashboard-carousel__dot${dotIdx == 0 ? ' is-active' : ''}" data-dot="${dotIdx}" aria-label="슬라이드 ${dotIdx + 1}" aria-selected="${dotIdx == 0}"></button>
                        </c:forEach>
                      </div>
                    </c:if>
                  </div>
                </c:when>
                <c:otherwise>
                  <div class="ref-list-empty">랭킹 데이터 준비 중</div>
                </c:otherwise>
              </c:choose>
            </article>

            <article class="ref-panel ref-panel--board">
              <div class="ref-panel__head">
                <h2>인기 게시글</h2>
                <a href="${ctx}/board">게시판</a>
              </div>
              <c:choose>
                <c:when test="${not empty topViewedPosts}">
                  <div class="ref-dashboard-carousel" id="refBoardCarousel">
                    <div class="ref-dashboard-carousel__slides">
                      <c:forEach var="post" items="${topViewedPosts}" varStatus="st">
                        <c:if test="${st.index % 3 == 0}">
                          <div class="ref-dashboard-carousel__slide ref-dashboard-carousel__slide--board${st.index == 0 ? ' is-active' : ''}">
                            <div class="ref-feed ref-feed--dashboard-triple">
                        </c:if>
                              <a href="${ctx}/boards/${post.boardType}/${post.id}" class="ref-feed-item ref-feed-item--board-main">
                                <span>TOP ${st.index + 1}</span>
                                <div class="ref-feed-item__title-row">
                                  <strong><c:out value="${post.title}" /></strong>
                                  <small>조회 ${post.viewCount}</small>
                                </div>
                              </a>
                        <c:if test="${st.index % 3 == 2 or st.last}">
                            </div>
                          </div>
                        </c:if>
                      </c:forEach>
                    </div>
                    <c:if test="${boardDashboardSlideCount > 1}">
                      <div class="ref-dashboard-carousel__dots" role="tablist" aria-label="인기 게시글 슬라이드">
                        <c:forEach var="dotIdx" begin="0" end="${boardDashboardSlideCount - 1}">
                          <button type="button" class="ref-dashboard-carousel__dot${dotIdx == 0 ? ' is-active' : ''}" data-dot="${dotIdx}" aria-label="슬라이드 ${dotIdx + 1}" aria-selected="${dotIdx == 0}"></button>
                        </c:forEach>
                      </div>
                    </c:if>
                  </div>
                </c:when>
                <c:otherwise>
                  <div class="ref-list-empty">게시글 데이터 준비 중</div>
                </c:otherwise>
              </c:choose>
            </article>

            <article class="ref-panel ref-panel--items">
              <div class="ref-panel__head">
                <h2>인기 아이템</h2>
                <a href="${ctx}/market/shop">상점</a>
              </div>
              <div class="ref-dashboard-carousel" id="refItemsCarousel">
                <div class="ref-dashboard-carousel__slides">
                  <c:forEach var="it" items="${shopSpotlightItems}" varStatus="st">
                    <c:if test="${st.index % 3 == 0}">
                      <div class="ref-dashboard-carousel__slide ref-dashboard-carousel__slide--items${st.index == 0 ? ' is-active' : ''}">
                        <div class="ref-item-list">
                    </c:if>
                          <div class="ref-item-row">
                            <a href="${ctx}/market/shop#${it.shopAnchorId}" class="ref-item-row__shop-link" title="상점에서 구매하기">
                              <div class="ref-item-card__media">
                                <img src="${ctx}${it.imagePath}" alt="${it.itemName} 이미지" loading="lazy">
                              </div>
                              <div class="ref-item-card__body">
                                <strong class="ref-item-card__title"><c:out value="${it.itemName}" /></strong>
                                <span class="ref-item-card__effect"><c:out value="${it.effectShort}" /></span>
                              </div>
                            </a>
                            <button type="button" class="ref-chip-btn ref-item-card__price js-hero-shop-buy" data-item-name="<c:out value='${it.itemName}' />" data-price="${it.priceCoin}">
                              <i class="fas fa-coins" aria-hidden="true"></i>
                              <span>${it.priceCoin}C</span>
                            </button>
                          </div>
                    <c:if test="${st.index % 3 == 2 or st.last}">
                        </div>
                      </div>
                    </c:if>
                  </c:forEach>
                </div>
                <div class="ref-dashboard-carousel__dots" role="tablist" aria-label="인기 아이템 슬라이드">
                  <button type="button" class="ref-dashboard-carousel__dot is-active" data-dot="0" aria-label="슬라이드 1" aria-selected="true"></button>
                  <button type="button" class="ref-dashboard-carousel__dot" data-dot="1" aria-label="슬라이드 2" aria-selected="false"></button>
                  <button type="button" class="ref-dashboard-carousel__dot" data-dot="2" aria-label="슬라이드 3" aria-selected="false"></button>
                </div>
              </div>
            </article>
          </section>
        </div>
      </div>
    </section>
  </main>

  <div class="game-modal" id="gameStartModal" aria-hidden="true">
    <div class="game-modal__dim" data-close-game-modal></div>
    <div class="game-modal__panel" role="dialog" aria-modal="true" aria-labelledby="gameModalTitle">
      <button type="button" class="game-modal__close" id="gameModalClose" aria-label="닫기">&times;</button>
      <div class="game-modal__head">
        <div class="game-modal__eyebrow">START YOUR DEBUT TEAM</div>
        <h2 class="game-modal__title" id="gameModalTitle">어떤 팀으로 데뷔 무대를 시작할까요?</h2>
        <p class="game-modal__desc">그룹 구성을 선택하면 바로 로스터 생성 단계로 이동합니다.</p>
      </div>
      <div class="game-select-grid" id="groupSelectGrid">
        <label class="group-option group-option--mixed is-selected" data-group-option data-group-type="MIXED">
          <input type="radio" name="groupType" value="MIXED" checked>
          <div class="group-option__badge">M</div>
          <div class="group-option__name">혼성</div>
          <div class="group-option__meta">남녀 조합으로 밸런스를 노리는 팀</div>
          <div class="group-option__hint">퍼포먼스와 스타성을 함께 챙기기 좋습니다</div>
          <div class="group-option__chip">4 MEMBERS</div>
        </label>
        <label class="group-option group-option--male" data-group-option data-group-type="MALE">
          <input type="radio" name="groupType" value="MALE">
          <div class="group-option__badge">B</div>
          <div class="group-option__name">보이 그룹</div>
          <div class="group-option__meta">강한 퍼포먼스 중심 팀</div>
          <div class="group-option__hint">강한 무대 집중형 플레이에 어울립니다</div>
          <div class="group-option__chip">4 MEMBERS</div>
        </label>
        <label class="group-option group-option--female" data-group-option data-group-type="FEMALE">
          <input type="radio" name="groupType" value="FEMALE">
          <div class="group-option__badge">G</div>
          <div class="group-option__name">걸 그룹</div>
          <div class="group-option__meta">스타성과 무드 중심 팀</div>
          <div class="group-option__hint">보컬과 콘셉트를 강조하기 좋습니다</div>
          <div class="group-option__chip">4 MEMBERS</div>
        </label>
      </div>
      <div class="game-modal__actions">
        <div class="game-modal__status" id="gameModalStatus">선호하는 그룹 타입을 고른 뒤 START를 눌러 주세요.</div>
        <div class="game-modal__btns">
          <button type="button" class="gm-btn gm-btn--ghost" data-close-game-modal>취소</button>
          <button type="button" class="gm-btn gm-btn--primary" id="gameModalStartBtn">START</button>
        </div>
      </div>
    </div>
  </div>

  <%@ include file="/WEB-INF/views/fragments/footer.jspf" %>

  <c:if test="${not empty rosterError}">
    <textarea id="__flashRosterErr" style="display:none" readonly><c:out value="${rosterError}"/></textarea>
    <script>
      document.addEventListener('DOMContentLoaded', function () {
        var t = document.getElementById('__flashRosterErr');
        if (t && t.textContent && t.textContent.trim()) {
          alert(t.textContent.trim());
        }
      });
    </script>
  </c:if>

  <script>
    window.mainPageConfig = {
      ctx: '${ctx}',
      loggedIn: ${loggedIn}
    };
  </script>
  <script defer src="${ctx}/js/main.js?v=main-js-shop-buy-delegate-20260410"></script>
</body>
</html>
