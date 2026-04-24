<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 주차/일차는 서버에서 계산해서 weekNum/dayInWeek로 내려옴 --%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>NEXT DEBUT — GAME</title>
<%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
<link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=Noto+Sans+KR:wght@400;500;700;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="${ctx}/css/game.css?v=20260421_targeting_modal_totalavg_v1">
<link rel="stylesheet" href="${ctx}/css/sim-status-presentation.css?v=20260403_sim_ui">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
</head>
<body class="is-game-route is-gameplay-screen">

<%-- 로딩 오버레이 (NEXT DEBUT) --%>
<div id="lov">
  <div class="lray"></div><div class="lray"></div><div class="lray"></div>
  <div class="ltitle">NEXT DEBUT</div>
  <div class="lsub">LOADING GAME . . .</div>
  <div class="lbar-wrap"><div class="lbar"></div></div>
  <div class="lpct" id="lpct">0%</div>
</div>

<div id="gameToast" class="game-toast" role="status" aria-live="polite"></div>

<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>

<div class="chem-modal" id="chemModal" onclick="closeChemModal(event)">
  <div class="chem-modal__viewport">
    <div class="chem-modal__dialog" role="dialog" aria-modal="true" aria-labelledby="chemModalName" onclick="event.stopPropagation()">
      <div class="chem-modal__head">
      <div>
        <div class="chem-modal__eyebrow">TEAM CHEMISTRY</div>
        <div class="chem-modal__title">
          <span class="chem-modal__grade" id="chemModalGrade">${chemistry.chemGrade}</span>
          <span class="chem-modal__name" id="chemModalName">${chemistry.chemLabel}</span>
        </div>
        <div class="chem-modal__bonus" id="chemModalBonus"><i class="fas fa-bolt"></i> +${chemistry.totalBonus}% BOOST (시너지 ${chemistry.baseBonus}% + 등급 ${chemistry.gradeBonus}%)</div>
      </div>
      <button type="button" class="chem-modal__close" onclick="closeChemModal()"><i class="fas fa-xmark"></i></button>
    </div>
      <div class="chem-modal__body">
        <div class="chem-modal__desc" id="chemModalDesc"></div>
        <div class="chem-modal__grid" id="chemModalGrid"></div>
      </div>
    </div>
  </div>
</div>

<div class="chem-modal" id="chemCatalogModal" onclick="closeChemCatalogModal(event)">
  <div class="chem-modal__viewport">
    <div class="chem-modal__dialog" role="dialog" aria-modal="true" aria-labelledby="chemCatalogModalName" onclick="event.stopPropagation()">
      <div class="chem-modal__head">
      <div>
        <div class="chem-modal__eyebrow">CHEMISTRY GUIDE</div>
        <div class="chem-modal__title">
          <span class="chem-modal__grade"><i class="fas fa-list"></i></span>
          <span class="chem-modal__name" id="chemCatalogModalName">전체 케미스트리 종류</span>
        </div>
      </div>
      <button type="button" class="chem-modal__close" onclick="closeChemCatalogModal()"><i class="fas fa-xmark"></i></button>
    </div>
      <div class="chem-modal__body">
        <div class="chem-modal__desc">현재 프로젝트에 적용된 케미 조건 목록입니다. 실제 발동 시에는 상위 4개가 선택되며, 시너지 합산 보너스에 등급 보너스가 추가됩니다.</div>
        <div class="chem-list" id="chemCatalogList"></div>
      </div>
    </div>
  </div>
</div>

<div class="chem-modal" id="goalModal" onclick="closeGoalModal(event)">
  <div class="chem-modal__viewport">
    <div class="chem-modal__dialog" role="dialog" aria-modal="true" aria-labelledby="goalModalTitle" onclick="event.stopPropagation()">
      <div class="chem-modal__head">
        <div>
          <div class="chem-modal__eyebrow">TODAY'S GOALS</div>
          <div class="chem-modal__title">
            <span class="chem-modal__grade"><i class="fas fa-bullseye"></i></span>
            <span class="chem-modal__name" id="goalModalTitle">목표</span>
          </div>
        </div>
        <button type="button" class="chem-modal__close" onclick="closeGoalModal()"><i class="fas fa-xmark"></i></button>
      </div>
      <div class="chem-modal__body">
        <div class="goal-panel" id="goalPanel">
          <div class="goal-title">PROGRESS · 오늘의 목표</div>
          <div class="goal-grid">
          <div class="goal-item" id="goal1">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-users"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">팬 500명 달성</div>
              <div class="goal-item-sub">팀 전투력(총합) 220 이상 만들기</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal1Bar"></div></div>
            </div>
          </div>
          <div class="goal-item" id="goal2">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-microphone-lines"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">첫 공연 성공</div>
              <div class="goal-item-sub">중간 평가까지 콤보 3회 이상</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal2Bar"></div></div>
            </div>
          </div>
          <div class="goal-item" id="goal3">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-flag-checkered"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">데뷔 준비 완료</div>
              <div class="goal-item-sub">최종 평가(DAY 84)까지 도달</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal3Bar"></div></div>
            </div>
          </div>
          <div class="goal-item" id="goal4">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-heart"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">국내 팬 확보</div>
              <div class="goal-item-sub">국내 팬 150명 이상</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal4Bar"></div></div>
            </div>
          </div>
          <div class="goal-item" id="goal5">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-trophy"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">라이브 상위권</div>
              <div class="goal-item-sub">라이브 랭킹 20위 안에 들기</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal5Bar"></div></div>
            </div>
          </div>
          <div class="goal-item" id="goal6">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-chart-line"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">팀 성장</div>
              <div class="goal-item-sub">멤버 스탯 합계 900 이상</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal6Bar"></div></div>
            </div>
          </div>
          <div class="goal-item" id="goal7">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-globe"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">팬덤 규모</div>
              <div class="goal-item-sub">총 팬 1,200명 이상</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal7Bar"></div></div>
            </div>
          </div>
          <div class="goal-item" id="goal8">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-fire"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">케미 시너지</div>
              <div class="goal-item-sub">케미 총 보너스 10% 이상</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal8Bar"></div></div>
            </div>
          </div>
          <div class="goal-item" id="goal9">
            <div class="goal-item__icon" aria-hidden="true"><i class="fas fa-road"></i></div>
            <div class="goal-item__content">
              <div class="goal-item-main">절반 코스 돌파</div>
              <div class="goal-item-sub">프로그램 진행도 50% 이상</div>
              <div class="goal-progress"><div class="goal-progress-bar" id="goal9Bar"></div></div>
            </div>
          </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="mini-game-overlay" id="miniGameOverlay" aria-hidden="true">
  <div class="mini-game-panel mini-game-panel--fs" id="miniGamePanel" role="dialog" aria-modal="true" aria-labelledby="miniGameIntroTitle">
    <div class="mini-game-intro-shell" id="miniGameIntroShell">
      <div class="mini-game-event-burst" id="miniGameEventBurst">이벤트 발생!</div>
      <p class="mini-game-intro-label">SURPRISE TRAINING</p>
      <h2 class="mini-game-intro-h2" id="miniGameIntroTitle"><i class="fas fa-bolt"></i><span id="miniGameIntroTitleText">미니게임</span></h2>
      <p class="mini-game-intro-p" id="miniGameIntroDesc">준비 중…</p>
      <button type="button" class="mini-game-btn mega" id="miniGameBtnStart">게임 시작</button>
    </div>
    <div class="mini-game-play-shell" id="miniGamePlayShell" style="display:none;">
      <div class="mini-game-play-top">
        <div class="mini-game-panel__title" id="miniGamePlayTitle"></div>
        <p class="mini-game-panel__desc" id="miniGamePlayDesc"></p>
      </div>
      <div class="mini-game-panel__stage" id="miniGameStage"></div>
      <div class="mini-game-hud">
        <span id="miniGameHudLeft"></span>
        <span class="mini-game-timer" id="miniGameTimer"></span>
      </div>
      <div class="mini-game-result-msg" id="miniGameResultMsg" style="display:none;"></div>
      <div class="mini-game-actions" id="miniGameActions" style="display:none;">
        <button type="button" class="mini-game-btn mini-game-btn--ghost" id="miniGameBtnRetry">다시</button>
        <button type="button" class="mini-game-btn" id="miniGameBtnOk">확인</button>
      </div>
    </div>
  </div>
</div>

