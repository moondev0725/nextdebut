<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>NEXT DEBUT - 게임 가이드</title>

    <%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
    <style>
        body.page-main{
            background:
                radial-gradient(circle at 12% 14%, rgba(233,176,196,0.20), transparent 22%),
                radial-gradient(circle at 86% 18%, rgba(204,186,216,0.22), transparent 24%),
                radial-gradient(circle at 55% 92%, rgba(186,198,220,0.20), transparent 22%),
                linear-gradient(180deg, #f6f3fb 0%, #efebf6 52%, #eceff7 100%) !important;
            background-attachment: fixed !important;
        }
        body.page-main::before{
            background:
                radial-gradient(circle at 18% 0%, rgba(255,255,255,0.82), transparent 34%),
                radial-gradient(circle at 100% 12%, rgba(255,255,255,0.68), transparent 28%),
                radial-gradient(circle at 50% 100%, rgba(255,255,255,0.46), transparent 30%) !important;
            filter: blur(18px) !important;
            opacity: .95 !important;
        }
        body.page-main::after{
            opacity: .75 !important;
        }

        .guide-wrap{ max-width: 1180px; margin: 0 auto; }
        .guide-section{ margin-bottom: 24px; }
        .guide-card{
            position: relative;
            overflow: hidden;
            border-radius: 30px;
            border: 1px solid rgba(196, 187, 222, 0.55);
            background: linear-gradient(180deg, rgba(255,255,255,0.82), rgba(255,255,255,0.70));
            box-shadow: 0 18px 42px rgba(140, 136, 170, 0.10), inset 0 1px 0 rgba(255,255,255,0.72);
            backdrop-filter: blur(18px);
            -webkit-backdrop-filter: blur(18px);
        }
        .guide-card::before{
            content:"";
            position:absolute;
            inset:0;
            pointer-events:none;
            background: linear-gradient(180deg, rgba(255,255,255,0.50), transparent 24%, transparent 70%, rgba(233,176,196,0.04));
        }

        .hero{ padding: 34px 30px 30px; }
        .hero-grid{
            display:grid;
            grid-template-columns: minmax(0, 1.25fr) minmax(320px, 0.75fr);
            gap: 20px;
            align-items: stretch;
        }
        @media (max-width: 920px){ .hero-grid{ grid-template-columns: 1fr; } }

        .eyebrow{
            display:inline-flex;
            align-items:center;
            gap:10px;
            font-family:"Orbitron",sans-serif;
            font-size:10px;
            letter-spacing:0.42em;
            color: #6d7385;
            margin-bottom: 14px;
        }
        .eyebrow::before{
            content:"";
            width: 28px;
            height: 1px;
            background: linear-gradient(90deg, rgba(109,115,133,0), rgba(109,115,133,0.85));
        }
        .hero-title{
            font-family:"Orbitron",sans-serif;
            font-weight: 900;
            font-size: clamp(2rem, 4vw, 3.2rem);
            line-height: 1.08;
            letter-spacing: 0.02em;
            color: #273246;
            margin: 0;
        }
        .hero-title .accent-pk{ color: rgb(233,176,196); }
        .hero-title .accent-lv{ color: rgb(204,186,216); }
        .hero-title .accent-bl{ color: rgb(186,198,220); }
        .hero-copy{
            margin-top: 16px;
            color: #6b7280;
            line-height: 1.8;
            font-size: 15px;
            max-width: 720px;
        }
        .hero-copy strong{ color:#2b3447; font-weight: 800; }
        .hero-chip-row{
            margin-top: 18px;
            display:flex;
            flex-wrap:wrap;
            gap:10px;
        }
        .hero-chip{
            display:inline-flex;
            align-items:center;
            gap:8px;
            padding: 10px 14px;
            border-radius: 999px;
            border: 1px solid rgba(204,186,216,0.58);
            background: rgba(255,255,255,0.62);
            color: #4f5a70;
            font-size: 12px;
            font-weight: 700;
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.76);
        }
        .hero-actions{
            margin-top: 20px;
            display:flex;
            flex-wrap:wrap;
            gap:10px;
        }
        .hero-btn{
            display:inline-flex;
            align-items:center;
            justify-content:center;
            gap:9px;
            min-width: 170px;
            padding: 13px 18px;
            border-radius: 18px;
            text-decoration: none;
            font-weight: 800;
            transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease, background .18s ease;
        }
        .hero-btn:hover{ transform: translateY(-1px); }
        .hero-btn--primary{
            color: #263245;
            border: 1px solid rgba(224, 192, 207, 0.88);
            background: linear-gradient(135deg, rgba(233,176,196,0.90), rgba(232,232,238,0.88));
            box-shadow: 0 14px 28px rgba(233,176,196,0.18);
        }
        .hero-btn--ghost{
            color: #3e4a60;
            border: 1px solid rgba(204,186,216,0.58);
            background: rgba(255,255,255,0.64);
            box-shadow: 0 8px 18px rgba(180, 176, 203, 0.10);
        }
        .hero-btn--ghost:hover,
        .hero-btn--primary:hover{
            box-shadow: 0 16px 32px rgba(179, 165, 197, 0.16);
        }

        .hero-side{
            display:grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }
        @media (max-width: 540px){ .hero-side{ grid-template-columns: 1fr; } }
        .mini-stat{
            border-radius: 22px;
            border: 1px solid rgba(209, 201, 229, 0.62);
            background: linear-gradient(180deg, rgba(255,255,255,0.68), rgba(255,255,255,0.58));
            padding: 18px 16px 16px;
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.76);
        }
        .mini-stat__label{
            font-family:"Orbitron",sans-serif;
            font-size: 9px;
            letter-spacing: 0.24em;
            color: #7d8495;
            margin-bottom: 10px;
        }
        .mini-stat__value{
            color:#2b3447;
            font-family:"Orbitron",sans-serif;
            font-size: 27px;
            font-weight: 900;
            line-height: 1;
            margin-bottom: 8px;
        }
        .mini-stat__desc{
            color: #6d7385;
            font-size: 13px;
            line-height: 1.65;
        }

        .section-head{ padding: 24px 24px 0; }
        .section-kicker{
            font-family:"Orbitron",sans-serif;
            font-size: 10px;
            letter-spacing: 0.28em;
            color: #7c8294;
            margin-bottom: 10px;
        }
        .section-title{
            color:#273246;
            font-family:"Orbitron",sans-serif;
            font-size: clamp(1.2rem, 2.4vw, 1.8rem);
            font-weight: 800;
            letter-spacing: 0.04em;
            margin: 0;
        }
        .section-sub{
            margin-top: 10px;
            color: #6d7385;
            line-height: 1.75;
            font-size: 14px;
        }

        .overview-grid,
        .system-grid,
        .grade-grid,
        .tip-grid{
            display:grid;
            gap:14px;
            padding: 22px 24px 24px;
        }
        .overview-grid{ grid-template-columns: repeat(4, minmax(0, 1fr)); }
        .system-grid{ grid-template-columns: repeat(2, minmax(0, 1fr)); }
        .grade-grid{ grid-template-columns: repeat(5, minmax(0, 1fr)); }
        .tip-grid{ grid-template-columns: repeat(2, minmax(0, 1fr)); }
        @media (max-width: 980px){
            .overview-grid{ grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .grade-grid{ grid-template-columns: repeat(3, minmax(0, 1fr)); }
        }
        @media (max-width: 760px){
            .system-grid, .tip-grid{ grid-template-columns: 1fr; }
            .grade-grid{ grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        @media (max-width: 540px){ .overview-grid, .grade-grid{ grid-template-columns: 1fr; } }

        .info-box,
        .system-card,
        .grade-card,
        .tip-card,
        .flow-step,
        .stat-card{
            border-radius: 24px;
            border: 1px solid rgba(214, 206, 231, 0.68);
            background: linear-gradient(180deg, rgba(255,255,255,0.72), rgba(255,255,255,0.58));
            padding: 18px 16px;
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.78);
        }
        .info-box__icon,
        .system-card__icon,
        .tip-card__icon{
            width: 42px;
            height: 42px;
            border-radius: 14px;
            display:flex;
            align-items:center;
            justify-content:center;
            color:#314055;
            margin-bottom: 14px;
            border: 1px solid rgba(211,198,223,0.74);
            background: linear-gradient(135deg, rgba(233,176,196,0.26), rgba(186,198,220,0.20));
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.76);
        }
        .info-box__title,
        .system-card__title,
        .tip-card__title{
            color:#273246;
            font-size: 16px;
            font-weight: 800;
            margin-bottom: 8px;
        }
        .info-box__desc,
        .system-card__desc,
        .tip-card__desc,
        .bullet-list li,
        .grade-meta li{
            color: #6d7385;
            font-size: 13px;
            line-height: 1.75;
        }
        .bullet-list,
        .grade-meta{ margin: 10px 0 0; padding-left: 18px; }
        .bullet-list li + li,
        .grade-meta li + li{ margin-top: 4px; }

        .flow-grid{
            display:grid;
            grid-template-columns: repeat(5, minmax(0, 1fr));
            gap: 12px;
            padding: 22px 24px 24px;
        }
        @media (max-width: 1120px){ .flow-grid{ grid-template-columns: repeat(3, minmax(0, 1fr)); } }
        @media (max-width: 760px){ .flow-grid{ grid-template-columns: 1fr; } }
        .flow-step{ min-height: 228px; }
        .flow-step__num{
            display:inline-flex;
            align-items:center;
            justify-content:center;
            width: 38px;
            height: 38px;
            border-radius: 14px;
            background: rgba(204,186,216,0.34);
            color:#344156;
            font-family:"Orbitron",sans-serif;
            font-size: 13px;
            font-weight: 900;
            margin-bottom: 14px;
            border: 1px solid rgba(204,186,216,0.66);
        }
        .flow-step__title{
            color:#273246;
            font-size: 17px;
            font-weight: 800;
            margin-bottom: 8px;
        }
        .flow-step__desc{
            color: #6d7385;
            font-size: 13px;
            line-height: 1.75;
        }
        .flow-tags{
            display:flex;
            flex-wrap:wrap;
            gap:8px;
            margin-top: 14px;
        }
        .flow-tag,
        .system-chip{
            padding: 6px 10px;
            border-radius: 999px;
            border: 1px solid rgba(209,198,226,0.70);
            background: rgba(255,255,255,0.72);
            color: #566278;
            font-size: 11px;
            font-weight: 700;
            white-space: nowrap;
        }

        .stats-grid{
            display:grid;
            grid-template-columns: repeat(5, minmax(0, 1fr));
            gap:12px;
            padding: 22px 24px 24px;
        }
        @media (max-width: 980px){ .stats-grid{ grid-template-columns: repeat(3, minmax(0, 1fr)); } }
        @media (max-width: 640px){ .stats-grid{ grid-template-columns: 1fr; } }
        .stat-card__key{
            font-family:"Orbitron",sans-serif;
            font-size: 9px;
            letter-spacing: 0.24em;
            margin-bottom: 8px;
        }
        .stat-card__name{
            color:#273246;
            font-size: 16px;
            font-weight: 800;
            margin-bottom: 8px;
        }
        .stat-card__desc{
            color: #6d7385;
            font-size: 13px;
            line-height: 1.7;
        }
        .stat-card--v .stat-card__key{ color: rgb(233,176,196); }
        .stat-card--d .stat-card__key{ color: rgb(204,186,216); }
        .stat-card--s .stat-card__key{ color: #c99024; }
        .stat-card--m .stat-card__key{ color: rgb(186,198,220); }
        .stat-card--t .stat-card__key{ color: #6fae9a; }

        .system-card__head{
            display:flex;
            align-items:flex-start;
            justify-content:space-between;
            gap:12px;
            margin-bottom: 8px;
        }

        .grade-card{ text-align:center; padding: 20px 14px 18px; }
        .grade-letter{
            font-family:"Orbitron",sans-serif;
            font-weight: 900;
            font-size: 36px;
            line-height: 1;
            margin-bottom: 10px;
        }
        .grade-title{
            color:#273246;
            font-size: 15px;
            font-weight: 800;
            margin-bottom: 10px;
        }
        .grade-card p{
            color: #6d7385;
            font-size: 13px;
            line-height: 1.7;
            margin: 0;
        }
        .grade-card--s .grade-letter{ color:#d39a2c; }
        .grade-card--a .grade-letter{ color:rgb(233,176,196); }
        .grade-card--b .grade-letter{ color:rgb(204,186,216); }
        .grade-card--c .grade-letter{ color:rgb(186,198,220); }
        .grade-card--d .grade-letter{ color:#9ca3af; }

        .footer-callout{
            padding: 24px;
            display:flex;
            align-items:center;
            justify-content:space-between;
            gap: 16px;
            flex-wrap: wrap;
        }
        .footer-callout__title{
            color:#273246;
            font-size: 20px;
            font-weight: 900;
            margin-bottom: 8px;
        }
        .footer-callout__desc{
            color: #6d7385;
            line-height: 1.75;
            font-size: 14px;
        }

        /* 회원 등급 블록만 전체적으로 촘촘하게 */
        #account-rank .section-head{
            padding: 12px 18px 0;
        }
        #account-rank .section-kicker{
            margin-bottom: 4px;
        }
        #account-rank .section-title{
            font-size: clamp(1.1rem, 2.2vw, 1.55rem);
        }
        #account-rank .section-sub{
            margin-top: 6px;
            font-size: 13px;
            line-height: 1.55;
        }
        .account-rank-grid{
            display:grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 10px;
            padding: 0 18px 8px;
        }
        @media (max-width: 760px){ .account-rank-grid{ grid-template-columns: 1fr; } }
        .account-rank-note{
            border-radius: 16px;
            border: 1px solid rgba(214, 206, 231, 0.68);
            background: linear-gradient(180deg, rgba(255,255,255,0.72), rgba(255,255,255,0.58));
            padding: 11px 12px;
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.78);
        }
        .account-rank-note__title{
            color:#273246;
            font-size: 13px;
            font-weight: 800;
            margin-bottom: 6px;
        }
        .account-rank-note p{
            color: #6d7385;
            font-size: 12px;
            line-height: 1.5;
            margin: 0;
        }
        .account-rank-note p + p{ margin-top: 6px; }
        .account-rank-tiers-head{
            padding: 4px 18px 4px;
        }
        .account-rank-tiers-head .section-kicker{
            margin-bottom: 2px;
        }
        .account-rank-tiers-head .section-title{
            font-size: 1rem !important;
            margin: 0 0 4px 0 !important;
        }
        .account-rank-tiers-head .section-sub{
            margin-top: 0;
            font-size: 12px;
            line-height: 1.45;
        }
        .account-rank-table-wrap{
            overflow-x: auto;
            padding: 2px 18px 14px;
        }
        .account-rank-table{
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
        }
        .account-rank-table th,
        .account-rank-table td{
            padding: 5px 8px;
            border-bottom: 1px solid rgba(214, 206, 231, 0.45);
            text-align: left;
            color: #4f5a70;
        }
        .account-rank-table th{
            font-family:"Orbitron",sans-serif;
            font-size: 9px;
            letter-spacing: 0.1em;
            color: #7c8294;
            background: rgba(255,255,255,0.45);
            padding-top: 6px;
            padding-bottom: 6px;
        }
        .account-rank-formula{
            display:inline-block;
            margin-top: 4px;
            padding: 5px 9px;
            border-radius: 10px;
            border: 1px solid rgba(209,198,226,0.70);
            background: rgba(255,255,255,0.72);
            font-family:"Orbitron",sans-serif;
            font-size: 11px;
            font-weight: 800;
            color: #4f5a70;
            letter-spacing: 0.02em;
        }
    </style>
