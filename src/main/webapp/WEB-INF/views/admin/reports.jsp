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
  <title>관리자 · 신고 게시글 · NEXT DEBUT</title>
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
      text-decoration:none;cursor:pointer;font-family:inherit;
    }
    .btn:hover{background:rgba(253,242,248,.9);}
    .btn.danger{border-color:rgba(251,113,133,.45);color:#be123c;background:rgba(255,241,242,.85);}
    .section-head{
      padding:12px 16px;font-size:12px;font-weight:800;letter-spacing:.1em;font-family:"Orbitron",sans-serif;
      border-bottom:1px solid rgba(196,181,253,.55);color:#7f62a3;
    }
    .section-body{padding:14px 16px 18px;}
    .members-table-wrap{overflow:auto;border:1px solid rgba(244,114,182,.12);border-radius:14px;}
    .members-table{width:100%;border-collapse:separate;border-spacing:0;min-width:520px;}
    .members-table th{text-align:left;font-size:10px;letter-spacing:.08em;color:#8d5f74;padding:10px;border-bottom:1px solid rgba(244,114,182,.18);}
    .members-table td{padding:11px 10px;border-bottom:1px solid rgba(244,114,182,.10);font-size:13px;vertical-align:top;}
    .members-table tbody tr:hover{background:rgba(253,242,248,.35);}
    .title-cell{min-width:0;}
    .title-cell .t{font-weight:800;color:#1f2937;}
    .title-cell .m{margin-top:4px;font-size:12px;color:#8e6f7f;}
    .empty{font-size:13px;color:#8e6f7f;padding:12px;text-align:center;}
    .alert{
      padding:11px 14px;border-radius:14px;font-size:13px;
      border:1px solid rgba(134,239,172,.32);
      background:rgba(220,252,231,.65);color:#166534;
    }
    .tools{display:flex;flex-wrap:wrap;gap:8px;align-items:center;justify-content:flex-end;}
    .status-pill{font-size:11px;font-weight:800;padding:4px 10px;border-radius:999px;letter-spacing:.02em;}
    .status-pill.done{background:rgba(220,252,231,.9);color:#166534;border:1px solid rgba(134,239,172,.45);}
    .status-pill.wait{background:rgba(254,243,199,.85);color:#92400e;border:1px solid rgba(251,191,36,.35);}
  </style>
</head>
<body>
<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>

<main class="ad-wrap">
  <section class="card hero">
    <div>
      <h1>REPORTS · 신고</h1>
      <p><code style="font-size:12px;background:rgba(244,114,182,.12);padding:2px 6px;border-radius:6px;">board_type = report</code> 사용자 신고판 접수 글입니다. <strong>처리완료</strong>는 신고판 목록에 완료 표시만 하고, <strong>삭제</strong>는 글을 제거합니다.</p>
    </div>
    <div style="display:flex;flex-wrap:wrap;gap:8px;">
      <a class="btn" href="${ctx}/admin"><i class="fas fa-arrow-left"></i> 대시보드</a>
      <a class="btn" href="${ctx}/boards/report"><i class="fas fa-list"></i> 사용자 신고판</a>
    </div>
  </section>

  <c:if test="${not empty success}">
    <div class="alert"><i class="fas fa-check-circle"></i> ${success}</div>
  </c:if>

  <section class="card">
    <div class="section-body" style="padding-bottom:0;">
      <div class="tools" style="justify-content:flex-start;">
        <a class="btn ${reportStatusFilter eq 'pending' ? 'danger' : ''}" href="${ctx}/admin/reports?status=pending">처리 대기</a>
        <a class="btn ${reportStatusFilter eq 'completed' ? 'danger' : ''}" href="${ctx}/admin/reports?status=completed">처리 완료</a>
      </div>
    </div>
    <div class="section-head">신고 목록 · <fmt:formatNumber value="${empty reportedPosts ? 0 : fn:length(reportedPosts)}" pattern="#,##0"/>건</div>
    <div class="section-body">
      <c:choose>
        <c:when test="${empty reportedPosts}">
          <div class="empty">등록된 신고 게시글이 없습니다.</div>
        </c:when>
        <c:otherwise>
          <div class="members-table-wrap">
            <table class="members-table">
              <thead>
              <tr>
                <th style="width:72px;">ID</th>
                <th>제목 · 분류</th>
                <th style="width:100px;">상태</th>
                <th style="width:120px;">작성</th>
                <th style="width:220px;text-align:right;">관리</th>
              </tr>
              </thead>
              <tbody>
              <c:forEach var="r" items="${reportedPosts}">
                <tr>
                  <td>#${r.id}</td>
                  <td class="title-cell">
                    <div class="t">
                      <a href="${ctx}/boards/report/${r.id}" style="color:inherit;text-decoration:none;"><c:out value="${r.title}"/></a>
                    </div>
                    <div class="m">
                      <c:if test="${not empty r.category}"><c:out value="${r.category}"/> · </c:if>
                      <c:out value="${r.authorNick}"/> · <c:out value="${r.createdAtStr}"/>
                    </div>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${reportHandledMap[r.id]}"><span class="status-pill done">처리완료</span></c:when>
                      <c:otherwise><span class="status-pill wait">접수중</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td style="white-space:nowrap;font-size:12px;color:#6b7280;"><c:out value="${r.createdAtStr}"/></td>
                  <td>
                    <div class="tools">
                      <a class="btn" href="${ctx}/boards/report/${r.id}" style="font-size:12px;padding:7px 10px;">보기</a>
                      <c:if test="${not reportHandledMap[r.id]}">
                        <form method="post" action="${ctx}/admin/reports/${r.id}/handle" style="margin:0;" onsubmit="return confirm('이 글을 사용자 신고판에서 처리완료로 표시할까요?');">
                          <input type="hidden" name="action" value="complete"/>
                          <input type="hidden" name="from" value="reports"/>
                          <input type="hidden" name="status" value="${reportStatusFilter}"/>
                          <button type="submit" class="btn" style="font-size:12px;padding:7px 10px;">처리완료</button>
                        </form>
                      </c:if>
                      <form method="post" action="${ctx}/admin/reports/${r.id}/handle" style="margin:0;" onsubmit="return confirm('이 신고 글을 삭제할까요?');">
                        <input type="hidden" name="action" value="delete"/>
                        <input type="hidden" name="from" value="reports"/>
                        <input type="hidden" name="status" value="${reportStatusFilter}"/>
                        <button type="submit" class="btn danger" style="font-size:12px;padding:7px 10px;">삭제</button>
                      </form>
                    </div>
                  </td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </div>
  </section>
</main>
</body>
</html>
