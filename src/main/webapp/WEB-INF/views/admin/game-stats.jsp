<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"  prefix="fmt" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>관리자 · 게임 통계 · NEXT DEBUT</title>
  <%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
  <style>
    :root{
      --ad-bg:#fff8fc;
      --ad-card:#ffffff;
      --ad-border:rgba(244,114,182,.20);
      --ad-text:#332b30;
      --ad-shadow:0 14px 34px rgba(236,72,153,.10);
      --ad-r:18px;
    }
    *{box-sizing:border-box}
    body{margin:0;color:var(--ad-text);
      background:
        radial-gradient(1200px 500px at 0% -20%, rgba(251,207,232,.5), transparent 56%),
        radial-gradient(900px 480px at 100% -10%, rgba(253,242,248,.9), transparent 58%),
        var(--ad-bg);
    }
    .ad-wrap{max-width:1100px;margin:0 auto;padding:calc(var(--nav-h,68px) + 22px) 20px 42px;display:grid;gap:14px;}
    .card{
      background:var(--ad-card);
      border:1px solid var(--ad-border);
      border-radius:var(--ad-r);
      box-shadow:var(--ad-shadow);
    }
    .hero{padding:18px;display:flex;justify-content:space-between;align-items:flex-start;gap:14px;flex-wrap:wrap;}
    .hero h1{font-family:"Orbitron",sans-serif;font-size:clamp(1.1rem,2.4vw,1.45rem);margin:0 0 8px;letter-spacing:.06em;}
    .hero p{margin:0;font-size:13px;color:#6B7280;max-width:560px;line-height:1.55;}
    .btn{
      display:inline-flex;align-items:center;gap:6px;padding:9px 14px;border-radius:12px;
      border:1px solid rgba(244,114,182,.35);background:#fff;color:#9d174d;font-size:13px;font-weight:700;
      text-decoration:none;cursor:pointer;
    }
    .btn:hover{background:rgba(253,242,248,.9);}
    .section-head{
      padding:12px 16px;font-size:12px;font-weight:800;letter-spacing:.1em;font-family:"Orbitron",sans-serif;
      border-bottom:1px solid rgba(196,181,253,.55);color:#7f62a3;
    }
    .section-body{padding:14px 16px 18px;}
    .members-table-wrap{overflow:auto;border:1px solid rgba(244,114,182,.12);border-radius:14px;}
    .members-table{width:100%;border-collapse:separate;border-spacing:0;min-width:280px;}
    .members-table th{text-align:left;font-size:10px;letter-spacing:.08em;color:#8d5f74;padding:10px;border-bottom:1px solid rgba(244,114,182,.18);}
    .members-table td{padding:11px 10px;border-bottom:1px solid rgba(244,114,182,.10);font-size:13px;}
    .members-table tbody tr:hover{background:rgba(253,242,248,.35);}
    .members-table td.num{text-align:right;font-variant-numeric:tabular-nums;}
    .empty{font-size:13px;color:#8e6f7f;padding:12px;text-align:center;}
    .hint{font-size:12px;color:#6B7280;margin:0 0 10px;line-height:1.5;}
  </style>
</head>
<body>
<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>

<main class="ad-wrap">
  <section class="card hero">
    <div>
      <h1>GAME · STATS</h1>
      <p>전체 <code style="font-size:12px;background:rgba(244,114,182,.12);padding:2px 6px;border-radius:6px;">GameRun</code> 레코드 기준으로 페이즈(단계)별 건수와 확정 여부를 집계합니다.</p>
    </div>
    <div style="display:flex;flex-wrap:wrap;gap:8px;">
      <a class="btn" href="${ctx}/admin"><i class="fas fa-arrow-left"></i> 대시보드</a>
      <a class="btn" href="${ctx}/game"><i class="fas fa-gamepad"></i> 게임 로비</a>
      <a class="btn" href="${ctx}/admin/shop"><i class="fas fa-coins"></i> 상점 통계</a>
    </div>
  </section>

  <section class="card">
    <div class="section-head">페이즈(단계)별 건수</div>
    <div class="section-body">
      <p class="hint">같은 페이즈 문자열을 기준으로 묶은 누적 건수입니다.</p>
      <c:choose>
        <c:when test="${empty phaseCounts}">
          <div class="empty">집계할 게임 기록이 없습니다.</div>
        </c:when>
        <c:otherwise>
          <div class="members-table-wrap">
            <table class="members-table">
              <thead><tr><th>페이즈</th><th style="text-align:right;">건수</th></tr></thead>
              <tbody>
              <c:forEach var="entry" items="${phaseCounts}">
                <tr>
                  <td><c:out value="${entry.key}"/></td>
                  <td class="num"><fmt:formatNumber value="${entry.value}" pattern="#,##0"/></td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </div>
  </section>

  <section class="card">
    <div class="section-head">확정 여부</div>
    <div class="section-body">
      <p class="hint"><code>GameRun.confirmed</code> 값별 누적 건수입니다.</p>
      <c:choose>
        <c:when test="${empty confirmedCounts}">
          <div class="empty">집계할 게임 기록이 없습니다.</div>
        </c:when>
        <c:otherwise>
          <div class="members-table-wrap">
            <table class="members-table">
              <thead><tr><th>확정</th><th style="text-align:right;">건수</th></tr></thead>
              <tbody>
              <c:forEach var="entry" items="${confirmedCounts}">
                <tr>
                  <td><c:out value="${entry.key ? '예' : '아니오'}"/></td>
                  <td class="num"><fmt:formatNumber value="${entry.value}" pattern="#,##0"/></td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </div>
  </section>

  <section class="card">
    <div class="section-head">채팅 선택 ML 예측 통계</div>
    <div class="section-body">
      <p class="hint"><code>app.ml.training-log-path</code> 누적 예측 로그 기준으로 ML 예측/미예측 비율을 집계합니다.</p>
      <div class="members-table-wrap">
        <table class="members-table">
          <thead><tr><th>항목</th><th style="text-align:right;">값</th></tr></thead>
          <tbody>
            <tr>
              <td>총 평가 샘플 수</td>
              <td class="num"><fmt:formatNumber value="${mlChoiceStats.total}" pattern="#,##0"/></td>
            </tr>
            <tr>
              <td>ML 예측 건수</td>
              <td class="num"><fmt:formatNumber value="${mlChoiceStats.ml}" pattern="#,##0"/> 건</td>
            </tr>
            <tr>
              <td>미예측 건수</td>
              <td class="num"><fmt:formatNumber value="${mlChoiceStats.rule}" pattern="#,##0"/> 건</td>
            </tr>
            <tr>
              <td>ML 예측률</td>
              <td class="num"><fmt:formatNumber value="${mlChoiceStats.mlRate}" pattern="#,##0.0"/>%</td>
            </tr>
            <tr>
              <td>미예측 비율</td>
              <td class="num"><fmt:formatNumber value="${mlChoiceStats.fallbackRate}" pattern="#,##0.0"/>%</td>
            </tr>
            <tr>
              <td>평균 예측 신뢰도</td>
              <td class="num"><fmt:formatNumber value="${mlChoiceStats.avgConfidence}" pattern="#,##0.000"/></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>
</main>
</body>
</html>