<div class="game-body" id="gameUiRoot" data-ui-mode="app">
<%-- 게임 HUD 상단: 돈 / 팬수 / 레벨 --%>
<div class="game-hud">
  <div class="game-hud-item game-hud-item--money">
    <div class="game-hud-icon"><i class="fas fa-coins"></i></div>
    <div>
      <div class="game-hud-lbl">COIN</div>
      <div class="game-hud-val"><c:out value="${currentCoin != null ? currentCoin : 0}"/></div>
    </div>
  </div>
  <button type="button" class="game-hud-item game-hud-item--inventory" id="openInventoryModalBtn" title="인벤토리" aria-label="인벤토리 열기">
    <div class="game-hud-icon"><i class="fas fa-box-open" aria-hidden="true"></i></div>
    <div>
      <div class="game-hud-lbl">ITEM</div>
      <div class="game-hud-val game-hud-val--inventory">INV</div>
    </div>
  </button>

  <div class="game-hud-applied">
    <div class="game-hud-applied-label">ITEM</div>
    <div>
      <div class="game-hud-applied-list">
        <c:choose>
          <c:when test="${not empty appliedItems}">
            <c:forEach var="item" items="${appliedItems}" varStatus="status">
              <c:set var="alreadyPrinted" value="false" />
              <c:if test="${status.index > 0}">
                <c:forEach var="prevItem" items="${appliedItems}" begin="0" end="${status.index - 1}">
                  <c:if test="${prevItem.itemName eq item.itemName}">
                    <c:set var="alreadyPrinted" value="true" />
                  </c:if>
                </c:forEach>
              </c:if>
              <c:if test="${not alreadyPrinted}">
                <c:set var="itemCount" value="0" />
                <c:forEach var="countItem" items="${appliedItems}">
                  <c:if test="${countItem.itemName eq item.itemName}">
                    <c:set var="itemCount" value="${itemCount + 1}" />
                  </c:if>
                </c:forEach>
                <c:set var="itemIconClass" value="fa-solid fa-gift" />
                <c:set var="itemDesc" value="아이템 설명이 없습니다." />
                <c:choose>
                  <c:when test="${item.itemName eq '보컬 워터'}"><c:set var="itemIconClass" value="fa-solid fa-droplet" /><c:set var="itemDesc" value="보컬 능력치를 +10 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '호흡 컨트롤 북'}"><c:set var="itemIconClass" value="fa-solid fa-microphone" /><c:set var="itemDesc" value="보컬 능력치를 +20 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '댄스 슈즈'}"><c:set var="itemIconClass" value="fa-solid fa-shoe-prints" /><c:set var="itemDesc" value="댄스 능력치를 +10 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '퍼포먼스 밴드'}"><c:set var="itemIconClass" value="fa-solid fa-star" /><c:set var="itemDesc" value="댄스 능력치를 +20 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '팬레터'}"><c:set var="itemIconClass" value="fa-solid fa-envelope" /><c:set var="itemDesc" value="스타성을 +10 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '라이브 방송 세트'}"><c:set var="itemIconClass" value="fa-solid fa-tower-broadcast" /><c:set var="itemDesc" value="스타성을 +20 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '릴렉스 캔디'}"><c:set var="itemIconClass" value="fa-solid fa-candy-cane" /><c:set var="itemDesc" value="멘탈 능력치를 +10 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '명상 키트'}"><c:set var="itemIconClass" value="fa-solid fa-spa" /><c:set var="itemDesc" value="멘탈 능력치를 +20 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '팀 스낵 박스'}"><c:set var="itemIconClass" value="fa-solid fa-box-open" /><c:set var="itemDesc" value="팀워크 능력치를 +10 올려주는 아이템입니다." /></c:when>
                  <c:when test="${item.itemName eq '유닛 워크북'}"><c:set var="itemIconClass" value="fa-solid fa-heart" /><c:set var="itemDesc" value="팀워크 능력치를 +20 올려주는 아이템입니다." /></c:when>
                </c:choose>
                <div class="game-hud-applied-item" data-item-name="${fn:escapeXml(item.itemName)}" data-item-desc="${fn:escapeXml(itemDesc)}">
                  <span class="game-hud-applied-item-icon"><i class="${itemIconClass}"></i></span>
                  <span class="game-hud-applied-item-name">${item.itemName}</span>
                  <c:if test="${itemCount > 1}"><span class="game-hud-applied-item-count">x${itemCount}</span></c:if>
                  <span class="game-hud-applied-tooltip"><strong>${item.itemName}</strong>${itemDesc}</span>
                </div>
              </c:if>
            </c:forEach>
          </c:when>
          <c:otherwise><span class="game-hud-applied-empty">적용된 아이템 없음</span></c:otherwise>
        </c:choose>
      </div>
    </div>
  </div>

  <div class="game-hud-center-fans" title="총 팬 수 (탭하면 상세)" role="button" tabindex="0" onclick="openFanDetailModal()" aria-label="총 팬 수">
    <span class="game-hud-center-fans__main">
      <i class="fas fa-heart" aria-hidden="true"></i>
      <span id="fansHudValue"><c:out value="${totalFans != null ? totalFans : 0}"/></span>
    </span>
    <span class="fans-delta-pop" id="fansHudDelta" aria-hidden="true"></span>
  </div>

  <c:if test="${not empty sessionScope.LOGIN_MEMBER}">
  <div class="game-hud-tools game-floating-chat-tray" role="group" aria-label="AI 챗봇 및 실시간 채팅방">
    <button type="button" id="chat-toggle-btn" class="game-hud-tool-btn" onclick="toggleChatWidget()" title="AI 챗봇" aria-label="AI 챗봇"><i class="fas fa-robot"></i></button>
    <button type="button" id="chatroom-toggle-btn" class="game-hud-tool-btn" onclick="toggleChatroomWidget()" title="실시간 채팅방" aria-label="실시간 채팅방"><i class="fas fa-message"></i></button>
  </div>
  </c:if>
</div>

<div class="game-fs-event" id="gameFullscreenEvent" aria-hidden="true" role="dialog" aria-modal="true" aria-labelledby="gameFsEventTitle">
  <div class="game-fs-event__panel" onclick="event.stopPropagation()">
    <div class="game-fs-event__burst" id="gameFsEventBurst">SURPRISE EVENT</div>
    <h2 class="game-fs-event__title" id="gameFsEventTitle">프로듀서, 잠깐만요!</h2>
    <p class="game-fs-event__body" id="gameFsEventBody">연습실에서 예상치 못한 일이 벌어졌습니다. 어떻게 대응할까요?</p>
    <div class="game-fs-event__choices" id="gameFsEventChoices"></div>
    <button type="button" class="game-fs-event__close" id="gameFsEventDismiss">나중에 하기</button>
  </div>
</div>

<div class="fan-detail-modal" id="fanDetailModal" onclick="closeFanDetailModal(event)">
  <div class="fan-detail-card" onclick="event.stopPropagation()">
    <div class="fan-detail-head">
      <div>
        <div class="fan-detail-eyebrow">FAN BREAKDOWN</div>
        <div class="fan-detail-title">현재 팬 분포</div>
      </div>
      <button type="button" class="fan-detail-close" onclick="closeFanDetailModal()"><i class="fas fa-xmark"></i></button>
    </div>
    <div class="fan-detail-total">
      <span>TOTAL</span>
      <strong id="fanDetailTotal"><c:out value="${totalFans != null ? totalFans : 0}"/></strong>
    </div>
    <p class="fan-detail-hint">국내·외국 카드를 누르면 지역·도시 분포 그래프가 펼쳐집니다.</p>
    <div class="fan-detail-split" role="group" aria-label="국내외 팬">
      <button type="button" class="fan-kpi fan-kpi--domestic fan-kpi--toggle" id="fanDetailBtnDomestic"
        aria-expanded="false" aria-controls="fanDetailPanelDomestic" data-btn-bounce="true">
        <span>국내팬</span>
        <strong id="fanDetailDomestic">—</strong>
        <em>한국 거주·국내 유입 팬</em>
      </button>
      <button type="button" class="fan-kpi fan-kpi--foreign fan-kpi--toggle" id="fanDetailBtnForeign"
        aria-expanded="false" aria-controls="fanDetailPanelForeign" data-btn-bounce="true">
        <span>외국팬</span>
        <strong id="fanDetailForeign">—</strong>
        <em>해외 권역별 팬</em>
      </button>
    </div>
    <div class="fan-detail-panel" id="fanDetailPanelDomestic" role="region" aria-label="국내 시·도 분포" hidden>
      <div class="fan-detail-panel__head">국내 · 시·도 분포</div>
      <div class="fan-bar-chart" id="fanDetailChartDomestic"></div>
    </div>
    <div class="fan-detail-panel" id="fanDetailPanelForeign" role="region" aria-label="해외 권역 분포" hidden>
      <div class="fan-detail-panel__head">해외 · 권역 분포</div>
      <div class="fan-bar-chart" id="fanDetailChartForeign"></div>
    </div>
  </div>
