<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"  prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>관리자 대시보드 · NEXT DEBUT</title>
  <%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js" defer></script>
  <style>
    :root{
      --ad-bg:#fff8fc;
      --ad-card:#ffffff;
      --ad-border:rgba(244,114,182,.20);
      --ad-text:#332b30;
      --ad-muted:#8b7180;
      --ad-pink:#f472b6;
      --ad-pink-soft:#fbcfe8;
      --ad-shadow:0 14px 34px rgba(236,72,153,.10);
      --ad-r:18px;
    }
    *{box-sizing:border-box}
    body{
      margin:0; color:var(--ad-text);
      background:
        radial-gradient(1200px 500px at 0% -20%, rgba(251,207,232,.5), transparent 56%),
        radial-gradient(900px 480px at 100% -10%, rgba(253,242,248,.9), transparent 58%),
        var(--ad-bg);
    }
    .ad-wrap{
      max-width:1360px;
      margin:0 auto;
      padding:calc(var(--nav-h,68px) + 22px) 20px 42px;
      display:grid;
      gap:14px;
    }
    .card{
      background:var(--ad-card);
      border:1px solid var(--ad-border);
      border-radius:var(--ad-r);
      box-shadow:var(--ad-shadow);
    }
    .hero{
      padding:18px;
      display:flex;
      justify-content:space-between;
      gap:14px;
      align-items:flex-end;
      flex-wrap:wrap;
    }
    .hero h1{
      margin:0;
      font-family:"Orbitron",sans-serif;
      font-size:clamp(22px,4vw,34px);
      letter-spacing:.08em;
      background:linear-gradient(100deg,#2f2a2c,#e656a0,#f8a5cb);
      -webkit-background-clip:text;
      background-clip:text;
      -webkit-text-fill-color:transparent;
    }
    .hero p{margin:8px 0 0; color:var(--ad-muted); font-size:13px}
    .hero .status{
      margin-top:10px;
      display:inline-flex; align-items:center; gap:8px;
      border-radius:999px; border:1px solid rgba(244,114,182,.28);
      background:rgba(253,242,248,.78); color:#a51866; padding:6px 10px; font-size:12px;
    }
    .quick{
      display:flex; flex-wrap:wrap; gap:8px;
    }
    .quick a{
      text-decoration:none;
      border:1px solid rgba(244,114,182,.24);
      border-radius:999px;
      padding:8px 12px;
      color:#9d1b5f; font-weight:700; font-size:12px;
      background:#fff;
    }
    .quick a:hover{background:rgba(253,242,248,.85)}
    .alert{
      padding:11px 14px; border-radius:14px; font-size:13px;
      border:1px solid rgba(134,239,172,.32);
      background:rgba(220,252,231,.65); color:#166534;
    }
    .kpis{
      display:grid;
      grid-template-columns:repeat(6,minmax(0,1fr));
      gap:10px;
    }
    @media(max-width:1180px){.kpis{grid-template-columns:repeat(3,minmax(0,1fr));}}
    @media(max-width:760px){.kpis{grid-template-columns:repeat(2,minmax(0,1fr));}}
    .kpi{
      padding:14px;
      border-radius:16px;
      background:#fff;
      border:1px solid rgba(244,114,182,.16);
      transition:transform .18s ease, box-shadow .18s ease;
    }
    .kpi:hover{transform:translateY(-2px); box-shadow:0 12px 26px rgba(236,72,153,.13);}
    .kpi .k{font-size:11px; color:#9a7185; letter-spacing:.12em; font-family:"Orbitron",sans-serif;}
    .kpi .v{margin-top:6px; font-size:28px; font-weight:900; line-height:1;}
    .kpi .s{margin-top:6px; font-size:11px; color:#8f6f7f;}

    .grid-4{
      display:grid;
      grid-template-columns:repeat(4,minmax(0,1fr));
      gap:10px;
      align-items:stretch;
    }
    .grid-4 > .card{
      min-width:0;
      display:flex;
      flex-direction:column;
    }
    .grid-4 > .card .section-body{
      flex:1;
      min-height:0;
      display:flex;
      flex-direction:column;
    }
    .grid-4 .list-scroll{
      flex:1;
      min-height:0;
      max-height:280px;
      overflow-y:auto;
      overflow-x:hidden;
      padding-right:6px;
    }
    .grid-4 .list-scroll .row{min-width:0;}
    .grid-4 .list-scroll .t{overflow:hidden;text-overflow:ellipsis;}
    @media(max-width:1200px){.grid-4{grid-template-columns:repeat(2,minmax(0,1fr));}}
    @media(max-width:760px){.grid-4{grid-template-columns:1fr;}}
    .section-head{
      padding:13px 15px 9px;
      border-bottom:1px solid rgba(244,114,182,.12);
      font-size:11px; letter-spacing:.18em; color:#a33674;
      font-family:"Orbitron",sans-serif;
    }
    .section-body{padding:12px 14px 14px}
    .list{display:grid; gap:8px;}
    .row{
      border:1px solid rgba(244,114,182,.14); border-radius:12px;
      padding:10px; background:#fff;
      display:flex; justify-content:space-between; align-items:center; gap:10px;
    }
    .row .t{font-size:13px; font-weight:800;}
    .row .m{margin-top:4px; font-size:11px; color:#8e6f7f;}
    .chip{font-size:10px; padding:5px 8px; border-radius:999px; border:1px solid rgba(244,114,182,.24); background:rgba(253,242,248,.8); color:#9d1b5f; white-space:nowrap;}
    .empty{
      border:1px dashed rgba(244,114,182,.28); border-radius:12px;
      background:rgba(253,242,248,.5); padding:20px 12px; text-align:center; color:#9b7b8b; font-size:13px;
    }

    .layout-main{
      display:grid;
      grid-template-columns:1fr;
      gap:12px;
    }
    .tools{display:flex; gap:8px; flex-wrap:wrap;}
    .btn{
      border:1px solid rgba(244,114,182,.24);
      border-radius:10px; background:#fff; color:#8f1b58;
      padding:7px 10px; font-size:12px; font-weight:700; cursor:pointer;
      text-decoration:none;
    }
    .btn:hover{background:rgba(253,242,248,.85)}
    .btn.danger{border-color:rgba(251,113,133,.35); color:#be123c; background:rgba(255,241,242,.8);}

    .members-search{
      display:flex; flex-wrap:wrap; gap:8px; margin-bottom:10px; align-items:center;
    }
    .input{
      border:1px solid rgba(244,114,182,.24);
      border-radius:10px;
      padding:9px 10px;
      background:#fff;
      color:#332b30;
      font-size:13px;
    }
    .members-pager{
      display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:10px;
      margin-top:12px; padding-top:12px; border-top:1px solid rgba(244,114,182,.12);
    }
    .members-pager .info{font-size:12px; color:#8b6a79;}
    .members-pager .nav{display:flex; flex-wrap:wrap; gap:8px; align-items:center;}
    .members-pager .nav .btn.page-on{
      background:linear-gradient(135deg,#fbcfe8,#f472b6);
      border-color:rgba(244,114,182,.5);
      color:#831843;
    }
    .members-table-wrap{overflow:auto; border:1px solid rgba(244,114,182,.12); border-radius:14px;}
    .members-table{width:100%; border-collapse:separate; border-spacing:0; min-width:840px;}
    .members-table th{
      background:rgba(253,242,248,.7); color:#8f5870;
      font-size:11px; letter-spacing:.08em; text-align:left; padding:11px 10px; border-bottom:1px solid rgba(244,114,182,.14);
    }
    .members-table td{padding:11px 10px; border-bottom:1px solid rgba(244,114,182,.10); font-size:13px;}
    .members-table tbody tr:hover{background:rgba(253,242,248,.35);}
    .avatar{
      width:28px; height:28px; border-radius:50%; display:inline-flex; align-items:center; justify-content:center;
      background:linear-gradient(130deg,#f9a8d4,#f472b6); color:#fff; font-size:11px; font-weight:900; margin-right:7px;
    }

    .trainee-grid{
      display:grid;
      grid-template-columns:repeat(auto-fill,minmax(220px,1fr));
      gap:10px;
    }
    .trainee-compact-row{
      appearance:none;
      color:inherit;
      font-family:inherit;
      border:1px solid rgba(244,114,182,.14); border-radius:14px; background:#fff; padding:12px 14px;
      cursor:pointer; transition:transform .12s ease, box-shadow .12s ease;
      text-align:left; width:100%;
    }
    .trainee-compact-thumb{
      width:100%;
      height:110px;
      border-radius:10px;
      overflow:hidden;
      background:rgba(244,114,182,.08);
      margin-bottom:8px;
      display:flex;
      align-items:center;
      justify-content:center;
      color:#b48ca3;
      font-size:26px;
    }
    .trainee-compact-thumb img{
      width:100%;
      height:100%;
      object-fit:contain;
      object-position:center;
      display:block;
    }
    .trainee-compact-row:hover{
      transform:translateY(-1px);
      box-shadow:0 8px 20px rgba(196,181,253,.22);
    }
    .trainee-compact-row:focus-visible{ outline:2px solid #a855f7; outline-offset:2px; }
    .trainee-compact-name{font-size:14px; font-weight:900; color:#1F2937;}
    .trainee-compact-meta{margin-top:4px; font-size:12px; color:#8b6a79;}
    .trainee-card-tags{display:flex;gap:6px;flex-wrap:wrap;margin-top:7px;}
    .trainee-card-tags .chip{font-size:10px;padding:4px 7px;}
    .trainee-toolbar{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:10px;}
    .trainee-toolbar .input{min-width:160px;}
    .trainee-add-form{display:none;margin-bottom:10px;border:1px solid rgba(244,114,182,.14);border-radius:12px;padding:10px;background:rgba(253,242,248,.5);}
    .trainee-add-form.on{display:block;}
    .trainee-pager{
      display:flex;
      align-items:center;
      justify-content:center;
      gap:6px;
      margin-top:12px;
      flex-wrap:wrap;
    }
    .trainee-pager .btn{
      padding:6px 10px;
      font-size:11px;
    }
    .trainee-pager .btn.page-on{
      background:linear-gradient(135deg,#fbcfe8,#f472b6);
      border-color:rgba(244,114,182,.5);
      color:#831843;
      cursor:default;
    }
    .trainee-detail-hero{display:flex; justify-content:space-between; align-items:flex-start; gap:10px; margin-bottom:10px;}
    .trainee{
      border:1px solid rgba(244,114,182,.14); border-radius:14px; background:#fff; padding:11px;
    }
    .trainee-top{display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;}
    .trainee-name{font-size:14px; font-weight:900;}
    .badge{font-size:10px; border-radius:999px; padding:4px 7px; border:1px solid rgba(244,114,182,.24); color:#9d1b5f; background:rgba(253,242,248,.8);}
    .score{font-family:"Orbitron",sans-serif; font-weight:900; color:#e11d8d;}
    .stat{margin-top:7px;}
    .stat-head{display:flex; justify-content:space-between; font-size:11px; color:#8b6a79; margin-bottom:3px;}
    .bar{height:7px; border-radius:999px; background:#fce7f3; overflow:hidden;}
    .bar > span{display:block; height:100%; border-radius:999px; background:linear-gradient(90deg,#f472b6,#f9a8d4);}

    .ops-grid{
      display:grid;
      grid-template-columns:1fr;
      gap:10px;
    }
    @media(max-width:980px){.ops-grid{grid-template-columns:1fr;}}
    .ops-card{
      border:1px solid rgba(244,114,182,.14); border-radius:14px; background:#fff; padding:12px;
    }
    .ops-title{font-size:11px; letter-spacing:.12em; color:#8d5f74; font-family:"Orbitron",sans-serif; margin-bottom:9px;}
    .admin-report-filterbar{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px;}
    .report-filter-btn{
      display:inline-flex;align-items:center;justify-content:center;
      padding:7px 14px;border-radius:999px;
      border:1px solid rgba(244,114,182,.30);
      background:#fff;color:#9d174d;
      font-size:12px;font-weight:700;cursor:pointer;
    }
    .report-filter-btn.is-active{
      background:linear-gradient(135deg,#f472b6,#e879f9);
      color:#fff;border-color:transparent;
    }
    .badge-status{
      display:inline-flex;align-items:center;justify-content:center;
      padding:3px 9px;border-radius:999px;font-size:11px;font-weight:800;
      border:1px solid rgba(203,213,225,.8);background:#fff;color:#475569;
      margin-right:4px;
    }
    .badge-status.open{background:rgba(251,207,232,.45);border-color:rgba(244,114,182,.35);color:#9d174d;}
    .badge-status.done{background:rgba(226,232,240,.7);border-color:rgba(148,163,184,.35);color:#475569;}
    .badge-status.blind{background:rgba(15,23,42,.88);border-color:rgba(15,23,42,.9);color:#fff;}
    .ops-metric{display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:8px;}
    .ops-metric--charge{grid-template-columns:repeat(3,minmax(0,1fr));}
    @media(max-width:760px){.ops-metric--charge{grid-template-columns:1fr;}}
    .metric{padding:10px; border-radius:12px; border:1px solid rgba(244,114,182,.12); background:rgba(253,242,248,.45);}
    .metric .k{font-size:10px; color:#8f6f7f;}
    .metric .v{font-size:20px; font-weight:900;}
    .metric .s{margin-top:6px;font-size:11px;color:#9ca3af;line-height:1.35;}

    .ad-modal-overlay{position:fixed; inset:0; background:rgba(30,12,24,.40); z-index:1010; display:none; align-items:center; justify-content:center; padding:16px;}
    .ad-modal{
      width:min(640px, 96vw);
      background:#fff;
      border:1px solid rgba(244,114,182,.22);
      border-radius:18px;
      box-shadow:0 22px 48px rgba(30,12,24,.22);
      overflow:hidden;
    }
    .ad-modal__bar{height:3px;background:linear-gradient(90deg,#f472b6,#fbcfe8);}
    .ad-modal__body{padding:16px;}

    /* semantic rule: pink=accent, lavender=system */
    :root{
      --ad-system:#C4B5FD;
      --ad-system-soft:#F5F3FF;
      --ad-system-line:rgba(196,181,253,.55);
      --ad-accent:#FF8FAB;
    }
    body{
      background:
        radial-gradient(1200px 500px at 0% -20%, rgba(205,185,255,.30), transparent 56%),
        radial-gradient(900px 480px at 100% -10%, rgba(232,221,255,.72), transparent 58%),
        #F5F3FF;
    }
    .card,
    .kpi,
    .ops-card,
    .trainee,
    .trainee-compact-row,
    .metric,
    .ad-modal{
      border-color:var(--ad-system-line) !important;
    }
    .section-head{
      border-bottom:1px solid var(--ad-system-line);
      color:#7f62a3;
    }
    .hero .status,
    .badge{
      border-color:var(--ad-system-line);
      background:rgba(232,221,255,.52);
    }
    .quick a{
      border-color:var(--ad-system-line);
      color:#8a4ea2;
    }
    .quick a:hover{
      background:rgba(232,221,255,.52);
    }
    .score{
      color:var(--ad-accent);
    }
    .bar{
      background:#f1e9ff;
    }
    .bar > span{
      background:linear-gradient(90deg,#e9b0d9,#f4c7e9);
    }
    .ad-modal__bar{
      background:linear-gradient(90deg,#e9b0d9,#cdb9ff);
    }
    .hero h1,.kpi .v,.trainee-name,.score{color:#1F2937;}
    .hero p,.kpi .k,.kpi .s,.stat-head{color:#6B7280;}

    .game-section{margin-top:4px}
    .charts-grid{
      display:grid;
      grid-template-columns:repeat(3,minmax(0,1fr));
      gap:12px;
    }
    @media(max-width:1100px){.charts-grid{grid-template-columns:1fr;}}
    .chart-panel{
      border:1px solid var(--ad-system-line);
      border-radius:14px;
      background:#fff;
      padding:12px 14px 16px;
      min-height:280px;
      display:flex;
      flex-direction:column;
    }
    .chart-panel--wide{grid-column:span 2;}
    @media(max-width:1100px){.chart-panel--wide{grid-column:auto;}}
    .chart-title{
      font-size:11px; letter-spacing:.12em; color:#7f62a3;
      font-family:"Orbitron",sans-serif; margin-bottom:10px;
    }
    .chart-tab-row{
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap:8px;
      margin-bottom:10px;
      flex-wrap:wrap;
    }
    .chart-tabs{
      display:flex;
      gap:6px;
      flex-wrap:wrap;
    }
    .chart-tab{
      border:1px solid var(--ad-system-line);
      background:#fff;
      color:#7f62a3;
      border-radius:999px;
      padding:5px 10px;
      font-size:11px;
      font-weight:800;
      cursor:pointer;
    }
    .chart-tab.is-on{
      background:linear-gradient(135deg,#fbcfe8,#e9b0d9);
      border-color:#d8b4fe;
      color:#6b21a8;
    }
    .chart-canvas-wrap{position:relative; flex:1; min-height:220px;}
    .chart-canvas-wrap canvas{max-height:260px;}
    .shop-admin-panels{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px;}
    @media(max-width:1180px){.shop-admin-panels{grid-template-columns:1fr 1fr;}}
    @media(max-width:900px){.shop-admin-panels{grid-template-columns:1fr;}}

    .chart-placeholder{
      flex:1; min-height:200px;
      border:1px dashed rgba(196,181,253,.55);
      border-radius:12px;
      background:rgba(245,243,255,.65);
      display:flex; align-items:center; justify-content:center;
      text-align:center; padding:16px;
      font-size:12px; color:#8b7aad; line-height:1.6;
    }
    .coin-kpi-grid{
      margin-top:12px;
      display:grid;
      grid-template-columns:repeat(4,minmax(0,1fr));
      gap:10px;
    }
    @media(max-width:1100px){.coin-kpi-grid{grid-template-columns:repeat(2,minmax(0,1fr));}}
    @media(max-width:640px){.coin-kpi-grid{grid-template-columns:1fr;}}
    .coin-kpi .k{font-size:11px;color:#8f6f7f;letter-spacing:.06em;}
    .coin-kpi .v{font-size:24px;font-weight:900;margin-top:6px;}
    .coin-kpi .s{font-size:11px;color:#9ca3af;margin-top:6px;line-height:1.35;}
    .coin-grid{
      margin-top:12px;
      display:grid;
      grid-template-columns:2fr 1fr;
      gap:12px;
    }
    @media(max-width:1100px){.coin-grid{grid-template-columns:1fr;}}
    .coin-log-wrap{
      margin-top:12px;
      border:1px solid var(--ad-system-line);
      border-radius:14px;
      overflow:auto;
      background:#fff;
    }
    .coin-log-table{width:100%;border-collapse:separate;border-spacing:0;min-width:760px;}
    .coin-log-table th{
      background:rgba(245,243,255,.8);
      color:#7f62a3;
      font-size:11px;
      letter-spacing:.06em;
      text-align:left;
      padding:10px;
      border-bottom:1px solid var(--ad-system-line);
      white-space:nowrap;
    }
    .coin-log-table td{
      padding:10px;
      font-size:12px;
      border-bottom:1px solid rgba(196,181,253,.35);
      vertical-align:top;
    }
    .coin-log-table tbody tr:hover{background:rgba(245,243,255,.55);}
    .coin-head-tools{
      display:flex;
      align-items:center;
      justify-content:flex-end;
      gap:8px;
      flex-wrap:wrap;
    }
    .coin-head-row{
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap:12px;
      margin-bottom:12px;
      padding-bottom:10px;
      border-bottom:1px solid var(--ad-system-line);
      flex-wrap:wrap;
    }
    .coin-head-row .chart-title{
      margin-bottom:0;
    }
  </style>
</head>
<body>
<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>

<c:set var="todayJoin" value="${(not empty joinByDayVals and fn:length(joinByDayVals) > 0) ? joinByDayVals[fn:length(joinByDayVals)-1] : 0}" />

<main class="ad-wrap">
  <section class="hero card">
    <div>
      <h1>ADMIN OPERATIONS DASHBOARD</h1>
      <p>게임/회원/게시판 운영 현황과 관리 기능을 한 화면에서 확인합니다.</p>
      <div class="status">
        <i class="fas fa-heartbeat"></i>
        오늘 운영 상태: 회원 ${totalMembers}명 · 플레이 ${totalGames}회 · 완료율 ${finishRatePct}% · 상점 코인 합계 ${shopTotalCoins}
      </div>
    </div>
    <div class="quick"></div>
  </section>

  <c:if test="${not empty success}">
    <div class="alert"><i class="fas fa-check-circle"></i> ${success}</div>
  </c:if>

  <section class="kpis">
    <article class="kpi card"><div class="k">총 회원 수</div><div class="v">${totalMembers}</div><div class="s">누적 가입</div></article>
    <article class="kpi card"><div class="k">총 게시글 수</div><div class="v">${totalPosts}</div><div class="s">공지/자유/리포트</div></article>
    <article class="kpi card"><div class="k">총 연습생 수</div><div class="v">${totalTrainees}</div><div class="s">관리 대상 카드</div></article>
    <article class="kpi card"><div class="k">총 게임 플레이</div><div class="v">${totalGames}</div><div class="s">전체 게임 런</div></article>
    <article class="kpi card"><div class="k">오늘 가입 수</div><div class="v">${todayJoin}</div><div class="s">최근 7일 기준</div></article>
    <article class="kpi card"><div class="k">완료 게임 수</div><div class="v">${finishedGames}</div><div class="s">완료율 ${finishRatePct}%</div></article>
  </section>

  <section class="card game-section" id="game-charts">
    <div class="section-head">게임 운영 · 그래프</div>
    <div class="section-body">
      <p style="margin:0 0 12px;font-size:13px;color:#6B7280;">
        최근 플레이 추이와 페이즈(단계) 분포, 추가 운영 지표를 한 화면에서 확인합니다.
      </p>
      <div class="charts-grid">
        <div class="chart-panel chart-panel--wide">
          <div class="chart-tab-row">
            <div class="chart-title" style="margin-bottom:0;">최근 게임 플레이</div>
            <div class="chart-tabs" data-chart-tabs="game-play">
              <button type="button" class="chart-tab is-on" data-period="daily">일간</button>
              <button type="button" class="chart-tab" data-period="weekly">주간</button>
              <button type="button" class="chart-tab" data-period="monthly">월간</button>
            </div>
          </div>
          <div class="chart-canvas-wrap">
            <canvas id="chartGameDaily" aria-label="일별 게임 플레이 차트"></canvas>
          </div>
        </div>
        <div class="chart-panel">
          <div class="chart-tab-row">
            <div class="chart-title" style="margin-bottom:0;">페이즈 분포 (상위 10)</div>
            <div class="chart-tabs" data-chart-tabs="phase">
              <button type="button" class="chart-tab is-on" data-period="daily">일간</button>
              <button type="button" class="chart-tab" data-period="weekly">주간</button>
              <button type="button" class="chart-tab" data-period="monthly">월간</button>
            </div>
          </div>
          <div class="chart-canvas-wrap">
            <canvas id="chartGamePhase" aria-label="페이즈 분포 차트"></canvas>
          </div>
        </div>
        <div class="chart-panel" style="grid-column:1 / -1;">
          <div class="chart-tab-row">
            <div class="chart-title" style="margin-bottom:0;">플레이 추이</div>
            <div class="chart-tabs" data-chart-tabs="extra">
              <button type="button" class="chart-tab is-on" data-period="daily">일간</button>
              <button type="button" class="chart-tab" data-period="weekly">주간</button>
              <button type="button" class="chart-tab" data-period="monthly">월간</button>
            </div>
          </div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;min-height:220px;">
            <div class="chart-canvas-wrap">
              <div class="chart-title" style="margin-bottom:6px;">시간대별 플레이</div>
              <canvas id="chartHourlyPlay" aria-label="시간대별 플레이 차트"></canvas>
            </div>
            <div class="chart-canvas-wrap">
              <div class="chart-title" style="margin-bottom:6px;">이탈 구간</div>
              <canvas id="chartDropOff" aria-label="이탈 구간 차트"></canvas>
            </div>
          </div>
        </div>
      </div>

      <div class="chart-panel" style="margin-top:12px;" id="coin-ops">
        <div class="coin-head-row">
          <div class="chart-title">코인 운영</div>
          <div class="coin-head-tools">
            <a class="btn" href="${ctx}/admin/analytics/usage"><i class="fas fa-coins"></i> 코인 사용 통계</a>
          </div>
        </div>
        <div class="coin-kpi-grid">
          <div class="metric coin-kpi">
            <div class="k">오늘 충전 코인</div>
            <div class="v"><fmt:formatNumber value="${coinKpi.todayChargeCoins}" pattern="#,##0"/></div>
            <div class="s">MarketTxn 기준</div>
          </div>
          <div class="metric coin-kpi">
            <div class="k">오늘 사용 코인</div>
            <div class="v"><fmt:formatNumber value="${coinKpi.todayUsedCoins}" pattern="#,##0"/></div>
            <div class="s">충전/구매 합산</div>
          </div>
          <div class="metric coin-kpi">
            <div class="k">현재 총 유통 코인</div>
            <div class="v"><fmt:formatNumber value="${coinKpi.totalCirculatingCoins}" pattern="#,##0"/></div>
            <div class="s">회원 보유 코인 총합</div>
          </div>
          <div class="metric coin-kpi">
            <div class="k">순증가량</div>
            <div class="v"><fmt:formatNumber value="${coinKpi.todayNetIncrease}" pattern="#,##0"/></div>
            <div class="s">충전 - 사용</div>
          </div>
        </div>

        <div class="coin-grid">
          <div class="chart-panel">
            <div class="chart-tab-row">
              <div class="chart-title" style="margin-bottom:0;">코인 흐름</div>
              <div class="chart-tabs" data-chart-tabs="coin-flow">
                <button type="button" class="chart-tab is-on" data-period="daily">일간</button>
                <button type="button" class="chart-tab" data-period="weekly">주간</button>
                <button type="button" class="chart-tab" data-period="monthly">월간</button>
              </div>
            </div>
            <div class="chart-canvas-wrap">
              <canvas id="chartCoinFlow" aria-label="코인 흐름 차트"></canvas>
            </div>
          </div>
          <div class="chart-panel">
            <div class="chart-tab-row">
              <div class="chart-title" style="margin-bottom:0;">회원 코인 분포</div>
              <div class="chart-tabs" data-chart-tabs="coin-distribution">
                <button type="button" class="chart-tab is-on" data-period="daily">일간</button>
                <button type="button" class="chart-tab" data-period="weekly">주간</button>
                <button type="button" class="chart-tab" data-period="monthly">월간</button>
              </div>
            </div>
            <div class="chart-canvas-wrap">
              <canvas id="chartCoinDistribution" aria-label="회원 코인 분포 차트"></canvas>
            </div>
          </div>
        </div>

        <div class="chart-title" style="margin-top:12px;">최근 코인 거래 (최근 1개월)</div>
        <div class="coin-log-wrap">
          <table class="coin-log-table">
            <thead>
            <tr>
              <th>시각</th>
              <th>회원</th>
              <th>유형</th>
              <th>코인 변화량</th>
              <th>비고</th>
            </tr>
            </thead>
            <tbody>
            <c:choose>
              <c:when test="${empty coinRecentLogs}">
                <tr><td colspan="5"><div class="empty">최근 코인 거래 데이터가 없습니다.</div></td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="tx" items="${coinRecentLogs}">
                  <tr>
                    <td><c:out value="${tx.createdAtStr}"/></td>
                    <td>#${tx.memberId} <c:out value="${empty tx.memberNickname ? '(닉없음)' : tx.memberNickname}"/></td>
                    <td><span class="chip"><c:out value="${tx.txnType}"/></span></td>
                    <td>
                      <c:choose>
                        <c:when test="${tx.coinDelta >= 0}">
                          +<fmt:formatNumber value="${tx.coinDelta}" pattern="#,##0"/>
                        </c:when>
                        <c:otherwise>
                          <fmt:formatNumber value="${tx.coinDelta}" pattern="#,##0"/>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td><c:out value="${empty tx.note ? '-' : tx.note}"/></td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
            </tbody>
          </table>
        </div>
        <c:if test="${coinLogTotal > 0}">
          <div class="members-pager">
            <div class="info">
              <c:choose>
                <c:when test="${coinLogTotalPages > 1}">
                  ${coinLogRowFrom}–${coinLogRowTo}번째 표시 · 전체 ${coinLogTotal}건 · 페이지 ${coinLogPage} / ${coinLogTotalPages}
                </c:when>
                <c:otherwise>
                  전체 ${coinLogTotal}건
                </c:otherwise>
              </c:choose>
            </div>
            <c:if test="${coinLogTotalPages > 1}">
              <div class="nav">
                <c:if test="${coinLogPage > 1}">
                  <c:url var="coinPageFirst" value="/admin">
                    <c:param name="q" value="${coinQueryForPager}"/>
                    <c:param name="page" value="${coinMemberPageForPager}"/>
                    <c:param name="coinPage" value="1"/>
                  </c:url>
                  <a class="btn" href="${coinPageFirst}#coin-ops" title="첫 페이지">« 처음</a>
                  <c:url var="coinPagePrev" value="/admin">
                    <c:param name="q" value="${coinQueryForPager}"/>
                    <c:param name="page" value="${coinMemberPageForPager}"/>
                    <c:param name="coinPage" value="${coinLogPage - 1}"/>
                  </c:url>
                  <a class="btn" href="${coinPagePrev}#coin-ops"><i class="fas fa-chevron-left"></i> 이전</a>
                </c:if>
                <c:set var="coinPageStart" value="${coinLogPage - 4}"/>
                <c:set var="coinPageEnd" value="${coinLogPage + 5}"/>
                <c:if test="${coinPageStart < 1}">
                  <c:set var="coinPageStart" value="1"/>
                  <c:set var="coinPageEnd" value="${coinLogTotalPages < 10 ? coinLogTotalPages : 10}"/>
                </c:if>
                <c:if test="${coinPageEnd > coinLogTotalPages}">
                  <c:set var="coinPageEnd" value="${coinLogTotalPages}"/>
                  <c:set var="coinPageStart" value="${coinPageEnd - 9}"/>
                  <c:if test="${coinPageStart < 1}">
                    <c:set var="coinPageStart" value="1"/>
                  </c:if>
                </c:if>
                <c:forEach begin="${coinPageStart}" end="${coinPageEnd}" var="cp">
                  <c:choose>
                    <c:when test="${cp == coinLogPage}">
                      <span class="btn page-on" aria-current="page">${cp}</span>
                    </c:when>
                    <c:otherwise>
                      <c:url var="coinPageUrl" value="/admin">
                        <c:param name="q" value="${coinQueryForPager}"/>
                        <c:param name="page" value="${coinMemberPageForPager}"/>
                        <c:param name="coinPage" value="${cp}"/>
                      </c:url>
                      <a class="btn" href="${coinPageUrl}#coin-ops">${cp}</a>
                    </c:otherwise>
                  </c:choose>
                </c:forEach>
                <c:if test="${coinLogPage < coinLogTotalPages}">
                  <c:url var="coinPageNext" value="/admin">
                    <c:param name="q" value="${coinQueryForPager}"/>
                    <c:param name="page" value="${coinMemberPageForPager}"/>
                    <c:param name="coinPage" value="${coinLogPage + 1}"/>
                  </c:url>
                  <a class="btn" href="${coinPageNext}#coin-ops">다음 <i class="fas fa-chevron-right"></i></a>
                  <c:url var="coinPageLast" value="/admin">
                    <c:param name="q" value="${coinQueryForPager}"/>
                    <c:param name="page" value="${coinMemberPageForPager}"/>
                    <c:param name="coinPage" value="${coinLogTotalPages}"/>
                  </c:url>
                  <a class="btn" href="${coinPageLast}#coin-ops" title="마지막 페이지">마지막 »</a>
                </c:if>
              </div>
            </c:if>
          </div>
        </c:if>
      </div>
    </div>
  </section>

  <div id="chatroomDetailModal" class="ad-modal-overlay" style="display:none;" aria-hidden="true" onclick="if(event.target===this)document.getElementById('chatroomDetailModal').style.display='none'">
    <div class="ad-modal" style="max-width:520px;" onclick="event.stopPropagation()">
      <div class="ad-modal__bar"></div>
      <div class="ad-modal__body" id="chatroomDetailBody" style="max-height:70vh;overflow:auto;"></div>
      <div style="padding:12px 16px;border-top:1px solid rgba(244,114,182,.12);display:flex;justify-content:flex-end;">
        <button type="button" class="btn" onclick="document.getElementById('chatroomDetailModal').style.display='none'">닫기</button>
      </div>
    </div>
  </div>

  <div id="chatKeywordModal" class="ad-modal-overlay" style="display:none;" aria-hidden="true" onclick="if(event.target===this)closeChatKeywordModal()">
    <div class="ad-modal" style="max-width:520px;" onclick="event.stopPropagation()">
      <div class="ad-modal__bar"></div>
      <div class="ad-modal__body" id="chatKeywordModalBody" style="max-height:70vh;overflow:auto;"></div>
      <div style="padding:12px 16px;border-top:1px solid rgba(244,114,182,.12);display:flex;justify-content:flex-end;gap:8px;">
        <button type="button" class="btn" onclick="closeChatKeywordModal()">닫기</button>
      </div>
    </div>
  </div>

  <section class="layout-main">
    <article class="card" id="members">
      <div class="section-head">회원 관리</div>
      <div class="section-body">
        <div class="chart-panel" style="margin-bottom:10px;">
          <div class="chart-title">연령별 회원 분포</div>
          <div class="chart-canvas-wrap" style="min-height:190px;">
            <canvas id="chartMemberAge" aria-label="연령별 회원 분포 차트"></canvas>
          </div>
        </div>
        <form method="get" action="${ctx}/admin" class="members-search">
          <input type="hidden" name="page" value="1"/>
          <input class="input" type="text" name="q" value="${q}" placeholder="아이디 / 이름 / 닉네임 / 이메일 검색" style="flex:1;min-width:220px;">
          <button class="btn" type="submit">검색</button>
          <a class="btn" href="${ctx}/admin">초기화</a>
          <span class="chip">${filteredMembersTotal} / ${allMembersTotal}</span>
        </form>
        <div class="members-table-wrap">
          <table class="members-table">
            <thead>
            <tr>
              <th>#</th><th>회원</th><th>ID</th><th>이메일</th><th>가입일</th><th>코인</th><th>연습생</th><th>포토카드</th><th>상태</th><th>관리</th>
            </tr>
            </thead>
            <tbody>
            <c:choose>
              <c:when test="${empty allMembers}">
                <tr><td colspan="10"><div class="empty">검색 결과가 없습니다.</div></td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="m" items="${allMembers}" varStatus="vs">
                  <tr>
                    <td>${(memberPage - 1) * memberPageSize + vs.count}</td>
                    <td><span class="avatar">${fn:substring(empty m.nickname ? m.mname : m.nickname, 0, 1)}</span><c:out value="${empty m.nickname ? m.mname : m.nickname}"/></td>
                    <td><c:out value="${m.mid}"/></td>
                    <td><c:out value="${m.email}"/></td>
                    <td><c:out value="${m.createdAtStr}"/></td>
                    <td><fmt:formatNumber value="${memberOpsSummaryByMno[m.mno].coin}" pattern="#,##0"/></td>
                    <td><fmt:formatNumber value="${memberOpsSummaryByMno[m.mno].traineeCount}" pattern="#,##0"/>명</td>
                    <td><fmt:formatNumber value="${memberOpsSummaryByMno[m.mno].photoCardCount}" pattern="#,##0"/>장</td>
                    <td><span class="chip">${m.suspendedNow ? m.suspendRemainingDays : "활성"}${m.suspendedNow ? "일 정지" : ""}</span></td>
                    <td>
                      <div class="tools">
                        <button type="button" class="btn" onclick="openMemberDetail(${m.mno})">상세</button>
                        <button type="button" class="btn danger js-open-suspend" data-target="suspendForm-${m.mno}">정지</button>
                        <form method="post" action="${ctx}/admin/members/${m.mno}/delete" style="margin:0;" onsubmit="return confirm('강제 탈퇴 처리할까요?');">
                          <button type="submit" class="btn danger">강제 탈퇴</button>
                        </form>
                      </div>
                      <form id="suspendForm-${m.mno}" method="post" action="${ctx}/admin/members/${m.mno}/suspend" style="display:none;margin-top:8px;gap:6px;align-items:center;flex-wrap:wrap;">
                        <input class="input" type="number" name="days" min="1" max="365" value="7" style="width:90px;">
                        <input class="input" type="text" name="reason" maxlength="255" placeholder="정지 사유(선택)" style="min-width:160px;flex:1;">
                        <button type="submit" class="btn" style="font-size:12px;padding:7px 10px;">적용</button>
                      </form>
                    </td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
            </tbody>
          </table>
        </div>
        <c:if test="${filteredMembersTotal > 0}">
          <div class="members-pager">
            <div class="info">
              <c:choose>
                <c:when test="${memberPageTotalPages > 1}">
                  ${memberPageRowFrom}–${memberPageRowTo}번째 표시 · 전체 ${filteredMembersTotal}명 · 페이지 ${memberPage} / ${memberPageTotalPages}
                </c:when>
                <c:otherwise>
                  전체 ${filteredMembersTotal}명
                </c:otherwise>
              </c:choose>
            </div>
            <c:if test="${memberPageTotalPages > 1}">
              <div class="nav">
                <c:if test="${memberPage > 1}">
                  <c:url var="memberPageFirst" value="/admin"><c:param name="q" value="${q}"/><c:param name="page" value="1"/></c:url>
                  <a class="btn" href="${memberPageFirst}#members" title="첫 페이지">« 처음</a>
                  <c:url var="memberPagePrev" value="/admin">
                    <c:param name="q" value="${q}"/>
                    <c:param name="page" value="${memberPage - 1}"/>
                  </c:url>
                  <a class="btn" href="${memberPagePrev}#members"><i class="fas fa-chevron-left"></i> 이전</a>
                </c:if>
                <c:forEach var="pi" items="${memberPageNumbers}">
                  <c:url var="memberPageUrl" value="/admin"><c:param name="q" value="${q}"/><c:param name="page" value="${pi}"/></c:url>
                  <c:choose>
                    <c:when test="${pi == memberPage}">
                      <span class="btn page-on" aria-current="page">${pi}</span>
                    </c:when>
                    <c:otherwise>
                      <a class="btn" href="${memberPageUrl}#members">${pi}</a>
                    </c:otherwise>
                  </c:choose>
                </c:forEach>
                <c:if test="${memberPage < memberPageTotalPages}">
                  <c:url var="memberPageNext" value="/admin">
                    <c:param name="q" value="${q}"/>
                    <c:param name="page" value="${memberPage + 1}"/>
                  </c:url>
                  <a class="btn" href="${memberPageNext}#members">다음 <i class="fas fa-chevron-right"></i></a>
                  <c:url var="memberPageLast" value="/admin"><c:param name="q" value="${q}"/><c:param name="page" value="${memberPageTotalPages}"/></c:url>
                  <a class="btn" href="${memberPageLast}#members" title="마지막 페이지">마지막 »</a>
                </c:if>
              </div>
            </c:if>
          </div>
        </c:if>
      </div>
    </article>

    <article class="card" id="game-admin">
      <div class="section-head">게임 관리</div>
      <div class="section-body">
        <div class="ops-card" style="margin-bottom:12px;">
          <div class="ops-title">게임 데이터 요약</div>
          <div class="ops-metric">
            <div class="metric"><div class="k">총 지문 수</div><div class="v">${totalGameScenes}</div></div>
            <div class="metric"><div class="k">지문 phase 수</div><div class="v">${distinctScenePhases}</div></div>
            <div class="metric"><div class="k">총 선택지 수</div><div class="v">${totalGameChoices}</div></div>
            <div class="metric"><div class="k">선택지 phase 수</div><div class="v">${distinctChoicePhases}</div></div>
            <div class="metric"><div class="k">이벤트 문제 수</div><div class="v">${totalGameMiniQuizzes}</div></div>
            <div class="metric"><div class="k">활성 이벤트 수</div><div class="v">${activeGameMiniQuizzes}</div></div>
          </div>
        </div>
        <div class="ops-card" style="margin-bottom:12px;">
          <div class="ops-title">채팅 선택 ML 통계</div>
          <div class="ops-metric">
            <div class="metric"><div class="k">총 샘플</div><div class="v"><fmt:formatNumber value="${mlChoiceStats.total}" pattern="#,##0"/></div></div>
            <div class="metric"><div class="k">ML 건수</div><div class="v"><fmt:formatNumber value="${mlChoiceStats.ml}" pattern="#,##0"/></div></div>
            <div class="metric"><div class="k">RULE 건수</div><div class="v"><fmt:formatNumber value="${mlChoiceStats.rule}" pattern="#,##0"/></div></div>
            <div class="metric"><div class="k">ML 적용률</div><div class="v"><fmt:formatNumber value="${mlChoiceStats.mlRate}" pattern="#,##0.0"/>%</div></div>
            <div class="metric"><div class="k">Fallback 비율</div><div class="v"><fmt:formatNumber value="${mlChoiceStats.fallbackRate}" pattern="#,##0.0"/>%</div></div>
            <div class="metric"><div class="k">평균 신뢰도</div><div class="v"><fmt:formatNumber value="${mlChoiceStats.avgConfidence}" pattern="#,##0.000"/></div></div>
          </div>
          <div class="hint" style="margin-top:8px;">
            로그 기준: <code>app.ml.training-log-path</code>
            <a class="btn" style="margin-left:8px;" href="${ctx}/admin/game-stats">상세 보기</a>
          </div>
        </div>
        <div class="ops-card">
          <div class="ops-title">관리 동선</div>
          <div style="display:grid;gap:10px;">
            <div class="row">
              <div>
                <div class="t">상황 지문 관리</div>
                <div class="m">게임 이벤트 지문 추가, 미리보기, 수정, 삭제를 전용 화면에서 처리합니다.</div>
              </div>
              <a class="btn" href="${ctx}/admin/game-scenes">상황 지문 관리 열기</a>
            </div>
            <div class="row">
              <div>
                <div class="t">채팅 매핑 규칙 관리</div>
                <div class="m">phase별 선택지 문구, 스탯 대상, 정렬 순서를 전용 화면에서 관리합니다.</div>
              </div>
              <a class="btn" href="${ctx}/admin/game-choices">채팅 매핑 규칙 관리 열기</a>
            </div>
            <div class="row">
              <div>
                <div class="t">이벤트 관리</div>
                <div class="m">인게임 이벤트(아이돌 이름 맞추기) 힌트/정답 문제 풀을 전용 화면에서 관리합니다.</div>
              </div>
              <a class="btn" href="${ctx}/admin/game-events">이벤트 관리 열기</a>
            </div>
          </div>
        </div>
      </div>
    </article>

    <article class="card" id="trainees">
      <div class="section-head">연습생 관리</div>
      <div class="section-body">
        <div class="trainee-toolbar">
          <input type="search" id="traineeLocalSearch" class="input" placeholder="이름 검색">
          <select id="traineeGenderFilter" class="input">
            <option value="ALL">성별 전체</option>
            <option value="MALE">남성</option>
            <option value="FEMALE">여성</option>
          </select>
          <select id="traineeGradeFilter" class="input">
            <option value="ALL">등급 전체</option>
            <option value="N">N</option>
            <option value="R">R</option>
            <option value="SR">SR</option>
            <option value="SSR">SSR</option>
          </select>
          <select id="traineeSortFilter" class="input">
            <option value="default">기본순</option>
            <option value="name">이름순</option>
            <option value="avg">평균 능력치순</option>
          </select>
          <button type="button" class="btn" id="toggleTraineeAddForm">연습생 추가</button>
          <a class="btn" href="${ctx}/admin/trainees">운영 관리 화면</a>
        </div>
        <form method="post" action="${ctx}/admin/trainee" enctype="multipart/form-data" id="traineeAddFormInDashboard" class="trainee-add-form">
          <div style="font-size:11px;color:#8f6f7f;margin-bottom:8px;">
            능력치 입력 범위: <strong>1~100</strong>
          </div>
          <div style="display:grid;grid-template-columns:1.4fr 1fr 1fr 1fr 1fr 1fr 1fr;gap:8px;">
            <input class="input" type="text" name="name" placeholder="이름" required>
            <select class="input" name="gender" required>
              <option value="MALE">남성</option>
              <option value="FEMALE">여성</option>
            </select>
            <input class="input" type="number" min="0" max="20" name="vocal" placeholder="보컬 (1~100)" required>
            <input class="input" type="number" min="0" max="20" name="dance" placeholder="댄스 (1~100)" required>
            <input class="input" type="number" min="0" max="20" name="star" placeholder="스타성 (1~100)" required>
            <input class="input" type="number" min="0" max="20" name="mental" placeholder="멘탈 (1~100)" required>
            <input class="input" type="number" min="0" max="20" name="teamwork" placeholder="팀워크 (1~100)" required>
          </div>
          <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-top:8px;">
            <input class="input" type="file" name="image" accept="image/*">
            <button type="submit" class="btn">추가 저장</button>
          </div>
        </form>
        <c:choose>
          <c:when test="${empty allTrainees}">
            <div class="empty">등록된 연습생이 없습니다.</div>
          </c:when>
          <c:otherwise>
            <div class="trainee-grid">
              <c:forEach var="t" items="${allTrainees}">
                <c:set var="sum" value="${t.vocal + t.dance + t.star + t.mental + t.teamwork}" />
                <button type="button" class="trainee-compact-row js-trainee-open"
                        data-id="${t.id}"
                        data-name="<c:out value='${t.name}' />"
                        data-avg="${sum div 5.0}"
                        data-grade="${empty t.grade ? '' : t.grade.name()}"
                        data-gender="${t.gender}"
                        data-image="${empty t.imagePath ? '' : t.imagePath}"
                        data-vocal="${t.vocal}" data-dance="${t.dance}" data-star="${t.star}"
                        data-mental="${t.mental}" data-teamwork="${t.teamwork}">
                  <div class="trainee-compact-thumb">
                    <c:choose>
                      <c:when test="${not empty t.imagePath}">
                        <img src="${ctx}${t.imagePath}" alt="${t.name}">
                      </c:when>
                      <c:otherwise><i class="fas fa-user"></i></c:otherwise>
                    </c:choose>
                  </div>
                  <div class="trainee-compact-name"><c:out value="${t.name}"/></div>
                  <div class="trainee-compact-meta">${t.gender eq 'MALE' ? '남성' : '여성'} · 평균 <fmt:formatNumber value="${sum div 5.0}" maxFractionDigits="1" /></div>
                  <div class="trainee-card-tags">
                    <span class="chip">R/SR/SSR 관리</span>
                  </div>
                </button>
              </c:forEach>
            </div>
            <div class="trainee-pager" id="traineePager"></div>
          </c:otherwise>
        </c:choose>
      </div>
    </article>
  </section>

  <section class="ops-grid">
    <article class="card" id="board-ops">
      <div class="section-head">게시판 운영 관리</div>
      <div class="section-body">
        <div class="ops-card">
          <div class="ops-title">운영 요약</div>
          <div class="ops-metric">
            <div class="metric"><div class="k">총 게시글 수</div><div class="v">${totalBoardCount}</div></div>
            <div class="metric"><div class="k">공지 게시글 수</div><div class="v">${noticeCount}</div></div>
            <div class="metric"><div class="k">일반 게시글 수</div><div class="v">${normalBoardCount}</div></div>
            <div class="metric"><div class="k">신고 접수 건수</div><div class="v">${reportCount}</div></div>
            <div class="metric"><div class="k">블라인드/숨김 게시글 수</div><div class="v">${blindedCount}</div></div>
          </div>
        </div>
        <div class="ops-card" style="margin-top:10px;">
          <div class="ops-title">신고/게시글 처리 필요 항목</div>
          <div class="admin-report-filterbar">
            <button type="button" class="report-filter-btn is-active js-admin-report-filter" data-status="all">전체</button>
            <button type="button" class="report-filter-btn js-admin-report-filter" data-status="processing">처리중</button>
            <button type="button" class="report-filter-btn js-admin-report-filter" data-status="completed">처리완료</button>
          </div>
          <c:choose>
            <c:when test="${empty recentReports}">
              <div class="empty">현재 처리할 신고 내역이 없습니다.</div>
            </c:when>
            <c:otherwise>
              <div class="members-table-wrap">
                <table class="members-table">
                  <thead>
                    <tr>
                      <th>신고일시</th>
                      <th>게시글 제목</th>
                      <th>작성자</th>
                      <th>신고 사유</th>
                      <th>누적 신고 수</th>
                      <th>상태</th>
                      <th style="text-align:right;">처리</th>
                    </tr>
                  </thead>
                  <tbody>
                    <c:forEach var="r" items="${recentReports}">
                      <tr data-workflow-status="${r.workflowStatus}">
                        <td style="white-space:nowrap;"><c:out value="${r.reportedAt}"/></td>
                        <td style="min-width:180px;">
                          <a href="${ctx}${r.detailPath}" style="color:inherit;text-decoration:none;font-weight:700;">
                            <c:out value="${r.boardTitle}"/>
                          </a>
                        </td>
                        <td><c:out value="${r.authorNick}"/></td>
                        <td><c:out value="${r.reason}"/></td>
                        <td><fmt:formatNumber value="${r.reportCount}" pattern="#,##0"/></td>
                        <td>
                          <c:choose>
                            <c:when test="${r.workflowStatus eq 'completed'}">처리완료</c:when>
                            <c:when test="${r.workflowStatus eq 'processing'}">처리중</c:when>
                            <c:otherwise>대기</c:otherwise>
                          </c:choose>
                        </td>
                        <td>
                          <div class="tools">
                            <form method="post" action="${ctx}/admin/reports/${r.id}/handle" style="margin:0;">
                              <input type="hidden" name="action" value="detail"/>
                              <button type="submit" class="btn" style="font-size:12px;padding:7px 10px;">상세</button>
                            </form>
                            <form method="post" action="${ctx}/admin/reports/${r.id}/handle" style="margin:0;">
                              <input type="hidden" name="action" value="toggleBlind"/>
                              <button type="submit" class="btn ${r.visible ? 'danger' : ''}" style="font-size:12px;padding:7px 10px;">${r.visible ? "블라인드" : "해제"}</button>
                            </form>
                            <button type="button" class="btn js-report-process-toggle" data-target="reportProcessRow-${r.id}" style="font-size:12px;padding:7px 10px;">처리</button>
                          </div>
                        </td>
                      </tr>
                      <tr id="reportProcessRow-${r.id}" data-workflow-status="${r.workflowStatus}" style="display:none;background:rgba(253,242,248,.35);">
                        <td colspan="7">
                          <form method="post" action="${ctx}/admin/reports/${r.id}/comment" style="display:flex;gap:8px;align-items:flex-start;flex-wrap:wrap;margin:0;">
                            <textarea class="input" name="content" rows="2" maxlength="500" required placeholder="처리 내용을 입력하면 관리자 이름으로 댓글이 등록됩니다." style="flex:1;min-width:320px;resize:vertical;"></textarea>
                            <button type="submit" class="btn">처리 등록</button>
                          </form>
                        </td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
        <div class="ops-card" style="margin-top:10px;">
          <div class="ops-title">게시판 운영 분석</div>
          <div class="charts-grid" style="grid-template-columns:1fr 1fr;gap:10px;">
            <div class="chart-panel">
              <div class="chart-title" style="margin-bottom:8px;">최근 7일 게시글 등록 추이</div>
              <div class="chart-canvas-wrap"><canvas id="chartBoardTrend" aria-label="게시글 등록 추이 차트"></canvas></div>
            </div>
            <div class="chart-panel">
              <div class="chart-title" style="margin-bottom:8px;">최근 7일 신고 건수 추이</div>
              <div class="chart-canvas-wrap"><canvas id="chartReportTrend" aria-label="신고 건수 추이 차트"></canvas></div>
            </div>
          </div>
        </div>
        <div class="ops-card" style="margin-top:10px;">
          <div class="ops-title">공지 운영</div>
          <button type="button" class="btn" id="noticeFormToggleBtn">공지 작성 열기</button>
          <form method="post" action="${ctx}/admin/notices" id="noticeCreateForm" style="display:none;margin-top:10px;">
            <input class="input" name="title" placeholder="제목" required maxlength="200" style="width:100%;margin-bottom:8px;">
            <textarea class="input" name="content" rows="4" placeholder="내용" required style="width:100%;resize:vertical;margin-bottom:8px;"></textarea>
            <label style="display:flex;align-items:center;gap:8px;font-size:12px;margin-bottom:8px;">
              <input type="checkbox" name="popup" value="true">
              <span>상단 고정</span>
            </label>
            <button type="submit" class="btn">등록</button>
          </form>
          <div style="margin-top:10px;">
            <c:choose>
              <c:when test="${empty noticeList}">
                <div class="empty">등록된 공지가 없습니다. 상단 버튼으로 공지를 등록해 주세요.</div>
              </c:when>
              <c:otherwise>
                <div class="members-table-wrap">
                  <table class="members-table">
                    <thead>
                      <tr>
                        <th>제목</th>
                        <th>작성일</th>
                        <th>작성자</th>
                        <th>상태</th>
                        <th>상단 고정</th>
                        <th style="text-align:right;">관리</th>
                      </tr>
                    </thead>
                    <tbody>
                      <c:forEach var="n" items="${noticeList}">
                        <tr>
                          <td style="min-width:200px;">
                            <a href="${ctx}/boards/notice/${n.id}" style="color:inherit;text-decoration:none;font-weight:700;">
                              <c:out value="${n.title}"/>
                            </a>
                          </td>
                          <td style="white-space:nowrap;"><c:out value="${n.createdAtStr}"/></td>
                          <td><c:out value="${empty n.authorNick ? '관리자' : n.authorNick}"/></td>
                          <td>${n.visible ? "게시중" : "숨김"}</td>
                          <td>${n.popup ? "고정" : "일반"}</td>
                          <td>
                            <div class="tools">
                              <a class="btn" href="${ctx}/boards/notice/${n.id}" style="font-size:12px;padding:7px 10px;">수정</a>
                              <form method="post" action="${ctx}/admin/notices/${n.id}/delete" style="margin:0;" onsubmit="return confirm('해당 공지를 삭제할까요?');">
                                <button type="submit" class="btn danger" style="font-size:12px;padding:7px 10px;">삭제</button>
                              </form>
                              <form method="post" action="${ctx}/admin/notices/${n.id}/pin" style="margin:0;">
                                <button type="submit" class="btn" style="font-size:12px;padding:7px 10px;">${n.popup ? "고정해제" : "고정"}</button>
                              </form>
                            </div>
                          </td>
                        </tr>
                      </c:forEach>
                    </tbody>
                  </table>
                </div>
                <c:if test="${noticeTotalPages > 1}">
                  <div class="members-pager" style="margin-top:10px;">
                    <div class="info">${noticeRowFrom}–${noticeRowTo}번째 표시 · 전체 ${noticeTotalCount}건 · 페이지 ${noticePage} / ${noticeTotalPages}</div>
                    <div class="nav">
                      <c:if test="${noticePage > 1}">
                        <c:url var="noticePageFirst" value="/admin">
                          <c:param name="q" value="${q}"/>
                          <c:param name="page" value="${memberPage}"/>
                          <c:param name="coinPage" value="${coinLogPage}"/>
                          <c:param name="noticePage" value="1"/>
                        </c:url>
                        <c:url var="noticePagePrev" value="/admin">
                          <c:param name="q" value="${q}"/>
                          <c:param name="page" value="${memberPage}"/>
                          <c:param name="coinPage" value="${coinLogPage}"/>
                          <c:param name="noticePage" value="${noticePage - 1}"/>
                        </c:url>
                        <a class="btn" href="${noticePageFirst}">« 처음</a>
                        <a class="btn" href="${noticePagePrev}"><i class="fas fa-chevron-left"></i> 이전</a>
                      </c:if>
                      <c:forEach var="pi" items="${noticePageNumbers}">
                        <c:url var="noticePageUrl" value="/admin">
                          <c:param name="q" value="${q}"/>
                          <c:param name="page" value="${memberPage}"/>
                          <c:param name="coinPage" value="${coinLogPage}"/>
                          <c:param name="noticePage" value="${pi}"/>
                        </c:url>
                        <c:choose>
                          <c:when test="${pi == noticePage}">
                            <span class="btn page-on" aria-current="page">${pi}</span>
                          </c:when>
                          <c:otherwise>
                            <a class="btn" href="${noticePageUrl}">${pi}</a>
                          </c:otherwise>
                        </c:choose>
                      </c:forEach>
                      <c:if test="${noticePage < noticeTotalPages}">
                        <c:url var="noticePageNext" value="/admin">
                          <c:param name="q" value="${q}"/>
                          <c:param name="page" value="${memberPage}"/>
                          <c:param name="coinPage" value="${coinLogPage}"/>
                          <c:param name="noticePage" value="${noticePage + 1}"/>
                        </c:url>
                        <c:url var="noticePageLast" value="/admin">
                          <c:param name="q" value="${q}"/>
                          <c:param name="page" value="${memberPage}"/>
                          <c:param name="coinPage" value="${coinLogPage}"/>
                          <c:param name="noticePage" value="${noticeTotalPages}"/>
                        </c:url>
                        <a class="btn" href="${noticePageNext}">다음 <i class="fas fa-chevron-right"></i></a>
                        <a class="btn" href="${noticePageLast}">마지막 »</a>
                      </c:if>
                    </div>
                  </div>
                </c:if>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
        <div class="ops-card" style="margin-top:10px;">
          <div class="ops-title">팬미팅 운영</div>
          <div style="font-size:12px;color:#7f62a3;margin-bottom:8px;">
            총 팬미팅 게시글 <strong>${fanMeetingPosts}</strong>건 · 최신 글 기준 신청자 수를 빠르게 확인합니다.
          </div>
          <div class="admin-report-filterbar" style="margin-bottom:10px;">
            <c:url var="fmFilterAllUrl" value="/admin">
              <c:param name="q" value="${q}"/>
              <c:param name="page" value="${memberPage}"/>
              <c:param name="coinPage" value="${coinLogPage}"/>
              <c:param name="noticePage" value="${noticePage}"/>
              <c:param name="fanMeetingPage" value="1"/>
              <c:param name="fanMeetingStatus" value="all"/>
            </c:url>
            <c:url var="fmFilterRecUrl" value="/admin">
              <c:param name="q" value="${q}"/>
              <c:param name="page" value="${memberPage}"/>
              <c:param name="coinPage" value="${coinLogPage}"/>
              <c:param name="noticePage" value="${noticePage}"/>
              <c:param name="fanMeetingPage" value="1"/>
              <c:param name="fanMeetingStatus" value="recruiting"/>
            </c:url>
            <c:url var="fmFilterDoneUrl" value="/admin">
              <c:param name="q" value="${q}"/>
              <c:param name="page" value="${memberPage}"/>
              <c:param name="coinPage" value="${coinLogPage}"/>
              <c:param name="noticePage" value="${noticePage}"/>
              <c:param name="fanMeetingPage" value="1"/>
              <c:param name="fanMeetingStatus" value="done"/>
            </c:url>
            <a class="report-filter-btn ${fanMeetingStatus eq 'all' ? 'is-active' : ''}" href="${fmFilterAllUrl}#board-ops">전체</a>
            <a class="report-filter-btn ${fanMeetingStatus eq 'recruiting' ? 'is-active' : ''}" href="${fmFilterRecUrl}#board-ops">모집중</a>
            <a class="report-filter-btn ${fanMeetingStatus eq 'done' ? 'is-active' : ''}" href="${fmFilterDoneUrl}#board-ops">완료</a>
          </div>
          <c:choose>
            <c:when test="${empty recentFanMeetingPosts}">
              <div class="empty">등록된 팬미팅 글이 없습니다.</div>
            </c:when>
            <c:otherwise>
              <div class="members-table-wrap">
                <table class="members-table">
                  <thead>
                    <tr>
                      <th>제목</th>
                      <th>작성자</th>
                      <th>상태</th>
                      <th>신청자</th>
                      <th>작성일</th>
                      <th style="text-align:right;">관리</th>
                    </tr>
                  </thead>
                  <tbody>
                    <c:forEach var="fm" items="${recentFanMeetingPosts}">
                      <tr>
                        <td style="min-width:220px;"><c:out value="${fm.title}"/></td>
                        <td><c:out value="${fm.authorNick}"/></td>
                        <td>
                          <span class="badge-status ${fm.fanMeetingStatusKey == 'DONE' ? 'done' : 'open'}"><c:out value="${fm.recruitStatusLabel}"/></span>
                          <c:if test="${!fm.visible}">
                            <span class="badge-status blind">블라인드</span>
                          </c:if>
                        </td>
                        <td>${fanMeetingApplicantCount[fm.id]}명</td>
                        <td style="white-space:nowrap;"><c:out value="${fm.createdAtStr}"/></td>
                        <td>
                          <div class="tools" style="justify-content:flex-end;">
                            <a class="btn" href="${ctx}/boards/fanmeeting/${fm.id}" style="font-size:12px;padding:7px 10px;">상세</a>
                            <a class="btn" href="${ctx}/boards/fanmeeting/${fm.id}/edit" style="font-size:12px;padding:7px 10px;">수정</a>
                            <form method="post" action="${ctx}/admin/fanmeeting/${fm.id}/visibility" style="margin:0;">
                              <input type="hidden" name="visible" value="${fm.visible ? 'false' : 'true'}"/>
                              <input type="hidden" name="q" value="${q}"/>
                              <input type="hidden" name="page" value="${memberPage}"/>
                              <input type="hidden" name="coinPage" value="${coinLogPage}"/>
                              <input type="hidden" name="noticePage" value="${noticePage}"/>
                              <input type="hidden" name="fanMeetingPage" value="${fanMeetingPage}"/>
                              <input type="hidden" name="fanMeetingStatus" value="${fanMeetingStatus}"/>
                              <button type="submit" class="btn ${fm.visible ? 'danger' : ''}" style="font-size:12px;padding:7px 10px;">${fm.visible ? '블라인드' : '해제'}</button>
                            </form>
                          </div>
                        </td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </div>
              <c:if test="${fanMeetingTotalPages > 1}">
                <div class="members-pager" style="margin-top:10px;">
                  <div class="info">${fanMeetingRowFrom}–${fanMeetingRowTo}번째 표시 · 전체 ${fanMeetingTotalCount}건 · 페이지 ${fanMeetingPage} / ${fanMeetingTotalPages}</div>
                  <div class="nav">
                    <c:if test="${fanMeetingPage > 1}">
                      <c:url var="fmPageFirst" value="/admin">
                        <c:param name="q" value="${q}"/>
                        <c:param name="page" value="${memberPage}"/>
                        <c:param name="coinPage" value="${coinLogPage}"/>
                        <c:param name="noticePage" value="${noticePage}"/>
                        <c:param name="fanMeetingPage" value="1"/>
                        <c:param name="fanMeetingStatus" value="${fanMeetingStatus}"/>
                      </c:url>
                      <c:url var="fmPagePrev" value="/admin">
                        <c:param name="q" value="${q}"/>
                        <c:param name="page" value="${memberPage}"/>
                        <c:param name="coinPage" value="${coinLogPage}"/>
                        <c:param name="noticePage" value="${noticePage}"/>
                        <c:param name="fanMeetingPage" value="${fanMeetingPage - 1}"/>
                        <c:param name="fanMeetingStatus" value="${fanMeetingStatus}"/>
                      </c:url>
                      <a class="btn" href="${fmPageFirst}#board-ops">« 처음</a>
                      <a class="btn" href="${fmPagePrev}#board-ops"><i class="fas fa-chevron-left"></i> 이전</a>
                    </c:if>
                    <c:forEach var="pi" items="${fanMeetingPageNumbers}">
                      <c:url var="fmPageUrl" value="/admin">
                        <c:param name="q" value="${q}"/>
                        <c:param name="page" value="${memberPage}"/>
                        <c:param name="coinPage" value="${coinLogPage}"/>
                        <c:param name="noticePage" value="${noticePage}"/>
                        <c:param name="fanMeetingPage" value="${pi}"/>
                        <c:param name="fanMeetingStatus" value="${fanMeetingStatus}"/>
                      </c:url>
                      <c:choose>
                        <c:when test="${pi == fanMeetingPage}">
                          <span class="btn page-on" aria-current="page">${pi}</span>
                        </c:when>
                        <c:otherwise>
                          <a class="btn" href="${fmPageUrl}#board-ops">${pi}</a>
                        </c:otherwise>
                      </c:choose>
                    </c:forEach>
                    <c:if test="${fanMeetingPage < fanMeetingTotalPages}">
                      <c:url var="fmPageNext" value="/admin">
                        <c:param name="q" value="${q}"/>
                        <c:param name="page" value="${memberPage}"/>
                        <c:param name="coinPage" value="${coinLogPage}"/>
                        <c:param name="noticePage" value="${noticePage}"/>
                        <c:param name="fanMeetingPage" value="${fanMeetingPage + 1}"/>
                        <c:param name="fanMeetingStatus" value="${fanMeetingStatus}"/>
                      </c:url>
                      <c:url var="fmPageLast" value="/admin">
                        <c:param name="q" value="${q}"/>
                        <c:param name="page" value="${memberPage}"/>
                        <c:param name="coinPage" value="${coinLogPage}"/>
                        <c:param name="noticePage" value="${noticePage}"/>
                        <c:param name="fanMeetingPage" value="${fanMeetingTotalPages}"/>
                        <c:param name="fanMeetingStatus" value="${fanMeetingStatus}"/>
                      </c:url>
                      <a class="btn" href="${fmPageNext}#board-ops">다음 <i class="fas fa-chevron-right"></i></a>
                      <a class="btn" href="${fmPageLast}#board-ops">마지막 »</a>
                    </c:if>
                  </div>
                </div>
              </c:if>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </article>
  </section>

  <section class="card" id="chatroom-admin">
    <div class="section-head">실시간 채팅방 관리</div>
    <div class="section-body">
      <p style="margin:0 0 12px;font-size:13px;color:#6B7280;">
        개설된 채팅방·접속자 목록을 확인하고, 부적절 키워드가 포함된 메시지는 자동으로 아래 로그에 쌓입니다. 방 삭제 시 해당 방의 모든 접속이 끊깁니다.
      </p>
      <div class="tools" style="margin-bottom:10px;">
        <button type="button" class="btn" id="chatroomAdminRefresh">새로고침</button>
      </div>
      <div id="chatroomAdminRooms"></div>
      <div style="margin-top:16px;padding-top:12px;border-top:1px solid rgba(244,114,182,.12);display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:10px;">
        <div style="font-size:11px;letter-spacing:.12em;color:#7f62a3;font-family:Orbitron,sans-serif;">의심 메시지 (키워드 감지)</div>
        <button type="button" class="btn" id="chatKeywordSettingsBtn" style="white-space:nowrap;">키워드 감지 설정</button>
      </div>
      <div id="chatroomAdminFlags" style="margin-top:10px;"></div>
    </div>
  </section>
</main>

<div id="traineeDetailModal" class="ad-modal-overlay" style="display:none;">
  <div class="ad-modal" onclick="event.stopPropagation()">
    <div class="ad-modal__bar"></div>
    <div class="ad-modal__body">
      <div class="trainee-detail-hero">
        <div style="min-width:0;">
          <div class="trainee-name" id="td_name" style="display:inline;"></div>
          <span class="badge" id="td_grade_badge" style="margin-left:8px;font-size:11px;font-weight:800;"></span>
        </div>
        <button type="button" class="btn" onclick="closeTraineeDetailModal()" aria-label="닫기">×</button>
      </div>
      <div class="m" id="td_sub" style="margin-top:6px;"></div>
      <div style="display:flex; justify-content:space-between; align-items:center; margin:12px 0 8px;">
        <span class="badge">TOTAL</span>
        <span class="score" id="td_total"></span>
      </div>
      <div id="td_stats"></div>
      <div class="tools" style="margin-top:14px;">
        <button type="button" class="btn" id="td_btn_edit">수정</button>
        <form method="post" id="td_form_delete" style="margin:0;" onsubmit="return confirm('삭제할까요?');">
          <button type="submit" class="btn danger">삭제</button>
        </form>
      </div>
    </div>
  </div>
</div>

<div id="editModal" class="ad-modal-overlay">
  <div class="ad-modal" onclick="event.stopPropagation()">
    <div class="ad-modal__bar"></div>
    <div class="ad-modal__body">
      <h3 style="font-size:16px;margin:0 0 12px;font-weight:900;">연습생 정보 수정</h3>
      <form id="editForm" method="post" action="">
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:10px;">
          <div>
            <label style="display:block;font-size:11px;color:#8e6476;margin-bottom:4px;">이름</label>
            <input type="text" name="name" id="edit_name" class="input" style="width:100%;">
          </div>
          <div>
            <label style="display:block;font-size:11px;color:#8e6476;margin-bottom:4px;">등급</label>
            <select name="grade" id="edit_grade" class="input" style="width:100%;">
              <option value="N">N</option>
              <option value="R">R</option>
              <option value="SR">SR</option>
              <option value="SSR">SSR</option>
            </select>
          </div>
        </div>
        <div style="display:grid;grid-template-columns:repeat(5,1fr);gap:8px;margin-bottom:12px;">
          <div><label style="display:block;font-size:11px;color:#8e6476;margin-bottom:4px;">보컬</label><input type="number" name="vocal" id="edit_vocal" min="0" max="20" class="input" style="width:100%;text-align:center;"></div>
          <div><label style="display:block;font-size:11px;color:#8e6476;margin-bottom:4px;">댄스</label><input type="number" name="dance" id="edit_dance" min="0" max="20" class="input" style="width:100%;text-align:center;"></div>
          <div><label style="display:block;font-size:11px;color:#8e6476;margin-bottom:4px;">스타</label><input type="number" name="star" id="edit_star" min="0" max="20" class="input" style="width:100%;text-align:center;"></div>
          <div><label style="display:block;font-size:11px;color:#8e6476;margin-bottom:4px;">멘탈</label><input type="number" name="mental" id="edit_mental" min="0" max="20" class="input" style="width:100%;text-align:center;"></div>
          <div><label style="display:block;font-size:11px;color:#8e6476;margin-bottom:4px;">팀워크</label><input type="number" name="teamwork" id="edit_teamwork" min="0" max="20" class="input" style="width:100%;text-align:center;"></div>
        </div>
        <div class="tools">
          <button type="submit" class="btn">저장</button>
          <button type="button" class="btn" onclick="closeEditModal()">취소</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
const ctx = '${pageContext.request.contextPath}';
const GAME_DAILY_KEYS = ${gameDailyKeysJson};
const GAME_DAILY_VALS = ${gameDailyValsJson};
const GAME_WEEKLY_KEYS = ${gameWeeklyKeysJson};
const GAME_WEEKLY_VALS = ${gameWeeklyValsJson};
const GAME_MONTHLY_KEYS = ${gameMonthlyKeysJson};
const GAME_MONTHLY_VALS = ${gameMonthlyValsJson};
const GAME_PHASE_DAILY_LABELS = ${gamePhaseDailyLabelsJson};
const GAME_PHASE_DAILY_VALS = ${gamePhaseDailyValuesJson};
const GAME_PHASE_WEEKLY_LABELS = ${gamePhaseWeeklyLabelsJson};
const GAME_PHASE_WEEKLY_VALS = ${gamePhaseWeeklyValuesJson};
const GAME_PHASE_MONTHLY_LABELS = ${gamePhaseMonthlyLabelsJson};
const GAME_PHASE_MONTHLY_VALS = ${gamePhaseMonthlyValuesJson};
const HOURLY_PLAY_DAILY_LABELS = ${hourlyPlayDailyLabelsJson};
const HOURLY_PLAY_DAILY_VALS = ${hourlyPlayDailyValuesJson};
const HOURLY_PLAY_WEEKLY_LABELS = ${hourlyPlayWeeklyLabelsJson};
const HOURLY_PLAY_WEEKLY_VALS = ${hourlyPlayWeeklyValuesJson};
const HOURLY_PLAY_MONTHLY_LABELS = ${hourlyPlayMonthlyLabelsJson};
const HOURLY_PLAY_MONTHLY_VALS = ${hourlyPlayMonthlyValuesJson};
const DROPOFF_DAILY_LABELS = ${dropOffDailyLabelsJson};
const DROPOFF_DAILY_VALS = ${dropOffDailyValuesJson};
const DROPOFF_WEEKLY_LABELS = ${dropOffWeeklyLabelsJson};
const DROPOFF_WEEKLY_VALS = ${dropOffWeeklyValuesJson};
const DROPOFF_MONTHLY_LABELS = ${dropOffMonthlyLabelsJson};
const DROPOFF_MONTHLY_VALS = ${dropOffMonthlyValuesJson};
const COIN_FLOW_DAILY_LABELS = ${coinFlowDailyLabelsJson};
const COIN_FLOW_DAILY_CHARGE = ${coinFlowDailyChargeJson};
const COIN_FLOW_DAILY_USED = ${coinFlowDailyUsedJson};
const COIN_FLOW_DAILY_NET = ${coinFlowDailyNetJson};
const COIN_FLOW_WEEKLY_LABELS = ${coinFlowWeeklyLabelsJson};
const COIN_FLOW_WEEKLY_CHARGE = ${coinFlowWeeklyChargeJson};
const COIN_FLOW_WEEKLY_USED = ${coinFlowWeeklyUsedJson};
const COIN_FLOW_WEEKLY_NET = ${coinFlowWeeklyNetJson};
const COIN_FLOW_MONTHLY_LABELS = ${coinFlowMonthlyLabelsJson};
const COIN_FLOW_MONTHLY_CHARGE = ${coinFlowMonthlyChargeJson};
const COIN_FLOW_MONTHLY_USED = ${coinFlowMonthlyUsedJson};
const COIN_FLOW_MONTHLY_NET = ${coinFlowMonthlyNetJson};
const COIN_DISTRIBUTION_LABELS = ${coinDistributionLabelsJson};
const COIN_DISTRIBUTION_VALUES = ${coinDistributionValuesJson};
const BOARD_TREND_KEYS = ${boardTrendKeysJson};
const BOARD_TREND_VALS = ${boardTrendValsJson};
const REPORT_TREND_KEYS = ${reportTrendKeysJson};
const REPORT_TREND_VALS = ${reportTrendValsJson};
const MEMBER_AGE_BUCKET_LABELS = ${memberAgeBucketLabelsJson};
const MEMBER_AGE_BUCKET_VALUES = ${memberAgeBucketValuesJson};

function formatDateLabelKo(s) {
  if (s == null || typeof s !== 'string') return s;
  var m = s.match(/^(\d{4})-(\d{1,2})-(\d{1,2})/);
  if (m) {
    return parseInt(m[1], 10) + '년 ' + parseInt(m[2], 10) + '월 ' + parseInt(m[3], 10) + '일';
  }
  return s;
}

function phaseLabelKo(s) {
  if (s == null || s === '') return '미지정';
  var u = String(s).toUpperCase();
  if (u === 'UNKNOWN' || u === '(NULL)') return '미지정';
  return String(s);
}

document.addEventListener('DOMContentLoaded', function() {
  if (typeof Chart === 'undefined') return;
  if (typeof Chart.defaults !== 'undefined') {
    Chart.defaults.locale = 'ko';
  }
  var dailyEl = document.getElementById('chartGameDaily');
  var phaseEl = document.getElementById('chartGamePhase');
  var hourlyEl = document.getElementById('chartHourlyPlay');
  var dropOffEl = document.getElementById('chartDropOff');
  var coinFlowEl = document.getElementById('chartCoinFlow');
  var coinDistEl = document.getElementById('chartCoinDistribution');
  var memberAgeEl = document.getElementById('chartMemberAge');
  var boardTrendEl = document.getElementById('chartBoardTrend');
  var reportTrendEl = document.getElementById('chartReportTrend');
  var gamePlaySets = {
    daily: {
      labels: Array.isArray(GAME_DAILY_KEYS) ? GAME_DAILY_KEYS.map(formatDateLabelKo) : [],
      values: Array.isArray(GAME_DAILY_VALS) ? GAME_DAILY_VALS : []
    },
    weekly: {
      labels: Array.isArray(GAME_WEEKLY_KEYS) ? GAME_WEEKLY_KEYS : [],
      values: Array.isArray(GAME_WEEKLY_VALS) ? GAME_WEEKLY_VALS : []
    },
    monthly: {
      labels: Array.isArray(GAME_MONTHLY_KEYS) ? GAME_MONTHLY_KEYS : [],
      values: Array.isArray(GAME_MONTHLY_VALS) ? GAME_MONTHLY_VALS : []
    }
  };
  var phaseSets = {
    daily: { labels: Array.isArray(GAME_PHASE_DAILY_LABELS) ? GAME_PHASE_DAILY_LABELS.map(phaseLabelKo) : [], values: Array.isArray(GAME_PHASE_DAILY_VALS) ? GAME_PHASE_DAILY_VALS : [] },
    weekly: { labels: Array.isArray(GAME_PHASE_WEEKLY_LABELS) ? GAME_PHASE_WEEKLY_LABELS.map(phaseLabelKo) : [], values: Array.isArray(GAME_PHASE_WEEKLY_VALS) ? GAME_PHASE_WEEKLY_VALS : [] },
    monthly: { labels: Array.isArray(GAME_PHASE_MONTHLY_LABELS) ? GAME_PHASE_MONTHLY_LABELS.map(phaseLabelKo) : [], values: Array.isArray(GAME_PHASE_MONTHLY_VALS) ? GAME_PHASE_MONTHLY_VALS : [] }
  };

  var gamePlayChart = null;
  var phaseChart = null;

  function renderGamePlay(period) {
    var ds = gamePlaySets[period] || gamePlaySets.daily;
    if (!dailyEl || !Array.isArray(ds.labels) || ds.labels.length === 0) {
      if (dailyEl && dailyEl.parentElement) dailyEl.parentElement.innerHTML = '<div class="chart-placeholder">플레이 데이터가 없습니다.</div>';
      return;
    }
    if (gamePlayChart) {
      gamePlayChart.destroy();
    }
    gamePlayChart = new Chart(dailyEl, {
      type: 'line',
      data: {
        labels: ds.labels,
        datasets: [{
          label: '게임 플레이',
          data: ds.values.map(function(v) { return Number(v); }),
          borderColor: 'rgba(236,72,153,.9)',
          backgroundColor: 'rgba(253,242,248,.55)',
          fill: true,
          tension: 0.28,
          pointRadius: 3
        }]
      },
      options: {
        locale: 'ko',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              title: function(items) {
                var i = items[0].dataIndex;
                return ds.labels[i] || '';
              },
              label: function(ctx) {
                return '플레이 ' + ctx.parsed.y + '회';
              }
            }
          }
        },
        scales: {
          x: {
            title: { display: true, text: period === 'monthly' ? '월' : (period === 'weekly' ? '주간' : '날짜') },
            ticks: { maxRotation: 40, minRotation: 0, autoSkip: true, maxTicksLimit: period === 'daily' ? 14 : 12 }
          },
          y: {
            beginAtZero: true,
            title: { display: true, text: '플레이 횟수' },
            ticks: { precision: 0, callback: function(v) { return v + '회'; } }
          }
        }
      }
    });
  }

  function renderPhase(period) {
    var ds = phaseSets[period] || phaseSets.daily;
    if (!phaseEl || !Array.isArray(ds.labels) || ds.labels.length === 0) {
      if (phaseEl && phaseEl.parentElement) phaseEl.parentElement.innerHTML = '<div class="chart-placeholder">페이즈 분포 데이터가 없습니다.</div>';
      return;
    }
    var colors = ['#ec4899','#d946ef','#a855f7','#8b5cf6','#6366f1','#0ea5e9','#14b8a6','#22c55e','#eab308','#f97316'];
    var phaseTotal = ds.values.reduce(function(a, b) { return a + Number(b); }, 0);
    if (phaseChart) {
      phaseChart.destroy();
    }
    phaseChart = new Chart(phaseEl, {
      type: 'doughnut',
      data: {
        labels: ds.labels,
        datasets: [{
          label: '건수',
          data: ds.values.map(function(v) { return Number(v); }),
          backgroundColor: ds.labels.map(function(_, i) { return colors[i % colors.length]; }),
          borderWidth: 0
        }]
      },
      options: {
        locale: 'ko',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          tooltip: {
            callbacks: {
              label: function(ctx) {
                var val = ctx.parsed;
                var pct = phaseTotal ? Math.round((val / phaseTotal) * 1000) / 10 : 0;
                return (ctx.label || '') + ': ' + val + '건 (' + pct + '%)';
              }
            }
          },
          legend: {
            position: 'bottom',
            labels: { boxWidth: 10, font: { size: 10 }, padding: 10 }
          }
        }
      }
    });
  }

  function bindPeriodTabs(groupName, onChange) {
    var wrap = document.querySelector('[data-chart-tabs="' + groupName + '"]');
    if (!wrap) return;
    wrap.querySelectorAll('.chart-tab').forEach(function(btn) {
      btn.addEventListener('click', function() {
        var period = btn.getAttribute('data-period') || 'daily';
        wrap.querySelectorAll('.chart-tab').forEach(function(b) {
          b.classList.toggle('is-on', b.getAttribute('data-period') === period);
        });
        onChange(period);
      });
    });
  }

  renderGamePlay('daily');
  renderPhase('daily');
  bindPeriodTabs('game-play', renderGamePlay);
  bindPeriodTabs('phase', renderPhase);

  var hourlySets = {
    daily: { labels: Array.isArray(HOURLY_PLAY_DAILY_LABELS) ? HOURLY_PLAY_DAILY_LABELS : [], values: Array.isArray(HOURLY_PLAY_DAILY_VALS) ? HOURLY_PLAY_DAILY_VALS : [] },
    weekly: { labels: Array.isArray(HOURLY_PLAY_WEEKLY_LABELS) ? HOURLY_PLAY_WEEKLY_LABELS : [], values: Array.isArray(HOURLY_PLAY_WEEKLY_VALS) ? HOURLY_PLAY_WEEKLY_VALS : [] },
    monthly: { labels: Array.isArray(HOURLY_PLAY_MONTHLY_LABELS) ? HOURLY_PLAY_MONTHLY_LABELS : [], values: Array.isArray(HOURLY_PLAY_MONTHLY_VALS) ? HOURLY_PLAY_MONTHLY_VALS : [] }
  };
  var dropOffSets = {
    daily: { labels: Array.isArray(DROPOFF_DAILY_LABELS) ? DROPOFF_DAILY_LABELS : [], values: Array.isArray(DROPOFF_DAILY_VALS) ? DROPOFF_DAILY_VALS : [] },
    weekly: { labels: Array.isArray(DROPOFF_WEEKLY_LABELS) ? DROPOFF_WEEKLY_LABELS : [], values: Array.isArray(DROPOFF_WEEKLY_VALS) ? DROPOFF_WEEKLY_VALS : [] },
    monthly: { labels: Array.isArray(DROPOFF_MONTHLY_LABELS) ? DROPOFF_MONTHLY_LABELS : [], values: Array.isArray(DROPOFF_MONTHLY_VALS) ? DROPOFF_MONTHLY_VALS : [] }
  };
  var hourlyChart = null;
  var dropOffChart = null;

  function renderExtraCharts(period) {
    var hs = hourlySets[period] || hourlySets.daily;
    var ds = dropOffSets[period] || dropOffSets.daily;

    if (hourlyEl && Array.isArray(hs.labels) && hs.labels.length > 0) {
      if (hourlyChart) {
        hourlyChart.destroy();
      }
      hourlyChart = new Chart(hourlyEl, {
      type: 'bar',
      data: {
        labels: hs.labels,
        datasets: [{
          label: '시간대별 플레이',
          data: hs.values.map(function(v){ return Number(v); }),
          borderColor: '#a855f7',
          backgroundColor: 'rgba(196,181,253,.45)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, ticks: { precision: 0 } }
        }
      }
    });
    } else if (hourlyEl && hourlyEl.parentElement) {
      hourlyEl.parentElement.innerHTML = '<div class="chart-placeholder">시간대별 데이터가 없습니다.</div>';
    }

    if (dropOffEl && Array.isArray(ds.labels) && ds.labels.length > 0) {
      if (dropOffChart) {
        dropOffChart.destroy();
      }
      dropOffChart = new Chart(dropOffEl, {
      type: 'bar',
      data: {
        labels: ds.labels,
        datasets: [{
          label: '이탈 건수',
          data: ds.values.map(function(v){ return Number(v); }),
          borderColor: '#f472b6',
          backgroundColor: 'rgba(251,207,232,.55)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { maxRotation: 45, minRotation: 0 } },
          y: { beginAtZero: true, ticks: { precision: 0 } }
        }
      }
    });
    } else if (dropOffEl && dropOffEl.parentElement) {
      dropOffEl.parentElement.innerHTML = '<div class="chart-placeholder">이탈 구간 데이터가 없습니다.</div>';
    }
  }

  renderExtraCharts('daily');
  bindPeriodTabs('extra', renderExtraCharts);

  var coinFlowSets = {
    daily: {
      labels: Array.isArray(COIN_FLOW_DAILY_LABELS) ? COIN_FLOW_DAILY_LABELS : [],
      charge: Array.isArray(COIN_FLOW_DAILY_CHARGE) ? COIN_FLOW_DAILY_CHARGE : [],
      used: Array.isArray(COIN_FLOW_DAILY_USED) ? COIN_FLOW_DAILY_USED : [],
      net: Array.isArray(COIN_FLOW_DAILY_NET) ? COIN_FLOW_DAILY_NET : []
    },
    weekly: {
      labels: Array.isArray(COIN_FLOW_WEEKLY_LABELS) ? COIN_FLOW_WEEKLY_LABELS : [],
      charge: Array.isArray(COIN_FLOW_WEEKLY_CHARGE) ? COIN_FLOW_WEEKLY_CHARGE : [],
      used: Array.isArray(COIN_FLOW_WEEKLY_USED) ? COIN_FLOW_WEEKLY_USED : [],
      net: Array.isArray(COIN_FLOW_WEEKLY_NET) ? COIN_FLOW_WEEKLY_NET : []
    },
    monthly: {
      labels: Array.isArray(COIN_FLOW_MONTHLY_LABELS) ? COIN_FLOW_MONTHLY_LABELS : [],
      charge: Array.isArray(COIN_FLOW_MONTHLY_CHARGE) ? COIN_FLOW_MONTHLY_CHARGE : [],
      used: Array.isArray(COIN_FLOW_MONTHLY_USED) ? COIN_FLOW_MONTHLY_USED : [],
      net: Array.isArray(COIN_FLOW_MONTHLY_NET) ? COIN_FLOW_MONTHLY_NET : []
    }
  };
  var coinFlowChart = null;
  var coinDistChart = null;

  function renderCoinFlow(period) {
    var ds = coinFlowSets[period] || coinFlowSets.daily;
    if (!coinFlowEl || !Array.isArray(ds.labels) || ds.labels.length === 0) {
      if (coinFlowEl && coinFlowEl.parentElement) {
        coinFlowEl.parentElement.innerHTML = '<div class="chart-placeholder">코인 흐름 데이터가 없습니다.</div>';
      }
      return;
    }
    if (coinFlowChart) {
      coinFlowChart.destroy();
    }
    coinFlowChart = new Chart(coinFlowEl, {
      type: 'line',
      data: {
        labels: ds.labels,
        datasets: [
          {
            label: '충전 코인',
            data: ds.charge.map(function(v){ return Number(v); }),
            borderColor: '#ec4899',
            backgroundColor: 'rgba(236,72,153,.15)',
            tension: 0.28,
            pointRadius: 2.8,
            fill: false
          },
          {
            label: '사용 코인',
            data: ds.used.map(function(v){ return Number(v); }),
            borderColor: '#8b5cf6',
            backgroundColor: 'rgba(139,92,246,.12)',
            tension: 0.28,
            pointRadius: 2.8,
            fill: false
          },
          {
            label: '순증가량',
            data: ds.net.map(function(v){ return Number(v); }),
            borderColor: '#14b8a6',
            backgroundColor: 'rgba(20,184,166,.12)',
            tension: 0.22,
            pointRadius: 2.8,
            fill: false
          }
        ]
      },
      options: {
        locale: 'ko',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'top', labels: { boxWidth: 10, font: { size: 11 }, padding: 10 } },
          tooltip: {
            callbacks: {
              label: function(ctx) {
                return (ctx.dataset.label || '') + ': ' + ctx.parsed.y + ' 코인';
              }
            }
          }
        },
        scales: {
          x: {
            title: { display: true, text: period === 'monthly' ? '월' : (period === 'weekly' ? '주간' : '날짜') },
            ticks: { maxRotation: 40, minRotation: 0, autoSkip: true, maxTicksLimit: period === 'daily' ? 14 : 12 }
          },
          y: {
            ticks: { precision: 0, callback: function(v){ return v + 'C'; } }
          }
        }
      }
    });
  }

  function renderCoinDistribution(period) {
    if (!coinDistEl || !Array.isArray(COIN_DISTRIBUTION_LABELS) || COIN_DISTRIBUTION_LABELS.length === 0) {
      if (coinDistEl && coinDistEl.parentElement) {
        coinDistEl.parentElement.innerHTML = '<div class="chart-placeholder">회원 코인 분포 데이터가 없습니다.</div>';
      }
      return;
    }
    if (coinDistChart) {
      coinDistChart.destroy();
    }
    coinDistChart = new Chart(coinDistEl, {
      type: 'doughnut',
      data: {
        labels: COIN_DISTRIBUTION_LABELS,
        datasets: [{
          label: '회원 수',
          data: COIN_DISTRIBUTION_VALUES.map(function(v){ return Number(v); }),
          backgroundColor: ['#f9a8d4','#d8b4fe','#a78bfa','#7c3aed'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 10 }, padding: 10 } },
          tooltip: {
            callbacks: {
              label: function(ctx) {
                return (ctx.label || '') + ': ' + ctx.parsed + '명';
              }
            }
          }
        }
      }
    });
  }

  renderCoinFlow('daily');
  bindPeriodTabs('coin-flow', renderCoinFlow);
  renderCoinDistribution('daily');
  bindPeriodTabs('coin-distribution', renderCoinDistribution);

  if (memberAgeEl && Array.isArray(MEMBER_AGE_BUCKET_LABELS) && MEMBER_AGE_BUCKET_LABELS.length > 0) {
    new Chart(memberAgeEl, {
      type: 'bar',
      data: {
        labels: MEMBER_AGE_BUCKET_LABELS,
        datasets: [{
          label: '회원 수',
          data: MEMBER_AGE_BUCKET_VALUES.map(function(v) { return Number(v); }),
          borderColor: '#ec4899',
          backgroundColor: 'rgba(244,114,182,.35)',
          borderWidth: 1.2,
          borderRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: function(ctx) {
                return '회원 ' + ctx.parsed.y + '명';
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              callback: function(v) { return v + '명'; }
            }
          }
        }
      }
    });
  } else if (memberAgeEl && memberAgeEl.parentElement) {
    memberAgeEl.parentElement.innerHTML = '<div class="chart-placeholder">연령 통계 데이터가 없습니다.</div>';
  }

  if (boardTrendEl && Array.isArray(BOARD_TREND_KEYS) && BOARD_TREND_KEYS.length > 0) {
    new Chart(boardTrendEl, {
      type: 'line',
      data: {
        labels: BOARD_TREND_KEYS,
        datasets: [{
          label: '게시글',
          data: BOARD_TREND_VALS.map(function(v) { return Number(v); }),
          borderColor: '#a855f7',
          backgroundColor: 'rgba(216,180,254,.28)',
          fill: true,
          tension: 0.25
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }
      }
    });
  } else if (boardTrendEl && boardTrendEl.parentElement) {
    boardTrendEl.parentElement.innerHTML = '<div class="chart-placeholder">게시글 추이 데이터가 없습니다.</div>';
  }

  if (reportTrendEl && Array.isArray(REPORT_TREND_KEYS) && REPORT_TREND_KEYS.length > 0) {
    new Chart(reportTrendEl, {
      type: 'bar',
      data: {
        labels: REPORT_TREND_KEYS,
        datasets: [{
          label: '신고',
          data: REPORT_TREND_VALS.map(function(v) { return Number(v); }),
          borderColor: '#ec4899',
          backgroundColor: 'rgba(244,114,182,.38)'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }
      }
    });
  } else if (reportTrendEl && reportTrendEl.parentElement) {
    reportTrendEl.parentElement.innerHTML = '<div class="chart-placeholder">신고 추이 데이터가 없습니다.</div>';
  }
});

document.addEventListener('DOMContentLoaded', function () {
  var addToggleBtn = document.getElementById('toggleTraineeAddForm');
  var addForm = document.getElementById('traineeAddFormInDashboard');
  var noticeToggleBtn = document.getElementById('noticeFormToggleBtn');
  var noticeForm = document.getElementById('noticeCreateForm');
  if (noticeToggleBtn && noticeForm) {
    noticeToggleBtn.addEventListener('click', function() {
      var open = noticeForm.style.display !== 'none';
      noticeForm.style.display = open ? 'none' : 'block';
      noticeToggleBtn.textContent = open ? '공지 작성 열기' : '공지 작성 닫기';
    });
  }
  if (addToggleBtn && addForm) {
    addToggleBtn.addEventListener('click', function () {
      addForm.classList.toggle('on');
    });
  }
  var suspendButtons = document.querySelectorAll('.js-open-suspend');
  suspendButtons.forEach(function(btn){
    btn.addEventListener('click', function(){
      var id = btn.getAttribute('data-target');
      if (!id) return;
      var form = document.getElementById(id);
      if (!form) return;
      var open = form.style.display !== 'none';
      form.style.display = open ? 'none' : 'flex';
      btn.textContent = open ? '정지' : '정지 닫기';
    });
  });
  var processToggleButtons = document.querySelectorAll('.js-report-process-toggle');
  processToggleButtons.forEach(function(btn) {
    btn.addEventListener('click', function() {
      var targetId = btn.getAttribute('data-target');
      if (!targetId) return;
      var row = document.getElementById(targetId);
      if (!row) return;
      var open = row.style.display !== 'none';
      row.style.display = open ? 'none' : 'table-row';
      btn.textContent = open ? '처리' : '처리 닫기';
    });
  });
  var adminReportFilters = document.querySelectorAll('.js-admin-report-filter');
  adminReportFilters.forEach(function(filterBtn) {
    filterBtn.addEventListener('click', function() {
      var target = filterBtn.getAttribute('data-status') || 'all';
      adminReportFilters.forEach(function(b) { b.classList.remove('is-active'); });
      filterBtn.classList.add('is-active');
      var rows = document.querySelectorAll('tr[data-workflow-status]');
      rows.forEach(function(row) {
        var rowStatus = row.getAttribute('data-workflow-status') || 'pending';
        var visible = target === 'all'
          || (target === 'completed' && rowStatus === 'completed')
          || (target === 'processing' && (rowStatus === 'processing' || rowStatus === 'pending'));
        row.style.display = visible ? (row.id && row.id.indexOf('reportProcessRow-') === 0 ? 'none' : 'table-row') : 'none';
      });
      var toggleButtons = document.querySelectorAll('.js-report-process-toggle');
      toggleButtons.forEach(function(b) { b.textContent = '처리'; });
    });
  });

  var searchEl = document.getElementById('traineeLocalSearch');
  var genderEl = document.getElementById('traineeGenderFilter');
  var gradeEl = document.getElementById('traineeGradeFilter');
  var sortEl = document.getElementById('traineeSortFilter');
  var grid = document.querySelector('#trainees .trainee-grid');
  var pager = document.getElementById('traineePager');
  var pageSize = 15;
  var currentPage = 1;
  if (!grid) return;

  function getFilteredAndSortedCards() {
    var cards = Array.prototype.slice.call(grid.querySelectorAll('.js-trainee-open'));
    var keyword = searchEl ? String(searchEl.value || '').trim().toLowerCase() : '';
    var gender = genderEl ? genderEl.value : 'ALL';
    var grade = gradeEl ? gradeEl.value : 'ALL';
    var sort = sortEl ? sortEl.value : 'default';

    var visibleCards = cards.filter(function (card) {
      var name = String(card.getAttribute('data-name') || '').toLowerCase();
      var g = String(card.getAttribute('data-gender') || 'ALL');
      var gr = String(card.getAttribute('data-grade') || 'N');
      return (!keyword || name.indexOf(keyword) >= 0)
        && (gender === 'ALL' || g === gender)
        && (grade === 'ALL' || gr === grade);
    });

    visibleCards.sort(function (a, b) {
      if (sort === 'name') {
        return String(a.getAttribute('data-name') || '').localeCompare(String(b.getAttribute('data-name') || ''), 'ko');
      }
      if (sort === 'avg') {
        return Number(b.getAttribute('data-avg') || 0) - Number(a.getAttribute('data-avg') || 0);
      }
      return Number(a.getAttribute('data-id') || 0) - Number(b.getAttribute('data-id') || 0);
    });
    return { cards: cards, visibleCards: visibleCards };
  }

  function renderPager(totalPages) {
    if (!pager) return;
    pager.innerHTML = '';
    if (totalPages <= 1) return;

    function makeButton(label, page, disabled, isCurrent) {
      var el = document.createElement(disabled || isCurrent ? 'span' : 'button');
      el.className = 'btn' + (isCurrent ? ' page-on' : '');
      el.textContent = label;
      if (!disabled && !isCurrent) {
        el.type = 'button';
        el.addEventListener('click', function () {
          currentPage = page;
          applyFiltersAndPagination();
        });
      }
      pager.appendChild(el);
    }

    makeButton('이전', currentPage - 1, currentPage <= 1, false);
    for (var i = 1; i <= totalPages; i++) {
      makeButton(String(i), i, false, i === currentPage);
    }
    makeButton('다음', currentPage + 1, currentPage >= totalPages, false);
  }

  function applyFiltersAndPagination() {
    var result = getFilteredAndSortedCards();
    var cards = result.cards;
    var visibleCards = result.visibleCards;

    cards.forEach(function (card) {
      card.style.display = 'none';
    });

    var totalPages = Math.max(1, Math.ceil(visibleCards.length / pageSize));
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    var start = (currentPage - 1) * pageSize;
    var end = start + pageSize;
    visibleCards.forEach(function (card, idx) {
      if (idx >= start && idx < end) {
        card.style.display = '';
      }
      grid.appendChild(card);
    });
    renderPager(totalPages);
  }

  if (searchEl) searchEl.addEventListener('input', function () { currentPage = 1; applyFiltersAndPagination(); });
  if (genderEl) genderEl.addEventListener('change', function () { currentPage = 1; applyFiltersAndPagination(); });
  if (gradeEl) gradeEl.addEventListener('change', function () { currentPage = 1; applyFiltersAndPagination(); });
  if (sortEl) sortEl.addEventListener('change', function () { currentPage = 1; applyFiltersAndPagination(); });
  applyFiltersAndPagination();
});

function openEditModal(id, name, grade, vocal, dance, star, mental, teamwork) {
  document.getElementById('edit_name').value = name;
  var g = grade || 'N';
  var ge = document.getElementById('edit_grade');
  if (ge && !Array.prototype.some.call(ge.options, function(o){ return o.value === g; })) g = 'N';
  document.getElementById('edit_grade').value = g;
  document.getElementById('edit_vocal').value = vocal;
  document.getElementById('edit_dance').value = dance;
  document.getElementById('edit_star').value = star;
  document.getElementById('edit_mental').value = mental;
  document.getElementById('edit_teamwork').value = teamwork;
  document.getElementById('editForm').action = ctx + '/admin/trainees/' + id + '/edit';
  document.getElementById('editModal').style.display = 'flex';
}
function closeEditModal() { document.getElementById('editModal').style.display = 'none'; }
document.getElementById('editModal').addEventListener('click', function(e) { if (e.target === this) closeEditModal(); });

function renderTraineeStatBars(vocal, dance, star, mental, teamwork) {
  var stats = [
    ['보컬', vocal], ['댄스', dance], ['스타', star], ['멘탈', mental], ['팀워크', teamwork]
  ];
  return stats.map(function(s) {
    var w = Math.min(100, Math.max(0, s[1]));
    return '<div class="stat"><div class="stat-head"><span>' + s[0] + '</span><span>' + s[1] + '</span></div>' +
      '<div class="bar"><span style="width:' + w + '%;"></span></div></div>';
  }).join('');
}

function openTraineeDetailModal(el) {
  var id = parseInt(el.getAttribute('data-id'), 10);
  var name = el.getAttribute('data-name') || '';
  var grade = el.getAttribute('data-grade') || '';
  var gender = el.getAttribute('data-gender') === 'MALE' ? '남성' : '여성';
  var vocal = parseInt(el.getAttribute('data-vocal'), 10) || 0;
  var dance = parseInt(el.getAttribute('data-dance'), 10) || 0;
  var star = parseInt(el.getAttribute('data-star'), 10) || 0;
  var mental = parseInt(el.getAttribute('data-mental'), 10) || 0;
  var teamwork = parseInt(el.getAttribute('data-teamwork'), 10) || 0;
  var sum = vocal + dance + star + mental + teamwork;
  var avg = (sum / 5).toFixed(1);

  document.getElementById('td_name').textContent = name;
  var gb = document.getElementById('td_grade_badge');
  if (gb) {
    gb.textContent = grade ? grade : '';
    gb.style.display = grade ? 'inline' : 'none';
  }
  document.getElementById('td_sub').textContent = gender + ' · 평균 ' + avg;
  document.getElementById('td_total').textContent = sum;
  document.getElementById('td_stats').innerHTML = renderTraineeStatBars(vocal, dance, star, mental, teamwork);

  var modal = document.getElementById('traineeDetailModal');
  document.getElementById('td_form_delete').action = ctx + '/admin/trainees/' + id + '/delete';

  modal.dataset.editId = String(id);
  modal.dataset.editName = name;
  modal.dataset.editGrade = grade;
  modal.dataset.editVocal = String(vocal);
  modal.dataset.editDance = String(dance);
  modal.dataset.editStar = String(star);
  modal.dataset.editMental = String(mental);
  modal.dataset.editTeamwork = String(teamwork);

  modal.style.display = 'flex';
  modal.setAttribute('aria-hidden', 'false');
}

function closeTraineeDetailModal() {
  var modal = document.getElementById('traineeDetailModal');
  if (!modal) return;
  modal.style.display = 'none';
  modal.setAttribute('aria-hidden', 'true');
}

var traineeDetailModalEl = document.getElementById('traineeDetailModal');
if (traineeDetailModalEl) {
  traineeDetailModalEl.addEventListener('click', function(e) {
    if (e.target === this) closeTraineeDetailModal();
  });
}

document.querySelectorAll('.js-trainee-open').forEach(function(btn) {
  btn.addEventListener('click', function() {
    openTraineeDetailModal(this);
  });
});

var tdBtnEdit = document.getElementById('td_btn_edit');
if (tdBtnEdit) {
  tdBtnEdit.addEventListener('click', function() {
    var modal = document.getElementById('traineeDetailModal');
    if (!modal) return;
    var id = parseInt(modal.dataset.editId, 10);
    var name = modal.dataset.editName || '';
    var grade = modal.dataset.editGrade || '';
    var vocal = parseInt(modal.dataset.editVocal, 10);
    var dance = parseInt(modal.dataset.editDance, 10);
    var star = parseInt(modal.dataset.editStar, 10);
    var mental = parseInt(modal.dataset.editMental, 10);
    var teamwork = parseInt(modal.dataset.editTeamwork, 10);
    closeTraineeDetailModal();
    openEditModal(id, name, grade, vocal, dance, star, mental, teamwork);
  });
}

function safeFetch(url, opt){ return fetch(url, Object.assign({ credentials: 'same-origin' }, opt || {})); }

function openChatroomDetail(roomId) {
  if (!roomId) return;
  safeFetch(ctx + '/admin/chatroom/' + encodeURIComponent(roomId) + '/detail')
    .then(function(r){ if (!r.ok) throw new Error(); return r.json(); })
    .then(function(d){
      if (d.error) { alert('방을 찾을 수 없습니다.'); return; }
      var modal = document.getElementById('chatroomDetailModal');
      var body = document.getElementById('chatroomDetailBody');
      if (!modal || !body) return;
      var uid = encodeURIComponent(d.roomId);
      var online = d.users || [];
      var hist = d.visitorHistory || [];
      var onlineSet = {};
      online.forEach(function(u){ onlineSet[u] = true; });
      var histHtml = hist.length ? hist.map(function(n){
        var on = onlineSet[n] ? ' <span class="chip" style="font-size:9px;">접속중</span>' : '';
        var kick = onlineSet[n]
          ? '<form method="post" action="' + ctx + '/admin/chatroom/' + uid + '/kick" style="margin:0 0 0 8px;display:inline;" onsubmit="return confirm(\'이 사용자를 추방할까요?\');">'
            + '<input type="hidden" name="nickname" value="' + escapeHtml(n) + '"/>'
            + '<button type="submit" class="btn danger" style="padding:2px 8px;font-size:11px;">추방</button></form>'
          : '';
        return '<div style="display:flex;align-items:center;flex-wrap:wrap;gap:6px;padding:8px 0;border-bottom:1px solid rgba(244,114,182,.10);">'
          + '<span style="font-weight:700;">' + escapeHtml(n) + '</span>' + on + kick + '</div>';
      }).join('') : '<div class="empty">아직 입장 기록이 없습니다.</div>';
      body.innerHTML = '<div style="font-weight:900;margin-bottom:8px;font-size:15px;">' + escapeHtml(d.roomName || '') + '</div>'
        + '<div class="m" style="margin-bottom:14px;">방장: ' + escapeHtml(d.creatorNickname || '') + ' · 방 ID: ' + escapeHtml(d.roomId || '') + ' · ' + (d.secret ? '비밀방' : '공개') + '</div>'
        + '<div style="font-size:11px;letter-spacing:.08em;color:#7f62a3;margin-bottom:8px;font-family:Orbitron,sans-serif;">누적 입장 닉네임 (한 번이라도 들어온 사람)</div>'
        + '<div>' + histHtml + '</div>';
      modal.style.display = 'flex';
      modal.setAttribute('aria-hidden', 'false');
    })
    .catch(function(){ alert('상세 정보를 불러오지 못했습니다.'); });
}

(function(){
  var roomsEl = document.getElementById('chatroomAdminRooms');
  var flagsEl = document.getElementById('chatroomAdminFlags');
  var btn = document.getElementById('chatroomAdminRefresh');
  if (!roomsEl || !flagsEl) return;
  roomsEl.addEventListener('click', function(e){
    var b = e.target.closest('.js-chatroom-detail');
    if (!b) return;
    e.preventDefault();
    var id = b.getAttribute('data-room-id');
    if (id) openChatroomDetail(id);
  });
  function loadChatroomAdmin(){
    safeFetch(ctx + '/admin/chatroom/data')
      .then(function(r){ if (!r.ok) throw new Error(); return r.json(); })
      .then(function(d){
        var rooms = d.rooms || [];
        var flags = d.flags || [];
        roomsEl.innerHTML = rooms.length ? rooms.map(function(room){
          var rid = room.roomId || '';
          var uid = encodeURIComponent(rid);
          var users = (room.users || []);
          var usersHtml = users.length
            ? users.map(function(u){
                return '<span style="display:inline-flex;align-items:center;gap:6px;margin:3px 6px 3px 0;">'
                  + '<span class="chip">' + escapeHtml(u) + '</span>'
                  + '<form method="post" action="' + ctx + '/admin/chatroom/' + uid + '/kick" style="margin:0;display:inline;" onsubmit="return confirm(\'추방할까요?\');">'
                  + '<input type="hidden" name="nickname" value="' + escapeHtml(u) + '"/>'
                  + '<button type="submit" class="btn danger" style="padding:3px 8px;font-size:11px;">추방</button>'
                  + '</form></span>';
              }).join('')
            : '<span style="font-size:12px;color:#8e6f7f;">접속자 없음</span>';
          return '<div class="row" style="flex-wrap:wrap;align-items:flex-start;">'
            + '<div style="min-width:220px;flex:1;">'
            + '<div class="t">' + escapeHtml(room.roomName || '') + ' <span style="font-size:11px;color:#8e6f7f;">' + escapeHtml(rid) + '</span></div>'
            + '<div class="m">방장: ' + escapeHtml(room.creatorNickname || '') + ' · ' + (room.userCount || 0) + '명 · ' + (room.secret ? '비밀방' : '공개') + '</div>'
            + '<div style="margin-top:8px;">' + usersHtml + '</div>'
            + '</div>'
            + '<div class="tools" style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;">'
            + '<button type="button" class="btn js-chatroom-detail" data-room-id="' + escapeHtml(rid) + '">방 상세</button>'
            + '<form method="post" action="' + ctx + '/admin/chatroom/' + uid + '/delete" style="margin:0;" onsubmit="return confirm(\'이 방을 삭제할까요? 접속 중인 사용자가 모두 나가게 됩니다.\');">'
            + '<button type="submit" class="btn danger">방 삭제</button>'
            + '</form></div>'
            + '</div>';
        }).join('') : '<div class="empty">개설된 채팅방이 없습니다.</div>';

        var fr = flags.slice().reverse();
        flagsEl.innerHTML = fr.length ? fr.map(function(f){
          var fid = encodeURIComponent(f.roomId || '');
          return '<div class="row" style="flex-wrap:wrap;align-items:flex-start;">'
            + '<div style="min-width:0;flex:1;">'
            + '<div class="t" style="font-size:12px;">' + escapeHtml(f.roomName || '') + ' · ' + escapeHtml(f.nickname || '') + '</div>'
            + '<div class="m" style="white-space:pre-wrap;word-break:break-word;">' + escapeHtml(f.content || '') + '</div>'
            + '<div class="m">' + escapeHtml(f.reason || '') + ' · ' + escapeHtml(f.at || '') + '</div>'
            + '</div>'
            + '<form method="post" action="' + ctx + '/admin/chatroom/' + fid + '/delete" style="margin:0;" onsubmit="return confirm(\'해당 방을 삭제할까요?\');">'
            + '<button type="submit" class="btn danger">방 삭제</button>'
            + '</form>'
            + '</div>';
        }).join('') : '<div class="empty">의심 메시지 로그가 없습니다.</div>';
      })
      .catch(function(){
        roomsEl.innerHTML = '<div class="empty">불러오지 못했습니다. 관리자 권한으로 로그인했는지 확인하세요.</div>';
      });
  }
  if (btn) btn.addEventListener('click', loadChatroomAdmin);
  loadChatroomAdmin();
  setInterval(loadChatroomAdmin, 60000);
})();

function closeChatKeywordModal() {
  var m = document.getElementById('chatKeywordModal');
  if (!m) return;
  m.style.display = 'none';
  m.setAttribute('aria-hidden', 'true');
}

function renderChatKeywordModalHtml(data) {
  var builtIn = data.builtIn || [];
  var custom = data.custom || [];
  var chips = builtIn.map(function(k) {
    return '<span class="chip" style="margin:3px 4px 3px 0;">' + escapeHtml(k) + '</span>';
  }).join('');
  var rows = custom.map(function(c) {
    var id = c.id;
    var kw = c.keyword || '';
    return '<div class="row" style="margin-bottom:8px;align-items:center;"><div class="t" style="min-width:0;flex:1;">' + escapeHtml(kw) + '</div>'
      + '<button type="button" class="btn danger js-chat-kw-del" style="padding:4px 10px;font-size:11px;" data-kwid="' + id + '">삭제</button></div>';
  }).join('');
  return '<div style="font-size:12px;font-weight:800;margin-bottom:8px;color:#7f62a3;">기본 키워드 (항상 적용)</div>'
    + '<div style="margin-bottom:16px;line-height:1.6;">' + (chips || '<span style="font-size:12px;color:#8e6f7f;">없음</span>') + '</div>'
    + '<div style="font-size:12px;font-weight:800;margin-bottom:8px;color:#7f62a3;">추가 키워드</div>'
    + (rows || '<div class="empty" style="padding:12px;">추가된 키워드가 없습니다.</div>')
    + '<div style="margin-top:16px;padding-top:12px;border-top:1px solid rgba(244,114,182,.12);">'
    + '<div style="font-size:12px;font-weight:700;margin-bottom:8px;">키워드 추가</div>'
    + '<div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center;">'
    + '<input type="text" id="chatKeywordNewInput" class="input" style="flex:1;min-width:160px;" maxlength="100" placeholder="새 키워드"/>'
    + '<button type="button" class="btn" id="chatKeywordAddBtn">추가</button>'
    + '</div>'
    + '<p style="margin:8px 0 0;font-size:11px;color:#8e6f7f;">부분 일치(대소문자 무시)로 감지합니다. 기본 키워드와 동일한 문구는 추가할 수 없습니다.</p>'
    + '</div>';
}

function bindChatKeywordModalActions() {
  var body = document.getElementById('chatKeywordModalBody');
  if (!body) return;
  body.querySelectorAll('.js-chat-kw-del').forEach(function(btn) {
    btn.addEventListener('click', function() {
      var id = btn.getAttribute('data-kwid');
      if (!id || !confirm('이 키워드를 삭제할까요?')) return;
      var fd = new FormData();
      safeFetch(ctx + '/admin/chatroom/keywords/' + id + '/delete', { method: 'POST', body: fd })
        .then(function(r) { return r.json(); })
        .then(function(x) {
          if (x && x.ok) { openChatKeywordModal(); }
          else { alert('삭제에 실패했습니다.'); }
        })
        .catch(function() { alert('삭제 요청에 실패했습니다.'); });
    });
  });
  var addBtn = document.getElementById('chatKeywordAddBtn');
  var inp = document.getElementById('chatKeywordNewInput');
  if (addBtn && inp) {
    addBtn.addEventListener('click', function() {
      var kw = (inp.value || '').trim();
      if (!kw) { alert('키워드를 입력하세요.'); return; }
      var fd = new FormData();
      fd.append('keyword', kw);
      safeFetch(ctx + '/admin/chatroom/keywords/add', { method: 'POST', body: fd })
        .then(function(r) { return r.json(); })
        .then(function(x) {
          var res = x && x.result;
          if (res === 'ok') { openChatKeywordModal(); return; }
          var msg = { empty: '빈 값입니다.', invalid: '100자 이내로 입력하세요.', duplicate: '이미 등록된 키워드입니다.', builtin: '기본 키워드와 동일합니다.' };
          alert(msg[res] || '추가에 실패했습니다.');
        })
        .catch(function() { alert('추가 요청에 실패했습니다.'); });
    });
  }
}

function openChatKeywordModal() {
  var modal = document.getElementById('chatKeywordModal');
  var body = document.getElementById('chatKeywordModalBody');
  if (!modal || !body) return;
  modal.style.display = 'flex';
  modal.setAttribute('aria-hidden', 'false');
  body.innerHTML = '<div class="empty">불러오는 중…</div>';
  safeFetch(ctx + '/admin/chatroom/keywords/data')
    .then(function(r) { if (!r.ok) throw new Error(); return r.json(); })
    .then(function(d) {
      body.innerHTML = renderChatKeywordModalHtml(d);
      bindChatKeywordModalActions();
    })
    .catch(function() {
      body.innerHTML = '<div class="empty">불러오지 못했습니다.</div>';
    });
}

var chatKeywordBtn = document.getElementById('chatKeywordSettingsBtn');
if (chatKeywordBtn) {
  chatKeywordBtn.addEventListener('click', openChatKeywordModal);
}

function escapeHtml(s) {
  if (s == null || s === '') return '';
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
function formatNumber(n){
  var v = Number(n || 0);
  return v.toLocaleString('ko-KR');
}
function wireListFilter(inputId, itemSelector){
  var input = document.getElementById(inputId);
  if (!input) return;
  var items = Array.prototype.slice.call(document.querySelectorAll(itemSelector));
  function applyFilter(){
    var q = (input.value || '').trim().toLowerCase();
    items.forEach(function(el){
      var hay = String(el.getAttribute('data-search') || '').toLowerCase();
      el.style.display = (!q || hay.indexOf(q) !== -1) ? '' : 'none';
    });
  }
  input.addEventListener('input', applyFilter);
  applyFilter();
}
function openMemberDetail(mno){
  safeFetch(ctx + '/admin/members/' + mno + '/detail')
    .then(function(r){
      if (!r.ok) return r.text().then(function(t){ throw new Error(t || r.status); });
      return r.json();
    })
    .then(function(d){
      if(d && d.error){ alert(d.error); return; }
      var old = document.getElementById('memberDetailOverlay');
      if(old) old.remove();
      var runs = d.recentRuns || [];
      var runsHtml = runs.length
        ? runs.map(function(r){
            return '<div style="display:flex;justify-content:space-between;align-items:center;padding:8px 10px;border:1px solid rgba(244,114,182,.14);border-radius:10px;background:#fff;margin-bottom:6px;">'
              + '<div><strong>#'+(r.runId||'-')+'</strong> <span style="font-size:12px;color:#8e6f7f;">'+escapeHtml(r.groupType||'')+' · '+escapeHtml(r.phase||'')+'</span></div>'
              + '<a class="btn" style="text-decoration:none;" href="'+ctx+'/game/run/'+(r.runId||0)+'/start">열기</a>'
              + '</div>';
          }).join('')
        : '<div style="font-size:13px;color:#8e6f7f;">최근 플레이 없음</div>';
      var ownTrainees = d.ownedTrainees || [];
      var ownTraineeRows = d.ownedTraineeRows || [];
      var ownCards = d.ownedPhotoCards || [];
      var traineeCheckList = (d.allTrainees || []).map(function(t){
        return '<label style="display:inline-flex;align-items:center;gap:6px;padding:4px 6px;border:1px solid rgba(244,114,182,.12);border-radius:8px;background:#fff;">'
          + '<input type="checkbox" class="js-trainee-check" value="'+t.id+'" />'
          + '<span>'+escapeHtml(t.name||('-#'+t.id))+'</span>'
          + '</label>';
      }).join('');
      var activityHtml = (d.recentActivities || []).length
        ? d.recentActivities.map(function(a){
            var delta = Number(a.coinDelta || 0);
            var sign = delta > 0 ? '+' : '';
            return '<div style="padding:6px 8px;border-bottom:1px solid rgba(244,114,182,.08);font-size:12px;">'
              + '<strong>'+escapeHtml(a.type || '-')
              + '</strong> · '+sign+formatNumber(delta)+'C'
              + ' · '+escapeHtml(a.note || '-')
              + ' <span style="color:#8e6f7f;">('+escapeHtml(a.createdAt || '-')+')</span></div>';
          }).join('')
        : '<div style="font-size:12px;color:#8e6f7f;">최근 활동 없음</div>';
      var sanctionsHtml = (d.recentSanctions || []).length
        ? d.recentSanctions.map(function(s){
            return '<div style="padding:6px 8px;border-bottom:1px solid rgba(244,114,182,.08);font-size:12px;">'
              + '<strong>' + (Number(s.days || 0)) + '일 정지</strong>'
              + ' · 관리자 ' + escapeHtml(s.adminNick || '-')
              + ' · 시작 ' + escapeHtml(s.createdAt || '-')
              + ' · 만료 ' + escapeHtml(s.expiresAt || '-')
              + (s.reason ? ' · 사유 ' + escapeHtml(s.reason) : '')
              + '</div>';
          }).join('')
        : '<div style="font-size:12px;color:#8e6f7f;">최근 제재 내역 없음</div>';
      var traineeEnhanceOptions = ownTraineeRows.map(function(t){
        var lv = Number(t.enhanceLevel || 0);
        var text = (lv >= 5 ? 'MAX' : ('+' + lv));
        var qty = Number(t.quantity || 0);
        return '<option value="' + Number(t.traineeId || 0) + '" data-lv="' + lv + '" data-qty="' + qty + '">'
          + escapeHtml(t.name || ('#' + t.traineeId)) + ' · ' + text + ' · ' + qty + '장'
          + '</option>';
      }).join('');

      var opts = d.rankOptions || [];
      var rankSel = opts.map(function(o){
        var c = o.code || '';
        var sel = (d.effectiveRankCode && d.effectiveRankCode === c) ? ' selected' : '';
        return '<option value="'+escapeHtml(c)+'"'+sel+'>'+escapeHtml(o.label || c)+'</option>';
      }).join('');

      var profBlock = '';
      if (d.profileImage && String(d.profileImage).trim() !== '') {
        profBlock = '<div style="margin:10px 0;"><img src="'+ctx+'/profile-image/'+escapeHtml(d.profileImage)+'" alt="" style="max-width:120px;max-height:120px;border-radius:12px;border:1px solid rgba(244,114,182,.2);object-fit:cover;" /></div>';
      }

      var html = ''
        + '<div id="memberDetailOverlay" style="position:fixed;inset:0;z-index:1200;background:rgba(31,15,23,.42);display:flex;align-items:center;justify-content:center;padding:16px;overflow:auto;" onclick="if(event.target===this)this.remove()">'
        + '  <div style="width:min(760px,97vw);max-height:92vh;overflow:auto;background:#fff;border:1px solid rgba(244,114,182,.2);border-radius:16px;box-shadow:0 28px 54px rgba(31,15,23,.25);" onclick="event.stopPropagation()">'
        + '    <div style="height:3px;background:linear-gradient(90deg,#f472b6,#fbcfe8);"></div>'
        + '    <div style="padding:16px;">'
        + '      <div style="position:sticky;top:0;z-index:3;display:flex;align-items:center;justify-content:space-between;gap:12px;margin:-16px -16px 12px -16px;padding:12px 16px;background:linear-gradient(180deg,#fff 70%,rgba(255,255,255,.92));border-bottom:1px solid rgba(244,114,182,.14);">'
        + '        <div style="font-weight:900;font-size:16px;">회원 상세</div>'
        + '        <button type="button" class="btn" aria-label="모달 닫기" onclick="document.getElementById(\'memberDetailOverlay\').remove()" style="flex-shrink:0;">닫기</button>'
        + '      </div>'
        +        profBlock
        + '      <div style="font-size:13px;line-height:1.85;color:#4a3340;">'
        + '        <div><strong>ID</strong> '+escapeHtml(d.mid||'-')+'</div>'
        + '        <div><strong>이름</strong> '+escapeHtml(d.name||'-')+'</div>'
        + '        <div><strong>닉네임</strong> '+escapeHtml((d.nickname&&d.nickname.trim())?d.nickname:'-')+'</div>'
        + '        <div><strong>이메일</strong> '+escapeHtml(d.email||'-')+'</div>'
        + '        <div><strong>휴대폰</strong> '+escapeHtml(d.phone||'-')+'</div>'
        + '        <div><strong>주소</strong> '+escapeHtml(d.address||'-')+'</div>'
        + '        <div><strong>상세주소</strong> '+escapeHtml(d.addressDetail||'-')+'</div>'
        + '        <div><strong>주민번호</strong> '+escapeHtml(d.jumin||'-')+'</div>'
        + '        <div><strong>권한</strong> '+escapeHtml(d.role||'-')+'</div>'
        + '        <div><strong>계정 상태</strong> '+escapeHtml(d.accountStatus||'활성')+'</div>'
        + '        <div><strong>정지 만료일</strong> '+escapeHtml(d.suspendedUntil||'-')+'</div>'
        + '        <div><strong>가입일</strong> '+escapeHtml(d.createdAt||'-')+'</div>'
        + '        <div><strong>다시뽑기 잔여</strong> '+(d.rerollRemaining != null ? d.rerollRemaining : '-')+' / 충전기준 '+escapeHtml(d.rerollLastAt||'-')+'</div>'
        + '        <div><strong>누적 팬 등급 경험치</strong> '+(d.rankExp != null ? d.rankExp : '-')+'</div>'
        + '        <div><strong>현재 표시 등급</strong> '+escapeHtml(d.effectiveRankLabel||'-')+' <span style="font-size:12px;color:#8e6f7f;">('+escapeHtml(d.effectiveRankCode||'')+')</span></div>'
        + '      </div>'
        + '      <div style="margin-top:12px;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;">'
        + '        <div class="metric"><div class="k">보유 코인</div><div class="v">'+formatNumber(d.coin||0)+'</div></div>'
        + '        <div class="metric"><div class="k">보유 연습생</div><div class="v">'+formatNumber(d.traineeCount||0)+'</div></div>'
        + '        <div class="metric"><div class="k">보유 포토카드</div><div class="v">'+formatNumber(d.photoCardCount||0)+'</div></div>'
        + '      </div>'
        + '      <div style="margin-top:14px;padding:12px;border:1px solid rgba(244,114,182,.18);border-radius:12px;background:#fffafb;">'
        + '        <div style="font-weight:800;font-size:13px;margin-bottom:8px;color:#7c1d51;">등급 지정</div>'
        + '        <div style="font-size:12px;color:#8e6f7f;margin-bottom:8px;">선택한 등급의 최소 경험치로 맞춰 저장됩니다. (팬 활동으로 경험치가 올라가면 등급이 함께 변할 수 있습니다.)</div>'
        + '        <div style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;">'
        + '          <label style="font-size:13px;">등급 <select id="memberDetailRankSel" class="input" style="min-width:180px;">'+rankSel+'</select></label>'
        + '          <button type="button" class="btn" id="memberDetailSaveRank">등급 저장</button>'
        + '        </div>'
        + '      </div>'
        + '      <div style="margin-top:10px;padding:12px;border:1px solid rgba(244,114,182,.18);border-radius:12px;background:#fff;">'
        + '        <div style="font-weight:800;font-size:13px;margin-bottom:8px;color:#7c1d51;">코인 관리</div>'
        + '        <div style="font-size:12px;color:#8e6f7f;margin-bottom:8px;">현재 코인: <strong>'+formatNumber(d.coin||0)+'</strong></div>'
        + '        <div style="display:flex;flex-wrap:wrap;gap:8px;">'
        + '          <select id="memberCoinType" class="input"><option value="ADD">지급(ADD)</option><option value="SUBTRACT">차감(SUBTRACT)</option></select>'
        + '          <input id="memberCoinAmount" type="number" min="1" class="input" placeholder="수량" />'
        + '          <input id="memberCoinReason" type="text" class="input" placeholder="사유" style="flex:1;min-width:180px;" />'
        + '          <button type="button" class="btn" id="memberCoinApply">적용</button>'
        + '        </div>'
        + '      </div>'
        + '      <div style="margin-top:10px;padding:12px;border:1px solid rgba(244,114,182,.18);border-radius:12px;background:#fff;">'
        + '        <div style="font-weight:800;font-size:13px;margin-bottom:8px;color:#7c1d51;">보유 연습생 관리</div>'
        + '        <div style="font-size:12px;color:#8e6f7f;margin-bottom:8px;">현재 보유: '+(ownTrainees.length ? ownTrainees.map(escapeHtml).join(', ') : '없음')+'</div>'
        + '        <div style="font-size:11px;color:#8e6f7f;margin-bottom:6px;">추가할 연습생을 체크하세요.</div>'
        + '        <div style="display:flex;gap:8px;flex-wrap:wrap;max-height:140px;overflow:auto;padding:4px;">'+(traineeCheckList || '<span style="font-size:12px;color:#8e6f7f;">연습생 없음</span>')+'</div>'
        + '        <div style="margin-top:8px;">'
        + '          <button type="button" class="btn" id="memberAddTraineeBtn">선택 연습생 추가</button>'
        + '        </div>'
        + '      </div>'
        + '      <div style="margin-top:10px;padding:12px;border:1px solid rgba(244,114,182,.18);border-radius:12px;background:#fff;">'
        + '        <div style="font-weight:800;font-size:13px;margin-bottom:8px;color:#7c1d51;">포토카드 지급</div>'
        + '        <div style="font-size:12px;color:#8e6f7f;margin-bottom:8px;">현재 보유: '+(ownCards.length ? ownCards.map(escapeHtml).join(', ') : '없음')+'</div>'
        + '        <div style="font-size:11px;color:#8e6f7f;margin-bottom:6px;">지급할 연습생을 체크하고 등급을 선택하세요.</div>'
        + '        <div style="display:flex;gap:8px;flex-wrap:wrap;max-height:140px;overflow:auto;padding:4px;">'
        +            (traineeCheckList ? traineeCheckList.replace(/js-trainee-check/g,'js-photo-trainee-check') : '<span style="font-size:12px;color:#8e6f7f;">연습생 없음</span>')
        + '        </div>'
        + '        <div style="margin-top:8px;display:flex;gap:8px;flex-wrap:wrap;">'
        + '          <select id="memberPhotoGradeSel" class="input"><option value="R">R</option><option value="SR">SR</option><option value="SSR">SSR</option></select>'
        + '          <button type="button" class="btn" id="memberGrantPhotoBtn">지급</button>'
        + '        </div>'
        + '      </div>'
        + '      <div style="margin-top:10px;padding:12px;border:1px solid rgba(244,114,182,.18);border-radius:12px;background:#fff;">'
        + '        <div style="font-weight:800;font-size:13px;margin-bottom:8px;color:#7c1d51;">카드 강화 관리</div>'
        + '        <div style="font-size:12px;color:#8e6f7f;margin-bottom:8px;">회원 보유 연습생의 강화 단계(0~5)와 카드 수량을 직접 보정합니다.</div>'
        + '        <div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center;">'
        + '          <select id="memberEnhanceTraineeSel" class="input" style="min-width:230px;">'
        +              (traineeEnhanceOptions || '<option value="">보유 연습생 없음</option>')
        + '          </select>'
        + '          <label style="font-size:12px;color:#4a3340;">강화'
        + '            <input id="memberEnhanceLevel" type="number" min="0" max="5" class="input" style="width:82px;margin-left:6px;" />'
        + '          </label>'
        + '          <label style="font-size:12px;color:#4a3340;">카드수량'
        + '            <input id="memberEnhanceQty" type="number" min="0" class="input" style="width:92px;margin-left:6px;" />'
        + '          </label>'
        + '          <button type="button" class="btn" id="memberEnhanceApplyBtn">강화 반영</button>'
        + '        </div>'
        + '      </div>'
        + '      <div style="margin-top:12px;font-size:12px;color:#8e6f7f;">최근 런</div>'
        + '      <div style="margin-top:8px;">'+runsHtml+'</div>'
        + '      <div style="margin-top:12px;font-size:12px;color:#8e6f7f;">최근 활동</div>'
        + '      <div style="margin-top:8px;border:1px solid rgba(244,114,182,.12);border-radius:10px;padding:6px 8px;background:#fffafb;">'+activityHtml+'</div>'
        + '      <div style="margin-top:12px;font-size:12px;color:#8e6f7f;">최근 제재</div>'
        + '      <div style="margin-top:8px;border:1px solid rgba(244,114,182,.12);border-radius:10px;padding:6px 8px;background:#fffafb;">'+sanctionsHtml+'</div>'
        + '      <div style="margin-top:14px;display:flex;gap:8px;flex-wrap:wrap;">'
        + '        <button type="button" class="btn" onclick="document.getElementById(\'memberDetailOverlay\').remove()">닫기</button>'
        + '      </div>'
        + '    </div>'
        + '  </div>'
        + '</div>';
      document.body.insertAdjacentHTML('beforeend', html);
      var saveBtn = document.getElementById('memberDetailSaveRank');
      if (saveBtn) {
        saveBtn.addEventListener('click', function(){
          var sel = document.getElementById('memberDetailRankSel');
          var code = sel ? sel.value : '';
          if (!code) { alert('등급을 선택하세요.'); return; }
          var body = 'memberRankCode=' + encodeURIComponent(code);
          safeFetch(ctx + '/admin/members/' + mno + '/grade', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: body
          })
            .then(function(r){ return r.json().then(function(j){ return { ok: r.ok, j: j }; }); })
            .then(function(x){
              if (!x.ok || (x.j && x.j.error)) { alert((x.j && x.j.error) ? x.j.error : '저장에 실패했습니다.'); return; }
              alert('등급이 저장되었습니다.');
              document.getElementById('memberDetailOverlay').remove();
              openMemberDetail(mno);
            })
            .catch(function(){ alert('저장에 실패했습니다.'); });
        });
      }
      var coinBtn = document.getElementById('memberCoinApply');
      if (coinBtn) {
        coinBtn.addEventListener('click', function(){
          var type = (document.getElementById('memberCoinType') || {}).value || 'ADD';
          var amount = Number((document.getElementById('memberCoinAmount') || {}).value || 0);
          var reason = (document.getElementById('memberCoinReason') || {}).value || '';
          if (amount <= 0) { alert('수량은 1 이상이어야 합니다.'); return; }
          safeFetch(ctx + '/admin/member/' + mno + '/coin', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ memberId: mno, type: type, amount: amount, reason: reason })
          })
          .then(function(r){ return r.json().then(function(j){ return { ok: r.ok, j: j }; }); })
          .then(function(x){
            if (!x.ok || (x.j && x.j.error)) { alert((x.j && x.j.error) ? x.j.error : '코인 처리에 실패했습니다.'); return; }
            alert('코인 변경이 반영되었습니다.');
            document.getElementById('memberDetailOverlay').remove();
            openMemberDetail(mno);
          })
          .catch(function(){ alert('코인 처리에 실패했습니다.'); });
        });
      }
      var addTraineeBtn = document.getElementById('memberAddTraineeBtn');
      if (addTraineeBtn) {
        addTraineeBtn.addEventListener('click', function(){
          var selected = Array.prototype.slice.call(document.querySelectorAll('.js-trainee-check:checked')).map(function(el){ return el.value; });
          if (!selected.length) { alert('연습생을 선택하세요.'); return; }
          var params = selected.map(function(id){ return 'traineeIds=' + encodeURIComponent(id); }).join('&');
          safeFetch(ctx + '/admin/member/' + mno + '/trainee?' + params, { method: 'POST' })
            .then(function(r){ return r.json().then(function(j){ return { ok: r.ok, j: j }; }); })
            .then(function(x){
              if (!x.ok || (x.j && x.j.error)) { alert((x.j && x.j.error) ? x.j.error : '연습생 추가에 실패했습니다.'); return; }
              alert('연습생 추가 완료: ' + (x.j.addedCount || 0) + '건 (중복/건너뜀 ' + (x.j.skippedCount || 0) + '건)');
              document.getElementById('memberDetailOverlay').remove();
              openMemberDetail(mno);
            })
            .catch(function(){ alert('연습생 추가에 실패했습니다.'); });
        });
      }
      var grantPhotoBtn = document.getElementById('memberGrantPhotoBtn');
      if (grantPhotoBtn) {
        grantPhotoBtn.addEventListener('click', function(){
          var selected = Array.prototype.slice.call(document.querySelectorAll('.js-photo-trainee-check:checked')).map(function(el){ return Number(el.value); });
          var grade = (document.getElementById('memberPhotoGradeSel') || {}).value || 'R';
          if (!selected.length) { alert('연습생을 선택하세요.'); return; }
          safeFetch(ctx + '/admin/member/' + mno + '/photocard', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ memberId: mno, traineeIds: selected, grade: grade })
          })
          .then(function(r){ return r.json().then(function(j){ return { ok: r.ok, j: j }; }); })
          .then(function(x){
            if (!x.ok || (x.j && x.j.error)) { alert((x.j && x.j.error) ? x.j.error : '포토카드 지급에 실패했습니다.'); return; }
            alert('포토카드 지급 완료: ' + (x.j.grantedCount || 0) + '건 (중복/건너뜀 ' + (x.j.skippedCount || 0) + '건)');
            document.getElementById('memberDetailOverlay').remove();
            openMemberDetail(mno);
          })
          .catch(function(){ alert('포토카드 지급에 실패했습니다.'); });
        });
      }
      var enhanceSel = document.getElementById('memberEnhanceTraineeSel');
      var enhanceLevelInput = document.getElementById('memberEnhanceLevel');
      var enhanceQtyInput = document.getElementById('memberEnhanceQty');
      function syncEnhanceInputsFromSelect() {
        if (!enhanceSel) return;
        var opt = enhanceSel.options[enhanceSel.selectedIndex];
        if (!opt) return;
        if (enhanceLevelInput) enhanceLevelInput.value = Number(opt.getAttribute('data-lv') || 0);
        if (enhanceQtyInput) enhanceQtyInput.value = Number(opt.getAttribute('data-qty') || 0);
      }
      if (enhanceSel) {
        enhanceSel.addEventListener('change', syncEnhanceInputsFromSelect);
        syncEnhanceInputsFromSelect();
      }
      var enhanceApplyBtn = document.getElementById('memberEnhanceApplyBtn');
      if (enhanceApplyBtn) {
        enhanceApplyBtn.addEventListener('click', function(){
          if (!enhanceSel || !enhanceSel.value) { alert('보유 연습생이 없습니다.'); return; }
          var traineeId = Number(enhanceSel.value || 0);
          var lv = Number((enhanceLevelInput || {}).value || 0);
          var qty = Number((enhanceQtyInput || {}).value || 0);
          if (!traineeId) { alert('연습생을 선택하세요.'); return; }
          if (lv < 0 || lv > 5 || !Number.isFinite(lv)) { alert('강화 단계는 0~5만 가능합니다.'); return; }
          if (qty < 0 || !Number.isFinite(qty)) { alert('카드 수량은 0 이상이어야 합니다.'); return; }
          safeFetch(ctx + '/admin/member/' + mno + '/enhance', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ traineeId: traineeId, enhanceLevel: lv, quantity: qty })
          })
          .then(function(r){ return r.json().then(function(j){ return { ok: r.ok, j: j }; }); })
          .then(function(x){
            if (!x.ok || (x.j && x.j.error)) { alert((x.j && x.j.error) ? x.j.error : '강화 반영에 실패했습니다.'); return; }
            alert('강화 정보가 반영되었습니다.');
            document.getElementById('memberDetailOverlay').remove();
            openMemberDetail(mno);
          })
          .catch(function(){ alert('강화 반영에 실패했습니다.'); });
        });
      }
    })
    .catch(function(){ alert('불러오기에 실패했습니다. (서버 오류일 수 있습니다)'); });
}
wireListFilter('gameSceneListFilter', '.js-game-scene-preview');
wireListFilter('gameSceneEditFilter', '.js-game-scene-edit');
wireListFilter('gameChoiceEditFilter', '.js-game-choice-edit');
</script>
</body>
</html>
