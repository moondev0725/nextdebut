<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>NEXT DEBUT — DEBUT RESULT</title>
<%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
<link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=Noto+Sans+KR:wght@300;400;500;700;900&display=swap" rel="stylesheet">

<style>
html{scroll-behavior:auto!important;min-height:100%}
*{box-sizing:border-box}
html,body{margin:0;padding:0;min-height:100%;overflow-x:hidden;overflow-y:auto}
:root{--grade-color:${ending.gradeColor};--ink:#3c2437;--muted:#7f6679;--grade-line-main:<c:choose><c:when test="${ending.grade eq 'S'}">rgba(255,215,0,.85)</c:when><c:when test="${ending.grade eq 'A'}">rgba(255,158,209,.85)</c:when><c:when test="${ending.grade eq 'B'}">rgba(198,168,255,.85)</c:when><c:when test="${ending.grade eq 'C'}">rgba(158,208,255,.85)</c:when><c:otherwise>rgba(255,255,255,.60)</c:otherwise></c:choose>;--grade-line-sub:<c:choose><c:when test="${ending.grade eq 'S'}">rgba(255,240,170,.65)</c:when><c:when test="${ending.grade eq 'A'}">rgba(255,205,230,.65)</c:when><c:when test="${ending.grade eq 'B'}">rgba(220,205,255,.65)</c:when><c:when test="${ending.grade eq 'C'}">rgba(205,232,255,.65)</c:when><c:otherwise>rgba(255,255,255,.42)</c:otherwise></c:choose>;--grade-line-glow:<c:choose><c:when test="${ending.grade eq 'S'}">rgba(255,215,0,.45)</c:when><c:when test="${ending.grade eq 'A'}">rgba(255,158,209,.45)</c:when><c:when test="${ending.grade eq 'B'}">rgba(198,168,255,.45)</c:when><c:when test="${ending.grade eq 'C'}">rgba(158,208,255,.45)</c:when><c:otherwise>rgba(255,255,255,.28)</c:otherwise></c:choose>;--grade-overlay:<c:choose><c:when test="${ending.grade eq 'S'}">rgba(255,215,0,.08)</c:when><c:when test="${ending.grade eq 'A'}">rgba(255,158,209,.10)</c:when><c:when test="${ending.grade eq 'B'}">rgba(198,168,255,.12)</c:when><c:when test="${ending.grade eq 'C'}">rgba(158,208,255,.12)</c:when><c:otherwise>rgba(210,210,220,.14)</c:otherwise></c:choose>;--grade-overlay-strong:<c:choose><c:when test="${ending.grade eq 'S'}">rgba(255,240,180,.14)</c:when><c:when test="${ending.grade eq 'A'}">rgba(255,205,230,.16)</c:when><c:when test="${ending.grade eq 'B'}">rgba(220,205,255,.18)</c:when><c:when test="${ending.grade eq 'C'}">rgba(205,232,255,.18)</c:when><c:otherwise>rgba(230,230,235,.20)</c:otherwise></c:choose>}
body{min-height:100vh;font-family:"Noto Sans KR",sans-serif;color:var(--ink);background:radial-gradient(circle at 20% 12%, rgba(255,255,255,.72), transparent 28%),radial-gradient(circle at 82% 8%, rgba(255,255,255,.68), transparent 24%),linear-gradient(180deg, #f7e8f3 0%, #f8edf7 48%, #fbf3f8 100%);overflow-x:hidden;overflow-y:auto;position:relative}
body::before{content:"";position:fixed;inset:0;background:url("${ctx}/images/back.png") center top/cover no-repeat;opacity:.30;filter:saturate(1.12) brightness(1.03);pointer-events:none;z-index:0}
body::after{content:"";position:fixed;inset:0;background:radial-gradient(circle at 50% 18%, var(--grade-overlay-strong) 0%, rgba(255,255,255,0) 36%),linear-gradient(180deg, var(--grade-overlay) 0%, rgba(255,255,255,0) 58%),linear-gradient(115deg, rgba(255,255,255,0) 0%, rgba(255,255,255,.10) 18%, rgba(255,255,255,0) 33%),linear-gradient(245deg, rgba(255,255,255,0) 0%, rgba(255,255,255,.08) 20%, rgba(255,255,255,0) 35%);pointer-events:none;z-index:0}
.result-page{position:relative;z-index:1;width:min(1320px, calc(100% - 48px));min-height:100vh;height:auto;margin:0 auto;padding:104px 0 32px;opacity:0;transform:scale(1.006);transition:opacity .38s ease-out, transform .38s ease-out;overflow:visible}
.result-page.show{opacity:1;transform:scale(1)}
.result-shell{border-radius:28px}
.result-shell.grade-S{background:linear-gradient(180deg, rgba(255,248,226,.26), rgba(255,250,252,.16))}
.result-shell.grade-A{background:linear-gradient(180deg, rgba(255,232,244,.24), rgba(255,250,252,.16))}
.result-shell.grade-B{background:linear-gradient(180deg, rgba(241,234,255,.24), rgba(255,250,252,.16))}
.result-shell.grade-C{background:linear-gradient(180deg, rgba(231,245,255,.24), rgba(255,250,252,.16))}
.result-shell.grade-D{background:linear-gradient(180deg, rgba(240,240,240,.18), rgba(255,250,252,.12))}
.grade-S{color:#ffd700;text-shadow:0 0 12px rgba(255,215,0,.6),0 0 24px rgba(255,215,0,.4)}
.grade-A{color:#ff9ed1;text-shadow:0 0 10px rgba(255,158,209,.6),0 0 20px rgba(255,158,209,.4)}
.grade-B{color:#c6a8ff;text-shadow:0 0 10px rgba(198,168,255,.6),0 0 20px rgba(198,168,255,.4)}
.grade-C{color:#9ed0ff;text-shadow:0 0 10px rgba(158,208,255,.6),0 0 20px rgba(158,208,255,.4)}
.grade-D{color:#f5f5f5;text-shadow:0 0 10px rgba(255,255,255,.34),0 0 20px rgba(255,255,255,.18)}
.result-top{margin-bottom:0;padding-bottom:4px}
.result-hero{display:grid;grid-template-columns:repeat(2,minmax(0,520px));gap:20px;align-items:stretch;justify-content:center;width:min(1180px,100%);max-width:100%;margin:0 auto 8px;min-height:0;box-sizing:border-box}
.result-left-stack{
  display:flex;
  flex-direction:column;
  gap:18px;
  min-width:0;
  max-width:100%;
  padding-top:22px;
}
.result-copy-panel{position:relative;min-height:auto;padding:8px 0 0;border-radius:0;background:transparent;box-shadow:none;overflow:visible;isolation:auto}
.result-copy-panel::before,.result-copy-panel::after{display:none}
.result-copy-inner{position:relative;z-index:1}
.result-copy-main{position:relative;padding-left:110px;padding-top:18px;}
.result-grade-anchor{position:absolute;left:0;top:6px;z-index:6;font-family:"Orbitron",sans-serif;font-size:92px;font-weight:900;line-height:1;letter-spacing:-3px;opacity:.82;pointer-events:none;text-shadow:none;filter:saturate(.88) brightness(1.02);}
.ending-intro-grade{font-family:"Orbitron",sans-serif;font-size:100px;font-weight:900;line-height:1;letter-spacing:-4px;opacity:0;transform:none;transition:opacity .35s ease;text-shadow:none}
.ending-intro-grade.show{opacity:1}
.grade-S .result-grade-anchor,
.ending-intro-grade.grade-S{
  color:#f2cd67;
  background:linear-gradient(180deg,#fff5d6 0%,#f2cd67 48%,#d8a63d 100%);
  -webkit-background-clip:text;
  background-clip:text;
  -webkit-text-fill-color:transparent;
  -webkit-text-stroke:1px rgba(226,182,78,.55);
  filter:none;
}

.grade-A .result-grade-anchor,
.ending-intro-grade.grade-A{
  color:#e8a8c4;
  background:linear-gradient(180deg,#fff0f6 0%,#e8a8c4 48%,#d988b0 100%);
  -webkit-background-clip:text;
  background-clip:text;
  -webkit-text-fill-color:transparent;
  -webkit-text-stroke:1px rgba(219,141,178,.50);
  filter:none;
}

.grade-B .result-grade-anchor,
.ending-intro-grade.grade-B{
  color:#bda9eb;
  background:linear-gradient(180deg,#f4efff 0%,#bda9eb 48%,#9c88d8 100%);
  -webkit-background-clip:text;
  background-clip:text;
  -webkit-text-fill-color:transparent;
  -webkit-text-stroke:1px rgba(162,140,219,.50);
  filter:none;
}

.grade-C .result-grade-anchor,
.ending-intro-grade.grade-C{
  color:#a8cbe8;
  background:linear-gradient(180deg,#eef8ff 0%,#a8cbe8 48%,#7faed1 100%);
  -webkit-background-clip:text;
  background-clip:text;
  -webkit-text-fill-color:transparent;
  -webkit-text-stroke:1px rgba(128,175,209,.45);
  filter:none;
}

.grade-D .result-grade-anchor,
.ending-intro-grade.grade-D{
  color:#d8d4dd;
  background:linear-gradient(180deg,#fafafa 0%,#d8d4dd 48%,#bbb4c2 100%);
  -webkit-background-clip:text;
  background-clip:text;
  -webkit-text-fill-color:transparent;
  -webkit-text-stroke:1px rgba(188,180,196,.45);
  filter:none;
}
.ending-intro-grade{font-family:"Orbitron",sans-serif;font-size:100px;font-weight:900;line-height:1;letter-spacing:-4px;opacity:0;transform:none;transition:opacity .35s ease;text-shadow:none}
.ending-intro-grade.show{opacity:1}
.score-wrap{position:relative;z-index:2;transform:none!important;will-change:auto;display:flex;flex-direction:column;align-items:center;justify-content:center;min-width:320px;margin-bottom:6px}

.result-copy-title{
  min-width:0;
  padding-top:14px;
}

.result-copy-title h1{
  margin:0 0 14px;
  font-family:"Noto Sans KR",sans-serif;
  font-size:42px;
  line-height:1.15;
  color:#5f4a67;
  font-weight:800;
  letter-spacing:-.03em;
  text-shadow:none;
}

.result-copy-title p{margin:0;max-width:420px;font-family:"Noto Sans KR",sans-serif;font-size:16px;line-height:1.9;color:#7b6677;font-weight:500;word-break:keep-all;text-shadow:none;}
.result-copy-badges{display:none}
.result-info-wrap{margin-top:2px;display:flex;flex-direction:column;gap:12px}
.result-panel-card{
  width:100%;
  padding:14px 14px 12px;
  border-radius:18px;
  background:rgba(255,255,255,.42);
  border:1px solid rgba(255,255,255,.55);
  box-shadow:0 10px 28px rgba(70,28,88,.10),0 0 0 1px rgba(255,255,255,.12) inset;
  backdrop-filter:blur(10px);
  -webkit-backdrop-filter:blur(10px);
}
.score-mini{width:100%;min-height:0}
.score-mini-row{display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap;margin-bottom:2px}
.score-mini-k{margin:0;font-family:"Orbitron",sans-serif;font-size:12px;font-weight:800;color:#3d2a38;letter-spacing:.02em}
.score-mini-link{font-size:11px;color:#a05078;text-decoration:none;font-weight:700;border-bottom:1px solid rgba(255,95,162,.35);white-space:nowrap}
.score-mini-link:hover{color:#ff5fa2;border-bottom-color:rgba(255,95,162,.55)}
.score-mini-val{font-family:"Orbitron",sans-serif;font-size:26px;font-weight:900;color:#ff5fa2;line-height:1.15;font-variant-numeric:tabular-nums}
.score-mini-max{font-size:13px;font-weight:800;color:#9a8894;margin-left:2px}
.score-mini-bar{margin-top:6px;height:7px;border-radius:999px;background:rgba(212,184,206,.40);overflow:hidden}
.score-mini-bar-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,#ff86bc 0%,#ff5fa2 45%,#caa4ff 100%)}
.score-mini-note{margin:8px 0 0;font-size:11px;line-height:1.5;color:#8a7281;word-break:keep-all}
.ranking-empty{padding:16px 10px;text-align:center;font-size:13px;color:#7f6679}
.result-visual{
  position:relative;
  align-self:stretch;
  min-height:0;
  min-width:0;
  display:flex;
  flex-direction:column;
  width:100%;
  max-width:100%;
  height:100%;
  padding-top:22px;
  box-sizing:border-box;
  overflow:hidden;
}
.member-quad-wrap{
  flex:1 1 auto;
  width:100%;
  min-height:0;
  max-width:100%;
  display:flex;
  flex-direction:column;
  padding:0;
  box-sizing:border-box;
}
.member-quad-grid{
  flex:1 1 auto;
  display:grid;
  grid-template-columns:repeat(2,minmax(0,1fr));
  grid-template-rows:1fr 1fr;
  gap:8px;
  min-height:0;
  height:100%;
}
.member-quad-card{
  position:relative;
  display:flex;
  flex-direction:column;
  min-height:0;
  height:100%;
  max-width:100%;
  border-radius:16px;
  overflow:hidden;
  background:linear-gradient(180deg,rgba(255,255,255,.32),rgba(255,250,252,.22));
  border:1px solid rgba(255,255,255,.38);
  box-shadow:0 8px 20px rgba(70,28,88,.10);
}
.member-quad-photo{
  position:relative;
  flex:1 1 0;
  width:100%;
  min-height:64px;
  background:rgba(248,236,244,.55);
  overflow:hidden;
  display:flex;
  align-items:center;
  justify-content:center;
}
.member-quad-photo img{
  display:block;
  max-width:100%;
  max-height:100%;
  width:auto;
  height:auto;
  object-fit:contain;
  object-position:center center;
}
.member-quad-fallback{
  width:100%;
  height:100%;
  min-height:64px;
  display:flex;
  align-items:center;
  justify-content:center;
  font-size:28px;
  color:rgba(255,255,255,.75);
  background:rgba(255,255,255,.10);
}
.member-quad-rank{
  position:absolute;
  top:6px;
  left:6px;
  z-index:2;
  width:22px;
  height:22px;
  border-radius:999px;
  display:flex;
  align-items:center;
  justify-content:center;
  background:rgba(255,210,235,.94);
  color:#8b4168;
  font-family:"Orbitron",sans-serif;
  font-size:10px;
  font-weight:900;
  box-shadow:0 4px 12px rgba(98,32,92,.15);
}
.member-quad-bottom{
  flex-shrink:0;
  display:flex;
  flex-direction:column;
  gap:5px;
  padding:7px 9px 9px;
  background:linear-gradient(180deg,rgba(255,255,255,.55),rgba(255,248,252,.75));
}
.member-quad-name{
  margin:0;
  font-size:13px;
  font-weight:900;
  color:#2f1a2a;
  line-height:1.2;
  white-space:nowrap;
  overflow:hidden;
  text-overflow:ellipsis;
}
.member-quad-ability{
  width:100%;
}
.member-quad-ability-label{
  display:flex;
  justify-content:space-between;
  align-items:center;
  margin-bottom:3px;
  font-size:8px;
  font-weight:800;
  letter-spacing:.04em;
  color:#8a7281;
  text-transform:uppercase;
}
.member-quad-ability-bar{
  position:relative;
  height:5px;
  border-radius:999px;
  background:rgba(212,184,206,.38);
  overflow:hidden;
}
.member-quad-ability-fill{
  height:100%;
  border-radius:999px;
  background:linear-gradient(90deg,#ff86bc 0%,#ff5fa2 50%,#caa4ff 100%);
  min-width:0;
  transition:width .35s ease;
}
.member-quad-row{
  display:flex;
  align-items:center;
  justify-content:space-between;
  gap:8px;
}
.member-quad-total{
  font-family:"Orbitron",sans-serif;
  font-size:15px;
  font-weight:900;
  color:#ff5fa2;
}
.member-quad-total small{
  font-size:9px;
  font-weight:800;
  color:#8a7281;
  margin-left:3px;
}
.member-quad-like{
  display:inline-flex;
  align-items:center;
  gap:4px;
  padding:4px 9px;
  border-radius:999px;
  border:1px solid rgba(255,158,209,.45);
  background:rgba(255,255,255,.75);
  color:#c94b8a;
  font-size:11px;
  font-weight:800;
  cursor:pointer;
  transition:background .15s ease, transform .12s ease;
}
.member-quad-like:hover{background:rgba(255,240,247,.95)}
.member-quad-like:active{transform:scale(.98)}
.member-quad-like.is-on{
  background:linear-gradient(135deg,rgba(255,188,210,.95),rgba(236,173,198,.92));
  color:#fff;
  border-color:rgba(255,255,255,.35);
}
.member-quad-like.is-disabled{
  opacity:.55;
  cursor:not-allowed;
}
.member-quad-like .like-ct{
  font-family:"Orbitron",sans-serif;
  font-size:11px;
  font-weight:800;
  opacity:.9;
}

.scroll-total .tt{font-family:"Orbitron",sans-serif;font-size:14px;color:rgba(255,255,255,.78);letter-spacing:.05em}
.scroll-total .tv{font-family:"Orbitron",sans-serif;font-size:24px;font-weight:900;color:#fff;line-height:1}
.metric-wrap{margin:20px 0 0;padding:14px 0 0;position:relative;z-index:2;clear:both;background:linear-gradient(180deg,rgba(251,243,248,.92),rgba(255,250,252,.78));border-radius:16px}
.metric-wrap::before,.metric-row::after{content:"";position:absolute;left:50%;transform:translateX(-50%);width:90%;height:4px;background:linear-gradient(90deg,rgba(255,255,255,0) 0%,var(--grade-line-sub) 20%,var(--grade-line-main) 35%,rgba(255,255,255,.95) 50%,var(--grade-line-main) 65%,var(--grade-line-sub) 80%,rgba(255,255,255,0) 100%);box-shadow:0 0 6px var(--grade-line-sub),0 0 10px var(--grade-line-main),0 0 14px var(--grade-line-glow)}
.metric-wrap::before{top:0}
.metric-row::after{bottom:0}
.metric-row{display:grid;grid-template-columns:repeat(4, minmax(0, 1fr));gap:0;position:relative;padding-bottom:12px}
.metric-box{position:relative;text-align:center;padding:6px 12px 8px}
.metric-box + .metric-box::before{content:"";position:absolute;left:0;top:20%;bottom:20%;width:1px;background:linear-gradient(180deg, rgba(255,255,255,0), rgba(232,186,210,.7), rgba(255,255,255,0));opacity:.6}
.metric-box .k{font-family:"Orbitron",sans-serif;font-size:18px;letter-spacing:.05em;color:#b79ab0;margin-bottom:8px}
.metric-box .v{display:inline-block;min-width:min(100%,140px);min-height:40px;padding:4px 10px;background:rgba(255,244,248,.62);font-family:"Orbitron",sans-serif;font-size:22px;font-weight:900;color:#341d31;white-space:nowrap}
.reward-v{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px;font-size:18px;line-height:1.25;padding:8px 10px}
.metric-box--reward .v{white-space:normal;max-width:min(100%,360px);text-align:center}
.reward-pair{font-family:"Orbitron",sans-serif;font-weight:800;color:#341d31;letter-spacing:.06em}
.reward-pair strong{font-size:24px;font-weight:900}
.reward-applied-tag{font-size:11px;font-weight:800;color:#7c6b88;font-family:"Noto Sans KR",sans-serif}
.bottom-actions{display:flex;justify-content:center;gap:16px;margin-top:18px;flex-wrap:wrap;padding-bottom:8px}
.bottom-btn{display:inline-flex;align-items:center;justify-content:center;min-width:150px;height:56px;padding:0 24px;border-radius:999px;border:1px solid rgba(180,144,167,.18);background:rgba(255,255,255,.78);color:#442a3f;text-decoration:none;font-size:18px;font-weight:900;box-shadow:0 10px 26px rgba(129,95,142,.10);transition:transform .18s ease, box-shadow .18s ease}
.bottom-btn:hover{transform:translateY(-2px);box-shadow:0 16px 34px rgba(129,95,142,.14)}
.bottom-btn.primary{background:linear-gradient(135deg, rgba(255,188,210,.96), rgba(236,173,198,.94));color:#fff}
.ending-intro{position:fixed;inset:0;z-index:9999;display:block;background:radial-gradient(circle at center, rgba(255,248,252,.82), rgba(247,232,243,.92));backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);overflow:hidden;transition:opacity .8s ease, visibility .8s ease}
.ending-intro.hide{opacity:0;visibility:hidden;pointer-events:none}
.ending-intro-inner{position:absolute;top:18%;left:50%;transform:translateX(-50%);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px;min-width:420px;padding:40px 56px;border-radius:32px;background:linear-gradient(180deg, rgba(255,255,255,.42), rgba(255,245,250,.22));box-shadow:0 0 30px rgba(255,200,230,.25),0 0 60px rgba(200,170,255,.18),inset 0 1px 0 rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.34);opacity:0;transition:opacity .35s ease}
.ending-intro-inner.show{opacity:1}
.ending-intro-score-label{font-family:"Orbitron",sans-serif;font-size:24px;letter-spacing:.08em;color:#b994b7}
.ending-intro-score-row{display:flex;align-items:baseline;justify-content:center;gap:4px;flex-wrap:wrap}
.ending-intro-score{font-family:"Orbitron",sans-serif;font-size:120px;font-weight:900;line-height:1;color:#2f1a2a;text-align:center;min-width:0;display:inline-block;font-variant-numeric:tabular-nums;font-feature-settings:"tnum";transform:translateZ(0);will-change:contents}
.ending-intro-score-suffix{font-family:"Orbitron",sans-serif;font-size:clamp(28px,5vw,44px);font-weight:800;color:#7f6679;letter-spacing:.04em}
.ending-intro-grade{font-family:"Orbitron",sans-serif;font-size:136px;font-weight:900;line-height:1;opacity:0;transform:scale(.9);transition:opacity .55s ease, transform .55s ease, color .35s ease, text-shadow .35s ease}
.ending-intro-grade.show{opacity:1;transform:scale(1)}
.ending-intro-grade.grade-S{color:#ffd700;text-shadow:0 0 16px rgba(255,215,0,.45),0 0 30px rgba(255,215,0,.22)}
.ending-intro-grade.grade-A{color:#ff9ed1;text-shadow:0 0 16px rgba(255,158,209,.45),0 0 30px rgba(255,158,209,.22)}
.ending-intro-grade.grade-B{color:#c6a8ff;text-shadow:0 0 16px rgba(198,168,255,.45),0 0 30px rgba(198,168,255,.22)}
.ending-intro-grade.grade-C{color:#9ed0ff;text-shadow:0 0 16px rgba(158,208,255,.45),0 0 30px rgba(158,208,255,.22)}
.ending-intro-grade.grade-D{color:#f5f5f5;text-shadow:0 0 16px rgba(255,255,255,.34),0 0 30px rgba(255,255,255,.16)}
.flying-grade{position:fixed;display:flex;align-items:center;justify-content:center;margin:0;z-index:10002;pointer-events:none;will-change:left, top, width, height, font-size, opacity;transition:left 1.05s cubic-bezier(.22,.9,.2,1), top 1.05s cubic-bezier(.22,.9,.2,1), width 1.05s cubic-bezier(.22,.9,.2,1), height 1.05s cubic-bezier(.22,.9,.2,1), font-size 1.05s cubic-bezier(.22,.9,.2,1), opacity .28s ease}
.score-wrap{position:relative;z-index:2;transform:none!important;will-change:auto;display:flex;flex-direction:column;align-items:center;justify-content:center;min-width:320px}
@media (max-width:1280px){.result-page{width:min(100% - 28px, 1320px);padding-top:96px}.result-hero{grid-template-columns:1fr;gap:24px;align-items:stretch;min-height:auto}.result-left-stack{min-height:0}.result-visual{padding-top:8px;height:auto;min-height:min(52vh,420px)}.member-quad-wrap{min-height:min(48vh,380px)}.member-quad-grid{grid-template-rows:1fr 1fr;min-height:min(44vh,340px)}.result-grade-anchor{top:18px;left:22px;font-size:72px}}
@media (max-width:760px){.result-page{padding:92px 0 28px}.result-hero{grid-template-columns:1fr;gap:18px;align-items:stretch}.result-left-stack{padding-top:8px;min-height:0}.result-visual{padding-top:4px;height:auto;min-height:280px}.result-copy-main{gap:14px}.result-copy-title h1{font-size:32px}.result-copy-title p{font-size:15px;line-height:1.65}.member-quad-grid{grid-template-columns:1fr;grid-template-rows:repeat(4,minmax(0,auto));min-height:0;height:auto}.member-quad-wrap{flex:0 1 auto;min-height:0}.member-quad-card{height:auto;min-height:200px}.member-quad-photo{flex:0 0 auto;min-height:112px;height:112px;max-height:112px}.metric-wrap{margin-top:16px;padding-top:12px}.metric-row{grid-template-columns:1fr}.metric-box + .metric-box::before{display:none}.metric-box{padding:12px 12px 14px}.bottom-btn{min-width:132px;height:52px;font-size:16px}.ending-intro-inner{min-width:300px;padding:30px 26px}.ending-intro-score-label{font-size:18px}.ending-intro-score{font-size:84px}.ending-intro-score-suffix{font-size:22px}.ending-intro-grade{font-size:100px}.result-grade-anchor{top:16px;left:18px;font-size:58px}}
.ending-trend-wrap{
  width:100%;
  margin-top:0;
}

.ending-trend-head{
  display:flex;
  flex-direction:column;
  align-items:flex-start;
  justify-content:flex-start;
  gap:2px;
  margin:12px 0 6px;
  padding-left:2px;
}

.ending-trend-head .ending-trend-title{
  font-size:13px;
  font-weight:800;
  letter-spacing:1px;
  color:#2a223d;
  opacity:.9;
}

.ending-trend-head .ending-trend-sub{
  font-size:11px;
  font-weight:700;
  color:#6b5a78;
  letter-spacing:.02em;
}
.ending-trend-legend{
  font-size:10px;
  font-weight:700;
  color:#7f6e8c;
  margin-top:4px;
  line-height:1.35;
}
.ending-trend-legend .lg-grey{display:inline-block;width:10px;height:8px;border-radius:2px;background:rgba(168,170,182,.72);vertical-align:middle;margin-right:4px}
.ending-trend-legend .lg-color{display:inline-block;width:10px;height:8px;border-radius:2px;background:linear-gradient(90deg,#ff86bc,#caa4ff);vertical-align:middle;margin:0 4px 0 10px}

.ending-trend-box{
  position:relative;
  width:100%;
  height:96px;
  background:transparent;
  border:none;
  border-radius:0;
  overflow:hidden;
}

.ending-trend-box canvas{
  display:block;
  width:100% !important;
  height:100% !important;
}
</style>
</head>

<c:set var="gradeClass" value="grade-d" />
<c:choose>
  <c:when test="${ending.grade eq 'S'}"><c:set var="gradeClass" value="grade-s" /></c:when>
  <c:when test="${ending.grade eq 'A'}"><c:set var="gradeClass" value="grade-a" /></c:when>
  <c:when test="${ending.grade eq 'B'}"><c:set var="gradeClass" value="grade-b" /></c:when>
  <c:when test="${ending.grade eq 'C'}"><c:set var="gradeClass" value="grade-c" /></c:when>
  <c:otherwise><c:set var="gradeClass" value="grade-d" /></c:otherwise>
</c:choose>

<body class="${gradeClass}">
<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>

<div class="ending-intro" id="endingIntro">
  <div class="ending-intro-inner" id="endingIntroInner">
    <div class="score-wrap">
      <div class="ending-intro-score-label">TOTAL SCORE</div>
      <div class="ending-intro-score-row">
        <span class="ending-intro-score" id="introTotalScore">0</span><span class="ending-intro-score-suffix">/1000</span>
      </div>
    </div>
    <div class="ending-intro-grade" id="introGrade">${ending.grade}</div>
  </div>
</div>

<div class="result-page" id="resultPage">
  <div class="result-shell grade-${ending.grade}">
    <section class="result-top">
      <div class="result-hero">
        <div class="result-left-stack">
          <div class="result-copy-panel">
            <div class="result-grade-anchor grade-${ending.grade}" id="finalGrade">${ending.grade}</div>
            <div class="result-copy-inner">
              <div class="result-copy-main">
                <div class="result-copy-title">
                  <h1>${ending.gradeLabel}</h1>
                  <p>
                    현재 조합의 강점은 <strong>${chemistry.chemLabel}</strong> 흐름입니다.<br/>
                    ${ending.endingReason}
                  </p>
                </div>
              </div>
              <div class="result-copy-badges">
                <div class="result-chip">TOTAL SCORE ${ending.totalScore}/1000</div>
                <div class="result-chip">
                  <c:choose>
                    <c:when test="${ending.groupType eq 'MIXED'}">혼성 그룹</c:when>
                    <c:when test="${ending.groupType eq 'MALE'}">남성 그룹</c:when>
                    <c:otherwise>여성 그룹</c:otherwise>
                  </c:choose>
                </div>
                <div class="result-chip">${chemistry.chemLabel}</div>
              </div>
            </div>
          </div>

          <section class="result-info-wrap">
            <div class="result-panel-card">
              <div class="score-mini">
                <c:choose>
                  <c:when test="${ending != null}">
                    <div class="score-mini-row">
                      <h3 class="score-mini-k">최종 점수</h3>
                      <a class="score-mini-link" href="${ctx}/guide#play-score">플레이 점수 산출 방식</a>
                    </div>
                    <c:set var="finalBarPct" value="${ending.totalScore >= 1000 ? 100 : (ending.totalScore * 100) / 1000}" />
                    <div class="score-mini-val">${ending.totalScore}<span class="score-mini-max">/1000</span></div>
                    <div class="score-mini-bar" title="만점 대비 비율"><div class="score-mini-bar-fill" style="width:${finalBarPct}%"></div></div>
                    <p class="score-mini-note">능력치 합 → 케미(%) → 진행 턴 보정 순입니다. 단계별 식과 예시는 가이드를 참고하세요.</p>
                  </c:when>
                  <c:otherwise>
                    <div class="ranking-empty">점수 정보를 불러올 수 없습니다.</div>
                  </c:otherwise>
                </c:choose>
              </div>
            </div>

            <div class="result-panel-card">
              <div class="ending-trend-wrap">
                <div class="ending-trend-head">
                  <span class="ending-trend-title">팀 능력치 요약</span>
                  <span class="ending-trend-sub">막대 비교 · 각 스탯 만점 100 (팀원 평균, 내부 원점수 0~20을 환산)</span>
                  <div class="ending-trend-legend" aria-hidden="true">
                    <span class="lg-grey"></span>회색=전체 연습생 평균
                    <span class="lg-color"></span>컬러=이번 팀
                  </div>
                </div>

                <div class="ending-trend-box">
                  <canvas id="memberTrendChart"></canvas>
                </div>
              </div>
            </div>
          </section>
        </div>

        <div class="result-visual">
          <div class="member-quad-wrap" id="memberQuadWrap">
            <div class="member-quad-grid">
              <c:if test="${empty endingTopFour}">
                <div class="ranking-empty" style="grid-column:1/-1;text-align:center;padding:24px 12px;">표시할 멤버가 없습니다.</div>
              </c:if>
              <c:forEach var="m" items="${endingTopFour}" varStatus="st">
                <c:set var="mTotal" value="${m.vocal + m.dance + m.star + m.mental + m.teamwork}" />
                <c:set var="mAvg" value="${(mTotal - (mTotal mod 5)) / 5}" />
                <c:set var="abilityPct" value="${mAvg}" />
                <c:set var="tid" value="${m.traineeId}" />
                <c:set var="likeCnt" value="${empty endingLikeCounts[tid] ? 0 : endingLikeCounts[tid]}" />
                <c:set var="likeCntLabel" value="${empty endingLikeLabels[tid] ? '0' : endingLikeLabels[tid]}" />
                <article class="member-quad-card">
                  <div class="member-quad-photo">
                    <div class="member-quad-rank">${st.index + 1}</div>
                    <c:choose>
                      <c:when test="${not empty m.imagePath}">
                        <img src="${ctx}${m.imagePath}" alt="${m.name}" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';" />
                        <div class="member-quad-fallback" style="display:none;"><i class="fas fa-user"></i></div>
                      </c:when>
                      <c:otherwise>
                        <div class="member-quad-fallback"><i class="fas fa-user"></i></div>
                      </c:otherwise>
                    </c:choose>
                  </div>
                  <div class="member-quad-bottom">
                    <h3 class="member-quad-name">${m.name}</h3>
                    <div class="member-quad-ability" title="다섯 능력치 평균 · 최대 20">
                      <div class="member-quad-ability-label">
                        <span>최종 능력치</span>
                        <span>${mAvg} / 100</span>
                      </div>
                      <div class="member-quad-ability-bar">
                        <div class="member-quad-ability-fill" style="width:${abilityPct}%"></div>
                      </div>
                    </div>
                    <div class="member-quad-row">
                      <div class="member-quad-total">${mAvg}<small>AVG</small></div>
                      <c:choose>
                        <c:when test="${endingLikeLoggedIn and not empty tid}">
                          <button type="button" class="member-quad-like js-trainee-like ${endingLikedTraineeIds.contains(tid) ? 'is-on' : ''}"
                            data-tid="${tid}" data-count="${likeCnt}">
                            <i class="${endingLikedTraineeIds.contains(tid) ? 'fas' : 'far'} fa-heart" aria-hidden="true"></i>
                            <span class="like-ct js-like-count">${likeCntLabel}</span>
                          </button>
                        </c:when>
                        <c:otherwise>
                          <button type="button" class="member-quad-like is-disabled" disabled title="로그인 후 좋아요를 누를 수 있습니다.">
                            <i class="far fa-heart" aria-hidden="true"></i>
                            <span class="like-ct js-like-count">${likeCntLabel}</span>
                          </button>
                        </c:otherwise>
                      </c:choose>
                    </div>
                  </div>
                </article>
              </c:forEach>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="metric-wrap">
      <div class="metric-row">
        <div class="metric-box">
          <div class="k">TOTAL SCORE</div>
          <div class="v" id="totalScore" data-score="${ending.totalScore}">${ending.totalScore}/1000</div>
        </div>
        <div class="metric-box">
          <div class="k">RANKING</div>
          <div class="v">
            <c:choose>
              <c:when test="${myRank != null && myRank > 0}">${myRank}위</c:when>
              <c:otherwise>-</c:otherwise>
            </c:choose>
          </div>
        </div>
        <div class="metric-box metric-box--reward">
          <div class="k">REWARD</div>
          <div class="v reward-v">
            <span class="reward-pair" title="런 DB 총 팬 · 등급 EXP는 ⌊팬÷10⌋(게임 지급 규칙과 동일)">
              팬 <strong><c:out value="${rewardFanTotal}"/></strong> → EXP <strong><c:out value="${rewardExpFromFans}"/></strong>
            </span>
            <c:if test="${ending.memberRankReward.alreadyApplied}">
              <span class="reward-applied-tag">※ 이 런 보상은 이미 계정에 반영됨 (중복 지급 없음)</span>
            </c:if>
          </div>
        </div>
        <div class="metric-box">
          <div class="k">GROUP TYPE</div>
          <div class="v"><c:choose><c:when test="${ending.groupType eq 'MIXED'}">혼성</c:when><c:when test="${ending.groupType eq 'MALE'}">남성</c:when><c:otherwise>여성</c:otherwise></c:choose></div>
        </div>
      </div>
    </section>

    <div class="bottom-actions">
      <a href="${ctx}/main" class="bottom-btn">메인페이지</a>
      <a href="${ctx}/main?groupSelect=1" class="bottom-btn primary">다시 플레이</a>
      <a href="${ctx}/game/run/${ending.runId}/ranking" class="bottom-btn">랭킹 보기</a>
    </div>
  </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function(){
  if ("scrollRestoration" in history) history.scrollRestoration = "manual";
  window.scrollTo(0, 0);
  document.documentElement.scrollTop = 0;
  document.body.scrollTop = 0;

  const intro = document.getElementById("endingIntro");
  const introInner = document.getElementById("endingIntroInner");
  const introScore = document.getElementById("introTotalScore");
  const introGrade = document.getElementById("introGrade");
  const finalScore = document.getElementById("totalScore");
  const resultPage = document.getElementById("resultPage");
  const finalGrade = document.getElementById("finalGrade");

  if(!intro || !introInner || !introScore || !introGrade || !finalScore || !resultPage || !finalGrade){
    if(resultPage) resultPage.classList.add("show");
    return;
  }

  const targetScore = parseInt(finalScore.getAttribute("data-score") || finalScore.textContent.replace(/\D.*/, ""), 10) || 0;
  const gradeText = introGrade.textContent.trim();

  finalScore.textContent = targetScore + "/1000";
  finalGrade.style.opacity = "0";
  introGrade.classList.add("grade-" + gradeText);

  function wait(ms){ return new Promise(resolve => setTimeout(resolve, ms)); }
  function nextFrame(){ return new Promise(resolve => requestAnimationFrame(() => resolve())); }

  function animateCountUp(target){
    return new Promise((resolve) => {
      let current = 0;
      const step = Math.max(1, Math.ceil(target / 45));
      function tick(){
        current += step;
        if(current >= target){
          introScore.textContent = target;
          resolve();
          return;
        }
        introScore.textContent = current;
        requestAnimationFrame(tick);
      }
      introScore.textContent = "0";
      requestAnimationFrame(tick);
    });
  }

  async function moveGradeToFinalSmooth(){
    const introRect = introGrade.getBoundingClientRect();
    const flying = introGrade.cloneNode(true);
    flying.classList.remove("show");
    flying.classList.add("flying-grade");

    const introStyle = window.getComputedStyle(introGrade);
    flying.style.left = introRect.left + "px";
    flying.style.top = introRect.top + "px";
    flying.style.width = introRect.width + "px";
    flying.style.height = introRect.height + "px";
    flying.style.fontSize = introStyle.fontSize;
    flying.style.lineHeight = introStyle.lineHeight;
    flying.style.opacity = "1";
    document.body.appendChild(flying);

    introGrade.style.opacity = "0";
    introGrade.style.visibility = "hidden";
    introInner.style.opacity = "0";
    resultPage.classList.add("show");

    await nextFrame();
    await nextFrame();

    const finalRect = finalGrade.getBoundingClientRect();
    const finalStyle = window.getComputedStyle(finalGrade);
    flying.style.left = finalRect.left + "px";
    flying.style.top = finalRect.top + "px";
    flying.style.width = finalRect.width + "px";
    flying.style.height = finalRect.height + "px";
    flying.style.fontSize = finalStyle.fontSize;
    flying.style.lineHeight = finalStyle.lineHeight;

    await wait(1080);
    finalGrade.style.opacity = "1";
    flying.style.opacity = "0";
    await wait(220);

    flying.remove();
    intro.classList.add("hide");
    finalScore.textContent = targetScore + "/1000";
  }

  async function runIntro(){
    introInner.classList.add("show");
    await wait(420);
    await animateCountUp(targetScore);
    await wait(220);
    introGrade.classList.add("show");
    await wait(900);
    await moveGradeToFinalSmooth();
  }

  runIntro();
});

window.addEventListener("load", function(){
  window.scrollTo(0, 0);
  document.documentElement.scrollTop = 0;
  document.body.scrollTop = 0;
});
</script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<script>
(function(){
  function drawMemberTrendChart(){
    var canvas = document.getElementById('memberTrendChart');
    if (!canvas || typeof Chart === 'undefined') return;

    var prev = Chart.getChart(canvas);
    if (prev) prev.destroy();

    /** 팀·전체 평균(0~20)을 서버에서 ×5한 뒤 주입 — 막대는 0~100 만점 스케일 */
    var vals = [
      ${teamAvgVocal},
      ${teamAvgDance},
      ${teamAvgStar},
      ${teamAvgMental},
      ${teamAvgTeamwork}
    ];
    var gvals = [
      ${globalAvgVocal},
      ${globalAvgDance},
      ${globalAvgStar},
      ${globalAvgMental},
      ${globalAvgTeamwork}
    ];

    new Chart(canvas, {
      type: 'bar',
      data: {
        labels: ['보컬', '댄스', '스타성', '멘탈', '팀워크'],
        datasets: [
          {
            label: '전체 연습생 평균',
            data: gvals,
            backgroundColor: 'rgba(168, 170, 182, 0.88)',
            borderColor: 'rgba(130, 132, 145, 0.35)',
            borderWidth: 1,
            borderRadius: 4,
            borderSkipped: false,
            maxBarThickness: 9,
            order: 0
          },
          {
            label: '이번 팀 평균',
            data: vals,
            backgroundColor: ['rgba(255,111,174,.92)','rgba(122,140,255,.92)','rgba(255,184,107,.94)','rgba(125,224,214,.92)','rgba(197,140,255,.92)'],
            borderColor: ['#e85a9a','#5f73e8','#e8984a','#4fc4b8','#a978e0'],
            borderWidth: 1,
            borderRadius: 5,
            borderSkipped: false,
            maxBarThickness: 9,
            order: 1
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: 'x',
        animation: { duration: 520 },
        interaction: { mode: 'index', intersect: false },
        layout: { padding: { top: 2, right: 2, bottom: 2, left: 2 } },
        datasets: {
          bar: {
            grouped: true,
            categoryPercentage: 0.68,
            barPercentage: 0.88
          }
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: 'rgba(34, 24, 48, 0.92)',
            titleColor: '#fff',
            bodyColor: '#f7eaff',
            borderColor: 'rgba(255,255,255,0.15)',
            borderWidth: 1,
            padding: 9,
            displayColors: true,
            callbacks: {
              title: function(items){ return items.length ? items[0].label : ''; },
              label: function(ctx){
                var v = ctx.parsed.y;
                var t = typeof v === 'number' ? v.toFixed(1) : v;
                var prefix = ctx.dataset.label ? ctx.dataset.label + ': ' : '';
                return prefix + t + ' / 100';
              }
            }
          }
        },
        scales: {
          x: {
            grid: { display: false, drawBorder: false },
            ticks: {
              color: '#5a4a68',
              font: { size: 9, weight: '700' },
              maxRotation: 0,
              autoSkip: false
            }
          },
          y: {
            min: 0,
            max: 100,
            ticks: {
              stepSize: 25,
              color: '#847a98',
              font: { size: 9, weight: '700' },
              padding: 2
            },
            grid: { color: 'rgba(90, 70, 120, 0.10)', drawBorder: false }
          }
        }
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', drawMemberTrendChart);
  } else {
    drawMemberTrendChart();
  }
})();
</script>

<script>
(function(){
  function formatLikeCount(n) {
    n = Math.floor(Number(n));
    if (!isFinite(n) || n < 0) n = 0;
    if (n < 1000) return String(n);
    var k = n / 1000;
    if (k === Math.floor(k)) return Math.floor(k) + 'k';
    return (Math.round(k * 10) / 10) + 'k';
  }
  var root = '${pageContext.request.contextPath}';
  var endingRunId = ${ending.runId};
  document.querySelectorAll('.js-trainee-like').forEach(function(btn){
    btn.addEventListener('click', function(){
      var tid = btn.getAttribute('data-tid');
      if (!tid) return;
      fetch(root + '/trainees/' + tid + '/like?runId=' + encodeURIComponent(endingRunId), {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Accept': 'application/json', 'Content-Type': 'application/json' }
      })
        .then(function(r){ return r.json(); })
        .then(function(data){
          if (!data || data.ok === false) {
            if (data && data.error === 'login_required') {
              alert('로그인 후 이용할 수 있습니다.');
            } else if (data && data.error === 'forbidden') {
              alert('이 플레이에 대한 좋아요만 가능합니다.');
            }
            return;
          }
          if (data.alreadyLikedThisRun) {
            alert('이번 플레이에서는 이미 좋아요를 눌렀습니다.');
            btn.classList.add('is-on');
            var ic = btn.querySelector('i');
            if (ic) { ic.classList.remove('far'); ic.classList.add('fas'); }
            return;
          }
          if (data.added) {
            btn.classList.add('is-on');
            var c = btn.querySelector('.js-like-count');
            if (c && typeof data.totalLikes === 'number') c.textContent = formatLikeCount(data.totalLikes);
            var icon = btn.querySelector('i');
            if (icon) {
              icon.classList.remove('far');
              icon.classList.add('fas');
            }
          }
        })
        .catch(function(){});
    });
  });
})();
</script>

</body>
</html>