</div>

<%-- BIG PEAK 오버레이 & COMBO 배너 --%>
<div class="peak-ov" id="peakOv">
  <div class="peak-inner">
    <div class="peak-label" id="peakLabel">STAT UP!</div>
    <div class="peak-detail" id="peakDetail">+10 VOCAL</div>
  </div>
</div>
<div class="combo-banner" id="comboBanner">2 COMBO!</div>

<%-- 결과 오버레이 --%>
<div class="rov" id="rov" tabindex="-1">
  <div class="rcard">
    <div class="rav" id="res-av"><div class="rav-ph"><i class="fas fa-user"></i></div></div>
    <div class="rname" id="res-name">연습생</div>
    <div class="rdetail">
      <div class="rbox">
        <div class="rbox-lbl">SELECTED ACTION</div>
        <div class="rbox-copy" id="res-action">선택한 액션</div>
      </div>
      <div class="rbox">
        <div class="rbox-lbl" style="letter-spacing:.2em;">[결과]</div>
        <div class="rbox-copy sub" id="res-result-narration">유저 선택 이후 연습실에서 벌어진 일이 여기에 표시됩니다.</div>
      </div>
      <div class="rbox rbox--minigame" id="res-minigame-box" style="display:none;">
        <div class="rbox-lbl" style="color:#a78bfa;letter-spacing:.18em;">🎮 MINI GAME</div>
        <div class="rbox-copy" id="res-minigame-title">미니게임</div>
        <div class="rbox-copy sub" id="res-minigame-desc"></div>
      </div>
      <div class="rbox" id="res-event-triggered-box">
        <div class="rbox-lbl" style="color:#fbbf24;letter-spacing:.24em;">🔥 EVENT TRIGGERED</div>
        <div class="rbox-copy" id="res-event-title">추가 이벤트가 발생했습니다</div>
        <div class="rbox-copy sub" id="res-event-desc">선택의 여파가 팀 전체에 반영됩니다.</div>
      </div>
    </div>
    <div class="rstat-box" id="res-primary-stat-box">
      <div class="rstat-lbl">STAT CHANGE</div>
      <div class="rstat-name" id="res-sname">보컬</div>
      <div class="rstat-change">
        <span class="rbefore" id="res-bef">0</span>
        <span class="rarrow">→</span>
        <span class="rafter" id="res-aft">0</span>
      </div>
      <span class="rdelta" id="res-delta">+0</span>
    </div>
    <div class="rstat-box rstat-box--penalty" id="res-penalty-stat-box" style="display:none;">
      <div class="rstat-lbl">STAT CHANGE · 미니게임 페널티</div>
      <div class="rstat-name" id="res-penalty-sname">보컬</div>
      <div class="rstat-who" id="res-penalty-who"></div>
      <div class="rstat-change">
        <span class="rbefore" id="res-penalty-bef">0</span>
        <span class="rarrow">→</span>
        <span class="rafter" id="res-penalty-aft">0</span>
      </div>
      <span class="rdelta dn" id="res-penalty-delta">▼ 1 보컬</span>
    </div>
    <div class="rfan-box">
      <div class="rstat-lbl">FAN REACTION</div>
      <div class="rfan-title" id="res-fan-title">팬 반응</div>
      <div class="rfan-desc" id="res-fan-desc">팬 반응 설명</div>
      <div class="rfan-breakdown" id="res-fan-breakdown">국내 +0 · 해외 +0</div>
      <div class="rfan-total-wrap"><span class="rfan-total" id="res-fan-total">팬 +0</span></div>
      <div class="rfan-event" id="res-fan-event" style="display:none"></div>
    </div>
    <div class="rstatus-box" id="res-status-box">
      <div class="rstat-lbl">STATUS EFFECT</div>
      <div><span class="rstatus-chip" id="res-status-chip">상태 없음</span></div>
      <div class="rstatus-desc" id="res-status-desc"></div>
      <div class="rstatus-meta" id="res-status-meta"></div>
    </div>
    <div class="rnext-row">
      <div class="rnext-badge" id="res-next">NEXT: —</div>
      <button class="rnext-btn" data-btn-bounce="true" onclick="goNext()">다음으로 <i class="fas fa-chevron-right"></i></button>
    </div>
  </div>
</div>

