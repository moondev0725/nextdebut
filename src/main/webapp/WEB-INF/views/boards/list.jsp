<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="loggedIn" value="${not empty sessionScope.LOGIN_MEMBER}" />

<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>UNIT-X - ${boardTitle}</title>

    <%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
    <c:if test="${(boardType eq 'map' or boardType eq 'fanmeeting') and not empty kakaoMapJavascriptKey}">
    <script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=${kakaoMapJavascriptKey}&autoload=false" charset="UTF-8"></script>
    </c:if>
    <style>
        /*폰트*/
        @import url('https://fonts.googleapis.com/css2?family=Pretendard:wght@400;600;700;800&display=swap');
        body{
        font-family:'Pretendard', sans-serif;
        }

        html, body{
        min-height:100%;
        }

        body{
        background:
        linear-gradient(rgba(255,255,255,0.6),rgba(255,255,255,0.6)),
        url('/images/ingame-scene-bg.png') center center / cover no-repeat fixed !important;
        }

        body::before,
        body::after,
        .page-main::before,
        .page-main::after{
        display:none !important;
        background:none !important;
        }
        main,
        .container,
        .container.mx-auto,
        main > .container,
        main > div{
        background-color:transparent !important;
        background-image:none !important;
        }
        .badge-report-done { display:inline-flex; align-items:center; font-size:10px; padding:2px 8px; border-radius:999px; font-weight:700;
            background:rgba(220,252,231,0.95); border:1px solid rgba(134,239,172,0.45); color:#166534; vertical-align:middle; margin-right:6px; }
        .badge-report-wait { display:inline-flex; align-items:center; font-size:10px; padding:2px 8px; border-radius:999px; font-weight:700;
            background:rgba(254,243,199,0.9); border:1px solid rgba(251,191,36,0.4); color:#92400e; vertical-align:middle; margin-right:6px; }
        .badge-secret { display:inline-flex; align-items:center; gap:3px; font-size:10px; padding:2px 7px; border-radius:999px;
            background:rgba(100,116,139,0.10); border:1px solid rgba(148,163,184,0.30); color:rgba(100,116,139,0.80); vertical-align:middle; margin-left:6px; }
        .badge-cat { display:inline-flex; align-items:center; font-size:10px; padding:2px 8px; border-radius:999px; font-weight:600; margin-right:6px; vertical-align:middle; }
        .badge-cat.bug { background:rgba(251,191,36,0.15); color:rgba(180,130,0,0.90); border:1px solid rgba(251,191,36,0.30); }
        .badge-cat.report { background:rgba(248,113,113,0.12); color:rgba(185,28,28,0.80); border:1px solid rgba(248,113,113,0.25); }
        .badge-community { display:inline-flex; align-items:center; font-size:10px; padding:2px 8px; border-radius:999px; font-weight:600; margin-right:6px; vertical-align:middle; }
        .badge-community.free { background:rgba(96,165,250,0.12); color:rgba(30,64,175,0.85); border:1px solid rgba(96,165,250,0.35); }
        .badge-community.lounge { background:rgba(96,165,250,0.12); color:rgba(30,64,175,0.85); border:1px solid rgba(96,165,250,0.35); }
        .badge-community.guide { background:rgba(167,139,250,0.12); color:rgba(91,33,182,0.88); border:1px solid rgba(167,139,250,0.35); }
        .pagination{display:flex;justify-content:center;align-items:center;gap:8px;margin-top:24px;flex-wrap:wrap;}

        .page-btn{
        min-width:34px;
        height:34px;
        padding:0 10px;
        display:inline-flex;
        align-items:center;
        justify-content:center;
        border-radius:12px;
        border:1px solid rgba(214,220,232,0.95);
        background:linear-gradient(180deg,rgba(255,255,255,0.88),rgba(248,250,252,0.82));
        color:#7b8798;
        font-size:12px;
        font-weight:700;
        text-decoration:none;
        box-shadow:0 4px 10px rgba(15,23,42,0.04), inset 0 1px 0 rgba(255,255,255,0.9);
        transition:all .18s ease;
        }

        .page-btn:hover{
        transform:translateY(-1px);
        border-color:rgba(244,168,198,0.42);
        background:linear-gradient(180deg,rgba(255,255,255,0.96),rgba(255,245,249,0.92));
        color:#d85b95;
        box-shadow:0 8px 18px rgba(244,168,198,0.14);
        }

        .page-btn.active{
        min-width:36px;
        height:36px;
        border-color:transparent;
        background:linear-gradient(135deg,#f6b3cf 0%,#e8b8ff 100%);
        color:#ffffff;
        font-weight:800;
        box-shadow:0 10px 20px rgba(244,168,198,0.22), 0 0 0 1px rgba(255,255,255,0.22) inset;
        }

        .page-btn.disabled{
        opacity:.38;
        pointer-events:none;
        box-shadow:none;
        filter:saturate(.7);
        }
        .board-filter-bar { display:flex; flex-wrap:wrap; align-items:center; gap:8px; }
        .filter-chip {
            display:inline-flex; align-items:center; gap:6px; padding:8px 18px; border-radius:999px; font-size:13px; font-weight:600;
            border:1px solid rgba(148,163,184,0.35); background:rgba(255,255,255,0.55); color:rgba(71,85,105,0.88);
            text-decoration:none; transition:all 200ms ease;
        }
        .filter-chip:hover { background:rgba(255,255,255,0.92); color:#0f172a; }
        .filter-chip.is-active {
            background:linear-gradient(135deg,rgba(233,176,196,0.88),rgba(204,186,216,0.85));
            color:rgba(20,10,30,0.95); border-color:transparent;
        }
        .board-search-row input[type="search"] {
            flex:1; min-width:180px; max-width:420px; padding:10px 14px; border-radius:12px;
            border:1px solid rgba(148,163,184,0.35); background:rgba(255,255,255,0.75); font-size:14px;
        }
        .board-search-row button[type="submit"] {
            padding:10px 18px; border-radius:12px; font-weight:700; font-size:13px;
            border:1px solid rgba(233,176,196,0.5);
            background:linear-gradient(135deg,rgba(233,176,196,0.9),rgba(204,186,216,0.75));
            color:rgba(20,10,30,0.92); cursor:pointer;
        }
        .board-search-row .search-clear {
            font-size:13px; color:rgba(71,85,105,0.85); text-decoration:underline;
        }
        .badge-board-type {
            display:inline-flex; align-items:center; font-size:10px; padding:2px 8px; border-radius:999px; font-weight:600; margin-right:6px; vertical-align:middle;
            background:rgba(148,163,184,0.12); color:rgba(51,65,85,0.9); border:1px solid rgba(148,163,184,0.28);
        }
        .cast-card {
            border-radius: 20px; border: 1px solid rgba(226,232,240,0.95); background: rgba(255,255,255,0.72);
            padding: 18px 20px; transition: box-shadow 180ms ease, transform 180ms ease;
        }
        .cast-card:hover { box-shadow: 0 12px 32px rgba(15,23,42,0.08); transform: translateY(-2px); }
        .cast-badge {
            display:inline-flex; align-items:center; font-size:10px; font-weight:800; padding:3px 8px; border-radius:999px;
            margin-right:4px; margin-bottom:4px; letter-spacing:0.02em;
        }
        .cast-badge--live { background: rgba(16,185,129,0.12); color: rgb(6,95,70); border: 1px solid rgba(16,185,129,0.25); }
        .cast-badge--soon { background: rgba(59,130,246,0.10); color: rgb(30,64,175); border: 1px solid rgba(59,130,246,0.22); }
        .cast-badge--end { background: rgba(148,163,184,0.12); color: rgb(71,85,105); border: 1px solid rgba(148,163,184,0.25); }
        .cast-fx { background: rgba(233,176,196,0.14); color: rgb(131,24,67); border: 1px solid rgba(233,176,196,0.35); }
        
        .glass-card > *{position:relative;z-index:1;}

        .filter-chip{height:38px;padding:0 18px;border-radius:999px;border:1px solid rgba(210,214,230,0.92);background:linear-gradient(180deg,#ffffff,#f8fafc);color:#64748b;font-weight:700;
/* 🔥 입체 */
box-shadow:0 4px 10px rgba(15,23,42,0.05),inset 0 1px 0 rgba(255,255,255,0.9);transition:all .18s ease;}
.filter-chip:hover{transform:translateY(-1px);box-shadow:0 8px 18px rgba(244,168,198,0.15),inset 0 1px 0 rgba(255,255,255,1);}
.filter-chip:active{transform:translateY(1px);box-shadow:inset 0 2px 6px rgba(0,0,0,0.15);}

        .board-search-row{margin-top:20px;padding:0;background:transparent;border:none;box-shadow:none;}
        .board-search-row input[type="search"]{height:44px;border-radius:14px;border:1px solid rgba(148,163,184,0.24);background:rgba(255,255,255,0.55);box-shadow:none;}
        .board-search-row button[type="submit"]{height:44px;padding:0 18px;border-radius:14px;border:1px solid rgba(233,176,196,0.32);background:rgba(233,176,196,0.22);color:#7c3956;box-shadow:none;}
        .board-search-row button[type="submit"]:hover{background:rgba(233,176,196,0.3);transform:none;}

        table{border-collapse:collapse;border-spacing:0;background:transparent;}
        thead th{font-size:12px;font-weight:700;color:rgba(100,116,139,0.95);border-bottom:1px solid rgba(148,163,184,0.18);}
        tbody tr{
        background:rgba(255,255,255,0.15);
        backdrop-filter:blur(6px);
        }

        tbody tr:hover{background:rgba(255,255,255,0.28);transform:translateX(2px);}
        tbody tr:hover::after{left:120%;opacity:1;}
        tbody tr::after{content:"";position:absolute;top:0;bottom:0;left:-120%;width:45%;background:linear-gradient(115deg,rgba(255,255,255,0) 0%,rgba(255,255,255,0.15) 25%,rgba(255,255,255,0.65) 50%,rgba(255,255,255,0.15) 75%,rgba(255,255,255,0) 100%);transform:skewX(-18deg);pointer-events:none;opacity:0;transition:left .55s ease,opacity .25s ease;}
        tbody td{border-bottom:1px solid rgba(148,163,184,0.12);padding-top:18px!important;padding-bottom:18px!important;}
        tbody td:first-child,tbody td:last-child{border-radius:0;border-left:none;border-right:none;}

td a.underline{
text-decoration:none!important;
color:#334155;
font-weight:500;
transition:all .18s ease;
}

td a.underline:hover{
color:#e93c53;
font-weight:600;
text-shadow:0 0 6px rgba(255,79,163,0.15);
}
.glass-card{
transition:box-shadow .45s cubic-bezier(.22,1,.36,1), transform .35s ease;
box-shadow:
0 18px 40px rgba(15,23,42,0.08),
0 0 18px rgba(255,182,193,0.18),
0 0 38px rgba(196,181,253,0.12),
inset 0 1px 0 rgba(255,255,255,0.6);
}

.glass-card:hover{
transform:translateY(-2px);
box-shadow:
0 24px 60px rgba(15,23,42,0.12),
0 0 26px rgba(255,182,193,0.28),
0 0 60px rgba(196,181,253,0.18),
inset 0 1px 0 rgba(255,255,255,0.6);
}
.glass-card:hover::before{
opacity:1;
transition:opacity .4s ease;
}
.glass-card::before{content:"";position:absolute;inset:0;border-radius:inherit;background:radial-gradient(circle at 18% 12%,rgba(244,168,198,0.10),transparent 28%),radial-gradient(circle at 82% 18%,rgba(196,181,253,0.08),transparent 24%);pointer-events:none;}
.glass-card>*{position:relative;z-index:1;}

h1.font-orbitron{
background:linear-gradient(#eb4c86be);
-webkit-background-clip:text;
-webkit-text-fill-color:transparent;

/* 🔥 살짝 선명하게 */
filter:contrast(1.1);
}
h1.font-orbitron + p{margin-top:10px;color:rgba(100,116,139,0.92)!important;font-size:15px;}

.board-filter-bar{gap:10px;margin-top:24px!important;}
.filter-chip{
height:38px;
padding:0 18px;
border-radius:999px;
border:1px solid rgba(210,214,230,0.92);
background:linear-gradient(180deg,#ffffff,#f8fafc);
color:#64748b;
font-weight:700;
box-shadow:0 4px 10px rgba(15,23,42,0.05),inset 0 1px 0 rgba(255,255,255,0.9);
transition:all .18s ease;
}
.filter-chip:hover{
background:linear-gradient(180deg,#ffffff,#fff7fb);
border-color:rgba(233,176,196,0.34);
color:#475569;
transform:translateY(-1px);
box-shadow:0 8px 18px rgba(244,168,198,0.15),inset 0 1px 0 rgba(255,255,255,1);
}
.filter-chip.is-active{
background:linear-gradient(135deg,#f6b3cf 0%,#e8b8ff 100%);
border-color:transparent;
color:#5b2d46;
box-shadow:0 10px 20px rgba(233,176,196,0.18),inset 0 1px 0 rgba(255,255,255,0.5);
}
.board-search-row{margin-top:18px!important;display:flex;align-items:center;gap:8px;padding:0;background:transparent;border:none;box-shadow:none;}
.board-search-row input[type="search"]{height:46px;border-radius:16px;border:1px solid rgba(209,213,219,0.95);background:rgba(255,255,255,0.74);padding:0 16px;box-shadow:inset 0 1px 2px rgba(255,255,255,0.42);}
.board-search-row input[type="search"]:focus{outline:none;border-color:rgba(233,176,196,0.42);box-shadow:0 0 0 4px rgba(244,168,198,0.10);}
.board-search-row button[type="submit"]{
height:46px;
padding:0 20px;
border-radius:16px;
border:1px solid rgba(233,176,196,0.30);
background:linear-gradient(135deg,#fbcfe8,#ddd6fe);
color:#7c3956;
font-weight:800;
box-shadow:0 6px 14px rgba(233,176,196,0.18),inset 0 1px 0 rgba(255,255,255,0.7);
transition:all .18s ease;
}
.board-search-row button[type="submit"]:hover{
transform:translateY(-1px);
background:linear-gradient(135deg,#f9d8ea,#e7ddff);
box-shadow:0 10px 20px rgba(233,176,196,0.25);
}
.board-search-row button[type="submit"]:active{
transform:translateY(1px);
box-shadow:inset 0 2px 6px rgba(0,0,0,0.15);
}
table{margin-top:22px;border-collapse:collapse;border-spacing:0;background:transparent;}
thead th{padding-top:14px!important;padding-bottom:14px!important;font-size:12px;font-weight:800;color:rgba(100,116,139,0.95);border-bottom:1px solid rgba(226,232,240,0.9);}
tbody tr{transition:background .18s ease,transform .18s ease,box-shadow .18s ease;}
tbody td{border-bottom:1px solid rgba(226,232,240,0.74);padding-top:18px!important;padding-bottom:18px!important;}

td a.underline{text-decoration:none!important;color:#334155;font-weight:500;transition:color .18s ease,font-weight .18s ease,text-shadow .18s ease;}
td a.underline:hover{color:#e85d96!important;font-weight:600;text-shadow:0 0 4px rgba(232,93,150,0.10);}

.pagination{display:flex;justify-content:center;align-items:center;gap:8px;margin-top:18px;padding-top:2px;flex-wrap:wrap;}
.page-btn{min-width:34px;height:34px;padding:0 10px;display:inline-flex;align-items:center;justify-content:center;border-radius:12px;border:1px solid rgba(214,220,232,0.95);background:linear-gradient(180deg,rgba(255,255,255,0.88),rgba(248,250,252,0.82));color:#7b8798;font-size:12px;font-weight:700;text-decoration:none;box-shadow:0 4px 10px rgba(15,23,42,0.04),inset 0 1px 0 rgba(255,255,255,0.9);transition:all .18s ease;}
.page-btn:hover{transform:translateY(-1px);border-color:rgba(244,168,198,0.42);background:linear-gradient(180deg,rgba(255,255,255,0.96),rgba(255,245,249,0.92));color:#d85b95;box-shadow:0 8px 18px rgba(244,168,198,0.14);}
.page-btn.active{min-width:36px;height:36px;border-color:transparent;background:linear-gradient(135deg,#f6b3cf 0%,#e8b8ff 100%);color:#fff;font-weight:800;box-shadow:0 10px 20px rgba(244,168,198,0.22),0 0 0 1px rgba(255,255,255,0.22) inset;}
.page-btn.disabled{opacity:.38;pointer-events:none;box-shadow:none;filter:saturate(.7);}

.btn-primary{
border-radius:18px!important;
background:linear-gradient(135deg,#f6a5c8 0%,#d8b4fe 100%)!important;
border:1px solid rgba(233,176,196,0.35)!important;
box-shadow:0 10px 22px rgba(233,176,196,0.22),0 2px 4px rgba(0,0,0,0.06),inset 0 1px 0 rgba(255,255,255,0.6);
transition:all .18s ease;
}
.btn-primary:hover{
transform:translateY(-2px);
box-shadow:0 14px 28px rgba(233,176,196,0.28),0 4px 10px rgba(0,0,0,0.08),inset 0 1px 0 rgba(255,255,255,0.7);
}
.btn-primary:active{
transform:translateY(1px);
box-shadow:0 4px 10px rgba(233,176,196,0.18),inset 0 3px 6px rgba(0,0,0,0.15);
}
.board-filter-bar--with-search{display:flex;align-items:center;justify-content:space-between;gap:14px;flex-wrap:nowrap;}
.board-filter-group{display:flex;align-items:center;gap:10px;flex-wrap:wrap;}
.board-search-row--inline{margin-top:0!important;display:flex;align-items:center;gap:8px;flex:0 0 auto;}
.board-search-row--inline form{display:flex;align-items:center;gap:8px;margin:0;}
.board-search-row--inline input[type="search"]{width:260px;min-width:260px;max-width:260px;}
@media (max-width:900px){.board-filter-bar--with-search{flex-wrap:wrap;align-items:flex-start;}.board-search-row--inline{width:100%;}.board-search-row--inline form{width:100%;}.board-search-row--inline input[type="search"]{width:100%;min-width:0;max-width:none;flex:1;}}
.board-table-panel{position:relative;margin-top:30px!important;padding:18px 18px 10px;border-radius:24px;background:linear-gradient(180deg,rgba(255,255,255,0.18),rgba(255,255,255,0.10));border:1px solid rgba(255,255,255,0.38);backdrop-filter:blur(18px);-webkit-backdrop-filter:blur(18px);box-shadow:0 0 0 1px rgba(255,255,255,0.18) inset,0 18px 40px rgba(31,41,55,0.08),0 0 24px rgba(255,182,193,0.18),0 0 54px rgba(196,181,253,0.12);overflow:hidden;}
.board-table-panel::before{content:"";position:absolute;inset:0;border-radius:inherit;padding:1px;background:linear-gradient(135deg,rgba(255,255,255,0.75),rgba(255,182,193,0.45),rgba(196,181,253,0.42),rgba(255,255,255,0.18));-webkit-mask:linear-gradient(#fff 0 0) content-box,linear-gradient(#fff 0 0);-webkit-mask-composite:xor;mask-composite:exclude;pointer-events:none;}
.board-table-panel::after{content:"";position:absolute;left:14px;right:14px;top:56px;height:1px;background:linear-gradient(90deg,rgba(255,255,255,0),rgba(255,182,193,0.55),rgba(196,181,253,0.50),rgba(255,255,255,0));pointer-events:none;}
.board-table-panel table{position:relative;z-index:1;margin-top:0!important;background:transparent;}
.board-table-panel thead th{padding-top:12px!important;padding-bottom:16px!important;font-size:12px;font-weight:800;color:#6b7280;border-bottom:1px solid rgba(255,255,255,0.22);}
.board-table-panel tbody td{border-bottom:1px solid rgba(255,255,255,0.14);}
.board-table-panel tbody tr{position:relative;background:rgba(255,255,255,0.08);transition:background .22s ease,transform .22s ease;}
.board-table-panel tbody tr:hover{background:rgba(255,255,255,0.18);transform:translateX(2px);}
.board-table-panel tbody tr::after{content:"";position:absolute;top:0;bottom:0;left:-120%;width:45%;background:linear-gradient(115deg,rgba(255,255,255,0) 0%,rgba(255,255,255,0.12) 24%,rgba(255,255,255,0.60) 50%,rgba(255,255,255,0.12) 76%,rgba(255,255,255,0) 100%);transform:skewX(-18deg);pointer-events:none;opacity:0;transition:left .58s ease,opacity .22s ease;}
.board-table-panel tbody tr:hover::after{left:120%;opacity:1;}
.board-table-panel tbody tr:first-child td:first-child{border-top-left-radius:14px;}
.board-table-panel tbody tr:first-child td:last-child{border-top-right-radius:14px;}
.board-table-panel tbody tr:last-child td:first-child{border-bottom-left-radius:14px;}
.board-table-panel tbody tr:last-child td:last-child{border-bottom-right-radius:14px;}
/* —— 팬미팅 보드 (맵 + 폼/리스트) —— */
.fm-page-head{margin-bottom:1rem;padding-bottom:0.75rem;border-bottom:1px solid rgba(226,232,240,.85);}
.fm-page-kicker{font-size:10px;letter-spacing:.24em;font-weight:800;color:rgba(124,58,237,.85);font-family:"Orbitron",ui-sans-serif,sans-serif;margin:0 0 .35rem;}
.fm-page-title{font-size:clamp(1.25rem,2.8vw,1.65rem);font-weight:900;letter-spacing:-.02em;color:#0f172a;margin:0;line-height:1.2;}
.fm-page-lead{font-size:13px;color:#64748b;margin:.45rem 0 0;max-width:42rem;line-height:1.55;}
.fm-badges{display:flex;flex-wrap:wrap;gap:6px;margin-top:.65rem;}
.fm-badge{display:inline-flex;align-items:center;gap:4px;padding:4px 10px;border-radius:999px;font-size:11px;font-weight:700;background:rgba(255,255,255,.72);border:1px solid rgba(196,181,253,.45);color:#5b21b6;}
.fm-layout{
  display:grid;grid-template-columns:minmax(0,1.12fr) minmax(0,.88fr);gap:1.25rem;align-items:stretch;
  min-height:min(72vh,900px);
}
.fm-map-col,.fm-board-col{display:flex;flex-direction:column;min-height:0;}
.fm-map-card{
  border:1px solid rgba(226,232,240,.9);background:linear-gradient(165deg,rgba(255,255,255,.97) 0%,rgba(248,250,252,.92) 100%);
  border-radius:1.125rem;padding:1rem 1rem 0.875rem;display:flex;flex-direction:column;gap:0.65rem;height:100%;
  box-shadow:0 1px 0 rgba(255,255,255,.9) inset,0 8px 32px rgba(15,23,42,.05);
}
.fm-map-toolbar{padding:2px 0 4px;}
.fm-filter-form{display:flex;gap:10px;flex-wrap:wrap;align-items:center;width:100%;}
.fm-select{
  flex:1;min-width:120px;max-width:220px;padding:10px 12px;border-radius:12px;
  border:1px solid rgba(203,213,225,.95);background:#fff;font-size:13px;font-weight:600;color:#334155;
  box-shadow:0 1px 2px rgba(15,23,42,.04);
}
.fm-btn{
  padding:10px 16px;border-radius:12px;border:1px solid rgba(167,139,250,.35);
  background:linear-gradient(135deg,rgba(250,232,255,.95),rgba(233,213,255,.88));font-weight:800;font-size:13px;color:#4c1d95;
  box-shadow:0 2px 8px rgba(124,58,237,.12);transition:transform .15s ease,box-shadow .15s ease;
}
.fm-btn:hover{transform:translateY(-1px);box-shadow:0 4px 14px rgba(124,58,237,.18);}
.fm-map-lead{
  font-size:12px;color:#64748b;line-height:1.45;margin:0;padding:0 2px 2px;
}
.fm-map-canvas{
  flex:1 1 auto;width:100%;min-height:clamp(280px,52vh,520px);border-radius:14px;
  border:1px solid rgba(203,213,225,.85);
  box-shadow:inset 0 1px 2px rgba(15,23,42,.06);overflow:hidden;background:#e2e8f0;
}
.fm-board-col{gap:1rem;}
.fm-write-box{
  border-radius:1.125rem;padding:0;overflow:hidden;
  border:1px solid rgba(226,232,240,.95);
  background:linear-gradient(180deg,rgba(255,255,255,.98),rgba(250,245,255,.75));
  box-shadow:0 4px 24px rgba(15,23,42,.04);
}
.fm-write-form{padding:1.1rem 1.15rem 1.15rem;display:flex;flex-direction:column;gap:0.75rem;}
.fm-write-form label{font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:.04em;color:#64748b;margin-bottom:-0.1rem;}
.fm-write-form input,.fm-write-form select,.fm-write-form textarea{
  width:100%;padding:10px 12px;border-radius:12px;border:1px solid rgba(203,213,225,.95);
  background:rgba(255,255,255,.95);font-size:14px;color:#0f172a;
  transition:border-color .15s ease,box-shadow .15s ease;
}
.fm-write-form input:focus,.fm-write-form select:focus,.fm-write-form textarea:focus{
  outline:none;border-color:rgba(167,139,250,.55);box-shadow:0 0 0 3px rgba(167,139,250,.15);
}
.fm-write-form textarea{min-height:88px;resize:vertical;line-height:1.5;}
.fm-form-row2{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
@media (max-width:520px){.fm-form-row2{grid-template-columns:1fr;}}
.fm-picked-field{width:100%;padding:10px 12px;border-radius:12px;border:1px dashed rgba(148,163,184,.55);background:rgba(241,245,249,.65);font-size:13px;color:#475569;}
.fm-submit-wrap{margin-top:.25rem;}
.fm-submit-wrap .btn-primary{
  width:100%;justify-content:center;display:inline-flex;align-items:center;gap:8px;
  padding:12px 16px;border-radius:14px;font-weight:800;font-size:14px;
  background:linear-gradient(135deg,#e879a3,#c4b5fd)!important;border:none!important;
  box-shadow:0 8px 22px rgba(190,24,93,.2)!important;
}
.fm-hint{font-size:11px;color:#64748b;line-height:1.5;}
.fm-link-ghost{
  display:flex;align-items:center;gap:8px;font-size:12px;font-weight:700;color:#6d28d9;
  text-decoration:none;padding:12px 1.15rem 1rem;border-top:1px solid rgba(226,232,240,.85);
  transition:color .15s ease,background .15s ease;
}
.fm-link-ghost:hover{color:#5b21b6;background:rgba(245,243,255,.5);}
.fm-list-head{
  display:flex;align-items:center;justify-content:space-between;gap:10px;padding:4px 4px 2px;
}
.fm-list-head-right{display:flex;flex-direction:column;align-items:flex-end;gap:6px;}
.fm-status-filter{display:flex;gap:6px;flex-wrap:wrap;justify-content:flex-end;}
.fm-status-chip{display:inline-flex;align-items:center;justify-content:center;padding:5px 10px;border-radius:999px;font-size:11px;font-weight:700;text-decoration:none;border:1px solid rgba(203,213,225,.9);background:#fff;color:#475569;}
.fm-status-chip.is-active{border-color:rgba(124,58,237,.32);background:rgba(237,233,254,.7);color:#5b21b6;}
.fm-list-title{font-size:12px;font-weight:800;letter-spacing:.12em;text-transform:uppercase;color:#475569;font-family:"Orbitron",sans-serif;}
.fm-list-count{font-size:12px;font-weight:600;color:#94a3b8;}
.fm-write-inline-btn{
  display:inline-flex;align-items:center;justify-content:center;gap:6px;
  padding:8px 14px;border-radius:999px;font-size:12px;font-weight:800;text-decoration:none;
  background:linear-gradient(135deg,#8b5cf6,#a855f7);color:#fff!important;
  box-shadow:0 6px 16px rgba(124,58,237,.24);transition:transform .15s ease,box-shadow .15s ease;
}
.fm-write-inline-btn:hover{transform:translateY(-1px);box-shadow:0 10px 20px rgba(124,58,237,.3);}
.fm-card-list{
  display:flex;flex-direction:column;gap:10px;overflow:hidden;flex:1 1 auto;min-height:120px;
  max-height:none;padding:2px;
}
.fm-card{
  padding:14px 14px 12px;text-decoration:none;color:#0f172a;transition:box-shadow .2s ease,border-color .2s ease,transform .18s ease;
  border-radius:14px;border:1px solid rgba(226,232,240,.95);background:rgba(255,255,255,.88);
}
.fm-card:hover,.fm-card.is-active{
  border-color:rgba(196,181,253,.55);box-shadow:0 10px 28px rgba(124,58,237,.1);transform:translateY(-2px);
}
.fm-card-head{display:flex;gap:12px;align-items:flex-start;}
.fm-thumb{width:44px;height:44px;border-radius:999px;object-fit:cover;border:2px solid rgba(255,255,255,.9);box-shadow:0 2px 8px rgba(15,23,42,.08);}
.fm-thumb--empty{display:flex;align-items:center;justify-content:center;background:linear-gradient(145deg,#f1f5f9,#e2e8f0);color:#64748b;border:1px solid rgba(203,213,225,.8);}
.fm-trainee-name{font-size:11px;font-weight:800;letter-spacing:.02em;color:#6d28d9;text-transform:uppercase;}
.fm-title{font-size:15px;font-weight:800;line-height:1.35;margin-top:2px;color:#0f172a;}
.fm-meta{display:flex;flex-wrap:wrap;gap:8px 12px;margin-top:10px;font-size:12px;color:#64748b;}
.fm-meta span{display:inline-flex;align-items:center;gap:5px;}
.fm-meta i{font-size:11px;opacity:.75;}
.fm-status{padding:3px 10px;border-radius:999px;font-weight:800;font-size:11px;}
.fm-status--RECRUITING{background:rgba(251,207,232,.5);color:#9d174d;}
.fm-status--PLANNED{background:rgba(191,219,254,.65);color:#1d4ed8;border:1px solid rgba(59,130,246,.2);}
.fm-status--DONE{background:rgba(226,232,240,.85);color:#475569;}
.fm-guest-card{
  padding:1.35rem 1.25rem 1.4rem;text-align:center;
}
.fm-guest-icon{
  width:48px;height:48px;margin:0 auto 12px;border-radius:14px;display:flex;align-items:center;justify-content:center;
  font-size:1.15rem;color:#7c3aed;background:linear-gradient(145deg,rgba(237,233,254,1),rgba(250,232,255,.9));border:1px solid rgba(196,181,253,.4);
}
.fm-guest-title{font-size:15px;font-weight:800;color:#0f172a;margin:0 0 6px;letter-spacing:-.02em;}
.fm-guest-text{font-size:13px;color:#64748b;margin:0 0 1rem;line-height:1.5;}
.fm-btn-login{
  display:inline-flex;align-items:center;justify-content:center;gap:8px;
  padding:11px 28px;border-radius:999px;font-weight:800;font-size:13px;text-decoration:none;
  background:linear-gradient(135deg,#8b5cf6,#a855f7);color:#fff!important;
  box-shadow:0 6px 20px rgba(124,58,237,.28);transition:transform .15s ease,box-shadow .15s ease;
}
.fm-btn-login:hover{transform:translateY(-1px);box-shadow:0 10px 26px rgba(124,58,237,.35);}
.fm-empty{
  padding:2.25rem 1.25rem;border-radius:16px;text-align:center;
  border:1px dashed rgba(203,213,225,.9);background:linear-gradient(180deg,rgba(248,250,252,.9),rgba(255,255,255,.5));color:#64748b;
}
.fm-empty i{display:block;font-size:1.75rem;margin-bottom:10px;opacity:.4;color:#94a3b8;}
.fm-empty strong{display:block;font-size:14px;font-weight:800;color:#475569;margin-bottom:4px;}
@media (max-width: 900px){
 .fm-layout{grid-template-columns:1fr;min-height:0;}
 .fm-map-canvas{min-height:280px;}
 .fm-card-list{max-height:none;}
}

    </style>
    <c:if test="${boardType eq 'map'}">
    <style>
        body.boards-map-page{
            min-height:100dvh; overflow-x:hidden; overflow-y:auto;
            background:#f1f5f9 !important;
            background-attachment:scroll !important;
        }
        body.boards-map-page::before{
            background:#f1f5f9 !important;
            opacity:1 !important;
        }
        body.boards-map-page::after{
            background:none !important;
            opacity:0 !important;
        }
        body.boards-map-page.modal-open{ overflow:hidden; }
        body.boards-map-page > main.boards-map-main{
            min-height:0; -webkit-overflow-scrolling:touch;
            display:block;
        }
        body.boards-map-page > footer.site-footer{
            padding:0.8rem 12px !important;
            padding-bottom:max(0.8rem, env(safe-area-inset-bottom, 0px)) !important;
        }
        body.boards-map-page .site-footer__container{ gap:0.35rem !important; }
        body.boards-map-page .site-footer__title{ font-size:0.85rem; margin:0; }
        body.boards-map-page .site-footer__meta{ font-size:10px; line-height:1.35; margin-top:0; }
        body.boards-map-page .site-footer__meta br{ display:none; }
        body.boards-map-page .site-footer__links{ gap:0.35rem 0.5rem !important; }
        body.boards-map-page .site-footer__links a{ font-size:10px !important; padding:4px 8px !important; }
        body.boards-map-page .site-footer__social{ gap:8px !important; margin-bottom:0.1rem; }
        body.boards-map-page .footer-icon{ width:28px !important; height:28px !important; font-size:12px; }
        .boards-map-inner{
            justify-content:stretch;
            align-items:stretch;
            display:flex;
            flex-direction:column;
            width:min(calc(88vw - 148px), 1380px);
            max-width:min(calc(88vw - 148px), 1380px) !important;
            margin-inline:auto;
        }
        @media (max-width: 900px){
            .boards-map-inner{
                width:min(99vw, 1920px);
                max-width:min(99vw, 1920px) !important;
            }
        }
        .boards-map-card{
            display:flex; flex-direction:column;
            box-shadow:0 12px 48px rgba(15,23,42,.08), 0 2px 12px rgba(15,23,42,.04);
            background:#fff;
            border-radius:1.25rem;
        }
        .cast-map-embed{
            position:relative; overflow:visible;
            border-radius:inherit;
            background:transparent;
            box-shadow:none;
            display:flex; flex-direction:column;
        }
        .cast-map-embed__inner{
            position:relative; z-index:1;
            display:flex; flex-direction:column;
        }
        .cast-map-embed__head{
            flex-shrink:0;
            display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:0.75rem 1rem;
            margin-bottom: clamp(0.55rem, 1.2vw, 0.85rem);
        }
        .cast-map-embed__title{ font-size:clamp(1.25rem, 2.6vw, 1.75rem); letter-spacing:-0.02em; }
        .cast-map-embed__lead{ font-size:clamp(0.8125rem, 1.5vw, 0.9375rem); line-height:1.55; }
        .cast-map-head__k{ font-family:"Orbitron",sans-serif; font-size:10px; letter-spacing:0.32em; color:rgba(91,33,182,0.75); }
        .cast-map-embed__gacha{
            display:inline-flex; align-items:center; gap:0.45rem;
            padding:0.55rem 1rem; border-radius:999px; font-size:0.8125rem; font-weight:800;
            text-decoration:none; color:#0f172a;
            border:1px solid rgba(167,139,250,0.45);
            background:linear-gradient(180deg,#fff,rgba(253,250,255,.98));
            box-shadow:0 4px 18px rgba(91,33,182,.12), 0 1px 0 rgba(255,255,255,.9) inset;
            transition:transform .18s ease, box-shadow .18s ease, border-color .18s ease;
        }
        .cast-map-embed__gacha:hover{
            transform:translateY(-2px);
            box-shadow:0 10px 28px rgba(91,33,182,.18);
            border-color:rgba(167,139,250,0.65);
        }
        .cast-status-strip{
            display:grid;
            grid-template-columns:repeat(3, minmax(0, 1fr));
            gap:clamp(0.65rem, 1.2vw, 0.9rem);
            margin-bottom:clamp(0.8rem, 1.4vw, 1.1rem);
        }
        @media (max-width: 900px){
            .cast-status-strip{ grid-template-columns:1fr; }
        }
        .cast-status-card{
            position:relative;
            display:flex;
            flex-direction:column;
            gap:0.28rem;
            min-height:106px;
            padding:1rem 1rem 0.95rem;
            border-radius:1.15rem;
            border:1px solid rgba(148,163,184,0.24);
            background:
                radial-gradient(circle at top right, rgba(196,181,253,0.16), transparent 34%),
                linear-gradient(180deg, rgba(255,255,255,.98), rgba(248,250,252,.92));
            box-shadow:0 12px 34px rgba(15,23,42,.06);
        }
        .cast-status-card--buff.is-live{
            border-color:rgba(167,139,250,.35);
            box-shadow:0 16px 40px rgba(91,33,182,.12);
        }
        .cast-status-card__label{
            font-family:"Orbitron",sans-serif;
            font-size:10px;
            letter-spacing:0.24em;
            color:rgba(91,33,182,.78);
        }
        .cast-status-card__value{
            font-size:clamp(1.05rem, 1.5vw, 1.35rem);
            font-weight:900;
            color:#0f172a;
            line-height:1.15;
        }
        .cast-status-card__sub{
            font-size:12px;
            line-height:1.45;
            color:#64748b;
        }
        .cast-stage{
            display:flex;
            flex-direction:column;
            gap:clamp(0.9rem, 1.6vw, 1.15rem);
            margin-top:0.15rem;
        }
        @media (min-width: 1024px){
            .cast-stage{
                display:grid;
                grid-template-columns:minmax(0, 1fr) minmax(420px, .95fr);
                align-items:stretch;
                gap:clamp(1rem, 1.5vw, 1.35rem);
            }
        }
        .cast-stage__map{
            min-width:0;
            display:flex;
            flex-direction:column;
            gap:0.5rem;
        }
        .cast-stage__panel{
            display:flex;
            flex-direction:column;
            gap:0.85rem;
            min-width:0;
        }
        .cast-map-wrap{
            position:relative; border-radius:1.25rem; overflow:hidden;
            border:1px solid rgba(148,163,184,0.28);
            box-shadow:0 12px 40px rgba(30,27,75,.1), inset 0 0 0 1px rgba(255,255,255,.45);
            background:linear-gradient(180deg,rgba(248,250,252,.98),rgba(241,245,249,.9));
        }
        .cast-map-wrap--wide{
            width:100%;
            max-width:760px;
            min-height:clamp(320px, 42vh, 520px);
            margin-inline:auto;
        }
        .cast-map-wrap::after{
            content:""; position:absolute; inset:0; pointer-events:none; border-radius:inherit;
            box-shadow:inset 0 0 0 1px rgba(255,255,255,.35);
        }
        .cast-map-wrap #castMapCanvas{ width:100% !important; height:100% !important; min-height:0; }
        .cast-map-hint{
            font-size:clamp(10px, 0.85vw, 12px); color:rgba(71,85,105,0.88);
            text-align:center; padding:0 4px;
        }
        .cast-region-panel{
            display:flex; flex-direction:column; justify-content:center;
            flex:1; width:100%; min-height:0;
            padding:clamp(0.75rem, 1.5vw, 1.15rem);
            border-radius:1.25rem;
            border:1px solid rgba(148,163,184,0.28);
            background:linear-gradient(180deg,#fff 0%,#f8fafc 100%);
            box-shadow:0 4px 24px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.9);
        }
        .cast-region-panel__head{
            display:flex;
            flex-wrap:wrap;
            align-items:center;
            justify-content:space-between;
            gap:0.5rem 1rem;
            margin-bottom:0.75rem;
        }
        .cast-region-panel__label{
            font-family:"Orbitron",sans-serif; font-size:10px; letter-spacing:0.2em; font-weight:800;
            text-transform:uppercase; color:rgba(91,33,182,0.9); margin:0;
            display:flex; align-items:center; gap:0.45rem;
        }
        .cast-region-panel__label i{ font-size:0.85rem; opacity:.9; }
        .cast-region-panel__selected{
            font-size:12px;
            color:#64748b;
            white-space:nowrap;
        }
        .cast-region-panel__selected strong{
            color:#7c3aed;
            font-weight:900;
        }
        .cast-region-chips{
            display:grid;
            grid-template-columns:repeat(4, minmax(0,1fr));
            gap:clamp(8px, 1.2vmin, 12px);
        }
        @media (max-width: 1100px){
            .cast-region-chips{ grid-template-columns:repeat(3, minmax(0,1fr)); }
        }
        @media (max-width: 760px){
            .cast-region-chips{ grid-template-columns:repeat(2, minmax(0,1fr)); }
        }
        .cast-region-chip{
            display:flex; flex-direction:column; align-items:flex-start; justify-content:center;
            gap:0.22rem;
            padding:clamp(0.65rem, 0.9vmin, 0.95rem) clamp(0.7rem, 1vw, 0.85rem);
            min-height:78px;
            border-radius:1rem;
            font-size:clamp(13px, 0.9vw + 0.35rem, 15px);
            font-weight:800; border:1px solid rgba(148,163,184,0.35);
            background:linear-gradient(180deg,rgba(255,255,255,.95),rgba(248,250,252,.88));
            color:#334155; cursor:pointer; text-align:left;
            transition:transform .15s ease, box-shadow .15s ease, border-color .15s ease;
        }
        .cast-region-chip__title{ font-size:14px; font-weight:900; color:#0f172a; line-height:1.2; }
        .cast-region-chip__sub{ font-size:11px; line-height:1.35; color:#64748b; font-weight:700; }
        .cast-region-chip:hover{
            border-color:rgba(167,139,250,0.65);
            box-shadow:0 6px 18px rgba(91,33,182,.12);
            transform:translateY(-1px);
        }
        .cast-region-chip.is-on{
            border-color:transparent;
            background:linear-gradient(135deg,rgba(233,176,196,0.98),rgba(196,181,253,0.72));
            color:rgba(20,10,30,0.95);
            box-shadow:0 8px 22px rgba(167,139,250,.28); transform:translateY(-1px);
        }
        .cast-region-chip.is-on .cast-region-chip__sub{ color:rgba(51,65,85,.92); }
        .cast-region-preview{
            padding:1rem 1rem 1.05rem;
            border-radius:1.05rem;
            border:1px solid rgba(148,163,184,0.24);
            background:
                linear-gradient(180deg, rgba(255,255,255,.98), rgba(248,250,252,.92)),
                radial-gradient(circle at top right, rgba(251,191,36,.14), transparent 36%);
            box-shadow:0 10px 28px rgba(15,23,42,.06);
        }
        .cast-region-preview__k{
            font-family:"Orbitron",sans-serif;
            font-size:10px;
            letter-spacing:0.22em;
            color:rgba(100,116,139,.9);
            margin-bottom:0.45rem;
        }
        .cast-region-preview__title{
            font-size:1.12rem;
            font-weight:900;
            color:#0f172a;
            margin:0 0 0.3rem;
        }
        .cast-region-preview__lead,
        .cast-region-preview__vibe,
        .cast-region-preview__tip{
            font-size:12px;
            line-height:1.55;
            color:#475569;
        }
        .cast-region-preview__meta{
            display:grid;
            grid-template-columns:repeat(2, minmax(0,1fr));
            gap:0.65rem;
            margin:0.85rem 0 0.8rem;
        }
        @media (max-width: 760px){
            .cast-region-preview__meta{ grid-template-columns:1fr; }
        }
        .cast-preview-pill{
            padding:0.75rem 0.8rem;
            border-radius:0.95rem;
            border:1px solid rgba(196,181,253,.28);
            background:linear-gradient(180deg, rgba(245,243,255,.92), rgba(255,255,255,.92));
        }
        .cast-preview-pill__label{
            display:block;
            font-size:10px;
            letter-spacing:0.12em;
            color:#7c3aed;
            margin-bottom:0.2rem;
        }
        .cast-preview-pill strong{
            color:#1e293b;
            font-size:13px;
            font-weight:900;
            line-height:1.4;
        }
        .cast-explore-bar{
            flex-shrink:0;
            display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:12px; margin-top:clamp(0.65rem, 1.2vh, 1rem);
            padding:clamp(0.75rem, 1.2vh, 1rem) clamp(0.85rem, 1.5vw, 1.1rem);
            border-radius:1.1rem;
            border:1px solid rgba(148,163,184,0.28);
            background:linear-gradient(180deg,#f8fafc 0%,#f1f5f9 100%);
            box-shadow:0 4px 20px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.9);
        }
        @media (max-width: 900px){
            body.boards-map-page > footer.site-footer{
                padding:0.7rem 12px calc(0.7rem + env(safe-area-inset-bottom, 0px)) !important;
            }
            .cast-map-wrap--wide{
                min-height:clamp(220px, 34vh, 300px);
            }
        }
        .cast-explore-stats{ flex:1 1 12rem; min-width:0; line-height:1.5; font-size:12px; }
        .cast-explore-cost strong{ margin:0 2px; }
        .cast-explore-btn{
            min-width:140px; padding:12px 22px; border-radius:999px; font-weight:900; font-size:13px;
            border:1px solid rgba(232,164,184,0.5);
            background:linear-gradient(135deg,rgba(233,176,196,0.98),rgba(196,181,253,0.62));
            color:rgba(20,10,30,0.92); transition:transform .15s ease, box-shadow .15s ease;
            box-shadow:0 6px 20px rgba(167,139,250,.22);
        }
        .cast-explore-btn.is-loading{
            opacity:.75;
            transform:none;
            box-shadow:0 4px 16px rgba(167,139,250,.16);
        }
        .cast-explore-btn:hover:not(:disabled){ transform:translateY(-2px); box-shadow:0 10px 28px rgba(167,139,250,.35); }
        .cast-explore-btn:disabled{ opacity:.45; cursor:not-allowed; box-shadow:none; }
        .cast-modal-dim{
            display:none; position:fixed; inset:0; z-index:10050;
            background:rgba(15,23,42,0); backdrop-filter:blur(0);
            align-items:center; justify-content:center; padding:16px;
            transition:background .28s ease, backdrop-filter .28s ease;
        }
        .cast-modal-dim.is-open{ display:flex; }
        .cast-modal-dim.is-visible{
            background:rgba(15,23,42,.42);
            backdrop-filter:blur(10px);
        }
        .cast-modal-panel{
            max-width:min(400px,100%); border-radius:24px; padding:0; overflow:hidden;
            border:1px solid rgba(232,164,184,.45);
            background:linear-gradient(180deg,#fff 0%,rgba(253,250,255,.98) 100%);
            box-shadow:0 28px 70px rgba(30,27,75,.2), 0 0 0 1px rgba(255,255,255,.6) inset;
            transform:scale(.94) translateY(12px); opacity:0;
            transition:transform .32s cubic-bezier(.22,1,.36,1), opacity .28s ease;
        }
        .cast-modal-dim.is-visible .cast-modal-panel{
            transform:scale(1) translateY(0); opacity:1;
        }
        .cast-modal-ribbon{
            height:4px; background:linear-gradient(90deg,#e9b0c4,#c4b5fd,#f472b6,#a78bfa);
            background-size:200% 100%; animation:castModalRibbon 4s linear infinite;
        }
        @keyframes castModalRibbon{ to{ background-position:200% 0; } }
        .cast-modal-panel__body{ padding:1.25rem 1.35rem 1.35rem; }
        .cast-modal-iconwrap{
            width:48px; height:48px; margin:0 auto .6rem; border-radius:16px;
            display:flex; align-items:center; justify-content:center;
            background:linear-gradient(145deg,rgba(233,176,196,.35),rgba(196,181,253,.25));
            box-shadow:0 8px 24px rgba(167,139,250,.2);
            font-size:1.35rem;
        }
        .cast-modal-iconwrap.is-rare{
            background:linear-gradient(145deg,rgba(251,191,36,.34),rgba(249,168,212,.25));
            box-shadow:0 10px 28px rgba(245,158,11,.22);
        }
        .cast-modal-iconwrap.is-fail{
            background:linear-gradient(145deg,rgba(226,232,240,.65),rgba(203,213,225,.55));
            box-shadow:none;
        }
        .cast-modal-eyebrow{
            text-align:center;
            font-family:"Orbitron",sans-serif;
            font-size:10px;
            letter-spacing:0.22em;
            color:#7c3aed;
            margin-bottom:0.3rem;
        }
        .cast-modal-panel h3{
            font-family:"Orbitron",sans-serif; font-size:.95rem; font-weight:900; letter-spacing:.06em;
            color:#0f172a; margin-bottom:.4rem; text-align:center;
        }
        .cast-modal-panel .cast-modal-msg{
            font-size:13px; color:#475569; line-height:1.55; margin-bottom:1rem; text-align:center;
        }
        .cast-modal-detail{
            margin-bottom:1rem;
            padding:0.95rem 1rem;
            border-radius:1rem;
            border:1px solid rgba(196,181,253,.28);
            background:linear-gradient(180deg, rgba(248,250,252,.94), rgba(255,255,255,.96));
        }
        .cast-modal-detail__spot{
            display:flex;
            flex-direction:column;
            gap:0.2rem;
            margin-bottom:0.75rem;
        }
        .cast-modal-detail__label,
        .cast-modal-stat__label{
            font-size:10px;
            letter-spacing:0.12em;
            color:#7c3aed;
        }
        .cast-modal-detail__spot strong,
        .cast-modal-stat strong{
            color:#0f172a;
            font-size:13px;
            line-height:1.45;
        }
        .cast-modal-detail__meta{
            display:grid;
            grid-template-columns:repeat(2, minmax(0,1fr));
            gap:0.65rem;
        }
        .cast-modal-stat{
            padding:0.7rem 0.75rem;
            border-radius:0.9rem;
            background:rgba(245,243,255,.72);
            border:1px solid rgba(196,181,253,.2);
        }
        .cast-modal-actions{ display:flex; flex-wrap:wrap; gap:10px; justify-content:center; }
        .cast-modal-actions a,.cast-modal-actions button{
            flex:1; min-width:120px; text-align:center; padding:11px 14px; border-radius:999px; font-weight:800; font-size:13px;
            text-decoration:none; border:none; cursor:pointer; transition:transform .15s ease, box-shadow .15s ease;
        }
        .cast-modal-actions .btn-primary{
            background:linear-gradient(135deg,rgba(233,176,196,0.98),rgba(196,181,253,0.6));
            color:rgba(20,10,30,0.92); border:1px solid rgba(232,164,184,0.45);
            box-shadow:0 6px 18px rgba(167,139,250,.22);
        }
        .cast-modal-actions .btn-primary:hover{ transform:translateY(-1px); }
        .cast-modal-actions .btn-ghost{
            background:rgba(255,255,255,.9); border:1px solid rgba(148,163,184,0.4); color:#334155;
        }
    </style>
    </c:if>
    <c:if test="${boardType eq 'fanmeeting'}">
    <style>
        body.boards-map-page.boards-map-page--fanmeet{
            min-height:100dvh; height:auto; max-height:none; overflow-x:hidden; overflow-y:auto;
            display:flex; flex-direction:column;
            background:
              radial-gradient(1200px 600px at 15% -10%, rgba(237,233,254,.65), transparent 55%),
              radial-gradient(900px 500px at 95% 20%, rgba(252,231,243,.5), transparent 50%),
              linear-gradient(180deg, #f4f4f8 0%, #eef2f7 45%, #f1f5f9 100%) !important;
            background-attachment:scroll !important;
        }
        body.boards-map-page.boards-map-page--fanmeet::before{
            background:transparent !important;
            opacity:0 !important;
        }
        body.boards-map-page.boards-map-page--fanmeet::after{
            background:none !important;
            opacity:0 !important;
        }
        body.boards-map-page.modal-open{ overflow:hidden; }
        body.boards-map-page.boards-map-page--fanmeet > main.boards-map-main{
            flex:1 1 auto; min-height:0;
            display:flex; flex-direction:column;
        }
        body.boards-map-page.boards-map-page--fanmeet > footer.site-footer{
            flex-shrink:0;
            padding:0.5rem 12px !important;
            padding-bottom:max(0.5rem, env(safe-area-inset-bottom, 0px)) !important;
        }
        body.boards-map-page .site-footer__container{ gap:0.35rem !important; }
        body.boards-map-page .site-footer__title{ font-size:0.85rem; margin:0; }
        body.boards-map-page .site-footer__meta{ font-size:10px; line-height:1.35; margin-top:0; }
        body.boards-map-page .site-footer__meta br{ display:none; }
        body.boards-map-page .site-footer__links{ gap:0.35rem 0.5rem !important; }
        body.boards-map-page .site-footer__links a{ font-size:10px !important; padding:4px 8px !important; }
        body.boards-map-page .site-footer__social{ gap:8px !important; margin-bottom:0.1rem; }
        body.boards-map-page .footer-icon{ width:28px !important; height:28px !important; font-size:12px; }
        .boards-map-inner{ flex:1; min-height:0; justify-content:stretch; align-items:stretch; display:flex; flex-direction:column; }
        .boards-map-card.boards-map-card--fanmeet{
            flex:1 1 auto; min-height:0; display:flex; flex-direction:column;
            background:linear-gradient(155deg, rgba(255,255,255,.96) 0%, rgba(250,250,252,.94) 50%, rgba(248,250,252,.92) 100%);
            border:1px solid rgba(226,232,240,.75)!important;
            border-radius:1.35rem!important;
            box-shadow:
              0 0 0 1px rgba(255,255,255,.75) inset,
              0 18px 50px rgba(15,23,42,.07),
              0 4px 14px rgba(124,58,237,.06);
        }
        .boards-map-card.boards-map-card--fanmeet.glass-card{backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);}
    </style>
    </c:if>
</head>

<body class="page-main min-h-screen flex flex-col
<c:if test="${boardType eq 'map' or boardType eq 'fanmeeting'}"> boards-map-page</c:if><c:if test="${boardType eq 'fanmeeting'}"> boards-map-page--fanmeet</c:if>
<c:if test="${boardType eq 'free'}"> free-board</c:if>
<c:if test="${boardType eq 'notice'}"> notice-board</c:if>">
<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>

<main class="flex-1<c:if test="${boardType eq 'map' or boardType eq 'fanmeeting'}"> boards-map-main flex flex-col min-h-0 px-3 sm:px-5 pb-2 sm:pb-3</c:if><c:if test="${boardType ne 'map' and boardType ne 'fanmeeting'}"> px-6 pb-16</c:if>" style="padding-top: calc(var(--nav-h) + <c:choose><c:when test="${boardType eq 'map' or boardType eq 'fanmeeting'}">8px</c:when><c:otherwise>24px</c:otherwise></c:choose>);">
    <div class="container mx-auto<c:if test="${boardType eq 'map' or boardType eq 'fanmeeting'}"> max-w-6xl xl:max-w-7xl boards-map-inner flex-1 flex flex-col min-h-0</c:if><c:if test="${boardType ne 'map' and boardType ne 'fanmeeting'}"> max-w-5xl</c:if>">
        <section class="glass-card<c:if test="${boardType eq 'map' or boardType eq 'fanmeeting'}"> boards-map-card<c:if test="${boardType eq 'fanmeeting'}"> boards-map-card--fanmeet</c:if> flex flex-col flex-1 min-h-0 w-full p-3 sm:p-4 md:p-5 border border-slate-200/80</c:if><c:if test="${boardType ne 'map' and boardType ne 'fanmeeting'}"> p-8 md:p-10</c:if>">
            <c:if test="${boardType ne 'map' and boardType ne 'fanmeeting'}">
            <div class="flex items-start justify-between gap-4">
                <div class="min-w-0">
                    <h1 class="font-orbitron font-black text-slate-900 drop-shadow text-3xl md:text-5xl mb-2">${boardTitle}</h1>
                    <p class="text-slate-600">총 <strong>${totalItems}</strong>개의 글</p>
                </div>
                <c:choose>
                    <c:when test="${boardType eq 'notice' and not isAdmin}">
                    </c:when>
                    <c:when test="${boardType eq 'search'}">
                        <a class="btn-primary" href="${ctx}/boards/free/write" id="btnWrite"
                           data-logged-in="${loggedIn}" data-redirect="/boards/free/write">
                            <i class="fa-solid fa-pen"></i>
                            글쓰기
                        </a>
                    </c:when>
                    <c:otherwise>
                        <a class="btn-primary" href="${ctx}/boards/${boardType}/write" id="btnWrite"
                           data-logged-in="${loggedIn}" data-redirect="/boards/${boardType}/write">
                            <i class="fa-solid fa-pen"></i>
                            글쓰기
                        </a>
                    </c:otherwise>
                </c:choose>
            </div>
            </c:if>

            <c:if test="${boardType eq 'free'}">
                <div class="board-filter-bar board-filter-bar--with-search mt-6">
                    <div class="board-filter-group">
                        <c:url var="freeAllUrl" value="/boards/free"><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                        <c:url var="freeFUrl" value="/boards/free"><c:param name="filter" value="free"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                        <c:url var="freeGUrl" value="/boards/free"><c:param name="filter" value="guide"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>

                        <a href="${freeAllUrl}" class="filter-chip ${communityFilter eq 'all' ? 'is-active' : ''}">전체</a>
                        <a href="${freeFUrl}" class="filter-chip ${communityFilter eq 'free' ? 'is-active' : ''}">자유</a>
                        <a href="${freeGUrl}" class="filter-chip ${communityFilter eq 'guide' ? 'is-active' : ''}">공략</a>
                    </div>

                    <div class="board-search-row board-search-row--inline">
                        <c:url var="freeSearchAction" value="/boards/free"/>
                        <form method="get" action="${freeSearchAction}">
                            <c:if test="${communityFilter eq 'free'}"><input type="hidden" name="filter" value="free"/></c:if>
                            <c:if test="${communityFilter eq 'guide'}"><input type="hidden" name="filter" value="guide"/></c:if>
                            <input type="search" name="q" value="${boardSearchQ}" placeholder="제목·내용 검색" autocomplete="off"/>
                            <button type="submit">검색</button>
                        </form>
                    </div>
                </div>
            </c:if>

            <c:if test="${boardType eq 'report'}">
                <div class="board-filter-bar board-filter-bar--with-search mt-6">
                    <div class="board-filter-group">
                        <c:url var="repAllUrl" value="/boards/report"><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                        <c:url var="repPendUrl" value="/boards/report"><c:param name="reportStatus" value="pending"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                        <c:url var="repDoneUrl" value="/boards/report"><c:param name="reportStatus" value="completed"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                        <a href="${repAllUrl}" class="filter-chip ${reportStatusFilter eq 'all' ? 'is-active' : ''}">전체</a>
                        <a href="${repPendUrl}" class="filter-chip ${reportStatusFilter eq 'pending' ? 'is-active' : ''}">처리 대기</a>
                        <a href="${repDoneUrl}" class="filter-chip ${reportStatusFilter eq 'completed' ? 'is-active' : ''}">처리 완료</a>
                    </div>
                </div>
            </c:if>

            <c:if test="${boardType eq 'search'}">
                <div class="board-filter-bar mt-6 flex-wrap">
                    <span class="text-xs text-slate-500 w-full mb-1">검색 범위</span>
                    <c:url var="scAll" value="/boards/search"><c:param name="scope" value="all"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                    <c:url var="scN" value="/boards/search"><c:param name="scope" value="notice"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                    <c:url var="scC" value="/boards/search"><c:param name="scope" value="community"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                    <c:url var="scM" value="/boards/search"><c:param name="scope" value="map"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                    <c:url var="scR" value="/boards/search"><c:param name="scope" value="report"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if></c:url>
                    <a href="${scAll}" class="filter-chip ${searchScope eq 'all' ? 'is-active' : ''}">전체</a>
                    <a href="${scN}" class="filter-chip ${searchScope eq 'notice' ? 'is-active' : ''}">공지</a>
                    <a href="${scC}" class="filter-chip ${searchScope eq 'community' ? 'is-active' : ''}">커뮤니티</a>
                    <a href="${scM}" class="filter-chip ${searchScope eq 'map' ? 'is-active' : ''}">캐스팅</a>
                    <a href="${scR}" class="filter-chip ${searchScope eq 'report' ? 'is-active' : ''}">신고</a>
                </div>
            </c:if>

            <c:if test="${boardType ne 'map' and boardType ne 'fanmeeting' and boardType ne 'free'}">
                <div class="board-search-row mt-5 flex flex-wrap items-center gap-2">
                    <c:choose>
                        <c:when test="${boardType eq 'search'}">
                            <c:url var="searchFormAction" value="/boards/search"/>
                            <form method="get" action="${searchFormAction}" class="flex flex-wrap items-center gap-2 flex-1 min-w-0">
                                <input type="hidden" name="scope" value="${searchScope}"/>
                                <input type="search" name="q" value="${boardSearchQ}" placeholder="제목·내용 검색 (전체 게시판)" autocomplete="off"
                                       class="flex-1 min-w-[200px] max-w-lg px-3 py-2 rounded-xl border border-slate-200 bg-white/80 text-slate-900 text-sm"/>
                                <button type="submit" class="px-4 py-2 rounded-xl font-semibold text-sm border border-pink-200 bg-gradient-to-r from-pink-100 to-violet-100 text-slate-900">검색</button>
                                <c:if test="${not empty boardSearchQ}">
                                    <c:url var="searchReset" value="/boards/search"><c:param name="scope" value="${searchScope}"/></c:url>
                                    <a href="${searchReset}" class="search-clear text-sm">검색 초기화</a>
                                </c:if>
                            </form>
                        </c:when>
                        <c:otherwise>
                            <c:url var="typeSearchAction" value="/boards/${boardType}"/>
                            <form method="get" action="${typeSearchAction}" class="flex flex-wrap items-center gap-2 flex-1 min-w-0">
                                <c:if test="${boardType eq 'free'}">
                                    <c:if test="${communityFilter eq 'free'}"><input type="hidden" name="filter" value="free"/></c:if>
                                    <c:if test="${communityFilter eq 'guide'}"><input type="hidden" name="filter" value="guide"/></c:if>
                                </c:if>
                                <c:if test="${boardType eq 'report'}">
                                    <c:if test="${reportStatusFilter eq 'pending'}"><input type="hidden" name="reportStatus" value="pending"/></c:if>
                                    <c:if test="${reportStatusFilter eq 'completed'}"><input type="hidden" name="reportStatus" value="completed"/></c:if>
                                </c:if>
                                <input type="search" name="q" value="${boardSearchQ}" placeholder="제목·내용 검색" autocomplete="off"
                                       class="flex-1 min-w-[200px] max-w-lg px-3 py-2 rounded-xl border border-slate-200 bg-white/80 text-slate-900 text-sm"/>
                                <button type="submit" class="px-4 py-2 rounded-xl font-semibold text-sm border border-pink-200 bg-gradient-to-r from-pink-100 to-violet-100 text-slate-900">검색</button>
                                <c:if test="${not empty boardSearchQ}">
                                    <c:url var="typeReset" value="/boards/${boardType}"><c:if test="${boardType eq 'free' and communityFilter eq 'free'}"><c:param name="filter" value="free"/></c:if><c:if test="${boardType eq 'free' and communityFilter eq 'guide'}"><c:param name="filter" value="guide"/></c:if><c:if test="${boardType eq 'report' and reportStatusFilter eq 'pending'}"><c:param name="reportStatus" value="pending"/></c:if><c:if test="${boardType eq 'report' and reportStatusFilter eq 'completed'}"><c:param name="reportStatus" value="completed"/></c:if></c:url>
                                    <a href="${typeReset}" class="search-clear text-sm">검색 초기화</a>
                                </c:if>
                            </form>
                        </c:otherwise>
                    </c:choose>
                </div>
            </c:if>

            <c:if test="${boardType eq 'map'}">
                <%@ include file="/WEB-INF/views/fragments/casting-map-explore.jspf" %>
            </c:if>

            <c:if test="${boardType eq 'fanmeeting'}">
                <div id="fanMeetingMapBoot"
                     data-ctx="${ctx}"
                     data-map-json='<c:out value="${fanMeetingMapJson}" escapeXml="true" />'
                     data-has-kakao="${not empty kakaoMapJavascriptKey}"
                     data-logged-in="${loggedIn}">
                </div>
                <header class="fm-page-head">
                    <p class="fm-page-kicker">LOCATION BOARD</p>
                    <h1 class="fm-page-title">${boardTitle}</h1>
                    <p class="fm-page-lead">지도에서 모임 장소를 고르고 글을 남기면 같은 화면에서 핀과 목록이 연동됩니다. 길거리 캐스팅 게시판과는 별도로 관리됩니다.</p>
                    <div class="fm-badges">
                        <span class="fm-badge"><i class="fa-solid fa-map-location-dot"></i> 카카오맵</span>
                        <span class="fm-badge"><i class="fa-solid fa-users"></i> 연습생별 보기</span>
                    </div>
                </header>
                <div class="fm-layout">
                    <div class="fm-map-col">
                        <div class="fm-map-card">
                            <div class="fm-map-toolbar">
                                <form method="get" action="${ctx}/boards/fanmeeting" class="fm-filter-form">
                                    <select name="filter" id="fmTraineeFilter" class="fm-select" aria-label="연습생 필터">
                                        <option value="">전체 연습생</option>
                                        <c:forEach var="t" items="${trainees}">
                                            <option value="${t.id}" ${mapTraineeFilter eq t.id ? 'selected' : ''}>${t.name}</option>
                                        </c:forEach>
                                    </select>
                                    <select name="scope" id="fmSortSelect" class="fm-select" aria-label="정렬">
                                        <option value="latest" ${mapSort eq 'latest' ? 'selected' : ''}>최신순</option>
                                        <option value="popular" ${mapSort eq 'popular' ? 'selected' : ''}>인기순</option>
                                    </select>
                                    <button type="submit" class="fm-btn">적용</button>
                                </form>
                            </div>
                            <p class="fm-map-lead">핀을 누르면 미리보기가 열립니다. 글 등록은 오른쪽 버튼으로 상세 옵션 페이지에서 진행하세요.</p>
                            <div id="fanMeetingMapCanvas" class="fm-map-canvas"></div>
                        </div>
                    </div>
                    <div class="fm-board-col">
                        <div class="fm-list-head">
                            <span class="fm-list-title">Meetups</span>
                            <div class="fm-list-head-right">
                                <a class="fm-write-inline-btn" href="${ctx}/boards/fanmeeting/write" id="btnWrite"
                                   data-logged-in="${loggedIn}" data-redirect="/boards/fanmeeting/write">
                                    <i class="fa-solid fa-pen"></i> 글쓰기
                                </a>
                                <div class="fm-status-filter">
                                    <c:url var="fmStatusAllUrl" value="/boards/fanmeeting"><c:param name="scope" value="${mapSort}"/><c:if test="${not empty mapTraineeFilter}"><c:param name="filter" value="${mapTraineeFilter}"/></c:if><c:param name="fmStatus" value="all"/></c:url>
                                    <c:url var="fmStatusRecUrl" value="/boards/fanmeeting"><c:param name="scope" value="${mapSort}"/><c:if test="${not empty mapTraineeFilter}"><c:param name="filter" value="${mapTraineeFilter}"/></c:if><c:param name="fmStatus" value="recruiting"/></c:url>
                                    <c:url var="fmStatusDoneUrl" value="/boards/fanmeeting"><c:param name="scope" value="${mapSort}"/><c:if test="${not empty mapTraineeFilter}"><c:param name="filter" value="${mapTraineeFilter}"/></c:if><c:param name="fmStatus" value="done"/></c:url>
                                    <a href="${fmStatusAllUrl}" class="fm-status-chip ${fanMeetingStatusFilter eq 'all' ? 'is-active' : ''}">전체</a>
                                    <a href="${fmStatusRecUrl}" class="fm-status-chip ${fanMeetingStatusFilter eq 'recruiting' ? 'is-active' : ''}">모집중</a>
                                    <a href="${fmStatusDoneUrl}" class="fm-status-chip ${fanMeetingStatusFilter eq 'done' ? 'is-active' : ''}">마감</a>
                                </div>
                            </div>
                        </div>
                        <div class="fm-card-list" id="fanMeetingPostList">
                            <c:choose>
                                <c:when test="${empty posts}">
                                    <div class="fm-empty">
                                        <i class="fa-solid fa-map-pin"></i>
                                        <strong>표시할 모임이 없어요</strong>
                                        글이 승인 대기이거나, 필터 조건에 맞는 글이 없습니다.
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <c:forEach var="p" items="${posts}">
                                        <c:set var="trainee" value="${traineeMap[p.traineeId]}" />
                                        <a class="fm-card" href="${ctx}/boards/fanmeeting/${p.id}" data-post-id="${p.id}" data-trainee-id="${p.traineeId}">
                                            <div class="fm-card-head">
                                                <c:if test="${not empty trainee.imagePath}">
                                                    <img class="fm-thumb" src="${ctx}${trainee.imagePath}" alt="${trainee.name}" />
                                                </c:if>
                                                <c:if test="${empty trainee.imagePath}">
                                                    <div class="fm-thumb fm-thumb--empty"><i class="fa-solid fa-user"></i></div>
                                                </c:if>
                                                <div>
                                                    <p class="fm-trainee-name">${not empty trainee ? trainee.name : '연습생 미지정'}</p>
                                                    <h3 class="fm-title">${p.title}</h3>
                                                </div>
                                            </div>
                                            <div class="fm-meta">
                                                <span><i class="fa-solid fa-location-dot"></i> ${p.placeName}</span>
                                                <span><i class="fa-solid fa-calendar-day"></i> ${p.eventAtStr}</span>
                                                <span class="fm-status fm-status--${p.fanMeetingStatusKey}">${p.recruitStatusLabel}</span>
                                                <span><i class="fa-solid fa-heart"></i> ${p.likeCount}</span>
                                                <span><i class="fa-solid fa-eye"></i> ${p.viewCount}</span>
                                            </div>
                                        </a>
                                    </c:forEach>
                                </c:otherwise>
                            </c:choose>
                        </div>
                        <c:if test="${totalPages > 1}">
                            <nav class="pagination" aria-label="팬미팅 페이지 이동" style="margin-top:10px;">
                                <c:url var="fmPrevUrlIn" value="/boards/fanmeeting">
                                    <c:param name="page" value="${currentPage - 1}"/>
                                    <c:param name="scope" value="${mapSort}"/>
                                    <c:if test="${not empty mapTraineeFilter}"><c:param name="filter" value="${mapTraineeFilter}"/></c:if>
                                    <c:param name="fmStatus" value="${fanMeetingStatusFilter}"/>
                                </c:url>
                                <a href="${fmPrevUrlIn}" class="page-btn ${currentPage == 0 ? 'disabled' : ''}"><i class="fa-solid fa-chevron-left fa-xs"></i></a>
                                <c:set var="fmStartPageIn" value="${currentPage - 2 < 0 ? 0 : currentPage - 2}" />
                                <c:set var="fmEndPageIn" value="${fmStartPageIn + 4 >= totalPages ? totalPages - 1 : fmStartPageIn + 4}" />
                                <c:set var="fmStartPageIn" value="${fmEndPageIn - 4 < 0 ? 0 : fmEndPageIn - 4}" />
                                <c:forEach var="i" begin="${fmStartPageIn}" end="${fmEndPageIn}">
                                    <c:url var="fmPageUrlIn" value="/boards/fanmeeting">
                                        <c:param name="page" value="${i}"/>
                                        <c:param name="scope" value="${mapSort}"/>
                                        <c:if test="${not empty mapTraineeFilter}"><c:param name="filter" value="${mapTraineeFilter}"/></c:if>
                                        <c:param name="fmStatus" value="${fanMeetingStatusFilter}"/>
                                    </c:url>
                                    <a href="${fmPageUrlIn}" class="page-btn ${i == currentPage ? 'active' : ''}">${i + 1}</a>
                                </c:forEach>
                                <c:url var="fmNextUrlIn" value="/boards/fanmeeting">
                                    <c:param name="page" value="${currentPage + 1}"/>
                                    <c:param name="scope" value="${mapSort}"/>
                                    <c:if test="${not empty mapTraineeFilter}"><c:param name="filter" value="${mapTraineeFilter}"/></c:if>
                                    <c:param name="fmStatus" value="${fanMeetingStatusFilter}"/>
                                </c:url>
                                <a href="${fmNextUrlIn}" class="page-btn ${currentPage + 1 >= totalPages ? 'disabled' : ''}"><i class="fa-solid fa-chevron-right fa-xs"></i></a>
                            </nav>
                        </c:if>
                    </div>
                </div>
            </c:if>

            <c:if test="${not empty success}">
                <div class="mt-6 px-4 py-3 rounded-xl bg-white/80 border border-slate-200 text-slate-800">
                    ${success}
                </div>
            </c:if>
            <c:if test="${not empty error}">
                <div class="mt-6 px-4 py-3 rounded-xl bg-red-500/10 border border-red-200 text-red-800">
                    ${error}
                </div>
            </c:if>
            <c:if test="${not empty param.error}">
                <div class="mt-6 px-4 py-3 rounded-xl bg-red-500/10 border border-red-200 text-red-800">
                    ${param.error}
                </div>
            </c:if>

            <c:if test="${boardType ne 'map' and boardType ne 'fanmeeting'}">
            <div class="mt-8 board-table-panel">
                <table class="w-full text-left text-sm text-slate-800">
                            <thead class="text-slate-600">
                            <tr class="border-b border-slate-200">
                                <th class="py-3 pr-4 w-[70px]">번호</th>
                                <th class="py-3 pr-4 text-center">제목</th>
                                <c:if test="${boardType eq 'report'}">
                                <th class="py-3 pr-4 w-[88px] text-center">상태</th>
                                </c:if>
                                <th class="py-3 pr-4 w-[80px] text-center">작성자</th>
                                <th class="py-3 pr-4 w-[60px] text-center">조회</th>
                                <th class="py-3 pr-4 w-[60px] text-center">좋아요</th>
                                <th class="py-3 pr-4 w-[130px]">작성일</th>
                            </tr>
                            </thead>
                            <tbody>
                            <c:choose>
                                <c:when test="${empty posts}">
                                    <tr class="border-b border-slate-100">
                                        <td class="py-5 text-slate-500" colspan="${boardType eq 'report' ? 7 : 6}">
                                            <c:choose>
                                                <c:when test="${boardType eq 'search' and empty boardSearchQ}">검색어를 입력한 뒤 검색해 주세요.</c:when>
                                                <c:when test="${not empty boardSearchQ}">검색 결과가 없습니다.</c:when>
                                                <c:otherwise>아직 글이 없어요. 첫 글을 작성해보세요.</c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:when>
                                <c:otherwise>
                                    <c:forEach var="p" items="${posts}" varStatus="vs">
                                        <tr class="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                            <td class="py-4 pr-4 text-slate-600">${totalItems - (currentPage * pageSize) - vs.index}</td>
                                            <td class="py-4 pr-4">
                                                <c:if test="${not empty p.category}">
                                                    <span class="badge-cat ${p.category}">${p.categoryLabel}</span>
                                                </c:if>
                                                <c:if test="${boardType eq 'free'}">
                                                    <c:choose>
                                                        <c:when test="${p.boardType eq 'guide'}">
                                                            <span class="badge-community guide">공략</span>
                                                        </c:when>
                                                        <c:when test="${p.boardType eq 'lounge'}">
                                                            <span class="badge-community lounge">자유</span>
                                                        </c:when>
                                                        <c:otherwise>
                                                            <span class="badge-community free">자유</span>
                                                        </c:otherwise>
                                                    </c:choose>
                                                </c:if>
                                                <c:if test="${boardType eq 'search'}">
                                                    <c:choose>
                                                        <c:when test="${p.boardType eq 'notice'}"><span class="badge-board-type">공지</span></c:when>
                                                        <c:when test="${p.boardType eq 'map'}"><span class="badge-board-type">캐스팅</span></c:when>
                                                        <c:when test="${p.boardType eq 'report'}"><span class="badge-board-type">신고</span></c:when>
                                                        <c:when test="${p.boardType eq 'guide'}"><span class="badge-community guide">공략</span></c:when>
                                                        <c:when test="${p.boardType eq 'lounge'}"><span class="badge-community lounge">자유</span></c:when>
                                                        <c:otherwise><span class="badge-community free">자유</span></c:otherwise>
                                                    </c:choose>
                                                </c:if>
                                                <a class="underline decoration-slate-300 hover:decoration-slate-500" href="${ctx}/boards/${p.boardType}/${p.id}">
                                                    <c:choose>
                                                        <c:when test="${boardType eq 'report'}">${reportDisplayTitleMap[p.id]}</c:when>
                                                        <c:otherwise>${p.title}</c:otherwise>
                                                    </c:choose>
                                                </a>
                                                <c:if test="${not empty p.originalFilename}">
                                                    <i class="fa-solid fa-paperclip text-slate-400 ml-1" style="font-size:10px;"></i>
                                                </c:if>
                                                <c:if test="${p.secret}">
                                                    <span class="badge-secret"><i class="fa-solid fa-lock" style="font-size:9px;"></i> 비밀글</span>
                                                </c:if>
                                            </td>
                                            <c:if test="${boardType eq 'report'}">
                                            <td class="py-4 pr-4 text-center" style="font-size:12px;">
                                                <c:choose>
                                                    <c:when test="${reportHandledMap[p.id]}"><span class="badge-report-done">처리완료</span></c:when>
                                                    <c:otherwise><span class="badge-report-wait">접수중</span></c:otherwise>
                                                </c:choose>
                                            </td>
                                            </c:if>
                                            <td class="py-4 pr-4 text-center text-slate-500" style="font-size:12px;">${p.authorNick}</td>
                                            <td class="py-4 pr-4 text-center text-slate-500" style="font-size:12px;">${p.viewCount}</td>
                                            <td class="py-4 pr-4 text-center" style="font-size:12px;color:rgba(233,176,196,0.90);">${p.likeCount}</td>
                                            <td class="py-4 pr-4 text-slate-500" style="font-size:12px;">${p.createdAtStr}</td>
                                        </tr>
                                    </c:forEach>
                                </c:otherwise>
                            </c:choose>
                            </tbody>
                </table>
            </div>
            </c:if>

            <c:if test="${boardType ne 'map' and boardType ne 'fanmeeting' and totalPages > 1}">
                <nav class="pagination" aria-label="페이지 이동">
                    <c:choose>
                        <c:when test="${boardType eq 'search'}">
                            <c:url var="pgPrev" value="/boards/search"><c:param name="page" value="${currentPage - 1}"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if><c:param name="scope" value="${searchScope}"/></c:url>
                            <a href="${pgPrev}" class="page-btn ${currentPage == 0 ? 'disabled' : ''}"><i class="fa-solid fa-chevron-left fa-xs"></i></a>
                            <c:set var="startPage" value="${currentPage - 4 < 0 ? 0 : currentPage - 4}" />
                            <c:set var="endPage" value="${startPage + 9 >= totalPages ? totalPages - 1 : startPage + 9}" />
                            <c:forEach var="i" begin="${startPage}" end="${endPage}">
                                <c:url var="pgI" value="/boards/search"><c:param name="page" value="${i}"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if><c:param name="scope" value="${searchScope}"/></c:url>
                                <a href="${pgI}" class="page-btn ${i == currentPage ? 'active' : ''}">${i + 1}</a>
                            </c:forEach>
                            <c:url var="pgNext" value="/boards/search"><c:param name="page" value="${currentPage + 1}"/><c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if><c:param name="scope" value="${searchScope}"/></c:url>
                            <a href="${pgNext}" class="page-btn ${currentPage + 1 >= totalPages ? 'disabled' : ''}"><i class="fa-solid fa-chevron-right fa-xs"></i></a>
                        </c:when>
                        <c:otherwise>
                            <c:url var="pgPrevT" value="/boards/${boardType}">
                                <c:param name="page" value="${currentPage - 1}"/>
                                <c:if test="${boardType eq 'free' and communityFilter eq 'free'}"><c:param name="filter" value="free"/></c:if>
                                <c:if test="${boardType eq 'free' and communityFilter eq 'guide'}"><c:param name="filter" value="guide"/></c:if>
                                <c:if test="${boardType eq 'report' and reportStatusFilter eq 'pending'}"><c:param name="reportStatus" value="pending"/></c:if>
                                <c:if test="${boardType eq 'report' and reportStatusFilter eq 'completed'}"><c:param name="reportStatus" value="completed"/></c:if>
                                <c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if>
                            </c:url>
                            <a href="${pgPrevT}" class="page-btn ${currentPage == 0 ? 'disabled' : ''}">
                                <i class="fa-solid fa-chevron-left fa-xs"></i>
                            </a>
                            <c:set var="startPage" value="${currentPage - 4 < 0 ? 0 : currentPage - 4}" />
                            <c:set var="endPage" value="${startPage + 9 >= totalPages ? totalPages - 1 : startPage + 9}" />
                            <c:forEach var="i" begin="${startPage}" end="${endPage}">
                                <c:url var="pgIT" value="/boards/${boardType}">
                                    <c:param name="page" value="${i}"/>
                                    <c:if test="${boardType eq 'free' and communityFilter eq 'free'}"><c:param name="filter" value="free"/></c:if>
                                    <c:if test="${boardType eq 'free' and communityFilter eq 'guide'}"><c:param name="filter" value="guide"/></c:if>
                                    <c:if test="${boardType eq 'report' and reportStatusFilter eq 'pending'}"><c:param name="reportStatus" value="pending"/></c:if>
                                    <c:if test="${boardType eq 'report' and reportStatusFilter eq 'completed'}"><c:param name="reportStatus" value="completed"/></c:if>
                                    <c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if>
                                </c:url>
                                <a href="${pgIT}" class="page-btn ${i == currentPage ? 'active' : ''}">${i + 1}</a>
                            </c:forEach>
                            <c:url var="pgNextT" value="/boards/${boardType}">
                                <c:param name="page" value="${currentPage + 1}"/>
                                <c:if test="${boardType eq 'free' and communityFilter eq 'free'}"><c:param name="filter" value="free"/></c:if>
                                <c:if test="${boardType eq 'free' and communityFilter eq 'guide'}"><c:param name="filter" value="guide"/></c:if>
                                <c:if test="${boardType eq 'report' and reportStatusFilter eq 'pending'}"><c:param name="reportStatus" value="pending"/></c:if>
                                <c:if test="${boardType eq 'report' and reportStatusFilter eq 'completed'}"><c:param name="reportStatus" value="completed"/></c:if>
                                <c:if test="${not empty boardSearchQ}"><c:param name="q" value="${boardSearchQ}"/></c:if>
                            </c:url>
                            <a href="${pgNextT}" class="page-btn ${currentPage + 1 >= totalPages ? 'disabled' : ''}">
                                <i class="fa-solid fa-chevron-right fa-xs"></i>
                            </a>
                        </c:otherwise>
                    </c:choose>
                </nav>
            </c:if>
        </section>
    </div>
</main>

<%@ include file="/WEB-INF/views/fragments/footer.jspf" %>

<script>
  (function(){
    const btn = document.getElementById('btnWrite');
    if (!btn) return;
    const loggedIn = btn.dataset.loggedIn === 'true';
    if (loggedIn) return;

    btn.addEventListener('click', function(e){
      e.preventDefault();
      alert('로그인해야 이용이 가능합니다.');
      const redirect = encodeURIComponent(btn.dataset.redirect || '/');
      window.location.href = '${ctx}/login?redirect=' + redirect;
    });
  })();
</script>
<c:if test="${boardType eq 'fanmeeting'}">
<script defer src="${ctx}/js/fanmeeting-map-board.js" charset="UTF-8"></script>
</c:if>

</body>
</html>