</head>

<body class="page-main min-h-screen flex flex-col">
    <%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>

    <main class="flex-1 px-6 pb-16" style="padding-top: calc(var(--nav-h) + 24px);">
        <div class="guide-wrap">
            <section class="guide-section guide-card hero">
                <div class="hero-grid">
                    <div>
                        <div class="eyebrow">NEXT DEBUT GUIDE</div>
                        <h1 class="hero-title">
                            선택과 조합으로 만드는<br/>
                            <span class="accent-pk">3개월 데뷔 프로젝트</span>
                        </h1>
                        <div class="hero-copy">
                            당신은 <strong>프로듀서</strong>로서 연습생 4명을 성장시키고, <strong>하루 2번의 선택</strong>을 쌓아
                            최종 데뷔 무대까지 이끌어야 합니다. <strong>게임 진행</strong>, <strong>시너지</strong>, <strong>이벤트</strong>,
                            <strong>랭킹</strong>, <strong>데뷔 등급</strong>이 모두 연결되어 결과를 바꿉니다.
                        </div>
                        <div class="hero-chip-row">
                            <span class="hero-chip"><i class="fas fa-calendar-days"></i> 총 3개월 진행</span>
                            <span class="hero-chip"><i class="fas fa-sun"></i> 하루 2회 선택</span>
                            <span class="hero-chip"><i class="fas fa-bolt"></i> 케미 보너스 반영</span>
                            <span class="hero-chip"><i class="fas fa-ranking-star"></i> 최종 랭킹 경쟁</span>
                            <a class="hero-chip" href="#account-rank" style="text-decoration:none;color:inherit;"><i class="fas fa-id-badge"></i> 회원 등급·경험치</a>
                            <a class="hero-chip" href="#play-score" style="text-decoration:none;color:inherit;"><i class="fas fa-calculator"></i> 플레이 점수 산출</a>
                        </div>
                        <div class="hero-actions">
                            <a class="hero-btn hero-btn--primary" href="${ctx}/game"><i class="fas fa-play"></i> 게임 시작</a>
                            <a class="hero-btn hero-btn--ghost" href="${ctx}/game/run/ranking"><i class="fas fa-trophy"></i> 랭킹 보기</a>
                        </div>
                    </div>
                    <div class="hero-side">
                        <div class="mini-stat">
                            <div class="mini-stat__label">RUN LENGTH</div>
                            <div class="mini-stat__value">84일</div>
                            <div class="mini-stat__desc">1개월 28일 기준으로 총 3개월을 진행합니다. 첫날 튜토리얼 이후 본격적인 운영이 시작됩니다.</div>
                        </div>
                        <div class="mini-stat">
                            <div class="mini-stat__label">CHOICE LOOP</div>
                            <div class="mini-stat__value">168턴</div>
                            <div class="mini-stat__desc">아침·저녁 선택이 누적됩니다. 짧은 이득보다 전체 흐름 관리가 더 중요합니다.</div>
                        </div>
                        <div class="mini-stat">
                            <div class="mini-stat__label">CORE STATS</div>
                            <div class="mini-stat__value">5개</div>
                            <div class="mini-stat__desc">보컬, 댄스, 스타성, 멘탈, 팀워크가 모든 평가와 이벤트의 핵심 기준이 됩니다.</div>
                        </div>
                        <div class="mini-stat">
                            <div class="mini-stat__label">FINAL GOAL</div>
                            <div class="mini-stat__value">S ~ D</div>
                            <div class="mini-stat__desc">최종 총점과 운영 결과에 따라 데뷔 등급과 엔딩 루트가 달라집니다.</div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="guide-section guide-card">
                <div class="section-head">
                    <div class="section-kicker">OVERVIEW</div>
                    <h2 class="section-title">먼저 알아야 할 핵심</h2>
                    <div class="section-sub">이 프로젝트는 <strong>84일(아침·저녁 168선택)</strong> 루프에 <strong>피로도</strong>·<strong>팬(국내·해외)</strong>·<strong>멤버 상태</strong>가 얹혀 있습니다. 선택지 <strong>A~D</strong>는 각각 보컬·댄스·팀웍·멘탈에 연결되며, 그 외 흐름에서는 스타가 다뤄집니다.</div>
                </div>
                <div class="overview-grid">
                    <div class="info-box">
                        <div class="info-box__icon"><i class="fas fa-user-group"></i></div>
                        <div class="info-box__title">4인 · 그룹 타입</div>
                        <div class="info-box__desc">연습생 4명과 혼성·남·여 구성이 정해지면, 첫날 튜토리얼과 이후 씬 풀(지문)이 달라집니다. 로스터 단계에서 케미(시너지)도 미리 확인할 수 있습니다.</div>
                    </div>
                    <div class="info-box">
                        <div class="info-box__icon"><i class="fas fa-repeat"></i></div>
                        <div class="info-box__title">턴 누적 · 피로</div>
                        <div class="info-box__desc">매 턴 행동은 피로를 쌓고, 피로가 높을수록 스탯 성장이 불안정해집니다. <strong>D(멘탈)</strong> 선택은 피로를 낮추는 쪽으로 설계되어 있습니다.</div>
                    </div>
                    <div class="info-box">
                        <div class="info-box__icon"><i class="fas fa-wave-square"></i></div>
                        <div class="info-box__title">중간평가 버프</div>
                        <div class="info-box__desc"><strong>56일차 저녁</strong> 이후 중간 평가에서 팀 총 스탯으로 S~D 티어가 정해지고, 그다음 <strong>7턴</strong> 동안 성장에 보정이 붙거나 불리해질 수 있습니다.</div>
                    </div>
                    <div class="info-box">
                        <div class="info-box__icon"><i class="fas fa-crown"></i></div>
                        <div class="info-box__title">한 가지 점수, 세 가지 결과</div>
                        <div class="info-box__desc">멤버 4명의 <strong>다섯 스탯 합(최대 2000)</strong>이 데뷔 등급·<strong>글로벌 랭킹 점수</strong>·일부 엔딩 분기의 기준이 됩니다. 팬 수는 별도로 계정 경험치에 쓰입니다.</div>
                    </div>
                </div>
            </section>

            <section class="guide-section guide-card" id="play-score">
                <div class="section-head">
                    <div class="section-kicker">SCORE</div>
                    <h2 class="section-title">플레이 점수 산출 방식</h2>
                    <div class="section-sub">
                        데뷔 결과·글로벌 랭킹에 쓰이는 <strong>0~1000</strong> 점수는 아래 순서로 계산됩니다.
                        스탯은 DB와 화면 모두 <strong>0~100</strong> 기준으로 사용됩니다.
                    </div>
                </div>
                <div class="system-grid" style="padding-top:0;grid-template-columns:1fr;">
                    <div class="system-card">
                        <div class="system-card__title">① 로스터 능력치 원점 합</div>
                        <div class="system-card__desc">
                            멤버 전원의 보컬·댄스·스타성·멘탈·팀워크를 모두 더합니다.
                            4인 로스터 기준 이론 상한은 <strong>400</strong>(인당 다섯 스탯 합 최대 100 × 4명).
                        </div>
                    </div>
                    <div class="system-card">
                        <div class="system-card__title">② 만점 1000 스케일로 환산 (케미 제외)</div>
                        <div class="system-card__desc">
                            <span class="account-rank-formula">① × (1000 ÷ 2000) = ① × 0.5</span>
                            반올림하며 상한은 1000입니다. 이 단계까지는 <strong>케미 보너스가 들어가지 않습니다</strong>.
                        </div>
                    </div>
                    <div class="system-card">
                        <div class="system-card__title">③ 케미(시너지) 보너스 반영</div>
                        <div class="system-card__desc">
                            활성 시너지 보너스(%)를 합산한 뒤 등급 보너스가 더해져 <strong>총 케미 %</strong>가 정해집니다.
                            <span class="account-rank-formula">② × (100 + 케미%) ÷ 100</span>
                            반올림, 상한 1000. 시너지 상세는 위 <strong>시너지 시스템</strong> 항목을 참고하세요.
                        </div>
                    </div>
                    <div class="system-card">
                        <div class="system-card__title">④ 진행 턴 보정</div>
                        <div class="system-card__desc">
                            같은 능력·케미라도 <strong>초반에 데뷔를 끝내면 점수가 낮게</strong> 반영되고, 턴이 진행될수록 계수가 <strong>1.0</strong>에 가까워집니다.
                            적용 턴은 1~169 범위로 잡히며, 최종 식은
                            <span class="account-rank-formula">③ × 진행계수</span>
                            (반올림, 상한 1000)입니다. 진행 계수는 턴 1에서 약 <strong>0.14</strong>, 턴 169에서 <strong>1.0</strong>에 수렴합니다.
                        </div>
                    </div>
                    <div class="system-card">
                        <div class="system-card__title">⑤ 최종 점수</div>
                        <div class="system-card__desc">
                            ④까지의 값이 <strong>데뷔 결과의 TOTAL SCORE</strong>·<strong>등급(S~D)</strong>·<strong>랭킹 점수</strong>와 일치합니다.
                            엔딩 화면에서는 요약만 보여 주며, 위 단계를 모두 적용한 결과입니다.
                        </div>
                    </div>
                </div>
            </section>

            <section class="guide-section guide-card" id="account-rank">
                <div class="section-head">
                    <div class="section-kicker">ACCOUNT RANK</div>
                    <h2 class="section-title">회원 등급 · 경험치</h2>
                    <div class="section-sub">
                        <strong>게임 안 데뷔 등급(S~D)</strong>과는 별개로, <strong>계정에 쌓이는 누적 경험치</strong>로 결정되는 등급입니다.
                        상단 네비·마이페이지·엔딩 결과에서 확인할 수 있습니다.
                    </div>
                </div>
                <div class="account-rank-grid">
                    <div class="account-rank-note">
                        <div class="account-rank-note__title"><i class="fas fa-arrow-trend-up"></i> 경험치는 어떻게 오르나요?</div>
                        <p>
                            플레이 한 판이 <strong>정상 종료(FINISHED)</strong>되면, 그 런에서 달성한 <strong>총 팬 수</strong>를 기준으로 등급 경험치가 한 번 반영됩니다.
                            같은 런에 대해 경험치는 <strong>중복 지급되지 않습니다</strong>.
                        </p>
                        <p>
                            <span class="account-rank-formula">등급 EXP = 총 팬 ÷ 10 (소수점 버림)</span>
                        </p>
                        <p>
                            예: 총 팬 55명 → <strong>+5 EXP</strong>. 비로그인(게스트) 플레이에는 계정 경험치가 쌓이지 않습니다.
                        </p>
                    </div>
                    <div class="account-rank-note">
                        <div class="account-rank-note__title"><i class="fas fa-layer-group"></i> 누적형이란?</div>
                        <p>
                            경험치는 <strong>차감되지 않는 누적 수치</strong>입니다. 일정 구간을 넘으면 등급 이름이 올라가며,
                            다음 등급까지 남은 EXP는 상단 프로필 영역의 막대로 확인할 수 있습니다. 최고 등급에 도달하면 막대가 가득 찬 상태로 표시됩니다.
                        </p>
                    </div>
                </div>
                <div class="account-rank-tiers-head">
                    <div class="section-kicker">TIERS</div>
                    <h3 class="section-title">등급 단계 (누적 경험치 기준)</h3>
                    <div class="section-sub">아래 <strong>누적 EXP</strong> 이상이면 해당 등급으로 표시됩니다.</div>
                </div>
                <div class="account-rank-table-wrap">
                    <table class="account-rank-table member-rank-tier-table">
                        <thead>
                            <tr>
                                <th scope="col">누적 EXP</th>
                                <th scope="col">등급명</th>
                                <th scope="col">코드</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr class="member-rank-tier member-rank-tier--ROOKIE"><td><strong>0</strong> 이상</td><td>루키</td><td>ROOKIE</td></tr>
                            <tr class="member-rank-tier member-rank-tier--TRAINEE"><td><strong>300</strong> 이상</td><td>트레이니</td><td>TRAINEE</td></tr>
                            <tr class="member-rank-tier member-rank-tier--RISING_STAR"><td><strong>800</strong> 이상</td><td>라이징 스타</td><td>RISING_STAR</td></tr>
                            <tr class="member-rank-tier member-rank-tier--IDOL"><td><strong>1,800</strong> 이상</td><td>아이돌</td><td>IDOL</td></tr>
                            <tr class="member-rank-tier member-rank-tier--SUPERSTAR"><td><strong>3,500</strong> 이상</td><td>슈퍼스타</td><td>SUPERSTAR</td></tr>
                            <tr class="member-rank-tier member-rank-tier--LEGEND"><td><strong>6,000</strong> 이상</td><td>레전드</td><td>LEGEND</td></tr>
                            <tr class="member-rank-tier member-rank-tier--MYTHIC"><td><strong>10,000</strong> 이상</td><td>미스틱</td><td>MYTHIC</td></tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="guide-section guide-card">
                <div class="section-head">
                    <div class="section-kicker">FLOW</div>
                    <h2 class="section-title">게임 진행 구조</h2>
                    <div class="section-sub">페이즈는 날짜·아침/저녁 형태로 진행되며, <strong>1·2·3개월차</strong>마다 씬 풀이 나뉘고 <strong>2주 단위(전반 / 후반)</strong>로 같은 달 안에서도 지문이 갈립니다.</div>
                </div>
                <div class="flow-grid">
                    <div class="flow-step">
                        <div class="flow-step__num">01</div>
                        <div class="flow-step__title">로스터 · 그룹 확정</div>
                        <div class="flow-step__desc">연습생 4명을 고르고 혼성/남성/여성 그룹이 정해집니다. 시너지(케미)는 로스터 화면에서 미리 계산되어 보여집니다.</div>
                        <div class="flow-tags">
                            <span class="flow-tag">시너지 미리보기</span>
                            <span class="flow-tag">튜토리얼 풀 분기</span>
                        </div>
                    </div>
                    <div class="flow-step">
                        <div class="flow-step__num">02</div>
                        <div class="flow-step__title">일일 루프 (84일)</div>
                        <div class="flow-step__desc"><strong>DAY1</strong>은 그룹별 튜토리얼 풀, <strong>DAY2~84</strong>는 월·전후반·아침/저녁 조합의 씬 풀에서 지문이 나옵니다. 턴마다 <strong>A~D</strong>는 보컬·댄스·팀웍·멘탈 중 하나에 스탯 변동을 주고, 팬(코어·캐주얼·라이트)과 피로도가 함께 움직입니다.</div>
                        <div class="flow-tags">
                            <span class="flow-tag">168 선택</span>
                            <span class="flow-tag">팬 · 피로</span>
                        </div>
                    </div>
                    <div class="flow-step">
                        <div class="flow-step__num">03</div>
                        <div class="flow-step__title">씬 · SPECIAL · 상태</div>
                        <div class="flow-step__desc">씬마다 이벤트 타입(컨디션·안무·미디어 등)이 있어 피로 가중이 달라질 수 있습니다. <strong>SPECIAL</strong>은 한 번에 크게 노리지만 실패·무변도 있고, 피로가 높을수록 실패 확률이 올라갑니다. 멤버에게는 턴마다 상태 효과가 틱으로 적용됩니다.</div>
                        <div class="flow-tags">
                            <span class="flow-tag">고위험 SPECIAL</span>
                            <span class="flow-tag">상태 이상</span>
                        </div>
                    </div>
                    <div class="flow-step">
                        <div class="flow-step__num">04</div>
                        <div class="flow-step__title">중간 평가 (56일차 후)</div>
                        <div class="flow-step__desc">팀 총 스탯 합으로 <strong>MID_EVAL_S ~ MID_EVAL_D</strong> 버킷이 정해집니다(예: 240 이상 S). 이후 <strong>113~119턴</strong> 동안 S/A는 성장이 한결 수월해지고, C/D는 하락이 잘 붙습니다.</div>
                        <div class="flow-tags">
                            <span class="flow-tag">7턴 보정</span>
                            <span class="flow-tag">반환점 점수</span>
                        </div>
                    </div>
                    <div class="flow-step">
                        <div class="flow-step__num">05</div>
                        <div class="flow-step__title">최종 데뷔 · 엔딩</div>
                        <div class="flow-step__desc"><strong>84일차 저녁</strong>까지 쌓인 스탯 합으로 <strong>S~D 데뷔 등급</strong>이 정해지고, 케미 등급·스페셜 성공 횟수·스타 평균 등이 <strong>엔딩 루트</strong>(예: 월드 투어, 바이럴 히트)를 가릅니다. 종료된 런은 같은 총 스탯으로 랭킹에 올라갑니다.</div>
                        <div class="flow-tags">
                            <span class="flow-tag">총합 0~400</span>
                            <span class="flow-tag">엔딩 분기</span>
                        </div>
                    </div>
                </div>
            </section>

            <section class="guide-section guide-card">
                <div class="section-head">
                    <div class="section-kicker">STATS</div>
                    <h2 class="section-title">핵심 능력치 5개</h2>
                    <div class="section-sub">능력치 이름만 외우는 것보다, 어떤 장면에서 체감되는지를 알고 운영하는 것이 더 중요합니다.</div>
                </div>
                <div class="stats-grid">
                    <div class="stat-card stat-card--v">
                        <div class="stat-card__key">VOCAL</div>
                        <div class="stat-card__name">보컬</div>
                        <div class="stat-card__desc">최종 무대 완성도와 평가 점수에 직접적으로 연결되는 핵심 스탯입니다. 후반 안정감에 큰 영향을 줍니다.</div>
                    </div>
                    <div class="stat-card stat-card--d">
                        <div class="stat-card__key">DANCE</div>
                        <div class="stat-card__name">댄스</div>
                        <div class="stat-card__desc">퍼포먼스 밀도를 높이는 능력치입니다. 무대형 이벤트와 조합형 운영에서 체감이 큽니다.</div>
                    </div>
                    <div class="stat-card stat-card--s">
                        <div class="stat-card__key">STAR</div>
                        <div class="stat-card__name">스타성</div>
                        <div class="stat-card__desc">팬 수 확보와 바이럴 계열 결과에 영향을 줍니다. 대중 반응을 끌어내는 지표로 보면 됩니다.</div>
                    </div>
                    <div class="stat-card stat-card--m">
                        <div class="stat-card__key">MENTAL</div>
                        <div class="stat-card__name">멘탈</div>
                        <div class="stat-card__desc">부정 이벤트나 연속 손해 구간을 버티는 힘입니다. 초반엔 티가 덜 나도 후반 체감이 큽니다.</div>
                    </div>
                    <div class="stat-card stat-card--t">
                        <div class="stat-card__key">TEAMWORK</div>
                        <div class="stat-card__name">팀워크</div>
                        <div class="stat-card__desc">시너지 발동과 전체 안정성의 기반입니다. 조합 플레이를 살리고 싶다면 반드시 챙겨야 합니다.</div>
                    </div>
                </div>
            </section>

            <section class="guide-section guide-card">
                <div class="section-head">
                    <div class="section-kicker">SYSTEMS</div>
                    <h2 class="section-title">핵심 시스템 · 메타</h2>
                    <div class="section-sub">핵심 시스템은 <strong>게임 런(데뷔 프로젝트)</strong> 안에서 동작하고, 메타는 <strong>도감·길거리 캐스팅·상점·뽑기</strong>로 이어집니다. 플레이 성과에 따라 해금 범위가 넓어지며, 일부 콘텐츠는 조건이 공개되지 않은 <strong>숨겨진 라인</strong>으로 준비되어 있습니다.</div>
                </div>
                <div class="system-grid">
                    <div class="system-card">
                        <div class="system-card__head">
                            <div>
                                <div class="system-card__icon"><i class="fas fa-bolt"></i></div>
                                <div class="system-card__title">시너지</div>
                            </div>
                            <div class="system-chip"><i class="fas fa-plus"></i> 상위 4개만 반영</div>
                        </div>
                        <div class="system-card__desc">조건을 만족하는 시너지가 여러 개 나와도, <strong>보너스 퍼센트가 큰 순</strong>으로 최대 <strong>4개</strong>만 적용됩니다. 각 시너지의 %를 더한 뒤, 활성 개수에 따라 <strong>등급 보너스</strong>가 한 번 더 더해져 케미 등급(S~D)과 총 보너스가 정해집니다.</div>
                        <ul class="bullet-list">
                            <li>활성 1개: 등급 보너스 +1 · 2개: +3 · 3개: +5 · 4개 이상: +10</li>
                            <li><strong>발동 조건 예시</strong> — 보컬·댄스 평균/고스탯 인원(<strong>하모니 라인</strong>, <strong>퍼포먼스 라인</strong>, <strong>꿀보이스</strong>, <strong>칼군무</strong> 등), 남녀 2:2(<strong>완벽한 조화</strong>)·동일 성별 4인(<strong>동일 성별 결속</strong>), 멘탈·팀워크(<strong>안정된 팀워크</strong>, <strong>분위기 메이커</strong>), 동갑(<strong>친구 사이</strong>), 스타 집중(<strong>시선 캐치</strong>·<strong>무대 장악</strong>), 개인 총합 상위(<strong>에이스 듀오</strong>), 전반 밸런스(<strong>올라운더 밸런스</strong>) 등</li>
                        </ul>
                    </div>
                    <div class="system-card">
                        <div class="system-card__head">
                            <div>
                                <div class="system-card__icon"><i class="fas fa-dice"></i></div>
                                <div class="system-card__title">턴 이벤트</div>
                            </div>
                            <div class="system-chip"><i class="fas fa-random"></i> 씬 풀 + 확률</div>
                        </div>
                        <div class="system-card__desc">같은 버킷 안에서도 씬이 랜덤으로 골라지며, 최근 씬·이벤트 타입 반복은 완화 로직이 있습니다. 턴마다 한 멤버에게 스탯이 들어가고, 선택지에 따라 <strong>국내(코어)·해외(캐주얼+라이트)</strong> 팬 변동이 달라집니다.</div>
                        <ul class="bullet-list">
                            <li><strong>중간평가 이후 7턴</strong>: 티어에 따라 성장 확률이 유리·불리해짐</li>
                            <li><strong>SPECIAL</strong>: 스탯이 크게 오를 수도, 무변·하락도 있음 (피로 높을수록 위험)</li>
                            <li>스페셜 중 <strong>스탯 증가로 기록된 횟수</strong>는 엔딩 조건에 사용됨</li>
                        </ul>
                    </div>
                    <div class="system-card">
                        <div class="system-card__head">
                            <div>
                                <div class="system-card__icon"><i class="fas fa-ranking-star"></i></div>
                                <div class="system-card__title">랭킹</div>
                            </div>
                            <div class="system-chip"><i class="fas fa-trophy"></i> 상위 10위</div>
                        </div>
                        <div class="system-card__desc"><strong>FINISHED</strong> 상태인 런만 대상이며, 점수는 멤버 4명의 <strong>보컬+댄스+스타+멘탈+팀웍 합</strong>과 데뷔 총점이 동일합니다. 화면에는 순위·점수·<strong>1위 대비 격차</strong>·<strong>바로 위 순위 대비 격차</strong>가 나옵니다.</div>
                        <ul class="bullet-list">
                            <li>팬 수는 랭킹 점수가 아니라 <strong>계정 경험치</strong>(정상 종료 시 총 팬÷10)에 반영</li>
                            <li>동점은 정렬 순서에 따라 순위가 매겨지며, 목록은 상위 10건만 표시</li>
                            <li>한 판에서 총 스탯을 올리는 것이 곧 랭킹 직행 루트</li>
                        </ul>
                    </div>
                    <div class="system-card">
                        <div class="system-card__head">
                            <div>
                                <div class="system-card__icon"><i class="fas fa-book-open"></i></div>
                                <div class="system-card__title">도감 / 해금</div>
                            </div>
                            <a class="system-chip" href="${ctx}/trainees" style="text-decoration:none;color:inherit;"><i class="fas fa-arrow-up-right-from-square"></i> /trainees</a>
                        </div>
                        <div class="system-card__desc">전체 연습생을 확인하고, 진행도에 따라 풀리는 그룹/대상을 추적할 수 있습니다. 로그인하면 <strong>보유 여부</strong>가 표시되어 로스터 후보를 빠르게 정리할 수 있고, 일부 카드는 <strong>히든 표기만 보이는 상태</strong>로 남아 탐색 재미를 유지합니다. 상세 모달에서는 <strong>카드 강화(+0~MAX)</strong>를 진행할 수 있으며, 강화 단계는 게임 로스터/인게임에도 동일하게 반영됩니다.</div>
                        <ul class="bullet-list">
                            <li>프로필·스탯·이미지는 게임 내 데이터와 같은 풀을 기준으로 표시됩니다</li>
                            <li>해금 전/히든 대상은 정보가 제한되며, 도감에서는 노출 규칙이 별도로 적용됩니다</li>
                            <li><strong>강화 재료 소모</strong>: 0→1은 1장, 1→2는 2장, 2→3은 3장, 3→4는 4장, 4→5는 5장(중복 카드 사용)</li>
                            <li><strong>강화 효과</strong>: +1/+2/+3/+4/+5(MAX)에서 전 능력치가 각각 +1/+2/+3/+4/+7 적용됩니다</li>
                            <li>정답형 조건 안내 대신, 플레이 로그와 변화로 추리하는 구조를 의도했습니다</li>
                        </ul>
                    </div>
                    <div class="system-card">
                        <div class="system-card__head">
                            <div>
                                <div class="system-card__icon"><i class="fas fa-map-location-dot"></i></div>
                                <div class="system-card__title">길거리 캐스팅</div>
                            </div>
                            <a class="system-chip" href="${ctx}/boards/map" style="text-decoration:none;color:inherit;"><i class="fas fa-arrow-up-right-from-square"></i> /boards/map</a>
                        </div>
                        <div class="system-card__desc"><strong>맵 게시판</strong>에서 지역·일정이 있는 캐스팅 이벤트를 확인하고, 지도 탐색으로 <strong>스팟 버프</strong>를 얻을 수 있습니다. 하루 <strong>무료 3회</strong>·이후 탐색당 <strong>50코인</strong> 규칙이 적용됩니다.</div>
                        <ul class="bullet-list">
                            <li>스팟 버프는 <strong>뽑기</strong> 화면에서 확률에 반영되며, 일정 시간 후 만료됩니다</li>
                            <li>게시글·월간 캘린더·<strong>.ics</strong> 내보내기로 일정을 가져갈 수 있습니다</li>
                        </ul>
                    </div>
                    <div class="system-card">
                        <div class="system-card__head">
                            <div>
                                <div class="system-card__icon"><i class="fas fa-store"></i></div>
                                <div class="system-card__title">상점</div>
                            </div>
                            <a class="system-chip" href="${ctx}/market/shop" style="text-decoration:none;color:inherit;"><i class="fas fa-arrow-up-right-from-square"></i> /market/shop</a>
                        </div>
                        <div class="system-card__desc">보유 <strong>코인</strong>으로 훈련·회복 계열 <strong>아이템</strong>을 사서 인벤토리에 넣을 수 있습니다. 산 아이템은 데뷔 프로젝트 플레이 중 인벤토리에서 사용해 스탯을 보강하는 데 쓰입니다.</div>
                        <ul class="bullet-list">
                            <li>코인은 게임 플레이·충전 등 계정 정책에 따라 변동</li>
                            <li>상점은 <strong>런 밖</strong>에서 구매·비축, <strong>런 안</strong>에서 소비하는 흐름입니다</li>
                        </ul>
                    </div>
                    <div class="system-card">
                        <div class="system-card__head">
                            <div>
                                <div class="system-card__icon"><i class="fas fa-gift"></i></div>
                                <div class="system-card__title">뽑기</div>
                            </div>
                            <a class="system-chip" href="${ctx}/market/gacha" style="text-decoration:none;color:inherit;"><i class="fas fa-arrow-up-right-from-square"></i> /market/gacha</a>
                        </div>
                        <div class="system-card__desc">코인을 써서 <strong>연습생 카드</strong>를 뽑고, 계정에 <strong>보유 수량</strong>으로 쌓입니다. 이미 보유 중인 연습생이 다시 나오면 수량만 늘어나며, 도감·게임 로스터에서 같은 데이터로 이어집니다.</div>
                        <ul class="bullet-list">
                            <li><strong>길거리 캐스팅</strong>에서 얻은 스팟 버프, 진행 중인 <strong>캐스팅 이벤트</strong>는 뽑기 화면에서 확률·표시에 반영됩니다</li>
                            <li>1회 뽑기와 다회 뽑기(설정된 횟수 묶음) 중 선택 가능</li>
                        </ul>
                    </div>
                    <div class="system-card">
                        <div class="system-card__head">
                            <div>
                                <div class="system-card__icon"><i class="fas fa-clone"></i></div>
                                <div class="system-card__title">포토카드 뽑기</div>
                            </div>
                            <a class="system-chip" href="${ctx}/market/photocard" style="text-decoration:none;color:inherit;"><i class="fas fa-arrow-up-right-from-square"></i> /market/photocard</a>
                        </div>
                        <div class="system-card__desc">
                            코인을 써서 연습생별 <strong>포토카드(등급 R/SR/SSR)</strong>를 뽑습니다.
                            포토카드는 “한 장의 카드”라기보다 <strong>해당 연습생의 추가 등급 일러스트 + 능력치 보너스</strong>를 해금하는 개념입니다.
                        </div>
                        <ul class="bullet-list">
                            <li><strong>뽑기 횟수</strong>: 1회(중복이면 코인 차감 없음) · 5회/10회(묶음 가격 선차감 후 결과 결정)</li>
                            <li><strong>중복 처리</strong>: 이미 보유한 조합(연습생+등급)이 나오면 “중복”으로 표시되며, 신규만 도감에 해금됩니다</li>
                            <li><strong>장착</strong>: 신규 획득 시 보유 중 가장 높은 등급이 자동 장착되며, 도감 상세에서 등급 버튼으로 즉시 변경할 수 있습니다</li>
                            <li><strong>효과</strong>: 장착 등급에 따라 해당 연습생 능력치에 <strong>+5% / +10% / +15%</strong> 보너스가 적용되고, 도감/게임 화면에서 카드에 <strong>글로우</strong>로 표시됩니다</li>
                        </ul>
                    </div>
                </div>
            </section>

            <section class="guide-section guide-card">
                <div class="section-head">
                    <div class="section-kicker">DEBUT GRADE</div>
                    <h2 class="section-title">데뷔 등급 기준</h2>
                    <div class="section-sub">최종 데뷔 평가는 멤버 4명의 총 스탯 합산값을 기준으로 계산됩니다. 총점이 높을수록 더 좋은 결과와 엔딩으로 이어집니다.</div>
                </div>
                <div class="grade-grid">
                    <div class="grade-card grade-card--s">
                        <div class="grade-letter">S</div>
                        <div class="grade-title">월드클래스 데뷔</div>
                        <p>총점 320 이상. 압도적인 완성도로 최고의 데뷔 결과를 노릴 수 있습니다.</p>
                    </div>
                    <div class="grade-card grade-card--a">
                        <div class="grade-letter">A</div>
                        <div class="grade-title">성공적인 데뷔</div>
                        <p>총점 260 이상. 높은 안정감과 퍼포먼스를 갖춘 상위권 결과입니다.</p>
                    </div>
                    <div class="grade-card grade-card--b">
                        <div class="grade-letter">B</div>
                        <div class="grade-title">기대되는 데뷔</div>
                        <p>총점 210 이상. 가능성과 성장 여지가 있는 준수한 결과입니다.</p>
                    </div>
                    <div class="grade-card grade-card--c">
                        <div class="grade-letter">C</div>
                        <div class="grade-title">평범한 데뷔</div>
                        <p>총점 160 이상. 데뷔는 가능하지만 완성도 면에서는 아쉬움이 남습니다.</p>
                    </div>
                    <div class="grade-card grade-card--d">
                        <div class="grade-letter">D</div>
                        <div class="grade-title">아쉬운 데뷔</div>
                        <p>총점 160 미만. 운영 방향과 조합을 다시 점검해보는 것이 좋습니다.</p>
                    </div>
                </div>
            </section>

            <section class="guide-section guide-card">
                <div class="section-head">
                    <div class="section-kicker">PLAY TIPS</div>
                    <h2 class="section-title">플레이 전략</h2>
                    <div class="section-sub">구현상 <strong>피로도</strong>와 <strong>중간평가 7턴</strong>이 성장 RNG를 가장 크게 흔듭니다. 그다음이 <strong>로스터 시너지</strong>와 <strong>SPECIAL·엔딩 조건</strong>입니다.</div>
                </div>
                <div class="tip-grid">
                    <div class="tip-card">
                        <div class="tip-card__icon"><i class="fas fa-battery-half"></i></div>
                        <div class="tip-card__title">피로와 D 선택의 관계</div>
                        <div class="tip-card__desc">피로가 쌓이면 통상 선택에서도 하락 확률이 늘고, SPECIAL 실패에 더 취약해집니다. <strong>D(멘탈)</strong>는 스탯뿐 아니라 피로를 크게 깎아 주므로, 연속 SPECIAL만 노리다 망가지는 패턴을 피하세요.</div>
                    </div>
                    <div class="tip-card">
                        <div class="tip-card__icon"><i class="fas fa-flag-checkered"></i></div>
                        <div class="tip-card__title">56일차 이전에 총합 올리기</div>
                        <div class="tip-card__desc">중간평가 티어는 팀 총 스탯(240·200·160·120 구간)으로 갈립니다. <strong>S/A</strong>를 받으면 이후 7턴이 체감상 “숨 고르기”, <strong>C/D</strong>면 역으로 버티기가 됩니다.</div>
                    </div>
                    <div class="tip-card">
                        <div class="tip-card__icon"><i class="fas fa-people-arrows"></i></div>
                        <div class="tip-card__title">시너지 4슬롯 맞추기</div>
                        <div class="tip-card__desc">발동은 많아도 실제 반영은 <strong>상위 4개</strong>뿐이고, 개수에 따른 <strong>+1~+10</strong> 등급 보너스가 큽니다. 남녀 2:2·고스탯 라인·밸런스형 등 코드에 있는 조건을 겹치면 케미 등급(S~D)도 올리기 쉽습니다.</div>
                    </div>
                    <div class="tip-card">
                        <div class="tip-card__icon"><i class="fas fa-bullseye"></i></div>
                        <div class="tip-card__title">엔딩 루트 목표 정하기</div>
                        <div class="tip-card__desc">예: 데뷔 <strong>S 또는 A</strong>이면서 케미 <strong>S/A</strong>, SPECIAL 성공(스탯 증가) <strong>6회 이상</strong>이면 월드 투어 루트 후보. <strong>A/B</strong>에 스타 평균 15 이상·SPECIAL 4회 이상이면 바이럴 히트 쪽을 노릴 수 있습니다.</div>
                    </div>
                </div>
            </section>

            <section class="guide-section guide-card footer-callout">
                <div>
                    <div class="footer-callout__title">결과는 하나가 아닙니다</div>
                    <div class="footer-callout__desc">같은 멤버라도 어떤 선택을 누적했는지, 어떤 시너지를 만들었는지에 따라 완전히 다른 결과가 나옵니다. 다른 조합과 다른 운영으로 더 높은 등급을 노려보세요.</div>
                </div>
                <div class="hero-actions" style="margin-top:0;">
                    <a class="hero-btn hero-btn--primary" href="${ctx}/game"><i class="fas fa-rocket"></i> 바로 플레이</a>
                </div>
            </section>
        </div>
    </main>

    <script>
        (function updateDebutGradeGuide(){
            var sections = document.querySelectorAll('.guide-section.guide-card');
            var target = Array.prototype.find.call(sections, function(section){
                var kicker = section.querySelector('.section-kicker');
                return kicker && kicker.textContent && kicker.textContent.trim() === 'DEBUT GRADE';
            });
            if (!target) return;

            var title = target.querySelector('.section-title');
            if (title) title.textContent = '데뷔 등급 기준';

            var sub = target.querySelector('.section-sub');
            if (sub) {
                sub.innerHTML = '최종 데뷔 평가는 결과 화면에 표시되는 <strong>TOTAL SCORE(만점 1000)</strong>를 기준으로 판정됩니다. 아래 점수 구간에 따라 S부터 D까지 등급이 부여됩니다.';
            }

            var cards = target.querySelectorAll('.grade-card');
            var grades = [
                { title: '월드클래스 데뷔', desc: 'TOTAL SCORE 800점 이상. 완성도와 화제성이 모두 높은 최상위 데뷔 결과입니다.' },
                { title: '성공적인 데뷔', desc: 'TOTAL SCORE 700점 이상. 팀 밸런스와 퍼포먼스가 안정적으로 갖춰진 상위권 결과입니다.' },
                { title: '기대되는 데뷔', desc: 'TOTAL SCORE 600점 이상. 기본 경쟁력은 충분하며, 추가 성장 여지가 남아 있는 준수한 결과입니다.' },
                { title: '평범한 데뷔', desc: 'TOTAL SCORE 500점 이상. 데뷔는 가능하지만 완성도와 운영 면에서 보완이 필요한 결과입니다.' },
                { title: '아쉬운 데뷔', desc: 'TOTAL SCORE 500점 미만. 특히 400점대부터는 D 등급으로 분류되며, 팀 운영과 성장 방향을 다시 점검해 재도전이 필요한 단계입니다.' }
            ];

            cards.forEach(function(card, index){
                var titleEl = card.querySelector('.grade-title');
                var descEl = card.querySelector('p');
                var grade = grades[index];
                if (!grade) return;
                if (titleEl) titleEl.textContent = grade.title;
                if (descEl) descEl.textContent = grade.desc;
            });
        })();
    </script>

    <%@ include file="/WEB-INF/views/fragments/footer.jspf" %>
</body>
</html>