<%-- 메인 레이아웃 --%>
<div class="gs-wrap" id="gsWrap">

  <%-- LEFT PANEL --%>
  <div class="panel-l">
    <div class="panel-l-inner">
      <p class="panel-title">✦ SELECTED MEMBERS ✦</p>
      <c:forEach var="m" items="${result.roster}">
      <c:set var="stripItemBonus" value="${not empty eliminatedTraineeIds && eliminatedTraineeIds.contains(m.traineeId)}" />
      <c:set var="pcGlowClass" value=""/>
      <c:set var="pcGradeNorm" value="${fn:toUpperCase(fn:trim(m.photoCardGrade))}" />
      <c:if test="${pcGradeNorm == 'R' || pcGradeNorm == 'SR' || pcGradeNorm == 'SSR'}">
        <c:set var="pcGlowClass" value="card-glow-${fn:toLowerCase(pcGradeNorm)}"/>
      </c:if>
      <c:set var="enhanceBonus" value="0"/>
      <c:choose>
        <c:when test="${m.enhanceLevel >= 5}"><c:set var="enhanceBonus" value="7"/></c:when>
        <c:when test="${m.enhanceLevel == 4}"><c:set var="enhanceBonus" value="4"/></c:when>
        <c:when test="${m.enhanceLevel == 3}"><c:set var="enhanceBonus" value="3"/></c:when>
        <c:when test="${m.enhanceLevel == 2}"><c:set var="enhanceBonus" value="2"/></c:when>
        <c:when test="${m.enhanceLevel == 1}"><c:set var="enhanceBonus" value="1"/></c:when>
      </c:choose>
      <c:set var="mTotalSum" value="${m.vocal + m.dance + m.star + m.mental + m.teamwork}" />
      <c:set var="mTotalDisplay" value="${mTotalSum}" />
      <div class="mcard mcard--${m.gender == 'MALE' ? 'm' : 'f'} ${pcGlowClass}" data-tid="${m.traineeId}" data-personality-code="<c:out value='${m.personalityCode}' />">
        <div class="cpho">
          <c:choose>
            <c:when test="${not empty m.imagePath}">
              <img src="${ctx}${m.imagePath}" alt="${m.name}" onerror="this.parentNode.innerHTML='<div class=\'cpho-ph\'><i class=\'fas fa-user\'></i></div>'"/>
            </c:when>
            <c:otherwise><div class="cpho-ph"><i class="fas fa-user"></i></div></c:otherwise>
          </c:choose>
          <span class="cpick">${m.pickOrder}</span>
        </div>
        <div class="cinfo">
          <div class="mcard-stat-strip" data-mcard-stat-strip aria-live="polite"></div>
          <div class="ctop">
            <div class="cname-wrap">
              <div class="cname">${m.name}</div>
              <span class="enhance-badge enhance-badge--lv-${m.enhanceLevel}">${m.enhanceLevel >= 5 ? 'MAX' : '+'.concat(m.enhanceLevel)}</span>
            </div>
            <div class="ctotal">
              <div class="ctotal-num" data-total-sum="${mTotalSum}">${mTotalDisplay}</div>
              <div class="ctotal-lbl">TOTAL</div>
            </div>
          </div>
          <div class="cbadges">
            <c:choose>
              <c:when test="${m.gender == 'MALE'}"><span class="badge badge--m"><i class="fas fa-mars" style="font-size:9px;"></i> 남자</span></c:when>
              <c:otherwise><span class="badge badge--f"><i class="fas fa-venus" style="font-size:9px;"></i> 여자</span></c:otherwise>
            </c:choose>
            <span class="role-badge" data-role-holder="true">ROLE</span>
            <div class="member-status-inline" data-status-inline="true">
              <c:if test="${not empty m.statusLabel}">
                <button type="button"
                        class="member-status-trigger is-active"
                        data-status-trigger="true"
                        data-tid="${m.traineeId}"
                        data-status-count="1"
                        onclick="toggleMemberStatusPopover(event, '${m.traineeId}')"
                        aria-expanded="false"
                        aria-label="${fn:escapeXml(m.name)} 상태 효과 보기">
                  +1
                </button>
                <div class="member-status-popover"
                     data-status-popover="true"
                     data-tid="${m.traineeId}"
                     hidden>
                  <div class="member-status-popover__head">
                    <strong>상태 효과</strong>
                    <button type="button" class="member-status-popover__close" onclick="closeMemberStatusPopover('${m.traineeId}')">
                      <i class="fas fa-xmark"></i>
                    </button>
                  </div>
                  <div class="member-status-popover__body">
                    <div class="member-status-popover__item ${m.statusCode == 'INJURY' || m.statusCode == 'BURNOUT' || m.statusCode == 'SLUMP' ? 'is-debuff' : 'is-buff'}">
                      <div class="member-status-popover__label">${m.statusLabel}</div>
                      <c:if test="${not empty m.statusDesc}"><div class="member-status-popover__desc">${m.statusDesc}</div></c:if>
                      <div class="member-status-popover__meta">${m.statusTurnsLeft}턴 남음</div>
                    </div>
                  </div>
                </div>
              </c:if>
            </div>
          </div>
          <div class="cstats">
            <div class="srow${not stripItemBonus && itemStatBonusMap['v'] > 0 ? ' item-on item-on--v' : ''}${not stripItemBonus && fn:contains(latestActiveItemStatKeysCsv, 'v') and itemGlowEnabled ? ' item-recent item-on item-on--v' : ''}" data-stat="v"><span class="slbl">보컬<c:if test="${not stripItemBonus && itemStatBonusMap['v'] > 0}"><span class="item-daily-badge">+${itemStatBonusMap['v']}</span></c:if></span><div class="strk"><div class="sfill sfill--v" data-w="${m.vocal}"></div></div><span class="sval" data-key="v" data-raw="${m.vocal}" data-eb="${enhanceBonus}">${m.vocal}</span></div>
            <div class="srow${not stripItemBonus && itemStatBonusMap['d'] > 0 ? ' item-on item-on--d' : ''}${not stripItemBonus && fn:contains(latestActiveItemStatKeysCsv, 'd') and itemGlowEnabled ? ' item-recent item-on item-on--d' : ''}" data-stat="d"><span class="slbl">댄스<c:if test="${not stripItemBonus && itemStatBonusMap['d'] > 0}"><span class="item-daily-badge">+${itemStatBonusMap['d']}</span></c:if></span><div class="strk"><div class="sfill sfill--d" data-w="${m.dance}"></div></div><span class="sval" data-key="d" data-raw="${m.dance}" data-eb="${enhanceBonus}">${m.dance}</span></div>
            <div class="srow${not stripItemBonus && itemStatBonusMap['s'] > 0 ? ' item-on item-on--s' : ''}${not stripItemBonus && fn:contains(latestActiveItemStatKeysCsv, 's') and itemGlowEnabled ? ' item-recent item-on item-on--s' : ''}" data-stat="s"><span class="slbl">스타<c:if test="${not stripItemBonus && itemStatBonusMap['s'] > 0}"><span class="item-daily-badge">+${itemStatBonusMap['s']}</span></c:if></span><div class="strk"><div class="sfill sfill--s" data-w="${m.star}"></div></div><span class="sval" data-key="s" data-raw="${m.star}" data-eb="${enhanceBonus}">${m.star}</span></div>
            <div class="srow${not stripItemBonus && itemStatBonusMap['m'] > 0 ? ' item-on item-on--m' : ''}${not stripItemBonus && fn:contains(latestActiveItemStatKeysCsv, 'm') and itemGlowEnabled ? ' item-recent item-on item-on--m' : ''}" data-stat="m"><span class="slbl">멘탈<c:if test="${not stripItemBonus && itemStatBonusMap['m'] > 0}"><span class="item-daily-badge">+${itemStatBonusMap['m']}</span></c:if></span><div class="strk"><div class="sfill sfill--m" data-w="${m.mental}"></div></div><span class="sval" data-key="m" data-raw="${m.mental}" data-eb="${enhanceBonus}">${m.mental}</span></div>
            <div class="srow${not stripItemBonus && itemStatBonusMap['t'] > 0 ? ' item-on item-on--t' : ''}${not stripItemBonus && fn:contains(latestActiveItemStatKeysCsv, 't') and itemGlowEnabled ? ' item-recent item-on item-on--t' : ''}" data-stat="t"><span class="slbl">팀웍<c:if test="${not stripItemBonus && itemStatBonusMap['t'] > 0}"><span class="item-daily-badge">+${itemStatBonusMap['t']}</span></c:if></span><div class="strk"><div class="sfill sfill--t" data-w="${m.teamwork}"></div></div><span class="sval" data-key="t" data-raw="${m.teamwork}" data-eb="${enhanceBonus}">${m.teamwork}</span></div>

          </div>
        </div>
      </div>
      </c:forEach>
    </div>
  </div>

  <div class="divider"></div>

  <%-- RIGHT PANEL --%>
  <div class="panel-r">


    <%-- SCENE AREA --%>
    <div class="scene-area">
      <canvas id="sceneCanvas"></canvas>
      <div class="scene-bg"></div>
      <div class="scene-orb scene-orb--1"></div>
      <div class="scene-orb scene-orb--2"></div>
      <div class="scene-orb scene-orb--3"></div>
      <div class="scene-scan"></div>

      <%-- CHEMISTRY/GOAL: 채팅 도크 아이콘에서 모달로 표시 --%>
      <div class="chem-side-actions" aria-hidden="true" style="display:none">
        <button type="button" class="chem-fab" id="chemFab" onclick="openChemModal()">
          <span class="chem-fab__icon"><i class="fas fa-sparkles"></i></span>
          <span class="chem-fab__meta">
            <span class="chem-fab__label">CHEMISTRY</span>
            <span class="chem-fab__value">
              <span class="chem-fab__grade" id="chemFabGrade">${chemistry.chemGrade}</span>
              <span class="chem-fab__name" id="chemFabName">${chemistry.chemLabel}</span>
            </span>
          </span>
          <span class="chem-fab__arrow"><i class="fas fa-chevron-up"></i></span>
        </button>
      </div>

      <div class="scene-grid">
        <div class="scene-main">
          <div class="game-mode-stack">
          <div class="game-ui-surface game-ui-surface--app" id="gameUiSurfaceApp" aria-hidden="false">
          <%-- 채팅: NPC 대사 + 유저 입력 --%>
          <div class="game-chat-panel" id="gameChatPanel">
            <%-- 채팅 상단: 현재 일차 + SAVE (동일 정보) --%>
            <div class="game-chat-dock" aria-label="현재 일차 및 저장">
              <div class="game-chat-dock__row">
                <div class="game-chat-dock__meta">
                  <span class="game-chat-dock__date" id="gameChatDockDate" data-is-debut="${isDebutEval ? '1' : '0'}">
                    <c:choose>
                      <c:when test="${isDebutEval}">${scheduleDatePretty} · 최종 데뷔 평가 🔥 ${scheduleTimeLabel}</c:when>
                      <c:otherwise>${scheduleDatePretty} · ${weekDayName} ${scheduleTimeLabel}</c:otherwise>
                    </c:choose>
                  </span>
                  <span class="game-chat-dock__badge">DAY ${planDayReverse}</span>
                  <span class="game-chat-dock__badge game-chat-dock__badge--rank">내 랭킹 ${myLiveRank}위</span>
                  <c:if test="${not empty sessionScope.LOGIN_MEMBER and not empty memberRankLabel}">
                  <span class="game-chat-dock__badge game-chat-dock__badge--exp" title="계정 누적 등급 경험치 · ${memberRankLabel}">
                    EXP <strong>${memberRankExp}</strong>
                  </span>
                  </c:if>
                  <div class="game-chat-dock__actions day-save-actions">
                    <button type="button" class="game-chat-dock__iconbtn" onclick="openGoalModal()" title="목표 보기" aria-label="목표 보기">
                      목표보기
                    </button>
                    <button type="button" class="game-chat-dock__iconbtn" onclick="openChemModal()" title="케미스트리 보기" aria-label="케미스트리 보기">
                      케미스트리보기
                    </button>
                    <button type="button" class="save-btn save-btn--dock-secondary save-btn--schedule"
                      onclick="openScheduleModal('${ctx}/game/run/${result.runId}/replay'); return false;"
                      title="스케줄" aria-label="스케줄 열기" data-btn-bounce="true">
                      <i class="fas fa-calendar-alt"></i><span>스케줄</span>
                    </button>
                    <button type="button" class="save-btn save-btn--dock-secondary save-btn--debut"
                      onclick="startPageTransition('${ctx}/game/run/${result.runId}/ending'); return false;"
                      title="데뷔" aria-label="데뷔 화면으로" data-btn-bounce="true">
                      <i class="fas fa-gem"></i><span>데뷔</span>
                    </button>
                    <button type="button" class="save-btn" id="saveBtnChatDock" onclick="doSave()">
                      <i class="fas fa-floppy-disk"></i><span>SAVE</span>
                    </button>
                    <button type="button" class="game-chat-dock__iconbtn game-chat-dock__iconbtn--settings"
                      id="debugToolsBtn" onclick="openDebugToolsModal()" title="테스트 설정" aria-label="테스트 설정 열기">
                      <i class="fas fa-gear" aria-hidden="true"></i>
                    </button>
                  </div>
                </div>
                <div class="phone-topbar" aria-label="상단 상태 바">
                  <button type="button" class="chat-bg-btn" id="chatBgPickBtn" aria-label="채팅 배경 사진 선택">
                    <i class="fas fa-image"></i>
                  </button>
                  <button type="button" class="chat-bg-clear-btn" id="chatBgClearBtn" aria-label="채팅 배경 제거">
                    <i class="fas fa-xmark"></i>
                  </button>
                  <div class="phone-status" aria-label="휴대폰 상태 표시">
                    <span class="phone-status__time" id="phoneTime">00:00</span>
                    <span class="phone-battery" aria-label="배터리 100%">
                      <span class="phone-battery__pct">100%</span>
                      <span class="phone-battery__icon" aria-hidden="true"><span class="phone-battery__fill"></span></span>
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <input type="file" id="chatBgFileInput" accept="image/*" style="display:none" />
        <div class="game-chat-log" id="gameChatLog">
          <c:choose>
            <c:when test="${not empty scene && not empty introDialogue}">
              <div class="chat-bubble chat-bubble--npc chat-bubble--system" data-scene-intro="1"<c:if test="${scene.sceneId != null}"> data-scene-id="${scene.sceneId}"</c:if>>
                <div class="chat-bubble-label">[상황]</div>
                <div class="chat-bubble-text"><c:out value="${introDialogue.situation}" /></div>
              </div>
              <c:if test="${not empty introDialogue.lines}">
                <div class="chat-section-label">[대사]</div>
              </c:if>
              <c:forEach var="line" items="${introDialogue.lines}">
                <c:if test="${empty eliminatedTraineeIds || !eliminatedTraineeIds.contains(line.traineeId)}">
                <div class="chat-bubble chat-bubble--npc chat-bubble--idol dialogue-stagger" data-trainee-id="${line.traineeId}">
                  <div class="chat-avatar"></div>
                  <div class="chat-bubble-body">
                    <div class="chat-bubble-label"><c:out value="${line.name}" /> · <c:out value="${line.personalityLabel}" /></div>
                    <div class="chat-bubble-text"><c:out value="${line.text}" /></div>
                  </div>
                </div>
                </c:if>
              </c:forEach>
            </c:when>
            <c:when test="${not empty scene}">
              <div class="chat-bubble chat-bubble--npc chat-bubble--system" data-scene-intro="1"<c:if test="${scene.sceneId != null}"> data-scene-id="${scene.sceneId}"</c:if>>
                <div class="chat-bubble-label">[상황]</div>
                <div class="chat-bubble-text"><c:out value="${scene.description}" /></div>
              </div>
            </c:when>
            <c:otherwise>
              <div class="chat-bubble chat-bubble--npc chat-bubble--muted">
                <div class="chat-bubble-text">진행할 이벤트가 없습니다.</div>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
        <div class="game-chat-compose">
          <input type="text" class="game-chat-input" id="gameChatInput" maxlength="240" autocomplete="off"
            placeholder="프로듀서 의견을 입력하세요… (예: 보컬 집중, 좀 쉬자, 팀 호흡, 승부수)"
            <c:if test="${empty scene}">disabled="disabled"</c:if> />
          <button type="button" class="game-chat-send" id="gameChatSend" data-btn-bounce="true" onclick="sendGameChat()"
            <c:if test="${empty scene}">disabled="disabled"</c:if>>
            전송 <i class="fas fa-paper-plane"></i>
          </button>
        </div>
        <div class="ipad-home-indicator" aria-hidden="true"></div>
        </div><%-- end game-chat-panel --%>
        </div><%-- end game-ui-surface app --%>

        <div class="game-ui-surface game-ui-surface--home" id="gameUiSurfaceHome" aria-hidden="true">
          <div class="ipad-home-status">
            <span id="ipadHomeTime">12:00</span>
            <span class="ipad-home-status__right">
              <span>100%</span>
              <span class="phone-battery__icon" aria-hidden="true"><span class="phone-battery__fill"></span></span>
            </span>
          </div>
          <div class="ipad-home-grid ipad-home-grid--apps">
            <button type="button" class="ipad-app" id="ipadGameAppBtn" aria-label="게임 앱 열기">
              <span class="ipad-app__icon"><i class="fas fa-star"></i></span>
              <span class="ipad-app__name">NEXT DEBUT</span>
            </button>
            <button type="button" class="ipad-app" id="ipadMapAppBtn" aria-label="지도 열기">
              <span class="ipad-app__icon"><i class="fas fa-map-location-dot"></i></span>
              <span class="ipad-app__name">MAP</span>
            </button>
          </div>
          <div class="ipad-home-indicator ipad-home-indicator--homescreen" aria-hidden="true"></div>
        </div>

        <div class="game-ui-surface game-ui-surface--map" id="gameUiSurfaceMap" aria-hidden="true">
          <div class="game-map-screen" role="region" aria-label="캠퍼스 맵" id="gameMapScreen">
            <div class="game-map-screen__top">
              <button type="button" class="game-map-screen__back" id="gameMapBackBtn" onclick="setGameUiMode('home')" aria-label="Back to home">
                <i class="fas fa-chevron-left"></i> Back
              </button>
              <span class="game-map-screen__title">CAMPUS MAP</span>
              <span class="game-map-screen__day">DAY ${planDayReverse}</span>
            </div>
            <div class="game-map-board">
              <svg class="game-map-board__routes" viewBox="0 0 300 260" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
                <path d="M 54 52 Q 150 95 150 128" />
                <path d="M 246 52 Q 150 95 150 128" />
                <path d="M 54 208 Q 150 165 150 128" />
                <path d="M 246 208 Q 150 165 150 128" />
                <path d="M 54 52 L 246 52" />
                <path d="M 54 208 L 246 208" />
              </svg>
              <div class="game-map-board__nodes">
                <button type="button" class="game-map-node game-map-node--dorm" data-location="dorm" data-location-label="Dorm" aria-pressed="false">
                  <span class="game-map-node__glyph" aria-hidden="true"><i class="fas fa-bed"></i></span>
                  <span class="game-map-node__label">Dorm</span>
                </button>
                <button type="button" class="game-map-node game-map-node--broadcast" data-location="broadcast_station" data-location-label="Broadcast Station" aria-pressed="false">
                  <span class="game-map-node__glyph" aria-hidden="true"><i class="fas fa-tower-broadcast"></i></span>
                  <span class="game-map-node__label">Broadcast<br/>Station</span>
                </button>
                <button type="button" class="game-map-node game-map-node--practice" data-location="practice_room" data-location-label="Practice Room" aria-pressed="false">
                  <span class="game-map-node__glyph" aria-hidden="true"><i class="fas fa-dumbbell"></i></span>
                  <span class="game-map-node__label">Practice<br/>Room</span>
                </button>
                <button type="button" class="game-map-node game-map-node--cafe" data-location="cafe" data-location-label="Cafe" aria-pressed="false">
                  <span class="game-map-node__glyph" aria-hidden="true"><i class="fas fa-mug-hot"></i></span>
                  <span class="game-map-node__label">Cafe</span>
                </button>
                <button type="button" class="game-map-node game-map-node--stage" data-location="stage" data-location-label="Stage" aria-pressed="false">
                  <span class="game-map-node__glyph" aria-hidden="true"><i class="fas fa-masks-theater"></i></span>
                  <span class="game-map-node__label">Stage</span>
                </button>
              </div>
            </div>
            <p class="game-map-screen__hint" id="gameMapSelectionHint">장소를 탭해 선택하세요.</p>
            <div class="game-map-screen__actions">
              <button type="button" class="game-map-screen__btn--ghost" onclick="setGameUiMode('app')">훈련 앱</button>
              <button type="button" class="game-map-screen__btn--ghost" onclick="openScheduleModal('${ctx}/game/run/${result.runId}/replay');">스케줄</button>
            </div>
          </div>
        </div>
        </div><%-- end game-mode-stack --%>
        </div><%-- end scene-main --%>

        <%-- iPad-style 프리미엄 컨트롤 패널: 채팅 옆에 붙여 배치 --%>
        <aside class="ipad-side-panel" id="ipadSidePanel" aria-label="게임 컨트롤 패널">
          <div class="ipad-side-panel__card status-card status-card--ai-monitor fade-in" id="ndxStatusCard">
            <div class="ipad-side-panel__head ai-cond-panel__head">
              <div>
                <span class="ipad-side-panel__kicker">AI MONITOR</span>
                <strong class="ipad-side-panel__title">컨디션 관리</strong>
              </div>
              <span class="ai-cond-panel__pulse" aria-hidden="true"></span>
            </div>

            <div class="sim-warn-banner" id="ndxSimWarnBanner" aria-hidden="true" role="status">
              <span class="sim-warn-banner__icon" aria-hidden="true"><i class="fas fa-triangle-exclamation"></i></span>
              <span class="sim-warn-banner__text"></span>
            </div>

            <div class="sim-status-log" id="ndxSimStatusLog" aria-label="상태 변화 로그">
              <div class="sim-status-log__head">턴 로그 · 막대가 왜 바뀌었는지</div>
              <div id="ndxSimStatusLogLines"></div>
            </div>

            <div class="status-bar ai-cond-meter" data-key="focus" data-pct="0" data-tone="safe">
              <div class="status-bar__row ai-cond-meter__row">
                <div class="ai-cond-meter__headline">
                  <span class="ai-cond-meter__title"><span class="ai-cond-meter__ko">집중도</span> <span class="ai-cond-meter__en">Focus</span></span>
                  <button type="button" class="ai-cond-meter__help" data-cond-help="focus" aria-label="집중도 쉬운 설명" title="쉬운 설명"><i class="fas fa-circle-question" aria-hidden="true"></i></button>
                </div>
                <strong class="status-bar__val">0%</strong>
                <span class="ai-cond-meter__badge">[—]</span>
              </div>
              <div class="status-bar__track"><span class="status-fill" style="width:0%"></span></div>
              <p class="ai-cond-meter__comment" aria-live="polite"></p>
            </div>
            <div class="status-bar ai-cond-meter" data-key="stress" data-pct="0" data-tone="safe">
              <div class="status-bar__row ai-cond-meter__row">
                <div class="ai-cond-meter__headline">
                  <span class="ai-cond-meter__title"><span class="ai-cond-meter__ko">스트레스</span> <span class="ai-cond-meter__en">Stress</span></span>
                  <button type="button" class="ai-cond-meter__help" data-cond-help="stress" aria-label="스트레스 쉬운 설명" title="쉬운 설명"><i class="fas fa-circle-question" aria-hidden="true"></i></button>
                </div>
                <strong class="status-bar__val">0%</strong>
                <span class="ai-cond-meter__badge">[—]</span>
              </div>
              <div class="status-bar__track"><span class="status-fill" style="width:0%"></span></div>
              <p class="ai-cond-meter__comment" aria-live="polite"></p>
            </div>
            <div class="status-bar ai-cond-meter" data-key="condition" data-pct="72" data-tone="safe">
              <div class="status-bar__row ai-cond-meter__row">
                <div class="ai-cond-meter__headline">
                  <span class="ai-cond-meter__title"><span class="ai-cond-meter__ko">컨디션</span> <span class="ai-cond-meter__en">Condition</span></span>
                  <button type="button" class="ai-cond-meter__help" data-cond-help="condition" aria-label="컨디션 쉬운 설명" title="쉬운 설명"><i class="fas fa-circle-question" aria-hidden="true"></i></button>
                </div>
                <strong class="status-bar__val">72%</strong>
                <span class="ai-cond-meter__badge">[—]</span>
              </div>
              <div class="status-bar__track"><span class="status-fill" style="width:72%"></span></div>
              <p class="ai-cond-meter__comment" aria-live="polite"></p>
            </div>
            <div class="status-bar ai-cond-meter" data-key="team" data-pct="100" data-tone="safe" data-team-warn="30" data-team-instability="20" aria-description="팀 분위기 막대예요. 30% 이하면 나쁜 편, 20% 이하면 스트레스가 더 잘 올라가요. 탈락은 컨디션 막대로만 정해져요.">
              <div class="status-bar__row ai-cond-meter__row">
                <div class="ai-cond-meter__headline">
                  <span class="ai-cond-meter__title"><span class="ai-cond-meter__ko">팀워크</span> <span class="ai-cond-meter__en">Teamwork</span></span>
                  <button type="button" class="ai-cond-meter__help" data-cond-help="team" aria-label="팀워크 쉬운 설명" title="쉬운 설명"><i class="fas fa-circle-question" aria-hidden="true"></i></button>
                </div>
                <strong class="status-bar__val">100%</strong>
                <span class="ai-cond-meter__badge">[—]</span>
              </div>
              <div class="status-bar__track"><span class="status-fill" style="width:100%"></span></div>
              <p class="ai-cond-meter__comment" aria-live="polite"></p>
            </div>
            <div class="status-bar ai-cond-meter" data-key="progress" data-pct="${monthProgressPct}" data-tone="safe">
              <div class="status-bar__row ai-cond-meter__row">
                <span class="ai-cond-meter__title"><span class="ai-cond-meter__ko">진행도</span> <span class="ai-cond-meter__en">Progress</span></span>
                <strong class="status-bar__val">${monthProgressPct}%</strong>
                <span class="ai-cond-meter__badge">[—]</span>
              </div>
              <div class="status-bar__track"><span class="status-fill" style="width:${monthProgressPct}%"></span></div>
              <p class="ai-cond-meter__comment" aria-live="polite"></p>
            </div>

            <div class="ai-cond-squad-wrap">
              <div class="ai-cond-squad__label">남은 멤버</div>
              <div class="ai-cond-squad" id="ndxCondSquad" data-empty="1"></div>
            </div>

            <div class="ai-cond-summary" id="ndxAiSummary">
              <div class="ai-cond-summary__head"><i class="fas fa-robot" aria-hidden="true"></i> 지금 뭐 하면 좋을까요</div>
              <div class="ai-cond-summary__text" id="ndxAiSummaryText"></div>
            </div>
          </div>
        </aside>
      </div>
    </div>

  </div><%-- end panel-r --%>
