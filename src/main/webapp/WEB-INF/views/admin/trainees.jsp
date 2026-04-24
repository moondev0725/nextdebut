<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>관리자 · 연습생 운영</title>
  <%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
  <style>
    :root { --bg:#fff8fc; --card:#fff; --pink:#f472b6; --line:rgba(244,114,182,.2); --text:#302734; --muted:#7f6e81; }
    body{margin:0;background:var(--bg);color:var(--text);}
    .wrap{max-width:1400px;margin:0 auto;padding:calc(var(--nav-h,68px) + 22px) 18px 40px;display:grid;gap:14px;}
    .box{background:var(--card);border:1px solid var(--line);border-radius:18px;box-shadow:0 12px 28px rgba(236,72,153,.1);}
    .head{padding:16px 18px;display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap;}
    .title{margin:0;font-family:"Orbitron",sans-serif;font-size:24px;letter-spacing:.04em;}
    .muted{color:var(--muted);font-size:13px;}
    .filters{padding:14px 18px;display:grid;gap:12px;}
    .row{display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
    .pill{padding:8px 12px;border-radius:999px;border:1px solid var(--line);text-decoration:none;color:#8f1b58;font-size:12px;font-weight:700;background:#fff;}
    .pill.on{background:linear-gradient(135deg,#fbcfe8,#f472b6);color:#831843;}
    .input,.select{border:1px solid var(--line);border-radius:10px;padding:9px 10px;font-size:13px;}
    .btn{border:1px solid var(--line);border-radius:10px;background:#fff;padding:9px 12px;font-size:12px;font-weight:700;color:#8f1b58;cursor:pointer;}
    .btn.primary{background:linear-gradient(135deg,#f9a8d4,#f472b6);color:#fff;}
    .layout{display:grid;grid-template-columns:1.2fr .8fr;gap:14px;}
    .grid{padding:12px 14px 16px;display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:10px;}
    .card{border:1px solid var(--line);border-radius:14px;padding:10px;background:#fff;text-decoration:none;color:inherit;display:block;}
    .card:hover{transform:translateY(-2px);box-shadow:0 8px 20px rgba(236,72,153,.14);}
    .thumb{height:130px;border-radius:10px;overflow:hidden;background:#f6f0f6;display:flex;align-items:center;justify-content:center;color:#b29ab0;}
    .thumb img{width:100%;height:100%;object-fit:contain;object-position:center;background:#f7f4f7;}
    .meta{margin-top:9px;display:grid;gap:4px;font-size:12px;}
    .name{font-weight:800;font-size:16px;}
    .pc-state{display:flex;gap:6px;flex-wrap:wrap;}
    .chip{padding:3px 8px;border-radius:999px;border:1px solid #d6d3d8;font-size:11px;color:#74687b;background:#f6f3f7;}
    .chip.ok{border-color:#86efac;background:#dcfce7;color:#166534;}
    .panel{padding:16px 18px;display:grid;gap:14px;}
    .sec{border:1px solid var(--line);border-radius:12px;padding:12px;background:#fff;}
    .sec h3{margin:0 0 10px;font-size:14px;}
    .form-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;}
    .form-grid .full{grid-column:1/-1;}
    .field{display:grid;gap:4px;}
    .field label{font-size:11px;font-weight:700;color:#7f6e81;}
    .stat-preview{display:grid;gap:6px;margin-top:8px;}
    .bar{height:8px;background:#f3eaf2;border-radius:999px;overflow:hidden;}
    .bar > span{display:block;height:100%;background:linear-gradient(90deg,#f472b6,#a78bfa);}
    .pc-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;}
    .notice{padding:10px 12px;border:1px solid rgba(134,239,172,.4);background:rgba(220,252,231,.7);border-radius:12px;color:#166534;font-size:13px;}
    @media(max-width:980px){.layout{grid-template-columns:1fr;}.pc-grid{grid-template-columns:1fr;}}
  </style>
</head>
<body>
<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>
<main class="wrap">
  <section class="box">
    <div class="head">
      <div>
        <h1 class="title">TRAINEE OPS</h1>
        <div class="muted">연습생 검색/추가/능력치/이미지/포토카드 운영</div>
      </div>
      <form method="post" action="${ctx}/admin/trainee" enctype="multipart/form-data" class="row">
        <input class="input" type="text" name="name" placeholder="이름" required>
        <select class="select" name="gender" required>
          <option value="MALE">남성</option>
          <option value="FEMALE">여성</option>
        </select>
        <input class="input" type="number" min="0" max="20" name="vocal" placeholder="보컬" required>
        <input class="input" type="number" min="0" max="20" name="dance" placeholder="댄스" required>
        <input class="input" type="number" min="0" max="20" name="star" placeholder="스타성" required>
        <input class="input" type="number" min="0" max="20" name="mental" placeholder="멘탈" required>
        <input class="input" type="number" min="0" max="20" name="teamwork" placeholder="팀워크" required>
        <input class="input" type="file" name="image" accept="image/*">
        <button class="btn primary" type="submit">연습생 추가</button>
      </form>
    </div>
    <div class="filters">
      <form method="get" action="${ctx}/admin/trainees" class="row">
        <input class="input" type="search" name="keyword" value="${keyword}" placeholder="이름 검색">
        <input type="hidden" name="gender" value="${selectedGender}">
        <input type="hidden" name="grade" value="${selectedGrade}">
        <select class="select" name="sort">
          <option value="name" ${selectedSort == 'name' ? 'selected' : ''}>이름순</option>
          <option value="ability" ${selectedSort == 'ability' ? 'selected' : ''}>평균 능력치순</option>
        </select>
        <button class="btn" type="submit">조회</button>
      </form>
      <div class="row">
        <c:url var="allUrl" value="/admin/trainees"><c:param name="gender" value="ALL"/><c:param name="grade" value="${selectedGrade}"/><c:param name="keyword" value="${keyword}"/><c:param name="sort" value="${selectedSort}"/></c:url>
        <c:url var="maleUrl" value="/admin/trainees"><c:param name="gender" value="MALE"/><c:param name="grade" value="${selectedGrade}"/><c:param name="keyword" value="${keyword}"/><c:param name="sort" value="${selectedSort}"/></c:url>
        <c:url var="femaleUrl" value="/admin/trainees"><c:param name="gender" value="FEMALE"/><c:param name="grade" value="${selectedGrade}"/><c:param name="keyword" value="${keyword}"/><c:param name="sort" value="${selectedSort}"/></c:url>
        <a href="${allUrl}" class="pill ${selectedGender == 'ALL' ? 'on' : ''}">전체</a>
        <a href="${maleUrl}" class="pill ${selectedGender == 'MALE' ? 'on' : ''}">남성</a>
        <a href="${femaleUrl}" class="pill ${selectedGender == 'FEMALE' ? 'on' : ''}">여성</a>
      </div>
      <div class="row">
        <c:url var="gradeAllUrl" value="/admin/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="ALL"/><c:param name="keyword" value="${keyword}"/><c:param name="sort" value="${selectedSort}"/></c:url>
        <c:url var="gradeNUrl" value="/admin/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="N"/><c:param name="keyword" value="${keyword}"/><c:param name="sort" value="${selectedSort}"/></c:url>
        <c:url var="gradeRUrl" value="/admin/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="R"/><c:param name="keyword" value="${keyword}"/><c:param name="sort" value="${selectedSort}"/></c:url>
        <c:url var="gradeSrUrl" value="/admin/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="SR"/><c:param name="keyword" value="${keyword}"/><c:param name="sort" value="${selectedSort}"/></c:url>
        <c:url var="gradeSsrUrl" value="/admin/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="SSR"/><c:param name="keyword" value="${keyword}"/><c:param name="sort" value="${selectedSort}"/></c:url>
        <a href="${gradeAllUrl}" class="pill ${selectedGrade == 'ALL' ? 'on' : ''}">등급 전체</a>
        <a href="${gradeNUrl}" class="pill ${selectedGrade == 'N' ? 'on' : ''}">N</a>
        <a href="${gradeRUrl}" class="pill ${selectedGrade == 'R' ? 'on' : ''}">R</a>
        <a href="${gradeSrUrl}" class="pill ${selectedGrade == 'SR' ? 'on' : ''}">SR</a>
        <a href="${gradeSsrUrl}" class="pill ${selectedGrade == 'SSR' ? 'on' : ''}">SSR</a>
      </div>
    </div>
  </section>

  <c:if test="${not empty success}">
    <div class="notice">${success}</div>
  </c:if>

  <section class="layout">
    <div class="box">
      <div class="head"><strong>연습생 목록</strong><span class="muted">${fn:length(trainees)}명</span></div>
      <div class="grid">
        <c:forEach var="t" items="${trainees}">
          <c:set var="cards" value="${cardConfiguredMap[t.id]}"/>
          <c:url var="detailUrl" value="/admin/trainees">
            <c:param name="keyword" value="${keyword}"/>
            <c:param name="gender" value="${selectedGender}"/>
            <c:param name="grade" value="${selectedGrade}"/>
            <c:param name="sort" value="${selectedSort}"/>
            <c:param name="traineeId" value="${t.id}"/>
          </c:url>
          <a class="card" href="${detailUrl}">
            <div class="thumb">
              <c:choose>
                <c:when test="${not empty t.imagePath}"><img src="${ctx}${t.imagePath}" alt="${t.name}"></c:when>
                <c:otherwise><i class="fas fa-user"></i></c:otherwise>
              </c:choose>
            </div>
            <div class="meta">
              <div class="name">${t.name}</div>
              <div>성별: ${t.gender == 'MALE' ? '남성' : '여성'}</div>
              <div>평균 능력치: ${t.averageAbilityScore}</div>
              <div class="pc-state">
                <span class="chip ${cards['R'] ? 'ok' : ''}">R ${cards['R'] ? '완료' : '미설정'}</span>
                <span class="chip ${cards['SR'] ? 'ok' : ''}">SR ${cards['SR'] ? '완료' : '미설정'}</span>
                <span class="chip ${cards['SSR'] ? 'ok' : ''}">SSR ${cards['SSR'] ? '완료' : '미설정'}</span>
              </div>
            </div>
          </a>
        </c:forEach>
      </div>
    </div>

    <div class="box">
      <div class="head"><strong>상세 관리</strong></div>
      <div class="panel">
        <c:choose>
          <c:when test="${empty selectedTrainee}">
            <div class="muted">좌측 목록에서 연습생을 선택하세요.</div>
          </c:when>
          <c:otherwise>
            <div class="sec">
              <h3>1) 기본 정보</h3>
              <div class="row">
                <c:choose>
                  <c:when test="${not empty selectedTrainee.imagePath}"><img src="${ctx}${selectedTrainee.imagePath}" alt="${selectedTrainee.name}" style="width:80px;height:80px;border-radius:12px;object-fit:contain;background:#f7f4f7;"></c:when>
                  <c:otherwise><div class="thumb" style="width:80px;height:80px;"><i class="fas fa-user"></i></div></c:otherwise>
                </c:choose>
                <div class="muted">등록일: ${selectedTrainee.createdAt != null ? selectedTrainee.createdAt : '-'}</div>
              </div>
              <form method="post" action="${ctx}/admin/trainees/${selectedTrainee.id}/basic" class="form-grid" style="margin-top:10px;">
                <div class="field">
                  <label>이름</label>
                  <input class="input" name="name" value="${selectedTrainee.name}" required>
                </div>
                <div class="field">
                  <label>성별</label>
                  <select class="select" name="gender" required>
                    <option value="MALE" ${selectedTrainee.gender == 'MALE' ? 'selected' : ''}>남성</option>
                    <option value="FEMALE" ${selectedTrainee.gender == 'FEMALE' ? 'selected' : ''}>여성</option>
                  </select>
                </div>
                <div class="field">
                  <label>등급</label>
                  <select class="select" name="grade" required>
                    <option value="N" ${selectedTrainee.grade == 'N' ? 'selected' : ''}>N</option>
                    <option value="R" ${selectedTrainee.grade == 'R' ? 'selected' : ''}>R</option>
                    <option value="SR" ${selectedTrainee.grade == 'SR' ? 'selected' : ''}>SR</option>
                    <option value="SSR" ${selectedTrainee.grade == 'SSR' ? 'selected' : ''}>SSR</option>
                  </select>
                </div>
                <div class="field">
                  <label>나이</label>
                  <input class="input" type="number" min="1" max="99" name="age" value="${selectedTrainee.age}" placeholder="나이">
                </div>
                <div class="field">
                  <label>생일</label>
                  <input class="input" type="date" name="birthday" value="${selectedTrainee.birthday}" placeholder="생일">
                </div>
                <div class="field">
                  <label>키(cm)</label>
                  <input class="input" type="number" min="100" max="230" name="height" value="${selectedTrainee.height}" placeholder="키(cm)">
                </div>
                <div class="field">
                  <label>취미</label>
                  <input class="input" name="hobby" value="${selectedTrainee.hobby}" placeholder="취미">
                </div>
                <div class="field full">
                  <label>인스타그램 아이디</label>
                  <input class="input full" name="instagram" value="${selectedTrainee.instagram}" placeholder="인스타그램 아이디">
                </div>
                <button class="btn primary full" type="submit">기본 정보 저장</button>
              </form>
              <form method="post" action="${ctx}/admin/trainees/${selectedTrainee.id}/ops-delete" onsubmit="return confirm('정말 이 연습생을 삭제하시겠습니까? 보유/포토카드/좋아요 데이터도 함께 정리됩니다.');" style="margin-top:8px;">
                <button class="btn full" type="submit" style="width:100%;border-color:#fecaca;color:#991b1b;background:#fff1f2;">연습생 삭제</button>
              </form>
            </div>

            <div class="sec">
              <h3>2) 이미지 관리</h3>
              <form method="post" action="${ctx}/admin/trainees/${selectedTrainee.id}/image" enctype="multipart/form-data" class="row">
                <input class="input" type="file" name="image" accept="image/*" required>
                <button class="btn" type="submit">대표 이미지 교체</button>
              </form>
            </div>

            <div class="sec">
              <h3>3) 능력치 관리</h3>
              <form method="post" action="${ctx}/admin/trainees/${selectedTrainee.id}/stats" class="form-grid" id="statsForm">
                <div class="field">
                  <label>보컬</label>
                  <input class="input stat-input" type="number" min="0" max="20" name="vocal" value="${selectedTrainee.vocal}" required data-label="보컬">
                </div>
                <div class="field">
                  <label>댄스</label>
                  <input class="input stat-input" type="number" min="0" max="20" name="dance" value="${selectedTrainee.dance}" required data-label="댄스">
                </div>
                <div class="field">
                  <label>스타성</label>
                  <input class="input stat-input" type="number" min="0" max="20" name="star" value="${selectedTrainee.star}" required data-label="스타성">
                </div>
                <div class="field">
                  <label>멘탈</label>
                  <input class="input stat-input" type="number" min="0" max="20" name="mental" value="${selectedTrainee.mental}" required data-label="멘탈">
                </div>
                <div class="field full">
                  <label>팀워크</label>
                  <input class="input stat-input full" type="number" min="0" max="20" name="teamwork" value="${selectedTrainee.teamwork}" required data-label="팀워크">
                </div>
                <div class="full stat-preview" id="statPreview"></div>
                <button class="btn primary full" type="submit">능력치 저장</button>
              </form>
            </div>

            <div class="sec">
              <h3>4) 포토카드 관리</h3>
              <div class="pc-grid">
                <c:forEach var="grade" items="${['R','SR','SSR']}">
                  <c:set var="cardState" value="미등록"/>
                  <c:set var="cardImage" value=""/>
                  <c:forEach var="card" items="${selectedCards}">
                    <c:if test="${card.grade == grade}">
                      <c:set var="cardState" value="${card.configured ? '등록됨' : '미등록'}"/>
                      <c:set var="cardImage" value="${card.imageUrl}"/>
                    </c:if>
                  </c:forEach>
                  <div class="sec">
                    <strong>${grade} 카드</strong>
                    <div class="muted">상태: ${cardState}</div>
                    <c:if test="${not empty cardImage}">
                      <img src="${ctx}${cardImage}" alt="${grade}" style="width:100%;height:100px;object-fit:contain;background:#f7f4f7;border-radius:10px;margin-top:8px;">
                    </c:if>
                    <form method="post" action="${ctx}/admin/trainees/${selectedTrainee.id}/photocards/${grade}" enctype="multipart/form-data" style="margin-top:8px;">
                      <input class="input" type="file" name="image" accept="image/*" required>
                      <button class="btn" type="submit" style="margin-top:8px;width:100%;">${grade} 저장</button>
                    </form>
                  </div>
                </c:forEach>
              </div>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>
</main>

<script>
  (function () {
    var statInputs = document.querySelectorAll('.stat-input');
    var preview = document.getElementById('statPreview');
    if (!statInputs.length || !preview) return;
    function render() {
      preview.innerHTML = '';
      statInputs.forEach(function (input) {
        var v = Number(input.value || 0);
        var row = document.createElement('div');
        row.innerHTML = '<div style="display:flex;justify-content:space-between;font-size:12px;"><span>'
          + input.dataset.label + '</span><strong>' + v + '</strong></div>'
          + '<div class="bar"><span style="width:' + Math.max(0, Math.min(100, v)) + '%;"></span></div>';
        preview.appendChild(row);
      });
    }
    statInputs.forEach(function (input) { input.addEventListener('input', render); });
    render();
  })();
</script>
</body>
</html>
