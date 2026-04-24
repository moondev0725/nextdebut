const NDX_GAME_CONFIG = window.NDX_GAME_CONFIG || {};
(function(){
  window.__gameToastTimer=null;
  window.showToast=function(msg, kind, durationMs){
    var el=document.getElementById('gameToast');
    if(!el){ try{ alert(String(msg||'')); }catch(e){} return; }
    el.className='game-toast'+(kind==='ok'?' game-toast--ok':(kind==='warn'?' game-toast--warn':''));
    el.textContent=String(msg||'');
    el.classList.add('show');
    if(window.__gameToastTimer) clearTimeout(window.__gameToastTimer);
    var hideAfter = (durationMs != null && isFinite(Number(durationMs)) && Number(durationMs) > 0) ? Number(durationMs) : 2800;
    window.__gameToastTimer=setTimeout(function(){
      try{ el.classList.remove('show'); }catch(e){}
    },hideAfter);
  };
})();

(function(){
  var seenKey='ndx_seen_start_loading_'+ String(NDX_GAME_CONFIG.runId || '');
  if(sessionStorage.getItem(seenKey)==='1'){
    var lov=document.getElementById('lov');
    var wrap=document.getElementById('gsWrap');
    if(lov) lov.style.display='none';
    if(wrap){ wrap.style.opacity='1'; wrap.style.animation='none'; }
    return;
  }
  sessionStorage.setItem(seenKey,'1');
})();

/* ══════════════════════════════════
   로딩 퍼센트 (100% 시 오버레이 숨김)
══════════════════════════════════ */
(function(){
  var el=document.getElementById('lpct'),t=Date.now(),dur=2200;
  if(!el)return;
  (function tick(){
    var n=Math.min(100,Math.floor(((Date.now()-t)/dur)*100));
    el.textContent=n+'%';
    if(n<100)requestAnimationFrame(tick);
    else{
      var lov=document.getElementById('lov');
      if(lov) lov.style.display='none';
    }
  })();
})();

(function(){
  function fillMonthBar(){
    var el=document.getElementById('monthProgressFill');
    if(!el)return;
    var pct=parseInt(el.getAttribute('data-pct'),10);
    if(isNaN(pct))pct=0;
    if(pct<0)pct=0;if(pct>100)pct=100;
    requestAnimationFrame(function(){
      requestAnimationFrame(function(){el.style.width=pct+'%';});
    });
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',fillMonthBar);
  else fillMonthBar();
})();

/* ══════════════════════════════════
   씬 Canvas — 별 + 유성
══════════════════════════════════ */
(function(){
  var cv=document.getElementById('sceneCanvas');
  var area=cv.parentElement;
  if(!cv||!area)return;
  var reducedMotion=window.matchMedia&&window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var ctx=cv.getContext('2d',{alpha:true,desynchronized:true});
  var W,H,RAF_ID=0;
  function resize(){
    var dpr=Math.min(window.devicePixelRatio||1, 1.25);
    W=Math.max(1,Math.floor(area.offsetWidth*dpr));
    H=Math.max(1,Math.floor(area.offsetHeight*dpr));
    cv.width=W;cv.height=H;
    cv.style.width=area.offsetWidth+'px';
    cv.style.height=area.offsetHeight+'px';
    try{ ctx.setTransform(1,0,0,1,0,0); ctx.scale(dpr,dpr); }catch(e){}
    W=area.offsetWidth; H=area.offsetHeight;
  }
  resize();
  new ResizeObserver(resize).observe(area);

  var stars=[];
  var STAR_COUNT=reducedMotion?36:88;
  for(var i=0;i<STAR_COUNT;i++){
    stars.push({
      x:Math.random(),y:Math.random(),
      r:Math.random()*1.3+.3,
      op:Math.random()*.55+.12,
      spd:Math.random()*.0004+.0001,
      phase:Math.random()*Math.PI*2,
      col:['rgba(255,210,230,OP)','rgba(248,182,200,OP)','rgba(253,235,241,OP)','rgba(255,255,255,OP)'][Math.floor(Math.random()*4)]
    });
  }
  var meteors=[];
  function fxOff(){ return document.documentElement.classList.contains('fx-off'); }
  function spawnMeteor(){
    if(document.hidden||reducedMotion||fxOff())return;
    meteors.push({x:Math.random()*.6+.05,y:Math.random()*.25,len:Math.random()*160+90,
      spd:Math.random()*.014+.008,angle:Math.PI/5.5,
      life:1,decay:Math.random()*.02+.013,col:'rgba(239,147,176,OP)'});
  }
  var meteorIv=fxOff()?null:setInterval(spawnMeteor,3600);
  var t=0;
  var lastTs=0;
  function draw(ts){
    RAF_ID=requestAnimationFrame(draw);
    if(document.hidden)return;
    if(ts-lastTs<33)return; // 30fps 제한으로 클릭 체감 렉 완화
    lastTs=ts;
    t+=.016;ctx.clearRect(0,0,W,H);
    stars.forEach(function(s){
      var op=s.op*(0.55+0.45*Math.sin(t*s.spd*200+s.phase));
      var c=s.col.replace('OP',op.toFixed(2));
      ctx.beginPath();ctx.arc(s.x*W,s.y*H,s.r,0,Math.PI*2);
      ctx.fillStyle=c;ctx.shadowBlur=s.r*4;ctx.shadowColor=c;ctx.fill();
    });
    ctx.shadowBlur=0;
    meteors=meteors.filter(function(m){
      m.life-=m.decay;if(m.life<=0)return false;
      var ex=m.x*W+Math.cos(m.angle)*m.len,ey=m.y*H+Math.sin(m.angle)*m.len;
      var g=ctx.createLinearGradient(m.x*W,m.y*H,ex,ey);
      g.addColorStop(0,m.col.replace('OP',(m.life*.85).toFixed(2)));
      g.addColorStop(1,m.col.replace('OP','0'));
      ctx.beginPath();ctx.moveTo(m.x*W,m.y*H);ctx.lineTo(ex,ey);
      ctx.strokeStyle=g;ctx.lineWidth=1.5;ctx.stroke();
      ctx.beginPath();ctx.arc(m.x*W,m.y*H,2,0,Math.PI*2);
      ctx.fillStyle=m.col.replace('OP',m.life.toFixed(2));
      ctx.shadowBlur=10;ctx.shadowColor='rgba(239,147,176,.8)';ctx.fill();ctx.shadowBlur=0;
      m.x+=Math.cos(m.angle)*m.spd;m.y+=Math.sin(m.angle)*m.spd;return true;
    });
  }
  function stopSceneFx(){
    try{ cancelAnimationFrame(RAF_ID); RAF_ID=0; }catch(e){}
    try{ if(meteorIv) clearInterval(meteorIv); }catch(e){}
    meteorIv=null;
    try{ ctx.clearRect(0,0,W,H); }catch(e){}
  }
  function startSceneFx(){
    if(fxOff())return;
    if(!meteorIv) meteorIv=setInterval(spawnMeteor,3600);
    if(!RAF_ID) RAF_ID=requestAnimationFrame(draw);
  }
  if(!fxOff()) RAF_ID=requestAnimationFrame(draw);
  else try{ ctx.clearRect(0,0,W,H); }catch(e){}
  window.addEventListener('unitxFxChange', function(){
    if(fxOff()) stopSceneFx();
    else startSceneFx();
  });
  window.addEventListener('pagehide', function(){
    try{ clearInterval(meteorIv); }catch(e){}
    try{ cancelAnimationFrame(RAF_ID); }catch(e){}
  }, {once:true});
})();

/* ══════════════════════════════════
   스탯 바 애니메이션
══════════════════════════════════ */
setTimeout(function(){
  document.querySelectorAll('.sfill[data-w]').forEach(function(el){
    el.style.width=el.getAttribute('data-w')+'%';
  });

  // 초기 레벨/역할/EXP 계산
  document.querySelectorAll('.mcard').forEach(function(card){
    try{
      var totalEl=card.querySelector('.ctotal-num');
      if(!totalEl)return;
      var t=memberRawTotalFromCard(card);
      // 임시 LV 규칙: 총합 기준
      var lv=1;
      if(t>=260)lv=5; else if(t>=220)lv=4; else if(t>=180)lv=3; else if(t>=140)lv=2;
      var lvEl=card.querySelector('.clv-pill[data-lv-holder]');
      if(lvEl)lvEl.textContent='LV '+lv;

      // 역할: 최고 스탯 기준
      var vs={ '보컬':'v', '댄스':'d', '스타':'s', '멘탈':'m', '팀웍':'t' };
      var bestName='ALL-ROUND',bestVal=-1;
      Object.keys(vs).forEach(function(k){
        var vEl=card.querySelector('.sval[data-key="'+vs[k]+'"]');
        var v=memberRawStatFromValueEl(vEl);
        if(v>bestVal){bestVal=v;bestName=k;}
      });
      var roleLabel='ALL-ROUND';
      if(bestName==='보컬')roleLabel='MAIN VOCAL';
      else if(bestName==='댄스')roleLabel='MAIN DANCER';
      else if(bestName==='스타')roleLabel='CENTER';
      else if(bestName==='멘탈')roleLabel='LEADER';
      else if(bestName==='팀웍')roleLabel='TEAM MAKER';
      var roleEl=card.querySelector('.role-badge[data-role-holder]');
      if(roleEl)roleEl.textContent=roleLabel;

      // EXP: 총합을 300 기준으로 0~100%
      var expPct=Math.max(0,Math.min(100,Math.round((t/300)*100)));
      var expFill=card.querySelector('.exp-fill');
      if(expFill){expFill.style.width=expPct+'%';}
    }catch(e){}
  });

  // 초기 목표 진행도
  try{
    var totalHeader=document.querySelector('.game-hud-item--money .game-hud-val');
    var curTotal=parseInt(totalHeader? totalHeader.textContent.replace(/[^0-9\-]/g,'') : '0')||0;
    updateGoals(curTotal, 0, null);
  }catch(e){}

  try{
    var df=document.getElementById('debutProgressFill');
    var dl=document.getElementById('debutProgressPctLabel');
    var effProg=(typeof effectiveMonthProgressPct==='function')?effectiveMonthProgressPct():MONTH_PROGRESS_PCT;
    if(df&&typeof effProg==='number') df.style.width=effProg+'%';
    if(dl&&typeof effProg==='number') dl.textContent=effProg+'%';
  }catch(e){}

},2100);

/* ══════════════════════════════════
   전역 상태
══════════════════════════════════ */
var RUN_ID=String(NDX_GAME_CONFIG.runId || '');
var CTX=String(NDX_GAME_CONFIG.ctx || '');
var MONTH_NUM=Number(NDX_GAME_CONFIG.monthNum || 0);
var CURRENT_TOTAL_FANS=Number(NDX_GAME_CONFIG.totalFans || 0);
var CURRENT_CORE_FANS=Number(NDX_GAME_CONFIG.coreFans || 0);
var CURRENT_CASUAL_FANS=Number(NDX_GAME_CONFIG.casualFans || 0);
var CURRENT_LIGHT_FANS=Number(NDX_GAME_CONFIG.lightFans || 0);
var DAY_NUM=Number(NDX_GAME_CONFIG.dayNum || 0);
var TEAM_TOTAL_STAT=Number(NDX_GAME_CONFIG.teamTotalStat || 0);
var MY_LIVE_RANK=Number(NDX_GAME_CONFIG.myLiveRank || 999);
var MONTH_PROGRESS_PCT=Number(NDX_GAME_CONFIG.monthProgressPct || 0);
var imgMap=Object.assign({}, NDX_GAME_CONFIG.rosterImgMap || {});

// 초기 로스터(스탯 바/컨디션 계산용)
var __initialRoster = Array.isArray(NDX_GAME_CONFIG.rosterStats) ? NDX_GAME_CONFIG.rosterStats.slice() : [];

/* 맵 장소 이벤트 등으로 조정하는 컨디션 바 표시 오프셋(로스터 기반 계산값에 가산, 0~100 클램프) */
window.__mapEventBarBonus = { focus: 0, stress: 0, team: 0, condition: 0 };

/** 팬이 마이너스로 변한 턴: 스트레스 +2%p · 팀워크(표시)는 감소분에 비례해 ↓ */
function applyFanLossConditionBonus(data){
  var d = Number(data && data.fanDelta);
  if(!isFinite(d) || d >= 0) return;
  var loss = Math.abs(Math.floor(d));
  if(loss < 1) return;
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  window.__mapEventBarBonus.stress = (Number(window.__mapEventBarBonus.stress) || 0) + 2;
  window.__mapEventBarBonus.team = (Number(window.__mapEventBarBonus.team) || 0) - Math.min(30, loss + Math.ceil(loss / 2));
}

/** 팬이 늘어난 턴: 컨디션 바 스트레스 2~3% 하락 */
function applyFanGainStressRelief(data){
  var d = Number(data && data.fanDelta);
  if(!isFinite(d) || d <= 0) return;
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  var down = 2 + Math.floor(Math.random() * 2);
  window.__mapEventBarBonus.stress = (Number(window.__mapEventBarBonus.stress) || 0) - down;
}

function ndxIsMiniGameFailed(data){
  if(!data) return false;
  var v = data.miniGameFailed;
  return v === true || v === 'true' || v === 1 || v === '1';
}

/** 미니게임 실패: 스트레스만 즉시 반영(채팅 시뮬이 스트레스 decay에 쓰도록). 팀워크 −2%는 시뮬 이후 별도 적용 */
function applyMiniGameFailConditionBonus(data){
  if(!ndxIsMiniGameFailed(data)) return;
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  var up = 1 + Math.floor(Math.random() * 2);
  window.__mapEventBarBonus.stress = (Number(window.__mapEventBarBonus.stress) || 0) + up;
}

/**
 * 채팅 시뮬이 deltaTeamwork로 팀워크를 다시 올린 뒤에 호출 — 미니 실패 시 표시 팀워크를 확실히 −2%p
 */
function applyMiniGameFailTeamworkPenaltyAfterSim(data){
  if(!ndxIsMiniGameFailed(data)) return;
  if(!window._pendingTurnHadMiniGame) return;
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  window.__mapEventBarBonus.team = (Number(window.__mapEventBarBonus.team) || 0) - 1;
  try{
    var roster = typeof collectRosterFromDom === 'function' ? collectRosterFromDom() : [];
    if(roster && roster.length) updateConditionBarsFromRoster(roster);
  }catch(e){}
}

/** 미니게임 성공: 스트레스↓, 팀워크·집중도 소폭↑ — 소확률 대성공 시 추가 */
function applyMiniGameSuccessConditionBonus(data){
  if(!window._pendingTurnHadMiniGame) return;
  if(!data || ndxIsMiniGameFailed(data)) return;
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  var b = window.__mapEventBarBonus;
  var crit = Math.random() < 0.15;
  var down = crit ? 8 + Math.floor(Math.random() * 4) : 3 + Math.floor(Math.random() * 3);
  b.stress = (Number(b.stress) || 0) - down;
  b.team = (Number(b.team) || 0) + (crit ? 6 + Math.floor(Math.random() * 3) : 2 + Math.floor(Math.random() * 3));
  b.focus = (Number(b.focus) || 0) + (crit ? 4 : 1 + Math.floor(Math.random() * 2));
  try{
    if(window.IdolSimStatusPresentation && typeof window.IdolSimStatusPresentation.appendLogLine === 'function'){
      window.IdolSimStatusPresentation.appendLogLine(
        crit
          ? '미니게임 대성공 · 스트레스 −' + down + ' · 팀워크·집중도 보너스'
          : '미니게임 성공 · 스트레스 −' + down + ' · 팀워크·집중도 소폭↑'
      );
    }
  }catch(e0){}
}

/** 훈련 페이즈 문자열 → 캘린더 일차(1~84). 서버 GameController·GameService와 동일 규칙 */
function ndxParseTrainingDayFromPhase(phase){
  var p = String(phase || '').trim();
  if (!p) return 1;
  if (p === 'FINISHED') return 84;
  if (p === 'DEBUT_EVAL') return 84;
  if (p === 'MID_EVAL') return 56;
  if (p.indexOf('DAY') !== 0) return 1;
  var us = p.indexOf('_');
  if (us <= 3) return 1;
  var n = parseInt(p.substring(3, us), 10);
  if (!isFinite(n) || n < 1) return 1;
  if (n > 84) return 84;
  return n;
}

/** 현재 훈련 일차(페이즈 동기). 채팅으로 페이즈가 바뀐 뒤에도 막대가 맞게 */
function ndxTrainingDayNumForBars(){
  try{
    var ph = '';
    if (typeof currentPhase !== 'undefined' && currentPhase) ph = String(currentPhase);
    else if (typeof NDX_GAME_CONFIG !== 'undefined' && NDX_GAME_CONFIG && NDX_GAME_CONFIG.phase) ph = String(NDX_GAME_CONFIG.phase || '');
    return ndxParseTrainingDayFromPhase(ph);
  }catch(e){
    return 1;
  }
}

/** 일차 베이스: 1일차 0%, 이후 하루마다 +1%p */
function ndxStressDailyBasePct(){
  var d = ndxTrainingDayNumForBars();
  return clampPct((d - 1) * 1);
}

/** 일차 베이스: 1일차 100%, 이후 하루마다 −0.5%p (0.5 단위) */
function ndxTeamDailyBasePct(){
  var d = ndxTrainingDayNumForBars();
  var raw = 100 - (d - 1) * 0.5;
  if (raw < 0) raw = 0;
  if (raw > 100) raw = 100;
  return Math.round(raw * 2) / 2;
}

/** 팀워크 막대: 0.5% 단위 허용 + 채팅·이벤트 보너스 합산 후 */
function clampTeamWorkMeterPct(n){
  var x = Number(n) || 0;
  if (x < 0) x = 0;
  if (x > 100) x = 100;
  return Math.round(x * 2) / 2;
}

/** 욕설·자모/문자 반복 등만 차단. 그 외 문장은 서버로 전송 */
function isGarbageGameChatInput(raw){
  var t=String(raw||'').trim();
  if(!t) return true;
  var noSpace=t.replace(/\s+/g,'');
  if(noSpace.length<2) return false;
  if(/^(.)\1+$/.test(noSpace)) return true;
  if(/^[a-z]{3,}$/i.test(noSpace) && /^(.)\1+$/i.test(noSpace)) return true;
  if(/^[ㄱ-ㅎㅏ-ㅣ]{3,}$/.test(noSpace)) return true;
  if(noSpace.length>=6){
    try{
      if(/^(.{1,2})\1{2,}$/.test(noSpace)) return true;
    }catch(e){}
  }
  var low=t.toLowerCase();
  var ban=[/시발/i,/씨발/i,/ㅅㅂ/i,/병신/i,/지랄/i,/좆/i,/개새/i,/fuck/i,/shit/i,/bitch/i];
  for(var i=0;i<ban.length;i++){
    if(ban[i].test(t)||ban[i].test(low)) return true;
  }
  return false;
}

var selLabel='',selText='',nextPhaseVal='';
window._lastUserChat='';
window._pendingTurnResult=null;
window._pendingTurnHadMiniGame=false;
window._penaltyBid=null;
window._penaltyDelta=null;
window._penaltyStat=null;
var currentPhase=String(NDX_GAME_CONFIG.phase || '');
try{
  if(typeof NDX_GAME_CONFIG !== 'undefined' && NDX_GAME_CONFIG && NDX_GAME_CONFIG.sceneId != null && NDX_GAME_CONFIG.sceneId !== ''){
    window.__ndxLastAppliedSceneIntroKey = 'scene:' + String(NDX_GAME_CONFIG.sceneId);
  }
}catch(eSceneKey){}
function persistResumeState(phase){
  try{
    localStorage.setItem('ndx_save', JSON.stringify({runId:RUN_ID, phase:phase||currentPhase||String(NDX_GAME_CONFIG.phase || ''), at:new Date().toLocaleString('ko-KR')}));
  }catch(e){}
}
persistResumeState(currentPhase);
var _FLASH_KEY='ndx_stat_flash_'+String(RUN_ID||'');

function persistLastStatFlash(data){
  try{
    if(!data) return;
    var tid = data.traineeId;
    var delta = Number(data.delta||0);
    var stat = data.statName;
    if(!tid || !stat || !isFinite(delta) || delta===0) return;
    var entry={ tid: String(tid), delta: delta, stat: String(stat), ts: Date.now() };
    var raw = sessionStorage.getItem(_FLASH_KEY);
    var list=[];
    if(raw){
      try{
        var parsed=JSON.parse(raw);
        list=Array.isArray(parsed)?parsed:(parsed&&parsed.tid?[parsed]:[]);
      }catch(e){}
    }
    list.push(entry);
    sessionStorage.setItem(_FLASH_KEY, JSON.stringify(list));
  }catch(e){}
}

function applyPersistedStatFlash(){
  try{
    var raw = sessionStorage.getItem(_FLASH_KEY);
    if(!raw) return;
    sessionStorage.removeItem(_FLASH_KEY);
    var parsed = JSON.parse(raw||'[]');
    var list = Array.isArray(parsed) ? parsed : (parsed && parsed.tid ? [parsed] : []);
    list.forEach(function(o, idx){
      if(!o || !o.tid || !o.stat) return;
      if(o.ts && (Date.now() - Number(o.ts)) > 5*60*1000) return;
      setTimeout(function(){
        try{ attachStatBadgeOne(String(o.tid), Number(o.delta||0), String(o.stat)); }catch(e){}
      }, 120 + idx*160);
    });
  }catch(e){}
}

var CHEMISTRY_CATALOG=[
  {name:'하모니 라인',bonus:2,desc:'팀 보컬 평균이 높을 때 발동. 상위 보컬 멤버가 핵심입니다.'},
  {name:'퍼포먼스 라인',bonus:2,desc:'팀 댄스 평균이 높을 때 발동. 퍼포먼스 강점 조합입니다.'},
  {name:'안정된 팀워크',bonus:3,desc:'멘탈과 팀워크 평균이 모두 높을 때 발동. 흔들림이 적습니다.'},
  {name:'완벽한 조화',bonus:3,desc:'남녀 2:2 혼성 조합일 때 발동. 혼성 무대 시너지가 큽니다.'},
  {name:'동일 성별 결속',bonus:3,desc:'동일 성별 4인 조합일 때 발동. 팀 호흡이 빨리 맞습니다.'},
  {name:'꿀보이스 조합',bonus:2,desc:'고보컬 멤버가 2명 이상일 때 발동. 파트 분배가 안정됩니다.'},
  {name:'칼군무 라인',bonus:2,desc:'고댄스 멤버가 2명 이상일 때 발동. 퍼포먼스 완성도가 올라갑니다.'},
  {name:'친구 사이',bonus:1,desc:'동갑 멤버가 2명 이상일 때 발동. 멘탈 케어와 친밀도가 높습니다.'},
  {name:'분위기 메이커',bonus:2,desc:'멘탈/팀워크 강점 멤버가 많을 때 발동. 팀 텐션이 안정됩니다.'},
  {name:'무대 장악',bonus:3,desc:'스타성 높은 멤버가 3명 이상일 때 발동. 무대 집중력이 크게 올라갑니다.'},
  {name:'시선 캐치',bonus:1,desc:'스타성 높은 멤버가 2명일 때 발동. 시선 집중도를 보강합니다.'},
  {name:'스타 포지션 밸런스',bonus:2,desc:'보컬/댄스/스타 평균이 고르게 높을 때 발동. 무대 핵심 축이 안정적입니다.'},
  {name:'멘탈 버팀목',bonus:1,desc:'고멘탈 멤버가 3명 이상일 때 발동. 장기전에서 흔들림이 줄어듭니다.'},
  {name:'팀워크 코어',bonus:1,desc:'고팀워크 멤버가 3명 이상일 때 발동. 협업 완성도가 높아집니다.'},
  {name:'에이스 듀오',bonus:3,desc:'총합 높은 멤버가 2명 이상일 때 발동. 팀 중심축이 단단해집니다.'},
  {name:'올라운더 밸런스',bonus:1,desc:'모든 평균 스탯이 일정 기준 이상일 때 발동. 전체 밸런스형 조합입니다.'},
  {name:'등급 보너스 C',bonus:0,desc:'활성 시너지 1개일 때 추가 적용됩니다.'},
  {name:'등급 보너스 B',bonus:1,desc:'활성 시너지 2개일 때 추가 적용됩니다.'},
  {name:'등급 보너스 A',bonus:2,desc:'활성 시너지 3개일 때 추가 적용됩니다.'},
  {name:'등급 보너스 S',bonus:5,desc:'활성 시너지 4개 이상일 때 추가 적용됩니다.'}
];
var currentChemistry = (NDX_GAME_CONFIG.chemistry && typeof NDX_GAME_CONFIG.chemistry === 'object') ? NDX_GAME_CONFIG.chemistry : { chemGrade:'', chemLabel:'', baseBonus:0, gradeBonus:0, totalBonus:0, synergies:[] };

function escHtml(s){
  return String(s == null ? '' : s).replace(/[&<>"']/g,function(ch){
    return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch];
  });
}

function chemistryDescription(chem){
  if(chem && chem.synergies && chem.synergies.length){
    var msg='현재 조합은 '+ (chem.chemLabel || '기본 케미') +' 상태입니다.';
    if((chem.totalBonus||0)>0){
      msg+=' 총 보너스 +'+chem.totalBonus+'%가 적용됩니다.';
      msg+=' (시너지 '+(chem.baseBonus||0)+'% + 등급 '+(chem.gradeBonus||0)+'%)';
    }
    msg+=' 각 시너지 카드 아래에서 실제로 들어간 멤버만 확인할 수 있습니다.';
    return msg;
  }
  return '아직 강하게 발동한 케미는 없지만, 진행 중 스탯 변화에 따라 팀 분위기가 바뀔 수 있습니다.';
}

function chemistryBonusText(chem){
  var total=chem&&chem.totalBonus?chem.totalBonus:0;
  if(total<=0) return '';
  return '+'+total+'% BOOST (시너지 '+(chem.baseBonus||0)+'% + 등급 '+(chem.gradeBonus||0)+'%)';
}

function renderChemistryPanel(chem){
  currentChemistry=chem||{chemGrade:'D',chemLabel:'케미 없음',baseBonus:0,gradeBonus:0,totalBonus:0,synergies:[]};
  var grade=currentChemistry.chemGrade||'D';
  var label=currentChemistry.chemLabel||'케미 없음';
  var fabGrade=document.getElementById('chemFabGrade');
  var fabName=document.getElementById('chemFabName');
  var modalGrade=document.getElementById('chemModalGrade');
  var modalName=document.getElementById('chemModalName');
  var modalBonus=document.getElementById('chemModalBonus');
  var modalDesc=document.getElementById('chemModalDesc');
  var modalGrid=document.getElementById('chemModalGrid');
  if(fabGrade) fabGrade.textContent=grade;
  if(fabName) fabName.textContent=label;
  if(modalGrade) modalGrade.textContent=grade;
  if(modalName) modalName.textContent=label;
  if(modalBonus){
    if((currentChemistry.totalBonus||0)>0){
      modalBonus.style.display='inline-flex';
      modalBonus.innerHTML='<i class="fas fa-bolt"></i> '+chemistryBonusText(currentChemistry);
    }else{
      modalBonus.style.display='none';
    }
  }
  if(modalDesc) modalDesc.textContent=chemistryDescription(currentChemistry);
  if(modalGrid){
    var list=currentChemistry.synergies||[];
    if(list.length){
      modalGrid.innerHTML=list.map(function(item){
        var members=(item.involvedMembers||[]).map(function(name){
          return '<span class="chem-chip__member">'+escHtml(name)+'</span>';
        }).join('');
        return '<div class="chem-chip">'
          + '<div class="chem-chip__icon">'+escHtml(item.icon||'✦')+'</div>'
          + '<div>'
          +   '<div class="chem-chip__title">'+escHtml(item.name||'시너지')+' · +'+(item.bonusPct||0)+'%</div>'
          +   '<div class="chem-chip__desc">'+escHtml(item.description||'')+'</div>'
          +   (members ? '<div class="chem-chip__members">'+members+'</div>' : '')
          + '</div>'
          + '</div>';
      }).join('');
    }else{
      modalGrid.innerHTML='<div class="chem-chip"><div class="chem-chip__icon"><i class="fas fa-chart-line"></i></div><div><div class="chem-chip__title">아직 강한 조합 없음</div><div class="chem-chip__desc">훈련 진행으로 스탯이 바뀌면 케미 등급과 발동 효과가 달라집니다.</div></div></div>';
    }
  }
}

function renderChemCatalog(){
  var list=document.getElementById('chemCatalogList');
  if(!list) return;
  list.innerHTML=CHEMISTRY_CATALOG.map(function(item){
    return '<div class="chem-list-item"><strong>'+escHtml(item.name)+' · +'+(item.bonus||0)+'%</strong><span>'+escHtml(item.desc)+'</span></div>';
  }).join('');
}


function openChemModal(){
  var modal=document.getElementById('chemModal');
  if(modal){
    renderChemistryPanel(currentChemistry);
    modal.classList.add('show');
    document.body.style.overflow='hidden';
    requestAnimationFrame(function(){
      var viewport=modal.querySelector('.chem-modal__viewport');
      var body=modal.querySelector('.chem-modal__body');
      if(viewport) viewport.scrollTop=0;
      if(body) body.scrollTop=0;
    });
  }
}

function closeChemModal(evt){
  if(evt && evt.target && evt.target !== document.getElementById('chemModal')) return;
  var modal=document.getElementById('chemModal');
  if(modal){
    modal.classList.remove('show');
    document.body.style.overflow='';
  }
}

function openChemCatalogModal(){
  renderChemCatalog();
  var modal=document.getElementById('chemCatalogModal');
  if(modal){
    modal.classList.add('show');
    document.body.style.overflow='hidden';
    requestAnimationFrame(function(){
      var viewport=modal.querySelector('.chem-modal__viewport');
      var body=modal.querySelector('.chem-modal__body');
      if(viewport) viewport.scrollTop=0;
      if(body) body.scrollTop=0;
    });
  }
}

function closeChemCatalogModal(evt){
  if(evt && evt.target && evt.target !== document.getElementById('chemCatalogModal')) return;
  var modal=document.getElementById('chemCatalogModal');
  if(modal){
    modal.classList.remove('show');
    document.body.style.overflow='';
  }
}

function openGoalModal(){
  var modal=document.getElementById('goalModal');
  if(modal){
    modal.classList.add('show');
    document.body.style.overflow='hidden';
    requestAnimationFrame(function(){
      var viewport=modal.querySelector('.chem-modal__viewport');
      var body=modal.querySelector('.chem-modal__body');
      if(viewport) viewport.scrollTop=0;
      if(body) body.scrollTop=0;
    });
  }
}

function closeGoalModal(evt){
  if(evt && evt.target && evt.target !== document.getElementById('goalModal')) return;
  var modal=document.getElementById('goalModal');
  if(modal){
    modal.classList.remove('show');
    document.body.style.overflow='';
  }
}


document.addEventListener('keydown',function(evt){
  if(evt.key==='Escape'){
    if(typeof closeNdxCondHelpModal==='function') closeNdxCondHelpModal();
    closeChemModal();
    closeChemCatalogModal();
    closeGoalModal();
    closeFanDetailModal();
  }
});


/* ══════════════════════════════════
   선택지 클릭
══════════════════════════════════ */
renderChemistryPanel(currentChemistry);
renderChemCatalog();

function openFanDetailModal(){
  var modal=document.getElementById('fanDetailModal');
  if(!modal) return;
  modal.classList.add('show');
  try{
    updateFanGeoUi();
    var panD=document.getElementById('fanDetailPanelDomestic');
    var panF=document.getElementById('fanDetailPanelForeign');
    var bd=document.getElementById('fanDetailBtnDomestic');
    var bf=document.getElementById('fanDetailBtnForeign');
    if(panD){ panD.hidden=true; }
    if(panF){ panF.hidden=true; }
    if(bd){ bd.classList.remove('is-active'); bd.setAttribute('aria-expanded','false'); }
    if(bf){ bf.classList.remove('is-active'); bf.setAttribute('aria-expanded','false'); }
  }catch(e){}
}
function closeFanDetailModal(evt){
  var modal=document.getElementById('fanDetailModal');
  if(!modal) return;
  if(evt && evt.target && evt.target !== modal) return;
  modal.classList.remove('show');
}
function syncFanDetail(total, core, casual, light){
  CURRENT_TOTAL_FANS = typeof total === 'number' ? total : CURRENT_TOTAL_FANS;
  CURRENT_CORE_FANS = typeof core === 'number' ? core : CURRENT_CORE_FANS;
  CURRENT_CASUAL_FANS = typeof casual === 'number' ? casual : CURRENT_CASUAL_FANS;
  CURRENT_LIGHT_FANS = typeof light === 'number' ? light : CURRENT_LIGHT_FANS;
  var totalEl=document.getElementById('fanDetailTotal');
  var hudEl=document.getElementById('fansHudValue');
  if(totalEl) totalEl.textContent=CURRENT_TOTAL_FANS;
  if(hudEl) hudEl.textContent=CURRENT_TOTAL_FANS;
  try{ updateFanGeoUi(); }catch(e){}
}