</div><%-- end gs-wrap --%>

<div class="ndx-cond-help-modal" id="ndxCondHelpModal" aria-hidden="true" role="dialog" aria-modal="true" aria-labelledby="ndxCondHelpTitle">
  <div class="ndx-cond-help-modal__dim" data-ndx-cond-help-close></div>
  <div class="ndx-cond-help-modal__panel">
    <button type="button" class="ndx-cond-help-modal__close" data-ndx-cond-help-close aria-label="닫기">&times;</button>
    <div class="ndx-cond-help-modal__eyebrow">초보자 가이드</div>
    <h2 class="ndx-cond-help-modal__title" id="ndxCondHelpTitle"></h2>
    <div class="ndx-cond-help-modal__body" id="ndxCondHelpBody"></div>
  </div>
</div>

<div class="gs-schedule-modal" id="scheduleModal" aria-hidden="true" role="presentation">
  <div class="gs-schedule-modal__dim" data-close-schedule-modal></div>
  <div class="gs-schedule-modal__panel" role="dialog" aria-modal="true" aria-labelledby="scheduleModalTitle">
    <button type="button" class="gs-schedule-modal__close" id="scheduleModalClose" aria-label="닫기">&times;</button>
    <div class="gs-schedule-modal__head">
      <div class="gs-schedule-modal__eyebrow">SCHEDULE</div>
      <h2 class="gs-schedule-modal__title" id="scheduleModalTitle">스케줄</h2>
    </div>
    <iframe id="scheduleModalFrame" class="gs-schedule-modal__frame" src="about:blank" title="스케줄 내용"></iframe>
  </div>
