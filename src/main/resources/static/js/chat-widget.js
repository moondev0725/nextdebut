(function () {
  const chatOpenKey = 'chat_open';

  // ── 위젯 HTML ──
  const widget = document.createElement('div');
  widget.id = 'chat-widget';
  widget.innerHTML = `
    <div id="chat-box" style="display:none;">
      <div id="chat-header">
        <span>AI 어시스턴트</span>
        <div>
          <button id="chat-clear" title="대화 초기화">🗑</button>
          <button id="chat-close">✕</button>
        </div>
      </div>
      <div id="chat-messages"></div>
      <div id="chat-input-row">
        <input type="text" id="chat-input" placeholder="메시지를 입력하세요..." autocomplete="off"/>
        <button id="chat-send">전송</button>
      </div>
    </div>
  `;
  document.body.appendChild(widget);

  const style = document.createElement('style');
  style.textContent = `
    #chat-widget { position:fixed; z-index:9999; font-family:'Orbitron',sans-serif; }
    #chat-box {
      position:fixed; width:320px;
      background: rgba(15, 8, 30, 0.55);
      backdrop-filter: blur(20px) saturate(1.6);
      -webkit-backdrop-filter: blur(20px) saturate(1.6);
      border: 1px solid rgba(232,176,196,0.25);
      border-radius: 20px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.05) inset,
                  0 0 40px rgba(200,184,216,0.08);
      display: flex; flex-direction: column; overflow: hidden;
    }
    #chat-header {
      background: linear-gradient(135deg, rgba(232,176,196,0.35) 0%, rgba(200,184,216,0.30) 50%, rgba(170,192,208,0.25) 100%);
      border-bottom: 1px solid rgba(232,176,196,0.30);
      color: #fff; padding: 12px 16px;
      display: flex; justify-content: space-between; align-items: center;
      font-family: 'Orbitron', sans-serif;
      font-size: 13px; font-weight: 700; letter-spacing: .12em;
    }
    #chat-header button {
      background: none; border: none; color: rgba(255,220,235,0.8);
      cursor: pointer; font-size: 14px; margin-left: 8px; transition: color .2s;
    }
    #chat-header button:hover { color: #fff; }
    #chat-messages {
      height: 340px; overflow-y: auto; padding: 14px;
      display: flex; flex-direction: column; gap: 10px;
      scrollbar-width: thin;
      scrollbar-color: rgba(232,176,196,0.2) transparent;
    }
    .chat-msg {
      max-width: 80%; padding: 9px 14px; border-radius: 18px;
      font-family: 'Orbitron', sans-serif;
      font-size: 12px; letter-spacing: .03em; line-height: 1.7;
      word-break: break-word;
    }
    .chat-msg.user {
      align-self: flex-end;
      background: linear-gradient(135deg, rgba(232,176,196,0.75), rgba(200,184,216,0.70));
      color: #fff; border-bottom-right-radius: 4px;
      box-shadow: 0 2px 12px rgba(232,176,196,0.25);
      border: 1px solid rgba(255,255,255,0.15);
    }
    .chat-msg.bot {
      align-self: flex-start;
      background: rgba(255,255,255,0.06);
      color: rgba(255,220,235,0.90); border-bottom-left-radius: 4px;
      border: 1px solid rgba(232,176,196,0.15);
      box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    }
    .chat-msg.typing {
      color: rgba(232,176,196,0.5); font-style: italic;
      font-size: 11px; letter-spacing: .08em;
    }
    #chat-input-row {
      display: flex; border-top: 1px solid rgba(232,176,196,0.20);
      background: rgba(232,176,196,0.04);
    }
    #chat-input {
      flex: 1; border: none; padding: 12px 14px;
      font-family: 'Orbitron', sans-serif;
      font-size: 11px; letter-spacing: .08em;
      outline: none; background: transparent;
      color: rgba(255,220,235,0.9);
      caret-color: rgba(232,176,196,0.9);
    }
    #chat-input::placeholder {
      color: rgba(232,176,196,0.35);
      font-family: 'Orbitron', sans-serif;
      font-size: 11px; letter-spacing: .08em;
    }
    #chat-input:focus { box-shadow: inset 0 0 0 1px rgba(232,176,196,0.25); }
    #chat-send {
      background: linear-gradient(135deg, rgba(232,176,196,0.5), rgba(200,184,216,0.45));
      color: #fff; border: none; padding: 12px 16px; cursor: pointer;
      font-family: 'Orbitron', sans-serif;
      font-size: 11px; letter-spacing: .12em; font-weight: 700;
      transition: background .2s;
      border-left: 1px solid rgba(232,176,196,0.20);
    }
    #chat-send:hover {
      background: linear-gradient(135deg, rgba(232,176,196,0.75), rgba(200,184,216,0.65));
    }
    #globalChatBar {
      position: fixed; right: 0; z-index: 999;
      padding: 0 22px; display: flex;
      align-items: center; justify-content: flex-end;
    }
    #chat-toggle-btn-global {
      background: linear-gradient(135deg, rgba(232,121,163,0.20), rgba(167,139,250,0.18));
      border: 1px solid rgba(167,139,250,0.55);
      color: rgba(80,20,120,0.95);
      border-radius: 999px; padding: 6px 16px; font-size: 11px;
      font-family: 'Orbitron', sans-serif; letter-spacing: .12em;
      cursor: pointer; display: flex; align-items: center; gap: 7px;
      transition: all .25s ease;
      box-shadow: 0 0 14px rgba(167,139,250,0.25), inset 0 1px 0 rgba(255,255,255,0.4);
      white-space: nowrap;
    }
    #chat-toggle-btn-global:hover {
      background: linear-gradient(135deg, rgba(232,121,163,0.35), rgba(167,139,250,0.30));
      border-color: rgba(167,139,250,0.80);
      box-shadow: 0 0 22px rgba(167,139,250,0.45);
    }
  `;
  document.head.appendChild(style);

  // ── WebSocket ──
  const protocol = location.protocol === 'https:' ? 'wss' : 'ws';
  let ws = null;

  function connect() {
    ws = new WebSocket(`${protocol}://${location.host}/ws/chat`);
    ws.onmessage = (e) => {
      removeTyping();
      if (e.data === '__cleared__') {
        document.getElementById('chat-messages').innerHTML = '';
        sessionStorage.removeItem('chat_history');
        appendMsg('bot', '대화가 초기화되었습니다.');
        return;
      }
      appendMsg('bot', e.data);
    };
    ws.onclose = () => { setTimeout(connect, 3000); };
  }
  connect();

  function appendMsg(role, text, save = true) {
    const el = document.createElement('div');
    el.className = `chat-msg ${role}`;
    el.textContent = text;
    const messages = document.getElementById('chat-messages');
    messages.appendChild(el);
    messages.scrollTop = messages.scrollHeight;
    if (save) saveHistory();
  }

  function appendTyping() {
    const el = document.createElement('div');
    el.className = 'chat-msg bot typing';
    el.id = 'typing-indicator';
    el.textContent = '입력 중...';
    const messages = document.getElementById('chat-messages');
    messages.appendChild(el);
    messages.scrollTop = messages.scrollHeight;
  }

  function removeTyping() {
    const el = document.getElementById('typing-indicator');
    if (el) el.remove();
  }

  function sendMsg() {
    const input = document.getElementById('chat-input');
    const text = input.value.trim();
    if (!text || !ws || ws.readyState !== WebSocket.OPEN) return;
    appendMsg('user', text);
    appendTyping();
    ws.send(text);
    input.value = '';
  }

  function saveHistory() {
    sessionStorage.setItem('chat_history', document.getElementById('chat-messages').innerHTML);
  }

  function restoreHistory() {
    const saved = sessionStorage.getItem('chat_history');
    if (saved) {
      document.getElementById('chat-messages').innerHTML = saved;
      document.getElementById('chat-messages').scrollTop = 99999;
    } else {
      appendMsg('bot', '안녕하세요! 무엇이든 물어보세요 ✨', false);
    }
  }

  function getToggleBtn() {
    const localBtn = document.getElementById('chat-toggle-btn');
    if (localBtn) return localBtn;

    const sideNavBtn = document.querySelector('.hero-side-nav button[onclick*="toggleChatWidget"]');
    if (sideNavBtn) return sideNavBtn;

    return document.getElementById('chat-toggle-btn-global');
  }

  function calcPositionFromBtn() {
    const boxWidth  = 320;
    const boxHeight = 420;
    const gap       = 8;
    const margin    = 8;
    const vw        = document.documentElement.clientWidth;
    const vh        = document.documentElement.clientHeight;

    const btn = getToggleBtn();
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

  function clampPosition(top, left) {
    const boxWidth = 320;
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

  function applyBoxPosition(topOrPos, left) {
    const box = document.getElementById('chat-box');
    if (!box) return;

    if (typeof topOrPos === 'object' && topOrPos !== null) {
      if (topOrPos.mode === 'side-nav') {
        const right = Math.max(8, Number(topOrPos.right) || 68);
        box.style.top = '50%';
        box.style.left = 'auto';
        box.style.right = right + 'px';
        box.style.transform = 'translateY(-50%)';
        box.style.display = 'flex';
        saveBoxState(true, '50%', 'auto');
        return;
      }

      const pos = clampPosition(topOrPos.top, topOrPos.left);
      box.style.top = pos.top + 'px';
      box.style.left = pos.left + 'px';
      box.style.right = 'auto';
      box.style.transform = 'none';
      box.style.display = 'flex';
      saveBoxState(true, pos.top, pos.left);
      return;
    }

    const pos = clampPosition(topOrPos, left);
    box.style.top = pos.top + 'px';
    box.style.left = pos.left + 'px';
    box.style.right = 'auto';
    box.style.transform = 'none';
    box.style.display = 'flex';
    saveBoxState(true, pos.top, pos.left);
  }

  function saveBoxState(isOpen, top, left) {
    sessionStorage.setItem(chatOpenKey, isOpen ? '1' : '0');
    if (isOpen && top !== undefined) {
      sessionStorage.setItem('chat_pos_top',  String(top));
      sessionStorage.setItem('chat_pos_left', String(left));
    } else if (!isOpen) {
      sessionStorage.removeItem('chat_pos_top');
      sessionStorage.removeItem('chat_pos_left');
    }
  }

  function initGlobalChatBar() {
    if (document.querySelector('.hero-side-nav')) {
      const staleBar = document.getElementById('globalChatBar');
      if (staleBar) staleBar.remove();
      return;
    }

    const dayBar = document.querySelector('.day-bar');
    if (dayBar) {
      const btn = document.getElementById('chat-toggle-btn');
      if (btn) btn.style.opacity = '1';
      return;
    }

    if (document.getElementById('chat-toggle-btn')) return;

    const nav       = document.querySelector('nav');
    const navBottom = nav ? nav.getBoundingClientRect().bottom : 68;
    const bar       = document.createElement('div');
    bar.id = 'globalChatBar';
    bar.style.cssText = `position:fixed; top:${navBottom}px; right:0; z-index:999;
      height:48px; padding:0 22px; display:flex; align-items:center; justify-content:flex-end;`;

    const btn = document.createElement('button');
    btn.id = 'chat-toggle-btn-global';
    btn.innerHTML = '<i class="fas fa-robot"></i>';
    btn.title = 'AI 챗봇';
    btn.onclick = () => toggleChatWidget();
    btn.style.cssText = `
      width:38px; height:38px; border-radius:12px;
      border:1px solid rgba(167,139,250,0.55);
      background:rgba(248,250,252,0.9);
      color:#1f2937; font-size:14px;
      display:flex; align-items:center; justify-content:center;
      box-shadow:0 10px 24px rgba(148,163,184,0.4);
      cursor:pointer; transition:all .18s ease;
    `;
    btn.onmouseenter = () => {
      btn.style.background   = '#fff';
      btn.style.borderColor  = 'rgba(232,121,163,0.65)';
      btn.style.transform    = 'scale(1.08)';
      btn.style.boxShadow    = '0 14px 24px rgba(99,102,241,0.18)';
    };
    btn.onmouseleave = () => {
      btn.style.background   = 'rgba(248,250,252,0.9)';
      btn.style.borderColor  = 'rgba(167,139,250,0.55)';
      btn.style.transform    = 'scale(1)';
      btn.style.boxShadow    = '0 8px 18px rgba(148,163,184,0.35)';
    };
    bar.appendChild(btn);
    document.body.appendChild(bar);

    window.addEventListener('resize', () => {
      bar.style.top = 'calc(var(--nav-h) + 16px)';
    });
  }

  function restoreBoxState() {
    if (sessionStorage.getItem('cr_open')   === '1') return;
    if (sessionStorage.getItem(chatOpenKey) !== '1') return;

    const savedTop  = sessionStorage.getItem('chat_pos_top');
    const savedLeft = sessionStorage.getItem('chat_pos_left');
    const pos = calcPositionFromBtn();
    if (pos) {
      applyBoxPosition(pos);
      return;
    }
    if (savedTop !== null && savedLeft !== null) {
      applyBoxPosition(Number(savedTop), Number(savedLeft));
    }
    retrySyncOpenBoxPosition();
  }

  function syncOpenBoxPosition() {
    const box = document.getElementById('chat-box');
    if (!box || box.style.display !== 'flex') return;
    const pos = calcPositionFromBtn();
    if (pos) {
      applyBoxPosition(pos);
      return;
    }
    applyBoxPosition(parseFloat(box.style.top), parseFloat(box.style.left));
  }

  function retrySyncOpenBoxPosition(maxRetries = 12, delayMs = 80) {
    let tries = 0;
    const tick = () => {
      const box = document.getElementById('chat-box');
      if (!box || box.style.display !== 'flex') return;
      const pos = calcPositionFromBtn();
      if (pos) {
        applyBoxPosition(pos);
        return;
      }
      tries += 1;
      if (tries < maxRetries) setTimeout(tick, delayMs);
    };
    tick();
  }

  function forceAlignOpenChatBox() {
    const box = document.getElementById('chat-box');
    if (!box || box.style.display !== 'flex') return;
    const pos = calcPositionFromBtn();
    if (!pos) return;
    applyBoxPosition(pos);
  }

  window.toggleChatWidget = function () {
    const box = document.getElementById('chat-box');

    if (box.style.display === 'flex') {
      box.style.display = 'none';
      saveBoxState(false);
      return;
    }

    const crBox = document.getElementById('cr-box');
    if (crBox && crBox.style.display === 'flex') {
      crBox.style.display = 'none';
      sessionStorage.setItem('cr_open', '0');
    }

    const pos = calcPositionFromBtn();
    if (!pos) return;

    applyBoxPosition(pos);
    document.getElementById('chat-input').focus();
  };

  document.getElementById('chat-close').addEventListener('click', () => {
    document.getElementById('chat-box').style.display = 'none';
    saveBoxState(false);
  });
  document.getElementById('chat-clear').addEventListener('click', () => {
    if (ws && ws.readyState === WebSocket.OPEN) ws.send('__clear__');
  });
  document.getElementById('chat-send').addEventListener('click', sendMsg);
  document.getElementById('chat-input').addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMsg(); }
  });

  function markGlobalSideNavActive() {
    var nav = document.querySelector('.hero-side-nav--global');
    if (!nav) return;
    var p = (location && location.pathname) ? location.pathname : '';
    nav.querySelectorAll('a.hero-side-btn').forEach(function (a) {
      var href = a.getAttribute('href') || '';
      var hrefPath = (href.split('?')[0] || '');
      var isBoardNavLink = /\/board\/?$/.test(hrefPath) && hrefPath.indexOf('/boards/') === -1;
      var boardFreeActive = isBoardNavLink && (p.indexOf('/boards/free') > -1 || /\/board\/?$/.test(p));
      var isActive =
        (p.indexOf('/game/run/ranking') > -1 && href.indexOf('/game/run/ranking') > -1) ||
        boardFreeActive ||
        (p.indexOf('/guide') > -1 && href.indexOf('/guide') > -1) ||
        (p.indexOf('/game') > -1 && href.indexOf('/game') > -1 && href.indexOf('/game/run/ranking') === -1);
      if (isActive) a.classList.add('is-active');
    });
  }

  function init() {
    markGlobalSideNavActive();
    initGlobalChatBar();
    restoreHistory();
    restoreBoxState();
    window.addEventListener('resize', syncOpenBoxPosition);
    window.addEventListener('pageshow', syncOpenBoxPosition);
    setTimeout(syncOpenBoxPosition, 120);
    setTimeout(syncOpenBoxPosition, 420);
    setTimeout(() => retrySyncOpenBoxPosition(), 40);
    setTimeout(() => retrySyncOpenBoxPosition(), 260);
    window.addEventListener('scroll', forceAlignOpenChatBox, true);
    window.addEventListener('hashchange', forceAlignOpenChatBox);
    window.addEventListener('popstate', forceAlignOpenChatBox);
    setInterval(forceAlignOpenChatBox, 700);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