/** 팬 지리 분포: 국내=코어, 해외=캐주얼(구 라이트 합산). 총합 불일치 시 비율 보정 또는 시드 분할 */
function fanGeoSeed(){
  var rid = Number(RUN_ID) || 0;
  var t = Math.floor(Number(CURRENT_TOTAL_FANS) || 0);
  var c = Math.floor(Number(CURRENT_CORE_FANS) || 0);
  var u = Math.floor(Number(CURRENT_CASUAL_FANS) || 0);
  var l = Math.floor(Number(CURRENT_LIGHT_FANS) || 0);
  return (rid * 2654435761 + t * 1597334677 + c * 2246822519 + u * 3266489917 + l * 668265263 + 9741) >>> 0;
}
function mulberry32Fan(a){
  return function(){
    var t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ t >>> 15, t | 1);
    t ^= t + Math.imul(t ^ t >>> 7, t | 61);
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}
function randomWeightsFan(seed, n){
  var rnd = mulberry32Fan(seed >>> 0);
  var w = [];
  var i;
  for(i = 0; i < n; i++) w.push(0.12 + rnd() * 0.88);
  var s = w.reduce(function(x, y){ return x + y; }, 0);
  return w.map(function(x){ return x / s; });
}
function countsFromWeightsFan(total, weights){
  total = Math.max(0, Math.floor(Number(total) || 0));
  if(!weights.length) return [];
  var raw = weights.map(function(w){ return w * total; });
  var flo = raw.map(function(x){ return Math.floor(x); });
  var rem = total - flo.reduce(function(a, b){ return a + b; }, 0);
  var idx = 0;
  while(rem > 0){
    flo[idx % flo.length]++;
    rem--;
    idx++;
  }
  return flo;
}
function getFanGeoBreakdown(){
  var total = Math.max(0, Math.floor(Number(CURRENT_TOTAL_FANS) || 0));
  var domestic = Math.max(0, Math.floor(Number(CURRENT_CORE_FANS) || 0));
  var foreign = Math.max(0, Math.floor(Number(CURRENT_CASUAL_FANS) || 0));
  var sum = domestic + foreign;
  if (total > 0 && sum !== total) {
    if (sum > 0) {
      domestic = Math.round(total * (domestic / sum));
      foreign = Math.max(0, total - domestic);
    } else {
      var seed = fanGeoSeed();
      var rndDom = mulberry32Fan(seed ^ 0x9e3779b9);
      var tilt = total > 0 ? (Number(CURRENT_CORE_FANS) || 0) / total : 0;
      var domRatio = 0.56 + rndDom() * 0.24 + Math.min(0.12, tilt * 0.4);
      if(domRatio > 0.88) domRatio = 0.88;
      if(domRatio < 0.5) domRatio = 0.5;
      domestic = Math.round(total * domRatio);
      foreign = Math.max(0, total - domestic);
    }
  }

  var regions = ['아시아', '유럽', '북미', '남미', '오세아니아', '아프리카', '중동'];
  var rw = randomWeightsFan((seed ^ 0xabcdef01) >>> 0, regions.length);
  var rCounts = countsFromWeightsFan(foreign, rw);
  var regionItems = regions.map(function(name, i){ return { label: name, count: rCounts[i] || 0 }; });

  var cities = ['서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종', '경기', '강원', '충청', '전라', '경상', '제주'];
  var cw = randomWeightsFan((seed ^ 0x13579bdf) >>> 0, cities.length);
  var cCounts = countsFromWeightsFan(domestic, cw);
  var cityItems = cities.map(function(name, i){ return { label: name, count: cCounts[i] || 0 }; });

  return { total: total, domestic: domestic, foreign: foreign, regions: regionItems, cities: cityItems };
}
function formatFanNum(n){
  return (Math.floor(Number(n) || 0)).toLocaleString('ko-KR');
}
function renderFanBarChart(el, items, denom){
  if(!el) return;
  denom = Math.max(1, Math.floor(Number(denom) || 0));
  var html = (items || []).map(function(it){
    var c = Math.max(0, Math.floor(it.count || 0));
    var pct = Math.min(100, Math.round((100 * c) / denom));
    return ''
      + '<div class="fan-bar-row">'
      + '<span class="fan-bar-label">' + escMiniHtml(it.label) + '</span>'
      + '<div class="fan-bar-track"><span class="fan-bar-fill" style="width:' + pct + '%"></span></div>'
      + '<span class="fan-bar-val">' + formatFanNum(c) + '</span>'
      + '</div>';
  }).join('');
  el.innerHTML = html;
}
function updateFanGeoUi(){
  var b = getFanGeoBreakdown();
  var dEl = document.getElementById('fanDetailDomestic');
  var fEl = document.getElementById('fanDetailForeign');
  if(dEl) dEl.textContent = formatFanNum(b.domestic);
  if(fEl) fEl.textContent = formatFanNum(b.foreign);
  var chartD = document.getElementById('fanDetailChartDomestic');
  var chartF = document.getElementById('fanDetailChartForeign');
  var domDenom = b.domestic > 0 ? b.domestic : 1;
  var forDenom = b.foreign > 0 ? b.foreign : 1;
  if(chartD) renderFanBarChart(chartD, b.cities, domDenom);
  if(chartF) renderFanBarChart(chartF, b.regions, forDenom);
}
(function initFanDetailGeoToggles(){
  function closeFanGeoPanels(){
    var panD = document.getElementById('fanDetailPanelDomestic');
    var panF = document.getElementById('fanDetailPanelForeign');
    var bd = document.getElementById('fanDetailBtnDomestic');
    var bf = document.getElementById('fanDetailBtnForeign');
    if(panD) panD.hidden = true;
    if(panF) panF.hidden = true;
    if(bd){ bd.classList.remove('is-active'); bd.setAttribute('aria-expanded', 'false'); }
    if(bf){ bf.classList.remove('is-active'); bf.setAttribute('aria-expanded', 'false'); }
  }
  function wire(){
    var btnD = document.getElementById('fanDetailBtnDomestic');
    var btnF = document.getElementById('fanDetailBtnForeign');
    var panD = document.getElementById('fanDetailPanelDomestic');
    var panF = document.getElementById('fanDetailPanelForeign');
    if(!btnD || !btnF || !panD || !panF) return;
    btnD.addEventListener('click', function(){
      var wasOpen = !panD.hidden;
      closeFanGeoPanels();
      if(!wasOpen){
        panD.hidden = false;
        btnD.classList.add('is-active');
        btnD.setAttribute('aria-expanded', 'true');
      }
    });
    btnF.addEventListener('click', function(){
      var wasOpen = !panF.hidden;
      closeFanGeoPanels();
      if(!wasOpen){
        panF.hidden = false;
        btnF.classList.add('is-active');
        btnF.setAttribute('aria-expanded', 'true');
      }
    });
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', wire);
  else wire();
})();
function animateHudFans(target, delta){
  var el=document.getElementById('fansHudValue');
  var pop=document.getElementById('fansHudDelta');
  if(!el) return;
  var from=parseInt((el.textContent||'0').replace(/[^0-9\-]/g,''))||0;
  var to=typeof target==='number'?target:from+(delta||0);
  animateNumber(el, from, to, 1100);
  if(pop && delta){
    pop.textContent=((delta>0?'✦ +':'✦ ')+delta);
    pop.className='fans-delta-pop show '+(delta>0?'up':'down');
    setTimeout(function(){ pop.className='fans-delta-pop'; }, 1900);
  }
}
function persistFanMotion(delta, total, core, casual, light){
  try{
    sessionStorage.setItem('ndx_fan_motion_'+RUN_ID, JSON.stringify({delta:delta,total:total,core:core,casual:casual,light:light}));
  }catch(e){}
}
function restoreFanMotion(){
  try{
    var raw=sessionStorage.getItem('ndx_fan_motion_'+RUN_ID);
    if(!raw){
      syncFanDetail(CURRENT_TOTAL_FANS,CURRENT_CORE_FANS,CURRENT_CASUAL_FANS,CURRENT_LIGHT_FANS);
      return;
    }
    sessionStorage.removeItem('ndx_fan_motion_'+RUN_ID);
    var data=JSON.parse(raw);
    var start=(typeof data.total==='number' ? data.total : CURRENT_TOTAL_FANS) - (typeof data.delta==='number' ? data.delta : 0);
    var hud=document.getElementById('fansHudValue');
    if(hud) hud.textContent=start;
    syncFanDetail(data.total, data.core, data.casual, data.light);
    animateHudFans(data.total, data.delta || 0);
  }catch(e){
    syncFanDetail(CURRENT_TOTAL_FANS,CURRENT_CORE_FANS,CURRENT_CASUAL_FANS,CURRENT_LIGHT_FANS);
  }
}

restoreFanMotion();

(function initFullscreenSurpriseEvents(){
  var pool=[
    {title:'SNS 라이브 제안',body:'방송국에서 긴급 라이브 슬롯이 떴습니다. 어떻게 대응할까요?',choices:[
      {label:'즉시 수락 — 화제성 우선',fx:'집중↑ · 긴장↑',deltas:{focus:8,stress:4}},
      {label:'팀과 합의 후 진행',fx:'팀워크↑',deltas:{team:9,stress:2}},
      {label:'정중히 거절',fx:'긴장 완화',deltas:{stress:-8}}
    ]},
    {title:'악성 댓글 알림',body:'멤버들이 흔들릴 수 있습니다. 어떤 분위기로 이어갈까요?',choices:[
      {label:'조용히 격려',fx:'팀워크↑ · 스트레스↓',deltas:{team:6,stress:-5}},
      {label:'연습에 몰입',fx:'집중↑',deltas:{focus:7,stress:3}},
      {label:'공식 대응 논의',fx:'팀워크↑',deltas:{team:5,stress:4}}
    ]},
    {title:'기자의 짧은 인터뷰',body:'촬영 요청이 들어왔습니다.',choices:[
      {label:'수락',fx:'집중 · 팀워크',deltas:{focus:5,team:4}},
      {label:'일정만 조율',fx:'안정',deltas:{team:7,stress:-1}},
      {label:'연습 우선',fx:'집중↑',deltas:{focus:9}}
    ]}
  ];
  function isFsBlocked(){
    var rov=document.getElementById('rov');
    if(rov&&rov.classList.contains('show')) return true;
    if(document.querySelector('.chem-modal.show')) return true;
    var fm=document.getElementById('fanDetailModal');
    if(fm&&fm.classList.contains('show')) return true;
    var fs=document.getElementById('gameFullscreenEvent');
    if(fs&&fs.classList.contains('is-open')) return true;
    return false;
  }
  function closeGameFsEvent(){
    var el=document.getElementById('gameFullscreenEvent');
    if(el){
      el.classList.remove('is-open');
      el.setAttribute('aria-hidden','true');
    }
  }
  function openGameFsEvent(ev){
    if(!ev) return;
    var shell=document.getElementById('gameFullscreenEvent');
    var title=document.getElementById('gameFsEventTitle');
    var body=document.getElementById('gameFsEventBody');
    var choices=document.getElementById('gameFsEventChoices');
    var burst=document.getElementById('gameFsEventBurst');
    if(!shell||!choices) return;
    if(burst) burst.textContent='SURPRISE EVENT';
    if(title) title.textContent=ev.title;
    if(body) body.textContent=ev.body;
    choices.innerHTML='';
    ev.choices.forEach(function(ch){
      var b=document.createElement('button');
      b.type='button';
      b.className='game-fs-event__btn';
      b.innerHTML='<span>'+ch.label+'</span><span class="game-fs-event__fx">'+(ch.fx||'')+'</span>';
      b.addEventListener('click', function(){
        try{
          if(ch.deltas && typeof applyLocationStatDeltas==='function') applyLocationStatDeltas(ch.deltas);
          var roster=null;
          try{
            roster=(typeof collectRosterFromDom==='function')?collectRosterFromDom():[];
          }catch(e2){ roster=[]; }
          if((!roster||!roster.length) && typeof __initialRoster!=='undefined') roster=__initialRoster;
          if(roster&&roster.length&&typeof updateConditionBarsFromRoster==='function') updateConditionBarsFromRoster(roster);
          try{ flashLocationStatDeltas(ch.deltas); }catch(e3){}
          if(typeof showToast==='function') showToast('이벤트 선택이 컨디션에 반영되었습니다.','ok');
        }catch(e){}
        closeGameFsEvent();
      });
      choices.appendChild(b);
    });
    shell.classList.add('is-open');
    shell.setAttribute('aria-hidden','false');
  }
  function scheduleFs(){
    var delay=95000+Math.random()*130000;
    setTimeout(function(){
      if(window.__ndxFsEventDone) return;
      if(isFsBlocked()){ scheduleFs(); return; }
      if(Math.random()>0.38){ scheduleFs(); return; }
      var ev=pool[Math.floor(Math.random()*pool.length)];
      openGameFsEvent(ev);
      window.__ndxFsEventDone=true;
    },delay);
  }
  function onReady(){
    var dismiss=document.getElementById('gameFsEventDismiss');
    var shell=document.getElementById('gameFullscreenEvent');
    if(dismiss) dismiss.addEventListener('click', closeGameFsEvent);
    if(shell) shell.addEventListener('click', function(e){ if(e.target===shell) closeGameFsEvent(); });
    document.addEventListener('keydown', function(e){
      if(e.key!=='Escape') return;
      var g=document.getElementById('gameFullscreenEvent');
      if(g&&g.classList.contains('is-open')) closeGameFsEvent();
    });
    scheduleFs();
  }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded', onReady);
  else onReady();
})();

function appendUserChatBubble(text){
  var log=document.getElementById('gameChatLog');
  if(!log)return;
  var wrap=document.createElement('div');
  wrap.className='chat-bubble chat-bubble--user';
  wrap.innerHTML='<div class="chat-bubble-label">PRODUCER</div><div class="chat-bubble-text"></div>';
  var t=wrap.querySelector('.chat-bubble-text');
  wrap.setAttribute('data-raw-text', String(text||''));
  ensureBubbleNeon(wrap, '');
  log.appendChild(wrap);
  startTypewriterForBubble(wrap);
  log.scrollTop=log.scrollHeight;
}

/** 채팅 시뮬 코치/AI 한 줄 요약 (타이핑 없이 즉시 표시) */
function appendCoachSimBubble(text){
  var log=document.getElementById('gameChatLog');
  if(!log) return;
  var wrap=document.createElement('div');
  wrap.className='chat-bubble chat-bubble--npc chat-bubble--system';
  wrap.innerHTML='<div class="chat-bubble-label">코치 분석</div><div class="chat-bubble-text"></div>';
  var te=wrap.querySelector('.chat-bubble-text');
  if(te) te.textContent=String(text||'');
  log.appendChild(wrap);
  log.scrollTop=log.scrollHeight;
}

function signedDelta(n){
  var x=Math.round(Number(n)||0);
  if(!x) return '0';
  return (x>0?'+':'')+x;
}

/** 유효 채팅 턴 직후: 스탯·컨디션 변화 요약 블록 */
function appendCoachEffectsBubble(data, simTurn, condBefore){
  var log=document.getElementById('gameChatLog');
  if(!log) return;
  var lines=[];
  if(simTurn && simTurn.intentLabelKo){
    lines.push('· 채팅 의도: '+simTurn.intentLabelKo+' (아래는 실제 반영된 변화)');
  }
  if(data && data.statName && data.statName!=='-' && data.delta!=null && Number(data.delta)!==0){
    lines.push('· '+data.statName+' '+signedDelta(data.delta));
  }
  if(data && data.miniGamePenalty && data.miniGamePenalty.delta!=null && Number(data.miniGamePenalty.delta)!==0){
    var mp=data.miniGamePenalty;
    lines.push('· '+mp.statName+' (미니게임) '+signedDelta(mp.delta));
  }
  if(simTurn){
    if(simTurn.deltaTeamwork) lines.push('· 팀워크(피드백) '+signedDelta(simTurn.deltaTeamwork));
    if(simTurn.deltaStress) lines.push('· 스트레스(피드백) '+signedDelta(simTurn.deltaStress));
    if(simTurn.deltaCondition) lines.push('· 컨디션(피드백) '+signedDelta(simTurn.deltaCondition));
    if(simTurn.deltaFocus) lines.push('· 집중도(피드백) '+signedDelta(simTurn.deltaFocus));
  }
  if(condBefore && data && data.updatedRoster && typeof computeConditionPcts==='function'){
    try{
      var cAfter=computeConditionPcts(data.updatedRoster);
      var df=cAfter.focus-condBefore.focus;
      var dtm=cAfter.team-condBefore.team;
      var ds=cAfter.stress-condBefore.stress;
      var dc=cAfter.condition-condBefore.condition;
      if(df) lines.push('· 집중도(로스터) '+signedDelta(df));
      if(dtm) lines.push('· 팀워크(로스터) '+signedDelta(dtm));
      if(ds) lines.push('· 스트레스(로스터) '+signedDelta(ds));
      if(dc) lines.push('· 컨디션(로스터) '+signedDelta(dc));
    }catch(e){}
  }
  if(!lines.length) return;
  var wrap=document.createElement('div');
  wrap.className='chat-bubble chat-bubble--npc chat-bubble--system chat-bubble--effects';
  wrap.innerHTML='<div class="chat-bubble-label">효과</div><div class="chat-bubble-text chat-bubble-text--effects"></div>';
  var te=wrap.querySelector('.chat-bubble-text');
  if(te) te.textContent=lines.join('\n');
  log.appendChild(wrap);
  log.scrollTop=log.scrollHeight;
}

var GAME_CHAT_COOLDOWN_MS=1650;
function gameChatCooldownRemaining(){
  var u=Number(window.__gameChatCooldownUntil)||0;
  return Math.max(0,u-Date.now());
}
function gameChatCooldownActive(){
  return gameChatCooldownRemaining()>0;
}

function revertGameChatMiniTurnCounter(){
  try{
    var key='ndx_mini_turn_counter_'+String(RUN_ID||'');
    var n=parseInt(sessionStorage.getItem(key)||'0',10)||0;
    if(n>0) sessionStorage.setItem(key,String(n-1));
  }catch(e){}
}

/** @param {{ lines?:string[], intentLabel?:string }} result */
function showChatFeedbackLog(result){
  try{
    if(!result || !result.lines || !result.lines.length) return;
  }catch(e0){ return; }
  try{
    if(window.IdolSimStatusPresentation && typeof window.IdolSimStatusPresentation.showChatFeedbackLog === 'function'){
      window.IdolSimStatusPresentation.showChatFeedbackLog(result);
    }
  }catch(e){}
}

function generateSituationHint(state){
  try{
    if(window.NdxConditionLogic && typeof window.NdxConditionLogic.generateSituationHint === 'function'){
      return window.NdxConditionLogic.generateSituationHint(state || {});
    }
  }catch(e){}
  return { hintLine:'', coachLine:'' };
}

/**
 * 서버 채팅 응답 반영 직후: 의도·톤·이벤트로 팀워크/스트레스/컨디션 바 보정 + 피드백 로그
 * @returns {object|null} 시뮬 턴 결과(없으면 null)
 */
function applyChatSimulationAfterServerResponse(data, userText){
  if(!userText || !window.NdxChatSimulation) return null;
  var cond = typeof getConditionForGoals === 'function' ? getConditionForGoals() : null;
  if(!cond) return null;
  var condBeforeSnap = window.__conditionPctBeforeChat || null;
  var ev = '';
  try{
    if(data && data.eventType) ev = String(data.eventType);
    else if(data && data.sceneEventType) ev = String(data.sceneEventType);
    else if(data && data.trainingCategory) ev = String(data.trainingCategory);
    ev = window.NdxChatSimulation.mapServerEventToPenaltyType(ev) || ev;
  }catch(e){ ev = ''; }
  var turn = window.NdxChatSimulation.runChatSimulationTurn(
    {
      teamwork: cond.team,
      stress: cond.stress,
      condition: cond.condition,
      focus: cond.focus
    },
    userText,
    ev || window.NdxChatSimulation.EventPenaltyType.NONE
  );
  var simScale = 1;
  try{
    if(data && (data.resolvedKey === 'NONE' || data.chatNoEffect === true)){
      simScale = 0.38;
    }else if(data && data.usedFallback === true && data.resolverType === 'RULE'){
      simScale = 0.78;
    }
  }catch(eSc){ simScale = 1; }
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  window.__mapEventBarBonus.team = (Number(window.__mapEventBarBonus.team) || 0) + (Number(turn.deltaTeamwork) || 0) * simScale;
  window.__mapEventBarBonus.stress = (Number(window.__mapEventBarBonus.stress) || 0) + (Number(turn.deltaStress) || 0) * simScale;
  window.__mapEventBarBonus.condition = (Number(window.__mapEventBarBonus.condition) || 0) + (Number(turn.deltaCondition) || 0) * simScale;
  window.__mapEventBarBonus.focus = (Number(window.__mapEventBarBonus.focus) || 0) + (Number(turn.deltaFocus) || 0) * simScale;
  try{
    if(turn.feedbackLines && turn.feedbackLines.length){
      showChatFeedbackLog({ lines: turn.feedbackLines });
    }
  }catch(eL){}
  try{
    var roster = typeof collectRosterFromDom === 'function' ? collectRosterFromDom() : [];
    if(roster && roster.length) updateConditionBarsFromRoster(roster);
  }catch(e2){}
  var narr = (turn && turn.aiLine) ? turn.aiLine : (data && data.resultNarration ? String(data.resultNarration) : '');
  try{
    if(narr) appendCoachSimBubble(narr);
  }catch(e3){}
  try{ appendCoachEffectsBubble(data, turn, condBeforeSnap); }catch(e35){}
  try{
    if(turn.gameState === 'STRESS_EXPLOSION'){
      triggerStressGameOver();
    }
  }catch(e4){}
  return turn;
}

/* ══════════════════════════════════
   채팅 전송 → 미니게임(5종 랜덤, 3턴마다 1회) → 키워드 해석 API
   실패 시 miniGameFailed: true → 서버에서 1~4번 멤버 스탯 -1~-3 추가
══════════════════════════════════ */
window.__miniGameCleanup=null;

function closeMiniGameOverlay(){
  var ov=document.getElementById('miniGameOverlay');
  if(ov){ov.classList.remove('show');ov.setAttribute('aria-hidden','true');}
  document.body.style.overflow='';
  if(typeof window.__miniGameCleanup==='function'){
    try{ window.__miniGameCleanup(); }catch(e){}
    window.__miniGameCleanup=null;
  }
}

/**
 * @param {function(boolean)} onDone true=성공, false=실패(페널티)
 */
function runChatMiniGame(onDone){
  var kinds=['idol_quiz'];
  var kind=kinds[Math.floor(Math.random()*kinds.length)];
  var ov=document.getElementById('miniGameOverlay');
  var stage=document.getElementById('miniGameStage');
  var introShell=document.getElementById('miniGameIntroShell');
  var playShell=document.getElementById('miniGamePlayShell');
  var hudL=document.getElementById('miniGameHudLeft');
  var timerEl=document.getElementById('miniGameTimer');
  var resMsg=document.getElementById('miniGameResultMsg');
  var actions=document.getElementById('miniGameActions');
  if(!ov||!stage||!onDone){ if(onDone) onDone(true); return; }

  closeMiniGameOverlay();
  if(resMsg) resMsg.style.display='none';
  if(actions) actions.style.display='none';
  stage.innerHTML='';
  document.body.style.overflow='hidden';
  ov.classList.add('show');
  ov.setAttribute('aria-hidden','false');
  if(introShell) introShell.style.display='flex';
  if(playShell) playShell.style.display='none';

  var timers=[];
  var intervals=[];
  var cleaners=[];
  var rafId=0;
  var finished=false;
  function done(passed){
    if(finished) return;
    finished=true;
    closeMiniGameOverlay();
    onDone(!!passed);
  }
  function addTimer(fn,t){ var id=setTimeout(fn,t); timers.push(id); return id; }
  window.__miniGameCleanup=function(){
    timers.forEach(function(id){ clearTimeout(id); });
    intervals.forEach(function(id){ clearInterval(id); });
    cleaners.forEach(function(fn){ try{ fn(); }catch(e){} });
    if(rafId) cancelAnimationFrame(rafId);
    timers=[]; intervals=[]; cleaners=[]; rafId=0;
  };

  var meta={
    idol_quiz:{t:'아이돌 이름 맞추기',d:'힌트를 보고 그룹 이름을 타자로 입력하세요',icon:'fa-keyboard'}
  }[kind]||{t:'미니게임',d:'',icon:'fa-gamepad'};

  var introTxt=document.getElementById('miniGameIntroTitleText');
  var introDesc=document.getElementById('miniGameIntroDesc');
  var introIcon=document.querySelector('#miniGameIntroTitle i');
  if(introTxt) introTxt.textContent=meta.t;
  if(introDesc) introDesc.textContent=meta.d;
  if(introIcon) introIcon.className='fas '+meta.icon;

  function setHud(left,timer){
    if(hudL) hudL.textContent=left||'';
    if(timerEl) timerEl.textContent=timer||'';
  }

  function beginMiniGamePlay(){
    if(introShell) introShell.style.display='none';
    if(playShell) playShell.style.display='flex';
    var pt=document.getElementById('miniGamePlayTitle');
    var pd=document.getElementById('miniGamePlayDesc');
    if(pt) pt.innerHTML='<i class="fas '+meta.icon+'"></i><span>'+meta.t+'</span>';
    if(pd) pd.textContent=meta.d;
    stage.innerHTML='';

  /* ── 1. 아이돌 이름 맞추기 ── */
  if(kind==='idol_quiz'){
    var defaultQuizPool=[
      // SM
      {hint:'SM 소속 · 4인조 걸그룹 · "Black Mamba" 데뷔',answer:'에스파'},
      {hint:'SM 소속 · 5인조 보이그룹 · "누난 너무 예뻐"',answer:'샤이니'},
      {hint:'SM 소속 · 9인조 걸그룹 · "Gee"',answer:'소녀시대'},
      {hint:'SM 소속 · 13인조 보이그룹 · "Sorry Sorry"',answer:'슈퍼주니어'},
      {hint:'SM 소속 · 9인조 보이그룹 · "으르렁"',answer:'엑소'},
      {hint:'SM 소속 · 5인조 걸그룹 · "빨간 맛"',answer:'레드벨벳'},
      {hint:'SM 소속 · NCT 유닛 · "일곱 번째 감각"',answer:'엔시티유'},
      {hint:'SM 소속 · NCT 유닛 · "영웅"',answer:'엔시티127'},
      {hint:'SM 소속 · NCT 유닛 · "맛"',answer:'엔시티드림'},
      {hint:'SM 소속 · 2023 데뷔 보이그룹 · "Get A Guitar"',answer:'라이즈'},

      // JYP
      {hint:'JYP 소속 · 8인조 보이그룹 · "God\'s Menu"',answer:'스트레이키즈'},
      {hint:'JYP 소속 · 9인조 걸그룹 · "CHEER UP"',answer:'트와이스'},
      {hint:'JYP 소속 · 5인조 걸그룹 · "달라달라"',answer:'있지'},
      {hint:'JYP 소속 · 6인조 보이그룹 · "Congratulations"',answer:'데이식스'},
      {hint:'JYP 소속 · 6인조 걸그룹 · "O.O"',answer:'엔믹스'},
      {hint:'JYP 소속 · 7인조 보이그룹 · "딱 좋아"',answer:'갓세븐'},
      {hint:'JYP 소속 · 2인조 남성 듀오 · "이 노래를 듣고 돌아와"',answer:'투에이엠'},
      {hint:'JYP 소속 · 밴드 · "Happy Death Day"',answer:'엑스디너리히어로즈'},

      // YG
      {hint:'YG 소속 · 4인조 걸그룹 · "DDU-DU DDU-DU"',answer:'블랙핑크'},
      {hint:'YG 소속 · 4인조 보이그룹 · "거짓말"',answer:'빅뱅'},
      {hint:'YG 소속 · 6인조 보이그룹 · "사랑을 했다"',answer:'아이콘'},
      {hint:'YG 소속 · 4인조 위너 · "REALLY REALLY"',answer:'위너'},
      {hint:'YG 소속 · 7인조 보이그룹 · "JIKJIN"',answer:'트레저'},
      {hint:'YG 소속 · 4인조 걸그룹 · "BATTER UP"',answer:'베이비몬스터'},
      {hint:'YG 소속 · 프로젝트 혼성그룹 · "Fire"',answer:'원타임'},

      // HYBE / 산하
      {hint:'HYBE 산하 · 5인조 걸그룹 · "Fearless"',answer:'르세라핌'},
      {hint:'HYBE 산하 · 7인조 보이그룹 · "Dynamite"',answer:'방탄소년단'},
      {hint:'HYBE 산하 · 13인조 보이그룹 · "아주 NICE"',answer:'세븐틴'},
      {hint:'HYBE 산하 · 5인조 보이그룹 · "어느날 머리에서 뿔이 자랐다"',answer:'투모로우바이투게더'},
      {hint:'HYBE 산하 · 7인조 걸그룹 · "SUPER SHY"',answer:'뉴진스'},
      {hint:'HYBE 산하 · 6인조 보이그룹 · "Given-Taken"',answer:'엔하이픈'},
      {hint:'HYBE 산하 · 6인조 보이그룹 · "Magnetic"',answer:'아일릿'},
      {hint:'HYBE 산하 · 글로벌 걸그룹 · "Debut"',answer:'캣츠아이'},
      {hint:'HYBE 산하 · 6인조 보이그룹 · "plot twist"',answer:'투어스'},

      // STARSHIP
      {hint:'스타쉽 소속 · 6인조 걸그룹 · "LOVE DIVE"',answer:'아이브'},
      {hint:'스타쉽 소속 · 6인조 보이그룹 · "DRAMARAMA"',answer:'몬스타엑스'},
      {hint:'스타쉽 소속 · 5인조 보이그룹 · "그리움이 쌓이면"',answer:'크래비티'},
      {hint:'스타쉽 소속 · 프로젝트 그룹 · "PICK ME"',answer:'아이오아이'},
      {hint:'스타쉽 소속 · 4인조 걸그룹 · "Touch"',answer:'키키'},

      // CUBE / RBW / FNC / IST / WM / KQ
      {hint:'큐브 소속 · 5인조 걸그룹 · "TOMBOY"',answer:'여자아이들'},
      {hint:'큐브 소속 · 6인조 보이그룹 · "빛나리"',answer:'펜타곤'},
      {hint:'큐브 소속 · 4인조 보이그룹 · "Movie Star"',answer:'씨아이엑스'},
      {hint:'RBW 소속 · 4인조 걸그룹 · "HIP"',answer:'마마무'},
      {hint:'RBW 소속 · 6인조 보이그룹 · "LUNA"',answer:'원어스'},
      {hint:'FNC 소속 · 밴드 · "I\'m Sorry"',answer:'씨엔블루'},
      {hint:'FNC 소속 · 8인조 보이그룹 · "Good Guy"',answer:'SF9'},
      {hint:'IST 소속 · 11인조 보이그룹 · "THRILL RIDE"',answer:'더보이즈'},
      {hint:'WM 소속 · 6인조 걸그룹 · "살짝 설렜어"',answer:'오마이걸'},
      {hint:'KQ 소속 · 8인조 보이그룹 · "BOUNCY"',answer:'에이티즈'}
    ];
    var configuredQuizPool = [];
    try{
      var cfgPool = window.NDX_GAME_CONFIG && window.NDX_GAME_CONFIG.miniGameQuizPool;
      if(Array.isArray(cfgPool)){
        configuredQuizPool = cfgPool
          .map(function(item){
            return {
              hint: String(item && item.hint || '').trim(),
              answer: String(item && item.answer || '').trim()
            };
          })
          .filter(function(item){ return item.hint && item.answer; });
      }
    }catch(e){}
    var quizPool = configuredQuizPool.length ? configuredQuizPool : defaultQuizPool;
    var q=quizPool[Math.floor(Math.random()*quizPool.length)];
    var deadlineQ=Date.now()+12000;
    stage.style.display='flex';
    stage.style.alignItems='center';
    stage.style.justifyContent='center';
    stage.style.minHeight='340px';

    var card=document.createElement('div');
    card.style.width='min(92%, 700px)';
    card.style.margin='0 auto';
    card.style.padding='26px 24px 22px';
    card.style.borderRadius='20px';
    card.style.border='1px solid rgba(167,139,250,.45)';
    card.style.background='linear-gradient(160deg, rgba(30,41,59,.45), rgba(15,23,42,.62))';
    card.style.boxShadow='0 22px 44px rgba(15,23,42,.35), 0 0 24px rgba(167,139,250,.18)';
    card.style.backdropFilter='blur(4px)';
    card.style.textAlign='center';

    var hint=document.createElement('div');
    hint.className='mini-timing-hint mini-idol-quiz-hint';
    hint.textContent='힌트: '+q.hint;
    hint.style.fontSize='22px';
    hint.style.lineHeight='1.6';
    hint.style.fontWeight='900';
    hint.style.color='#f8fafc';
    hint.style.letterSpacing='.01em';
    hint.style.textShadow='0 0 12px rgba(167,139,250,.38)';
    hint.style.margin='0 0 16px';

    var inp=document.createElement('input');
    inp.type='text';
    inp.placeholder='그룹 이름 입력';
    inp.style.width='100%';
    inp.style.maxWidth='480px';
    inp.style.padding='16px 18px';
    inp.style.fontSize='20px';
    inp.style.fontWeight='800';
    inp.style.textAlign='center';
    inp.style.borderRadius='14px';
    inp.style.border='2px solid rgba(167,139,250,.6)';
    inp.style.background='rgba(255,255,255,.96)';
    inp.style.boxShadow='0 8px 20px rgba(15,23,42,.22)';
    inp.style.margin='0 auto 14px';
    inp.style.display='block';

    var btn=document.createElement('button');
    btn.type='button';
    btn.className='mini-game-btn';
    btn.textContent='정답 제출';
    btn.style.margin='0 auto';
    btn.style.display='block';
    btn.style.minWidth='170px';
    btn.style.padding='12px 22px';
    btn.style.fontSize='15px';
    btn.style.fontWeight='900';

    card.appendChild(hint);
    card.appendChild(inp);
    card.appendChild(btn);
    stage.appendChild(card);
    function norm(s){ return String(s||'').toLowerCase().replace(/\s+/g,''); }
    var revealPending=false;
    function submit(){
      if(finished||revealPending)return;
      var ok=norm(inp.value)===norm(q.answer);
      revealPending=true;
      inp.disabled=true;
      btn.disabled=true;
      if(ok){
        hint.textContent='맞습니다! 정답은 "'+q.answer+'" 입니다.';
        addTimer(function(){ done(true); },380);
      }else{
        hint.textContent='오답! 정답 그룹은 "'+q.answer+'" 입니다.';
        addTimer(function(){ done(false); },720);
      }
    }
    btn.addEventListener('click', submit);
    inp.addEventListener('keydown', function(e){ if(e.key==='Enter'){ e.preventDefault(); submit(); } });
    addTimer(function(){ try{ inp.focus(); }catch(e){} },120);
    (function tick(){
      if(finished)return;
      var left=Math.max(0,Math.ceil((deadlineQ-Date.now())/1000));
      setHud('아이돌 퀴즈', left+'초');
      if(left<=0){ hint.textContent='시간 종료! 정답은 "'+q.answer+'"'; done(false); }
      else addTimer(tick,250);
    })();
    return;
  }

  done(true);
  }

  var btnStart=document.getElementById('miniGameBtnStart');
  if(btnStart){
    var _hStart=function(){
      btnStart.removeEventListener('click',_hStart);
      beginMiniGamePlay();
    };
    btnStart.addEventListener('click',_hStart);
  }else{
    beginMiniGamePlay();
  }
}

function sendGameChat(){
  var inp=document.getElementById('gameChatInput');
  var btn=document.getElementById('gameChatSend');
  if(!inp||!btn||inp.disabled)return;
  var text=(inp.value||'').trim();
  if(!text)return;

  if(gameChatCooldownActive()){
    try{
      if(typeof showToast === 'function'){
        showToast('잠시 후 다시 입력해 주세요. ('+Math.ceil(gameChatCooldownRemaining()/100)/10+'초)', 'warn', 1800);
      }
    }catch(e){}
    return;
  }

  if(isGarbageGameChatInput(text)){
    try{
      if(typeof showToast === 'function'){
        showToast('욕설이나 ㅇㅇㅇ·sss 같은 무의미 입력은 보낼 수 없습니다.', 'warn', 4000);
      }else{
        appendCoachSimBubble('무의미한 입력입니다. 지시를 분명히 적어 주세요.');
      }
    }catch(e2){}
    return;
  }

  // 미니게임은 3턴에 1번만 실행 (빈도 완화)
  function shouldRunMiniGameThisTurn(){
    var key='ndx_mini_turn_counter_'+String(RUN_ID||'');
    var n=0;
    try{
      n=parseInt(sessionStorage.getItem(key)||'0',10)||0;
      n+=1;
      sessionStorage.setItem(key,String(n));
    }catch(e){
      n=1;
    }
    return (n%3===0);
  }
  var runMini=shouldRunMiniGameThisTurn();
  window._pendingTurnHadMiniGame=runMini;

  window._lastUserChat=text;
  selText=text;
  inp.value='';
  var prevHtml=btn.innerHTML;
  btn.disabled=true;
  inp.disabled=true;

  function requestApply(passed){
    appendUserChatBubble(window._lastUserChat);
    try{
      var rb=typeof collectRosterFromDom === 'function' ? collectRosterFromDom() : [];
      if(typeof filterRosterExcludingEliminated === 'function') rb = filterRosterExcludingEliminated(rb);
      if(typeof computeConditionPcts === 'function'){
        window.__conditionPctBeforeChat = computeConditionPcts(rb && rb.length ? rb : []);
      }else window.__conditionPctBeforeChat=null;
    }catch(eSnap){
      window.__conditionPctBeforeChat=null;
    }
    btn.innerHTML='처리 중… <i class="fas fa-spinner fa-spin"></i>';
    var ac=new AbortController();
    var chatFetchTimer=setTimeout(function(){ try{ ac.abort(); }catch(e){} }, 90000);
    fetch(CTX+'/game/run/'+RUN_ID+'/choice/chat',{
      method:'POST',
      headers:{'Content-Type':'application/json;charset=UTF-8'},
      signal:ac.signal,
      body:JSON.stringify({
        text:window._lastUserChat,
        miniGameFailed:(runMini?!passed:false),
        eliminatedTids:(typeof loadEliminatedTraineeIds==='function' ? loadEliminatedTraineeIds().join(',') : ''),
        statGrowth2x:(typeof isStatGrowth2xEnabled==='function' ? isStatGrowth2xEnabled() : false)
      })
    })
    .then(function(res){
      return res.json().then(function(data){
        if(data && data.redirect){
          window.location.href = CTX + data.redirect;
          return Promise.reject(new Error('login'));
        }
        if(!res.ok){
          var msg=(data && (data.error||data.message)) ? String(data.error||data.message) : ('HTTP '+res.status);
          throw new Error(msg);
        }
        return data;
      });
    })
    .then(function(data){applyAfterChatResponse(data);})
    .catch(function(err){
      window._pendingTurnHadMiniGame=false;
      var msg=err && err.name==='AbortError' ? '응답 시간이 초과되었습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.' : (err && err.message ? err.message : String(err));
      alert('오류: '+msg);
    })
    .finally(function(){
      try{ clearTimeout(chatFetchTimer); }catch(e){}
      btn.disabled=false;
      inp.disabled=false;
      btn.innerHTML=prevHtml;
    });
  }

  if(runMini) runChatMiniGame(function(passed){ requestApply(passed); });
  else requestApply(true);
}

(function bindGameChatEnter(){
  function init(){
    var inp=document.getElementById('gameChatInput');
    if(!inp||inp.dataset.enterBound)return;
    inp.dataset.enterBound='1';
    inp.addEventListener('keydown',function(e){
      if(e.key==='Enter'&&!e.shiftKey){
        e.preventDefault();
        sendGameChat();
      }
    });
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);
  else init();
})();

/* ────────────────────────────────
   iPad side panel interactions
   (UI 전용: 로직은 data-*로만 연결)
──────────────────────────────── */
(function initIpadSidePanel(){
  function init(){
    var root=document.getElementById('ipadSidePanel');
    if(!root) return;

    function insertToInput(text, opts){
      opts = opts || {};
      var inp=document.getElementById('gameChatInput'); // TODO: 입력창 id가 바뀌면 여기만 수정
      if(!inp) return false;
      if(inp.disabled) return false;
      var t=String(text||'').trim();
      if(!t) return false;
      inp.value = (inp.value ? (inp.value + ' ') : '') + t;
      try{ inp.dispatchEvent(new Event('input', {bubbles:true})); }catch(e){}
      if(opts.focus !== false) inp.focus();
      return true;
    }

    function maybeAutoSend(){
      // 전송 버튼이 막혀있거나(요청 중) 입력이 비활성화면 자동 전송하지 않음
      var btn=document.getElementById('gameChatSend');
      var inp=document.getElementById('gameChatInput');
      if(!btn || !inp) return false;
      if(btn.disabled || inp.disabled) return false;
      if(typeof window.sendGameChat === 'function'){
        window.sendGameChat();
        return true;
      }
      return false;
    }

    // quick commands: input에 자동 삽입
    root.querySelectorAll('.quick-chip[data-command]').forEach(function(chip){
      chip.addEventListener('click', function(){
        var cmd=chip.getAttribute('data-command') || '';
        insertToInput(cmd, {focus:true});
        try{ console.log('[COMMAND]', cmd); }catch(e){}
      });
    });

    // dummy progress: data-pct 기반 (필요 시 서버 값으로 교체 가능)
    root.querySelectorAll('.status-bar[data-pct]').forEach(function(bar){
      var pct=parseInt(bar.getAttribute('data-pct'),10);
      if(!isFinite(pct)) pct=0;
      if(pct<0) pct=0; if(pct>100) pct=100;
      var fill=bar.querySelector('.status-fill');
      var val=bar.querySelector('.status-bar__val');
      if(fill) fill.style.width=pct+'%';
      if(val) val.textContent=pct+'%';
    });
  }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();

// 초기 로딩 시에도 컨디션 바를 로스터 기준으로 맞춘다
try{
  if(typeof window.__initialRoster !== 'undefined' && window.__initialRoster && window.__initialRoster.length){
    updateConditionBarsFromRoster(window.__initialRoster);
  }
}catch(e){}

function escapeChatHtml(s){
  return String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// 휴대폰 스타일 시간 표시(우측 상단): 현재 시간 HH:MM
(function initPhoneTime(){
  function pad2(n){ n = String(n||0); return n.length<2 ? ('0'+n) : n; }
  function tick(){
    try{
      var el=document.getElementById('phoneTime');
      if(!el) return;
      var d=new Date();
      var hh=pad2(d.getHours());
      var mm=pad2(d.getMinutes());
      el.textContent = hh+':'+mm;
    }catch(e){}
  }
  tick();
  // 분 경계에 가깝게 맞추려고 1초마다 체크(비용 매우 적음)
  setInterval(tick, 1000);
})();

(function initGameUiModeSystem(){
  /** @type {{ mode: 'app'|'home'|'map', selectedLocation: string|null }} 게임 UI 전용(채팅·인벤 등 DOM 상태는 유지, 페이지 이동 없음) */
  window.gameUi = window.gameUi || { mode: 'app', selectedLocation: null };
  if (typeof window.gameUi.selectedLocation === 'undefined') window.gameUi.selectedLocation = null;

  var root = document.getElementById('gameUiRoot');
  var surfApp = document.getElementById('gameUiSurfaceApp');
  var surfHome = document.getElementById('gameUiSurfaceHome');
  var surfMap = document.getElementById('gameUiSurfaceMap');
  var appBtn = document.getElementById('ipadGameAppBtn');
  var mapBtn = document.getElementById('ipadMapAppBtn');
  var tm = document.getElementById('ipadHomeTime');

  function pad2(n){ return n<10?('0'+n):String(n); }
  function refreshHomeTime(){
    var d=new Date();
    var h=d.getHours(), m=d.getMinutes();
    var ap=h<12?'AM':'PM';
    var h12=h%12; if(h12===0) h12=12;
    if(tm) tm.textContent=ap+' '+h12+':'+pad2(m);
  }

  function applyAria(mode){
    if(surfApp) surfApp.setAttribute('aria-hidden', mode==='app' ? 'false' : 'true');
    if(surfHome) surfHome.setAttribute('aria-hidden', mode==='home' ? 'false' : 'true');
    if(surfMap) surfMap.setAttribute('aria-hidden', mode==='map' ? 'false' : 'true');
  }

  window.setGameUiMode = function(next){
    var ok = { app:1, home:1, map:1 };
    if(!ok[next]) return;
    var prev = window.gameUi.mode;
    if(root && prev === 'map' && next === 'app'){
      window.gameUi.mode = next;
      root.setAttribute('data-ui-mode', next);
      applyAria(next);
      root.classList.add('ui-transition-map-app');
      window.setTimeout(function(){
        try{ root.classList.remove('ui-transition-map-app'); }catch(e){}
      }, 560);
      return;
    }
    window.gameUi.mode = next;
    if(root) root.setAttribute('data-ui-mode', next);
    applyAria(next);
  };

  window.openIpadHome = function(){ window.setGameUiMode('home'); };

  if(root) root.setAttribute('data-ui-mode', window.gameUi.mode || 'app');
  applyAria(window.gameUi.mode || 'app');

  refreshHomeTime();
  setInterval(refreshHomeTime, 15000);

  if(appBtn) appBtn.addEventListener('click', function(){ window.setGameUiMode('app'); });
  if(mapBtn) mapBtn.addEventListener('click', function(){ window.setGameUiMode('map'); });

  document.addEventListener('keydown', function(ev){
    if(ev.key !== 'Escape') return;
    if(!window.gameUi || (window.gameUi.mode !== 'home' && window.gameUi.mode !== 'map')) return;
    var t = ev.target;
    if(t && t.closest && (t.closest('.chem-modal.show') || t.closest('.gs-schedule-modal.is-open'))) return;
    window.setGameUiMode('app');
  });
})();

(function initGameMapScreen(){
  var hint = document.getElementById('gameMapSelectionHint');
  var nodes = document.querySelectorAll('.game-map-node[data-location]');
  if(!nodes.length) return;

  nodes.forEach(function(btn){
    btn.addEventListener('click', function(){
      var loc = btn.getAttribute('data-location');
      var label = btn.getAttribute('data-location-label') || loc;
      if(!window.gameUi) window.gameUi = { mode: 'app', selectedLocation: null };
      window.gameUi.selectedLocation = loc;

      nodes.forEach(function(n){
        n.classList.toggle('is-selected', n === btn);
        n.setAttribute('aria-pressed', n === btn ? 'true' : 'false');
      });

      if(hint) hint.textContent = '선택: ' + label;

      var detail = { location: loc, label: label };
      try{
        document.dispatchEvent(new CustomEvent('gameMap:locationSelect', { bubbles: true, detail: detail }));
      }catch(e){}
      var root = document.getElementById('gameUiRoot');
      if(root){
        try{
          root.dispatchEvent(new CustomEvent('gameMap:locationSelect', { bubbles: true, detail: detail }));
        }catch(e){}
      }
      if(typeof handleLocationEvent === 'function') handleLocationEvent(loc);
    });
  });
})();

// 상단 날짜·요일·시각은 서버(GameController: TRAINING_CALENDAR_START + dayNum, randomScheduleTimeLabel)에서만 표시

// 채팅 패널 배경 이미지 선택(로컬 저장)
(function initChatPanelBgPicker(){
  var LS_KEY='ndx_chat_panel_bg';
  var panel=document.getElementById('gameChatPanel');
  var log=document.getElementById('gameChatLog');
  if(!panel) return;

  function apply(url){
    if(url){
      panel.style.setProperty('--chat-bg-url', 'url(\"' + String(url).replace(/\"/g,'') + '\")');
      if(log){
        log.style.backgroundImage = 'linear-gradient(0deg, rgba(224,187,228,.18), rgba(224,187,228,.18)), url(\"' + String(url).replace(/\"/g,'') + '\")';
        log.style.backgroundSize = 'cover';
        log.style.backgroundPosition = 'center';
        log.style.backgroundRepeat = 'no-repeat';
      }
    }else{
      panel.style.setProperty('--chat-bg-url', 'none');
      if(log){
        log.style.backgroundImage = '';
        log.style.backgroundSize = '';
        log.style.backgroundPosition = '';
        log.style.backgroundRepeat = '';
      }
    }
  }

  // restore
  try{
    var saved=localStorage.getItem(LS_KEY);
    if(saved) apply(saved);
  }catch(e){}

  function openPicker(){
    var inp=document.getElementById('chatBgFileInput');
    if(inp) inp.click();
  }

  function onPick(){
    var inp=document.getElementById('chatBgFileInput');
    if(!inp || !inp.files || !inp.files[0]) return;
    var f=inp.files[0];
    if(!/^image\//.test(f.type||'')) { inp.value=''; return; }
    var r=new FileReader();
    r.onload=function(){
      var rawUrl=String(r.result||'');
      if(!rawUrl){ inp.value=''; return; }

      // 용량 큰 이미지도 새로고침 후 유지되도록 브라우저 저장용으로 리사이즈/압축
      var img=new Image();
      img.onload=function(){
        try{
          var maxW=1280, maxH=900;
          var w=img.naturalWidth||img.width, h=img.naturalHeight||img.height;
          var ratio=Math.min(maxW/w, maxH/h, 1);
          var tw=Math.max(1, Math.round(w*ratio));
          var th=Math.max(1, Math.round(h*ratio));
          var canvas=document.createElement('canvas');
          canvas.width=tw; canvas.height=th;
          var ctx=canvas.getContext('2d');
          ctx.drawImage(img,0,0,tw,th);
          var storedUrl=canvas.toDataURL('image/jpeg',0.82);

          try{
            localStorage.setItem(LS_KEY, storedUrl);
            apply(storedUrl);
          }catch(e1){
            // 저장 실패 시 현재 세션에는 적용, 단 새로고침 유지 안 됨을 안내
            apply(rawUrl);
            alert('이미지는 적용됐지만 용량이 커서 저장되지 않았어요. 더 작은 이미지로 선택해 주세요.');
          }
        }catch(e2){
          // 캔버스 변환 실패 시 원본으로 시도
          try{
            localStorage.setItem(LS_KEY, rawUrl);
            apply(rawUrl);
          }catch(e3){
            apply(rawUrl);
            alert('이미지는 적용됐지만 저장에 실패했어요. 이미지 크기를 줄여 다시 시도해 주세요.');
          }
        }
        inp.value='';
      };
      img.onerror=function(){
        inp.value='';
      };
      img.src=rawUrl;
    };
    r.readAsDataURL(f);
  }

  // 우클릭/길게: 기본으로 리셋
  function reset(){
    try{ localStorage.removeItem(LS_KEY); }catch(e){}
    apply('');
  }

  try{
    var btn=document.getElementById('chatBgPickBtn');
    var clearBtn=document.getElementById('chatBgClearBtn');
    var inp=document.getElementById('chatBgFileInput');
    if(btn && !btn.dataset.bound){
      btn.dataset.bound='1';
      btn.addEventListener('click', openPicker);
      btn.addEventListener('contextmenu', function(e){ e.preventDefault(); reset(); });
      btn.title='클릭: 배경 선택 / 우클릭: 기본으로';
    }
    if(clearBtn && !clearBtn.dataset.bound){
      clearBtn.dataset.bound='1';
      clearBtn.addEventListener('click', function(){ reset(); });
      clearBtn.title='배경 제거';
    }
    if(inp && !inp.dataset.bound){
      inp.dataset.bound='1';
      inp.addEventListener('change', onPick);
    }
  }catch(e){}
})();

function isNarrationLead(raw){
  var t=String(raw||'').trim();
  if(!t) return false;
  // 무대 지문 스타일은 "맨 앞이 ("일 때 강하게 적용 (혼합 문장 지원)
  if(t.startsWith('(')) return true;
  // ……만으로 지문 판정하면 따옴표 안의 "……"까지 지문이 되어버려서 제외
  if(t.indexOf('……') >= 0 && t.indexOf('"') < 0) return true;
  return false;
}

function buildChatRichHtml(raw){
  var text=String(raw||'').replace(/\r\n/g,'\n').replace(/\r/g,'\n');
  /* (행동) 과 "대사" 사이는 한 줄 띄움 — 이미 줄바꿈된 경우는 건드리지 않음 */
  text = text.replace(/\)[ \t]*"/g, ')\n"');
  var hasParenOrQuote=/[(\"]/.test(text);
  var leadNarr=isNarrationLead(text);
  var clsDefault=(!hasParenOrQuote && leadNarr) ? 'chat-text--narration' : 'chat-dialogue';

  var out=[];
  var i=0;
  var n=text.length;
  while(i<n){
    var ch=text.charAt(i);
    if(ch==='\n'){
      out.push('<br/>');
      i++;
      continue;
    }
    if(ch==='('){
      var end=text.indexOf(')',i+1);
      if(end<0){
        out.push('<span class="chat-paren">'+ escapeChatHtml(text.slice(i)) +'</span>');
        break;
      }
      out.push('<span class="chat-paren">'+ escapeChatHtml(text.slice(i,end+1)) +'</span>');
      i=end+1;
      continue;
    }
    if(ch==='"'){
      var eq=text.indexOf('"',i+1);
      if(eq<0){
        out.push('<span class="'+clsDefault+'">'+ escapeChatHtml(text.slice(i)) +'</span>');
        break;
      }
      out.push('<span class="chat-quote">'+ escapeChatHtml(text.slice(i,eq+1)) +'</span>');
      i=eq+1;
      continue;
    }
    var nextP=text.indexOf('(',i);
    var nextQ=text.indexOf('"',i);
    var next=-1;
    if(nextP>=0 && nextQ>=0) next=Math.min(nextP,nextQ);
    else next=nextP>=0 ? nextP : nextQ;
    if(next<0){
      var tail=text.slice(i);
      if(tail) out.push('<span class="'+clsDefault+'">'+ escapeChatHtml(tail) +'</span>');
      break;
    }
    if(next>i) out.push('<span class="'+clsDefault+'">'+ escapeChatHtml(text.slice(i,next)) +'</span>');
    i=next;
  }
  if(!out.length) return '';
  return out.join('');
}

function ensureBubbleNeon(bubble, statusCode){
  if(!bubble) return;
  var code=String(statusCode||'').trim().toUpperCase();
  var neon='rgba(224,187,228,.55)';
  if(code==='BURNOUT') neon='rgba(255, 107, 107, .65)';
  else if(code==='INJURY') neon='rgba(251, 191, 36, .68)';
  else if(code==='CONFIDENCE') neon='rgba(255, 209, 218, .72)';
  else if(code==='HARMONY') neon='rgba(52, 211, 153, .65)';
  else if(code==='SLUMP') neon='rgba(148, 163, 184, .65)';
  else if(code==='SPOTLIGHT') neon='rgba(125, 211, 252, .70)';
  else if(code==='FANDOM') neon='rgba(167, 139, 250, .70)';
  bubble.style.setProperty('--neon', neon);
}

function updateRosterStatusMapFromResult(data){
  try{
    var list=data && data.updatedRoster ? data.updatedRoster : (data && data.roster ? data.roster : null);
    if(!list || !list.length) return;
    window.__statusByTraineeId=window.__statusByTraineeId||{};
    list.forEach(function(m){
      if(!m) return;
      var id=m.traineeId != null ? String(m.traineeId) : null;
      if(!id) return;
      window.__statusByTraineeId[id]=m.statusCode||'';
    });
  }catch(e){}
}

/** 구버전 폴백·모델 오류: 「이름」 - 대사 한 줄 제거 후 스타일링 */
function stripLegacyIdolBracketPrefix(raw){
  var t = String(raw || '');
  t = t.replace(/「[^」]{1,48}」\s*[-—–]\s*/g, '');
  t = t.replace(/^[-—–\s]+/, '');
  return t.trim();
}

function applyBubbleTextStyling(textEl, raw){
  if(!textEl) return;
  var t = stripLegacyIdolBracketPrefix(String(raw||''));
  // 한 문장 안에서 (지문) + "대사" 혼합 스타일링 지원
  textEl.classList.remove('chat-text--narration');
  textEl.classList.remove('chat-dialogue');
  var html = buildChatRichHtml(t);
  // [상황] 버블에서 "프로듀서:"로 시작하는 줄은 핑크 강조
  // (괄호 지문은 이미 이모지 제거/괄호 처리됨. 여기서는 cue 한 줄만 스타일)
  html = html.replace(/(^|<br\s*\/?>)(\s*)(프로듀서:\s*[^<]*)/g, function(_, br, sp, line){
    return (br || '') + (sp || '') + '<span class="cue-producer">' + line + '</span>';
  });
  textEl.innerHTML = html;
}

function typewriterInto(el, rawText, speedMs, onDone){
  if(!el) { if(onDone) onDone(); return; }
  var text=String(rawText||'');
  el.textContent='';
  var i=0;
  function tick(){
    if(i >= text.length){
      if(onDone) onDone();
      return;
    }
    el.textContent += text.charAt(i++);
    // 스크롤 따라가기
    var log=document.getElementById('gameChatLog');
    if(log) log.scrollTop=log.scrollHeight;
    setTimeout(tick, speedMs);
  }
  tick();
}

function startTypewriterForBubble(bubble, onComplete){
  if(!bubble) { if(onComplete) onComplete(); return; }
  var textEl=bubble.querySelector('.chat-bubble-text');
  if(!textEl) { if(onComplete) onComplete(); return; }
  var raw=bubble.getAttribute('data-raw-text');
  if(raw==null) { if(onComplete) onComplete(); return; }
  bubble.removeAttribute('data-raw-text');
  if(!String(raw).trim() && bubble.classList && bubble.classList.contains('chat-bubble--idol')){
    var lab=bubble.querySelector('.chat-bubble-label');
    var nm=(lab && lab.textContent) ? String(lab.textContent).split('·')[0].trim() : '';
    raw=ndxFallbackIdolLineText({ name:nm });
  }
  // 사용자 요청: 타이핑 효과 제거, 항상 즉시 전체 출력
  applyBubbleTextStyling(textEl, raw);
  var log=document.getElementById('gameChatLog');
  if(log) log.scrollTop=log.scrollHeight;
  if(onComplete) onComplete();
}

function applyIdolDialogueEmphasisInLog(){
  document.querySelectorAll('#gameChatLog .chat-bubble--idol .chat-bubble-text').forEach(function(el){
    var raw=el.textContent||'';
    applyBubbleTextStyling(el, raw);
  });
}

function buildRosterAvatarMap(){
  var mapByName={}, mapByTid={};
  document.querySelectorAll('.mcard[data-tid]').forEach(function(card){
    var tid=card.getAttribute('data-tid');
    var name=((card.querySelector('.cname')||{}).textContent||'').trim();
    var img=card.querySelector('.cpho img');
    var src=img ? (img.getAttribute('src')||'') : '';
    if(tid) mapByTid[tid]=src;
    if(name) mapByName[name]=src;
  });
  window.__rosterAvatarByName=mapByName;
  window.__rosterAvatarByTid=mapByTid;
}

function avatarHtmlFor(line){
  var tid=line && (line.traineeId||line.traineeID||line.tid||line.trainee_id);
  var name=line && (line.name||'');
  var src='';
  try{
    if(tid && window.__rosterAvatarByTid) src=window.__rosterAvatarByTid[String(tid)]||'';
    if(!src && name && window.__rosterAvatarByName) src=window.__rosterAvatarByName[String(name).trim()]||'';
  }catch(e){src='';}
  if(src){
    return '<div class="chat-avatar"><img src="'+escapeChatHtml(src)+'" alt=""/></div>';
  }
  return '<div class="chat-avatar"><span class="ph"><i class="fas fa-user"></i></span></div>';
}

function ensureIdolBubbleAvatar(bubble, lineLike){
  if(!bubble) return;
  var av=bubble.querySelector('.chat-avatar');
  if(av){
    // placeholder(아이콘)만 있는 경우 실제 이미지로 교체
    var hasImg=!!av.querySelector('img');
    if(!hasImg){
      av.outerHTML=avatarHtmlFor(lineLike||{});
    }
  }else{
    bubble.insertAdjacentHTML('afterbegin', avatarHtmlFor(lineLike||{}));
  }
  if(!bubble.querySelector('.chat-bubble-body')){
    var label=bubble.querySelector('.chat-bubble-label');
    var text=bubble.querySelector('.chat-bubble-text');
    if(label && text){
      var body=document.createElement('div');
      body.className='chat-bubble-body';
      body.appendChild(label);
      body.appendChild(text);
      bubble.appendChild(body);
    }
  }
}

function decorateExistingIdolBubbles(){
  buildRosterAvatarMap();
  document.querySelectorAll('#gameChatLog .chat-bubble--idol').forEach(function(b){
    var lab=b.querySelector('.chat-bubble-label');
    var nm=(lab && lab.textContent ? (lab.textContent.split('·')[0]||'').trim() : '');
    ensureIdolBubbleAvatar(b, {name:nm});
    var txtEl=b.querySelector('.chat-bubble-text');
    if(txtEl && !b.getAttribute('data-raw-text')){
      var rt=stripLegacyIdolBracketPrefix(String(txtEl.textContent||''));
      if(!String(rt||'').trim()) rt = ndxFallbackIdolLineText({});
      b.setAttribute('data-raw-text', rt);
    }
  });
}

window.__dialogueStaggerTimers=window.__dialogueStaggerTimers||[];
window.__dialogueChainId=window.__dialogueChainId||0;

function clearDialogueMcardHighlight(){
  document.querySelectorAll('.mcard').forEach(function(c){
    c.classList.remove('mcard--dialogue-active','mcard--dimmed');
  });
}
function highlightMcardForDialogueBubble(bubble){
  clearDialogueMcardHighlight();
  if(!bubble)return;
  var tid=bubble.getAttribute('data-trainee-id');
  var card=null;
  if(tid) card=document.querySelector('.mcard[data-tid="'+String(tid).replace(/"/g,'')+'"]');
  if(!card){
    var lab=bubble.querySelector('.chat-bubble-label');
    var nm=(lab&&lab.textContent)?lab.textContent.split('·')[0].trim():'';
    if(nm){
      document.querySelectorAll('.mcard').forEach(function(mc){
        var cn=mc.querySelector('.cname');
        if(cn&&cn.textContent.trim()===nm) card=mc;
      });
    }
  }
  if(!card)return;
  card.classList.add('mcard--dialogue-active');
  document.querySelectorAll('.mcard').forEach(function(mc){
    if(mc!==card) mc.classList.add('mcard--dimmed');
  });
}

function clearDialogueStagger(){
  var arr=window.__dialogueStaggerTimers;
  if(arr&&arr.length) arr.forEach(function(id){ clearTimeout(id); });
  window.__dialogueStaggerTimers=[];
  window.__dialogueChainId=(window.__dialogueChainId||0)+1;
  clearDialogueMcardHighlight();
}

/** 픽 순(1→2→3→4) 정렬 후, 이전 말풍선 타이핑이 끝난 뒤 다음 말풍선 표시 */
function scheduleStaggerForElements(els){
  clearDialogueStagger();
  if(!els||!els.length)return;
  var BUBBLE_STAGGER_MS=420;
  var list=Array.prototype.slice.call(els);
  var roster=typeof collectRosterFromDom==='function' ? collectRosterFromDom() : [];
  var nameOrder={};
  roster.forEach(function(m){ if(m&&m.name) nameOrder[String(m.name).trim()]=m.pickOrder||999; });
  list.sort(function(a,b){
    var la=a.querySelector('.chat-bubble-label');
    var lb=b.querySelector('.chat-bubble-label');
    var na=(la&&la.textContent||'').split('·')[0].trim();
    var nb=(lb&&lb.textContent||'').split('·')[0].trim();
    return (nameOrder[na]||999)-(nameOrder[nb]||999);
  });
  var chainId=++window.__dialogueChainId;
  function showNext(idx){
    if(chainId!==window.__dialogueChainId) return;
    if(idx>=list.length){
      clearDialogueMcardHighlight();
      return;
    }
    var el=list[idx];
    el.classList.add('dialogue-stagger--shown');
    highlightMcardForDialogueBubble(el);
    startTypewriterForBubble(el, function(){
      if(chainId!==window.__dialogueChainId) return;
      var log=document.getElementById('gameChatLog');
      if(log) log.scrollTop=log.scrollHeight;
      var tid=setTimeout(function(){ showNext(idx+1); },BUBBLE_STAGGER_MS);
      window.__dialogueStaggerTimers.push(tid);
    });
  }
  showNext(0);
}

/** 스태거 예약만 취소(체인 ID는 건드리지 않음) — skipDialogueStagger에서 본문 채우기 전에 ID를 올리면 showNext가 전부 중단되어 뒷줄 말풍선이 영원히 비는 버그가 난다 */
function clearDialogueStaggerTimersOnly(){
  var arr=window.__dialogueStaggerTimers;
  if(arr&&arr.length) arr.forEach(function(id){ clearTimeout(id); });
  window.__dialogueStaggerTimers=[];
}

/** 「다음」: 생각 중 타이머·말풍선 처리 + 대사 즉시 전부 표시 */
function skipDialogueStagger(){
  clearDialogueStaggerTimersOnly();
  if(window.__chatThinkingTimer){
    clearTimeout(window.__chatThinkingTimer);
    window.__chatThinkingTimer=null;
  }
  var th=document.getElementById('gameChatThinkingBubble');
  if(th&&th.parentNode) th.parentNode.removeChild(th);
  if(window._pendingReactionLines&&window._pendingReactionLines.length){
    var pending=window._pendingReactionLines;
    window._pendingReactionLines=null;
    appendCharacterResponseBubbles(pending,false);
    var log=document.getElementById('gameChatLog');
    if(log) log.scrollTop=log.scrollHeight;
    window.__dialogueChainId=(window.__dialogueChainId||0)+1;
    clearDialogueMcardHighlight();
    return;
  }
  document.querySelectorAll('#gameChatLog .dialogue-stagger').forEach(function(el){
    el.classList.add('dialogue-stagger--shown');
    // 스킵 시에는 타이핑을 기다리지 않고 즉시 본문을 채운다(빈 말풍선 방지)
    try{
      var raw=el.getAttribute('data-raw-text');
      var txt=el.querySelector('.chat-bubble-text');
      if(!txt) return;
      if(raw!==null){
        el.removeAttribute('data-raw-text');
        var t=String(raw||'').trim();
        if(!t && el.classList.contains('chat-bubble--idol')){
          var lab0=el.querySelector('.chat-bubble-label');
          var nm0=(lab0 && lab0.textContent) ? String(lab0.textContent).split('·')[0].trim() : '';
          t=ndxFallbackIdolLineText({ name:nm0 });
        }
        applyBubbleTextStyling(txt, t);
      }else{
        startTypewriterForBubble(el);
      }
    }catch(e){
      startTypewriterForBubble(el);
    }
  });
  // 시스템(상황) 버블: 턴마다 여러 개일 수 있으므로 전부 즉시 채움(첫 버블만 채우면 이후 지문이 비는 버그 방지)
  try{
    document.querySelectorAll('#gameChatLog .chat-bubble--system').forEach(function(sys){
      var raw2=sys.getAttribute('data-raw-text');
      var t2=sys.querySelector('.chat-bubble-text');
      if(raw2!=null && t2){
        sys.removeAttribute('data-raw-text');
        applyBubbleTextStyling(t2, raw2);
      }
    });
  }catch(e){}
  // 본문·표시가 모두 반영된 뒤에만 체인 무효화(위에서 clearDialogueStagger를 먼저 호출하면 showNext가 끊겨 빈 말풍선만 남음)
  window.__dialogueChainId=(window.__dialogueChainId||0)+1;
  clearDialogueMcardHighlight();
  var log=document.getElementById('gameChatLog');
  if(log) log.scrollTop=log.scrollHeight;
}

/** 상단 「다음」: 대사 스킵 후 — 채팅 결과 대기 중이면 결과 패널, 아니면 브리핑 패널 */
function onDialogueNextClick(){
  skipDialogueStagger();
  var rov=document.getElementById('rov');
  if(rov&&rov.classList.contains('show'))return;
  if(window._pendingTurnResult){
    openTurnResultOverlayFromPending();
    return;
  }
  openBriefingResultOverlay();
}

/** 로스터 카드 DOM에서 멤버 스탯 수집 (픽 순 정렬) */
function collectRosterFromDom(){
  var out=[];
  document.querySelectorAll('.mcard[data-tid]').forEach(function(card){
    if(card.classList.contains('mcard--eliminated')) return;
    function gv(key){
      var el=card.querySelector('.sval[data-key="'+key+'"]');
      return memberRawStatFromValueEl(el);
    }
    var pCode=(card.getAttribute('data-personality-code')||'').trim();
    out.push({
      traineeId:card.getAttribute('data-tid'),
      name:((card.querySelector('.cname')||{}).textContent||'').trim(),
      vocal:gv('v'),dance:gv('d'),star:gv('s'),mental:gv('m'),teamwork:gv('t'),
      pickOrder:parseInt((card.querySelector('.cpick')||{}).textContent,10)||999,
      personalityCode:pCode||null
    });
  });
  out.sort(function(a,b){return a.pickOrder-b.pickOrder;});
  return out;
}

/**
 * 채팅 전·상황 확인용 결과 패널 (스탯 변화 없음). 목업과 동일 레이아웃(#rov).
 */
function openBriefingResultOverlay(){
  var rov=document.getElementById('rov');
  if(!rov)return;
  if(rov.classList.contains('show'))return;

  var roster=collectRosterFromDom();
  var m=roster[0];
  if(!m)return;

  window._resultOverlayMode='briefing';

  var av=document.getElementById('res-av');
  if(av) av.innerHTML='<div class="rav-ph"><i class="fas fa-user"></i></div>';

  document.getElementById('res-name').textContent=m.name;
  document.getElementById('res-action').textContent='브리핑 확인';

  var sitText='';
  var sysBubble=document.querySelector('#gameChatLog .chat-bubble--system .chat-bubble-text');
  if(sysBubble) sitText=(sysBubble.textContent||'').trim();
  if(!sitText) sitText='연습실 상황을 확인했습니다. 아래에서 지시를 내려 주세요.';
  document.getElementById('res-result-narration').textContent=sitText;

  document.getElementById('res-event-title').textContent='이벤트 발생 · 팀이 한자리에 모였습니다';
  document.getElementById('res-event-desc').textContent='키워드(휴식·훈련·보컬·댄스 등)로 지시하면 스탯과 팬 반응이 반영됩니다.';

  document.getElementById('res-sname').textContent='보컬';
  document.getElementById('res-bef').textContent=String(m.vocal);
  document.getElementById('res-aft').textContent=String(m.vocal);
  var dEl=document.getElementById('res-delta');
  dEl.textContent='— · 이번 확인 단계에서는 변화 없음';
  dEl.className='rdelta flat';

  var fanTitle=document.getElementById('res-fan-title');
  var fanDesc=document.getElementById('res-fan-desc');
  var fanBreak=document.getElementById('res-fan-breakdown');
  var fanTotal=document.getElementById('res-fan-total');
  var fanEvent=document.getElementById('res-fan-event');
  if(fanTitle) fanTitle.textContent='팬 반응';
  if(fanDesc) fanDesc.textContent='아직 지시 전입니다. 채팅 입력 후 팬 반응이 갱신됩니다.';
  if(fanBreak) fanBreak.textContent='국내 '+CURRENT_CORE_FANS+' · 해외 '+CURRENT_CASUAL_FANS;
  if(fanTotal){
    fanTotal.textContent='팬 '+CURRENT_TOTAL_FANS;
    fanTotal.className='rfan-total';
  }
  if(fanEvent){ fanEvent.style.display='none'; fanEvent.innerHTML=''; }

  var statusBox=document.getElementById('res-status-box');
  if(statusBox){
    statusBox.classList.remove('show');
    document.getElementById('res-status-chip').textContent='상태 없음';
    document.getElementById('res-status-desc').textContent='';
    document.getElementById('res-status-meta').textContent='';
  }

  var nextBadge=document.getElementById('res-next');
  if(nextBadge) nextBadge.textContent='▸ 채팅으로 훈련 지시를 내려 주세요';

  var mg=document.getElementById('res-minigame-box');
  if(mg) mg.style.display='none';
  var pb=document.getElementById('res-penalty-stat-box');
  if(pb) pb.style.display='none';

  rov.classList.add('show');
  try{ rov.focus(); }catch(eFocus){}
  var card=document.querySelector('.rcard');
  if(card){
    card.style.boxShadow='0 0 0 1px rgba(167,139,250,.22),0 0 36px rgba(167,139,250,.12),0 24px 72px rgba(30,41,59,.18)';
  }
  setTimeout(function(){
    var rc=document.querySelector('.rcard');
    if(rc){var r=rc.getBoundingClientRect();burstAt(r.left+r.width/2,r.top+r.height/2,14);}
  },280);
}

function initGameChatIntroSequence(){
  var logRoot=document.getElementById('gameChatLog');
  if(logRoot && logRoot.getAttribute('data-log-restored')==='1'){
    logRoot.removeAttribute('data-log-restored');
    decorateExistingIdolBubbles();
    applyIdolDialogueEmphasisInLog();
    document.querySelectorAll('#gameChatLog .dialogue-stagger').forEach(function(el){
      el.classList.add('dialogue-stagger--shown');
    });
    return;
  }
  decorateExistingIdolBubbles();
  applyIdolDialogueEmphasisInLog();
  var nodes=document.querySelectorAll('#gameChatLog .dialogue-stagger:not([data-intro-initialized])');
  var sysEarly=document.querySelector('#gameChatLog .chat-bubble--system:not([data-intro-initialized])');
  if(sysEarly && !sysEarly.getAttribute('data-from-reaction')){
    sysEarly.setAttribute('data-scene-intro', '1');
  }
  nodes.forEach(function(b){
    var t=b.querySelector('.chat-bubble-text');
    if(t){
      var raw0=t.textContent||'';
      var raw=stripLegacyIdolBracketPrefix(raw0);
      if(!String(raw||'').trim()){
        raw = ndxFallbackIdolLineText({});
      }
      b.setAttribute('data-raw-text', raw);
      t.textContent='';
    }
    var lab=b.querySelector('.chat-bubble-label');
    var tid=b.getAttribute('data-trainee-id');
    if(!tid && lab && lab.textContent){
      ensureBubbleNeon(b,'');
    }
    b.setAttribute('data-intro-initialized','1');
  });

  var sysList=document.querySelectorAll('#gameChatLog .chat-bubble--system:not([data-intro-initialized]):not([data-from-reaction])');
  sysList.forEach(function(sys){
    var st=sys.querySelector('.chat-bubble-text');
    if(st){
      var raw2=st.textContent||'';
      sys.setAttribute('data-raw-text', raw2);
      st.textContent='';
      ensureBubbleNeon(sys,'');
      sys.setAttribute('data-intro-initialized','1');
      startTypewriterForBubble(sys);
    }
  });
  if(nodes.length) scheduleStaggerForElements(nodes);
}
window.initGameChatIntroSequence = initGameChatIntroSequence;

function ndxGameChatLogStorageKey(){
  return 'ndx_chat_log_v2_' + String(RUN_ID || '');
}

/** 새로고침·탭 복귀 시 #gameChatLog 복원 (localStorage로 탭을 닫아도 유지, phase와 무관하게 누적) */
function restoreGameChatLogFromSession(){
  try{
    if(!RUN_ID) return;
    var key = ndxGameChatLogStorageKey();
    var raw = null;
    try{
      raw = localStorage.getItem(key);
    }catch(e0){}
    if(!raw){
      try{
        raw = sessionStorage.getItem('ndx_chat_log_v1_' + String(RUN_ID || ''));
        if(raw) localStorage.setItem(key, raw);
      }catch(e1){}
    }
    if(!raw) return;
    var o = JSON.parse(raw);
    if(!o || !o.html) return;
    var log = document.getElementById('gameChatLog');
    if(!log) return;
    log.innerHTML = o.html;
    log.setAttribute('data-log-restored', '1');
    if(o.lastSceneIntroKey != null && String(o.lastSceneIntroKey) !== ''){
      window.__ndxLastAppliedSceneIntroKey = String(o.lastSceneIntroKey);
    }
  }catch(e){}
}

function persistGameChatLogToSession(){
  try{
    if(!RUN_ID) return;
    var log = document.getElementById('gameChatLog');
    if(!log) return;
    var payload = JSON.stringify({
      phase: String(currentPhase || (typeof NDX_GAME_CONFIG !== 'undefined' && NDX_GAME_CONFIG && NDX_GAME_CONFIG.phase) || ''),
      html: log.innerHTML,
      lastSceneIntroKey: window.__ndxLastAppliedSceneIntroKey != null ? String(window.__ndxLastAppliedSceneIntroKey) : ''
    });
    try{
      localStorage.setItem(ndxGameChatLogStorageKey(), payload);
    }catch(eFull){
      try{
        sessionStorage.setItem('ndx_chat_log_v1_' + String(RUN_ID || ''), payload);
      }catch(e2){}
    }
  }catch(e){}
}

(function bindGameChatLogPersistence(){
  var timer;
  function schedule(){
    clearTimeout(timer);
    timer = setTimeout(persistGameChatLogToSession, 380);
  }
  function bind(){
    var log = document.getElementById('gameChatLog');
    if(!log || log.dataset.ndxPersistBound) return;
    log.dataset.ndxPersistBound = '1';
    try{
      var obs = new MutationObserver(function(){ schedule(); });
      obs.observe(log, { childList: true, subtree: true, characterData: true });
    }catch(e0){
      schedule();
    }
  }
  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', bind);
  }else{
    bind();
  }
})();

function bootGameChatIntroSequence(){
  try{ restoreGameChatLogFromSession(); }catch(eR){}
  try{ initGameChatIntroSequence(); }catch(eI){}
  try{
    if(window.__ndxLastAppliedSceneIntroKey == null || window.__ndxLastAppliedSceneIntroKey === ''){
      var k = ndxComputeIntroKeyFromDom();
      if(k) window.__ndxLastAppliedSceneIntroKey = k;
    }
  }catch(eK){}
}
window.bootGameChatIntroSequence = bootGameChatIntroSequence;
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bootGameChatIntroSequence);
else bootGameChatIntroSequence();

/**
 * @param lines API characterLines [{name,personality,text}]
 * @param useStagger true면 0.5초 간격 등장용 클래스 부여 (기본 true)
 */
/** 서버/폴백에서 text가 비면 말풍선만 남는 버그 방지 */
function ndxFallbackIdolLineText(line){
  var pool=[
    '(잠시 숨을 고르고 거울을 본다)\n"호흡만 맞추면 돼. 한 번 더 해보자!"',
    '(손끝으로 박자를 허공에 짚는다)\n"지금 흐름, 끝까지 같이 가보자!"',
    '(물병을 내려놓고 어깨를 편다)\n"괜찮아, 같이 맞춰보면 돼. 천천히."',
    '(눈을 감았다 뜨며 고개를 끄덕인다)\n"여기까지 왔으니, 이어서 가보자!"'
  ];
  return pool[Math.floor(Math.random()*pool.length)];
}

function appendCharacterResponseBubbles(lines, useStagger){
  if(useStagger===undefined)useStagger=true;
  lines = typeof filterDialogueLinesNotEliminated === 'function' ? filterDialogueLinesNotEliminated(lines) : (lines || []);
  if(!lines||!lines.length)return [];
  var log=document.getElementById('gameChatLog');
  if(!log)return [];
  var batch=[];
  lines.forEach(function(line){
    var d=document.createElement('div');
    d.className='chat-bubble chat-bubble--npc chat-bubble--idol'+(useStagger?' dialogue-stagger':'');
    var nm=escapeChatHtml(line.name||'');
    var pers=escapeChatHtml(line.personality||'');
    var rawText=String(line.text||'').trim();
    if(!rawText) rawText=ndxFallbackIdolLineText(line);
    var tid=line && (line.traineeId||line.traineeID||line.tid||line.trainee_id);
    if(tid != null) d.setAttribute('data-trainee-id', String(tid));
    d.setAttribute('data-raw-text', rawText);
    d.innerHTML=avatarHtmlFor(line)
      + '<div class="chat-bubble-body">'
      +   '<div class="chat-bubble-label">'+nm+(pers?' · '+pers:'')+'</div>'
      +   '<div class="chat-bubble-text"></div>'
      + '</div>';
    var status='';
    try{
      if(tid != null && window.__statusByTraineeId) status=window.__statusByTraineeId[String(tid)]||'';
    }catch(e){status='';}
    ensureBubbleNeon(d, status);
    log.appendChild(d);
    batch.push(d);
    if(!useStagger){
      startTypewriterForBubble(d);
    }
  });
  return batch;
}

function setSelectedMemberByName(name){
  var n=(name||'').trim();
  if(!n) return;
  var cards=document.querySelectorAll('.mcard .cname');
  var foundCard=null;
  cards.forEach(function(el){
    var cn=(el.textContent||'').trim();
    if(cn===n && !foundCard){
      foundCard=el.closest('.mcard');
    }
  });
  if(!foundCard) return;
  document.querySelectorAll('.mcard.is-selected').forEach(function(c){ c.classList.remove('is-selected'); });
  foundCard.classList.add('is-selected');
}

(function bindChatSpeakerSelect(){
  function pickFirstOnLoad(){
    var first=document.querySelector('.mcard');
    if(first) first.classList.add('is-selected');
  }
  function onClick(e){
    var bubble=e.target && e.target.closest ? e.target.closest('.chat-bubble--idol') : null;
    if(!bubble) return;
    var lab=bubble.querySelector('.chat-bubble-label');
    var raw=(lab && lab.textContent) ? lab.textContent : '';
    var nm=(raw.split('·')[0]||'').trim();
    setSelectedMemberByName(nm);
    document.querySelectorAll('#gameChatLog .chat-bubble--idol.is-speaker').forEach(function(b){ b.classList.remove('is-speaker'); });
    bubble.classList.add('is-speaker');
  }
  if(document.readyState==='loading'){
    document.addEventListener('DOMContentLoaded',function(){
      pickFirstOnLoad();
      var log=document.getElementById('gameChatLog');
      if(log) log.addEventListener('click', onClick);
    });
  }else{
    pickFirstOnLoad();
    var log=document.getElementById('gameChatLog');
    if(log) log.addEventListener('click', onClick);
  }
})();

(function bindMcardDirectSelect(){
  document.addEventListener('click', function(e){
    var card=e.target&&e.target.closest?e.target.closest('.mcard[data-tid]'):null;
    if(!card||!card.closest('.panel-l')) return;
    document.querySelectorAll('.mcard.is-selected').forEach(function(c){ c.classList.remove('is-selected'); });
    card.classList.add('is-selected');
    card.classList.remove('mcard--tap-bump');
    void card.offsetWidth;
    card.classList.add('mcard--tap-bump');
    setTimeout(function(){ try{ card.classList.remove('mcard--tap-bump'); }catch(err){} },400);
  });
})();

function hudNextStep(){
  var rov=document.getElementById('rov');
  if(rov && rov.classList.contains('show')){
    goNext();
    return;
  }
  onDialogueNextClick();
}

var CHAT_THINKING_MS=420;

/** 서버가 dialogueSituation을 비운 채 대사만 줄 때 [상황] 버블이 사라지지 않게 함 */
var NDX_CLIENT_FALLBACK_SITUATIONS = [
  '(연습실에서 호흡이 이어지고, 방금 지시가 팀에 스며든다.)',
  '(메트로놈이 한 박자 늦게 들리고, 누군가 숨을 고른다.)',
  '(거울 앞에서 시선이 잠깐 엇갈렸다 다시 맞춰진다.)',
  '(스피커에서 잔향이 남고, 바닥 테이프가 살짝 들뜬다.)',
  '(누군가 물병을 돌리고, 의자가 바닥을 긁는 소리가 난다.)',
  '(파트가 겹치는 구간에서 목소리가 한 톤 어긋났다 맞춰진다.)',
  '(팀원 사이에 짧은 침묵이 있다가, 누군가 먼저 박자를 짚는다.)',
  '(프로듀서 노트가 테이블에 펼쳐져 있고, 펜이 한 줄을 더 긋는다.)'
];
function ndxPickClientFallbackSituation(){
  var a = NDX_CLIENT_FALLBACK_SITUATIONS;
  return a[Math.floor(Math.random() * a.length)];
}

function ndxNormChatTxt(s){
  return String(s==null?'':s).replace(/\s+/g,' ').trim();
}

/** 서버 line에서 연습생 id (필드명 여러 형태) */
function ndxLineTraineeId(line){
  if(!line) return '';
  var v = line.traineeId != null ? line.traineeId : (line.traineeID != null ? line.traineeID : line.tid);
  return v != null ? String(v) : '';
}

/** 말풍선 라벨에서 이름만 (타이핑 id 불일치 시 보조 비교) */
function ndxBubbleSpeakerName(bub){
  var lab = bub && bub.querySelector ? bub.querySelector('.chat-bubble-label') : null;
  if(!lab) return '';
  return ndxNormChatTxt(String((lab.textContent||'').split('·')[0]||'').trim());
}

/**
 * 중복 검사용 본문: 타이핑 중이면 text가 짧아지므로 data-raw-text 우선.
 */
function ndxIdolBubbleMatchText(bub){
  if(!bub) return '';
  var raw = bub.getAttribute('data-raw-text');
  var txtEl = bub.querySelector('.chat-bubble-text');
  var live = ndxNormChatTxt(txtEl && txtEl.textContent);
  var rawN = raw != null && raw !== '' ? ndxNormChatTxt(String(raw)) : '';
  if(rawN && (!live || live.length < rawN.length)) return rawN;
  return live || rawN;
}

/** [상황] 시스템 버블의 전체 본문 — 타이핑 중에도 data-raw-text 우선 */
function ndxSituationBubblePlainText(bubble){
  if(!bubble) return '';
  var raw = bubble.getAttribute('data-raw-text');
  if(raw != null && String(raw).length){
    return String(raw).replace(/\s+/g,' ').trim();
  }
  var txt = bubble.querySelector('.chat-bubble-text');
  return txt ? String(txt.textContent||'').replace(/\s+/g,' ').trim() : '';
}

/** 마지막 [상황] 버블 본문(타이핑 완료 기준 textContent) */
function ndxLastSituationBubbleText(log){
  if(!log) return '';
  var labs = log.querySelectorAll('.chat-bubble--system .chat-bubble-label');
  for(var i = labs.length - 1; i >= 0; i--){
    if((labs[i].textContent||'').indexOf('[상황]') >= 0){
      var p = labs[i].closest('.chat-bubble--system');
      if(p){
        var fromRaw = ndxSituationBubblePlainText(p);
        if(fromRaw) return ndxNormChatTxt(fromRaw);
      }
      var txt = p && p.querySelector('.chat-bubble-text');
      return txt ? ndxNormChatTxt(txt.textContent) : '';
    }
  }
  return '';
}

/** 서버(Gemini) 상황·대사를 채팅 로그에 붙임 */
function tryAppendServerAiSituationDialogue(data){
  if(!data) return;
  var sit = data.dialogueSituation;
  var lines = data.characterLines;
  if((!sit || !String(sit).trim()) && lines && lines.length){
    sit = ndxPickClientFallbackSituation();
    data.dialogueSituation = sit;
  }
  if(!sit && !(lines && lines.length)) return;
  if(typeof appendReactionDialogue !== 'function') return;
  var hintPack = null;
  try{
    if(typeof generateSituationHint === 'function'){
      var st = typeof getConditionForGoals === 'function' ? getConditionForGoals() : null;
      if(st) hintPack = generateSituationHint(st);
    }
  }catch(e0){}
  try{
    appendReactionDialogue(sit, lines, hintPack);
  }catch(e1){}
  try{
    if(typeof persistGameChatLogToSession==='function') persistGameChatLogToSession();
  }catch(e2){}
}

/**
 * 스탯 플래시·결과 패널을 본 뒤 상황·멤버 대사 표시.
 * NDX_GAME_CONFIG.geminiDialogueDelayMs (기본 120). 서버(Gemini) 지연은 별도 — 키워드 확실 시 선택지 API 1회 생략.
 */
function scheduleServerAiSituationDialogue(data){
  if(!data) return;
  var sit = data.dialogueSituation;
  var lines = data.characterLines;
  if((!sit || !String(sit).trim()) && lines && lines.length){
    sit = ndxPickClientFallbackSituation();
    data.dialogueSituation = sit;
  }
  if(!sit && !(lines && lines.length)) return;
  var cfg = (typeof NDX_GAME_CONFIG !== 'undefined' && NDX_GAME_CONFIG) ? NDX_GAME_CONFIG : {};
  var ms = cfg.geminiDialogueDelayMs != null ? Number(cfg.geminiDialogueDelayMs) : 120;
  if(!isFinite(ms) || ms < 0) ms = 120;
  try{
    if(window.__serverAiDialogueTimer){
      clearTimeout(window.__serverAiDialogueTimer);
      window.__serverAiDialogueTimer = null;
    }
  }catch(e0){}
  window.__serverAiDialogueTimer = setTimeout(function(){
    try{ window.__serverAiDialogueTimer = null; }catch(e1){}
    tryAppendServerAiSituationDialogue(data);
  }, ms);
}

function appendReactionDialogue(situation, lines, hintPack){
  var log=document.getElementById('gameChatLog');
  if(!log)return;

  lines = typeof filterDialogueLinesNotEliminated === 'function' ? filterDialogueLinesNotEliminated(lines) : (lines || []);

  if((!situation || !String(situation).trim()) && lines && lines.length){
    situation = ndxPickClientFallbackSituation();
  }
  situation = String(situation || '');

  if(window.__chatThinkingTimer){
    clearTimeout(window.__chatThinkingTimer);
    window.__chatThinkingTimer=null;
  }
  var oldThink=document.getElementById('gameChatThinkingBubble');
  if(oldThink&&oldThink.parentNode) oldThink.parentNode.removeChild(oldThink);
  window._pendingReactionLines=null;

  // dupSameAsTail 로 [대사] 전체를 건너뛰면 DB 폴백 등으로 이전 턴과 문장이 비슷할 때 지문·대사가 영영 안 붙는 버그가 난다. 서버가 준 반응은 항상 렌더한다.
  var sitNorm = ndxNormChatTxt(situation);
  var hasHint = hintPack && (hintPack.hintLine || hintPack.coachLine);
  var hasSituationText = !!(sitNorm || (hintPack && hintPack.hintLine));

  var sitFull = String(situation || '');
  if(hintPack && hintPack.hintLine){
    sitFull = sitFull + (sitFull ? '\n\n※ ' : '※ ') + hintPack.hintLine;
  }
  if(hasSituationText){
    var s=document.createElement('div');
    s.className='chat-bubble chat-bubble--npc chat-bubble--system';
    s.setAttribute('data-from-reaction', '1');
    s.innerHTML='<div class="chat-bubble-label">[상황]</div><div class="chat-bubble-text"></div>';
    s.setAttribute('data-raw-text', String(sitFull || ''));
    ensureBubbleNeon(s, '');
    log.appendChild(s);
    startTypewriterForBubble(s);
  }
  if(hintPack && hintPack.coachLine){
    var c=document.createElement('div');
    c.className='chat-bubble chat-bubble--npc chat-bubble--system';
    c.setAttribute('data-coach-hint', '1');
    c.innerHTML='<div class="chat-bubble-label">[방향 제시]</div><div class="chat-bubble-text"></div>';
    var ct=c.querySelector('.chat-bubble-text');
    if(ct) ct.textContent=String(hintPack.coachLine||'');
    log.appendChild(c);
  }
  if(!lines||!lines.length){
    log.scrollTop=log.scrollHeight;
    return;
  }

  var lab=document.createElement('div');
  lab.className='chat-section-label';
  lab.textContent='[대사]';
  log.appendChild(lab);

  var think=document.createElement('div');
  think.id='gameChatThinkingBubble';
  think.className='chat-bubble chat-bubble--npc chat-bubble--thinking';
  think.innerHTML='<div class="chat-bubble-label">멤버</div><div class="chat-bubble-text chat-thinking-dots">···</div>';
  log.appendChild(think);
  log.scrollTop=log.scrollHeight;

  window._pendingReactionLines=lines.slice();

  window.__chatThinkingTimer=setTimeout(function(){
    window.__chatThinkingTimer=null;
    window._pendingReactionLines=null;
    var t=document.getElementById('gameChatThinkingBubble');
    if(t&&t.parentNode) t.parentNode.removeChild(t);
    var batch=appendCharacterResponseBubbles(lines,true);
    scheduleStaggerForElements(batch);
    var lg=document.getElementById('gameChatLog');
    if(lg) lg.scrollTop=lg.scrollHeight;
    try{
      if(typeof persistGameChatLogToSession==='function') persistGameChatLogToSession();
    }catch(eP){}
  },CHAT_THINKING_MS);
}

/**
 * 동적 맵 이벤트: 상황 풀 + 20성격 대사 조합 + 장소별 스탯 규칙 → 100+ 조합
 * IdolPersonality(enum) 순서와 동일한 20코드
 */
window.__lastSituationIndexByLocation = window.__lastSituationIndexByLocation || {};

var IDOL_PERSONALITY_ORDER = [
  'BUBBLY','CALM','TSUNDERE','GENTLE','PRANKSTER','SERIOUS','PERFECTIONIST','SENSITIVE','OPTIMISTIC','SHY',
  'LEADER','FREE_SPIRIT','COOL','COMPETITIVE','DEPENDENT','RELIABLE','BLUNT','SENTIMENTAL','LAID_BACK','REBELLIOUS'
];
var IDOL_PERSONALITY_META = {
  BUBBLY:{shortLabel:'활발'},CALM:{shortLabel:'차분'},TSUNDERE:{shortLabel:'츤데레'},GENTLE:{shortLabel:'다정'},PRANKSTER:{shortLabel:'장난꾸러기'},
  SERIOUS:{shortLabel:'진지함'},PERFECTIONIST:{shortLabel:'완벽주의'},SENSITIVE:{shortLabel:'예민함'},OPTIMISTIC:{shortLabel:'낙천적'},SHY:{shortLabel:'소심함'},
  LEADER:{shortLabel:'리더형'},FREE_SPIRIT:{shortLabel:'자유분방'},COOL:{shortLabel:'냉정함'},COMPETITIVE:{shortLabel:'승부욕'},DEPENDENT:{shortLabel:'의존적'},
  RELIABLE:{shortLabel:'든든함'},BLUNT:{shortLabel:'직설적'},SENTIMENTAL:{shortLabel:'감성적'},LAID_BACK:{shortLabel:'느긋함'},REBELLIOUS:{shortLabel:'반항적'}
};

var LOCATION_KO_NAME = {
  practice_room:'연습실', dorm:'숙소', broadcast_station:'방송국', stage:'무대', cafe:'카페'
};

var LOCATION_SITUATION_POOLS = {
  practice_room: [
    '{a} {loc}에 들어서자 {b} 공기가 얼굴을 스친다.',
    '스피커에서 {c}가 흐르고, {loc} 바닥엔 {d} 자국이 남아 있다.',
    '{loc} 한가운데 {e} 조명 아래 누군가 카운트를 세고 있다.',
    '{a} 거울 앞에서 {b} 시선이 교차한다.',
    '{loc} 구석 {c} 소품 더미가 {d} 그림자를 드리운다.',
    '문이 닫히자 {e} 정적이 {loc}를 메운다.',
    '{b} 호흡 소리만 {a} {loc}에 울린다.',
    '{loc} 로비에서 {c} 안내 방송이 {d} 울려 퍼진다.',
    '{a} 매트 위에 {e} 발자국이 겹겹이 쌓여 있다.',
    '{loc} 유리창 너머로 {b} 하늘이 비친다.'
  ],
  dorm: [
    '{a} {loc} 복도 끝에서 {b} 불빛이 새어 나온다.',
    '{loc} 공용 주방에 {c} 향이 {d} 번진다.',
    '{a} 침대마다 {b} 이불 산이 다른 높이로 쌓여 있다.',
    '{loc} 창가에 {e} 빗소리가 {c} 맴돈다.',
    '누군가 {d} 목소리로 {loc}에서 웃음을 터뜨린다.',
    '{a} 소파에 {b} 쿠션이 {e} 기울어져 있다.',
    '{loc} 게시판에 {c} 메모가 {d} 붙어 있다.',
    '{a} 세탁 바구니가 {b} 문 앞에 줄지어 있다.',
    '{loc} 복도에 {e} 슬리퍼가 하나 더 놓여 있다.',
    '{c} 라면 냄새가 {loc}를 {d} 감싼다.'
  ],
  broadcast_station: [
    '{a} {loc} 로비에 {b} 조명이 깜빡인다.',
    '{c} 대본 더미가 {loc} 테이블을 {d} 누르고 있다.',
    '{loc} 모니터엔 {e} 테스트 화면이 {a} 돌아간다.',
    '{b} 헤드셋이 {loc} 벽걸이에 {c} 걸려 있다.',
    '{a} 스태프가 {loc}를 {d} 뛰어 지나간다.',
    '{loc} 대기석에 {e} 이름표가 {b} 놓여 있다.',
    '{c} 카메라가 {loc} 구석에서 {a} 반짝인다.',
    '{loc} 안내판이 {d} 화살표로 {e} 방을 가리킨다.',
    '{a} 메이크업 거울 앞에 {b} 의자가 늘어서 있다.',
    '{loc} 복도 끝 {c} 사인펜 자국이 {d} 번져 있다.'
  ],
  stage: [
    '{a} {loc} 위 {b} 조명이 천천히 올라온다.',
    '{loc} 끝에서 {c} 잔향이 {d} 남아 있다.',
    '{e} 커튼 너머로 {a} 실루엣이 비친다.',
    '{b} 케이블이 {loc} 바닥을 {c} 가로지른다.',
    '{loc} 중앙에 {d} 마이크 스탠드가 {e} 서 있다.',
    '{a} 리허설 표시가 {loc} 바닥에 {b} 테이프로 붙어 있다.',
    '{c} 스모그가 {loc}를 {d} 부드럽게 덮는다.',
    '{loc} 객석은 {e} 어둠 속 {a} 실루엣만 보인다.',
    '{b} 피아노 건반이 {loc} 한쪽에서 {c} 반짝인다.',
    '{d} 발소리가 {loc}를 {a} 울린다.'
  ],
  cafe: [
    '{a} {loc} 카운터에 {b} 메뉴판이 늘어서 있다.',
    '{c} 원두 향이 {loc}를 {d} 채운다.',
    '{loc} 구석 {e} 플레이리스트가 {a} 흐른다.',
    '{b} 의자가 {loc} 테이블마다 {c} 살짝 어긋나 있다.',
    '{a} 유리잔에 {d} 얼음이 {e} 닿는 소리가 난다.',
    '{loc} 창밖 {b} 햇살이 {c} 커피 스팀과 섞인다.',
    '{d} 디저트 케이스가 {loc}에 {a} 빛을 받는다.',
    '{e} 바리스타가 {loc} 너머로 {b} 손을 흔든다.',
    '{c} 영수증이 {loc} 테이블에 {d} 날린다.',
    '{a} 라떼 아트가 {loc} 잔 위에 {e} 천천히 퍼진다.'
  ]
};

var SITUATION_SLOT_POOLS = {
  a:['낮게 깔린','익숙한','낯선','따끈한','차가운','은은한','희미한','선명한'],
  b:['긴장된','고요한','따뜻한','전율하는','무거운','가벼운','달큰한','서늘한'],
  c:['메트로놈','발라드 MR','빠른 비트','알람 벨','무전기 잡음','피아노 선율','군밤 향','종이 넘기는 소리'],
  d:['젖은','따뜻한','긴','짧은','흐릿한','날카로운','부드러운','거친'],
  e:['푸른','주황','보랏빛','흰','노란','붉은','은빛','보라']
};

var LOCATION_STAT_RULES = {
  practice_room:{ focus:[5,12], stress:[2,8] },
  dorm:{ stress:[-12,-6], condition:[6,14] },
  broadcast_station:{ focus:[3,9], team:[4,11] },
  stage:{ focus:[5,12], stress:[4,12] },
  cafe:{ stress:[-10,-4], team:[4,10] }
};

var DIALOGUE_OPEN_POOL = ['','"응!" ','"음…" ','"좋아." ','"잠깐." ','"봐봐." ','"진짜?" ','' ];
var DIALOGUE_CLOSE_POOL = [
  ' 그리고 작게 말을 잇는다.',' 주변을 한 번 더 살핀다.',' 잠시 멈춰 선다.',' 미소를 짓는다.',' 시선을 내린다.',
  ' 고개를 끄덕인다.',' 손끝을 꼼짝인다.',' 숨을 고른다.',' 프로듀서 쪽을 힐끗 본다.',' 어깨를 으쓱인다.'
];

var PERSONALITY_DIALOGUE_TEMPLATES = {
  BUBBLY:['텐션을 끌어올리며 ','신이 나서 ','웃음을 터뜨리며 ','에너지 넘치게 ',''],
  CALM:['차분히 ','이성적으로 ','천천히 ','무리 없이 ',''],
  TSUNDERE:['투덜대며 ','겉으로는 싫은 척하며 ','말끝을 흐리며 ','시선을 돌리며 ',''],
  GENTLE:['다정하게 ','부드럽게 ','배려하며 ','조심스레 ',''],
  PRANKSTER:['장난스레 ','살짝 농담하며 ','윙크하며 ','살짝 밀치며 ',''],
  SERIOUS:['진지하게 ','눈빛을 고이며 ','원칙을 되새기며 ','집중하며 ',''],
  PERFECTIONIST:['디테일을 짚으며 ','기준을 확인하며 ','살짝 불만스레 ','각을 세우며 ',''],
  SENSITIVE:['예민하게 ','작은 변화에 ','살짝 움찔하며 ','공기를 읽으며 ',''],
  OPTIMISTIC:['긍정적으로 ','밝게 ','앞을 향해 ','희망을 담아 ',''],
  SHY:['조심스레 ','작게 ','눈치를 보며 ','말을 아끼며 ',''],
  LEADER:['정리하며 ','흐름을 잡으며 ','결정을 내리며 ','손짓으로 ',''],
  FREE_SPIRIT:['틀을 비껴가며 ','자유롭게 ','즉흥적으로 ','충동적으로 ',''],
  COOL:['담담하게 ','감정을 숨기며 ','짧게 ','무심한 척 ',''],
  COMPETITIVE:['승부욕을 드러내며 ','이를 악물고 ','승부를 걸며 ','눈을 빛내며 ',''],
  DEPENDENT:['불안을 감추지 못하며 ','확인을 구하며 ','의지하며 ','망설이며 ',''],
  RELIABLE:['묵직하게 ','받쳐주듯 ','든든하게 ','맡기며 ',''],
  BLUNT:['직설적으로 ','돌려 말하지 않고 ','단도직입으로 ','핵심만 ',''],
  SENTIMENTAL:['감성적으로 ','목소리를 떨며 ','추억을 담아 ','눈시울이 붉어지며 ',''],
  LAID_BACK:['느긋하게 ','천천히 ','여유롭게 ','편하게 ',''],
  REBELLIOUS:['반항적으로 ','규칙을 비껴가며 ','쏘아붙이며 ','도발하며 ','']
};

var LOCATION_DIALOGUE_MID = {
  practice_room:[
    '{loc}에서 거울을 향해 포즈를 잡는다','{loc}에서 스트레칭을 이어간다','{loc}에서 동작을 천천히 되짚는다','{loc}에서 파트너와 호흡을 맞춘다',
    '{loc}에서 물병을 집어 든다','{loc}에서 음악에 맞춰 박자를 탄다','{loc}에서 무릎을 굽혀 쉰다','{loc}에서 프로듀서 쪽을 본다'
  ],
  dorm:[
    '{loc} 소파에 몸을 맡긴다','{loc} 창가에 앉아 하늘을 본다','{loc} 침대맡 스탠드를 끈다','{loc}에서 이불을 정돈한다',
    '{loc}에서 라면 봉지를 흔든다','{loc} 복도에서 슬리퍼 소리를 낸다','{loc}에서 핸드폰 화면을 본다','{loc}에서 하품을 참는다'
  ],
  broadcast_station:[
    '{loc}에서 대본을 넘긴다','{loc} 대기석에 앉아 호흡을 고른다','{loc}에서 마이크 높이를 가늠한다','{loc} 모니터를 응시한다',
    '{loc}에서 립밤을 바른다','{loc}에서 스태프에게 질문한다','{loc}에서 카드 석 순서를 확인한다','{loc}에서 거울에 이를 드러낸다'
  ],
  stage:[
    '{loc} 중앙에 선다','{loc} 끝에서 관객석을 바라본다','{loc}에서 마이크 스탠드를 잡는다','{loc}에서 조명을 느낀다',
    '{loc}에서 리허설 표시를 밟는다','{loc}에서 무대맨을 향해 고개를 끄덕인다','{loc}에서 커튼 뒤 숨을 고른다','{loc}에서 주먹을 쥐었다 폈다 한다'
  ],
  cafe:[
    '{loc}에서 메뉴를 훑는다','{loc} 테이블에 팔꿈치를 올린다','{loc}에서 빨대를 돌린다','{loc}에서 디저트 진열을 본다',
    '{loc}에서 팀원에게 컵을 건넨다','{loc}에서 영수증을 구겨 넣는다','{loc}에서 창밖 풍경을 본다','{loc}에서 설탕 패킷을 뜯는다'
  ]
};

/** 맵 이벤트 멤버 줄: (행동) 다음 줄 "대사" — 본문에 이름 없음 */
var MAP_EVENT_QUOTE_BY_PERSONALITY = {
  BUBBLY:['여기 분위기 좋다! 한 번 더 가보자!','텐션 올려서 끝까지 붙자!','지금 느낌 그대로 살리자, 같이!'],
  CALM:['천천히 호흡부터 맞추자. 괜찮아.','지금 흐름 유지하자. 흔들지 말자.','무리하지 말고 박자만 잡자.'],
  TSUNDERE:['…봐, 이번엔 제대로 해보자.','실수? 알아. 다시 하면 돼.','딱히 기대는 안 했는데, 나쁘지 않네.'],
  GENTLE:['괜찮아, 같이 맞추면 돼. 천천히.','내가 옆에서 맞춰줄게. 걱정 마.','여기만 살짝 손 보면 돼, 알지?'],
  PRANKSTER:['장난 아니야, 이번엔 진짜 간다?','분위기 살려서 가보자, 너무 진지~','웃음 참으면 더 어색해져, 진짜로.'],
  SERIOUS:['여기서 기준 다시 맞추자. 한 번에.','집중해. 지금 구간이 승부야.','말 줄이고 동작으로 보여주자.'],
  PERFECTIONIST:['디테일 하나만 더 잡자. 여기.','각도 아직 아쉬워. 한 번 더.','대충 넘기지 말고 여기부터 다시.'],
  SENSITIVE:['방금 공기 바뀐 것 같아… 느껴져?','예민해지기 쉬운 구간이야. 천천히.','괜찮다고 말하기 전에 호흡부터.'],
  OPTIMISTIC:['여기까지 잘 왔어! 이어가자!','넘어져도 다시 세우면 돼, 같이!','한 흐름만 더 붙여보자, 끝까지!'],
  SHY:['저… 저도 다시 해볼게요. 조금만요.','부끄럽지만… 이번엔 말할게요.','옆분이랑 호흡 맞춰볼게요. 천천히.'],
  LEADER:['정리하고 한 번 더 가자. 내가 앞에 설게.','순서만 잡으면 돼. 따라와.','지금 헷갈리는 부분만 딱 짚자.'],
  FREE_SPIRIT:['틀에 안 맞춰도 돼, 우리 호흡으로.','느낌 온다, 그대로 가자.','즉흥으로 한 번 가볼까? 재밌잖아.'],
  COOL:['감정 빼고 동작만 맞추자.','굳이 말 안 해도 알지? 한 번 더.','말 대신 박자로 답하자. 지금.'],
  COMPETITIVE:['여기서 지면 안 돼. 한 번 더.','끝까지 붙자, 빠지지 말고.','더 세게. 여기서 승부야.'],
  DEPENDENT:['옆에서 같이 맞춰줄게… 잠깐만.','눈만 마주쳐 줘도 힘이 나. 진짜로.','이렇게 하면 돼? 알려줘. 한 번만.'],
  RELIABLE:['내가 받쳐줄 테니까. 뒤는 걱정 마.','네 파트 내가 맞출게. 흔들리지 마.','믿고 한 번 더 밀어봐. 내가 있어.'],
  BLUNT:['지금은 솔직히 여기가 어긋났어.','돌려 말하면 끝없어. 여기 고쳐.','감으로 넘기지 말고 여기부터.'],
  SENTIMENTAL:['마음까지 같이 맞춰보자… 여기서.','이 순간 놓치기 아까운데, 천천히.','말 안 해도 전해지게 해 보자.'],
  LAID_BACK:['급할 거 없어. 호흡만. 여유.','천천히, 그래도 리듬은 잡자.','어깨 내려놓고 그다음에 박자.'],
  REBELLIOUS:['규칙보다 느낌으로 한 번 더.','시키는 대로만 하기엔 아깝잖아.','눈치 보지 말고 우리 색으로 가자.']
};

function createRng(seed){
  if(seed == null || seed === undefined) return function(){ return Math.random(); };
  var s = Number(seed) >>> 0;
  return function(){
    s += 0x6D2B79F5;
    var t = Math.imul(s ^ s >>> 15, 1 | s);
    t ^= t + Math.imul(t ^ t >>> 7, 61 | t);
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}

function shuffleArray(arr, rng){
  rng = rng || Math.random;
  var a = arr.slice();
  for(var i=a.length-1;i>0;i--){
    var j = Math.floor(rng() * (i+1));
    var t = a[i]; a[i] = a[j]; a[j] = t;
  }
  return a;
}

function pick(arr, rng){
  rng = rng || Math.random;
  if(!arr || !arr.length) return '';
  return arr[Math.floor(rng() * arr.length)];
}

function normalizePersonalityCode(code){
  var c = String(code || '').trim().toUpperCase();
  if(c && IDOL_PERSONALITY_META[c]) return c;
  return 'CALM';
}

function personalityLabelFromCode(code){
  var c = normalizePersonalityCode(code);
  var m = IDOL_PERSONALITY_META[c];
  return m ? m.shortLabel : '차분';
}

function fallbackPersonalityFromPickOrder(po){
  var o = IDOL_PERSONALITY_ORDER;
  if(!o || !o.length) return 'CALM';
  var n = (Number(po) || 1) - 1;
  var i = ((n % o.length) + o.length) % o.length;
  return o[i];
}

function getMembersForMapEvent(members){
  if(members && members.length) return members.map(enrichMapMember);
  var list = typeof collectRosterFromDom === 'function' ? collectRosterFromDom() : [];
  if(!list.length && typeof __initialRoster !== 'undefined' && __initialRoster && __initialRoster.length){
    list = __initialRoster.map(function(m){
      var card = document.querySelector('.mcard[data-tid="'+String(m.traineeId)+'"]');
      var pc = card ? (card.getAttribute('data-personality-code')||'').trim() : '';
      var name = card ? (((card.querySelector('.cname')||{}).textContent||'').trim()) : '';
      var pick = card ? (parseInt((card.querySelector('.cpick')||{}).textContent,10)||1) : 1;
      return { traineeId:m.traineeId, name:name||'연습생', pickOrder:pick, personalityCode:pc||null };
    });
  }
  return list.map(enrichMapMember);
}

function enrichMapMember(m){
  var code = (m.personalityCode && String(m.personalityCode).trim()) ? String(m.personalityCode).trim().toUpperCase() : '';
  if(!code) code = fallbackPersonalityFromPickOrder(m.pickOrder);
  code = normalizePersonalityCode(code);
  return {
    traineeId:m.traineeId,
    name:m.name || '연습생',
    pickOrder:m.pickOrder || 999,
    personalityCode:code,
    personalityLabel:personalityLabelFromCode(code)
  };
}

function fillSituationTemplate(tpl, location, rng){
  var loc = LOCATION_KO_NAME[location] || '장소';
  var s = tpl.replace(/\{loc\}/g, loc);
  return s.replace(/\{(\w+)\}/g, function(_, key){
    var arr = SITUATION_SLOT_POOLS[key];
    if(!arr || !arr.length) return '';
    return arr[Math.floor(rng() * arr.length)];
  });
}

function pickSituationLine(location, rng){
  var pool = LOCATION_SITUATION_POOLS[location];
  if(!pool || !pool.length) return fillSituationTemplate('{a} 이곳에 {b} 기운이 감돈다.', location, rng);
  var last = window.__lastSituationIndexByLocation[location];
  var idx = 0;
  for(var g=0; g<32; g++){
    idx = Math.floor(rng() * pool.length);
    if(pool.length < 2 || idx !== last) break;
  }
  window.__lastSituationIndexByLocation[location] = idx;
  return fillSituationTemplate(pool[idx], location, rng);
}

function rollStatDeltasFromRules(location, rng){
  var rules = LOCATION_STAT_RULES[location];
  var out = {};
  if(!rules) return out;
  Object.keys(rules).forEach(function(k){
    var pair = rules[k];
    if(!pair || pair.length < 2) return;
    var v = Math.round(pair[0] + rng() * (pair[1] - pair[0]));
    if(v !== 0) out[k] = v;
  });
  return out;
}

function buildDialogueLine(member, location, rng){
  var code = normalizePersonalityCode(member.personalityCode);
  var midPool = LOCATION_DIALOGUE_MID[location] || LOCATION_DIALOGUE_MID.practice_room;
  var loc = LOCATION_KO_NAME[location] || '';
  var actionLine = pick(midPool, rng).replace(/\{loc\}/g, loc);
  var quotes = MAP_EVENT_QUOTE_BY_PERSONALITY[code] || MAP_EVENT_QUOTE_BY_PERSONALITY.CALM;
  var quote = pick(quotes, rng);
  return '(' + actionLine + ')\n"' + quote + '"';
}

/**
 * @param {string} location practice_room | dorm | broadcast_station | stage | cafe
 * @param {Array<{traineeId,name,pickOrder,personalityCode}>} [members]
 * @param {number|string} [seed] 재현용 시드(생략 시 Math.random)
 * @returns {{situation:string, characterLines:Array, statDeltas:Object, location:string}}
 */
function generateEvent(location, members, seed){
  var rng = createRng(seed);
  var locKey = String(location || '').trim();
  if(!LOCATION_STAT_RULES[locKey]) return null;
  var mems = getMembersForMapEvent(members);
  if(!mems.length) mems = [{ traineeId:null, name:'연습생', pickOrder:1, personalityCode:'CALM', personalityLabel:'차분' }];
  var situation = pickSituationLine(locKey, rng);
  var characterLines = mems.map(function(m){
    return {
      name:m.name,
      personality:m.personalityLabel || personalityLabelFromCode(m.personalityCode),
      text:buildDialogueLine(m, locKey, rng),
      traineeId:m.traineeId
    };
  });
  characterLines = shuffleArray(characterLines, rng);
  var statDeltas = rollStatDeltasFromRules(locKey, rng);
  return { situation:situation, characterLines:characterLines, statDeltas:statDeltas, location:locKey };
}

window.generateEvent = generateEvent;
window.getMembersForMapEvent = getMembersForMapEvent;
window.generateSituationHint = generateSituationHint;
window.showChatFeedbackLog = showChatFeedbackLog;

function applyLocationStatDeltas(deltas){
  if(!deltas) return;
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  var b = window.__mapEventBarBonus;
  if(deltas.focus != null) b.focus = (Number(b.focus) || 0) + Number(deltas.focus);
  if(deltas.stress != null) b.stress = (Number(b.stress) || 0) + Number(deltas.stress);
  if(deltas.team != null) b.team = (Number(b.team) || 0) + Number(deltas.team);
  if(deltas.condition != null) b.condition = (Number(b.condition) || 0) + Number(deltas.condition);
}

/** 맵 이벤트 직후 컨디션 바 옆 +10 / -5 플로팅 (디자인 시스템 톤) */
function flashLocationStatDeltas(deltas){
  if(!deltas) return;
  function spawn(barKey, val){
    if(val == null || val === 0 || !isFinite(Number(val))) return;
    var n = Number(val);
    var bar = document.querySelector('.status-bar[data-key="' + barKey + '"]');
    if(!bar) return;
    var el = document.createElement('span');
    el.className = 'condition-bar-delta-float ' + (n > 0 ? 'condition-bar-delta-float--up' : 'condition-bar-delta-float--down');
    el.setAttribute('aria-hidden', 'true');
    el.textContent = (n > 0 ? '+' : '') + n;
    bar.appendChild(el);
    window.setTimeout(function(){ try{ el.remove(); }catch(e){} }, 920);
  }
  if(deltas.focus != null) spawn('focus', deltas.focus);
  if(deltas.stress != null) spawn('stress', deltas.stress);
  if(deltas.condition != null) spawn('condition', deltas.condition);
  if(deltas.team != null) spawn('team', deltas.team);
}

/**
 * 채팅 로그 하단에만 붙는 내용 추가 시: 사용자가 위로 스크롤해 읽는 중이면 scroll 유지, 하단 근처만 자동 스크롤
 */
function withGameChatScrollPreserved(run){
  var log = document.getElementById('gameChatLog');
  if(!log || typeof run !== 'function'){
    if(typeof run === 'function') run();
    return;
  }
  var st = log.scrollTop;
  var sh = log.scrollHeight;
  var ch = log.clientHeight;
  var nearBottom = (sh - ch - st) < 120;
  run();
  if(nearBottom) log.scrollTop = log.scrollHeight;
  else log.scrollTop = st;
}

function formatLocationStatToast(deltas){
  if(!deltas) return '';
  var parts = [];
  if(deltas.focus) parts.push('집중도 ' + (deltas.focus > 0 ? '+' : '') + deltas.focus);
  if(deltas.stress) parts.push('스트레스 ' + (deltas.stress > 0 ? '+' : '') + deltas.stress);
  if(deltas.team) parts.push('팀워크 ' + (deltas.team > 0 ? '+' : '') + deltas.team);
  if(deltas.condition) parts.push('컨디션 ' + (deltas.condition > 0 ? '+' : '') + deltas.condition);
  return parts.join(' · ');
}

function getDefaultIdolSpeaker(){
  var card = document.querySelector('.mcard');
  if(!card) return { name: '연습생', personality: '팀원', traineeId: null };
  var cn = card.querySelector('.cname');
  var name = (cn && cn.textContent) ? String(cn.textContent).trim() : '연습생';
  var tid = card.getAttribute('data-tid');
  return { name: name, personality: '팀원', traineeId: tid != null ? tid : null };
}

function appendLocationEventToChat(situation, characterLines, hintPack){
  var log = document.getElementById('gameChatLog');
  if(!log) return;
  var sp = getDefaultIdolSpeaker();
  var lines = (characterLines || []).map(function(L){
    var tid = L && L.traineeId != null ? L.traineeId : sp.traineeId;
    return {
      name: (L && L.name != null && String(L.name).length) ? L.name : sp.name,
      personality: (L && L.personality != null && String(L.personality).length) ? L.personality : sp.personality,
      text: L && L.text,
      traineeId: tid
    };
  });
  lines = typeof filterDialogueLinesNotEliminated === 'function' ? filterDialogueLinesNotEliminated(lines) : lines;
  var sitFull = String(situation || '');
  if(hintPack && hintPack.hintLine){
    sitFull = sitFull + (sitFull ? '\n\n※ ' : '※ ') + hintPack.hintLine;
  }
  withGameChatScrollPreserved(function(){
    if(situation || hintPack){
      var s = document.createElement('div');
      s.className = 'chat-bubble chat-bubble--npc chat-bubble--system';
      s.setAttribute('data-location-event-msg', '1');
      s.innerHTML = '<div class="chat-bubble-label">[상황]</div><div class="chat-bubble-text"></div>';
      s.setAttribute('data-raw-text', String(sitFull || ''));
      ensureBubbleNeon(s, '');
      log.appendChild(s);
      startTypewriterForBubble(s);
    }
    if(hintPack && hintPack.coachLine){
      var c = document.createElement('div');
      c.className = 'chat-bubble chat-bubble--npc chat-bubble--system';
      c.setAttribute('data-location-event-msg', '1');
      c.setAttribute('data-coach-hint', '1');
      c.innerHTML = '<div class="chat-bubble-label">[방향 제시]</div><div class="chat-bubble-text"></div>';
      var ct = c.querySelector('.chat-bubble-text');
      if(ct) ct.textContent = String(hintPack.coachLine || '');
      log.appendChild(c);
    }
    if(lines.length){
      var lab = document.createElement('div');
      lab.className = 'chat-section-label';
      lab.setAttribute('data-location-event-msg', '1');
      lab.textContent = '[대사]';
      log.appendChild(lab);
      var batch = appendCharacterResponseBubbles(lines, true);
      lines.forEach(function(_, i){
        if(batch[i]) batch[i].setAttribute('data-location-event-msg', '1');
      });
      scheduleStaggerForElements(batch);
    }
  });
}

function appendLocationEventFooter(){
  var log = document.getElementById('gameChatLog');
  if(!log) return;
  document.querySelectorAll('[data-location-event-footer="1"]').forEach(function(n){ try{ n.remove(); }catch(e){} });
  withGameChatScrollPreserved(function(){
    var div = document.createElement('div');
    div.className = 'chat-bubble chat-bubble--npc chat-bubble--system location-event-footer';
    div.setAttribute('data-location-event-footer', '1');
    div.innerHTML = ''
      + '<div class="chat-bubble-label">[안내]</div>'
      + '<div class="chat-bubble-text">장소 이벤트가 반영되었습니다. 훈련 화면에서 계속 진행할 수 있어요.</div>'
      + '<div class="location-event-footer__actions">'
      + '<button type="button" class="location-event-footer__btn location-event-footer__btn--primary" onclick="dismissLocationEventFooter(this)">훈련 화면 계속</button>'
      + '<button type="button" class="location-event-footer__btn location-event-footer__btn--ghost" onclick="dismissLocationEventFooterToMap(this)">맵으로</button>'
      + '</div>';
    log.appendChild(div);
  });
}

function dismissLocationEventFooter(btn){
  var el = btn && btn.closest ? btn.closest('[data-location-event-footer]') : null;
  if(el) try{ el.remove(); }catch(e){}
  if(typeof setGameUiMode === 'function') setGameUiMode('app');
  try{
    var inp = document.getElementById('gameChatInput');
    if(inp && !inp.disabled){
      if(typeof inp.focus === 'function'){
        try{ inp.focus({ preventScroll: true }); }
        catch(e2){ inp.focus(); }
      }
    }
  }catch(e){}
}

function dismissLocationEventFooterToMap(btn){
  var el = btn && btn.closest ? btn.closest('[data-location-event-footer]') : null;
  if(el) try{ el.remove(); }catch(e){}
  if(typeof setGameUiMode === 'function') setGameUiMode('map');
}

/**
 * @param {string} location practice_room | dorm | broadcast_station | stage | cafe
 */
function handleLocationEvent(location, members){
  var ev = typeof generateEvent === 'function' ? generateEvent(location, members) : null;
  if(!ev){
    try{ if(window.__NDX_DEBUG__) console.warn('[handleLocationEvent] unknown location or generateEvent failed:', location); }catch(e){}
    return;
  }
  window.gameUi = window.gameUi || { mode: 'app', selectedLocation: null };
  window.gameUi.selectedLocation = location;
  applyLocationStatDeltas(ev.statDeltas);
  try{
    if(typeof __initialRoster !== 'undefined' && __initialRoster && __initialRoster.length){
      updateConditionBarsFromRoster(__initialRoster);
    }
  }catch(e){}
  try{ flashLocationStatDeltas(ev.statDeltas); }catch(e){}

  var toastMsg = formatLocationStatToast(ev.statDeltas);
  try{
    if(toastMsg && typeof window.showToast === 'function') window.showToast('컨디션 반영 · ' + toastMsg, 'ok');
  }catch(e){}

  if(typeof setGameUiMode === 'function') setGameUiMode('app');

  var hintPack = null;
  try{
    var stForHint = typeof getConditionForGoals === 'function' ? getConditionForGoals() : null;
    if(stForHint) hintPack = generateSituationHint(stForHint);
  }catch(eH){}
  appendLocationEventToChat(ev.situation, ev.characterLines, hintPack);

  var n = (ev.characterLines && ev.characterLines.length) ? ev.characterLines.length : 0;
  var delay = 1100 + n * 550 + 900;
  if(window.__locationFooterTimer) clearTimeout(window.__locationFooterTimer);
  window.__locationFooterTimer = setTimeout(function(){
    window.__locationFooterTimer = null;
    appendLocationEventFooter();
  }, delay);

  try{
    document.dispatchEvent(new CustomEvent('gameMap:locationEvent', { bubbles: true, detail: { location: location, event: ev } }));
  }catch(e){}
}

/* ══════════════════════════════════
   채팅 응답: 패널은 열지 않고 대기 (상단 「다음」에서 표시)
══════════════════════════════════ */
function statKeyFromKorean(name){
  var m={'보컬':'v','댄스':'d','스타':'s','멘탈':'m','팀웍':'t'};
  return m[String(name||'')]||'';
}
function escMiniHtml(s){
  return String(s==null?'':s).replace(/[&<>"']/g,function(ch){
    return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch];
  });
}
function flashStatOnTraineeCard(traineeId, key, delta, displayName){
  if(traineeId==null||!key||delta==null||delta===0)return;
  var tidStr=String(traineeId);
  var card=document.querySelector('.mcard[data-tid="'+tidStr+'"]');
  if(!card){
    var want=String(displayName||'').trim();
    if(want){
      var cards=document.querySelectorAll('.mcard');
      for(var ci=0;ci<cards.length;ci++){
        var c=cards[ci];
        var cn=c.querySelector('.cname');
        var nm=cn?String(cn.textContent||'').trim():'';
        if(nm===want){ card=c; break; }
      }
    }
  }
  if(!card)return;
  if(card.classList.contains('mcard--eliminated')) return;
  var keyToKo={v:'보컬',d:'댄스',s:'스타',m:'멘탈',t:'팀웍'};
  var lbl=keyToKo[key]||key;
  var isUp=delta>0;
  var pickEl=card.querySelector('.cpick');
  var pickNum=(pickEl&&pickEl.textContent)?String(pickEl.textContent).trim():'';
  var strip=card.querySelector('[data-mcard-stat-strip]');
  if(strip){
    var nudge=document.createElement('div');
    nudge.className='mcard-stat-nudge'+(isUp?'':' mcard-stat-nudge--down');
    var who=displayName?'<span class="mcard-stat-nudge__who">'+escMiniHtml(displayName)+'</span>':'';
    nudge.innerHTML='<span class="mcard-stat-nudge__pick">'+(pickNum?pickNum+'번':'')+'</span>'
      +who
      +'<span class="mcard-stat-nudge__badge">'+(isUp?'▲ +':'▼ ')+Math.abs(memberDisplayDeltaFromRaw(delta))+'</span>'
      +'<span class="mcard-stat-nudge__lbl">'+lbl+'</span>'
      +'<span class="mcard-stat-nudge__fx">✨</span>';
    strip.appendChild(nudge);
    setTimeout(function(){ try{ nudge.remove(); }catch(e){} },2800);
  }
  var valEl=card.querySelector('.sval[data-key="'+key+'"]');
  var row=valEl?valEl.closest('.srow'):null;
  if(row&&valEl){
    row.style.position='relative';
    row.classList.add('sup');
    var bdg=document.createElement('span');
    bdg.className='sup-badge'+(isUp?'':' dn');
    bdg.textContent=(isUp?'▲ +':'▼ ')+Math.abs(memberDisplayDeltaFromRaw(delta));
    valEl.insertAdjacentElement('afterend',bdg);
    setTimeout(function(){
      try{
        row.classList.remove('sup');
        bdg.remove();
      }catch(e){}
    },2400);
  }
  card.classList.add('mcard--stat-pulse','boosted');
  setTimeout(function(){ try{ card.classList.remove('mcard--stat-pulse','boosted'); }catch(e){} },900);
}
/** 채팅 응답 직후: 로스터 숫자·바·케미 갱신 + 턴 스탯·미니게임 페널티 플래시 */
function applyChatRosterHud(data){
  if(!data)return;
  try{ applyFanLossConditionBonus(data); }catch(e){}
  try{ applyFanGainStressRelief(data); }catch(e){}
  try{ applyMiniGameFailConditionBonus(data); }catch(e){}
  try{ applyMiniGameSuccessConditionBonus(data); }catch(e){}
  try{ if(data.updatedRoster) updateStats(data.updatedRoster); }catch(e){}
  try{
    if(data.chemistry){
      currentChemistry=data.chemistry;
      renderChemistryPanel(data.chemistry);
    }
  }catch(e){}
  var sk=statKeyFromKorean(data.statName);
  if(data.traineeId!=null && sk && data.delta!=null && typeof isTraineeEliminatedId==='function' && !isTraineeEliminatedId(data.traineeId)){
    flashStatOnTraineeCard(data.traineeId, sk, data.delta, data.traineeName);
  }
  if(data.miniGamePenalty){
    var mp=data.miniGamePenalty;
    var k2=statKeyFromKorean(mp.statName);
    if(mp.traineeId!=null && k2 && mp.delta!=null && typeof isTraineeEliminatedId==='function' && !isTraineeEliminatedId(mp.traineeId)){
      flashStatOnTraineeCard(mp.traineeId, k2, mp.delta, mp.traineeName);
    }
  }
}

function applyAfterChatResponse(data){
  if(!data) return;
  try{
    console.log("choice prediction", {
      predictedKey: data.predictedKey,
      confidence: data.predictionConfidence,
      resolverType: data.resolverType,
      usedFallback: data.usedFallback
    });
    console.debug("choice prediction", {
      predictedKey: data.predictedKey,
      confidence: data.predictionConfidence,
      resolverType: data.resolverType,
      usedFallback: data.usedFallback
    });
  }catch(e){}
  var noEffect = (data.resolvedKey === 'NONE' || data.chatNoEffect === true);
  if(noEffect){
    try{ revertGameChatMiniTurnCounter(); }catch(e0){}
    nextPhaseVal=data.nextPhase;
    currentPhase=data.nextPhase || currentPhase;
    persistResumeState(currentPhase);
    updateRosterStatusMapFromResult(data);
    try{ applyChatRosterHud(data); }catch(e){}
    var utNone = window._lastUserChat;
    var turnNone = null;
    try{
      if(utNone) turnNone = applyChatSimulationAfterServerResponse(data, utNone);
    }catch(eSim0){}
    try{
      applyMiniGameFailTeamworkPenaltyAfterSim(data);
    }catch(eTw0){}
    try{
      if(!turnNone || !turnNone.aiLine){
        appendCoachSimBubble('훈련 지시로는 인식되지 않았어요. 대신 말투·의도로 팀 반응이 반영됐는지 옆 로그와 「효과」를 확인해 보세요.');
      }
    }catch(e1){}
    try{
      if(typeof showToast === 'function'){
        showToast('서버 훈련 키워드는 없었지만, 채팅 의도로 스트레스·팀워크 등이 바뀔 수 있어요. 턴 로그를 확인해 보세요.', 'ok', 4000);
      }
    }catch(e2){}
    try{ scheduleServerAiSituationDialogue(data); }catch(eDlg0){}
    window._pendingTurnResult=data;
    try{
      skipDialogueStagger();
    }catch(eSk){}
    try{
      if(window.__afterChatShowResultTimer){
        clearTimeout(window.__afterChatShowResultTimer);
        window.__afterChatShowResultTimer=null;
      }
      window.__afterChatShowResultTimer=setTimeout(function(){
        window.__afterChatShowResultTimer=null;
        try{
          openTurnResultOverlayFromPending();
        }catch(eOv){}
      },0);
    }catch(eOv2){}
    try{ if(typeof refreshTodayGoals === 'function') refreshTodayGoals(); }catch(e3){}
    return;
  }

  window.__gameChatCooldownUntil = Date.now() + GAME_CHAT_COOLDOWN_MS;

  nextPhaseVal=data.nextPhase;
  currentPhase=data.nextPhase || currentPhase;
  persistResumeState(currentPhase);
  updateRosterStatusMapFromResult(data);
  try{ applyChatRosterHud(data); }catch(e){}
  try{
    var ut = window._lastUserChat;
    if(ut) applyChatSimulationAfterServerResponse(data, ut);
  }catch(eSim){}
  try{
    applyMiniGameFailTeamworkPenaltyAfterSim(data);
  }catch(eTw){}
  // TODAY'S GOAL: 팬 목표(턴 누적) 업데이트 (서버 연결 어려우면 여기만 교체)
  try{
    if(typeof updateTodayGoalFansDelta === 'function'){
      updateTodayGoalFansDelta(Number(data && data.fanDelta) || 0);
    }
  }catch(e){}
  try{
    if(data && data.miniGamePenalty && typeof isTraineeEliminatedId==='function' && !isTraineeEliminatedId(data.miniGamePenalty.traineeId)){
      var mp=data.miniGamePenalty;
      showToast('미니게임 실패 · '+mp.pickOrder+'번 '+mp.traineeName+' '+mp.statName+' '+mp.delta, 'warn');
    }
  }catch(e){}
  try{ scheduleServerAiSituationDialogue(data); }catch(eDlg){}
  window._pendingTurnResult=data;

  // 채팅 입력 후: 지문/대사를 즉시 전부 펼치고 결과 오버레이도 즉시 표시
  try{
    skipDialogueStagger();
  }catch(e){}
  try{
    if(window.__afterChatShowResultTimer){
      clearTimeout(window.__afterChatShowResultTimer);
      window.__afterChatShowResultTimer=null;
    }
    var showDelay=0;
    window.__afterChatShowResultTimer=setTimeout(function(){
      window.__afterChatShowResultTimer=null;
      try{
        // 결과 오버레이 표시(기존 "다음" 흐름과 동일)
        openTurnResultOverlayFromPending();
      }catch(e){}
    },showDelay);
  }catch(e){}

  // TODAY'S GOAL: 현재 수치로 목표 체크 갱신
  try{ if(typeof refreshTodayGoals === 'function') refreshTodayGoals(); }catch(e){}
}

function populateResultOverlayDom(data){
  var hadMini=!!window.__resultHadMiniGame;
  var mainElim = typeof isTraineeEliminatedId === 'function' && data && isTraineeEliminatedId(data.traineeId);
  var rawMp = data && data.miniGamePenalty;
  var penElim = rawMp && typeof isTraineeEliminatedId === 'function' && isTraineeEliminatedId(rawMp.traineeId);
  var effectiveMp = (rawMp && !penElim) ? rawMp : null;

  var mgBox=document.getElementById('res-minigame-box');
  var mgTitle=document.getElementById('res-minigame-title');
  var mgDesc=document.getElementById('res-minigame-desc');
  var penBox=document.getElementById('res-penalty-stat-box');
  if(mgBox){
    if(hadMini){
      mgBox.style.display='';
      if(effectiveMp){
        if(mgTitle) mgTitle.textContent='미니게임 실패';
        if(mgDesc){
          var mp0=effectiveMp;
          mgDesc.textContent=mp0.pickOrder+'번 '+mp0.traineeName+' — '+mp0.statName+'이(가) '+mp0.delta+' 추가 페널티가 적용되었습니다.';
        }
      }else if(data && data.miniGameFailed){
        if(mgTitle) mgTitle.textContent='미니게임 실패';
        if(mgDesc) mgDesc.textContent='탈락한 멤버는 페널티 대상에서 제외됩니다. 추가 스탯 감소는 적용되지 않았습니다.';
      }else{
        if(mgTitle) mgTitle.textContent='미니게임 성공';
        var dTrain=mainElim ? 0 : Number(data.delta||0);
        var tn=data.traineeName||'해당 멤버';
        var sn=data.statName||'스탯';
        if(mgDesc) mgDesc.textContent='미니게임을 통과했습니다. 훈련 효과로 '+tn+'의 '+sn+'이(가) '+(dTrain>=0?'+':'')+dTrain+' 변화했습니다.';
      }
    }else{
      mgBox.style.display='none';
      if(mgTitle) mgTitle.textContent='미니게임';
      if(mgDesc) mgDesc.textContent='';
    }
  }
  if(penBox){
    if(effectiveMp){
      var mp=effectiveMp;
      penBox.style.display='';
      var psn=document.getElementById('res-penalty-sname');
      if(psn) psn.textContent=mp.statName;
      var pwho=document.getElementById('res-penalty-who');
      if(pwho) pwho.textContent=mp.pickOrder+'번 '+mp.traineeName;
      document.getElementById('res-penalty-bef').textContent=mp.beforeVal;
      document.getElementById('res-penalty-aft').textContent=mp.afterVal;
      var pd=document.getElementById('res-penalty-delta');
      var pUp=mp.delta>=0;
      if(pd){
        pd.textContent=(pUp?'▲ +':'▼ ')+Math.abs(mp.delta)+' '+mp.statName;
        pd.className='rdelta '+(pUp?'up':'dn');
      }
    }else{
      penBox.style.display='none';
    }
  }

  var av=document.getElementById('res-av');
  if(av){
    var tid = data && data.traineeId != null ? String(data.traineeId) : '';
    var p = (tid && window.imgMap && window.imgMap[tid]) ? String(window.imgMap[tid]) : '';
    // 문자열 조립(innerHTML) 대신 DOM으로 안전하게 렌더 (JS 파싱 에러 방지)
    av.innerHTML='';
    if(p){
      var src = (p.startsWith('http') ? p : (CTX + p));
      var img=document.createElement('img');
      img.src=src;
      img.alt='';
      img.onerror=function(){
        try{
          av.innerHTML='<div class="rav-ph"><i class="fas fa-user"></i></div>';
        }catch(e){}
      };
      av.appendChild(img);
    }else{
      av.innerHTML='<div class="rav-ph"><i class="fas fa-user"></i></div>';
    }
  }

  document.getElementById('res-name').textContent=data.traineeName;
  document.getElementById('res-action').textContent=window._lastUserChat || selText || '선택 효과가 적용되었습니다.';
  var resNarr=document.getElementById('res-result-narration');
  if(resNarr){
    var rn=data.resultNarration||'';
    if(/응답을 파싱할 수 없습니다|API 키가 설정되지|AI 응답 중 오류|Gemini API 오류/.test(rn)) rn='';
    resNarr.textContent=rn;
  }
  var evBox=document.getElementById('res-event-triggered-box');
  var primBox=document.getElementById('res-primary-stat-box');
  if(mainElim){
    if(evBox) evBox.style.display='none';
    if(primBox) primBox.style.display='none';
  }else{
    if(evBox) evBox.style.display='';
    if(primBox) primBox.style.display='';
    var ev=buildEventCopy(data);
    document.getElementById('res-event-title').textContent='이벤트 발생 · '+ev.title;
    var catPrefix=data.trainingCategory?('키워드 분류: '+data.trainingCategory+' · '):'';
    document.getElementById('res-event-desc').textContent=catPrefix+ev.desc;
    document.getElementById('res-sname').textContent=data.statName;
    document.getElementById('res-bef').textContent=data.beforeVal;
    document.getElementById('res-aft').textContent=data.afterVal;

    var dEl=document.getElementById('res-delta');
    var isUp=data.delta>=0;
    dEl.textContent=(isUp?'▲ +':'▼ ')+Math.abs(data.delta)+' '+data.statName;
    dEl.className='rdelta '+(isUp?'up':'dn');
  }

  var fanTitle=document.getElementById('res-fan-title');
  var fanDesc=document.getElementById('res-fan-desc');
  var fanBreak=document.getElementById('res-fan-breakdown');
  var fanTotal=document.getElementById('res-fan-total');
  var fanEvent=document.getElementById('res-fan-event');

  if(fanTitle) fanTitle.textContent=data.fanReactionTitle || '팬 반응';
  if(fanDesc) fanDesc.textContent=data.fanReactionDesc || '이번 선택에 대한 팬 반응이 반영됐습니다.';
  if(fanBreak) fanBreak.textContent='국내 '+(data.coreFanDelta>0?'+':'')+(data.coreFanDelta||0)+' · 해외 '+(data.casualFanDelta>0?'+':'')+(data.casualFanDelta||0);

  if(fanTotal){
    var fdelta=data.fanDelta||0;
    fanTotal.textContent='팬 '+(fdelta>0?'+':'')+fdelta;
    fanTotal.className='rfan-total'+(fdelta<0?' down':'');
  }

  if(fanEvent){
    if(data.unlockedEvent){
      fanEvent.style.display='block';
      var events=(data.unlockedEvent || '').split('||').filter(Boolean);
      fanEvent.innerHTML=events.map(function(ev){
        var parts=ev.split('|');
        var title=parts[0] || '';
        var desc=parts[1] || '';
        return ''
          + '<div class="fan-event-box">'
          +   '<div class="fan-event-title">✦ '+title+'</div>'
          +   '<div class="fan-event-desc">'+desc+'</div>'
          + '</div>';
      }).join('');
    }else{
      fanEvent.style.display='none';
      fanEvent.innerHTML='';
    }
  }

  var statusBox=document.getElementById('res-status-box');
  var statusChip=document.getElementById('res-status-chip');
  var statusDesc=document.getElementById('res-status-desc');
  var statusMeta=document.getElementById('res-status-meta');
  var statusTexts=[];
  if(data.activeStatusLabel && (data.activeStatusTurnsLeft || 0) > 0){
    statusTexts.push(data.activeStatusLabel+' · '+data.activeStatusTurnsLeft+'턴');
  }
  if(data.statusEffectText){
    statusTexts.push(data.statusEffectText);
  }
  if(statusBox && statusChip && statusDesc && statusMeta){
    if(statusTexts.length){
      statusBox.classList.add('show');
      statusChip.textContent=(data.activeStatusLabel || '추가 효과');
      statusDesc.textContent=data.activeStatusDesc || data.statusEffectText || '이번 턴에 상태 효과가 반영되었습니다.';
      statusMeta.textContent=statusTexts.join(' ');
    }else{
      statusBox.classList.remove('show');
      statusChip.textContent='상태 없음';
      statusDesc.textContent='';
      statusMeta.textContent='';
    }
  }

  document.getElementById('res-next').textContent='▸ NEXT  '+phaseLabel(data.nextPhase);
  window.__resultHadMiniGame=false;
}

function runTurnResultEffects(data){
  var mainElim = typeof isTraineeEliminatedId === 'function' && data && isTraineeEliminatedId(data.traineeId);
  var rawMp = data && data.miniGamePenalty;
  var penElim = rawMp && typeof isTraineeEliminatedId === 'function' && isTraineeEliminatedId(rawMp.traineeId);
  var effectiveMp = (rawMp && !penElim) ? rawMp : null;

  var deltaVal = mainElim ? 0 : (data.delta || 0);
  if(!mainElim){
    triggerPeak(deltaVal, data.statName);
    updateCombo(deltaVal);
    animateHudMoney(deltaVal);
  }
  syncFanDetail(data.totalFans, data.coreFans, data.casualFans, data.lightFans);
  animateHudFans(data.totalFans, data.fanDelta||0);

  window._bid = mainElim ? null : data.traineeId;
  window._bdelta = mainElim ? null : data.delta;
  window._bstat = mainElim ? null : data.statName;
  window._penaltyBid=null;
  window._penaltyDelta=null;
  window._penaltyStat=null;
  if(effectiveMp){
    window._penaltyBid=effectiveMp.traineeId;
    window._penaltyDelta=effectiveMp.delta;
    window._penaltyStat=effectiveMp.statName;
  }
  window._broster=data.updatedRoster;
  window._fanDelta=data.fanDelta||0;
  // 팬 손실·미니게임 실패 컨디션 보너스는 applyChatRosterHud에서 이미 반영됨. 여기서 다시 더하면 스트레스가 이중으로 쌓여 100%로 잘못 판정됨.
  updateStats(data.updatedRoster);
  renderChemistryPanel(data.chemistry || currentChemistry);
}

/** 상단 「다음」: 서버에 반영된 턴 결과 패널 표시 → 하단 「다음으로」로 다음 화면 */
function openTurnResultOverlayFromPending(){
  var data=window._pendingTurnResult;
  if(!data)return false;
  window._pendingTurnResult=null;
  window.__resultHadMiniGame=!!window._pendingTurnHadMiniGame;
  window._pendingTurnHadMiniGame=false;

  populateResultOverlayDom(data);
  runTurnResultEffects(data);

  window._resultOverlayMode='turn';
  document.getElementById('rov').classList.add('show');
  try{ document.getElementById('rov').focus(); }catch(eFocus){}
  var card=document.querySelector('.rcard');
  if(card){
    card.style.boxShadow='0 0 0 1px rgba(251,191,36,.24),0 0 40px rgba(251,191,36,.16),0 24px 80px rgba(0,0,0,.42)';
  }
  setTimeout(function(){
    var rc=document.querySelector('.rcard');
    if(rc){var r=rc.getBoundingClientRect();burstAt(r.left+r.width/2,r.top+r.height/2,20);}
  },350);
  return true;
}

(function bindTurnResultOverlayDismiss(){
  document.addEventListener('click', function(evt){
    var rov=document.getElementById('rov');
    if(!rov || !rov.classList.contains('show')) return;
    if(evt.target === rov) goNext();
  });
  document.addEventListener('keydown', function(evt){
    var rov=document.getElementById('rov');
    if(!rov || !rov.classList.contains('show')) return;
    if(evt.key === 'Enter' || evt.key === 'Escape'){
      evt.preventDefault();
      goNext();
    }
  });
})();

function buildEventCopy(data){
  var tone=data.delta>=0?'긍정':'변수';
  var byStat={
    '보컬':['하모니가 살아나며 집중력이 올라갔습니다','짧은 훈련이었지만 보컬 라인의 감이 빠르게 올라왔습니다.'],
    '댄스':['동선 호흡이 맞으면서 퍼포먼스가 안정됐습니다','선택의 영향으로 안무 완성도가 눈에 띄게 정리됐습니다.'],
    '스타':['카메라 무드가 살아나며 존재감이 커졌습니다','작은 선택이지만 무대 장악력이 확실히 올라왔습니다.'],
    '멘탈':['긴장이 정리되며 컨디션이 안정됐습니다','분위기를 다잡으면서 흔들리던 감정선이 정리됐습니다.'],
    '팀웍':['멤버 간 호흡이 살아나며 팀 밸런스가 안정됐습니다','짧은 대화 하나가 팀 분위기를 다시 묶어냈습니다.']
  };
  var downByStat={
    '보컬':['호흡이 잠시 흔들렸습니다','집중은 했지만 목 상태가 다소 예민해졌습니다.'],
    '댄스':['합이 잠시 어긋났습니다','강하게 밀어붙인 만큼 체력 소모가 커졌습니다.'],
    '스타':['무대 텐션이 살짝 흔들렸습니다','시선 처리가 잠깐 무너졌지만 다음 선택으로 만회 가능합니다.'],
    '멘탈':['부담이 쌓이며 집중이 흔들렸습니다','피로감이 올라오면서 판단이 무거워졌습니다.'],
    '팀웍':['의견 조율 과정에서 잠시 텐션이 갈렸습니다','좋은 방향이었지만 호흡은 조금 흔들렸습니다.']
  };
  var src=(data.delta>=0?byStat:downByStat)[data.statName]||['변수가 발생했습니다','선택의 여파가 다음 턴 분위기에 반영됩니다.'];
  return {title: src[0], desc: src[1] + ' ' + data.traineeName + '의 ' + data.statName + '이(가) ' + (data.delta>=0? '상승' : '하락') + '했습니다.'};
}

function phaseLabel(p){
  if(p==='FINISHED') return '🎉 DEBUT DAY !';
  if(p==='DEBUT_EVAL') return '최종 데뷔 평가';
  if(!p||p.indexOf('DAY')!==0) return p;
  var us=p.indexOf('_');
  var n=parseInt(us>3 ? p.substring(3,us) : p.substring(3),10);
  if(!isFinite(n)||n<=0) return p;
  var month=Math.floor((n-1)/28)+1;
  var dayInMonth=((n-1)%28)+1;
  var part=(us>-1?p.substring(us+1):'');
  var isMorning=(part==='MORNING');
  var week=Math.floor((((n-1)%28))/7)+1;
  var dayNames=['월요일','화요일','수요일','목요일','금요일','토요일','일요일'];
  var dayName=dayNames[(n-1)%7];
  return month+'개월 '+week+'주차 '+dayName+' '+(isMorning?'☀️ 아침':'🌙 저녁');
}

function memberRawTotalFromRosterMember(m){
  if(!m) return 0;
  return (Number(m.vocal)||0) + (Number(m.dance)||0) + (Number(m.star)||0)
    + (Number(m.mental)||0) + (Number(m.teamwork)||0);
}

function memberDisplayStatFromRaw(raw){
  return Number(raw)||0;
}

function memberDisplayDeltaFromRaw(delta){
  return Number(delta)||0;
}

function memberDisplayTotalFromRosterMember(m){
  return memberRawTotalFromRosterMember(m);
}

function memberRawStatFromValueEl(el){
  if(!el) return 0;
  var rawAttr = parseInt(el.getAttribute('data-raw'), 10);
  if(isFinite(rawAttr)) return rawAttr;
  var displayVal = parseInt(String(el.textContent || '').replace(/[^0-9\-]/g,''), 10);
  if(!isFinite(displayVal)) return 0;
  return displayVal;
}

function memberRawTotalFromCard(card){
  if(!card) return 0;
  var totalEl=card.querySelector('.ctotal-num');
  var sumAttr=totalEl ? parseInt(totalEl.getAttribute('data-total-sum'),10) : NaN;
  if(isFinite(sumAttr)) return sumAttr;
  var sum=0;
  ['v','d','s','m','t'].forEach(function(key){
    var valEl=card.querySelector('.sval[data-key="'+key+'"]');
    sum += memberRawStatFromValueEl(valEl);
  });
  return sum;
}

function updateStats(roster){
  var skMap={v:'vocal',d:'dance',s:'star',m:'mental',t:'teamwork'};
  roster.forEach(function(m){
    var card=document.querySelector('.mcard[data-tid="'+m.traineeId+'"]');
    if(!card)return;
    if(card.classList.contains('mcard--eliminated')) return;
    /* total 업데이트 */
    var rawTot=memberRawTotalFromRosterMember(m);
    var tot=memberDisplayTotalFromRosterMember(m);
    var totEl=card.querySelector('.ctotal-num');
    if(totEl){
      var fromTot=parseInt(totEl.textContent.replace(/[^0-9\-]/g,''))||0;
      totEl.setAttribute('data-total-sum', String(rawTot));
      animateNumber(totEl,fromTot,tot,420);
    }
    Object.keys(skMap).forEach(function(k){
      var rawVal = Number(m[skMap[k]]) || 0;
      var displayVal = memberDisplayStatFromRaw(rawVal);
      var bar=card.querySelector('.sfill--'+k);
      var valEl=card.querySelector('.sval[data-key="'+k+'"]');
      if(bar){bar.style.transition='width .7s cubic-bezier(.23,1,.46,1)';bar.style.width=displayVal+'%';}
      if(valEl){
        var from=parseInt(valEl.textContent.replace(/[^0-9\-]/g,''))||0;
        valEl.setAttribute('data-raw', String(rawVal));
        animateNumber(valEl,from,displayVal,420);
      }
    });
    renderMemberStatus(card, m);
  });

  // 스탯 변화에 맞춰 사이드 패널(집중도/스트레스/팀워크)도 함께 갱신
  try{ updateConditionBarsFromRoster(roster); }catch(e){}
}

function clampPct(n){
  n = Math.round(Number(n)||0);
  if(n < 0) n = 0;
  if(n > 100) n = 100;
  return n;
}

function avgStat(roster, key){
  if(!roster || !roster.length) return 0;
  var sum=0, cnt=0;
  roster.forEach(function(m){
    if(!m) return;
    var v = Number(m[key]);
    if(!isFinite(v)) return;
    sum += v;
    cnt++;
  });
  return cnt ? (sum / cnt) : 0;
}

/** 로스터에 해당 키의 유효한 숫자가 몇 개인지(평균 0과 '데이터 없음' 구분용) */
function countFiniteRosterStat(roster, key){
  if(!roster || !roster.length) return 0;
  var n = 0;
  roster.forEach(function(m){
    if(!m) return;
    var v = Number(m[key]);
    if(isFinite(v)) n++;
  });
  return n;
}

// 집중도·스트레스·팀워크·컨디션(생존) — 로스터 기반 베이스 + __mapEventBarBonus
// - 집중도: (보컬+댄스+스타) 평균 → 0~100%
// - 스트레스: 멘탈 역산(압박)
// - 팀워크: 팀웍 평균 → 0~100%
// - 컨디션: 멘탈·체력(보댄스) 가중 생존 지표 (탈락 판정은 이 베이스+보너스)
function computeConditionPcts(roster){
  if(!roster || !roster.length){
    var w = window.__ndxLastConditionBasePcts;
    if(w && typeof w.stress === 'number'){
      return {
        focus: w.focus,
        stress: w.stress,
        team: w.team,
        condition: typeof w.condition === 'number' ? w.condition : 65
      };
    }
    return { focus: 50, stress: 25, team: 55, condition: 68 };
  }
  var avV = avgStat(roster,'vocal');
  var avD = avgStat(roster,'dance');
  var avS = avgStat(roster,'star');
  var avM = avgStat(roster,'mental');
  var avT = avgStat(roster,'teamwork');
  var mentalN = countFiniteRosterStat(roster, 'mental');

  var focus = clampPct(((avV + avD + avS) / 300) * 100);
  var stress;
  if(mentalN === 0){
    var w0 = window.__ndxLastConditionBasePcts;
    stress = (w0 && typeof w0.stress === 'number') ? clampPct(w0.stress) : 25;
  }else{
    stress = clampPct(100 - avM);
  }
  var team = clampPct(avT);
  var phys = (avV + avD + avS) / 3;
  var condition = clampPct(
    28 + (mentalN === 0 ? 40 : (avM / 100) * 42) + Math.min(30, (phys / 100) * 30)
  );
  var out = { focus: focus, stress: stress, team: team, condition: condition };
  window.__ndxLastConditionBasePcts = {
    focus: out.focus,
    stress: out.stress,
    team: out.team,
    condition: out.condition
  };
  return out;
}

function setStatusBar(key, pct){
  var bar=document.querySelector('.status-bar[data-key="'+key+'"]');
  if(!bar) return;
  pct = clampPct(pct);
  bar.setAttribute('data-pct', String(pct));
  var fill=bar.querySelector('.status-fill');
  var val=bar.querySelector('.status-bar__val');
  if(fill){
    fill.style.transition='width .7s cubic-bezier(.23,1,.46,1)';
    fill.style.width=pct+'%';
  }
  if(val) val.textContent=pct+'%';
}

function ndxEliminatedStorageKey(){
  return 'ndx_run_eliminated_' + String(RUN_ID || '');
}

function loadEliminatedTraineeIds(){
  try{
    var raw = localStorage.getItem(ndxEliminatedStorageKey());
    if(!raw) return [];
    var a = JSON.parse(raw);
    if(!Array.isArray(a)) return [];
    return a.map(function(x){ return String(x); });
  }catch(e){ return []; }
}

/** 탈락 처리된 연습생이면 true (로컬 스토리지 + 카드 DOM) */
function isTraineeEliminatedId(tid){
  if(tid == null || tid === '') return false;
  try{
    var s = String(tid);
    var ids = loadEliminatedTraineeIds();
    if(ids && ids.indexOf(s) >= 0) return true;
    var card = document.querySelector('.mcard[data-tid="'+s+'"]');
    if(card && card.classList.contains('mcard--eliminated')) return true;
  }catch(e){}
  return false;
}

/** API/맵 이벤트 대사 줄에서 탈락자 제거 */
function filterDialogueLinesNotEliminated(lines){
  if(!lines || !lines.length) return [];
  if(typeof isTraineeEliminatedId !== 'function') return lines.slice();
  return lines.filter(function(line){
    var tid = line && (line.traineeId != null ? line.traineeId : line.traineeID);
    if(tid == null || tid === '') return true;
    return !isTraineeEliminatedId(tid);
  });
}

/** 채팅 로그에 이미 렌더된 탈락자 아이돌 말풍선 제거(+ 고아 [대사] 라벨) */
function removeEliminatedDialogueFromChatLog(){
  var log = document.getElementById('gameChatLog');
  if(!log || typeof isTraineeEliminatedId !== 'function') return;
  log.querySelectorAll('.chat-bubble--idol[data-trainee-id]').forEach(function(bub){
    var tid = bub.getAttribute('data-trainee-id');
    if(tid != null && tid !== '' && isTraineeEliminatedId(tid)){
      var prev = bub.previousElementSibling;
      bub.remove();
      if(prev && prev.classList && prev.classList.contains('chat-section-label')){
        var t = (prev.textContent || '').replace(/\s/g, '');
        if(t === '[대사]'){
          var next = prev.nextElementSibling;
          var hasNextIdol = next && next.classList && next.classList.contains('chat-bubble--idol');
          if(!hasNextIdol) try{ prev.remove(); }catch(e){}
        }
      }
    }
  });
}
window.removeEliminatedDialogueFromChatLog = removeEliminatedDialogueFromChatLog;

function saveEliminatedTraineeIds(ids){
  try{
    localStorage.setItem(ndxEliminatedStorageKey(), JSON.stringify(ids || []));
  }catch(e){}
}

/** 탈락 ID를 URL에 맞춰 두어 이후 새로고침·공유 시 세션과 일치시킴. 전체 리로드는 하지 않음(채팅 POST가 세션에 반영). */
(function ndxSyncEliminatedIdsToServerOnce(){
  try{
    if(typeof RUN_ID === 'undefined' || !RUN_ID) return;
    if(typeof loadEliminatedTraineeIds !== 'function') return;
    var ids = loadEliminatedTraineeIds();
    if(!ids || !ids.length) return;
    var q = window.location.search || '';
    if(/(?:^|[?&])eliminatedTids=/.test(q)) return;
    var u = new URL(window.location.href);
    u.searchParams.set('eliminatedTids', ids.join(','));
    if(u.toString() === window.location.href) return;
    var path = u.pathname + u.search + u.hash;
    if(typeof history !== 'undefined' && history.replaceState){
      history.replaceState(null, '', path);
    }else{
      window.location.replace(u.toString());
    }
  }catch(e){}
})();

function persistEliminationStateFromMembers(){
  var mem = window.__ndxConditionMembers || [];
  var ids = [];
  mem.forEach(function(m){
    if(m && !m.alive) ids.push(String(m.id));
  });
  saveEliminatedTraineeIds(ids);
}

function applyPersistedEliminations(){
  if(!window.__ndxConditionMembers || !window.__ndxConditionMembers.length) return;
  var ids = loadEliminatedTraineeIds();
  if(!ids.length) return;
  ids.forEach(function(id){
    window.__ndxConditionMembers.forEach(function(m){
      if(String(m.id) === String(id)) m.alive = false;
    });
    if(window.NdxConditionPanelView && typeof window.NdxConditionPanelView.applyEliminationToMcard === 'function'){
      window.NdxConditionPanelView.applyEliminationToMcard(id);
    }
  });
  try{
    if(typeof removeEliminatedDialogueFromChatLog === 'function') removeEliminatedDialogueFromChatLog();
  }catch(e){}
}

/** 컨디션이 탈락선 초과로 회복되면 탈락 래치 해제 */
function ndxConditionElimThreshold(){
  var L = window.NdxConditionLogic;
  return L && L.CONDITION_ELIM_THRESHOLD_PCT != null ? L.CONDITION_ELIM_THRESHOLD_PCT : 19;
}

function syncEliminationLatchFromCondition(conditionPct){
  var gate = window.__ndxConditionLatch || (window.__ndxConditionLatch = { condElimActive: false });
  var c = Number(conditionPct) || 0;
  if(c > ndxConditionElimThreshold()) gate.condElimActive = false;
}

function hydrateEliminationLatchOnce(conditionPct){
  if(window.__ndxEliminationLatchHydrated) return;
  window.__ndxEliminationLatchHydrated = true;
  var c = Number(conditionPct) || 0;
  var th = ndxConditionElimThreshold();
  var ids = loadEliminatedTraineeIds();
  if(c <= th && ids && ids.length > 0){
    var gate = window.__ndxConditionLatch || (window.__ndxConditionLatch = { condElimActive: false });
    gate.condElimActive = true;
  }
}

/**
 * 스트레스↔컨디션·집중·팀워크 교차 효과 — 보너스에 누적하지 않고, 현재 스냅샷에서만 가산(갱신 N번 호출돼도 1번분만 반영)
 * @returns {{ addStress:number, dCond:number, dFocus:number }}
 */
function computeVitalityCrossLayer(p, bonus, opts){
  opts = opts || {};
  if(opts.skipCross) return { addStress: 0, dCond: 0, dFocus: 0 };
  var L = window.NdxConditionLogic;
  var instab = L && L.TEAMWORK_INSTABILITY_PCT != null ? L.TEAMWORK_INSTABILITY_PCT : 20;
  var baseS = clampPct(p.stress + (Number(bonus.stress) || 0));
  var team = clampPct(p.team + (Number(bonus.team) || 0));
  var cond = clampPct(p.condition + (Number(bonus.condition) || 0));
  var addStress = 0;
  if(cond <= 30) addStress += 1;
  else if(cond <= 40) addStress += 1;
  if(team <= instab) addStress += 2;
  var stressAfter = clampPct(baseS + addStress);
  var dCond = 0;
  var dFocus = 0;
  if(stressAfter >= 90){
    dCond -= 1;
    dFocus -= 1;
  }else if(stressAfter >= 80){
    dCond -= 1;
    dFocus -= 1;
  }else if(stressAfter >= 70){
    dCond -= 1;
    dFocus -= 1;
  }
  return { addStress: addStress, dCond: dCond, dFocus: dFocus };
}

function getTraineeTotalStatFromDom(traineeId){
  var card = document.querySelector('.mcard[data-tid="' + String(traineeId) + '"]');
  if(!card) return 0;
  function gv(k){
    var el = card.querySelector('.sval[data-key="'+k+'"]');
    return memberRawStatFromValueEl(el);
  }
  return gv('v') + gv('d') + gv('s') + gv('m') + gv('t');
}

function initNdxConditionMembersIfNeeded(){
  if(window.__ndxConditionMembers && window.__ndxConditionMembers.length) return;
  window.__ndxConditionMembers = [];
  var cards = document.querySelectorAll('.mcard[data-tid]');
  var n = 0;
  cards.forEach(function(card){
    if(n >= 4) return;
    var id = card.getAttribute('data-tid');
    var nameEl = card.querySelector('.cname');
    var name = nameEl ? String(nameEl.textContent || '').trim() : ('멤버 ' + (n + 1));
    var pickEl = card.querySelector('.cpick');
    var po = parseInt(pickEl && pickEl.textContent, 10);
    if(!isFinite(po)) po = 0;
    window.__ndxConditionMembers.push({ id: String(id), name: name, alive: true, pickOrder: po });
    n++;
  });
}

function processNdxConditionState(state){
  var logic = window.NdxConditionLogic;
  var view = window.NdxConditionPanelView;
  if(!logic || !view) return;

  var outcome = logic.checkGameState(state);
  if(outcome === 'STRESS_EXPLOSION'){
    triggerStressGameOver();
    return;
  }

  var gate = window.__ndxConditionLatch || (window.__ndxConditionLatch = { condElimActive: false });
  var elimTh = logic.CONDITION_ELIM_THRESHOLD_PCT != null ? logic.CONDITION_ELIM_THRESHOLD_PCT : 19;
  var condNow = logic.clampPct(state.condition);
  if(condNow > elimTh){
    gate.condElimActive = false;
  }else if(outcome === 'ELIMINATION' && condNow <= elimTh){
    if(!gate.condElimActive){
      gate.condElimActive = true;
      var eliminated =
        typeof logic.eliminateRandomAliveMember === 'function'
          ? logic.eliminateRandomAliveMember(state.members)
          : logic.eliminateLowestStatMember(state.members, getTraineeTotalStatFromDom);
      if(eliminated){
        view.applyEliminationToMcard(eliminated.id);
        var elimMsg =
          eliminated.name +
          ' 탈락 — 컨디션 ' +
          condNow +
          '% (기준 ' +
          elimTh +
          '% 이하). 무작위로 한 명이 나갔어요.';
        view.showEliminationBanner(elimMsg);
        try{
          if(typeof window.showToast === 'function'){
            window.showToast('멤버 탈락: 컨디션이 ' + elimTh + '% 이하로 너무 낮았어요', 'warn', 5200);
          }
        }catch(eT){}
        persistEliminationStateFromMembers();
        try{
          if(window.IdolSimStatusPresentation && typeof window.IdolSimStatusPresentation.appendLogLine === 'function'){
            window.IdolSimStatusPresentation.appendLogLine(
              '멤버 1명 탈락 (컨디션 ' + condNow + '% ≤ ' + elimTh + '%)'
            );
          }
        }catch(eLog){}
        try{
          if(window.IdolSimStatusPresentation && typeof window.IdolSimStatusPresentation.triggerEliminationEffect==='function'){
            window.IdolSimStatusPresentation.triggerEliminationEffect(eliminated.id, null, { skipDomAlter: true });
          }
        }catch(ePresElim){}
      }
    }
  }
}

function triggerStressGameOver(){
  if(window.__ndxStressGameOverTriggered) return;
  window.__ndxStressGameOverTriggered = true;
  try{
    if(typeof showToast === 'function'){
      showToast('스트레스 100% 도달 · 게임오버 연출이 시작됩니다.', 'warn', 2400);
    }
  }catch(eToast){}
  try{
    var ov = document.getElementById('ndxGameOverOverlay');
    if(ov){
      ov.classList.add('is-open');
      ov.setAttribute('aria-hidden', 'false');
      try{ document.body.classList.add('is-locked'); }catch(eLock){}
      startStressGameOverSequence();
      return;
    }
  }catch(eOverlay){}
  try{
    window.location.href = CTX + '/game/run/' + RUN_ID + '/roster';
  }catch(eMove){
    window.__ndxStressGameOverTriggered = false;
  }
}
function playStressGameOverBeep(step){
  try{
    var AC = window.AudioContext || window.webkitAudioContext;
    if(!AC) return;
    if(!window.__ndxAlertAudioCtx) window.__ndxAlertAudioCtx = new AC();
    var ctx = window.__ndxAlertAudioCtx;
    if(ctx.state === 'suspended' && typeof ctx.resume === 'function') ctx.resume();
    var osc = ctx.createOscillator();
    var gain = ctx.createGain();
    var now = ctx.currentTime;
    var freq = step <= 1 ? 260 : (step === 2 ? 320 : 380);
    osc.type = 'square';
    osc.frequency.setValueAtTime(freq, now);
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.12, now + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.22);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.24);
  }catch(eAudio){}
}
function setGameOverActionButtonsEnabled(enabled){
  var ids = ['ndxGameOverRosterBtn', 'ndxGameOverEndingBtn'];
  ids.forEach(function(id){
    var el = document.getElementById(id);
    if(!el) return;
    if(enabled){
      el.classList.remove('is-disabled');
      el.removeAttribute('aria-disabled');
    }else{
      el.classList.add('is-disabled');
      el.setAttribute('aria-disabled', 'true');
    }
  });
}
function startStressGameOverSequence(){
  var label = document.getElementById('ndxGameOverCountdown');
  if(window.__ndxGameOverTimer){
    clearInterval(window.__ndxGameOverTimer);
    window.__ndxGameOverTimer = null;
  }
  var left = 3;
  setGameOverActionButtonsEnabled(false);
  if(label) label.textContent = '팀 붕괴까지 ' + left + '초';
  playStressGameOverBeep(left);
  window.__ndxGameOverTimer = setInterval(function(){
    left -= 1;
    if(left > 0){
      if(label) label.textContent = '팀 붕괴까지 ' + left + '초';
      playStressGameOverBeep(left);
      return;
    }
    clearInterval(window.__ndxGameOverTimer);
    window.__ndxGameOverTimer = null;
    if(label) label.textContent = '팀이 무너졌습니다 · 다음 행동을 선택하세요';
    setGameOverActionButtonsEnabled(true);
    try{
      if(typeof showToast === 'function'){
        showToast('게임오버 정산 대기 완료 · 이동 경로를 선택하세요.', 'ok', 2200);
      }
    }catch(eToastReady){}
  }, 1000);
}

/** 탈락자(스토리지·DOM)는 컨디션 평균에서 제외 */
function filterRosterExcludingEliminated(roster){
  if(!roster || !roster.length) return roster || [];
  var eliminated = {};
  try{
    loadEliminatedTraineeIds().forEach(function(id){ eliminated[String(id)] = true; });
  }catch(e){}
  return roster.filter(function(m){
    if(!m || m.traineeId == null) return false;
    var id = String(m.traineeId);
    if(eliminated[id]) return false;
    try{
      var card = document.querySelector('.mcard[data-tid="'+id+'"]');
      if(card && card.classList.contains('mcard--eliminated')) return false;
    }catch(e2){}
    return true;
  });
}

/** 예전: 팀워크 30% 미만 보정. 현재는 일차 베이스 100% 시작이라 비활성화 */
function maybeBootstrapStartTeamworkBand(roster){
  void roster;
}

function updateConditionBarsFromRoster(roster){
  roster = filterRosterExcludingEliminated(roster);
  maybeBootstrapStartTeamworkBand(roster);
  var p = computeConditionPcts(roster);
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  var bonus = window.__mapEventBarBonus;
  /* 스트레스·팀워크 막대: 훈련 일차 베이스(스트레스 0→하루+1%, 팀워크 100→하루−0.5%) + 이벤트·채팅 보너스. 집중·컨디션은 로스터 기반 */
  var stressBase = ndxStressDailyBasePct();
  var teamBase = ndxTeamDailyBasePct();
  var pCross = { focus: p.focus, stress: stressBase, team: teamBase, condition: p.condition };
  var cross = computeVitalityCrossLayer(pCross, bonus);
  var stress = clampPct(stressBase + (Number(bonus.stress) || 0) + cross.addStress);

  var focus = clampPct(p.focus + (Number(bonus.focus) || 0) + cross.dFocus);
  var team = clampTeamWorkMeterPct(teamBase + (Number(bonus.team) || 0));
  var condition = clampPct(p.condition + (Number(bonus.condition) || 0) + cross.dCond);
  var progress = 0;
  try{
    if(typeof MONTH_PROGRESS_PCT === 'number'){
      progress = clampPct(typeof effectiveMonthProgressPct === 'function' ? effectiveMonthProgressPct() : MONTH_PROGRESS_PCT);
    }
  }catch(e){ progress = 0; }

  initNdxConditionMembersIfNeeded();
  applyPersistedEliminations();
  var members = window.__ndxConditionMembers || [];
  var state = {
    focus: focus,
    stress: stress,
    teamwork: team,
    condition: condition,
    progress: progress,
    members: members,
    conditionRosterCount: roster.length
  };

  hydrateEliminationLatchOnce(condition);
  syncEliminationLatchFromCondition(condition);
  processNdxConditionState(state);

  if(window.NdxConditionPanelView && typeof window.NdxConditionPanelView.render === 'function'){
    window.NdxConditionPanelView.render(state);
  }else{
    setStatusBar('focus', focus);
    setStatusBar('stress', stress);
    setStatusBar('condition', condition);
    setStatusBar('team', team);
    setStatusBar('progress', progress);
  }

  try{
    if(window.IdolSimStatusPresentation && typeof window.IdolSimStatusPresentation.updateStatusUI==='function'){
      window.IdolSimStatusPresentation.updateStatusUI(
        { stress: stress, condition: condition, focus: focus, teamwork: team },
        { skipBanner: false, skipGauges: false }
      );
    }
  }catch(ePres){}
}

/* ────────────────────────────────
   TODAY'S GOAL (오른쪽 패널)
   실제 값 연동 위치:
   - team/stress: computeConditionPcts(roster) + __mapEventBarBonus
   - fans delta: applyAfterChatResponse(data.fanDelta) 누적
──────────────────────────────── */
window.__todayGoal = window.__todayGoal || { fansDelta: 0, lastCompleted: {} };

function getRosterForGoals(){
  var r = [];
  try{
    r = (typeof collectRosterFromDom === 'function') ? collectRosterFromDom() : [];
  }catch(e){ r = []; }
  if(!r || !r.length){
    try{
      if(typeof __initialRoster !== 'undefined' && __initialRoster && __initialRoster.length) r = __initialRoster;
    }catch(e2){}
  }
  // 상단 바·채팅 시뮬은 updateConditionBarsFromRoster와 동일하게 탈락자 제외 후 평균 (0스탯 탈락자가 스트레스만 100으로 튀는 버그 방지)
  try{
    if(typeof filterRosterExcludingEliminated === 'function') r = filterRosterExcludingEliminated(r || []);
  }catch(e3){}
  return r || [];
}

function getConditionForGoals(){
  var roster = getRosterForGoals();
  var p =
    typeof computeConditionPcts === 'function'
      ? computeConditionPcts(roster && roster.length ? roster : [])
      : { focus: 0, stress: 0, team: 0, condition: 68 };
  var bonus = window.__mapEventBarBonus || {};
  var stressBase = typeof ndxStressDailyBasePct === 'function' ? ndxStressDailyBasePct() : 0;
  var teamBase = typeof ndxTeamDailyBasePct === 'function' ? ndxTeamDailyBasePct() : 100;
  var pCross = { focus: p.focus, stress: stressBase, team: teamBase, condition: p.condition };
  var cross =
    typeof computeVitalityCrossLayer === 'function'
      ? computeVitalityCrossLayer(pCross, bonus)
      : { addStress: 0, dCond: 0, dFocus: 0 };
  return {
    team: typeof clampTeamWorkMeterPct === 'function'
      ? clampTeamWorkMeterPct(teamBase + (Number(bonus.team) || 0))
      : clampPct(teamBase + (Number(bonus.team) || 0)),
    stress: clampPct(stressBase + (Number(bonus.stress) || 0) + cross.addStress),
    condition: clampPct(p.condition + (Number(bonus.condition) || 0) + cross.dCond),
    focus: clampPct(p.focus + (Number(bonus.focus) || 0) + cross.dFocus)
  };
}

function updateTodayGoalFansDelta(delta){
  delta = Number(delta) || 0;
  if(!isFinite(delta) || delta === 0) return;
  window.__todayGoal = window.__todayGoal || { fansDelta: 0, lastCompleted: {} };
  window.__todayGoal.fansDelta = (Number(window.__todayGoal.fansDelta) || 0) + delta;
}

function setGoalCompleted(el, done){
  if(!el) return;
  var was = el.classList.contains('completed');
  el.classList.toggle('completed', !!done);
  el.setAttribute('aria-checked', done ? 'true' : 'false');
  var icon = el.querySelector('.goal-check i');
  if(icon){
    icon.className = done ? 'fa-solid fa-check' : 'fa-solid fa-circle';
  }
  if(done && !was){
    el.classList.remove('goal-pop');
    void el.offsetWidth;
    el.classList.add('goal-pop');
    setTimeout(function(){ try{ el.classList.remove('goal-pop'); }catch(e){} }, 520);
  }
}

function refreshTodayGoals(){
  var card = document.getElementById('todayGoalCard');
  if(!card) return;
  var rec = document.getElementById('goalRecommendation');
  var cond = getConditionForGoals();
  var fansDelta = (window.__todayGoal && isFinite(Number(window.__todayGoal.fansDelta))) ? Number(window.__todayGoal.fansDelta) : 0;

  card.querySelectorAll('.goal-item[data-goal]').forEach(function(item){
    var key = item.getAttribute('data-goal');
    var thr = Number(item.getAttribute('data-threshold')) || 0;
    var nowEl = item.querySelector('[data-goal-now="'+key+'"]');
    var now = 0;
    var done = false;

    if(key === 'teamwork'){
      now = Number(cond.team) || 0;
      done = now >= thr;
      if(nowEl) nowEl.textContent = now + '%';
    }else if(key === 'stress'){
      now = Number(cond.stress) || 0;
      done = now <= thr;
      if(nowEl) nowEl.textContent = now + '%';
    }else if(key === 'fans'){
      now = fansDelta;
      done = now >= thr;
      if(nowEl) nowEl.textContent = (now >= 0 ? '+' : '') + now;
    }
    setGoalCompleted(item, done);
  });

  if(rec){
    // 추천 문구 (더미 → 실제 연결 시 여기만 교체)
    var msg = '';
    if(cond.stress > 70) msg = '추천: 지금은 휴식이 필요합니다 (스트레스 관리 우선)';
    else if(cond.team < 40) msg = '추천: 팀워크를 올리는 액션(칭찬/케미)이 유리합니다';
    else if(fansDelta < 10) msg = '추천: 팬을 늘릴 수 있는 선택(긍정 흐름/콤보)을 노리세요';
    else msg = '추천: 목표 달성! 다음 턴은 성장 스탯을 선택해도 좋습니다';
    rec.textContent = msg;
  }
}

(function initTodayGoalCard(){
  function run(){
    try{ refreshTodayGoals(); }catch(e){}
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run);
  else run();
})();

function renderMemberStatus(card, member){
  if(!card) return;
  var host=card.querySelector('[data-status-inline="true"]');
  if(!host) return;

  var items=[];
  if(member && Array.isArray(member.statusEffects)){
    items=member.statusEffects.map(function(effect){
      if(!effect) return null;
      var effectLabel=effect.label != null ? String(effect.label).trim() : '';
      var effectTurns=effect.turnsLeft != null ? Number(effect.turnsLeft) : 0;
      if(!effectLabel) return null;
      return {
        label:effectLabel,
        desc:effect.desc != null ? String(effect.desc).trim() : '',
        turns:effectTurns > 0 ? effectTurns : 1,
        code:effect.code != null ? String(effect.code).trim().toUpperCase() : ''
      };
    }).filter(Boolean);
  }

  if(!items.length){
    var label=(member && member.statusLabel) ? String(member.statusLabel).trim() : '';
    var desc=(member && member.statusDesc) ? String(member.statusDesc).trim() : '';
    var turns=(member && typeof member.statusTurnsLeft !== 'undefined' && member.statusTurnsLeft !== null) ? Number(member.statusTurnsLeft) : 0;
    var code=(member && member.statusCode) ? String(member.statusCode).trim().toUpperCase() : '';
    if(label){
      items.push({label:label, desc:desc, turns:turns > 0 ? turns : 1, code:code});
    }
  }

  if(!items.length){
    host.innerHTML='';
    return;
  }

  var debuffCodes=['INJURY','BURNOUT','SLUMP'];
  var itemHtml=items.map(function(item){
    var typeClass=debuffCodes.indexOf(item.code) > -1 ? 'is-debuff' : 'is-buff';
    var descHtml=item.desc ? '<div class="member-status-popover__desc">'+escapeHtml(item.desc)+'</div>' : '';
    return ''
      + '<div class="member-status-popover__item '+typeClass+'">'
      + '  <div class="member-status-popover__label">'+escapeHtml(item.label)+'</div>'
      +      descHtml
      + '  <div class="member-status-popover__meta">'+item.turns+'턴 남음</div>'
      + '</div>';
  }).join('');

  var tid=String((member && member.traineeId) || card.getAttribute('data-tid') || '');
  host.innerHTML=''
    + '<button type="button" class="member-status-trigger is-active" data-status-trigger="true" data-tid="'+escapeHtml(tid)+'" data-status-count="'+items.length+'" aria-expanded="false" aria-label="상태 효과 보기">+'
    + items.length
    + '</button>'
    + '<div class="member-status-popover" data-status-popover="true" data-tid="'+escapeHtml(tid)+'" hidden>'
    + '  <div class="member-status-popover__head">'
    + '    <strong>상태 효과</strong>'
    + '    <button type="button" class="member-status-popover__close" data-status-close="true" data-tid="'+escapeHtml(tid)+'"><i class="fas fa-xmark"></i></button>'
    + '  </div>'
    + '  <div class="member-status-popover__body">'+itemHtml+'</div>'
    + '</div>';
}

(function initMemberStatusBadges(){
  function run(){
    try{
      var roster = (typeof __initialRoster !== 'undefined' && Array.isArray(__initialRoster)) ? __initialRoster : [];
      roster.forEach(function(m){
        if(!m || m.traineeId == null) return;
        var card=document.querySelector('.mcard[data-tid="'+String(m.traineeId)+'"]');
        if(card) renderMemberStatus(card, m);
      });
    }catch(e){}
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run);
  else run();
})();

function closeAllMemberStatusPopovers(){
  document.querySelectorAll('[data-status-popover="true"]').forEach(function(pop){
    pop.hidden=true;
  });
  document.querySelectorAll('[data-status-trigger="true"]').forEach(function(btn){
    btn.setAttribute('aria-expanded','false');
    btn.classList.remove('is-open');
    var card=btn.closest ? btn.closest('.mcard') : null;
    if(card) card.classList.remove('is-status-open');
  });
}

function closeMemberStatusPopover(tid){
  if(typeof tid==='undefined' || tid===null || tid===''){
    closeAllMemberStatusPopovers();
    return;
  }
  var key=String(tid);
  document.querySelectorAll('[data-status-popover="true"][data-tid="'+cssEscapeValue(key)+'"]').forEach(function(pop){
    pop.hidden=true;
  });
  document.querySelectorAll('[data-status-trigger="true"][data-tid="'+cssEscapeValue(key)+'"]').forEach(function(btn){
    btn.setAttribute('aria-expanded','false');
    btn.classList.remove('is-open');
    var card=btn.closest ? btn.closest('.mcard') : null;
    if(card) card.classList.remove('is-status-open');
  });
}

function toggleMemberStatusPopover(evt, tid){
  if(evt){
    evt.preventDefault();
    evt.stopPropagation();
  }
  var key=String(tid||'');
  if(!key) return;
  var trigger=document.querySelector('[data-status-trigger="true"][data-tid="'+cssEscapeValue(key)+'"]');
  var pop=document.querySelector('[data-status-popover="true"][data-tid="'+cssEscapeValue(key)+'"]');
  if(!trigger || !pop) return;
  var willOpen=pop.hidden;
  closeAllMemberStatusPopovers();
  pop.hidden=!willOpen;
  trigger.setAttribute('aria-expanded', willOpen ? 'true' : 'false');
  trigger.classList.toggle('is-open', willOpen);
  var card=trigger.closest ? trigger.closest('.mcard') : null;
  if(card) card.classList.toggle('is-status-open', willOpen);
}

function escapeHtml(value){
  return String(value==null ? '' : value)
    .replace(/&/g,'&amp;')
    .replace(/</g,'&lt;')
    .replace(/>/g,'&gt;')
    .replace(/"/g,'&quot;')
    .replace(/'/g,'&#39;');
}

function cssEscapeValue(value){
  if(window.CSS && typeof window.CSS.escape === 'function') return window.CSS.escape(String(value));
  return String(value).replace(/([ #;?%&,.+*~\':"!^$\[\]()=>|\/@])/g,'\\$1');
}

(function initMemberStatusPopoverDismiss(){
  document.addEventListener('click', function(evt){
    var closeBtn=evt.target.closest ? evt.target.closest('[data-status-close="true"]') : null;
    if(closeBtn){
      evt.preventDefault();
      evt.stopPropagation();
      closeMemberStatusPopover(closeBtn.getAttribute('data-tid'));
      return;
    }
    var trigger=evt.target.closest ? evt.target.closest('[data-status-trigger="true"]') : null;
    if(trigger){
      toggleMemberStatusPopover(evt, trigger.getAttribute('data-tid'));
      return;
    }
    if(evt.target.closest && evt.target.closest('[data-status-inline="true"]')) return;
    closeAllMemberStatusPopovers();
  });
  document.addEventListener('keydown', function(evt){
    if(evt.key==='Escape') closeAllMemberStatusPopovers();
  });
})();

// 숫자 튀면서 올라가는 공용 함수
function animateNumber(el,from,to,duration){
  if(from===to){el.textContent=to;return;}
  var start=null;
  function step(ts){
    if(!start)start=ts;
    var p=Math.min(1,(ts-start)/duration);
    // easeOutQuad
    var eased=1-(1-p)*(1-p);
    var val=Math.round(from+(to-from)*eased);
    el.textContent=val;
    if(p<1)requestAnimationFrame(step);
  }
  requestAnimationFrame(step);
}

// HUD 머니 bump + 숫자 변경
function animateHudMoney(delta){
  if(!delta)return;
  try{
    var el=document.querySelector('.game-hud-item--money .game-hud-val');
    if(!el)return;
    var txt=el.textContent.replace(/[^0-9\-]/g,'');
    var cur=parseInt(txt)||0;
    var target=cur+delta;
    el.classList.remove('hud-bump');
    void el.offsetWidth;
    el.classList.add('hud-bump');
    var start=null;
    function step(ts){
      if(!start)start=ts;
      var p=Math.min(1,(ts-start)/480);
      var eased=1-(1-p)*(1-p);
      var v=Math.round(cur+(target-cur)*eased);
      el.textContent=v+' G';
      if(p<1)requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }catch(e){}
}

// BIG PEAK 연출 (큰 스탯 변화 시)
function triggerPeak(delta, statName){
  if(!delta)return;
  var big = Math.abs(delta) >= 8;
  if(!big)return;
  try{
    var ov=document.getElementById('peakOv');
    if(!ov)return;
    var lbl=document.getElementById('peakLabel');
    var det=document.getElementById('peakDetail');
    var isUp = delta > 0;
    if(lbl) lbl.textContent = isUp ? 'BIG UP!' : 'BIG DOWN';
    if(det) det.textContent = (isUp?'+':'')+Math.abs(memberDisplayDeltaFromRaw(delta))+' '+(statName || '');
    ov.classList.remove('show');
    void ov.offsetWidth;
    ov.classList.add('show');
    var scene=document.querySelector('.scene-area');
    if(scene){
      scene.classList.add('shake');
      setTimeout(function(){scene.classList.remove('shake');},600);
    }
    setTimeout(function(){ov.classList.remove('show');},720);
  }catch(e){}
}

// 연속 상승 COMBO
function updateCombo(delta){
  try{
    var key='ndx_combo_'+RUN_ID;
    var cur=parseInt(sessionStorage.getItem(key)||'0')||0;
    if(delta>0){cur++;} else {cur=0;}
    sessionStorage.setItem(key,cur);
    if(cur>=2){
      var el=document.getElementById('comboBanner');
      if(!el)return;
      el.textContent = cur + ' COMBO!';
      el.classList.remove('show');
      void el.offsetWidth;
      el.classList.add('show');
      setTimeout(function(){el.classList.remove('show');},1200);
    }
    // 콤보 기반 목표 업데이트
    var totalHeader=document.querySelector('.game-hud-item--money .game-hud-val');
    var curTotal=parseInt(totalHeader? totalHeader.textContent.replace(/[^0-9\-]/g,'') : '0')||0;
    updateGoals(curTotal, cur, nextPhaseVal);
  }catch(e){}
}

// 목표 진행도 업데이트
function updateGoals(currentTotal, comboCount, phase){
  try{
    // Goal 1: 팀 총합 220 이상 (팬 500명 달성 컨셉)
    var g1Target=220;
    var g1Pct=Math.max(0,Math.min(1,currentTotal/g1Target));
    var g1Bar=document.getElementById('goal1Bar');
    var g1Box=document.getElementById('goal1');
    if(g1Bar) g1Bar.style.width=(g1Pct*100)+'%';
    if(g1Box && g1Pct>=1){
      if(!g1Box.classList.contains('done')){
        g1Box.classList.add('done');
        showToast('목표 달성! 팬 500명 달성 완료.', 'ok');
      }
    }

    // Goal 2: 콤보 3 이상 (첫 공연 성공 컨셉)
    var g2Bar=document.getElementById('goal2Bar');
    var g2Box=document.getElementById('goal2');
    var g2Pct=Math.max(0,Math.min(1,(comboCount||0)/3));
    if(g2Bar) g2Bar.style.width=(g2Pct*100)+'%';
    if(g2Box && (comboCount||0)>=3){
      if(!g2Box.classList.contains('done')){
        g2Box.classList.add('done');
        showToast('첫 공연 성공! 콤보 3회 이상 달성.', 'ok');
      }
    }

    // Goal 3: 최종 평가 도달 (데뷔 준비 완료)
    var g3Bar=document.getElementById('goal3Bar');
    var g3Box=document.getElementById('goal3');
    var reachedFinal = phase==='DEBUT_EVAL' || phase==='FINISHED';
    if(g3Bar){
      var base = Math.max(1,Math.min(3,MONTH_NUM));
      g3Bar.style.width=(base/3)*100+'%';
    }
    if(g3Box && reachedFinal){
      if(!g3Box.classList.contains('done')){
        g3Box.classList.add('done');
        showToast('데뷔 준비 완료! 최종 평가에 도달했습니다.', 'ok');
      }
    }

    // Goal 4: 국내 팬 150+
    var g4Target=150;
    var g4Pct=Math.max(0,Math.min(1,(CURRENT_CORE_FANS||0)/g4Target));
    var g4Bar=document.getElementById('goal4Bar');
    var g4Box=document.getElementById('goal4');
    if(g4Bar) g4Bar.style.width=(g4Pct*100)+'%';
    if(g4Box && (CURRENT_CORE_FANS||0)>=g4Target){
      if(!g4Box.classList.contains('done')){
        g4Box.classList.add('done');
        showToast('목표 달성! 국내 팬 '+g4Target+'명 이상.', 'ok');
      }
    }

    // Goal 5: 라이브 랭킹 20위 이내 (0 = 미산정)
    var rk=typeof MY_LIVE_RANK==='number'?MY_LIVE_RANK:999;
    if(rk<=0) rk=999;
    var g5Pct=(rk<=20)?1:Math.max(0,Math.min(1,(45-Math.min(rk,45))/25));
    var g5Bar=document.getElementById('goal5Bar');
    var g5Box=document.getElementById('goal5');
    if(g5Bar) g5Bar.style.width=(g5Pct*100)+'%';
    if(g5Box && rk>0 && rk<=20){
      if(!g5Box.classList.contains('done')){
        g5Box.classList.add('done');
        showToast('목표 달성! 라이브 랭킹 상위 20위 안.', 'ok');
      }
    }

    // Goal 6: 팀 스탯 합 900+
    var teamSum=TEAM_TOTAL_STAT||0;
    try{
      if(typeof collectRosterFromDom==='function'){
        var rr=collectRosterFromDom();
        var s=0;
        rr.forEach(function(m){
          s+=(m.vocal||0)+(m.dance||0)+(m.star||0)+(m.mental||0)+(m.teamwork||0);
        });
        if(rr.length) teamSum=s;
      }
    }catch(e){}
    var g6Target=900;
    var g6Pct=Math.max(0,Math.min(1,teamSum/g6Target));
    var g6Bar=document.getElementById('goal6Bar');
    var g6Box=document.getElementById('goal6');
    if(g6Bar) g6Bar.style.width=(g6Pct*100)+'%';
    if(g6Box && teamSum>=g6Target){
      if(!g6Box.classList.contains('done')){
        g6Box.classList.add('done');
        showToast('목표 달성! 팀 스탯 합계 '+g6Target+' 이상.', 'ok');
      }
    }

    // Goal 7: 총 팬 1200+
    var g7Target=1200;
    var g7Pct=Math.max(0,Math.min(1,(CURRENT_TOTAL_FANS||0)/g7Target));
    var g7Bar=document.getElementById('goal7Bar');
    var g7Box=document.getElementById('goal7');
    if(g7Bar) g7Bar.style.width=(g7Pct*100)+'%';
    if(g7Box && (CURRENT_TOTAL_FANS||0)>=g7Target){
      if(!g7Box.classList.contains('done')){
        g7Box.classList.add('done');
        showToast('목표 달성! 총 팬 '+g7Target+'명 이상.', 'ok');
      }
    }

    // Goal 8: 케미 총 보너스 10%+
    var chemBonus=(typeof currentChemistry!=='undefined' && currentChemistry)?(currentChemistry.totalBonus||0):0;
    var g8Target=10;
    var g8Pct=Math.max(0,Math.min(1,chemBonus/g8Target));
    var g8Bar=document.getElementById('goal8Bar');
    var g8Box=document.getElementById('goal8');
    if(g8Bar) g8Bar.style.width=(g8Pct*100)+'%';
    if(g8Box && chemBonus>=g8Target){
      if(!g8Box.classList.contains('done')){
        g8Box.classList.add('done');
        showToast('목표 달성! 케미 총 보너스 '+g8Target+'% 이상.', 'ok');
      }
    }

    // Goal 9: 진행도 50%+ (2배 모드는 표시 진행도 기준)
    var progPct=(typeof MONTH_PROGRESS_PCT==='number' && typeof effectiveMonthProgressPct==='function')?effectiveMonthProgressPct():((typeof MONTH_PROGRESS_PCT==='number')?MONTH_PROGRESS_PCT:0);
    var g9Pct=Math.max(0,Math.min(1,progPct/50));
    var g9Bar=document.getElementById('goal9Bar');
    var g9Box=document.getElementById('goal9');
    if(g9Bar) g9Bar.style.width=(g9Pct*100)+'%';
    if(g9Box && progPct>=50){
      if(!g9Box.classList.contains('done')){
        g9Box.classList.add('done');
        showToast('목표 달성! 프로그램 진행도 50% 돌파.', 'ok');
      }
    }
  }catch(e){}
}

/** play-state JSON → 채팅 로그 인트로 HTML (gamestart.jsp와 동일 구조) */
function buildGameChatIntroHtmlFromPlayState(intro, eliminatedIds, sceneIdStr){
  var elim = {};
  if(eliminatedIds && eliminatedIds.length){
    eliminatedIds.forEach(function(id){ elim[String(id)] = true; });
  }
  var parts = [];
  var sit = intro && intro.situation ? String(intro.situation) : '';
  var sidAttr = sceneIdStr != null && String(sceneIdStr) !== '' ? ' data-scene-id="' + escHtml(String(sceneIdStr)) + '"' : '';
  if(sit){
    parts.push(
      '<div class="chat-bubble chat-bubble--npc chat-bubble--system" data-scene-intro="1"' + sidAttr + ' data-raw-text="' + escHtml(sit) + '">'
      + '<div class="chat-bubble-label">[상황]</div>'
      + '<div class="chat-bubble-text">' + escHtml(sit) + '</div></div>'
    );
  }
  var lines = intro && intro.lines ? intro.lines : [];
  var visibleLines = lines.filter(function(line){
    var tid = line && line.traineeId != null ? String(line.traineeId) : '';
    if(tid && elim[tid]) return false;
    return true;
  });
  if(visibleLines.length){
    parts.push('<div class="chat-section-label">[대사]</div>');
    visibleLines.forEach(function(line){
      var tid = line.traineeId != null ? String(line.traineeId) : '';
      var name = escHtml(line.name || '');
      var pers = escHtml(line.personalityLabel || '');
      var txt = escHtml(line.text || '');
      parts.push(
        '<div class="chat-bubble chat-bubble--npc chat-bubble--idol dialogue-stagger" data-trainee-id="' + escHtml(tid) + '">'
        + '<div class="chat-avatar"></div><div class="chat-bubble-body">'
        + '<div class="chat-bubble-label">' + name + (pers ? ' · ' + pers : '') + '</div>'
        + '<div class="chat-bubble-text">' + txt + '</div></div></div>'
      );
    });
  }
  return parts.join('');
}

function rosterJsonToUpdateStatsArray(roster){
  if(!roster || !roster.length) return [];
  return roster.map(function(m){
    return {
      traineeId: m.traineeId,
      vocal: m.vocal,
      dance: m.dance,
      star: m.star,
      mental: m.mental,
      teamwork: m.teamwork,
      statusCode: m.statusCode,
      statusLabel: m.statusLabel,
      statusDesc: m.statusDesc,
      statusTurnsLeft: m.statusTurnsLeft
    };
  });
}

/** play-state 인트로 중복 방지 키 (sceneId 없으면 phase+상황 지문으로 대체 — 빈 키로 인한 무조건 append 방지) */
function ndxPlayStateIntroKey(data){
  if(!data) return '';
  var sid = data.scene && data.scene.sceneId != null && data.scene.sceneId !== '' ? String(data.scene.sceneId) : '';
  if(sid) return 'scene:' + sid;
  var ph = String(data.phase || '');
  var sit = data.introDialogue && data.introDialogue.situation ? String(data.introDialogue.situation) : '';
  var sig = sit.replace(/\s+/g,' ').trim().slice(0, 120);
  return ph + '|sit:' + sig.length + ':' + sig;
}

/** 이미 로그에 해당 sceneId 인트로가 있으면 true (JSP 1차 페인트와 play-state 중복 방지) */
function ndxLogHasSceneIntroForSceneId(log, sceneIdStr){
  if(!log || sceneIdStr == null || sceneIdStr === '') return false;
  var want = String(sceneIdStr);
  var sys = log.querySelectorAll('.chat-bubble--system[data-scene-intro="1"]');
  for(var i = sys.length - 1; i >= 0; i--){
    var ds = sys[i].getAttribute('data-scene-id');
    if(ds != null && String(ds) === want) return true;
  }
  return false;
}

/** 이미 로그에 같은 씬 인트로(상황)가 있으면 true — JSP 첫 페인트 후 goNext가 같은 지문을 또 붙이는 경우 차단 */
function ndxLogAlreadyHasSameSceneIntro(log, data){
  if(!log || !data) return false;
  var wantSid = data.scene && data.scene.sceneId != null && data.scene.sceneId !== '' ? String(data.scene.sceneId) : '';
  var sit = data.introDialogue && data.introDialogue.situation ? String(data.introDialogue.situation) : '';
  var n = sit.replace(/\s+/g,' ').trim();
  if(!n) return false;
  var sys = log.querySelectorAll('.chat-bubble--system[data-scene-intro="1"]');
  var lim = Math.max(0, sys.length - 8);
  for(var i = sys.length - 1; i >= lim; i--){
    var el = sys[i];
    var t = ndxSituationBubblePlainText(el);
    if(t !== n) continue;
    if(!wantSid) return true;
    var ds = el.getAttribute('data-scene-id');
    if(ds === wantSid) return true;
    if(ds == null || ds === '') return true;
  }
  return false;
}

/** JSP 페인트 직후 intro 키를 맞춰 두면 play-state와 동일 키로 중복 append 방지 */
function ndxComputeIntroKeyFromDom(){
  var cfg = window.NDX_GAME_CONFIG || {};
  var sid = cfg.sceneId != null && cfg.sceneId !== '' ? String(cfg.sceneId) : '';
  if(sid) return 'scene:' + sid;
  var ph = String(typeof currentPhase !== 'undefined' ? currentPhase : (cfg.phase || ''));
  var log = document.getElementById('gameChatLog');
  var sys = log ? log.querySelector('.chat-bubble--system[data-scene-intro="1"]') : null;
  var sit = sys ? ndxSituationBubblePlainText(sys) : '';
  var sig = sit.replace(/\s+/g,' ').trim().slice(0, 120);
  return ph + '|sit:' + sig.length + ':' + sig;
}

/** GET /game/run/{id}/play-state 응답으로 화면 갱신 (전체 리로드 없음) */
function applyPlayStatePayload(data){
  if(!data || !data.ok) return;
  var cfg = window.NDX_GAME_CONFIG = window.NDX_GAME_CONFIG || {};
  cfg.phase = data.phase;
  cfg.monthNum = data.monthNum;
  cfg.totalFans = data.totalFans;
  cfg.coreFans = data.coreFans;
  cfg.casualFans = data.casualFans;
  cfg.lightFans = data.lightFans;
  cfg.dayNum = data.weekNum;
  cfg.teamTotalStat = data.teamTotal;
  cfg.myLiveRank = data.myLiveRank;
  cfg.monthProgressPct = data.monthProgressPct;
  cfg.chemistry = data.chemistry || cfg.chemistry;
  cfg.appliedItemCount = data.appliedItemCount != null ? data.appliedItemCount : cfg.appliedItemCount;
  cfg.rosterStats = rosterJsonToUpdateStatsArray(data.roster);
  if(data.scene && data.scene.sceneId != null){
    cfg.sceneId = data.scene.sceneId;
  }
  var imgMapNext = {};
  (data.roster || []).forEach(function(m){
    if(m && m.traineeId != null && m.imagePath) imgMapNext[String(m.traineeId)] = m.imagePath;
  });
  cfg.rosterImgMap = imgMapNext;
  try{
    imgMap = Object.assign({}, imgMapNext);
  }catch(eIm){}

  currentPhase = String(data.phase || '');
  nextPhaseVal = currentPhase;
  persistResumeState(currentPhase);
  TEAM_TOTAL_STAT = Number(data.teamTotal) || 0;
  DAY_NUM = Number(data.weekNum) || 0;
  MONTH_NUM = Number(data.monthNum) || 0;
  MY_LIVE_RANK = Number(data.myLiveRank) || 999;
  MONTH_PROGRESS_PCT = Number(data.monthProgressPct) || 0;

  document.querySelectorAll('.mcard[data-tid]').forEach(function(card){
    card.classList.remove('mcard--eliminated');
  });
  var eids = data.eliminatedTraineeIds || [];
  if(typeof saveEliminatedTraineeIds === 'function' && eids.length){
    saveEliminatedTraineeIds(eids.map(function(x){ return String(x); }));
  }
  eids.forEach(function(id){
    var c = document.querySelector('.mcard[data-tid="' + String(id) + '"]');
    if(c) c.classList.add('mcard--eliminated');
  });

  syncFanDetail(
    Number(data.totalFans) || 0,
    Number(data.coreFans) || 0,
    Number(data.casualFans) || 0,
    Number(data.lightFans) || 0
  );
  try{
    renderChemistryPanel(data.chemistry);
  }catch(eCh){}

  var dock = document.getElementById('gameChatDockDate');
  if(dock && data.dockDateLine){
    dock.textContent = data.dockDateLine;
    if(data.isDebutEval) dock.setAttribute('data-is-debut', '1');
    else dock.removeAttribute('data-is-debut');
  }
  var badges = document.querySelectorAll('.game-chat-dock__badge');
  if(badges[0] && data.planDayReverse != null) badges[0].textContent = 'DAY ' + data.planDayReverse;
  if(badges[1] && data.myLiveRank != null) badges[1].textContent = '내 랭킹 ' + data.myLiveRank + '위';

  var progBar = document.querySelector('.ai-cond-meter[data-key="progress"]');
  if(progBar){
    var pct = typeof effectiveMonthProgressPct === 'function' ? effectiveMonthProgressPct() : Math.max(0, Math.min(100, Number(data.monthProgressPct) || 0));
    progBar.setAttribute('data-pct', String(pct));
    var pv = progBar.querySelector('.status-bar__val');
    var pf = progBar.querySelector('.status-fill');
    if(pv) pv.textContent = pct + '%';
    if(pf) pf.style.width = pct + '%';
  }
  var mapDay = document.querySelector('.game-map-screen__day');
  if(mapDay && data.planDayReverse != null) mapDay.textContent = 'DAY ' + data.planDayReverse;

  try{
    updateStats(rosterJsonToUpdateStatsArray(data.roster));
  }catch(eSt){}
  try{
    window.__initialRoster = cfg.rosterStats ? cfg.rosterStats.slice() : [];
  }catch(eIr){}

  var log = document.getElementById('gameChatLog');
  if(log){
    var sid = data.scene && data.scene.sceneId != null ? String(data.scene.sceneId) : '';
    var introHtml = buildGameChatIntroHtmlFromPlayState(data.introDialogue, eids, sid);
    var introKey = ndxPlayStateIntroKey(data);
    if(introHtml && introKey){
      var dupKey = window.__ndxLastAppliedSceneIntroKey === introKey;
      var dupDom = ndxLogAlreadyHasSameSceneIntro(log, data);
      var dupScene = sid && ndxLogHasSceneIntroForSceneId(log, sid);
      if(!dupKey && !dupDom && !dupScene){
        window.__ndxLastAppliedSceneIntroKey = introKey;
        var wrap = document.createElement('div');
        wrap.setAttribute('data-play-state-block','1');
        wrap.innerHTML = introHtml;
        while(wrap.firstChild) log.appendChild(wrap.firstChild);
      }else{
        window.__ndxLastAppliedSceneIntroKey = introKey;
      }
    }
    log.scrollTop = log.scrollHeight;
  }
  try{
    initGameChatIntroSequence();
  }catch(eIn){}

  var comboKey = 'ndx_combo_' + String(RUN_ID || '');
  var comboCur = 0;
  try{
    comboCur = parseInt(sessionStorage.getItem(comboKey) || '0', 10) || 0;
  }catch(eCb){}
  try{
    updateGoals(TEAM_TOTAL_STAT, comboCur, currentPhase);
  }catch(eUg){}
  try{
    if(typeof refreshTodayGoals === 'function') refreshTodayGoals();
  }catch(eTg){}
}

function fetchPlayStateAndApply(fallbackUrl){
  var url = CTX + '/game/run/' + RUN_ID + '/play-state';
  var q = [];
  try{
    if(typeof loadEliminatedTraineeIds === 'function'){
      var eids = loadEliminatedTraineeIds();
      if(eids && eids.length) q.push('eliminatedTids=' + encodeURIComponent(eids.join(',')));
    }
  }catch(e0){}
  q.push('skipIntroDialogue=1');
  if(q.length) url += '?' + q.join('&');
  var wrap = document.getElementById('gsWrap');
  function releaseUi(){
    if(wrap){
      wrap.style.pointerEvents = '';
      /* 빈 문자열로 두면 .gs-wrap { opacity:0 } 으로 되돌아가 scrIn 애니메이션은 재실행되지 않아 화면이 비어 보임 */
      wrap.style.opacity = '1';
      wrap.style.animation = 'none';
    }
  }
  if(wrap){
    wrap.style.pointerEvents = 'none';
    wrap.style.opacity = '0.94';
  }
  fetch(url, { credentials: 'same-origin' })
    .then(function(res){
      if(!res.ok) throw new Error('play-state ' + res.status);
      return res.json();
    })
    .then(function(data){
      if(data && data.redirect){
        releaseUi();
        window.location.href = CTX + data.redirect;
        return;
      }
      if(data && data.ok){
        applyPlayStatePayload(data);
        releaseUi();
        setTimeout(focusGameChatInputAuto, 0);
        return;
      }
      releaseUi();
      window.location.href = fallbackUrl;
    })
    .catch(function(){
      releaseUi();
      try{
        if(typeof showToast === 'function') showToast('연결에 문제가 있어 전체 새로고침으로 불러옵니다.', 'warn', 2600);
      }catch(eT2){}
      window.location.href = fallbackUrl;
    });
}

function focusGameChatInputAuto(){
  try{
    var inp=document.getElementById('gameChatInput');
    if(!inp || inp.disabled) return;
    if(typeof inp.focus === 'function'){
      try{ inp.focus({ preventScroll: true }); }
      catch(e2){ inp.focus(); }
    }
  }catch(e){}
}

/* ══════════════════════════════════
   다음으로
══════════════════════════════════ */
function goNext(){
  if(window._resultOverlayMode==='briefing'){
    document.getElementById('rov').classList.remove('show');
    window._resultOverlayMode='';
    var card=document.querySelector('.rcard');
    if(card) card.style.boxShadow='';
    setTimeout(focusGameChatInputAuto, 0);
    return;
  }

  document.getElementById('rov').classList.remove('show');
  document.querySelectorAll('.sup-badge').forEach(function(b){b.remove();});
  document.querySelectorAll('.srow.sup').forEach(function(r){r.classList.remove('sup');});
  document.querySelectorAll('.mcard.boosted').forEach(function(c){c.classList.remove('boosted');});
  persistLastStatFlash({ traineeId: window._bid, delta: window._bdelta, statName: window._bstat });
  if(window._penaltyBid!=null && window._penaltyDelta!=null && window._penaltyStat){
    persistLastStatFlash({ traineeId: window._penaltyBid, delta: window._penaltyDelta, statName: window._penaltyStat });
  }
  attachBadge();
  persistFanMotion(window._fanDelta || 0, CURRENT_TOTAL_FANS, CURRENT_CORE_FANS, CURRENT_CASUAL_FANS, CURRENT_LIGHT_FANS);
  if(nextPhaseVal==='FINISHED'){
    window.location.href=CTX+'/game/run/'+RUN_ID+'/ending';
    return;
  }
  var startUrl = CTX + '/game/run/' + RUN_ID + '/start';
  try{
    if(typeof loadEliminatedTraineeIds === 'function'){
      var eids = loadEliminatedTraineeIds();
      if(eids && eids.length) startUrl += '?eliminatedTids=' + encodeURIComponent(eids.join(','));
    }
  }catch(eGo){}
  fetchPlayStateAndApply(startUrl);
}

function transitionTo(url){
  window.location.href=url;
}

function attachStatBadgeOne(traineeId, delta, statName){
  if(traineeId==null||delta==null||delta===0||!statName)return;
  var nameToKey={'보컬':'v','댄스':'d','스타':'s','멘탈':'m','팀웍':'t'};
  var k=nameToKey[statName]; if(!k) return;
  var card=document.querySelector('.mcard[data-tid="'+String(traineeId)+'"]');
  if(!card) return;
  if(card.classList.contains('mcard--eliminated')) return;
  card.classList.add('boosted');
  var valEl=card.querySelector('.sval[data-key="'+k+'"]');
  var row=valEl?valEl.closest('.srow'):null;
  if(!row) return;
  row.classList.add('sup');
  var isUp=delta>0;
  var bdg=document.createElement('span');
  bdg.className='sup-badge'+(isUp?'':' dn');
  bdg.textContent=(isUp?'\u25b2 +':'\u25bc ')+Math.abs(memberDisplayDeltaFromRaw(delta));
  valEl.insertAdjacentElement('afterend',bdg);
  var f=document.createElement('span');
  f.className='stat-float'+(isUp?'':' dn');
  f.textContent=(isUp?'+':'')+Math.abs(memberDisplayDeltaFromRaw(delta))+' '+statName+' \u2728';
  row.appendChild(f);
  setTimeout(function(){
    try{
      card.classList.remove('boosted');
      bdg.remove();
      f.remove();
      row.classList.remove('sup');
    }catch(e){}
  },15000);
}

function attachBadge(){
  var list=[];
  if(window._bid!=null && window._bdelta!=null && window._bstat) list.push({tid:window._bid,d:window._bdelta,s:window._bstat});
  if(window._penaltyBid!=null && window._penaltyDelta!=null && window._penaltyStat)
    list.push({tid:window._penaltyBid,d:window._penaltyDelta,s:window._penaltyStat});
  if(!list.length) return;
  list.forEach(function(e, idx){
    setTimeout(function(){ attachStatBadgeOne(e.tid, e.d, e.s); }, idx*110);
  });
  window._penaltyBid=null;window._penaltyDelta=null;window._penaltyStat=null;
  window._bid=null;window._bdelta=0;window._bstat=null;
}

/* ══════════════════════════════════
   테스트: 턴당 능력치 상승 2배 (로컬 저장 + 메모리 — storage 실패해도 UI·요청은 일치)
══════════════════════════════════ */
function statGrowth2xStorageKey(){
  return 'ndx_stat_growth_2x_' + String(RUN_ID || 'default');
}
/** localStorage 실패 시에도 토글 상태 유지 */
var __ndxStatGrowth2xOn = false;
function statGrowth2xInitFromStorage(){
  try{
    __ndxStatGrowth2xOn = localStorage.getItem(statGrowth2xStorageKey()) === '1';
  }catch(e){
    __ndxStatGrowth2xOn = false;
  }
}
function isStatGrowth2xEnabled(){
  return !!__ndxStatGrowth2xOn;
}
/** 서버 기준 진행도(0~100) → 2배 모드일 때 UI·목표용 표시값(최대 100) */
function effectiveMonthProgressPct(basePct){
  var b = typeof basePct === 'number' && isFinite(basePct) ? basePct : (typeof MONTH_PROGRESS_PCT === 'number' ? MONTH_PROGRESS_PCT : 0);
  if(!isFinite(b)) b = 0;
  b = Math.max(0, Math.min(100, b));
  if(typeof isStatGrowth2xEnabled === 'function' && isStatGrowth2xEnabled()){
    return Math.max(0, Math.min(100, Math.round(b * 2)));
  }
  return Math.round(b);
}
function refreshProgramProgressDisplay(){
  try{
    var rb = typeof collectRosterFromDom === 'function' ? collectRosterFromDom() : [];
    if(rb && rb.length && typeof updateConditionBarsFromRoster === 'function'){
      updateConditionBarsFromRoster(rb);
      return;
    }
  }catch(e){}
  var eff = effectiveMonthProgressPct();
  var progBar = document.querySelector('.ai-cond-meter[data-key="progress"]');
  if(progBar){
    progBar.setAttribute('data-pct', String(eff));
    var pv = progBar.querySelector('.status-bar__val');
    var pf = progBar.querySelector('.status-fill');
    if(pv) pv.textContent = eff + '%';
    if(pf) pf.style.width = eff + '%';
  }
  var df = document.getElementById('debutProgressFill');
  var dl = document.getElementById('debutProgressPctLabel');
  if(df) df.style.width = eff + '%';
  if(dl) dl.textContent = eff + '%';
  var mfill = document.getElementById('monthProgressFill');
  if(mfill){
    mfill.setAttribute('data-pct', String(eff));
    mfill.style.width = eff + '%';
  }
  try{
    var totalHeader = document.querySelector('.game-hud-item--money .game-hud-val');
    var curTotal = parseInt(totalHeader ? totalHeader.textContent.replace(/[^0-9\-]/g,'') : '0', 10) || 0;
    var comboKey = 'ndx_combo_' + String(RUN_ID || '');
    var comboCur = 0;
    try{ comboCur = parseInt(sessionStorage.getItem(comboKey) || '0', 10) || 0; }catch(eC){}
    if(typeof updateGoals === 'function') updateGoals(curTotal, comboCur, typeof currentPhase !== 'undefined' ? currentPhase : null);
  }catch(eG){}
}
function setStatGrowth2xEnabled(on){
  __ndxStatGrowth2xOn = !!on;
  try{
    if(__ndxStatGrowth2xOn) localStorage.setItem(statGrowth2xStorageKey(), '1');
    else localStorage.removeItem(statGrowth2xStorageKey());
  }catch(e){}
  syncStatGrowth2xButton();
}
function toggleStatGrowth2x(){
  setStatGrowth2xEnabled(!__ndxStatGrowth2xOn);
  try{
    if(typeof showToast === 'function'){
      if(isStatGrowth2xEnabled()){
        showToast('2배 모드 켜짐 · 턴 능력치 상승·진행도 표시가 2배로 적용됩니다.', 'ok', 3200);
      }else{
        showToast('2배 모드 꺼짐 · 일반 배율로 돌아갔습니다.', 'warn', 2800);
      }
    }
  }catch(e){}
}
function syncStatGrowth2xButton(){
  var btn=document.getElementById('statGrowth2xBtn');
  var badge=document.getElementById('statGrowth2xBadge');
  if(!btn) return;
  if(isStatGrowth2xEnabled()){
    btn.classList.add('is-on');
    btn.setAttribute('aria-pressed','true');
    btn.setAttribute('aria-label','테스트 2배 모드 켜짐 · 클릭하면 끔');
    btn.title='2배 모드 켜짐 · 턴 능력치·진행도 표시 2배 (클릭하면 끔)';
    if(badge){
      badge.textContent='ON';
      badge.classList.remove('stat2x-btn__badge--off');
      badge.classList.add('stat2x-btn__badge--on');
    }
  }else{
    btn.classList.remove('is-on');
    btn.setAttribute('aria-pressed','false');
    btn.setAttribute('aria-label','테스트 2배 모드 꺼짐 · 클릭하면 켬');
    btn.title='2배 모드 꺼짐 · 클릭하면 턴 능력치·진행도 표시 2배 적용';
    if(badge){
      badge.textContent='OFF';
      badge.classList.remove('stat2x-btn__badge--on');
      badge.classList.add('stat2x-btn__badge--off');
    }
  }
  try{ refreshProgramProgressDisplay(); }catch(eR){}
}
(function initStatGrowth2xUi(){
  function run(){
    statGrowth2xInitFromStorage();
    syncStatGrowth2xButton();
  }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded', run);
  else run();
})();
(function bindStatGrowth2xDelegation(){
  if(window.__ndxStat2xDocBound) return;
  window.__ndxStat2xDocBound = true;
  document.addEventListener('click', function(ev){
    var t = ev.target;
    if(!t || typeof t.closest !== 'function') return;
    if(!t.closest('#statGrowth2xBtn')) return;
    ev.preventDefault();
    ev.stopImmediatePropagation();
    if(typeof toggleStatGrowth2x === 'function') toggleStatGrowth2x();
  }, true);
})();
window.toggleStatGrowth2x = toggleStatGrowth2x;
window.syncStatGrowth2xButton = syncStatGrowth2xButton;
window.isStatGrowth2xEnabled = isStatGrowth2xEnabled;

applyPersistedStatFlash();

/* ══════════════════════════════════
   SAVE
══════════════════════════════════ */
function doSave(){
  var btns=[];
  var a=document.getElementById('saveBtn');
  var b=document.getElementById('saveBtnChatDock');
  if(a)btns.push(a);
  if(b)btns.push(b);
  if(!btns.length)return;
  function setAll(html, addSaved){
    btns.forEach(function(btn){
      btn.innerHTML=html;
      if(addSaved)btn.classList.add('saved');else btn.classList.remove('saved');
    });
  }
  try{
    persistEliminationStateFromMembers();
    persistResumeState(currentPhase);
    setAll('<i class="fas fa-check"></i><span>SAVED</span>',true);
    setTimeout(function(){setAll('<i class="fas fa-floppy-disk"></i><span>SAVE</span>',false);},2000);
  }catch(e){
    setAll('<i class="fas fa-xmark"></i><span>실패</span>',false);
    setTimeout(function(){setAll('<i class="fas fa-floppy-disk"></i><span>SAVE</span>',false);},1500);
  }
}

/* ══════════════════════════════════
   파티클 버스트
══════════════════════════════════ */
function burst(btn){
  var r=btn.getBoundingClientRect();
  burstAt(r.left+r.width/2,r.top+r.height/2,14);
}
function burstAt(cx,cy,n){
  var cols=['#ef93b0','#f8b6c8','#f5c4d4','#fbbf24','#34d399'];
  var wrap=document.createElement('div');wrap.className='bst';
  wrap.style.left=cx+'px';wrap.style.top=cy+'px';
  for(var i=0;i<n;i++){
    var p=document.createElement('div');p.className='bst-p';
    var angle=(i/n)*Math.PI*2;
    var dist=40+Math.random()*40;
    p.style.setProperty('--tx',Math.cos(angle)*dist+'px');
    p.style.setProperty('--ty',Math.sin(angle)*dist+'px');
    p.style.background=cols[i%cols.length];
    p.style.boxShadow='0 0 '+(6+Math.random()*6)+'px '+cols[i%cols.length];
    p.style.animationDelay=Math.random()*80+'ms';
    p.style.animationDuration=(.5+Math.random()*.3)+'s';
    wrap.appendChild(p);
  }
  document.body.appendChild(wrap);
  setTimeout(function(){wrap.remove();},900);
}

// nav 높이: documentElement에 측정값을 쓰면 theme의 .nav-brand{height:var(--nav-h)}와 순환해
// 상단바가 픽셀 단위로 계속 커지는 버그가 난다. --nav-h는 theme.css 고정값만 사용.

// =========================
// 스케줄 모달 (iframe)
// =========================
function openScheduleModal(url){
  var modal=document.getElementById('scheduleModal');
  var frame=document.getElementById('scheduleModalFrame');
  if(!modal || !frame) return;
  var embedUrl = url + (url.indexOf('?')>=0 ? '&' : '?') + 'embed=1';
  frame.src = embedUrl;
  modal.classList.add('is-open');
  modal.setAttribute('aria-hidden','false');
}
function closeScheduleModal(){
  var modal=document.getElementById('scheduleModal');
  var frame=document.getElementById('scheduleModalFrame');
  if(!modal) return;
  modal.classList.remove('is-open');
  modal.setAttribute('aria-hidden','true');
  if(frame) frame.src = 'about:blank';
}
(function(){
  var modal=document.getElementById('scheduleModal');
  if(!modal) return;

  document.querySelectorAll('[data-close-schedule-modal]').forEach(function(el){
    el.addEventListener('click', closeScheduleModal);
  });

  var closeBtn=document.getElementById('scheduleModalClose');
  if(closeBtn) closeBtn.addEventListener('click', closeScheduleModal);

  document.addEventListener('keydown', function(e){
    if(e.key==='Escape' && modal.classList.contains('is-open')) closeScheduleModal();
  });
})();

function openDebugToolsModal(){
  var modal = document.getElementById('debugToolsModal');
  if(!modal) return;
  modal.classList.add('is-open');
  modal.setAttribute('aria-hidden', 'false');
}
function closeDebugToolsModal(){
  var modal = document.getElementById('debugToolsModal');
  if(!modal) return;
  modal.classList.remove('is-open');
  modal.setAttribute('aria-hidden', 'true');
}
function ndxDebugGetRoster(){
  try{
    if(typeof collectRosterFromDom === 'function'){
      var domRoster = collectRosterFromDom();
      if(domRoster && domRoster.length) return domRoster;
    }
  }catch(eDom){}
  try{
    if(window.__initialRoster && window.__initialRoster.length) return window.__initialRoster;
  }catch(eInit){}
  return [];
}
function forceStressToGameOverForDemo(){
  if(window.__ndxStressGameOverTriggered) return;
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  window.__mapEventBarBonus.stress = (Number(window.__mapEventBarBonus.stress) || 0) + 300;
  var roster = ndxDebugGetRoster();
  if(roster && roster.length && typeof updateConditionBarsFromRoster === 'function'){
    updateConditionBarsFromRoster(roster);
  }else if(typeof triggerStressGameOver === 'function'){
    triggerStressGameOver();
  }
  try{
    if(typeof showToast === 'function'){
      showToast('시연용: 스트레스 100% 상태를 강제로 만들었습니다.', 'warn', 2300);
    }
  }catch(eToast){}
}
function forceConditionDropForEliminationDemo(){
  window.__mapEventBarBonus = window.__mapEventBarBonus || { focus: 0, stress: 0, team: 0, condition: 0 };
  window.__mapEventBarBonus.condition = (Number(window.__mapEventBarBonus.condition) || 0) - 300;
  if(window.__ndxConditionLatch && typeof window.__ndxConditionLatch === 'object'){
    window.__ndxConditionLatch.condElimActive = false;
  }
  var roster = ndxDebugGetRoster();
  if(roster && roster.length && typeof updateConditionBarsFromRoster === 'function'){
    updateConditionBarsFromRoster(roster);
  }
  try{
    if(typeof showToast === 'function'){
      showToast('시연용: 컨디션 19% 이하 자동 탈락을 강제로 실행했습니다.', 'warn', 2600);
    }
  }catch(eToast2){}
}
(function bindDebugToolsModal(){
  if(window.__ndxDebugToolsBound) return;
  window.__ndxDebugToolsBound = true;
  function bind(){
    var modal = document.getElementById('debugToolsModal');
    if(!modal) return;
    document.querySelectorAll('[data-close-debug-tools]').forEach(function(el){
      el.addEventListener('click', closeDebugToolsModal);
    });
    var closeBtn = document.getElementById('debugToolsModalClose');
    if(closeBtn) closeBtn.addEventListener('click', closeDebugToolsModal);
    var stressBtn = document.getElementById('debugStressMaxBtn');
    if(stressBtn){
      stressBtn.addEventListener('click', function(){
        closeDebugToolsModal();
        forceStressToGameOverForDemo();
      });
    }
    var condBtn = document.getElementById('debugConditionDropBtn');
    if(condBtn){
      condBtn.addEventListener('click', function(){
        forceConditionDropForEliminationDemo();
      });
    }
    document.addEventListener('keydown', function(e){
      if(e.key === 'Escape' && modal.classList.contains('is-open')) closeDebugToolsModal();
    });
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', bind);
  else bind();
})();
window.openDebugToolsModal = openDebugToolsModal;
window.closeDebugToolsModal = closeDebugToolsModal;

(function initInventoryManageModal(){
  function qs(id){ return document.getElementById(id); }
  var modal = qs('inventoryManageModal');
  if(!modal) return;
  var openBtn = qs('openInventoryModalBtn');
  var closeBtn = qs('inventoryManageModalClose');
  var selectedInline = qs('inventorySelectedInline');
  var pickedList = qs('inventoryPickedList');
  var applyBtn = qs('applySelectedItemsBtn');
  var maxCount = Number(NDX_GAME_CONFIG.maxAppliedItemCount || 6);
  var selectedMap = new Map();

  function setActiveTab(tabName){
    modal.querySelectorAll('[data-inventory-tab]').forEach(function(tab){
      var active = tab.getAttribute('data-inventory-tab') === tabName;
      tab.classList.toggle('is-active', active);
      tab.setAttribute('aria-selected', active ? 'true' : 'false');
    });
    modal.querySelectorAll('[data-inventory-panel]').forEach(function(panel){
      panel.classList.toggle('is-active', panel.getAttribute('data-inventory-panel') === tabName);
    });
  }
  function openModal(tabName){ setActiveTab(tabName || 'owned'); modal.classList.add('is-open'); modal.setAttribute('aria-hidden', 'false'); document.body.style.overflow='hidden'; }
  function closeModal(){ modal.classList.remove('is-open'); modal.setAttribute('aria-hidden', 'true'); document.body.style.overflow=''; }
  if(openBtn) openBtn.addEventListener('click', function(){ openModal('owned'); });
  if(closeBtn) closeBtn.addEventListener('click', closeModal);
  modal.querySelectorAll('[data-inventory-close]').forEach(function(el){ el.addEventListener('click', closeModal); });
  modal.querySelectorAll('[data-inventory-tab]').forEach(function(tab){ tab.addEventListener('click', function(){ setActiveTab(tab.getAttribute('data-inventory-tab') || 'owned'); }); });
  document.addEventListener('keydown', function(e){ if(e.key==='Escape' && modal.classList.contains('is-open')) closeModal(); });

  function updateCoinViews(nextCoin){
    var hudCoin = document.querySelector('.game-hud-item--money .game-hud-val');
    var modalCoin = qs('gameInventoryCoinText');
    if(hudCoin && nextCoin !== undefined && nextCoin !== null) hudCoin.textContent = nextCoin;
    if(modalCoin && nextCoin !== undefined && nextCoin !== null) modalCoin.textContent = nextCoin;
  }

  function escapeHtml(value){
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }
  function getOwnedList(){ return qs('inventoryOwnedSelectableList'); }
  function getOwnedRows(){ return Array.from(modal.querySelectorAll('.inventory-item--pickable')); }
  function renderSelected(){
    var items = Array.from(selectedMap.values());
    if(selectedInline) selectedInline.textContent = items.length ? items.map(function(it){ return it.name; }).join(' / ') : '선택된 아이템 없음';
    if(!pickedList) return;
    if(!items.length){ pickedList.innerHTML = '<div class="inventory-empty inventory-empty--compact">선택된 아이템이 없습니다.</div>'; return; }
    pickedList.innerHTML = items.map(function(it){
      return '<div class="inventory-picked-card" data-picked-id="'+ it.id +'">'
        + '<img src="'+ it.image +'" alt="'+ it.name +'">'
        + '<div class="inventory-picked-card__meta"><strong>'+ it.name +'</strong><span>'+ (it.effect||'') +'</span></div>'
        + '<button type="button" class="inventory-picked-card__remove" data-remove-picked="'+ it.id +'">&times;</button>'
        + '</div>';
    }).join('');
  }
  function syncSelectionUi(){
    getOwnedRows().forEach(function(row){
      var id = row.getAttribute('data-item-id');
      var on = selectedMap.has(id);
      row.classList.toggle('is-selected', on);
      var btn = row.querySelector('.inventory-item__rowbtn');
      if(btn) btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    renderSelected();
  }
  function buildOwnedItemMarkup(item){
    var id = escapeHtml(item.id);
    var name = escapeHtml(item.itemName || '아이템');
    var effect = escapeHtml(item.itemEffect || '');
    var image = escapeHtml(String(NDX_GAME_CONFIG.ctx || '') + (item.imagePath || ''));
    var qty = Number(item.quantity || 0);
    return '<div class="inventory-item inventory-item--modal inventory-item--pickable" role="listitem" data-item-id="' + id + '" data-item-name="' + name + '" data-item-effect="' + effect + '" data-item-image="' + image + '">'
      + '<button type="button" class="inventory-item__rowbtn" aria-pressed="false">'
      + '<span class="inventory-item__check"></span>'
      + '<img class="inventory-item__thumb" src="' + image + '" alt="' + name + '">'
      + '<div class="inventory-item__meta"><div class="inventory-item__name">' + name + '</div><div class="inventory-item__effect">' + effect + '</div></div>'
      + '<div class="inventory-item__qty">x' + qty + '</div>'
      + '</button></div>';
  }
  function bindOwnedRowEvents(){
    getOwnedRows().forEach(function(row){
      var btn = row.querySelector('.inventory-item__rowbtn');
      if(btn && !btn.dataset.bound){
        btn.dataset.bound='1';
        btn.addEventListener('click', function(e){ e.preventDefault(); toggleRowSelection(row); });
      }
    });
  }
  function renderOwnedItems(items){
    var list = getOwnedList();
    if(!list) return;
    var safeItems = Array.isArray(items) ? items.filter(function(it){ return it && Number(it.quantity || 0) > 0; }) : [];
    selectedMap.forEach(function(value, key){
      var matched = safeItems.find(function(it){ return String(it.id) === String(key); });
      if(!matched){ selectedMap.delete(key); return; }
      value.name = matched.itemName || value.name;
      value.effect = matched.itemEffect || value.effect;
      value.image = String(NDX_GAME_CONFIG.ctx || '') + (matched.imagePath || '');
    });
    list.innerHTML = safeItems.length ? safeItems.map(buildOwnedItemMarkup).join('') : '<div class="inventory-empty">보유한 아이템이 없습니다.</div>';
    bindOwnedRowEvents();
    syncSelectionUi();
  }
  function flashPurchasedRows(itemNames){
    if(!Array.isArray(itemNames) || !itemNames.length) return;
    var counts = itemNames.reduce(function(map, name){
      var key = String(name || '');
      map[key] = (map[key] || 0) + 1;
      return map;
    }, {});
    getOwnedRows().forEach(function(row){
      var itemName = row.getAttribute('data-item-name') || '';
      var plus = counts[itemName] || 0;
      if(!plus) return;
      row.classList.remove('is-purchased-flash');
      void row.offsetWidth;
      row.classList.add('is-purchased-flash');
      var qty = row.querySelector('.inventory-item__qty');
      if(qty){
        qty.classList.remove('is-bump');
        void qty.offsetWidth;
        qty.classList.add('is-bump');
        qty.setAttribute('data-bump', '+' + plus);
        window.setTimeout(function(){ qty.classList.remove('is-bump'); qty.removeAttribute('data-bump'); }, 1800);
      }
      window.setTimeout(function(){ row.classList.remove('is-purchased-flash'); }, 1800);
    });
  }
  function toggleRowSelection(row){
    var id = row.getAttribute('data-item-id');
    if(!id) return;
    if(selectedMap.has(id)){ selectedMap.delete(id); syncSelectionUi(); return; }
    if(selectedMap.size >= maxCount){ alert('아이템은 최대 '+ maxCount +'개까지 선택할 수 있습니다.'); return; }
    selectedMap.set(id, {
      id:id,
      name: row.getAttribute('data-item-name') || '아이템',
      effect: row.getAttribute('data-item-effect') || '',
      image: row.getAttribute('data-item-image') || ''
    });
    syncSelectionUi();
  }
  bindOwnedRowEvents();
  if(pickedList){
    pickedList.addEventListener('click', function(e){
      var removeBtn = e.target.closest('[data-remove-picked]');
      if(!removeBtn) return;
      selectedMap.delete(removeBtn.getAttribute('data-remove-picked'));
      syncSelectionUi();
    });
  }
  function buildAppliedHudItem(name, desc){
    var wrap = document.createElement('div');
    wrap.className='game-hud-applied-item';
    wrap.setAttribute('data-item-name', name);
    wrap.setAttribute('data-item-desc', desc||'');
    wrap.innerHTML='<span class="game-hud-applied-item-icon"><i class="fa-solid fa-gift"></i></span>'
      + '<span class="game-hud-applied-item-name"></span>'
      + '<span class="game-hud-applied-tooltip"><strong></strong></span>';
    wrap.querySelector('.game-hud-applied-item-name').textContent=name;
    wrap.querySelector('.game-hud-applied-tooltip strong').textContent=name;
    wrap.querySelector('.game-hud-applied-tooltip').append(desc||'');
    return wrap;
  }
  function updateAppliedHud(names){
    var list = document.querySelector('.game-hud-applied-list');
    if(!list || !names || !names.length) return;
    var empty = list.querySelector('.game-hud-applied-empty'); if(empty) empty.remove();
    names.forEach(function(name){ list.appendChild(buildAppliedHudItem(name, '적용된 아이템')); });
  }
  function applySelectedItems(){
    var items = Array.from(selectedMap.values());
    if(!items.length){ alert('적용할 아이템을 선택하세요.'); return; }
    var names = items.map(function(it){ return it.name; });
    if(!confirm(names.join('\n') + '\n\n적용하시겠습니까?')) return;
    var params = new URLSearchParams();
    items.forEach(function(it){ params.append('itemIds', String(it.id)); });
    try{
      if(typeof loadEliminatedTraineeIds === 'function'){
        var eids = loadEliminatedTraineeIds();
        if(eids && eids.length) params.append('eliminatedTids', eids.join(','));
      }
    }catch(eIt){}
    closeModal();
    window.location.href = (String(NDX_GAME_CONFIG.ctx||'')) + '/game/run/' + String(NDX_GAME_CONFIG.runId||'') + '/start?' + params.toString();
  }
  if(applyBtn) applyBtn.addEventListener('click', applySelectedItems);

  function buyInventoryModalItem(itemName, price){
    if(!itemName || !price) return;
    if(!confirm(price + ' COIN으로 ' + itemName + '을 구매하시겠습니까?')) return;
    fetch((String(NDX_GAME_CONFIG.ctx || '')) + '/market/buyItem', {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ itemName: itemName, price: Number(price) })
    })
    .then(function(res){ return res.text().then(function(raw){ return { ok: res.ok, raw: raw }; }); })
    .then(function(payload){ if(!payload.ok) throw new Error('HTTP ' + payload.raw); try{return JSON.parse(payload.raw);}catch(e){return {result:(payload.raw||'').trim()};} })
    .then(function(data){
      if(data.result === 'success'){
        updateCoinViews(data.currentCoin);
        renderOwnedItems(data.items || []);
        setActiveTab('owned');
        flashPurchasedRows(data.boughtItemNames || [itemName]);
        alert(itemName + ' 구매가 완료되었습니다.');
        return;
      }
      if(data.result === 'lack'){ alert('코인이 부족합니다.'); updateCoinViews(data.currentCoin); return; }
      alert('구매 실패');
    })
    .catch(function(){ alert('구매 실패'); });
  }
  modal.querySelectorAll('.inventory-shop-item[data-buy-item-name]').forEach(function(btn){
    btn.addEventListener('click', function(){ buyInventoryModalItem(btn.getAttribute('data-buy-item-name'), btn.getAttribute('data-buy-item-price')); });
  });
  bindOwnedRowEvents();
  syncSelectionUi();
})();