</div>
<div class="gs-debug-modal" id="debugToolsModal" aria-hidden="true" role="presentation">
  <div class="gs-debug-modal__dim" data-close-debug-tools></div>
  <div class="gs-debug-modal__panel" role="dialog" aria-modal="true" aria-labelledby="debugToolsModalTitle">
    <button type="button" class="gs-debug-modal__close" id="debugToolsModalClose" aria-label="닫기">&times;</button>
    <div class="gs-debug-modal__head">
      <div class="gs-debug-modal__eyebrow">TEST SETTINGS</div>
      <h2 class="gs-debug-modal__title" id="debugToolsModalTitle">시연용 즉시 실행</h2>
      <p class="gs-debug-modal__desc">아래 버튼으로 게임오버/탈락 상황을 바로 재현합니다.</p>
    </div>
    <div class="gs-debug-modal__actions">
      <button type="button" class="save-btn gs-debug-modal__action gs-debug-modal__action--danger" id="debugStressMaxBtn"
        title="스트레스를 100%로 만들어 즉시 게임오버를 재현합니다." aria-label="스트레스 100으로 게임오버">
        <i class="fas fa-heart-crack" aria-hidden="true"></i><span>스트레스 100% (게임오버)</span>
      </button>
      <button type="button" class="save-btn gs-debug-modal__action gs-debug-modal__action--warn" id="debugConditionDropBtn"
        title="컨디션을 19% 이하로 만들어 멤버 자동 탈락을 재현합니다." aria-label="컨디션 19로 멤버 탈락">
        <i class="fas fa-user-minus" aria-hidden="true"></i><span>컨디션 19% (자동 탈락)</span>
      </button>
      <button type="button" class="save-btn save-btn--stat2x gs-debug-modal__action" id="statGrowth2xBtn"
        title="테스트: 턴당 능력치·진행도 표시 2배 (클릭으로 ON/OFF)" aria-label="테스트 2배 모드 꺼짐" aria-pressed="false">
        <i class="fas fa-forward-fast" aria-hidden="true"></i><span class="stat2x-btn__txt">2배 모드</span>
        <span class="stat2x-btn__badge stat2x-btn__badge--off" id="statGrowth2xBadge">OFF</span>
      </button>
    </div>
  </div>
