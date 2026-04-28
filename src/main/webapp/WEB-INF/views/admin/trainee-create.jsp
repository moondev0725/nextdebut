<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>연습생 추가 관리</title>
  <%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
  <style>
    :root { --bg:#fff8fc; --card:#fff; --pink:#f472b6; --line:rgba(244,114,182,.2); --text:#302734; --muted:#7f6e81; }
    body{margin:0;background:var(--bg);color:var(--text);}
    .wrap{max-width:980px;margin:0 auto;padding:calc(var(--nav-h,68px) + 22px) 18px 40px;display:grid;gap:14px;}
    .box{background:var(--card);border:1px solid var(--line);border-radius:18px;box-shadow:0 12px 28px rgba(236,72,153,.1);}
    .head{padding:16px 18px;display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap;}
    .title{margin:0;font-family:"Orbitron",sans-serif;font-size:24px;letter-spacing:.04em;}
    .muted{color:var(--muted);font-size:13px;}
    .panel{padding:16px 18px;display:grid;gap:14px;}
    .sec{border:1px solid var(--line);border-radius:12px;padding:12px;background:#fff;}
    .sec h3{margin:0 0 10px;font-size:14px;}
    .form-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;}
    .form-grid .full{grid-column:1/-1;}
    .field{display:grid;gap:4px;}
    .field label{font-size:11px;font-weight:700;color:#7f6e81;}
    .input,.select,.hint-box{border:1px solid var(--line);border-radius:10px;padding:9px 10px;font-size:13px;}
    .hint-box{background:#fff8fc;color:#7f6e81;font-size:12px;line-height:1.6;}
    .btn{display:inline-flex;align-items:center;justify-content:center;border:1px solid var(--line);border-radius:10px;background:#fff;padding:9px 12px;font-size:12px;font-weight:700;color:#8f1b58;cursor:pointer;text-decoration:none;}
    .btn.primary{background:linear-gradient(135deg,#f9a8d4,#f472b6);color:#fff;}
    .btn-row{display:flex;gap:8px;flex-wrap:wrap;}
    .stat-preview{display:grid;gap:6px;margin-top:8px;}
    .bar{height:8px;background:#f3eaf2;border-radius:999px;overflow:hidden;}
    .bar > span{display:block;height:100%;background:linear-gradient(90deg,#f472b6,#a78bfa);}
    @media(max-width:760px){.form-grid{grid-template-columns:1fr;}}
  </style>
</head>
<body>
<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>
<main class="wrap">
  <section class="box">
    <div class="head">
      <div>
        <h1 class="title">TRAINEE CREATE</h1>
        <div class="muted">상세 관리 화면과 같은 흐름으로 새 연습생을 등록합니다.</div>
      </div>
      <a href="${ctx}/admin/trainees" class="btn">목록으로</a>
    </div>
  </section>

  <section class="box">
    <div class="head"><strong>신규 연습생 등록</strong></div>
    <div class="panel">
      <form method="post" action="${ctx}/admin/trainee" enctype="multipart/form-data" class="panel" style="padding:0;">
        <div class="sec">
          <h3>1) 기본 정보</h3>
          <div class="form-grid">
            <div class="field">
              <label>이름</label>
              <input class="input" type="text" name="name" required>
            </div>
            <div class="field">
              <label>성별</label>
              <select class="select" name="gender" required>
                <option value="MALE">남성</option>
                <option value="FEMALE">여성</option>
              </select>
            </div>
            <div class="field">
              <label>등급</label>
              <select class="select" name="grade" required>
                <option value="N">N</option>
                <option value="R">R</option>
                <option value="SR">SR</option>
                <option value="SSR">SSR</option>
              </select>
            </div>
            <div class="field">
              <label>나이</label>
              <input class="input" type="number" min="1" name="age" placeholder="나이">
            </div>
            <div class="field">
              <label>생일</label>
              <input class="input" type="date" name="birthday">
            </div>
            <div class="field">
              <label>키(cm)</label>
              <input class="input" type="number" min="100" max="230" name="height" placeholder="키(cm)">
            </div>
            <div class="field">
              <label>취미</label>
              <input class="input" type="text" name="hobby" placeholder="취미">
            </div>
            <div class="field">
              <label>인스타그램 아이디</label>
              <input class="input" type="text" name="instagram" placeholder="인스타그램 아이디">
            </div>
            <div class="field">
              <label>해금 최소 점수</label>
              <input class="input" type="number" min="0" max="1000" name="unlockScore" placeholder="예: 500">
            </div>
            <div class="field full">
              <label>적용 기준</label>
              <div class="hint-box">게임 최종 점수 1000점 만점 기준입니다. 500을 넣으면 최고 점수 500점 이상 달성한 회원에게만 해금됩니다.</div>
            </div>
          </div>
        </div>

        <div class="sec">
          <h3>2) 대표 이미지</h3>
          <div class="form-grid">
            <div class="field full">
              <label>이미지 파일</label>
              <input class="input" type="file" name="image" accept="image/*">
            </div>
          </div>
        </div>

        <div class="sec">
          <h3>3) 능력치 설정</h3>
          <div class="form-grid" id="statsForm">
            <div class="field">
              <label>보컬</label>
              <input class="input stat-input" type="number" min="0" max="100" name="vocal" value="0" required data-label="보컬">
            </div>
            <div class="field">
              <label>댄스</label>
              <input class="input stat-input" type="number" min="0" max="100" name="dance" value="0" required data-label="댄스">
            </div>
            <div class="field">
              <label>스타성</label>
              <input class="input stat-input" type="number" min="0" max="100" name="star" value="0" required data-label="스타성">
            </div>
            <div class="field">
              <label>멘탈</label>
              <input class="input stat-input" type="number" min="0" max="100" name="mental" value="0" required data-label="멘탈">
            </div>
            <div class="field full">
              <label>팀워크</label>
              <input class="input stat-input" type="number" min="0" max="100" name="teamwork" value="0" required data-label="팀워크">
            </div>
            <div class="full stat-preview" id="statPreview"></div>
          </div>
        </div>

        <div class="btn-row">
          <button class="btn primary" type="submit">연습생 등록</button>
          <a href="${ctx}/admin/trainees" class="btn">취소</a>
        </div>
      </form>
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
