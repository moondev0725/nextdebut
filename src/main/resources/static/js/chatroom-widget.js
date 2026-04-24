(function () {
  const crOpenKey = 'cr_open';
  'use strict';

  const nickname = document.querySelector('.mypage-trigger__name')?.textContent?.trim() || '익명';
  const ctxBase = (typeof window !== 'undefined' && window.__UNITX_CTX !== undefined) ? window.__UNITX_CTX : '';
  function unitxLoginUrl() {
    return ctxBase + '/login?redirect=' + encodeURIComponent(location.pathname + location.search);
  }

  // ── 위젯 HTML ──
  // 전체 구조: 헤더 + 바디(왼쪽 패널 | 오른쪽 채팅)
  const widget = document.createElement('div');
  widget.id = 'chatroom-widget';
  widget.innerHTML = `
    <div id="cr-box" style="display:none;">

      <!-- 헤더 -->
      <div id="cr-header">
        <span id="cr-title">💬 채팅방</span>
        <div id="cr-header-actions">
          <button type="button" id="cr-open-create" title="방 만들기">방 만들기</button>
          <button type="button" id="cr-close" title="닫기">✕</button>
        </div>
      </div>

      <!-- 바디: 2열 -->
      <div id="cr-body">

        <!-- ① 왼쪽: 방 목록 패널 -->
        <div id="cr-panel">
          <div id="cr-create-row">
            <input type="text" id="cr-room-search" placeholder="방 검색" maxlength="20" autocomplete="off"/>
            <button type="button" id="cr-search-btn" title="검색">🔍</button>
          </div>
          <div id="cr-tab-row">
            <button class="cr-tab" data-tab="all">전체</button>
            <button class="cr-tab active" data-tab="joined">참여중</button>
          </div>
          <div id="cr-room-list"></div>
        </div>

        <!-- ② 오른쪽: 채팅 영역 -->
        <div id="cr-chat-area">
          <!-- 방 미선택 안내 -->
          <div id="cr-no-room">
            <span>← 방을 선택하세요</span>
          </div>
          <!-- 채팅 화면 (방 선택 후) -->
          <div id="cr-chat" style="display:none;">
            <div id="cr-chat-header">
              <button type="button" id="cr-back-btn">← 나가기</button>
              <div style="flex:1; min-width:0; overflow:hidden;">
                <div style="display:flex; align-items:center; gap:6px; flex-wrap:wrap;">
                  <span id="cr-room-title"></span>
                  <span id="cr-host-self-badge" class="cr-host-badge" style="display:none;">방장</span>
                </div>
              </div>
              <span id="cr-user-count"></span>
            </div>
            <div id="cr-member-row" style="display:none;">
              <div id="cr-member-list" class="cr-member-list"></div>
            </div>
            <div id="cr-messages"></div>
            <div id="cr-input-row">
              <input type="text" id="cr-input" placeholder="메시지 입력..." autocomplete="off"/>
              <button id="cr-send-btn">↑</button>
            </div>
          </div>
        </div>

      </div><!-- /cr-body -->
    </div>

    <!-- 방 만들기 모달 -->
    <div id="cr-create-overlay" aria-hidden="true">
      <div class="cr-modal-backdrop" id="cr-create-backdrop"></div>
      <div class="cr-modal-panel" role="dialog" aria-labelledby="cr-create-heading">
        <div class="cr-modal-heading" id="cr-create-heading">방 만들기</div>
        <label class="cr-modal-label">방 이름</label>
        <input type="text" id="cr-modal-name" class="cr-modal-input" maxlength="20" placeholder="방 이름" autocomplete="off"/>
        <label class="cr-modal-check">
          <input type="checkbox" id="cr-modal-secret"/> 비밀방
        </label>
        <div id="cr-modal-pw-wrap" style="display:none;">
          <label class="cr-modal-label">비밀번호</label>
          <input type="password" id="cr-modal-password" class="cr-modal-input" maxlength="40" placeholder="비밀번호" autocomplete="new-password"/>
        </div>
        <div class="cr-modal-actions">
          <button type="button" id="cr-modal-cancel">취소</button>
          <button type="button" id="cr-modal-submit">만들기</button>
        </div>
      </div>
    </div>

    <!-- 비밀방 입장 비밀번호 -->
    <div id="cr-pwd-overlay" aria-hidden="true">
      <div class="cr-modal-backdrop" id="cr-pwd-backdrop"></div>
      <div class="cr-modal-panel" role="dialog">
        <div class="cr-modal-heading">비밀번호 입력</div>
        <div class="cr-modal-sub" id="cr-pwd-room-label"></div>
        <input type="password" id="cr-pwd-input" class="cr-modal-input" maxlength="40" placeholder="비밀번호" autocomplete="off"/>
        <div class="cr-modal-actions">
          <button type="button" id="cr-pwd-cancel">취소</button>
          <button type="button" id="cr-pwd-submit">입장</button>
        </div>
      </div>
    </div>
  `;
  document.body.appendChild(widget);

  // ── 스타일 ──
  const style = document.createElement('style');
  style.textContent = `
    /* ── 외곽 박스 ── */
    #cr-box {
      position:fixed; z-index:9998;
      width:580px;
      background:rgba(15,8,30,0.60);
      backdrop-filter:blur(20px) saturate(1.6);
      -webkit-backdrop-filter:blur(20px) saturate(1.6);
      border:1px solid rgba(125,211,252,0.25);
      border-radius:20px;
      box-shadow:
        0 8px 32px rgba(0,0,0,0.55),
        0 0 0 1px rgba(255,255,255,0.05) inset,
        0 0 40px rgba(125,211,252,0.08);
      display:flex; flex-direction:column; overflow:hidden;
    }

    /* ── 헤더 ── */
    #cr-header {
      background:linear-gradient(135deg,rgba(125,211,252,0.25),rgba(167,139,250,0.18));
      border-bottom:1px solid rgba(125,211,252,0.20);
      padding:11px 16px; display:flex; justify-content:space-between; align-items:center;
      font-family:'Orbitron',sans-serif; font-size:12px; font-weight:700;
      letter-spacing:.12em; color:#fff; flex-shrink:0;
    }
    #cr-header-actions { display:flex; align-items:center; gap:10px; }
    #cr-header button {
      background:none; border:none; color:rgba(200,240,255,0.8);
      cursor:pointer; font-size:14px; transition:color .2s;
    }
    #cr-header button:hover { color:#fff; }
    #cr-open-create {
      font-family:'Orbitron',sans-serif; font-size:9px; letter-spacing:.08em;
      padding:5px 10px; border-radius:999px;
      border:1px solid rgba(125,211,252,0.45) !important;
      background:rgba(125,211,252,0.12) !important;
    }
    #cr-open-create:hover {
      background:rgba(125,211,252,0.22) !important; color:#fff !important;
    }

    /* ── 바디 2열 ── */
    #cr-body {
      display:flex; flex:1; overflow:hidden;
      min-height:0; /* cr-box height에 맞춰 자동 확장 */
    }

    /* ── 왼쪽 패널 ── */
    #cr-panel {
      width:200px; flex-shrink:0;
      display:flex; flex-direction:column;
      border-right:1px solid rgba(125,211,252,0.15);
      background:rgba(0,0,0,0.12);
    }
    #cr-create-row {
      display:flex; gap:6px; padding:10px 10px 8px; flex-shrink:0;
      border-bottom:1px solid rgba(125,211,252,0.10);
    }
    #cr-room-search {
      flex:1; min-width:0;
      border:1px solid rgba(125,211,252,0.28); border-radius:999px;
      padding:6px 10px; background:rgba(255,255,255,0.06);
      font-family:'Orbitron',sans-serif; font-size:9px; color:#fff;
      outline:none; letter-spacing:.04em;
    }
    #cr-room-search::placeholder { color:rgba(200,240,255,0.32); }
    #cr-search-btn {
      width:28px; height:28px; flex-shrink:0;
      background:linear-gradient(135deg,rgba(125,211,252,0.45),rgba(167,139,250,0.40));
      border:none; border-radius:50%;
      font-size:14px; color:#fff;
      cursor:pointer; transition:background .2s;
      display:flex; align-items:center; justify-content:center;
      line-height:1;
    }
    #cr-search-btn:hover {
      background:linear-gradient(135deg,rgba(125,211,252,0.65),rgba(167,139,250,0.60));
    }

    /* ── 방 만들기 / 비밀번호 모달 ── */
    #cr-create-overlay, #cr-pwd-overlay {
      display:none; position:fixed; inset:0; z-index:10000;
      align-items:center; justify-content:center;
    }
    #cr-create-overlay.cr-open, #cr-pwd-overlay.cr-open {
      display:flex !important;
    }
    .cr-modal-backdrop {
      position:absolute; inset:0; background:rgba(5,3,15,0.55);
      backdrop-filter:blur(6px); -webkit-backdrop-filter:blur(6px);
    }
    .cr-modal-panel {
      position:relative; z-index:1;
      width:min(300px, calc(100vw - 32px));
      padding:18px 18px 16px;
      border-radius:16px;
      border:1px solid rgba(125,211,252,0.35);
      background:rgba(18,10,35,0.92);
      box-shadow:0 16px 48px rgba(0,0,0,0.5);
    }
    .cr-modal-heading {
      font-family:'Orbitron',sans-serif; font-size:11px; font-weight:700;
      letter-spacing:.1em; color:#fff; margin-bottom:12px;
    }
    .cr-modal-sub {
      font-family:'Orbitron',sans-serif; font-size:9px; color:rgba(200,240,255,0.55);
      margin:-6px 0 10px; letter-spacing:.04em;
    }
    .cr-modal-label {
      display:block; font-family:'Orbitron',sans-serif; font-size:8px;
      color:rgba(200,240,255,0.55); letter-spacing:.06em; margin-bottom:4px;
    }
    .cr-modal-input {
      width:100%; box-sizing:border-box;
      border:1px solid rgba(125,211,252,0.28); border-radius:10px;
      padding:8px 11px; margin-bottom:10px;
      background:rgba(255,255,255,0.06);
      font-family:'Orbitron',sans-serif; font-size:10px; color:#fff;
      outline:none;
    }
    .cr-modal-check {
      display:flex; align-items:center; gap:8px;
      font-family:'Orbitron',sans-serif; font-size:9px; color:rgba(200,240,255,0.85);
      margin-bottom:10px; cursor:pointer;
    }
    .cr-modal-check input { accent-color:rgba(125,211,252,0.9); }
    .cr-modal-actions {
      display:flex; justify-content:flex-end; gap:8px; margin-top:6px;
    }
    .cr-modal-actions button {
      font-family:'Orbitron',sans-serif; font-size:9px; letter-spacing:.06em;
      padding:7px 14px; border-radius:999px; cursor:pointer; border:none;
      transition:background .2s, color .2s;
    }
    #cr-modal-cancel, #cr-pwd-cancel {
      background:rgba(255,255,255,0.06); color:rgba(200,240,255,0.75);
      border:1px solid rgba(125,211,252,0.2) !important;
    }
    #cr-modal-submit, #cr-pwd-submit {
      background:linear-gradient(135deg,rgba(125,211,252,0.55),rgba(167,139,250,0.5));
      color:#fff;
    }
    #cr-modal-submit:hover, #cr-pwd-submit:hover {
      filter:brightness(1.08);
    }
    .cr-r-lock {
      font-size:9px; margin-right:4px; opacity:.85;
    }

    /* 탭 */
    #cr-tab-row {
      display:flex; flex-shrink:0;
      border-bottom:1px solid rgba(125,211,252,0.10);
    }
    .cr-tab {
      flex:1; background:none; border:none;
      border-bottom:2px solid transparent;
      padding:8px 0;
      font-family:'Orbitron',sans-serif; font-size:9px;
      color:rgba(200,240,255,0.40); letter-spacing:.08em; cursor:pointer;
      transition:all .2s;
    }
    .cr-tab:hover  { color:rgba(200,240,255,0.70); }
    .cr-tab.active {
      color:rgba(125,211,252,0.95);
      border-bottom-color:rgba(125,211,252,0.65);
    }

    /* 방 목록 */
    #cr-room-list {
      height:340px; overflow-y:auto; padding:8px 6px;
      display:flex; flex-direction:column; gap:4px;
      scrollbar-width:thin; scrollbar-color:rgba(125,211,252,0.18) transparent;
    }
    .cr-room-item {
      display:flex; align-items:center; justify-content:space-between;
      padding:8px 10px; border-radius:10px;
      border:1px solid transparent;
      transition:all .18s;
    }
    .cr-room-item:hover {
      background:rgba(125,211,252,0.08);
      border-color:rgba(125,211,252,0.28);
    }
    .cr-room-item.active-room {
      background:rgba(125,211,252,0.14);
      border-color:rgba(125,211,252,0.45);
    }
    .cr-r-join-btn {
      flex-shrink:0; margin-left:6px;
      background:linear-gradient(135deg,rgba(125,211,252,0.30),rgba(167,139,250,0.25));
      border:1px solid rgba(125,211,252,0.40); border-radius:999px;
      padding:3px 9px; font-size:8px; font-family:'Orbitron',sans-serif;
      color:rgba(200,240,255,0.9); cursor:pointer; transition:all .2s;
    }
    .cr-r-join-btn:hover {
      background:linear-gradient(135deg,rgba(125,211,252,0.50),rgba(167,139,250,0.45));
    }
    .cr-r-joined-badge {
      flex-shrink:0; margin-left:6px;
      background:linear-gradient(135deg,rgba(232,121,163,0.35),rgba(200,100,150,0.28));
      border:1px solid rgba(232,121,163,0.55); border-radius:999px;
      padding:3px 9px; font-size:8px; font-family:'Orbitron',sans-serif;
      color:rgba(255,180,210,0.95); pointer-events:none;
    }

    .cr-r-name {
      font-family:'Orbitron',sans-serif; font-size:10px;
      color:#fff; letter-spacing:.04em;
      overflow:hidden; text-overflow:ellipsis; white-space:nowrap;
    }
    .cr-r-info {
      font-size:9px; color:rgba(200,240,255,0.45);
      font-family:'Orbitron',sans-serif; margin-top:2px;
    }
    .cr-r-badge {
      font-size:8px; font-family:'Orbitron',sans-serif;
      color:rgba(125,211,252,0.85);
      background:rgba(125,211,252,0.13); border:1px solid rgba(125,211,252,0.28);
      border-radius:999px; padding:1px 6px; margin-bottom:2px; display:inline-block;
    }
    .cr-empty {
      text-align:center; color:rgba(200,240,255,0.28);
      font-family:'Orbitron',sans-serif; font-size:9px;
      padding:30px 8px; letter-spacing:.06em; line-height:2.2;
    }

    /* ── 오른쪽 채팅 영역 ── */
    #cr-chat-area {
      flex:1; display:flex; flex-direction:column; overflow:hidden;
    }
    #cr-no-room {
      flex:1; display:flex; align-items:center; justify-content:center;
      font-family:'Orbitron',sans-serif; font-size:10px; letter-spacing:.07em;
      color:rgba(200,240,255,0.28); text-align:center; padding:20px;
    }
    #cr-chat {
      flex:1; display:flex; flex-direction:column; overflow:hidden;
    }
    #cr-chat-header {
      display:flex; align-items:center; justify-content:space-between;
      padding:9px 14px; flex-shrink:0;
      border-bottom:1px solid rgba(125,211,252,0.13);
      background:rgba(125,211,252,0.04);
    }
    #cr-back-btn {
      background:none; border:none; color:rgba(200,240,255,0.65);
      font-family:'Orbitron',sans-serif; font-size:9px; cursor:pointer;
      transition:color .2s; white-space:nowrap; flex-shrink:0; padding:0 8px 0 0;
    }
    #cr-back-btn:hover { color:#fff; }
    #cr-room-title {
      font-family:'Orbitron',sans-serif; font-size:11px;
      color:#fff; font-weight:700; letter-spacing:.07em;
      overflow:hidden; text-overflow:ellipsis; white-space:nowrap;
      flex:1;
    }
    #cr-user-count {
      font-family:'Orbitron',sans-serif; font-size:10px;
      color:rgba(125,211,252,0.75); flex-shrink:0; margin-left:8px;
    }
    .cr-host-badge {
      font-size:8px; font-family:'Orbitron',sans-serif;
      padding:2px 7px; border-radius:999px;
      border:1px solid rgba(232,121,163,0.55);
      background:rgba(232,121,163,0.18); color:rgba(255,200,220,0.95);
      letter-spacing:.06em;
    }
    #cr-member-row {
      padding:6px 10px 8px; flex-shrink:0;
      border-bottom:1px solid rgba(125,211,252,0.10);
      background:rgba(0,0,0,0.08);
    }
    .cr-member-list {
      display:flex; flex-wrap:wrap; gap:5px; align-items:center;
      max-height:72px; overflow-y:auto;
    }
    .cr-member-chip {
      display:inline-flex; align-items:center; gap:5px;
      font-family:'Orbitron',sans-serif; font-size:8px;
      padding:3px 8px; border-radius:999px;
      border:1px solid rgba(125,211,252,0.28);
      background:rgba(125,211,252,0.08); color:rgba(200,240,255,0.88);
    }
    .cr-member-chip .cr-kick {
      border:none; background:rgba(244,67,54,0.25); color:#ffcdd2;
      border-radius:999px; padding:1px 6px; font-size:7px; cursor:pointer;
      font-family:'Orbitron',sans-serif;
    }
    .cr-member-chip .cr-kick:hover { background:rgba(244,67,54,0.45); }
    .cr-r-host-badge {
      font-size:7px; padding:1px 5px; border-radius:999px;
      border:1px solid rgba(232,121,163,0.45);
      background:rgba(232,121,163,0.12); color:rgba(255,190,210,0.9);
      margin-right:4px;
    }
    #cr-messages {
      height:340px; overflow-y:auto; padding:12px;
      display:flex; flex-direction:column; gap:8px;
      scrollbar-width:thin; scrollbar-color:rgba(125,211,252,0.18) transparent;
    }
    .cr-msg {
      max-width:85%; padding:7px 11px; border-radius:14px;
      font-family:'Orbitron',sans-serif; font-size:11px; line-height:1.6; word-break:break-word;
    }
    .cr-msg.me {
      align-self:flex-end;
      background:linear-gradient(135deg,rgba(125,211,252,0.55),rgba(167,139,250,0.45));
      color:#fff; border-bottom-right-radius:3px; border:1px solid rgba(255,255,255,0.14);
    }
    .cr-msg.other {
      align-self:flex-start;
      background:rgba(255,255,255,0.06); color:rgba(200,240,255,0.90);
      border-bottom-left-radius:3px; border:1px solid rgba(125,211,252,0.14);
      backdrop-filter:blur(6px);
    }
    .cr-msg.system {
      align-self:center; background:rgba(125,211,252,0.07);
      color:rgba(200,240,255,0.50); font-size:9px; border-radius:999px;
      padding:3px 12px; border:1px solid rgba(125,211,252,0.13);
    }
    .cr-msg-nick { font-size:9px; color:rgba(200,240,255,0.50); margin-bottom:2px; letter-spacing:.07em; }
    .cr-msg-time { font-size:9px; color:rgba(200,240,255,0.32); margin-top:2px; text-align:right; }
    #cr-input-row {
      display:flex; align-items:center; gap:6px;
      padding:8px 10px; flex-shrink:0;
      border-top:1px solid rgba(125,211,252,0.13);
      background:rgba(125,211,252,0.03);
    }
    #cr-input {
      flex:1; border:1px solid rgba(125,211,252,0.22); border-radius:999px;
      padding:8px 13px; background:rgba(255,255,255,0.05);
      font-family:'Orbitron',sans-serif; font-size:10px; color:#fff;
      outline:none; caret-color:rgba(125,211,252,0.9);
    }
    #cr-input::placeholder { color:rgba(200,240,255,0.28); font-size:10px; }
    #cr-input:focus { border-color:rgba(125,211,252,0.45); }
    #cr-send-btn {
      width:32px; height:32px; flex-shrink:0;
      background:linear-gradient(135deg,rgba(125,211,252,0.50),rgba(167,139,250,0.45));
      color:#fff; border:none; border-radius:50%; cursor:pointer;
      font-size:14px; font-family:'Orbitron',sans-serif; font-weight:700;
      transition:background .2s;
      display:flex; align-items:center; justify-content:center;
    }
    #cr-send-btn:hover {
      background:linear-gradient(135deg,rgba(125,211,252,0.70),rgba(167,139,250,0.65));
    }
  `;
  document.head.appendChild(style);

  // ── 상태 ──
  const protocol    = location.protocol === 'https:' ? 'wss' : 'ws';
  /** 서블릿 컨텍스트 경로(/unitx 등) 배포 시 WebSocket도 동일 prefix 필요 */
  function wsChatroomUrl() {
    return `${protocol}://${location.host}${ctxBase}/ws/chatroom`;
  }
  let ws            = null;
  let currentRoomId = null;
  let allRooms      = [];
  let joinedRoomIds = new Set();
  let activeTab     = 'joined';
  let roomSearchQuery = '';
  /** JOIN_ROOM 전송 직후 JOIN_OK에서 저장(비밀방 재접속용) */
  let pendingJoinPassword = null;
  /** 페이지 복원 시 REJOIN 응답 대기 중(실패 시에만 세션 초기화) */
  let restoreRejoinPending = false;
  /** JOIN_OK 전까지 입력 차단(서버 세션과 UI 불일치 방지) */
  let joinPending = false;
  let currentCreatorNickname = '';
  let roomParticipants = [];
  const CR_SECRETS_KEY = 'cr_room_secrets';
  // 방별 메시지 캐시: roomId → innerHTML 문자열 (나가기 안 눌러도 대화내용 유지)
  let roomMessages  = {};

  function loadRoomSecrets() {
    try {
      const s = sessionStorage.getItem(CR_SECRETS_KEY);
      return s ? JSON.parse(s) : {};
    } catch (_) { return {}; }
  }
  function saveRoomSecret(roomId, password) {
    const o = loadRoomSecrets();
    o[roomId] = password;
    sessionStorage.setItem(CR_SECRETS_KEY, JSON.stringify(o));
  }
  function removeRoomSecret(roomId) {
    const o = loadRoomSecrets();
    delete o[roomId];
    sessionStorage.setItem(CR_SECRETS_KEY, JSON.stringify(o));
  }

  function setJoinPending(v) {
    joinPending = v;
    const input = document.getElementById('cr-input');
    if (input) input.disabled = v;
  }

  function openCreateModal() {
    const el = document.getElementById('cr-create-overlay');
    document.getElementById('cr-modal-name').value = '';
    document.getElementById('cr-modal-secret').checked = false;
    document.getElementById('cr-modal-password').value = '';
    document.getElementById('cr-modal-pw-wrap').style.display = 'none';
    el.classList.add('cr-open');
    el.setAttribute('aria-hidden', 'false');
    setTimeout(() => document.getElementById('cr-modal-name').focus(), 50);
  }
  function closeCreateModal() {
    const el = document.getElementById('cr-create-overlay');
    el.classList.remove('cr-open');
    el.setAttribute('aria-hidden', 'true');
  }
  function openPwdModal(roomId, roomName) {
    pendingPwdRoomId = roomId;
    pendingPwdRoomName = roomName;
    const el = document.getElementById('cr-pwd-overlay');
    document.getElementById('cr-pwd-room-label').textContent = roomName;
    document.getElementById('cr-pwd-input').value = '';
    el.classList.add('cr-open');
    el.setAttribute('aria-hidden', 'false');
    setTimeout(() => document.getElementById('cr-pwd-input').focus(), 50);
  }
  function closePwdModal() {
    const el = document.getElementById('cr-pwd-overlay');
    el.classList.remove('cr-open');
    el.setAttribute('aria-hidden', 'true');
    pendingPwdRoomId = null;
    pendingPwdRoomName = null;
  }
  let pendingPwdRoomId = null;
  let pendingPwdRoomName = null;

  // ── 토글 버튼 반환 ──
  function getChatroomBtn() {
    const sideNavBtn = document.querySelector('.hero-side-nav button[onclick*="toggleChatroomWidget"]');
    if (sideNavBtn) return sideNavBtn;

    return document.getElementById('chatroom-toggle-btn');
  }

  /**
   * ── 버튼 기준 모달 위치 계산 ──
   * position:fixed + getBoundingClientRect() → scrollY 보정 없이 스크롤 무관하게 정확
   * 복원 시에는 반드시 rAF 2중첩 안에서 호출
   */
  function calcPositionFromBtn() {
    const boxWidth  = 580;
    const boxHeight = 420;
    const gap       = 8;
    const margin    = 8;
    const vw        = document.documentElement.clientWidth;
    const vh        = document.documentElement.clientHeight;

    // hero-side-nav: 버튼이 오른쪽 세로 배치 → 모달을 버튼 왼쪽에 붙임
    const btn = getChatroomBtn();
    if (!btn) return null;
    const sideNav = btn.closest('.hero-side-nav');
    if (sideNav) {
      const navRect = sideNav.getBoundingClientRect();
      const right = Math.max(margin, Math.round(navRect ? (vw - navRect.left + gap) : 68));
      return { mode: 'side-nav', right };
    }
    const rect = btn.getBoundingClientRect();

    let top  = rect.bottom + gap;
    let left = rect.right  - boxWidth;

    const maxLeft = vw - boxWidth  - margin;
    const maxTop  = vh - boxHeight - margin;

    if (left < margin)  left = margin;
    if (left > maxLeft) left = maxLeft;
    if (top  > maxTop)  top  = rect.top - boxHeight - gap;
    if (top  < margin)  top  = margin;
    if (top  > maxTop)  top  = maxTop;

    return { mode: 'free', top, left };
  }

  function clampCrPosition(top, left) {
    const boxWidth = 580;
    const boxHeight = 420;
    const margin = 8;
    const vw = document.documentElement.clientWidth;
    const vh = document.documentElement.clientHeight;
    const maxLeft = Math.max(margin, vw - boxWidth - margin);
    const maxTop = Math.max(margin, vh - boxHeight - margin);
    let nextTop = Number(top);
    let nextLeft = Number(left);
    if (!Number.isFinite(nextTop)) nextTop = margin;
    if (!Number.isFinite(nextLeft)) nextLeft = margin;
    if (nextLeft < margin) nextLeft = margin;
    if (nextLeft > maxLeft) nextLeft = maxLeft;
    if (nextTop < margin) nextTop = margin;
    if (nextTop > maxTop) nextTop = maxTop;
    return { top: nextTop, left: nextLeft };
  }

  // ── 채팅방 버튼 동적 생성 ──
  function initChatroomBtn() {
    if (document.querySelector('.hero-side-nav')) return true;
    if (document.getElementById('chatroom-toggle-btn')) return true;

    const chatBtn = document.getElementById('chat-toggle-btn')
                  || document.getElementById('chat-toggle-btn-global');
    if (!chatBtn) return false;

    // 비로그인 여부: nickname이 없거나 '익명'이면 로그인 페이지로 이동
    const isGuest = !nickname || nickname === '익명';

    const btn      = document.createElement('button');
    const chatTray = document.querySelector('.game-floating-chat-tray');
    const dayBar   = document.querySelector('.day-bar');
    btn.id = 'chatroom-toggle-btn';
    btn.innerHTML = '<i class="fas fa-message"></i>';
    btn.title = isGuest ? '채팅방 (로그인 필요)' : '채팅방';
    btn.onclick = () => {
      if (isGuest) {
        alert('로그인해야 이용이 가능합니다.');
        location.href = unitxLoginUrl();
        return;
      }
      toggleChatroomWidget();
    };
    btn.style.cssText = `
      width:38px; height:38px; border-radius:12px;
      border:1px solid rgba(125,211,252,0.55);
      background:rgba(248,250,252,0.9);
      color:#1f2937; font-size:14px;
      display:inline-flex; align-items:center; justify-content:center;
      box-shadow:0 10px 24px rgba(148,163,184,0.4);
      cursor:pointer; transition:all .18s ease; margin-left:8px;
    `;
    btn.onmouseenter = () => {
      btn.style.background  = '#fff';
      btn.style.borderColor = 'rgba(232,121,163,0.65)';
      btn.style.boxShadow   = '0 14px 24px rgba(99,102,241,0.18)';
      btn.style.transform   = (dayBar && dayBar.contains(btn))
        ? 'translateY(-50%) scale(1.08)' : 'scale(1.08)';
    };
    btn.onmouseleave = () => {
      btn.style.background  = 'rgba(248,250,252,0.9)';
      btn.style.borderColor = 'rgba(125,211,252,0.55)';
      btn.style.boxShadow   = '0 8px 18px rgba(148,163,184,0.35)';
      btn.style.transform   = (dayBar && dayBar.contains(btn))
        ? 'translateY(-50%)' : 'scale(1)';
    };

    if (chatTray && chatTray.contains(chatBtn)) {
      btn.style.marginLeft = '8px';
      chatTray.appendChild(btn);
    } else if (dayBar && dayBar.contains(chatBtn)) {
      btn.style.position   = 'absolute';
      btn.style.right      = '22px';
      btn.style.top        = '50%';
      btn.style.transform  = 'translateY(-50%)';
      btn.style.zIndex     = '9998';
      btn.style.marginLeft = '0';
      dayBar.appendChild(btn);
      chatBtn.style.right     = (22 + 38 + 8) + 'px';
      chatBtn.style.top       = '50%';
      chatBtn.style.transform = 'translateY(-50%)';
    } else {
      chatBtn.insertAdjacentElement('afterend', btn);
    }
    return true;
  }

  function retryInitChatroomBtn(maxRetries = 12, delayMs = 80) {
    let tries = 0;
    const tick = () => {
      if (initChatroomBtn()) return;
      tries += 1;
      if (tries < maxRetries) setTimeout(tick, delayMs);
    };
    tick();
  }

  // ── WebSocket 연결 ──
  function connect() {
    ws = new WebSocket(wsChatroomUrl());
    ws.onopen = () => {
      ws.send(JSON.stringify({ type: 'INIT', nickname }));
      restoreCrState();
    };
    ws.onmessage = (e) => {
      const msg = JSON.parse(e.data);
      switch (msg.type) {
        case 'ROOM_LIST':
          allRooms = msg.rooms || [];
          renderRoomList();
          break;
        case 'JOIN_OK':
          restoreRejoinPending = false;
          setJoinPending(false);
          if (pendingJoinPassword) {
            saveRoomSecret(msg.roomId, pendingJoinPassword);
            pendingJoinPassword = null;
          }
          currentCreatorNickname = msg.creatorNickname || '';
          roomParticipants = Array.isArray(msg.participants) ? msg.participants : [];
          completeJoinRoomAfterJoinOk(msg.roomId, msg.roomName, msg.history);
          renderMemberBar();
          break;
        case 'KICKED':
          setJoinPending(false);
          if (msg.roomId) {
            joinedRoomIds.delete(msg.roomId);
            removeRoomSecret(msg.roomId);
            delete roomMessages[msg.roomId];
            saveJoinedRooms();
            saveRoomMessages();
          }
          if (currentRoomId === msg.roomId) {
            currentRoomId = null;
            currentCreatorNickname = '';
            roomParticipants = [];
            sessionStorage.removeItem('cr_room_id');
            sessionStorage.removeItem('cr_room_title');
            sessionStorage.removeItem('cr_messages');
            alert(msg.reason === 'ADMIN' ? '관리자에 의해 방에서 추방되었습니다.' : '방장에 의해 추방되었습니다.');
            showNoRoom();
          }
          break;
        case 'JOIN_DENIED':
          pendingJoinPassword = null;
          setJoinPending(false);
          alert(msg.reason === 'PASSWORD' ? '비밀번호가 올바르지 않습니다.' : '입장할 수 없습니다.');
          if (restoreRejoinPending) {
            restoreRejoinPending = false;
            sessionStorage.removeItem('cr_room_id');
            sessionStorage.removeItem('cr_room_title');
            sessionStorage.removeItem('cr_messages');
            currentRoomId = null;
            showNoRoom();
          }
          break;
        case 'CHAT':
          appendChatMsg(msg);
          break;
        case 'SYSTEM':
          if (msg.participants) {
            roomParticipants = msg.participants;
            renderMemberBar();
          }
          if (msg.content) appendSystemMsg(msg);
          else if (msg.userCount !== undefined)
            document.getElementById('cr-user-count').textContent = msg.userCount + '명';
          break;
        // ROOM_GONE: 0명이어도 방 유지 → 서버에서 ROOM_GONE 안 보내도록 수정 필요
        // 서버가 보내더라도 프론트에서는 방 목록에서만 제거하고 로비 전환은 안 함
        case 'ROOM_GONE':
          restoreRejoinPending = false;
          if (msg.roomId) {
            removeRoomSecret(msg.roomId);
            allRooms = allRooms.filter(r => r.roomId !== msg.roomId);
            joinedRoomIds.delete(msg.roomId);
            saveJoinedRooms();
            renderRoomList();
          }
          // 현재 입장 중인 방이 사라진 경우에만 채팅 화면 닫기
          if (msg.roomId && currentRoomId === msg.roomId) {
            setJoinPending(false);
            currentRoomId = null;
            sessionStorage.removeItem('cr_room_id');
            sessionStorage.removeItem('cr_room_title');
            sessionStorage.removeItem('cr_messages');
            showNoRoom();
          }
          break;
      }
    };
    ws.onclose = () => { setTimeout(connect, 3000); };
  }
  function matchesSearch(r) {
    const q = roomSearchQuery.trim().toLowerCase();
    if (!q) return true;
    return String(r.roomName || '').toLowerCase().includes(q);
  }

  // ── 방 목록 렌더링 ──
  function renderRoomList() {
    const list  = document.getElementById('cr-room-list');
    let rooms = activeTab === 'joined'
      ? allRooms.filter(r => joinedRoomIds.has(r.roomId))
      : allRooms.slice();
    rooms = rooms.filter(matchesSearch);

    if (!rooms.length) {
      let msg;
      if (roomSearchQuery.trim()) {
        msg = '검색 결과 없음';
      } else if (activeTab === 'joined') {
        msg = '참여중인<br>채팅방 없음<br><span style="opacity:.5;font-size:8px">전체 탭에서 입장</span>';
      } else {
        msg = '개설된<br>채팅방 없음';
      }
      list.innerHTML = `<div class="cr-empty">${msg}</div>`;
      return;
    }

    list.innerHTML = rooms.map(r => {
      const isJoined = joinedRoomIds.has(r.roomId);
      const isSecret = !!r.secret;

      const clickable = activeTab === 'joined' || (activeTab === 'all' && isJoined);
      const rightEl = (activeTab === 'all' && !isJoined)
        ? `<button type="button" class="cr-r-join-btn" data-cr-room-id="${escapeAttr(r.roomId)}" data-cr-room-name="${escapeAttr(r.roomName)}" data-cr-secret="${isSecret ? '1' : '0'}">입장</button>`
        : (activeTab === 'all' && isJoined)
          ? '<span class="cr-r-joined-badge">참여중</span>'
          : '';

      const lockEl = isSecret ? '<span class="cr-r-lock" title="비밀방">🔒</span>' : '';
      const hostBadge = `<span class="cr-r-host-badge">방장</span>`;

      const rowClick = clickable
        ? `data-cr-row-click="1" style="cursor:pointer;" role="button" tabindex="0"`
        : '';

      return `
        <div class="cr-room-item${currentRoomId === r.roomId ? ' active-room' : ''}"
             data-room-id="${escapeAttr(r.roomId)}"
             data-room-name="${escapeAttr(r.roomName)}"
             data-cr-secret="${isSecret ? '1' : '0'}"
             ${rowClick}>
          <div style="overflow:hidden; flex:1; min-width:0;">
            <div class="cr-r-name">${lockEl}${escapeHtml(r.roomName)}</div>
            <div class="cr-r-info">${hostBadge}${escapeHtml(r.creatorNickname)} · ${r.userCount}명</div>
          </div>
          ${rightEl}
        </div>`;
    }).join('');
  }

  // 탭 클릭
  document.querySelectorAll('.cr-tab').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.cr-tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeTab = btn.dataset.tab;
      renderRoomList();
    });
  });

  // ── 방 미선택 안내 표시 ──
  function showNoRoom() {
    document.getElementById('cr-chat').style.display   = 'none';
    document.getElementById('cr-no-room').style.display = 'flex';
    document.getElementById('cr-title').textContent    = '💬 채팅방';
    currentCreatorNickname = '';
    roomParticipants = [];
    const mr = document.getElementById('cr-member-row');
    if (mr) mr.style.display = 'none';
    const hb = document.getElementById('cr-host-self-badge');
    if (hb) hb.style.display = 'none';
    renderRoomList();
  }

  function completeJoinRoomAfterJoinOk(roomId, roomName, historyFromServer) {
    if (currentRoomId && currentRoomId !== roomId) {
      roomMessages[currentRoomId] = document.getElementById('cr-messages').innerHTML;
      saveRoomMessages();
    }

    currentRoomId = roomId;
    joinedRoomIds.add(roomId);
    saveJoinedRooms();

    document.getElementById('cr-room-title').textContent = roomName;
    const msgsEl = document.getElementById('cr-messages');
    if (Array.isArray(historyFromServer)) {
      msgsEl.innerHTML = '';
      historyFromServer.forEach(function (h) {
        if (h && h.type === 'CHAT') appendChatMsg(h, true);
      });
      roomMessages[roomId] = msgsEl.innerHTML;
      saveRoomMessages();
    } else {
      const cached = roomMessages[roomId] || '';
      msgsEl.innerHTML = cached;
    }
    msgsEl.scrollTop = msgsEl.scrollHeight || 99999;
    document.getElementById('cr-no-room').style.display = 'none';
    document.getElementById('cr-chat').style.display    = 'flex';
    document.getElementById('cr-title').textContent     = '💬 ' + roomName;

    document.querySelectorAll('.cr-room-item').forEach(el => {
      el.classList.toggle('active-room', el.getAttribute('data-room-id') === roomId);
    });

    saveCrState();
    document.getElementById('cr-input').focus();
  }


  /**
   * 서버 JOIN_OK 이후에만 UI가 열림. 입장 요청은 여기서 WS로만 보냄.
   */
  window.joinRoom = function (roomId, roomName, secret) {
    if (!ws || ws.readyState !== WebSocket.OPEN) {
      alert('채팅 서버에 연결되지 않았습니다. 잠시 후 다시 시도해 주세요.');
      return;
    }
    const isSecret = !!secret;
    const already = joinedRoomIds.has(roomId);
    const storedPwd = loadRoomSecrets()[roomId];

    if (already) {
      if (isSecret && !storedPwd) {
        openPwdModal(roomId, roomName);
        return;
      }
      setJoinPending(true);
      pendingJoinPassword = isSecret ? (storedPwd || null) : null;
      ws.send(JSON.stringify({
        type: 'REJOIN_ROOM',
        roomId,
        password: isSecret ? (storedPwd || undefined) : undefined
      }));
      return;
    }

    if (isSecret) {
      openPwdModal(roomId, roomName);
      return;
    }

    setJoinPending(true);
    pendingJoinPassword = null;
    ws.send(JSON.stringify({ type: 'JOIN_ROOM', roomId }));
  };

  function submitPwdJoin() {
    const pwd = document.getElementById('cr-pwd-input').value;
    const rid = pendingPwdRoomId;
    if (!rid || !ws || ws.readyState !== WebSocket.OPEN) return;
    pendingJoinPassword = pwd;
    closePwdModal();
    setJoinPending(true);
    const already = joinedRoomIds.has(rid);
    ws.send(JSON.stringify(
      already
        ? { type: 'REJOIN_ROOM', roomId: rid, password: pwd }
        : { type: 'JOIN_ROOM', roomId: rid, password: pwd }
    ));
  }

  // ── 참여 방 저장/복원 ──
  function saveJoinedRooms() {
    sessionStorage.setItem('cr_joined_rooms', JSON.stringify([...joinedRoomIds]));
  }
  function loadJoinedRooms() {
    try {
      const s = sessionStorage.getItem('cr_joined_rooms');
      if (s) joinedRoomIds = new Set(JSON.parse(s));
    } catch (_) {}
  }

  // 방별 메시지 캐시 저장/복원
  function saveRoomMessages() {
    sessionStorage.setItem('cr_room_messages', JSON.stringify(roomMessages));
  }
  function loadRoomMessages() {
    try {
      const s = sessionStorage.getItem('cr_room_messages');
      if (s) roomMessages = JSON.parse(s);
    } catch (_) {}
  }

  // ── 메시지 추가 ──
  function appendChatMsg(msg, skipSave) {
    const isMe = msg.nickname === nickname;
    const el   = document.createElement('div');
    el.className = `cr-msg ${isMe ? 'me' : 'other'}`;
    el.innerHTML = isMe
      ? `<div>${escapeHtml(msg.content)}</div><div class="cr-msg-time">${escapeHtml(msg.time || '')}</div>`
      : `<div class="cr-msg-nick">${escapeHtml(msg.nickname)}</div>
         <div>${escapeHtml(msg.content)}</div>
         <div class="cr-msg-time">${escapeHtml(msg.time || '')}</div>`;
    const msgs = document.getElementById('cr-messages');
    msgs.appendChild(el);
    msgs.scrollTop = msgs.scrollHeight;
    if (!skipSave) saveCrState();
  }

  function appendSystemMsg(msg) {
    const el = document.createElement('div');
    el.className   = 'cr-msg system';
    el.textContent = msg.content;
    const msgs = document.getElementById('cr-messages');
    msgs.appendChild(el);
    msgs.scrollTop = msgs.scrollHeight;
    if (msg.userCount !== undefined)
      document.getElementById('cr-user-count').textContent = msg.userCount + '명';
    saveCrState();
  }

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g,'&amp;').replace(/</g,'&lt;')
      .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }
  function escapeAttr(str) {
    return String(str)
      .replace(/&/g,'&amp;')
      .replace(/"/g,'&quot;')
      .replace(/</g,'&lt;')
      .replace(/>/g,'&gt;');
  }

  function renderMemberBar() {
    const row = document.getElementById('cr-member-row');
    const list = document.getElementById('cr-member-list');
    const hostBadge = document.getElementById('cr-host-self-badge');
    const chat = document.getElementById('cr-chat');
    if (!row || !list || !chat) return;
    if (chat.style.display === 'none') {
      row.style.display = 'none';
      return;
    }
    row.style.display = 'block';
    const isHost = nickname === currentCreatorNickname;
    if (hostBadge) hostBadge.style.display = isHost ? 'inline-block' : 'none';
    if (!roomParticipants.length) {
      list.innerHTML = '';
      return;
    }
    list.innerHTML = roomParticipants.map(p => {
      const isMe = p === nickname;
      const canKick = isHost && !isMe && p !== currentCreatorNickname;
      const kickBtn = canKick
        ? `<button type="button" class="cr-kick" data-kick="${escapeAttr(p)}">추방</button>`
        : '';
      return `<span class="cr-member-chip">${escapeHtml(p)}${kickBtn}</span>`;
    }).join('');
  }

  // ── 상태 저장 ──
  function saveCrState() {
    sessionStorage.setItem('cr_messages',   document.getElementById('cr-messages').innerHTML);
    sessionStorage.setItem('cr_room_id',    currentRoomId || '');
    sessionStorage.setItem('cr_room_title', document.getElementById('cr-room-title').textContent || '');
    sessionStorage.setItem(crOpenKey,
      document.getElementById('cr-box').style.display === 'flex' ? '1' : '0');
    // 현재 방 메시지도 캐시에 반영
    if (currentRoomId) {
      roomMessages[currentRoomId] = document.getElementById('cr-messages').innerHTML;
    }

    saveJoinedRooms();
    saveRoomMessages();
  }

  /**
   * 로그아웃 시 호출: 패널 닫고 채팅 관련 sessionStorage 정리 (비로그인 복원 방지)
   */
  function closeChatroomOnLogout() {
    const box = document.getElementById('cr-box');
    if (box) box.style.display = 'none';
    document.getElementById('cr-create-overlay')?.classList.remove('cr-open');
    document.getElementById('cr-pwd-overlay')?.classList.remove('cr-open');
    sessionStorage.setItem(crOpenKey, '0');
    sessionStorage.removeItem('cr_pos_top');
    sessionStorage.removeItem('cr_pos_left');
    sessionStorage.removeItem('cr_room_id');
    sessionStorage.removeItem('cr_room_title');
    sessionStorage.removeItem('cr_messages');
    sessionStorage.removeItem('cr_joined_rooms');
    sessionStorage.removeItem('cr_room_messages');
    sessionStorage.removeItem(CR_SECRETS_KEY);
  }
  window.closeChatroomOnLogout = closeChatroomOnLogout;

  /**
   * ── 상태 복원 (WS onopen 시 호출) ──
   * 모달 위치는 rAF 2중첩으로 레이아웃 확정 후 계산
   */
  function restoreCrState() {
    if (!nickname || nickname === '익명') {
      closeChatroomOnLogout();
      return;
    }
    loadJoinedRooms();
    loadRoomMessages();

    const savedMessages  = sessionStorage.getItem('cr_messages');
    const savedRoomId    = sessionStorage.getItem('cr_room_id');
    const savedRoomTitle = sessionStorage.getItem('cr_room_title');
    const isOpen         = sessionStorage.getItem(crOpenKey) === '1';

    // 방 상태 복원
    if (savedRoomId) {
      currentRoomId = savedRoomId;
      document.getElementById('cr-room-title').textContent = savedRoomTitle;
      document.getElementById('cr-title').textContent      = '💬 ' + savedRoomTitle;
      document.getElementById('cr-no-room').style.display  = 'none';
      document.getElementById('cr-chat').style.display     = 'flex';
      if (savedMessages) {
        document.getElementById('cr-messages').innerHTML  = savedMessages;
        document.getElementById('cr-messages').scrollTop = 99999;
      }
      setJoinPending(true);
      setTimeout(() => {
        if (ws && ws.readyState === WebSocket.OPEN) {
          restoreRejoinPending = true;
          const secrets = loadRoomSecrets();
          const pwd = secrets[savedRoomId];
          ws.send(JSON.stringify({
            type: 'REJOIN_ROOM',
            roomId: savedRoomId,
            password: pwd || undefined
          }));
        }
      }, 500);
    }

    // 모달 위치/열림 복원은 restoreBoxOpen()에서 별도 처리
  }

  // ── 메시지 전송 ──
  function sendMsg() {
    const input = document.getElementById('cr-input');
    const text  = input.value.trim();
    if (joinPending || !text || !ws || ws.readyState !== WebSocket.OPEN || !currentRoomId) return;
    ws.send(JSON.stringify({ type: 'SEND_MSG', content: text }));
    input.value = '';
  }

  // ── 토글 ──
  window.toggleChatroomWidget = function () {
    // 비로그인이면 alert 후 로그인 페이지로 이동 (메인 hero-side-nav 버튼 포함 모든 진입점 처리)
    if (!nickname || nickname === '익명') {
      alert('로그인해야 이용이 가능합니다.');
      location.href = unitxLoginUrl();
      return;
    }

    const box = document.getElementById('cr-box');

    if (box.style.display === 'flex') {
      box.style.display = 'none';
      sessionStorage.setItem(crOpenKey, '0');
      return;
    }

    // AI 어시스턴트가 열려있으면 먼저 닫기
    const chatBox = document.getElementById('chat-box');
    if (chatBox && chatBox.style.display === 'flex') {
      chatBox.style.display = 'none';
      sessionStorage.setItem('chat_open', '0');
      sessionStorage.removeItem('chat_pos_top');
      sessionStorage.removeItem('chat_pos_left');
    }

    const pos = calcPositionFromBtn();
    if (!pos) return;

    applyBoxPos(pos);
    sessionStorage.setItem(crOpenKey, '1');
    saveCrState();
  };

  // ── 이벤트 바인딩 ──
  document.getElementById('cr-close').addEventListener('click', () => {
    document.getElementById('cr-box').style.display = 'none';
    sessionStorage.setItem(crOpenKey, '0');
    sessionStorage.removeItem('cr_pos_top');
    sessionStorage.removeItem('cr_pos_left');
  });
  document.getElementById('cr-back-btn').addEventListener('click', () => {
    if (currentRoomId) {
      joinedRoomIds.delete(currentRoomId);
      delete roomMessages[currentRoomId];
      removeRoomSecret(currentRoomId);
      saveJoinedRooms();
      saveRoomMessages();
      ws.send(JSON.stringify({ type: 'LEAVE_ROOM' }));
      currentRoomId = null;
      sessionStorage.removeItem('cr_room_id');
      sessionStorage.removeItem('cr_room_title');
      sessionStorage.removeItem('cr_messages');
    }
    showNoRoom();
  });
  document.getElementById('cr-open-create').addEventListener('click', openCreateModal);
  document.getElementById('cr-create-backdrop').addEventListener('click', closeCreateModal);
  document.getElementById('cr-modal-cancel').addEventListener('click', closeCreateModal);
  document.getElementById('cr-modal-secret').addEventListener('change', (e) => {
    document.getElementById('cr-modal-pw-wrap').style.display = e.target.checked ? 'block' : 'none';
  });
  document.getElementById('cr-modal-name').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') document.getElementById('cr-modal-submit').click();
  });
  document.getElementById('cr-modal-submit').addEventListener('click', () => {
    const name = document.getElementById('cr-modal-name').value.trim();
    const secret = document.getElementById('cr-modal-secret').checked;
    const password = document.getElementById('cr-modal-password').value;
    if (!name) {
      alert('방 이름을 입력하세요.');
      return;
    }
    if (secret && !password.trim()) {
      alert('비밀방은 비밀번호를 입력해야 합니다.');
      return;
    }
    if (!ws || ws.readyState !== WebSocket.OPEN) {
      alert('채팅 서버에 연결되지 않았습니다. 잠시 후 다시 시도해 주세요.');
      return;
    }
    const payload = { type: 'CREATE_ROOM', roomName: name };
    if (secret) {
      payload.secret = true;
      payload.password = password.trim();
    }
    ws.send(JSON.stringify(payload));
    closeCreateModal();
  });
  document.getElementById('cr-pwd-backdrop').addEventListener('click', closePwdModal);
  document.getElementById('cr-pwd-cancel').addEventListener('click', closePwdModal);
  document.getElementById('cr-pwd-submit').addEventListener('click', submitPwdJoin);
  document.getElementById('cr-pwd-input').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') submitPwdJoin();
  });
  function runRoomSearch() {
    roomSearchQuery = document.getElementById('cr-room-search').value;
    renderRoomList();
  }
  document.getElementById('cr-search-btn').addEventListener('click', runRoomSearch);
  document.getElementById('cr-room-search').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') runRoomSearch();
  });

  document.getElementById('cr-room-list').addEventListener('click', (e) => {
    const joinBtn = e.target.closest('.cr-r-join-btn');
    if (joinBtn) {
      e.preventDefault();
      e.stopPropagation();
      const id = joinBtn.getAttribute('data-cr-room-id');
      const name = joinBtn.getAttribute('data-cr-room-name');
      const secret = joinBtn.getAttribute('data-cr-secret') === '1';
      if (id != null && name != null) window.joinRoom(id, name, secret);
      return;
    }
    const row = e.target.closest('.cr-room-item[data-cr-row-click]');
    if (row && !e.target.closest('.cr-r-join-btn')) {
      const id = row.getAttribute('data-room-id');
      const name = row.getAttribute('data-room-name');
      const secret = row.getAttribute('data-cr-secret') === '1';
      if (id != null && name != null) window.joinRoom(id, name, secret);
    }
  });

  document.getElementById('cr-member-list').addEventListener('click', (e) => {
    const b = e.target.closest('.cr-kick');
    if (!b) return;
    const target = b.getAttribute('data-kick');
    if (!target || !currentRoomId || !ws || ws.readyState !== WebSocket.OPEN) return;
    e.preventDefault();
    if (!confirm(target + ' 님을 추방할까요?')) return;
    ws.send(JSON.stringify({ type: 'KICK_USER', roomId: currentRoomId, targetNickname: target }));
  });

  document.getElementById('cr-send-btn').addEventListener('click', sendMsg);
  document.getElementById('cr-input').addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMsg(); }
  });
  window.addEventListener('beforeunload', saveCrState);

  /**
   * ── 모달 열림 상태 복원 ──
   * rAF 타이밍 문제 우회: setTimeout 0으로 현재 콜스택 완전히 비운 뒤 실행
   * 버튼 DOM이 확정된 후 getBoundingClientRect() 호출
   */
  function restoreBoxOpen() {
    if (sessionStorage.getItem('chat_open') === '1') return;
    if (sessionStorage.getItem(crOpenKey) !== '1') return;
    if (!nickname || nickname === '익명') {
      sessionStorage.setItem(crOpenKey, '0');
      const box = document.getElementById('cr-box');
      if (box) box.style.display = 'none';
      return;
    }

    const savedTop  = sessionStorage.getItem('cr_pos_top');
    const savedLeft = sessionStorage.getItem('cr_pos_left');
    const pos = calcPositionFromBtn();
    if (pos) {
      applyBoxPos(pos);
      return;
    }
    if (savedTop !== null && savedLeft !== null) {
      applyBoxPos({ top: Number(savedTop), left: Number(savedLeft) });
    }
    retrySyncOpenCrBoxPosition();
  }

  function applyBoxPos(pos) {
    const box = document.getElementById('cr-box');
    if (!box || !pos) return;

    if (pos.mode === 'side-nav') {
      const right = Math.max(8, Number(pos.right) || 68);
      box.style.top = '50%';
      box.style.left = 'auto';
      box.style.right = right + 'px';
      box.style.transform = 'translateY(-50%)';
      box.style.display = 'flex';
      box.style.flexDirection = 'column';
      sessionStorage.setItem('cr_pos_top', '50%');
      sessionStorage.setItem('cr_pos_left', 'auto');
      return;
    }

    const clamped = clampCrPosition(pos.top, pos.left);
    box.style.top           = clamped.top  + 'px';
    box.style.left          = clamped.left + 'px';
    box.style.right         = 'auto';
    box.style.transform     = 'none';
    box.style.display       = 'flex';
    box.style.flexDirection = 'column';
    sessionStorage.setItem('cr_pos_top', String(clamped.top));
    sessionStorage.setItem('cr_pos_left', String(clamped.left));
  }

  function syncOpenCrBoxPosition() {
    const box = document.getElementById('cr-box');
    if (!box || box.style.display !== 'flex') return;
    const pos = calcPositionFromBtn();
    if (pos) {
      applyBoxPos(pos);
      return;
    }
    applyBoxPos({
      top: parseFloat(box.style.top),
      left: parseFloat(box.style.left)
    });
  }

  function retrySyncOpenCrBoxPosition(maxRetries = 12, delayMs = 80) {
    let tries = 0;
    const tick = () => {
      const box = document.getElementById('cr-box');
      if (!box || box.style.display !== 'flex') return;
      const pos = calcPositionFromBtn();
      if (pos) {
        applyBoxPos(pos);
        return;
      }
      tries += 1;
      if (tries < maxRetries) setTimeout(tick, delayMs);
    };
    tick();
  }

  function forceAlignOpenCrBox() {
    const box = document.getElementById('cr-box');
    if (!box || box.style.display !== 'flex') return;
    const pos = calcPositionFromBtn();
    if (!pos) return;
    applyBoxPos(pos);
  }

  connect();

  // ── 초기화 ──
  function init() {
    initChatroomBtn();
    retryInitChatroomBtn();
    document.querySelectorAll('form[action*="logout"]').forEach(f => {
      f.addEventListener('submit', () => { closeChatroomOnLogout(); });
    });
    restoreBoxOpen(); // 버튼 생성 직후 복원 (WS 타이밍 무관)
    window.addEventListener('resize', syncOpenCrBoxPosition);
    window.addEventListener('pageshow', syncOpenCrBoxPosition);
    setTimeout(syncOpenCrBoxPosition, 120);
    setTimeout(syncOpenCrBoxPosition, 420);
    setTimeout(() => retrySyncOpenCrBoxPosition(), 40);
    setTimeout(() => retrySyncOpenCrBoxPosition(), 260);
    window.addEventListener('scroll', forceAlignOpenCrBox, true);
    window.addEventListener('hashchange', forceAlignOpenCrBox);
    window.addEventListener('popstate', forceAlignOpenCrBox);
    setInterval(forceAlignOpenCrBox, 700);
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