</div>
<div class="ndx-game-over" id="ndxGameOverOverlay" aria-hidden="true" role="alertdialog" aria-labelledby="ndxGameOverTitle">
  <div class="ndx-game-over__panel">
    <div class="ndx-game-over__badge">GAME LOST</div>
    <div class="ndx-game-over__countdown" id="ndxGameOverCountdown" aria-live="polite">SYSTEM SHUTDOWN IN 3</div>
    <h2 class="ndx-game-over__title" id="ndxGameOverTitle">스트레스 100% — 패배</h2>
    <p class="ndx-game-over__body">무대 직전 팀이 완전히 흔들렸습니다. 바로 결과를 넘기지 않고, 다음 행동을 선택해 흐름을 이어갈 수 있습니다.</p>
    <div class="ndx-game-over__actions">
      <a class="ndx-game-over__btn ndx-game-over__btn--primary is-disabled" id="ndxGameOverRosterBtn" href="${ctx}/game/run/${result.runId}/roster" aria-disabled="true">팀 관리로 이동</a>
      <a class="ndx-game-over__btn ndx-game-over__btn--ghost is-disabled" id="ndxGameOverEndingBtn" href="${ctx}/game/run/${result.runId}/ending" aria-disabled="true">결과 화면 보기</a>
    </div>
  </div>
</div>

</div><%-- end game-body --%>

<div class="inventory-manage-modal" id="inventoryManageModal" aria-hidden="true" role="presentation">
  <div class="inventory-manage-modal__dim" data-inventory-close></div>
  <div class="inventory-manage-modal__panel" role="dialog" aria-modal="true" aria-labelledby="inventoryManageModalTitle">
    <button type="button" class="inventory-manage-modal__close" id="inventoryManageModalClose" aria-label="닫기">&times;</button>
    <div class="inventory-manage-modal__head">
      <div>
        <div class="inventory-manage-modal__eyebrow">ITEM MANAGE</div>
        <h2 class="inventory-manage-modal__title" id="inventoryManageModalTitle">인벤토리</h2>
      </div>
      <div class="inventory-manage-modal__coin">COIN <strong id="gameInventoryCoinText"><c:out value="${currentCoin != null ? currentCoin : 0}"/></strong></div>
    </div>
    <div class="inventory-manage-modal__tabs" role="tablist" aria-label="아이템 탭">
      <button type="button" class="inventory-manage-modal__tab is-active" data-inventory-tab="owned" aria-selected="true">내 아이템</button>
      <button type="button" class="inventory-manage-modal__tab" data-inventory-tab="shop" aria-selected="false">구매</button>
    </div>

    <div class="inventory-manage-modal__body">
      <section class="inventory-manage-modal__panel-view is-active" data-inventory-panel="owned">
        <div class="inventory-manage-modal__applybar">
          <div class="inventory-manage-modal__selected-inline" id="inventorySelectedInline">선택된 아이템 없음</div>
          <button type="button" class="inventory-manage-modal__apply-btn" id="applySelectedItemsBtn">선택 아이템 적용</button>
        </div>
        <div class="inventory-manage-modal__owned-layout">
          <div class="inventory-picked-panel">
            <div class="inventory-picked-panel__title">선택한 아이템</div>
            <div class="inventory-picked-panel__list" id="inventoryPickedList">
              <div class="inventory-empty inventory-empty--compact">선택된 아이템이 없습니다.</div>
            </div>
          </div>
          <div class="inventory-manage-modal__list inventory-manage-modal__list--selectable" role="list" aria-label="보유 아이템 목록" id="inventoryOwnedSelectableList">
            <c:choose>
              <c:when test="${not empty myItems}">
                <c:forEach var="it" items="${myItems}">
                  <div class="inventory-item inventory-item--modal inventory-item--pickable" role="listitem" data-item-id="${it.id}" data-item-name="${fn:escapeXml(it.itemName)}" data-item-effect="${fn:escapeXml(it.itemEffect)}" data-item-image="${ctx}${it.imagePath}">
                    <button type="button" class="inventory-item__rowbtn" aria-pressed="false">
                      <span class="inventory-item__check"></span>
                      <img class="inventory-item__thumb" src="${ctx}${it.imagePath}" alt="${it.itemName}" />
                      <div class="inventory-item__meta">
                        <div class="inventory-item__name"><c:out value="${it.itemName}" /></div>
                        <div class="inventory-item__effect"><c:out value="${it.itemEffect}" /></div>
                      </div>
                      <div class="inventory-item__qty">x<c:out value="${it.quantity}" /></div>
                    </button>
                  </div>
                </c:forEach>
              </c:when>
              <c:otherwise>
                <div class="inventory-empty">보유한 아이템이 없습니다.</div>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </section>

      <section class="inventory-manage-modal__panel-view" data-inventory-panel="shop">
        <div class="inventory-shop-grid">
          <button type="button" class="inventory-shop-item" data-buy-item-name="보컬 워터" data-buy-item-price="180">
            <img src="${ctx}/images/items/water.png" alt="보컬 워터">
            <div class="inventory-shop-item__meta"><strong>보컬 워터</strong><span>보컬 +10</span></div><em>180 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="호흡 컨트롤 북" data-buy-item-price="320">
            <img src="${ctx}/images/items/breathe%20control.jpg" alt="호흡 컨트롤 북">
            <div class="inventory-shop-item__meta"><strong>호흡 컨트롤 북</strong><span>보컬 +20</span></div><em>320 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="댄스 슈즈" data-buy-item-price="180">
            <img src="${ctx}/images/items/shoes.png" alt="댄스 슈즈">
            <div class="inventory-shop-item__meta"><strong>댄스 슈즈</strong><span>댄스 +10</span></div><em>180 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="퍼포먼스 밴드" data-buy-item-price="320">
            <img src="${ctx}/images/items/band.png" alt="퍼포먼스 밴드">
            <div class="inventory-shop-item__meta"><strong>퍼포먼스 밴드</strong><span>댄스 +20</span></div><em>320 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="팬레터" data-buy-item-price="180">
            <img src="${ctx}/images/items/letter.png" alt="팬레터">
            <div class="inventory-shop-item__meta"><strong>팬레터</strong><span>스타성 +10</span></div><em>180 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="라이브 방송 세트" data-buy-item-price="320">
            <img src="${ctx}/images/items/live.png" alt="라이브 방송 세트">
            <div class="inventory-shop-item__meta"><strong>라이브 방송 세트</strong><span>스타성 +20</span></div><em>320 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="릴렉스 캔디" data-buy-item-price="180">
            <img src="${ctx}/images/items/candy.png" alt="릴렉스 캔디">
            <div class="inventory-shop-item__meta"><strong>릴렉스 캔디</strong><span>멘탈 +10</span></div><em>180 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="명상 키트" data-buy-item-price="320">
            <img src="${ctx}/images/items/meditation.png" alt="명상 키트">
            <div class="inventory-shop-item__meta"><strong>명상 키트</strong><span>멘탈 +20</span></div><em>320 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="팀 스낵 박스" data-buy-item-price="180">
            <img src="${ctx}/images/items/snack-box.png" alt="팀 스낵 박스">
            <div class="inventory-shop-item__meta"><strong>팀 스낵 박스</strong><span>팀워크 +10</span></div><em>180 COIN</em>
          </button>
          <button type="button" class="inventory-shop-item" data-buy-item-name="유닛 워크북" data-buy-item-price="320">
            <img src="${ctx}/images/items/workbook.png" alt="유닛 워크북">
            <div class="inventory-shop-item__meta"><strong>유닛 워크북</strong><span>팀워크 +20</span></div><em>320 COIN</em>
          </button>
        </div>
      </section>
    </div>
  </div>
