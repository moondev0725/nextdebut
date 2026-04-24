<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>NEXT DEBUT - 도감</title>
    <%@ include file="/WEB-INF/views/fragments/head-common.jspf" %>
    <style>
        *, *::before, *::after { box-sizing: border-box; }

        body.page-main {
            background:
                radial-gradient(circle at top left, rgba(233,176,196,0.28), transparent 32%),
                radial-gradient(circle at top right, rgba(186,198,220,0.26), transparent 30%),
                radial-gradient(circle at bottom center, rgba(204,186,216,0.20), transparent 38%),
                linear-gradient(135deg, #f7f2f8 0%, #eef2f9 52%, #f7f4fb 100%) !important;
            background-attachment: fixed !important;
        }
        body.page-main::before,
        body.page-main::after {
            background: none !important;
            filter: none !important;
        }

        .archive-shell {
            position: relative;
        }

        .archive-card {
            position: relative;
            overflow: hidden;
            border-radius: 34px;
            border: 1px solid rgba(255,255,255,0.72);
            background: rgba(255,255,255,0.58);
            box-shadow:
                0 24px 60px rgba(109, 125, 163, 0.16),
                inset 0 1px 0 rgba(255,255,255,0.6);
            backdrop-filter: blur(22px);
            -webkit-backdrop-filter: blur(22px);
        }
        .archive-card::before {
            content: "";
            position: absolute;
            inset: 0;
            background:
                linear-gradient(135deg, rgba(255,255,255,0.22), transparent 34%),
                radial-gradient(circle at 18% 15%, rgba(233,176,196,0.18), transparent 24%),
                radial-gradient(circle at 84% 18%, rgba(186,198,220,0.16), transparent 22%);
            pointer-events: none;
        }

        /* 도감 상단: 통계 + 필터 한 장의 카드(.archive-hero-toolbar) 안에서 사용 */
        .page-hero {
            position: relative;
            padding: 26px 28px 12px;
            margin-bottom: 0;
        }
        .hero-topline {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 8px 14px;
            border-radius: 999px;
            border: 1px solid rgba(255,255,255,0.72);
            background: rgba(255,255,255,0.52);
            color: #6f628a;
            font-family: "Orbitron", sans-serif;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.28em;
            margin-bottom: 18px;
        }
        .hero-title {
            margin: 0;
            font-family: "Orbitron", sans-serif;
            font-size: clamp(2rem, 4vw, 3.4rem);
            font-weight: 900;
            line-height: 1.05;
            letter-spacing: -0.04em;
            color: #1c2338;
        }
        .hero-title strong {
            background: linear-gradient(110deg, rgb(233,176,196), rgb(204,186,216), rgb(186,198,220));
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero-sub {
            margin: 16px 0 0;
            max-width: 760px;
            color: #5c6479;
            font-size: 15px;
            line-height: 1.8;
        }
        .hero-sub strong {
            color: #1f2638;
            font-weight: 800;
        }

        .summary-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 10px;
            margin-top: 16px;
            align-items: stretch;
        }
        .summary-item {
            position: relative;
            display: flex;
            flex-direction: column;
            justify-content: center;
            min-height: 0;
            padding: 11px 12px 10px;
            border-radius: 16px;
            border: 1px solid rgba(255,255,255,0.7);
            background: rgba(255,255,255,0.48);
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.55);
        }
        .summary-label {
            display: block;
            margin-bottom: 5px;
            font-family: "Orbitron", sans-serif;
            font-size: 9px;
            font-weight: 700;
            letter-spacing: 0.18em;
            color: #8087a1;
        }
        .summary-value {
            display: flex;
            align-items: baseline;
            flex-wrap: wrap;
            gap: 6px;
            row-gap: 2px;
            color: #1f2638;
        }
        .summary-value strong {
            font-family: "Orbitron", sans-serif;
            font-size: 22px;
            font-weight: 900;
            line-height: 1.1;
        }
        .summary-value span {
            font-size: 11px;
            color: #70778e;
        }
        .summary-item--pink { background: linear-gradient(180deg, rgba(255,255,255,0.58), rgba(255,244,248,0.82)); }
        .summary-item--blue { background: linear-gradient(180deg, rgba(255,255,255,0.58), rgba(244,248,255,0.88)); }
        .summary-item--lavender { background: linear-gradient(180deg, rgba(255,255,255,0.58), rgba(247,244,255,0.86)); }

        .archive-hero-toolbar {
            margin-bottom: 22px;
        }
        .archive-hero-toolbar .toolbar.trainee-toolbar {
            margin-top: 4px;
            margin-bottom: 0;
            padding: 14px 28px 18px;
            border-top: 1px solid rgba(255,255,255,0.55);
            gap: 14px;
        }
        .toolbar.trainee-toolbar {
            display: flex;
            flex-direction: column;
            gap: 18px;
            padding: 20px 22px;
            margin-bottom: 0;
        }
        .trainee-toolbar__filters {
            display: flex;
            flex-direction: column;
            gap: 14px;
        }
        .trainee-toolbar__row {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 10px 12px;
        }
        .trainee-toolbar__label {
            flex: 0 0 auto;
            min-width: 3rem;
            font-family: "Orbitron", sans-serif;
            font-size: 10px;
            font-weight: 800;
            letter-spacing: 0.14em;
            color: #8b93a8;
            text-transform: uppercase;
        }
        .trainee-toolbar__chips {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            align-items: center;
            flex: 1;
            min-width: 0;
        }
        .trainee-toolbar__bottom {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 12px;
            padding-top: 4px;
            border-top: 1px solid rgba(255,255,255,0.65);
        }
        .trainee-toolbar__search-form {
            display: flex;
            flex: 1;
            align-items: center;
            gap: 8px;
            min-width: min(100%, 260px);
            flex-wrap: nowrap;
        }
        .trainee-toolbar__search-form .search-box {
            flex: 1;
            min-width: 0;
            width: auto;
            max-width: none;
        }
        .trainee-search-btn {
            flex: 0 0 auto;
            height: 46px;
            padding: 0 20px;
            border-radius: 18px;
            border: 1px solid rgba(186,198,220,0.55);
            background: linear-gradient(135deg, rgba(255,255,255,0.95), rgba(247,243,251,0.98));
            color: #1c2338;
            font-size: 14px;
            font-weight: 800;
            cursor: pointer;
            white-space: nowrap;
            box-shadow: 0 4px 14px rgba(140, 150, 180, 0.1);
            transition: transform 0.15s ease, box-shadow 0.15s ease;
        }
        .trainee-search-btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 8px 20px rgba(143, 117, 168, 0.14);
        }
        .trainee-toolbar__clear {
            flex: 0 0 auto;
            font-size: 13px;
            font-weight: 600;
            color: #6d768f;
            text-decoration: none;
            white-space: nowrap;
        }
        .trainee-toolbar__clear:hover {
            color: #1c2338;
            text-decoration: underline;
        }
        .trainee-toolbar__sort {
            flex: 0 1 auto;
            min-width: 140px;
            margin-left: auto;
        }
        .filter-tabs,
        .tool-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: center;
        }
        .filter-pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 11px 18px;
            border-radius: 999px;
            border: 1px solid rgba(255,255,255,0.84);
            background: rgba(255,255,255,0.66);
            color: #5c6479;
            font-size: 13px;
            font-weight: 700;
            text-decoration: none;
            transition: transform 160ms ease, box-shadow 160ms ease, color 160ms ease;
        }
        .filter-pill:hover {
            transform: translateY(-1px);
            box-shadow: 0 14px 28px rgba(140, 150, 180, 0.12);
            color: #21283a;
        }
        .filter-pill.active {
            color: #1c2338;
            box-shadow: 0 16px 32px rgba(143, 117, 168, 0.16);
        }
        .filter-pill--all.active {
            background: linear-gradient(135deg, rgba(255,255,255,0.9), rgba(247,243,251,0.95));
        }
        .filter-pill--male.active {
            background: linear-gradient(135deg, rgba(255,255,255,0.88), rgba(236,243,255,0.96));
            border-color: rgba(186,198,220,0.95);
        }
        .filter-pill--female.active {
            background: linear-gradient(135deg, rgba(255,255,255,0.9), rgba(255,239,245,0.98));
            border-color: rgba(233,176,196,0.95);
        }
        .filter-pill--grade {
            min-width: 2.75rem;
            justify-content: center;
            padding-left: 14px;
            padding-right: 14px;
        }
        .filter-pill--grade.active {
            background: linear-gradient(135deg, rgba(255,255,255,0.88), rgba(245,243,255,0.96));
            border-color: rgba(167,139,250,0.55);
            color: #1c2338;
        }

        .search-box,
        .sort-box {
            border-radius: 18px;
            border: 1px solid rgba(255,255,255,0.82);
            background: rgba(255,255,255,0.72);
            color: #273048;
            font-size: 14px;
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.5);
        }
        .search-box {
            width: min(320px, 100%);
            height: 46px;
            padding: 0 16px;
            outline: none;
        }
        .sort-box {
            height: 46px;
            padding: 0 16px;
            outline: none;
            cursor: pointer;
        }
        .search-box::placeholder { color: #8f97ad; }

        .board-card {
            padding: 26px 24px 30px;
        }
        .section-head {
            display: flex;
            justify-content: space-between;
            align-items: end;
            gap: 12px;
            margin-bottom: 18px;
        }
        .section-title {
            margin: 0;
            color: #1b2234;
            font-size: 22px;
            font-weight: 800;
        }
        .section-copy {
            color: #6d768f;
            font-size: 14px;
        }
        .result-count {
            font-family: "Orbitron", sans-serif;
            font-size: 12px;
            letter-spacing: 0.16em;
            color: #7e86a0;
        }

        .trainee-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
            gap: 18px;
        }
        .group-section {
            margin-bottom: 28px;
            padding-top: 18px;
            border-top: 1px solid rgba(186, 194, 214, 0.38);
        }
        .group-section:first-child {
            padding-top: 0;
            border-top: none;
        }
        .group-section:last-child {
            margin-bottom: 0;
        }
        .group-section-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 12px;
        }
        .group-section-title {
            margin: 0;
            font-size: 30px;
            font-weight: 900;
            letter-spacing: -0.01em;
            color: #1f2638;
            text-shadow: 0 2px 12px rgba(84, 94, 120, 0.18);
        }
        .group-section-count {
            font-family: "Orbitron", sans-serif;
            font-size: 11px;
            letter-spacing: 0.08em;
            color: #8d95ad;
        }
        .group-section-title--riize {
            color: #ff8c1a;
            text-shadow: 0 0 14px rgba(255, 140, 26, 0.45), 0 0 26px rgba(255, 170, 76, 0.26);
        }
        .group-section-title--exo {
            color: #5c4a2f;
            text-shadow: 0 0 10px rgba(243, 227, 196, 0.5), 0 0 18px rgba(192, 166, 123, 0.35);
        }
        .group-section-title--h2h {
            background: linear-gradient(120deg, rgb(233,176,196), rgb(204,186,216), rgb(186,198,220));
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
            text-shadow: none;
            filter: drop-shadow(0 0 12px rgba(204,186,216,0.45));
        }
        .group-section-title--aespa {
            background: linear-gradient(120deg, #8d95a6 0%, #6f788d 45%, #555e74 100%);
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
            text-shadow: none;
            filter: drop-shadow(0 0 10px rgba(143, 152, 173, 0.46));
        }
        .group-section-title--redvelvet {
            background: linear-gradient(120deg, #d90429 0%, #b11226 42%, #7a1f2b 62%, #5f1d2d 100%);
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
            text-shadow: none;
            filter: drop-shadow(0 0 12px rgba(185, 25, 53, 0.42));
        }
        .group-section-title--hidden {
            background: linear-gradient(120deg, #10b981 0%, #34d399 45%, #6ee7b7 100%);
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
            text-shadow: none;
            filter: drop-shadow(0 0 10px rgba(16,185,129,0.45));
        }

        .trainee-card {
            position: relative;
            overflow: hidden;
            border-radius: 26px;
            border: 1px solid rgba(255,255,255,0.84);
            background: rgba(255,255,255,0.72);
            box-shadow:
                0 18px 42px rgba(118, 132, 165, 0.14),
                inset 0 1px 0 rgba(255,255,255,0.65);
            transition: transform 180ms ease, box-shadow 180ms ease, border-color 180ms ease;
            cursor: pointer;
        }
        .trainee-card:hover {
            transform: translateY(-6px);
            box-shadow:
                0 28px 52px rgba(118, 132, 165, 0.2),
                0 0 0 1px rgba(255,255,255,0.4) inset;
        }
        .trainee-card--male:hover { border-color: rgba(186,198,220,0.92); }
        .trainee-card--female:hover { border-color: rgba(233,176,196,0.92); }

        .card-media {
            position: relative;
            height: 286px;
            overflow: hidden;
            background: linear-gradient(180deg, rgba(226,233,245,0.85), rgba(245,239,247,0.92));
        }
        .card-media-fill {
            position: absolute;
            inset: 0;
            z-index: 0;
        }
        .card-media img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            object-position: center top;
            display: block;
            transition: transform 220ms ease;
        }
        .trainee-card:hover .card-media-fill img { transform: scale(1.04); }
        .card-media::after {
            content: "";
            position: absolute;
            inset: auto 0 0 0;
            height: 48%;
            z-index: 1;
            pointer-events: none;
            background: linear-gradient(180deg, rgba(255,255,255,0) 0%, rgba(255,255,255,0.06) 18%, rgba(255,255,255,0.95) 100%);
        }
        .card-lock {
            position: absolute;
            inset: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 2;
            pointer-events: none;
            background: linear-gradient(180deg, rgba(12, 14, 22, 0.10), rgba(12, 14, 22, 0.22));
        }
        .card-lock i {
            font-size: 53px;
            color: #fff;
            opacity: 0.8;
            text-shadow: 0 6px 16px rgba(0, 0, 0, 0.28);
        }
        .card-placeholder {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 64px;
            color: rgba(132, 142, 166, 0.28);
        }

        .card-topline {
            position: absolute;
            top: 14px;
            left: 14px;
            right: 14px;
            z-index: 3;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
        }
        .grade-badge,
        .gender-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 36px;
            height: 36px;
            padding: 0 12px;
            border-radius: 999px;
            border: 1px solid rgba(255,255,255,0.72);
            background: rgba(255,255,255,0.62);
            box-shadow: 0 10px 18px rgba(74, 84, 108, 0.08);
            color: #2d3550;
            font-family: "Orbitron", sans-serif;
            font-size: 12px;
            font-weight: 800;
        }
        .gender-badge {
            min-width: auto;
            padding: 0 11px 0 9px;
            gap: 5px;
        }
        .gender-badge__text {
            font-size: 12px;
            font-weight: 800;
            letter-spacing: 0.02em;
        }
        .grade-n { color: #475569; background: linear-gradient(135deg, rgba(226,232,240,0.96), rgba(203,213,225,0.88)); }
        .grade-r { color: #1d4ed8; background: linear-gradient(135deg, rgba(219,234,254,0.95), rgba(147,197,253,0.82)); }
        .grade-sr { color: #6d28d9; background: linear-gradient(135deg, rgba(237,233,254,0.96), rgba(196,181,253,0.88)); }
        .grade-ssr { color: #92400e; background: linear-gradient(135deg, rgba(254,243,199,0.98), rgba(251,191,36,0.85)); }
        .grade-hidden { color: #065f46; background: linear-gradient(135deg, rgba(209,250,229,0.98), rgba(52,211,153,0.9)); }
        .gender-male { color: #5c79a6; }
        .gender-female { color: #b66b85; }

        .ownership-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-height: 36px;
            padding: 0 12px;
            border-radius: 999px;
            border: 1px solid rgba(255,255,255,0.72);
            background: rgba(255,255,255,0.62);
            box-shadow: 0 10px 18px rgba(74, 84, 108, 0.08);
            font-family: "Noto Sans KR", sans-serif;
            font-size: 11px;
            font-weight: 800;
            letter-spacing: 0.02em;
        }
        .ownership-badge--owned {
            color: #0f766e;
            background: linear-gradient(135deg, rgba(204,251,241,0.95), rgba(167,243,208,0.88));
            border-color: rgba(45,212,191,0.45);
        }
        .ownership-badge--missing {
            color: #64748b;
            background: linear-gradient(135deg, rgba(241,245,249,0.95), rgba(226,232,240,0.9));
            border-color: rgba(148,163,184,0.5);
        }
        /* 미보유: 카드 전체 흑백(자식 포함 일괄 처리) */
        .trainee-card--unowned {
            filter: grayscale(1);
            opacity: 0.9;
        }
        .trainee-card--unowned:hover {
            filter: grayscale(0.92);
            opacity: 0.94;
        }
        .trainee-img--owned,
        .trainee-img--guest {
            filter: none;
            opacity: 1;
        }
        .tag-chip--dim {
            background: rgba(241,245,249,0.9) !important;
            color: #64748b !important;
            border-color: rgba(148,163,184,0.35) !important;
        }

        .card-body {
            position: relative;
            z-index: 2;
            padding: 18px 18px 18px;
            margin-top: -28px;
        }
        .card-name-row {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            align-items: flex-start;
            margin-bottom: 10px;
        }
        .card-name-row__meta {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 8px;
            flex-shrink: 0;
        }
        .card-like-pill {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 800;
            color: #b44a7a;
            background: rgba(255, 232, 244, 0.85);
            border: 1px solid rgba(233, 176, 196, 0.55);
        }
        .card-like-pill i {
            font-size: 11px;
            opacity: 0.9;
        }
        .card-name {
            margin: 0;
            color: #1f2638;
            font-size: 22px;
            font-weight: 800;
            line-height: 1.1;
        }
        .enhance-mark {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-left: 8px;
            font-family: "Orbitron", sans-serif;
            font-size: 9px;
            font-weight: 900;
            letter-spacing: 0.06em;
            padding: 2px 7px;
            border-radius: 999px;
            border: 1px solid rgba(148,163,184,.4);
            background: rgba(255,255,255,.82);
            color: #64748b;
        }
        .enhance-mark.lv-0 { color: #64748b; }
        .enhance-mark.lv-1 { color: #b45309; border-color: rgba(251,191,36,.4); background: rgba(254,243,199,.85); }
        .enhance-mark.lv-2 { color: #a16207; border-color: rgba(251,191,36,.5); background: rgba(254,240,138,.84); }
        .enhance-mark.lv-3 { color: #92400e; border-color: rgba(245,158,11,.58); background: rgba(253,230,138,.86); }
        .enhance-mark.lv-4 { color: #7c2d12; border-color: rgba(245,158,11,.65); background: rgba(251,191,36,.34); }
        .enhance-mark.lv-5 {
            color: #713f12;
            border-color: rgba(234,179,8,.72);
            background: linear-gradient(135deg,rgba(254,249,195,.9),rgba(250,204,21,.8));
            box-shadow: 0 0 10px rgba(250,204,21,.35);
        }
        .card-id {
            display: block;
            margin-top: 5px;
            font-family: "Orbitron", sans-serif;
            font-size: 10px;
            letter-spacing: 0.18em;
            color: #8d95ad;
        }
        .card-total {
            text-align: right;
            flex-shrink: 0;
        }
        .card-total strong {
            display: block;
            font-family: "Orbitron", sans-serif;
            font-size: 18px;
            font-weight: 900;
            color: #1e2437;
            line-height: 1;
        }
        .card-total span {
            display: block;
            margin-top: 4px;
            font-size: 10px;
            color: #8d95ad;
            letter-spacing: 0.18em;
        }

        .tag-row {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 14px;
        }
        .tag-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 7px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
            color: #55607b;
            border: 1px solid rgba(255,255,255,0.8);
            background: rgba(255,255,255,0.64);
        }
        .tag-chip--pink { background: rgba(255,240,245,0.88); color: #a05d78; }
        .tag-chip--blue { background: rgba(240,247,255,0.92); color: #607ea7; }
        .tag-chip--lavender { background: rgba(245,241,255,0.94); color: #7b6998; }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 10px;
        }
        .mini-stat {
            padding: 12px 10px;
            border-radius: 18px;
            background: rgba(247,248,252,0.92);
            border: 1px solid rgba(255,255,255,0.72);
            text-align: center;
        }
        .mini-stat label {
            display: block;
            margin-bottom: 6px;
            font-size: 10px;
            font-weight: 800;
            letter-spacing: 0.16em;
            color: #8a92a9;
        }
        .mini-stat strong {
            display: block;
            color: #20283b;
            font-family: "Orbitron", sans-serif;
            font-size: 18px;
            font-weight: 900;
            line-height: 1;
        }

        .card-foot {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            margin-top: 14px;
            color: #70788f;
            font-size: 12px;
            font-weight: 700;
        }
        .card-foot span {
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .empty-state {
            padding: 70px 24px;
            text-align: center;
            border-radius: 26px;
            border: 1px dashed rgba(152, 161, 185, 0.35);
            background: rgba(255,255,255,0.42);
            color: #7b849f;
        }
        .empty-state i {
            display: block;
            margin-bottom: 14px;
            font-size: 42px;
            color: #b2b9cb;
        }

        .detail-overlay {
            position: fixed;
            inset: 0;
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            background: rgba(19, 23, 34, 0.35);
            backdrop-filter: blur(18px);
            -webkit-backdrop-filter: blur(18px);
            opacity: 0;
            pointer-events: none;
            transition: opacity 180ms ease;
        }
        .detail-overlay.is-open {
            opacity: 1;
            pointer-events: auto;
        }
        .detail-modal {
            width: min(1020px, 100%);
            max-height: min(94vh, 860px);
            overflow: hidden;
            border-radius: 34px;
            border: 1px solid rgba(255,255,255,0.78);
            background: rgba(255,255,255,0.86);
            box-shadow: 0 36px 90px rgba(65, 76, 98, 0.24);
            transform: translateY(18px) scale(0.98);
            transition: transform 180ms ease;
        }
        .detail-overlay.is-open .detail-modal {
            transform: translateY(0) scale(1);
        }
        .detail-header {
            display: grid;
            grid-template-columns: minmax(280px, 360px) minmax(0, 1fr);
            gap: 0;
            height: min(94vh, 860px);
        }
        .detail-photo {
            position: relative;
            min-height: 100%;
            background: linear-gradient(180deg, rgba(226,233,245,0.95), rgba(248,243,249,0.94));
            overflow: hidden;
        }
        .detail-photo img,
        .detail-photo .card-placeholder {
            width: 100%;
            height: 100%;
            object-fit: cover;
            object-position: center top;
        }
        .detail-photo::after {
            content: "";
            position: absolute;
            inset: auto 0 0 0;
            height: 40%;
            background: linear-gradient(180deg, rgba(255,255,255,0) 0%, rgba(255,255,255,0.72) 70%, rgba(255,255,255,0.92) 100%);
        }
        .detail-modal {
            position: relative;
        }
        .detail-close {
            position: absolute;
            top: 18px;
            right: 18px;
            z-index: 20;
            width: 42px;
            height: 42px;
            border: 0;
            border-radius: 50%;
            background: rgba(255,255,255,0.76);
            color: #2b3348;
            cursor: pointer;
            box-shadow: 0 10px 24px rgba(78, 91, 114, 0.14);
        }
        .detail-info {
            padding: 24px 24px 20px;
            overflow: hidden;
        }
        .detail-eyebrow {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 14px;
            margin-bottom: 16px;
            border-radius: 999px;
            background: rgba(248,248,252,0.9);
            border: 1px solid rgba(236,238,244,0.9);
            color: #7a8298;
            font-family: "Orbitron", sans-serif;
            font-size: 10px;
            font-weight: 800;
            letter-spacing: 0.18em;
        }
        .detail-name {
            margin: 0;
            color: #1b2234;
            font-size: clamp(30px, 4vw, 42px);
            font-weight: 900;
            line-height: 1.04;
        }
        .detail-sub {
            margin: 8px 0 0;
            color: #677089;
            font-size: 14px;
            line-height: 1.55;
        }
        .detail-enhance-row {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-top: 8px;
            margin-bottom: 8px;
            flex-wrap: wrap;
        }
        .detail-owned-card {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            min-height: 36px;
            padding: 0 12px;
            border-radius: 999px;
            border: 1px solid rgba(226,232,240,0.95);
            background: linear-gradient(135deg, rgba(255,255,255,0.95), rgba(248,250,252,0.92));
            box-shadow: 0 4px 14px rgba(148,163,184,0.16);
        }
        .detail-owned-card i {
            color: #f59e0b;
            font-size: 13px;
        }
        .detail-owned-card__label {
            font-size: 12px;
            font-weight: 800;
            color: #64748b;
            letter-spacing: 0.02em;
        }
        .detail-owned-card__value {
            font-family: "Orbitron", sans-serif;
            font-size: 12px;
            font-weight: 900;
            color: #0f172a;
        }
        .enhance-open-btn {
            border: 1px solid rgba(167, 139, 250, 0.52);
            border-radius: 999px;
            background: linear-gradient(135deg, rgba(255,255,255,0.94), rgba(245,243,255,0.98));
            color: #5b21b6;
            font-size: 12px;
            font-weight: 800;
            padding: 8px 14px;
            cursor: pointer;
        }
        .enhance-open-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        .detail-badges {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin: 12px 0 14px;
        }
        .detail-badge {
            padding: 9px 14px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 800;
            border: 1px solid rgba(255,255,255,0.72);
            background: rgba(255,255,255,0.72);
            color: #56617d;
        }
        .detail-grid {
            display: grid;
            grid-template-columns: minmax(0, 1.1fr) minmax(280px, .9fr);
            gap: 12px;
        }
        .detail-panel {
            padding: 14px;
            border-radius: 24px;
            border: 1px solid rgba(255,255,255,0.82);
            background: rgba(248,249,252,0.8);
        }
        .detail-panel h3 {
            margin: 0 0 10px;
            color: #1f2638;
            font-size: 15px;
            font-weight: 800;
        }
        .profile-list {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 8px;
        }
        .profile-item {
            padding: 9px 11px;
            border-radius: 18px;
            background: rgba(255,255,255,0.78);
            border: 1px solid rgba(255,255,255,0.86);
        }
        .profile-item label {
            display: block;
            margin-bottom: 4px;
            color: #8b93aa;
            font-size: 10px;
            font-weight: 800;
            letter-spacing: 0.16em;
        }
        .profile-item strong,
        .profile-item a,
        .profile-item span {
            color: #252d41;
            font-size: 13px;
            line-height: 1.45;
            word-break: break-word;
        }
        .profile-item a {
            text-decoration: none;
        }

        .stat-stack {
            display: grid;
            gap: 8px;
        }
        .stat-bar {
            padding: 10px 12px 11px;
            border-radius: 18px;
            background: rgba(255,255,255,0.8);
            border: 1px solid rgba(255,255,255,0.86);
        }
        .stat-bar-head {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 7px;
            color: #263046;
            font-size: 12px;
            font-weight: 800;
        }
        .stat-value-main {
            color: #263046;
        }
        .stat-value-bonus {
            margin-left: 4px;
            color: #b45309;
            font-weight: 900;
            text-shadow: 0 0 8px rgba(245, 158, 11, 0.24);
        }
        .stat-track {
            height: 10px;
            border-radius: 999px;
            background: rgba(227,232,242,0.92);
            overflow: hidden;
        }
        .stat-fill {
            height: 100%;
            border-radius: inherit;
            background: linear-gradient(90deg, rgb(233,176,196), rgb(204,186,216), rgb(186,198,220));
        }
        .total-panel {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            padding: 12px 14px;
            margin-top: 10px;
            border-radius: 20px;
            background: linear-gradient(135deg, rgba(255,240,245,0.86), rgba(241,247,255,0.9));
            border: 1px solid rgba(255,255,255,0.9);
        }
        .total-panel span {
            color: #6c7590;
            font-size: 12px;
            font-weight: 800;
            letter-spacing: 0.18em;
        }
        .total-panel strong {
            color: #1d2437;
            font-family: "Orbitron", sans-serif;
            font-size: 25px;
            font-weight: 900;
            line-height: 1;
        }

        @media (max-width: 960px) {
            .summary-grid,
            .detail-header,
            .detail-grid {
                grid-template-columns: 1fr;
            }
            .trainee-toolbar__sort {
                margin-left: 0;
                width: 100%;
            }
            .detail-photo { min-height: 360px; }
        }
        @media (max-width: 720px) {
            .archive-hero-toolbar .page-hero,
            .archive-hero-toolbar .toolbar.trainee-toolbar,
            .page-hero,
            .toolbar,
            .board-card,
            .detail-info { padding: 22px; }
            .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .profile-list,
            .stats-grid { grid-template-columns: 1fr; }
            .trainee-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .card-media { height: 230px; }
            .card-name { font-size: 18px; }
        }
        @media (max-width: 540px) {
            .summary-grid,
            .trainee-grid { grid-template-columns: 1fr; }
            .trainee-toolbar__bottom { flex-direction: column; align-items: stretch; }
            .trainee-toolbar__search-form { flex-wrap: wrap; }
            .trainee-toolbar__search-form .trainee-search-btn { width: 100%; }
            .trainee-toolbar__sort { width: 100%; }
        }
        .detail-photocard { margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(236,238,244,0.95); }
        .detail-photo--carousel { display: flex; flex-direction: column; align-items: stretch; justify-content: flex-end; padding: 0; }
        .detail-photo--carousel::after { display: none; }
        .detail-photo-viewport {
            position: relative;
            flex: 1;
            min-height: 360px;
            overflow: hidden;
            z-index: 1;
        }
        .detail-photo-track {
            display: flex;
            height: 100%;
            transition: transform 0.38s cubic-bezier(0.25, 0.8, 0.25, 1);
            will-change: transform;
        }
        .detail-photo-slide {
            position: relative;
            flex: 0 0 100%;
            width: 100%;
            min-width: 100%;
            height: 100%;
        }
        .detail-photo-slide img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            object-position: center top;
            display: block;
        }
        .detail-photo-grade {
            position: absolute;
            top: 10px;
            left: 10px;
            z-index: 3;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 48px;
            height: 30px;
            padding: 0 10px;
            border-radius: 999px;
            border: 1px solid rgba(255,255,255,0.75);
            background: rgba(255,255,255,0.82);
            color: #334155;
            font-family: "Orbitron", sans-serif;
            font-size: 11px;
            font-weight: 900;
            letter-spacing: 0.06em;
            box-shadow: 0 10px 20px rgba(30,41,59,0.18);
        }
        .detail-photo-grade--base { color: #334155; }
        .detail-photo-grade--r { color: #5b21b6; background: rgba(245,243,255,0.9); }
        .detail-photo-grade--sr { color: #334155; background: rgba(241,245,249,0.95); }
        .detail-photo-grade--ssr { color: #92400e; background: rgba(254,243,199,0.9); }
        .detail-photo-slide-lock {
            position: absolute;
            inset: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(15, 23, 42, 0.42);
            color: #fff;
            font-weight: 900;
            font-size: 15px;
            letter-spacing: 0.06em;
            text-shadow: 0 2px 12px rgba(0, 0, 0, 0.45);
        }
        .detail-photo-nav {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            z-index: 4;
            width: 40px;
            height: 40px;
            border: 0;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.82);
            color: #334155;
            cursor: pointer;
            box-shadow: 0 8px 22px rgba(30, 41, 59, 0.18);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
        }
        .detail-photo-nav:hover { filter: brightness(1.05); }
        .detail-photo-nav--prev { left: 10px; }
        .detail-photo-nav--next { right: 10px; }
        .detail-photo-dots {
            display: flex;
            justify-content: center;
            gap: 8px;
            padding: 10px 0 4px;
            z-index: 3;
        }
        .detail-photo-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            border: none;
            padding: 0;
            background: rgba(148, 163, 184, 0.55);
            cursor: pointer;
        }
        .detail-photo-dot.is-active {
            background: linear-gradient(135deg, #a78bfa, #6366f1);
            transform: scale(1.15);
        }
        .pc-tier-grid { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
        .pc-tier-btn {
            padding: 10px 16px; border-radius: 14px; border: 1px solid rgba(167,139,250,0.38);
            font-weight: 800; font-size: 13px; background: rgba(255,255,255,0.9); color: #334155;
            cursor: pointer; font-family: "Orbitron", sans-serif; letter-spacing: 0.06em;
        }
        .pc-tier-btn.is-equipped { border-color: #22c55e; box-shadow: 0 0 0 2px rgba(34,197,94,0.22); color: #14532d; }
        .pc-tier-btn.is-locked { opacity: 0.48; cursor: not-allowed; }
        .trainee-card.card-glow-r{
            box-shadow:0 0 20px rgba(139,92,246,0.45),0 0 28px rgba(167,139,250,0.35),0 18px 42px rgba(118,132,165,0.14);
            border-color:rgba(139,92,246,.5);
        }
        .trainee-card.card-glow-sr{
            box-shadow:0 0 22px rgba(226,232,240,0.95),0 0 18px rgba(148,163,184,0.55),0 18px 42px rgba(118,132,165,0.14);
            border-color:rgba(203,213,225,.9);
        }
        .trainee-card.card-glow-ssr{
            box-shadow:0 0 24px rgba(251,191,36,0.5),0 0 20px rgba(245,158,11,0.4),0 18px 42px rgba(118,132,165,0.14);
            border-color:rgba(251,191,36,.65);
        }
        .trainee-card.trainee-card--hidden{
            box-shadow:0 0 24px rgba(16,185,129,0.42),0 0 18px rgba(52,211,153,0.3),0 18px 42px rgba(118,132,165,0.14);
            border-color:rgba(16,185,129,.62);
        }
        .enhance-overlay {
            position: fixed;
            inset: 0;
            z-index: 10040;
            display: none;
            align-items: center;
            justify-content: center;
            padding: 20px;
            background: rgba(15,23,42,0.34);
        }
        .enhance-overlay.is-open { display: flex; }
        .enhance-modal {
            width: min(460px, 100%);
            border-radius: 24px;
            border: 1px solid rgba(255,255,255,0.85);
            background: rgba(255,255,255,0.94);
            box-shadow: 0 28px 64px rgba(30,41,59,0.24);
            padding: 18px 18px 16px;
            position: relative;
            overflow: hidden;
        }
        .enhance-head-title {
            font-size: 17px;
            font-weight: 900;
            color: #0f172a;
        }
        .enhance-state-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 8px;
            margin-top: 10px;
        }
        .enhance-state-item {
            border: 1px solid rgba(203,213,225,0.72);
            border-radius: 12px;
            background: rgba(248,250,252,0.9);
            padding: 8px 10px;
            text-align: center;
        }
        .enhance-state-item label {
            display: block;
            font-size: 10px;
            letter-spacing: 0.06em;
            color: #64748b;
            font-weight: 800;
        }
        .enhance-state-item strong {
            display: block;
            margin-top: 3px;
            font-family: "Orbitron", sans-serif;
            font-size: 14px;
            color: #0f172a;
        }
        .enhance-require-desc {
            margin-top: 10px;
            padding: 10px 12px;
            border-radius: 12px;
            border: 1px solid rgba(226,232,240,0.95);
            background: rgba(255,255,255,0.82);
            font-size: 12px;
            color: #475569;
            line-height: 1.6;
        }
        .enhance-do-btn {
            width: 100%;
            margin-top: 12px;
            min-height: 44px;
            font-size: 14px;
            font-weight: 900;
            letter-spacing: 0.02em;
            border-radius: 12px;
            border: 1px solid rgba(167,139,250,0.55);
            background: linear-gradient(135deg, rgba(139,92,246,0.95), rgba(236,72,153,0.9));
            color: #fff;
            cursor: pointer;
        }
        .enhance-do-btn:disabled {
            background: rgba(148,163,184,0.46);
            border-color: rgba(148,163,184,0.6);
            cursor: not-allowed;
        }
        .enhance-modal::before {
            content: "";
            position: absolute;
            inset: 0;
            pointer-events: none;
            background: radial-gradient(circle at 20% 0%, rgba(251,191,36,0.12), transparent 38%),
                        radial-gradient(circle at 85% 100%, rgba(167,139,250,0.12), transparent 42%);
        }
        .enhance-result {
            margin-top: 10px;
            border-radius: 12px;
            padding: 10px 12px;
            font-size: 13px;
            font-weight: 800;
            color: #374151;
            background: rgba(241,245,249,0.8);
        }
        .enhance-result.is-success { color: #14532d; background: rgba(220,252,231,0.85); animation: enhancePop 360ms ease; }
        .enhance-result.is-fail { color: #7f1d1d; background: rgba(254,226,226,0.9); animation: enhanceShake 460ms ease; }
        .enhance-result i { margin-right: 6px; }
        @keyframes enhancePop {
            0% { transform: scale(0.96); opacity: 0.7; }
            100% { transform: scale(1); opacity: 1; }
        }
        @keyframes enhanceShake {
            0%, 100% { transform: translateX(0); }
            20% { transform: translateX(-4px); }
            40% { transform: translateX(4px); }
            60% { transform: translateX(-2px); }
            80% { transform: translateX(2px); }
        }
        .enhance-celebrate {
            position: absolute;
            inset: 0;
            pointer-events: none;
            opacity: 0;
            z-index: 2;
        }
        .enhance-celebrate.is-active {
            animation: enhanceCelebrate 620ms ease-out;
        }
        .enhance-celebrate::before {
            content: "";
            position: absolute;
            inset: 0;
            background: radial-gradient(circle at center, rgba(254,240,138,0.65), rgba(251,191,36,0.12) 45%, transparent 68%);
        }
        .enhance-celebrate::after {
            content: "";
            position: absolute;
            left: -30%;
            right: -30%;
            top: 44%;
            height: 12px;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.9), transparent);
            transform: rotate(-8deg) translateX(-40%);
        }
        .enhance-celebrate.is-active::after {
            animation: enhanceSweep 520ms ease-out;
        }
        .enhance-celebrate.is-max-active {
            animation: enhanceCelebrateMax 860ms ease-out;
        }
        .enhance-celebrate.is-max-active::before {
            background:
                radial-gradient(circle at center, rgba(255,247,173,0.95), rgba(251,191,36,0.45) 36%, transparent 68%),
                conic-gradient(from 0deg, rgba(255,255,255,0.0), rgba(255,255,255,0.65), rgba(255,255,255,0.0));
        }
        .enhance-celebrate.is-max-active::after {
            height: 16px;
            animation: enhanceSweepMax 760ms ease-out;
        }
        .enhance-max-badge {
            position: absolute;
            top: 12px;
            right: 52px;
            z-index: 3;
            padding: 6px 10px;
            border-radius: 999px;
            border: 1px solid rgba(251,191,36,0.8);
            background: linear-gradient(135deg, rgba(255,248,204,0.96), rgba(251,191,36,0.9));
            color: #5b3a00;
            font-family: "Orbitron", sans-serif;
            font-size: 11px;
            font-weight: 900;
            letter-spacing: 0.08em;
            box-shadow: 0 8px 20px rgba(251,191,36,0.42);
            opacity: 0;
            transform: translateY(-8px) scale(0.94);
            pointer-events: none;
        }
        .enhance-max-badge.is-show {
            animation: enhanceMaxBadgeIn 860ms ease-out forwards;
        }
        @keyframes enhanceCelebrate {
            0% { opacity: 0; transform: scale(0.96); }
            18% { opacity: 1; }
            100% { opacity: 0; transform: scale(1.04); }
        }
        @keyframes enhanceCelebrateMax {
            0% { opacity: 0; transform: scale(0.9); filter: brightness(1.35); }
            20% { opacity: 1; }
            100% { opacity: 0; transform: scale(1.09); filter: brightness(1); }
        }
        @keyframes enhanceSweep {
            0% { transform: rotate(-8deg) translateX(-40%); opacity: 0; }
            20% { opacity: 1; }
            100% { transform: rotate(-8deg) translateX(40%); opacity: 0; }
        }
        @keyframes enhanceSweepMax {
            0% { transform: rotate(-8deg) translateX(-45%); opacity: 0; }
            15% { opacity: 1; }
            100% { transform: rotate(-8deg) translateX(45%); opacity: 0; }
        }
        @keyframes enhanceMaxBadgeIn {
            0% { opacity: 0; transform: translateY(-8px) scale(0.94); }
            25% { opacity: 1; transform: translateY(0) scale(1.04); }
            60% { opacity: 1; transform: translateY(0) scale(1); }
            100% { opacity: 0.92; transform: translateY(0) scale(1); }
        }
        .enhance-modal.is-fail-shake {
            animation: enhanceModalShake 460ms ease;
        }
        @keyframes enhanceModalShake {
            0%,100% { transform: translateX(0); }
            15% { transform: translateX(-6px); }
            30% { transform: translateX(6px); }
            45% { transform: translateX(-5px); }
            60% { transform: translateX(5px); }
            75% { transform: translateX(-2px); }
        }
    </style>
</head>
<body class="page-main min-h-screen flex flex-col">
<%@ include file="/WEB-INF/views/fragments/topnav.jspf" %>

<c:set var="maleCount" value="0"/>
<c:set var="femaleCount" value="0"/>
<c:set var="sumScore" value="0"/>
<c:forEach var="t" items="${trainees}">
    <c:if test="${t.gender == 'MALE'}"><c:set var="maleCount" value="${maleCount + 1}"/></c:if>
    <c:if test="${t.gender == 'FEMALE'}"><c:set var="femaleCount" value="${femaleCount + 1}"/></c:if>
    <c:set var="sumScore" value="${sumScore + t.vocal + t.dance + t.star + t.mental + t.teamwork}"/>
</c:forEach>
<c:set var="avgScore" value="${totalCount == 0 ? 0 : (sumScore / totalCount)}"/>

<main class="flex-1 px-6 pb-16" style="padding-top: calc(var(--nav-h) + 32px);">
    <div class="container mx-auto max-w-6xl archive-shell">
        <section class="archive-card archive-hero-toolbar">
            <div class="page-hero">
                <span class="hero-topline"><i class="fas fa-book-open"></i> TRAINEE INDEX</span>
                <h1 class="hero-title">연습생 <strong>도감</strong></h1>
                <p class="hero-sub">
                    연습생의 프로필·능력치·카드 강화 단계를 한 번에 확인할 수 있습니다.
                    <c:choose>
                        <c:when test="${loggedIn}">로그인 시 <strong>보유한 멤버</strong>는 컬러, 미보유 멤버는 흑백으로 표시되며, 상세 모달에서 <strong>카드 강화</strong>를 진행할 수 있습니다.</c:when>
                        <c:otherwise>로그인하면 보유 여부를 컬러/흑백으로 구분해 보고, 상세 모달에서 카드 강화 기능을 이용할 수 있습니다.</c:otherwise>
                    </c:choose>
                    현재 <strong>${totalCount}명</strong>이 등록되어 있습니다.
                </p>

                <div class="summary-grid">
                    <div class="summary-item summary-item--lavender">
                        <span class="summary-label">TOTAL TRAINEES</span>
                        <div class="summary-value"><strong>${totalCount}</strong><span>명 등록</span></div>
                    </div>
                    <div class="summary-item summary-item--blue">
                        <span class="summary-label">MALE</span>
                        <div class="summary-value"><strong>${maleCount}</strong><span>남자 연습생</span></div>
                    </div>
                    <div class="summary-item summary-item--pink">
                        <span class="summary-label">FEMALE</span>
                        <div class="summary-value"><strong>${femaleCount}</strong><span>여자 연습생</span></div>
                    </div>
                    <div class="summary-item summary-item--lavender">
                        <span class="summary-label">AVG SCORE</span>
                        <div class="summary-value"><strong><fmt:formatNumber value="${avgScore}" maxFractionDigits="2" minFractionDigits="2"/></strong><span>평균 종합점수</span></div>
                    </div>
                </div>
            </div>

            <div class="toolbar trainee-toolbar">
            <div class="trainee-toolbar__filters">
                <div class="trainee-toolbar__row">
                    <span class="trainee-toolbar__label">성별</span>
                    <div class="trainee-toolbar__chips">
                        <c:url var="urlGAll" value="/trainees"><c:param name="gender" value="ALL"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="${selectedGroup}"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGM" value="/trainees"><c:param name="gender" value="MALE"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="${selectedGroup}"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGF" value="/trainees"><c:param name="gender" value="FEMALE"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="${selectedGroup}"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <a href="${urlGAll}" class="filter-pill filter-pill--all ${selectedGender == 'ALL' ? 'active' : ''}">전체</a>
                        <a href="${urlGM}" class="filter-pill filter-pill--male ${selectedGender == 'MALE' ? 'active' : ''}"><i class="fas fa-mars"></i> 남자</a>
                        <a href="${urlGF}" class="filter-pill filter-pill--female ${selectedGender == 'FEMALE' ? 'active' : ''}"><i class="fas fa-venus"></i> 여자</a>
                    </div>
                </div>
                <div class="trainee-toolbar__row">
                    <span class="trainee-toolbar__label">등급</span>
                    <div class="trainee-toolbar__chips">
                        <c:url var="urlGrAll" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="ALL"/><c:param name="group" value="${selectedGroup}"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGrN" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="N"/><c:param name="group" value="${selectedGroup}"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGrR" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="R"/><c:param name="group" value="${selectedGroup}"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGrSR" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="SR"/><c:param name="group" value="${selectedGroup}"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGrSSR" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="SSR"/><c:param name="group" value="${selectedGroup}"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <a href="${urlGrAll}" class="filter-pill filter-pill--grade ${selectedGrade == 'ALL' ? 'active' : ''}">전체</a>
                        <a href="${urlGrN}" class="filter-pill filter-pill--grade ${selectedGrade == 'N' ? 'active' : ''}">N</a>
                        <a href="${urlGrR}" class="filter-pill filter-pill--grade ${selectedGrade == 'R' ? 'active' : ''}">R</a>
                        <a href="${urlGrSR}" class="filter-pill filter-pill--grade ${selectedGrade == 'SR' ? 'active' : ''}">SR</a>
                        <a href="${urlGrSSR}" class="filter-pill filter-pill--grade ${selectedGrade == 'SSR' ? 'active' : ''}">SSR</a>
                    </div>
                </div>
                <div class="trainee-toolbar__row">
                    <span class="trainee-toolbar__label">그룹</span>
                    <div class="trainee-toolbar__chips">
                        <c:url var="urlGpAll" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="ALL"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGpRiize" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="RIIZE"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGpExo" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="EXO"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGpH2h" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="HEARTS2HEARTS"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGpAespa" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="AESPA"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <c:url var="urlGpRv" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="REDVELVET"/><c:if test="${not empty searchQ}"><c:param name="q" value="${searchQ}"/></c:if></c:url>
                        <a href="${urlGpAll}" class="filter-pill ${selectedGroup == 'ALL' ? 'active' : ''}">전체</a>
                        <a href="${urlGpRiize}" class="filter-pill ${selectedGroup == 'RIIZE' ? 'active' : ''}">라이즈</a>
                        <a href="${urlGpExo}" class="filter-pill ${selectedGroup == 'EXO' ? 'active' : ''}">엑소</a>
                        <a href="${urlGpH2h}" class="filter-pill ${selectedGroup == 'HEARTS2HEARTS' ? 'active' : ''}">하츠투하츠</a>
                        <a href="${urlGpAespa}" class="filter-pill ${selectedGroup == 'AESPA' ? 'active' : ''}">에스파</a>
                        <a href="${urlGpRv}" class="filter-pill ${selectedGroup == 'REDVELVET' ? 'active' : ''}">레드벨벳</a>
                    </div>
                </div>
            </div>
            <div class="trainee-toolbar__bottom">
                <form method="get" action="${pageContext.request.contextPath}/trainees" class="trainee-toolbar__search-form" id="traineeSearchForm">
                    <input type="hidden" name="gender" value="${selectedGender}"/>
                    <input type="hidden" name="grade" value="${selectedGrade}"/>
                    <input type="hidden" name="group" value="${selectedGroup}"/>
                    <input type="search" name="q" value="${searchQ}" id="traineeSearch" class="search-box" placeholder="이름으로 검색" autocomplete="off" />
                    <button type="submit" class="trainee-search-btn">검색</button>
                    <c:if test="${not empty searchQ}">
                        <c:url var="urlClearQ" value="/trainees"><c:param name="gender" value="${selectedGender}"/><c:param name="grade" value="${selectedGrade}"/><c:param name="group" value="${selectedGroup}"/></c:url>
                        <a href="${urlClearQ}" class="trainee-toolbar__clear">초기화</a>
                    </c:if>
                </form>
                <select id="traineeSort" class="sort-box trainee-toolbar__sort" aria-label="정렬 방식">
                    <option value="default">기본 정렬</option>
                    <option value="name">이름순</option>
                    <option value="total">종합점수순</option>
                    <option value="vocal">보컬순</option>
                    <option value="dance">댄스순</option>
                    <option value="star">스타성순</option>
                    <option value="mental">멘탈순</option>
                    <option value="teamwork">팀워크순</option>
                </select>
            </div>
        </div>
        </section>

        <section class="archive-card board-card">
            <div class="section-head">
                <div>
                    <h2 class="section-title">도감 목록</h2>
                    <div class="section-copy">
                        <c:choose>
                            <c:when test="${loggedIn}">보유한 멤버만 상세 프로필을 열 수 있습니다. 미보유 카드는 흑백으로 표시됩니다.</c:when>
                            <c:otherwise>목록은 누구나 볼 수 있으며, 카드 상세는 로그인 후 이용할 수 있습니다.</c:otherwise>
                        </c:choose>
                    </div>
                </div>
                <div class="result-count">VISIBLE <span id="visibleCount">${totalCount}</span></div>
            </div>

            <div id="traineeBoard">
                <c:choose>
                    <c:when test="${empty trainees}">
                        <div class="empty-state">
                            <i class="fas fa-user-slash"></i>
                            등록된 연습생이 없습니다.
                        </div>
                    </c:when>
                    <c:otherwise>
                        <c:forEach var="groupEntry" items="${groupedTrainees.entrySet()}">
                            <c:if test="${not empty groupEntry.value}">
                                <section class="group-section" data-group-section="true">
                                    <div class="group-section-head">
                                        <h3 class="group-section-title ${
                                            groupEntry.key == 'RIIZE' ? 'group-section-title--riize' :
                                            (groupEntry.key == 'EXO' ? 'group-section-title--exo' :
                                            (groupEntry.key == 'HEARTS2HEARTS' ? 'group-section-title--h2h' :
                                            (groupEntry.key == 'AESPA' ? 'group-section-title--aespa' :
                                            (groupEntry.key == 'REDVELVET' ? 'group-section-title--redvelvet' :
                                            (groupEntry.key == 'HIDDEN' ? 'group-section-title--hidden' : '')))))
                                        }">
                                            <c:choose>
                                                <c:when test="${groupEntry.key == 'RIIZE'}">라이즈</c:when>
                                                <c:when test="${groupEntry.key == 'EXO'}">엑소</c:when>
                                                <c:when test="${groupEntry.key == 'HEARTS2HEARTS'}">하츠투하츠</c:when>
                                                <c:when test="${groupEntry.key == 'AESPA'}">에스파</c:when>
                                                <c:when test="${groupEntry.key == 'REDVELVET'}">레드벨벳</c:when>
                                                <c:when test="${groupEntry.key == 'HIDDEN'}">HIDDEN</c:when>
                                                <c:otherwise>기타</c:otherwise>
                                            </c:choose>
                                        </h3>
                                        <span class="group-section-count">${fn:length(groupEntry.value)}명</span>
                                    </div>
                                    <div class="trainee-grid">
                        <c:forEach var="t" items="${groupEntry.value}" varStatus="status">
                            <c:set var="isHiddenMask" value="${not empty t.grade and t.grade.name() == 'HIDDEN'}"/>
                            <c:set var="maskedName" value="${isHiddenMask ? 'HIDDEN' : t.name}"/>
                            <c:set var="total" value="${t.vocal + t.dance + t.star + t.mental + t.teamwork}"/>
                            <c:set var="pcs" value="${photoCardSummaries[t.id]}"/>
                            <c:set var="pcImgs" value="${photoCardImageMap[t.id]}"/>
                            <c:set var="cardDisplayImage" value="${ctx}${t.imagePath}"/>
                            <c:if test="${loggedIn and ownedTraineeIds.contains(t.id) and pcs != null and not empty pcs.equippedGrade and pcImgs != null}">
                                <c:choose>
                                    <c:when test="${pcs.equippedGrade == 'R' and not empty pcImgs['R']}">
                                        <c:set var="cardDisplayImage" value="${ctx}${pcImgs['R']}"/>
                                    </c:when>
                                    <c:when test="${pcs.equippedGrade == 'SR' and not empty pcImgs['SR']}">
                                        <c:set var="cardDisplayImage" value="${ctx}${pcImgs['SR']}"/>
                                    </c:when>
                                    <c:when test="${pcs.equippedGrade == 'SSR' and not empty pcImgs['SSR']}">
                                        <c:set var="cardDisplayImage" value="${ctx}${pcImgs['SSR']}"/>
                                    </c:when>
                                </c:choose>
                            </c:if>
                            <c:choose>
                                <c:when test="${loggedIn and ownedTraineeIds.contains(t.id)}"><c:set var="ownStr" value="true"/></c:when>
                                <c:when test="${loggedIn}"><c:set var="ownStr" value="false"/></c:when>
                                <c:otherwise><c:set var="ownStr" value="na"/></c:otherwise>
                            </c:choose>
                            <c:set var="pcGlowClass" value=""/>
                            <c:if test="${loggedIn and pcs != null and not empty pcs.equippedGrade}">
                                <c:set var="pcGlowClass" value="${fn:toLowerCase(pcs.equippedGrade) == 'r' ? 'card-glow-r' : (fn:toLowerCase(pcs.equippedGrade) == 'sr' ? 'card-glow-sr' : 'card-glow-ssr')}"/>
                            </c:if>
                            <div
                                class="trainee-card ${t.gender == 'MALE' ? 'trainee-card--male' : 'trainee-card--female'} ${isHiddenMask ? 'trainee-card--hidden' : ''} ${loggedIn and (ownedTraineeIds.contains(t.id) == false) ? 'trainee-card--unowned' : ''} ${pcGlowClass}"
                                data-order="${status.index}"
                                data-name="${maskedName}"
                                data-total="${total}"
                                data-base-vocal="${isHiddenMask ? 0 : t.vocal}"
                                data-base-dance="${isHiddenMask ? 0 : t.dance}"
                                data-base-star="${isHiddenMask ? 0 : t.star}"
                                data-base-mental="${isHiddenMask ? 0 : t.mental}"
                                data-base-teamwork="${isHiddenMask ? 0 : t.teamwork}"
                                data-vocal="${isHiddenMask ? 0 : t.vocal}"
                                data-dance="${isHiddenMask ? 0 : t.dance}"
                                data-star="${isHiddenMask ? 0 : t.star}"
                                data-mental="${isHiddenMask ? 0 : t.mental}"
                                data-teamwork="${isHiddenMask ? 0 : t.teamwork}"
                                data-id="${t.id}"
                                data-image="${isHiddenMask ? '' : ctx}${isHiddenMask ? '' : t.imagePath}"
                                data-gender="${t.gender}"
                                data-grade="${empty t.grade ? '' : t.grade.name()}"
                                data-group="${isHiddenMask ? 'HIDDEN' : (empty traineeGroups[t.id] ? 'OTHER' : traineeGroups[t.id])}"
                                data-age="${isHiddenMask ? '' : t.age}"
                                data-birthday="${isHiddenMask ? '' : t.birthday}"
                                data-hobby="${isHiddenMask ? '' : t.hobby}"
                                data-instagram="${isHiddenMask ? '' : t.instagram}"
                                data-image-path="${isHiddenMask ? '' : t.imagePath}"
                                data-hidden="${isHiddenMask ? 'true' : 'false'}"
                                data-owned="${ownStr}"
                                data-owned-qty="${ownedTraineeQtyMap[t.id]}"
                                data-enhance-level="${ownedEnhanceLevelMap[t.id] != null ? ownedEnhanceLevelMap[t.id] : 0}"
                                data-pc-r="${pcs != null ? pcs.ownedR : false}"
                                data-pc-sr="${pcs != null ? pcs.ownedSr : false}"
                                data-pc-ssr="${pcs != null ? pcs.ownedSsr : false}"
                                data-pc-img-r="${pcImgs != null ? pcImgs['R'] : ''}"
                                data-pc-img-sr="${pcImgs != null ? pcImgs['SR'] : ''}"
                                data-pc-img-ssr="${pcImgs != null ? pcImgs['SSR'] : ''}"
                                data-pc-eq="${pcs != null && not empty pcs.equippedGrade ? pcs.equippedGrade : ''}"
                                data-pc-bonus="${pcs != null ? pcs.equippedBonusPercent : 0}"
                                onclick="handleTraineeCardClick(this)">
                                <div class="card-media">
                                    <c:if test="${loggedIn and not ownedTraineeIds.contains(t.id)}">
                                        <div class="card-lock" aria-hidden="true">
                                            <i class="fas fa-lock"></i>
                                        </div>
                                    </c:if>
                                    <div class="card-topline">
                                        <span class="grade-badge ${
                                          empty t.grade ? 'grade-n' : (
                                            t.grade.name() == 'N' ? 'grade-n' : (
                                            t.grade.name() == 'R' ? 'grade-r' : (
                                            t.grade.name() == 'SR' ? 'grade-sr' : (
                                            t.grade.name() == 'SSR' ? 'grade-ssr' : 'grade-hidden'
                                          ))))}">${empty t.grade ? '—' : t.grade.name()}</span>
                                        <c:choose>
                                            <c:when test="${loggedIn}">
                                                <span class="ownership-badge ${ownedTraineeIds.contains(t.id) ? 'ownership-badge--owned' : 'ownership-badge--missing'}" title="${ownedTraineeIds.contains(t.id) ? '보유 중' : '미보유'}">
                                                    ${ownedTraineeIds.contains(t.id) ? '보유중' : '미보유'}
                                                </span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="gender-badge ${t.gender == 'MALE' ? 'gender-male' : 'gender-female'}" title="${t.gender == 'MALE' ? '남자 연습생' : '여자 연습생'}">
                                                    <i class="fas ${t.gender == 'MALE' ? 'fa-mars' : 'fa-venus'}" aria-hidden="true"></i>
                                                    <span class="gender-badge__text">${t.gender == 'MALE' ? '남' : '여'}</span>
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                    <div class="card-media-fill">
                                        <c:choose>
                                            <c:when test="${isHiddenMask}">
                                                <div class="card-placeholder"><i class="fas fa-user-secret"></i></div>
                                            </c:when>
                                            <c:when test="${not empty t.imagePath}">
                                                <img src="${cardDisplayImage}" alt="${maskedName}"
                                                    class="${loggedIn and ownedTraineeIds.contains(t.id) ? 'trainee-img--owned' : (loggedIn ? '' : 'trainee-img--guest')}"
                                                    onerror="this.style.display='none'; var fb=this.parentNode.querySelector('.card-placeholder--fallback'); if(fb) fb.style.display='flex';" />
                                                <div class="card-placeholder card-placeholder--fallback" style="display:none" aria-hidden="true"><i class="fas fa-user"></i></div>
                                            </c:when>
                                            <c:otherwise>
                                                <div class="card-placeholder"><i class="fas fa-user"></i></div>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                </div>
                                <div class="card-body">
                                    <div class="card-name-row">
                                        <div>
                                            <h3 class="card-name">${maskedName}<c:if test="${loggedIn and ownedTraineeIds.contains(t.id)}"><span class="enhance-mark lv-${ownedEnhanceLevelMap[t.id] != null ? ownedEnhanceLevelMap[t.id] : 0}">${ownedEnhanceLevelMap[t.id] != null and ownedEnhanceLevelMap[t.id] >= 5 ? 'MAX' : '+'.concat(ownedEnhanceLevelMap[t.id] != null ? ownedEnhanceLevelMap[t.id] : 0)}</span></c:if></h3>
                                            <span class="card-id">${isHiddenMask ? '#HIDDEN' : '#'}${isHiddenMask ? '' : t.id}</span>
                                        </div>
                                        <div class="card-name-row__meta">
                                            <div class="card-total">
                                                <strong>${isHiddenMask ? '???' : total}</strong>
                                                <span>평균 능력치</span>
                                            </div>
                                            <div class="card-like-pill" title="누적 좋아요">
                                                <i class="fas fa-heart" aria-hidden="true"></i>
                                                <span>${empty traineeLikeLabels[t.id] ? '0' : traineeLikeLabels[t.id]}</span>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="tag-row">
                                        <c:choose>
                                            <c:when test="${loggedIn}">
                                                <span class="tag-chip ${ownedTraineeIds.contains(t.id) ? 'tag-chip--lavender' : 'tag-chip--dim'}">
                                                    <i class="fas ${ownedTraineeIds.contains(t.id) ? 'fa-check-circle' : 'fa-lock'}"></i>
                                                    ${ownedTraineeIds.contains(t.id) ? '보유 중' : '미보유'}
                                                </span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="tag-chip ${t.gender == 'MALE' ? 'tag-chip--blue' : 'tag-chip--pink'}">
                                                    <i class="fas ${t.gender == 'MALE' ? 'fa-mars' : 'fa-venus'}"></i>
                                                    ${t.gender == 'MALE' ? '남자 연습생' : '여자 연습생'}
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                        <span class="tag-chip tag-chip--lavender">
                                            <i class="fas fa-star"></i>
                                            ${isHiddenMask ? '히든 등급' : '스타성 '.concat(t.star)}
                                        </span>
                                        <span class="tag-chip">
                                            <i class="fas fa-users"></i>
                                            <c:choose>
                                                <c:when test="${isHiddenMask}">HIDDEN</c:when>
                                                <c:when test="${traineeGroups[t.id] == 'RIIZE'}">라이즈</c:when>
                                                <c:when test="${traineeGroups[t.id] == 'EXO'}">엑소</c:when>
                                                <c:when test="${traineeGroups[t.id] == 'HEARTS2HEARTS'}">하츠투하츠</c:when>
                                                <c:when test="${traineeGroups[t.id] == 'AESPA'}">에스파</c:when>
                                                <c:when test="${traineeGroups[t.id] == 'REDVELVET'}">레드벨벳</c:when>
                                                <c:otherwise>기타</c:otherwise>
                                            </c:choose>
                                        </span>
                                    </div>

                                    <div class="stats-grid">
                                        <div class="mini-stat">
                                            <label>VOCAL</label>
                                            <strong>${isHiddenMask ? '?' : t.vocal}</strong>
                                        </div>
                                        <div class="mini-stat">
                                            <label>DANCE</label>
                                            <strong>${isHiddenMask ? '?' : t.dance}</strong>
                                        </div>
                                        <div class="mini-stat">
                                            <label>STAR</label>
                                            <strong>${isHiddenMask ? '?' : t.star}</strong>
                                        </div>
                                    </div>

                                    <div class="card-foot">
                                        <span><i class="fas fa-heart"></i> 멘탈 ${isHiddenMask ? '?' : t.mental}</span>
                                        <span><i class="fas fa-users"></i> 팀워크 ${isHiddenMask ? '?' : t.teamwork}</span>
                                    </div>
                                </div>
                            </div>
                        </c:forEach>
                                    </div>
                                </section>
                            </c:if>
                        </c:forEach>
                    </c:otherwise>
                </c:choose>
            </div>
        </section>
    </div>
</main>

<div id="detailOverlay" class="detail-overlay" onclick="handleOverlayClose(event)">
    <div class="detail-modal">
        <div class="detail-header">
            <div class="detail-photo" id="detailPhoto"></div>
            <div class="detail-info">
                <div id="detailEyebrow" class="detail-eyebrow">TRAINEE PROFILE</div>
                <h2 id="detailName" class="detail-name">이름</h2>
                <p id="detailSub" class="detail-sub">연습생 상세 정보</p>
                <div class="detail-enhance-row">
                    <span id="detailOwnedQty" class="detail-owned-card">
                        <i class="fas fa-layer-group" aria-hidden="true"></i>
                        <span class="detail-owned-card__label">보유 카드</span>
                        <strong class="detail-owned-card__value">0장</strong>
                    </span>
                    <button type="button" id="detailEnhanceOpenBtn" class="enhance-open-btn">강화하기</button>
                </div>
                <div id="detailBadges" class="detail-badges"></div>

                <div class="detail-grid">
                    <div class="detail-panel">
                        <h3>PROFILE</h3>
                        <div id="detailProfile" class="profile-list"></div>
                        <div id="detailPhotoCardWrap" class="detail-photocard" style="display:none;">
                            <h3 style="margin:18px 0 10px;font-size:16px;font-weight:800;color:#1f2638;">포토카드</h3>
                            <p id="detailPhotoCardHint" style="margin:0 0 12px;line-height:1.6;font-size:14px;color:#5c6479;"></p>
                            <div id="detailPhotoCardTiers" class="pc-tier-grid"></div>
                        </div>
                    </div>
                    <div class="detail-panel">
                        <h3>STATS</h3>
                        <div id="detailStats" class="stat-stack"></div>
                        <div class="total-panel">
                            <span>평균 능력치 (합계)</span>
                            <strong id="detailTotal">0</strong>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div id="enhanceOverlay" class="enhance-overlay" onclick="handleEnhanceOverlayClose(event)">
    <div id="enhanceModalPanel" class="enhance-modal">
        <div id="enhanceCelebrateFx" class="enhance-celebrate" aria-hidden="true"></div>
        <div id="enhanceMaxBadge" class="enhance-max-badge" aria-hidden="true">MAX 달성</div>
        <div class="flex items-center justify-between gap-2">
            <h3 class="enhance-head-title">카드 강화</h3>
            <button type="button" id="enhanceCloseBtn" class="text-xl text-slate-500">&times;</button>
        </div>
        <div class="enhance-state-grid">
            <div class="enhance-state-item"><label>현재</label><strong id="enhanceStateCurrent">+0</strong></div>
            <div class="enhance-state-item"><label>필요 재료</label><strong id="enhanceStateNeed">1장</strong></div>
            <div class="enhance-state-item"><label>보유</label><strong id="enhanceStateOwned">0장</strong></div>
        </div>
        <p id="enhanceInfoText" class="enhance-require-desc"></p>
        <button type="button" id="enhanceDoBtn" class="enhance-do-btn">강화하기</button>
        <div id="enhanceResultBox" class="enhance-result" style="display:none;"></div>
    </div>
</div>

<script>
    (function () {
        var CTX = '${pageContext.request.contextPath}';
        var board = document.getElementById('traineeBoard');
        var cards = Array.prototype.slice.call(board ? board.querySelectorAll('.trainee-card') : []);
        var groupedSections = Array.prototype.slice.call(document.querySelectorAll('[data-group-section="true"]'));
        var searchInput = document.getElementById('traineeSearch');
        var sortSelect = document.getElementById('traineeSort');
        var visibleCount = document.getElementById('visibleCount');

        function updateVisibleCount() {
            var visible = cards.filter(function (card) {
                return card.style.display !== 'none';
            }).length;
            if (visibleCount) visibleCount.textContent = visible;
        }

        function sortCards() {
            if (!board) return;
            var type = sortSelect ? sortSelect.value : 'default';
            groupedSections.forEach(function (section) {
                var grid = section.querySelector('.trainee-grid');
                if (!grid) return;
                var sectionCards = Array.prototype.slice.call(grid.querySelectorAll('.trainee-card'));
                var sorted = sectionCards.slice().sort(function (a, b) {
                    if (type === 'default') {
                        return Number(a.dataset.order) - Number(b.dataset.order);
                    }
                    if (type === 'name') {
                        return String(a.dataset.name).localeCompare(String(b.dataset.name), 'ko');
                    }
                    return Number(b.dataset[type]) - Number(a.dataset[type]);
                });
                sorted.forEach(function (card) { grid.appendChild(card); });
            });
        }

        if (sortSelect) {
            sortSelect.addEventListener('change', function () {
                sortCards();
                updateVisibleCount();
            });
        }
        updateVisibleCount();

        var overlay = document.getElementById('detailOverlay');
        var detailPhoto = document.getElementById('detailPhoto');
        var detailName = document.getElementById('detailName');
        var detailSub = document.getElementById('detailSub');
        var detailBadges = document.getElementById('detailBadges');
        var detailProfile = document.getElementById('detailProfile');
        var detailStats = document.getElementById('detailStats');
        var detailTotal = document.getElementById('detailTotal');
        var detailEyebrow = document.getElementById('detailEyebrow');
        var detailPhotoCardWrap = document.getElementById('detailPhotoCardWrap');
        var detailPhotoCardHint = document.getElementById('detailPhotoCardHint');
        var detailPhotoCardTiers = document.getElementById('detailPhotoCardTiers');
        var detailOwnedQty = document.getElementById('detailOwnedQty');
        var detailEnhanceOpenBtn = document.getElementById('detailEnhanceOpenBtn');
        var enhanceOverlay = document.getElementById('enhanceOverlay');
        var enhanceCloseBtn = document.getElementById('enhanceCloseBtn');
        var enhanceInfoText = document.getElementById('enhanceInfoText');
        var enhanceDoBtn = document.getElementById('enhanceDoBtn');
        var enhanceResultBox = document.getElementById('enhanceResultBox');
        var enhanceStateCurrent = document.getElementById('enhanceStateCurrent');
        var enhanceStateNeed = document.getElementById('enhanceStateNeed');
        var enhanceStateOwned = document.getElementById('enhanceStateOwned');
        var enhanceModalPanel = document.getElementById('enhanceModalPanel');
        var enhanceCelebrateFx = document.getElementById('enhanceCelebrateFx');
        var enhanceMaxBadge = document.getElementById('enhanceMaxBadge');
        var currentDetailCard = null;

        var PC_TIER_ORDER = ['BASE', 'R', 'SR', 'SSR'];
        var BASE_STATS = null;
        function gradeClass(gradeCode) {
            var g = String(gradeCode || '').toUpperCase();
            if (g === 'R') return 'r';
            if (g === 'SR') return 'sr';
            if (g === 'SSR') return 'ssr';
            return 'base';
        }
        function normalizeGrade(g) {
            var u = String(g || '').toUpperCase();
            return (u === 'R' || u === 'SR' || u === 'SSR') ? u : '';
        }
        function applyCardGlow(cardEl, gradeCode) {
            if (!cardEl) return;
            cardEl.classList.remove('card-glow-r', 'card-glow-sr', 'card-glow-ssr');
            var g = normalizeGrade(gradeCode);
            if (g) cardEl.classList.add('card-glow-' + g.toLowerCase());
        }
        function imageFromRel(rel, fallback) {
            if (!rel) return fallback || '';
            return (rel.charAt(0) === '/') ? (CTX + rel) : (CTX + '/' + rel);
        }
        function updateCardThumbnailImage(cardEl) {
            if (!cardEl) return;
            var imgEl = cardEl.querySelector('.card-media-fill img');
            if (!imgEl) return;
            var baseRel = cardEl.dataset.imagePath || '';
            var baseAbs = cardEl.dataset.image || '';
            var eq = normalizeGrade((cardEl.dataset.pcEq || '').trim());
            var rel = '';
            if (eq === 'R') rel = cardEl.dataset.pcImgR || '';
            else if (eq === 'SR') rel = cardEl.dataset.pcImgSr || '';
            else if (eq === 'SSR') rel = cardEl.dataset.pcImgSsr || '';
            if (!rel && eq) {
                rel = baseRel ? pcImageUrlRel(baseRel, eq) : '';
            }
            var nextSrc = rel ? imageFromRel(rel, baseAbs) : (imageFromRel(baseRel, baseAbs) || baseAbs);
            if (nextSrc) {
                imgEl.src = nextSrc;
            }
        }
        function applyPercentBonus(base, bonusPercent) {
            var b = Number(base || 0);
            var pct = Number(bonusPercent || 0);
            if (pct <= 0 || b <= 0) return b;
            var add = Math.round(b * (pct / 100));
            return Math.max(0, Math.min(100, b + add));
        }
        function enhanceBonusByLevel(level) {
            var lv = Math.max(0, Number(level || 0));
            if (lv === 1) return 1;
            if (lv === 2) return 2;
            if (lv === 3) return 3;
            if (lv === 4) return 4;
            if (lv >= 5) return 7;
            return 0;
        }
        function renderDetailStats(cardEl) {
            if (!cardEl) return;
            var bonus = Number(cardEl.dataset.pcBonus || 0);
            var enhanceBonus = enhanceBonusByLevel(cardEl.dataset.enhanceLevel || 0);
            BASE_STATS = {
                vocal: Number(cardEl.dataset.baseVocal || cardEl.dataset.vocal || 0),
                dance: Number(cardEl.dataset.baseDance || cardEl.dataset.dance || 0),
                star: Number(cardEl.dataset.baseStar || cardEl.dataset.star || 0),
                mental: Number(cardEl.dataset.baseMental || cardEl.dataset.mental || 0),
                teamwork: Number(cardEl.dataset.baseTeamwork || cardEl.dataset.teamwork || 0)
            };
            var cur = {
                vocal: applyPercentBonus(BASE_STATS.vocal, bonus) + enhanceBonus,
                dance: applyPercentBonus(BASE_STATS.dance, bonus) + enhanceBonus,
                star: applyPercentBonus(BASE_STATS.star, bonus) + enhanceBonus,
                mental: applyPercentBonus(BASE_STATS.mental, bonus) + enhanceBonus,
                teamwork: applyPercentBonus(BASE_STATS.teamwork, bonus) + enhanceBonus
            };
            detailStats.innerHTML = '';
            detailStats.appendChild(createStatBar('VOCAL', cur.vocal, enhanceBonus));
            detailStats.appendChild(createStatBar('DANCE', cur.dance, enhanceBonus));
            detailStats.appendChild(createStatBar('STAR', cur.star, enhanceBonus));
            detailStats.appendChild(createStatBar('MENTAL', cur.mental, enhanceBonus));
            detailStats.appendChild(createStatBar('TEAMWORK', cur.teamwork, enhanceBonus));
            detailTotal.textContent = cur.vocal + cur.dance + cur.star + cur.mental + cur.teamwork;
        }
        function pcImageUrlRel(basePath, grade) {
            if (!basePath || !grade) {
                return basePath || '';
            }
            var g = String(grade).toUpperCase();
            var dot = basePath.lastIndexOf('.');
            if (dot <= 0) {
                return basePath + '_pc_' + g;
            }
            return basePath.substring(0, dot) + '_pc_' + g + basePath.substring(dot);
        }
        function gradeToIndex(g) {
            var u = normalizeGrade(g);
            var i = PC_TIER_ORDER.indexOf(u || 'BASE');
            return i >= 0 ? i : 0;
        }

        window.__detailPcGoTo = null;

        function setupDetailPhotoCarousel(cardEl) {
            if (!detailPhoto) {
                return;
            }
            window.__detailPcGoTo = null;
            var baseRel = cardEl.dataset.imagePath || '';
            var fullBase = cardEl.dataset.image || '';
            var own = cardEl.dataset.owned || 'na';
            var eq = normalizeGrade((cardEl.dataset.pcEq || '').trim());
            var startIdx = gradeToIndex(eq);

            detailPhoto.className = 'detail-photo detail-photo--carousel';
            detailPhoto.innerHTML = '';

            var viewport = document.createElement('div');
            viewport.className = 'detail-photo-viewport';

            var track = document.createElement('div');
            track.className = 'detail-photo-track';
            track.id = 'detailPhotoTrack';

            PC_TIER_ORDER.forEach(function (code) {
                var owned = (code === 'R' && cardEl.dataset.pcR === 'true')
                    || (code === 'SR' && cardEl.dataset.pcSr === 'true')
                    || (code === 'SSR' && cardEl.dataset.pcSsr === 'true');
                var slide = document.createElement('div');
                slide.className = 'detail-photo-slide';
                slide.setAttribute('data-pc-grade', code);

                var img = document.createElement('img');
                img.alt = cardEl.dataset.name || '';
                var explicit = '';
                if (code === 'R') explicit = cardEl.dataset.pcImgR || '';
                else if (code === 'SR') explicit = cardEl.dataset.pcImgSr || '';
                else if (code === 'SSR') explicit = cardEl.dataset.pcImgSsr || '';
                var rel = '';
                if (code === 'BASE') {
                    rel = baseRel;
                } else if (explicit) {
                    rel = explicit;
                } else {
                    rel = baseRel ? pcImageUrlRel(baseRel, code) : '';
                }
                img.src = rel
                    ? ((rel.charAt(0) === '/') ? (CTX + rel) : (CTX + '/' + rel))
                    : (fullBase || '');
                img.onerror = function () {
                    this.onerror = null;
                    this.src = fullBase || '';
                };
                if (own === 'false') {
                    img.style.filter = 'grayscale(1)';
                    img.style.opacity = '0.88';
                }
                var badge = document.createElement('span');
                badge.className = 'detail-photo-grade detail-photo-grade--' + gradeClass(code);
                badge.textContent = code === 'BASE' ? 'BASE' : code;
                slide.appendChild(img);
                slide.appendChild(badge);
                if (code !== 'BASE' && !owned) {
                    var lock = document.createElement('div');
                    lock.className = 'detail-photo-slide-lock';
                    lock.innerHTML = '<span>' + code + ' · 잠금</span>';
                    slide.appendChild(lock);
                    img.style.filter = (own === 'false' ? 'grayscale(1) ' : '') + 'brightness(0.82)';
                }
                track.appendChild(slide);
            });

            viewport.appendChild(track);
            detailPhoto.appendChild(viewport);

            var prevBtn = document.createElement('button');
            prevBtn.type = 'button';
            prevBtn.className = 'detail-photo-nav detail-photo-nav--prev';
            prevBtn.setAttribute('aria-label', '이전 등급');
            prevBtn.innerHTML = '<i class="fas fa-chevron-left"></i>';
            var nextBtn = document.createElement('button');
            nextBtn.type = 'button';
            nextBtn.className = 'detail-photo-nav detail-photo-nav--next';
            nextBtn.setAttribute('aria-label', '다음 등급');
            nextBtn.innerHTML = '<i class="fas fa-chevron-right"></i>';
            detailPhoto.appendChild(prevBtn);
            detailPhoto.appendChild(nextBtn);

            var dots = document.createElement('div');
            dots.className = 'detail-photo-dots';
            PC_TIER_ORDER.forEach(function (code, i) {
                var d = document.createElement('button');
                d.type = 'button';
                d.className = 'detail-photo-dot' + (i === startIdx ? ' is-active' : '');
                d.setAttribute('aria-label', code);
                d.addEventListener('click', function () { go(i); });
                dots.appendChild(d);
            });
            detailPhoto.appendChild(dots);

            var cur = startIdx;
            function go(i) {
                cur = Math.max(0, Math.min(PC_TIER_ORDER.length - 1, i));
                track.style.transform = 'translateX(-' + (cur * 100) + '%)';
                var ds = dots.querySelectorAll('.detail-photo-dot');
                for (var j = 0; j < ds.length; j++) {
                    ds[j].classList.toggle('is-active', j === cur);
                }
            }
            window.__detailPcGoTo = function (idx) {
                go(typeof idx === 'number' ? idx : gradeToIndex(idx));
            };

            prevBtn.addEventListener('click', function () { go(cur - 1); });
            nextBtn.addEventListener('click', function () { go(cur + 1); });

            var tx = 0;
            var ty = 0;
            viewport.addEventListener('touchstart', function (e) {
                if (!e.touches || !e.touches[0]) {
                    return;
                }
                tx = e.touches[0].clientX;
                ty = e.touches[0].clientY;
            }, { passive: true });
            viewport.addEventListener('touchend', function (e) {
                if (!e.changedTouches || !e.changedTouches[0]) {
                    return;
                }
                var dx = e.changedTouches[0].clientX - tx;
                var dy = e.changedTouches[0].clientY - ty;
                if (Math.abs(dx) < 48 || Math.abs(dx) < Math.abs(dy)) {
                    return;
                }
                if (dx < 0) {
                    go(cur + 1);
                } else {
                    go(cur - 1);
                }
            }, { passive: true });

            go(startIdx);
        }

        function populatePhotoCardSection(cardEl) {
            if (!detailPhotoCardWrap || !detailPhotoCardHint || !detailPhotoCardTiers) return;
            var own = cardEl.dataset.owned || 'na';
            if (own !== 'true') {
                detailPhotoCardWrap.style.display = 'none';
                return;
            }
            detailPhotoCardWrap.style.display = 'block';
            var tid = cardEl.dataset.id;
            var eq = (cardEl.dataset.pcEq || '').trim();
            var bonus = Number(cardEl.dataset.pcBonus || 0);
            detailPhotoCardHint.textContent = '보유한 등급만 장착 가능합니다. 현재 장착 등급은 즉시 능력치에 반영됩니다. 현재 장착: '
                + (eq ? (eq + ' (능력치 +' + bonus + '%)') : '없음')
                + '. 상점 포토카드 탭에서 뽑기가 가능합니다.';
            var tiers = [
                { code: 'R', pct: '5%' },
                { code: 'SR', pct: '10%' },
                { code: 'SSR', pct: '15%' }
            ];
            detailPhotoCardTiers.innerHTML = '';
            tiers.forEach(function (t) {
                var owned = (t.code === 'R' && cardEl.dataset.pcR === 'true')
                    || (t.code === 'SR' && cardEl.dataset.pcSr === 'true')
                    || (t.code === 'SSR' && cardEl.dataset.pcSsr === 'true');
                var btn = document.createElement('button');
                btn.type = 'button';
                btn.className = 'pc-tier-btn' + (eq === t.code ? ' is-equipped' : '') + (!owned ? ' is-locked' : '');
                btn.textContent = t.code + ' · +' + t.pct + (owned ? '' : ' · 잠금');
                if (owned) {
                    (function (code) {
                        btn.onclick = function () {
                            fetch(CTX + '/trainees/' + tid + '/photocard/equip?grade=' + encodeURIComponent(code), { method: 'POST' })
                                .then(function (r) { return r.json(); })
                                .then(function (d) {
                                    if (!d.ok) {
                                        alert('장착에 실패했습니다.');
                                        return;
                                    }
                                    var s = d.summary;
                                    cardEl.dataset.pcEq = s.equippedGrade || '';
                                    cardEl.dataset.pcBonus = String(s.equippedBonusPercent || 0);
                                    applyCardGlow(cardEl, cardEl.dataset.pcEq);
                                    updateCardThumbnailImage(cardEl);
                                    renderDetailStats(cardEl);
                                    populatePhotoCardSection(cardEl);
                                    if (typeof window.__detailPcGoTo === 'function') {
                                        window.__detailPcGoTo(code);
                                    }
                                })
                                .catch(function () { alert('요청 오류'); });
                        };
                    })(t.code);
                }
                detailPhotoCardTiers.appendChild(btn);
            });
        }

        function createBadge(text) {
            var badge = document.createElement('span');
            badge.className = 'detail-badge';
            badge.textContent = text;
            return badge;
        }

        function createProfileItem(label, value, isLink) {
            var item = document.createElement('div');
            item.className = 'profile-item';

            var title = document.createElement('label');
            title.textContent = label;
            item.appendChild(title);

            if (isLink && value) {
                var link = document.createElement('a');
                var href = String(value).indexOf('http') === 0 ? value : ('https://instagram.com/' + String(value).replace(/^@/, ''));
                link.href = href;
                link.target = '_blank';
                link.rel = 'noreferrer noopener';
                link.textContent = String(value).charAt(0) === '@' ? value : ('@' + value);
                item.appendChild(link);
            } else {
                var body = document.createElement('span');
                body.textContent = value || '-';
                item.appendChild(body);
            }

            return item;
        }

        function createStatBar(label, value, enhanceBonus) {
            var wrap = document.createElement('div');
            wrap.className = 'stat-bar';

            var head = document.createElement('div');
            head.className = 'stat-bar-head';
            var labelEl = document.createElement('span');
            labelEl.textContent = label;
            var valueEl = document.createElement('span');
            var current = Number(value || 0);
            var bonus = Number(enhanceBonus || 0);
            var main = document.createElement('span');
            main.className = 'stat-value-main';
            main.textContent = String(current);
            valueEl.appendChild(main);
            if (bonus > 0) {
                var bonusEl = document.createElement('span');
                bonusEl.className = 'stat-value-bonus';
                bonusEl.textContent = '(+' + bonus + ')';
                valueEl.appendChild(bonusEl);
            }
            head.appendChild(labelEl);
            head.appendChild(valueEl);

            var track = document.createElement('div');
            track.className = 'stat-track';
            var fill = document.createElement('div');
            fill.className = 'stat-fill';
            fill.style.width = Math.max(0, Math.min(100, Number(value || 0))) + '%';
            track.appendChild(fill);

            wrap.appendChild(head);
            wrap.appendChild(track);
            return wrap;
        }

        function getEnhanceLevelText(level) {
            var lv = Math.max(0, Number(level || 0));
            return lv >= 5 ? 'MAX' : ('+' + lv);
        }

        function getNeedCardsForNext(level) {
            var lv = Math.max(0, Number(level || 0));
            return lv + 1;
        }

        function updateEnhanceNameMark(cardEl) {
            if (!cardEl) return;
            var level = Math.max(0, Number(cardEl.dataset.enhanceLevel || 0));
            var nameEl = cardEl.querySelector('.card-name');
            if (!nameEl) return;
            var mark = nameEl.querySelector('.enhance-mark');
            if (!mark) {
                mark = document.createElement('span');
                mark.className = 'enhance-mark';
                nameEl.appendChild(mark);
            }
            mark.className = 'enhance-mark lv-' + Math.min(5, level);
            mark.textContent = getEnhanceLevelText(level);
        }

        function updateEnhanceButtonState(cardEl) {
            if (!cardEl || !detailEnhanceOpenBtn || !detailOwnedQty) return;
            var qty = Math.max(0, Number(cardEl.dataset.ownedQty || 0));
            var level = Math.max(0, Number(cardEl.dataset.enhanceLevel || 0));
            var need = getNeedCardsForNext(level);
            var maxed = level >= 5;
            var valueEl = detailOwnedQty.querySelector('.detail-owned-card__value');
            if (valueEl) {
                valueEl.textContent = qty + '장';
            } else {
                detailOwnedQty.textContent = qty + '장';
            }
            detailEnhanceOpenBtn.disabled = maxed || qty < need;
        }

        function showEnhanceResult(ok, message) {
            if (!enhanceResultBox) return;
            enhanceResultBox.style.display = 'block';
            enhanceResultBox.className = 'enhance-result ' + (ok ? 'is-success' : 'is-fail');
            enhanceResultBox.innerHTML = (ok ? '<i class="fas fa-circle-check"></i>' : '<i class="fas fa-triangle-exclamation"></i>') + message;
            if (enhanceModalPanel) {
                enhanceModalPanel.classList.remove('is-fail-shake');
                if (!ok) {
                    void enhanceModalPanel.offsetWidth;
                    enhanceModalPanel.classList.add('is-fail-shake');
                }
            }
            if (enhanceCelebrateFx) {
                enhanceCelebrateFx.classList.remove('is-active');
                enhanceCelebrateFx.classList.remove('is-max-active');
                if (ok) {
                    void enhanceCelebrateFx.offsetWidth;
                    enhanceCelebrateFx.classList.add('is-active');
                }
            }
            if (enhanceMaxBadge) {
                enhanceMaxBadge.classList.remove('is-show');
            }
        }

        function triggerMaxEnhanceFx() {
            if (enhanceCelebrateFx) {
                enhanceCelebrateFx.classList.remove('is-active');
                enhanceCelebrateFx.classList.remove('is-max-active');
                void enhanceCelebrateFx.offsetWidth;
                enhanceCelebrateFx.classList.add('is-max-active');
            }
            if (enhanceMaxBadge) {
                enhanceMaxBadge.classList.remove('is-show');
                void enhanceMaxBadge.offsetWidth;
                enhanceMaxBadge.classList.add('is-show');
            }
        }

        function openEnhanceModal(cardEl) {
            if (!cardEl || !enhanceOverlay || !enhanceInfoText || !enhanceDoBtn) return;
            currentDetailCard = cardEl;
            var level = Math.max(0, Number(cardEl.dataset.enhanceLevel || 0));
            var qty = Math.max(0, Number(cardEl.dataset.ownedQty || 0));
            var need = getNeedCardsForNext(level);
            var maxed = level >= 5;
            if (enhanceResultBox) {
                enhanceResultBox.style.display = 'none';
                enhanceResultBox.className = 'enhance-result';
                enhanceResultBox.textContent = '';
            }
            if (enhanceStateCurrent) enhanceStateCurrent.textContent = getEnhanceLevelText(level);
            if (enhanceStateNeed) enhanceStateNeed.textContent = maxed ? 'MAX' : (need + '장');
            if (enhanceStateOwned) enhanceStateOwned.textContent = qty + '장';
            enhanceInfoText.textContent = maxed
                ? '최대 강화에 도달했습니다. 더 이상 강화할 수 없습니다.'
                : ('다음 강화에 동일 카드 ' + need + '장이 필요합니다. 재료가 충분할 때만 강화가 가능합니다.');
            enhanceDoBtn.disabled = maxed || qty < need;
            enhanceDoBtn.textContent = maxed ? '이미 최대 강화' : ('강화하기 (재료 ' + need + '장 소모)');
            enhanceOverlay.classList.add('is-open');
        }

        function closeEnhanceModal() {
            if (!enhanceOverlay) return;
            enhanceOverlay.classList.remove('is-open');
        }

        window.openTraineeModal = function (el) {
            if (!overlay || !el) return;

            var grade = el.dataset.grade || '—';
            var genderText = el.dataset.gender === 'MALE' ? '남자 연습생' : '여자 연습생';
            var image = el.dataset.image || '';
            var own = el.dataset.owned || 'na';

            detailEyebrow.textContent = 'TRAINEE PROFILE';
            detailName.textContent = el.dataset.name || '-';
            detailSub.textContent = '핵심 능력치와 프로필을 함께 볼 수 있는 상세 도감 카드입니다.';
            detailName.innerHTML = (el.dataset.name || '-') + ' <span class="enhance-mark lv-' + Math.min(5, Number(el.dataset.enhanceLevel || 0)) + '">' + getEnhanceLevelText(el.dataset.enhanceLevel || 0) + '</span>';
            applyCardGlow(el, el.dataset.pcEq || '');

            if (own === 'true') {
                setupDetailPhotoCarousel(el);
            } else {
                detailPhoto.className = 'detail-photo';
                detailPhoto.innerHTML = '';
                if (image && image !== 'null') {
                    var img0 = document.createElement('img');
                    img0.src = image;
                    img0.alt = el.dataset.name || '';
                    if (own === 'false') {
                        img0.style.filter = 'grayscale(1)';
                        img0.style.opacity = '0.88';
                    }
                    img0.onerror = function () {
                        this.remove();
                        var fallback = document.createElement('div');
                        fallback.className = 'card-placeholder';
                        fallback.innerHTML = '<i class="fas fa-user"></i>';
                        detailPhoto.appendChild(fallback);
                    };
                    detailPhoto.appendChild(img0);
                } else {
                    var placeholder0 = document.createElement('div');
                    placeholder0.className = 'card-placeholder';
                    placeholder0.innerHTML = '<i class="fas fa-user"></i>';
                    detailPhoto.appendChild(placeholder0);
                }
            }

            detailBadges.innerHTML = '';
            detailBadges.appendChild(createBadge('등급 ' + grade));
            var groupCode = el.dataset.group || 'OTHER';
            var groupLabel = groupCode === 'RIIZE' ? '라이즈'
                : groupCode === 'EXO' ? '엑소'
                : groupCode === 'HEARTS2HEARTS' ? '하츠투하츠'
                : groupCode === 'AESPA' ? '에스파'
                : groupCode === 'REDVELVET' ? '레드벨벳'
                : '기타';
            detailBadges.appendChild(createBadge(groupLabel));
            if (own === 'true') {
                detailBadges.appendChild(createBadge('보유 중'));
            } else if (own === 'false') {
                detailBadges.appendChild(createBadge('미보유'));
            } else {
                detailBadges.appendChild(createBadge(genderText));
            }
            detailBadges.appendChild(createBadge('ID #' + (el.dataset.id || '-')));
            updateEnhanceButtonState(el);
            if (detailEnhanceOpenBtn) {
                detailEnhanceOpenBtn.onclick = function () {
                    openEnhanceModal(el);
                };
            }

            detailProfile.innerHTML = '';
            detailProfile.appendChild(createProfileItem('AGE', el.dataset.age));
            detailProfile.appendChild(createProfileItem('BIRTHDAY', el.dataset.birthday));
            detailProfile.appendChild(createProfileItem('HOBBY', el.dataset.hobby));
            detailProfile.appendChild(createProfileItem('INSTAGRAM', el.dataset.instagram, true));

            renderDetailStats(el);

            populatePhotoCardSection(el);

            overlay.classList.add('is-open');
            document.body.style.overflow = 'hidden';
        };

        if (enhanceCloseBtn) {
            enhanceCloseBtn.addEventListener('click', closeEnhanceModal);
        }
        window.handleEnhanceOverlayClose = function (event) {
            if (event.target === enhanceOverlay) {
                closeEnhanceModal();
            }
        };
        if (enhanceDoBtn) {
            enhanceDoBtn.addEventListener('click', function () {
                if (!currentDetailCard) return;
                var tid = currentDetailCard.dataset.id;
                fetch(CTX + '/trainees/' + tid + '/enhance', { method: 'POST' })
                    .then(function (r) { return r.json(); })
                    .then(function (d) {
                        if (!d || d.ok !== true) {
                            var failMsg = (d && d.message) ? d.message : '강화 재료가 부족합니다.';
                            showEnhanceResult(false, failMsg);
                            return;
                        }
                        currentDetailCard.dataset.enhanceLevel = String(d.enhanceLevel || 0);
                        currentDetailCard.dataset.ownedQty = String(d.quantity || 0);
                        updateEnhanceNameMark(currentDetailCard);
                        detailName.innerHTML = (currentDetailCard.dataset.name || '-') + ' <span class="enhance-mark lv-' + Math.min(5, Number(currentDetailCard.dataset.enhanceLevel || 0)) + '">' + getEnhanceLevelText(currentDetailCard.dataset.enhanceLevel || 0) + '</span>';
                        updateEnhanceButtonState(currentDetailCard);
                        openEnhanceModal(currentDetailCard);
                        showEnhanceResult(true, d.message || '강화가 완료되었습니다.');
                        if (Number(d.enhanceLevel || 0) >= 5) {
                            triggerMaxEnhanceFx();
                        }
                    })
                    .catch(function () {
                        showEnhanceResult(false, '강화 재료가 부족합니다.');
                    });
            });
        }

        var detailModal = document.querySelector('.detail-modal');

        if (detailModal && !detailModal.querySelector('.detail-close')) {
            var fixedCloseBtn = document.createElement('button');
            fixedCloseBtn.type = 'button';
            fixedCloseBtn.className = 'detail-close';
            fixedCloseBtn.innerHTML = '<i class="fas fa-times"></i>';
            fixedCloseBtn.onclick = closeModal;
            detailModal.appendChild(fixedCloseBtn);
        }

        function closeModal() {
            if (!overlay) return;
            overlay.classList.remove('is-open');
            document.body.style.overflow = '';
        }

        window.handleOverlayClose = function (event) {
            if (event.target === overlay) {
                closeModal();
            }
        };

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                closeEnhanceModal();
                closeModal();
            }
        });

        window.handleTraineeCardClick = function (el) {
            var own = el && el.dataset ? (el.dataset.owned || 'na') : 'na';
            var hidden = el && el.dataset ? (el.dataset.hidden === 'true') : false;
            if (hidden) {
                alert('히든 연습생 정보는 비공개입니다.');
                return;
            }
            if (own === 'na') {
                alert('로그인 후 상세 정보를 이용할 수 있습니다.');
                return;
            }
            if (own === 'false') {
                alert('아직 잠금된 연습생입니다. 플레이를 진행해 팀의 완성도를 높여 보세요. 특정 조건을 만족하면 새로운 그룹과 숨겨진 대상이 열립니다.');
                return;
            }
            window.openTraineeModal(el);
        };
    })();
</script>
</body>
</html>