</div>

<script>
window.NDX_GAME_CONFIG = {
  runId: '${result.runId}',
  ctx: '${ctx}',
  monthNum: ${monthNum},
  totalFans: ${totalFans != null ? totalFans : 0},
  coreFans: ${coreFans != null ? coreFans : 0},
  casualFans: ${casualFans != null ? casualFans : 0},
  lightFans: ${lightFans != null ? lightFans : 0},
  dayNum: ${weekNum},
  teamTotalStat: ${teamTotal},
  myLiveRank: ${myLiveRank != null ? myLiveRank : 999},
  monthProgressPct: ${monthProgressPct},
  phase: '${result.phase}',
  maxAppliedItemCount: 6,
  chemistry: {
    chemGrade: '${chemistry.chemGrade}',
    chemLabel: '${chemistry.chemLabel}',
    baseBonus: ${chemistry.baseBonus},
    gradeBonus: ${chemistry.gradeBonus},
    totalBonus: ${chemistry.totalBonus},
    synergies: [
      <c:forEach var="syn" items="${chemistry.synergies}" varStatus="st">
      {name:'${syn.name}',description:'${syn.description}',icon:'${syn.icon}',bonusPct:${syn.bonusPct},involvedMembers:[<c:forEach var="member" items="${syn.involvedMembers}" varStatus="memberSt">'${member}'<c:if test="${!memberSt.last}">,</c:if></c:forEach>]}<c:if test="${!st.last}">,</c:if>
      </c:forEach>
    ]
  },
  rosterImgMap: {
    <c:forEach var="m" items="${result.roster}" varStatus="st">'${m.traineeId}':'${m.imagePath}'<c:if test="${!st.last}">,</c:if></c:forEach>
  },
  rosterStats: [
    <c:forEach var="m" items="${result.roster}" varStatus="st">{traineeId:'${m.traineeId}', vocal:${m.vocal}, dance:${m.dance}, star:${m.star}, mental:${m.mental}, teamwork:${m.teamwork}, statusCode:'${fn:escapeXml(m.statusCode)}', statusLabel:'${fn:escapeXml(m.statusLabel)}', statusDesc:'${fn:escapeXml(m.statusDesc)}', statusTurnsLeft:${empty m.statusTurnsLeft ? 'null' : m.statusTurnsLeft}}<c:if test="${!st.last}">,</c:if></c:forEach>
  ],
  appliedItemCount: ${empty appliedItems ? 0 : appliedItems.size()},
  /** ms: 턴 스탯 플래시·결과 확인 후 AI 상황·대사를 채팅에 붙이기까지 추가 대기 */
  geminiDialogueDelayMs: 120,
  miniGameQuizPool: ${empty miniGameQuizPoolJson ? '[]' : miniGameQuizPoolJson},
  sceneId: <c:choose><c:when test="${not empty scene && scene.sceneId != null}">${scene.sceneId}</c:when><c:otherwise>null</c:otherwise></c:choose>
};
</script>
<script>
/* 훈련 일차 기준 스트레스·팀워크 첫 표시(로딩 중 깜빡임 완화). game.js와 동일 규칙 */
(function(){
  function parseDay(phase){
    var p = String(phase || '').trim();
    if (!p) return 1;
    if (p === 'FINISHED' || p === 'DEBUT_EVAL') return 84;
    if (p === 'MID_EVAL') return 56;
    if (p.indexOf('DAY') !== 0) return 1;
    var us = p.indexOf('_');
    if (us <= 3) return 1;
    var n = parseInt(p.substring(3, us), 10);
    if (!isFinite(n) || n < 1) return 1;
    if (n > 84) return 84;
    return n;
  }
  function clampPct(n){
    n = Math.round(Number(n) || 0);
    if (n < 0) return 0;
    if (n > 100) return 100;
    return n;
  }
  var d = parseDay(window.NDX_GAME_CONFIG && window.NDX_GAME_CONFIG.phase);
  var stress = clampPct((d - 1) * 1);
  var teamRaw = 100 - (d - 1) * 0.5;
  if (teamRaw < 0) teamRaw = 0;
  if (teamRaw > 100) teamRaw = 100;
  var team = Math.round(teamRaw * 2) / 2;
  var barS = document.querySelector('.ai-cond-meter[data-key="stress"]');
  if (barS) {
    barS.setAttribute('data-pct', String(stress));
    var vs = barS.querySelector('.status-bar__val');
    var fs = barS.querySelector('.status-fill');
    if (vs) vs.textContent = stress + '%';
    if (fs) fs.style.width = stress + '%';
  }
  var barT = document.querySelector('.ai-cond-meter[data-key="team"]');
  if (barT) {
    barT.setAttribute('data-pct', String(team));
    var vt = barT.querySelector('.status-bar__val');
    var ft = barT.querySelector('.status-fill');
    if (vt) vt.textContent = team % 1 !== 0 ? team.toFixed(1) + '%' : team + '%';
    if (ft) ft.style.width = team + '%';
  }
})();
</script>
<script>
(function(){
  function hideGameLoader(){
    try{
      var lov=document.getElementById('lov');
      var wrap=document.getElementById('gsWrap');
      var pct=document.getElementById('lpct');
      if(pct) pct.textContent='100%';
      if(lov){
        lov.style.opacity='0';
        lov.style.visibility='hidden';
        lov.style.pointerEvents='none';
        setTimeout(function(){ try{ lov.style.display='none'; }catch(e){} }, 350);
      }
      if(wrap){
        wrap.style.opacity='1';
        wrap.style.animation='none';
      }
    }catch(e){}
  }
  window.hideGameLoader = hideGameLoader;
  window.addEventListener('load', function(){
    setTimeout(hideGameLoader, 2600);
  });
  setTimeout(hideGameLoader, 4500);
})();
</script>
<script src="${ctx}/js/condition-panel-logic.js?v=20260404_daily_bars"></script>
<script src="${ctx}/js/condition-panel-ui.js?v=20260404_daily_bars"></script>
<script src="${ctx}/js/chat-simulation-logic.js?v=20260404_intent_chat"></script>
<script src="${ctx}/js/sim-status-presentation.js?v=20260404_daily_bars"></script>
<script src="${ctx}/js/game.js?v=20260421_targeting_modal_totalavg_v1"></script>
<script>
(function(){
  if(typeof window.toggleStatGrowth2x !== 'function'){
    console.error('[2배] game.js에 toggleStatGrowth2x가 없습니다. 강력 새로고침(Ctrl+F5) 후 다시 시도하세요.');
  }
})();
</script>
