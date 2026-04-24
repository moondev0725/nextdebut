import fs from "node:fs/promises";
import path from "node:path";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const ROOT = "C:/Users/KOSMO/Desktop/nextdebut";
const OUT_DIR = path.join(ROOT, "outputs", "next-debut-ppt");
const PPT_PATH = path.join(OUT_DIR, "output.pptx");
const IMG_DIR = "C:/Users/KOSMO/Desktop/ppt 사진";
const W = 1280;
const H = 720;

const COLORS = {
  bg: "#fffafc",
  bgSoft: "#f8f3ff",
  ink: "#3a3346",
  inkSoft: "#6f6880",
  pink: "#f48fb1",
  pinkDeep: "#e46daa",
  lavender: "#cdb9ff",
  lavenderDeep: "#aa8dff",
  cream: "#fffdf8",
  mint: "#a8ead6",
  blue: "#cde7ff",
  gold: "#f6c86d",
  border: "#eadff5",
  white: "#ffffff",
};

const FONT = {
  title: "Malgun Gothic",
  body: "Malgun Gothic",
};

async function readImageBlob(imagePath) {
  const bytes = await fs.readFile(imagePath);
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
}

function img(name) {
  return path.join(IMG_DIR, name);
}

function addBg(slide) {
  slide.background.fill = COLORS.bg;

  slide.shapes.add({
    geometry: "ellipse",
    position: { left: -80, top: -50, width: 420, height: 240 },
    fill: COLORS.bgSoft,
    line: { width: 0, fill: COLORS.bgSoft },
  });

  slide.shapes.add({
    geometry: "ellipse",
    position: { left: 930, top: -40, width: 360, height: 220 },
    fill: "#ffe6f2",
    line: { width: 0, fill: "#ffe6f2" },
  });

  slide.shapes.add({
    geometry: "ellipse",
    position: { left: 980, top: 520, width: 260, height: 150 },
    fill: "#eefaff",
    line: { width: 0, fill: "#eefaff" },
  });
}

function addCard(slide, left, top, width, height, fill = COLORS.white, radius = 0.18) {
  const card = slide.shapes.add({
    geometry: "roundRect",
    adjustmentList: [{ name: "adj", formula: `val ${Math.round(radius * 50000)}` }],
    position: { left, top, width, height },
    fill,
    line: { width: 1.2, fill: COLORS.border },
  });
  return card;
}

function addText(slide, text, left, top, width, height, style = {}) {
  const box = slide.shapes.add({
    geometry: "rect",
    position: { left, top, width, height },
    fill: "#FFFFFF00",
    line: { width: 0, fill: "#FFFFFF00" },
  });
  box.text = text;
  box.text.typeface = style.typeface || FONT.body;
  box.text.fontSize = style.fontSize || 22;
  box.text.color = style.color || COLORS.ink;
  box.text.bold = style.bold || false;
  box.text.alignment = style.alignment || "left";
  box.text.verticalAlignment = style.verticalAlignment || "top";
  box.text.insets = style.insets || { left: 0, right: 0, top: 0, bottom: 0 };
  return box;
}

function addTitle(slide, num, title, subtitle = "") {
  addBg(slide);
  addCard(slide, 36, 28, 1208, 94, "#ffffffcc", 0.22);
  addCard(slide, 52, 46, 92, 44, "#ffe7f0", 0.48);
  addText(slide, `${num}`, 52, 52, 92, 34, {
    fontSize: 22,
    bold: true,
    alignment: "center",
    verticalAlignment: "middle",
    color: COLORS.pinkDeep,
  });
  addText(slide, title, 164, 44, 760, 38, {
    fontSize: 28,
    bold: true,
    typeface: FONT.title,
  });
  if (subtitle) {
    addText(slide, subtitle, 164, 82, 760, 24, {
      fontSize: 13,
      color: COLORS.inkSoft,
    });
  }
  addText(slide, "NEXT DEBUT", 1030, 54, 170, 28, {
    fontSize: 15,
    bold: true,
    alignment: "right",
    color: COLORS.lavenderDeep,
  });
}

function addBullets(slide, bullets, left, top, width, height) {
  addCard(slide, left, top, width, height, "#ffffffd8", 0.16);
  let y = top + 22;
  for (const bullet of bullets) {
    addCard(slide, left + 18, y + 6, 10, 10, COLORS.pink, 0.5);
    addText(slide, bullet, left + 40, y, width - 58, 48, {
      fontSize: 19,
      color: COLORS.ink,
    });
    y += 52;
  }
}

function addAccentNote(slide, text, left, top, width, height, fill = "#fff1f7") {
  addCard(slide, left, top, width, height, fill, 0.2);
  addText(slide, text, left + 18, top + 14, width - 36, height - 28, {
    fontSize: 18,
    bold: true,
    color: COLORS.pinkDeep,
    verticalAlignment: "middle",
  });
}

async function addImage(slide, imageName, left, top, width, height, fit = "cover", radius = 0.14) {
  const blob = await readImageBlob(img(imageName));
  const image = slide.images.add({
    blob,
    fit,
    alt: imageName,
    geometry: "roundRect",
    adjustmentList: [{ name: "adj", formula: `val ${Math.round(radius * 50000)}` }],
  });
  image.position = { left, top, width, height };
  slide.shapes.add({
    geometry: "roundRect",
    adjustmentList: [{ name: "adj", formula: `val ${Math.round(radius * 50000)}` }],
    position: { left, top, width, height },
    fill: "#FFFFFF00",
    line: { width: 1.2, fill: COLORS.border },
  });
}

function addSectionPill(slide, text, left, top, width = 180) {
  addCard(slide, left, top, width, 30, "#f4ecff", 0.48);
  addText(slide, text, left, top + 6, width, 18, {
    fontSize: 12,
    bold: true,
    alignment: "center",
    color: COLORS.lavenderDeep,
  });
}

async function build() {
  await fs.mkdir(OUT_DIR, { recursive: true });
  const presentation = Presentation.create({ slideSize: { width: W, height: H } });

  presentation.theme.colorScheme = {
    name: "NEXT DEBUT",
    themeColors: {
      accent1: COLORS.pink,
      accent2: COLORS.lavender,
      accent3: COLORS.mint,
      accent4: COLORS.gold,
      bg1: COLORS.bg,
      bg2: COLORS.bgSoft,
      tx1: COLORS.ink,
      tx2: COLORS.inkSoft,
    },
  };

  // 1 cover
  {
    const slide = presentation.slides.add();
    slide.background.fill = COLORS.bg;
    await addImage(slide, "01_cover_main_hero.png", 0, 0, W, H, "cover", 0);
    slide.shapes.add({
      geometry: "rect",
      position: { left: 0, top: 0, width: W, height: H },
      fill: "#ffffff14",
      line: { width: 0, fill: "#FFFFFF00" },
    });
    addCard(slide, 42, 36, 330, 40, "#ffffffd5", 0.42);
    addText(slide, "K-POP 연습생 육성 시뮬레이션 플랫폼", 56, 46, 302, 18, {
      fontSize: 14,
      bold: true,
      color: COLORS.inkSoft,
      alignment: "center",
    });
    addText(slide, "NEXT DEBUT", 76, 420, 760, 88, {
      fontSize: 42,
      bold: true,
      color: COLORS.white,
      typeface: FONT.title,
    });
    addText(slide, "연습생을 선택하고, 성장시키고, 데뷔 무대까지 이끄는 프로듀싱 경험", 82, 512, 760, 30, {
      fontSize: 21,
      color: COLORS.white,
      bold: true,
    });
    addCard(slide, 840, 522, 366, 130, "#ffffffd2", 0.2);
    addText(slide, "엔지니어 7기 2팀", 866, 548, 160, 24, {
      fontSize: 20,
      bold: true,
      color: COLORS.pinkDeep,
    });
    addText(slide, "팀장: 문성훈\n팀원: 이슬기, 방혜은\n발표일: 26년 4월 30일", 866, 584, 280, 56, {
      fontSize: 16,
      color: COLORS.ink,
    });
  }

  // 2 toc
  {
    const slide = presentation.slides.add();
    addTitle(slide, 2, "목차", "프로젝트의 배경부터 구현 구조, 협업 과정까지 순서대로 소개합니다.");
    addCard(slide, 64, 160, 1150, 462, "#ffffffd8", 0.16);
    const items = [
      ["1. 프로젝트 개요", "왜 만들었는가"],
      ["2. 프로젝트 상세", "어떤 기능과 구조로 구현했는가"],
      ["3. 진행 프로세스", "어떻게 협업하고 완성했는가"],
    ];
    let x = 92;
    const cols = [340, 340, 340];
    for (let i = 0; i < items.length; i++) {
      addCard(slide, x, 230, cols[i], 310, i === 0 ? "#fff3f8" : i === 1 ? "#f6f0ff" : "#f6fffc", 0.22);
      addText(slide, items[i][0], x + 28, 280, cols[i] - 56, 40, {
        fontSize: 30,
        bold: true,
        color: i === 0 ? COLORS.pinkDeep : i === 1 ? COLORS.lavenderDeep : "#4ca693",
      });
      addText(slide, items[i][1], x + 28, 340, cols[i] - 56, 54, {
        fontSize: 20,
        color: COLORS.ink,
      });
      x += cols[i] + 28;
    }
  }

  const simpleSlides = [
    {
      num: 3,
      title: "프로젝트 개요 - 개발 동기",
      subtitle: "아이돌 결과 소비를 넘어, 성장 과정에 몰입하는 팬 경험이 필요했습니다.",
      bullets: [
        "K-POP에 대한 글로벌 관심이 커지면서 팬 경험도 더 깊고 다양해지고 있습니다.",
        "단순히 데뷔 후 결과를 소비하는 것이 아니라 성장 과정 자체를 함께 즐기려는 수요가 증가했습니다.",
        "팬들이 연습생 단계부터 몰입하고 참여할 수 있는 서비스는 아직 부족했습니다.",
        "기존 서비스가 결과 중심이라면, NEXT DEBUT는 과정 중심 체험형 구조를 지향합니다.",
      ],
      note: "핵심 메시지: 아이돌의 결과가 아닌, 과정을 즐기는 서비스",
    },
  ];

  for (const s of simpleSlides) {
    const slide = presentation.slides.add();
    addTitle(slide, s.num, s.title, s.subtitle);
    addBullets(slide, s.bullets, 66, 156, 780, 420);
    addAccentNote(slide, s.note, 66, 600, 780, 58);
    addCard(slide, 878, 156, 322, 502, "#fff7fb", 0.18);
    addText(slide, "과정 중심 팬 경험", 914, 208, 250, 40, {
      fontSize: 28,
      bold: true,
      color: COLORS.pinkDeep,
    });
    addText(slide, "연습생 시절부터 선택하고, 성장시키고, 결과를 함께 만들어 가는 구조가 본 프로젝트의 출발점입니다.", 914, 272, 234, 150, {
      fontSize: 20,
      color: COLORS.ink,
    });
  }

  // 4
  {
    const slide = presentation.slides.add();
    addTitle(slide, 4, "프로젝트 개요 - 기획 의도", "게임, 커뮤니티, AI, 채팅을 하나의 팬 경험 플랫폼으로 연결했습니다.");
    addBullets(slide, [
      "사용자가 직접 연습생을 선택하고 성장시키는 시뮬레이션 서비스입니다.",
      "실제 아이돌 육성 과정을 게임화해 과정 중심 몰입을 제공합니다.",
      "연습생 시절부터 팬이 유입되고 성장 과정을 함께 소비하는 플랫폼 구조를 지향합니다.",
      "사용자의 선택이 결과에 영향을 주는 몰입형 상호작용 구조를 구현했습니다.",
      "게임, 커뮤니티, AI, 채팅을 결합한 복합형 팬 경험 플랫폼으로 설계했습니다.",
    ], 60, 154, 550, 438);
    addAccentNote(slide, "확장성: 엔터 협업, 실제 데이터 연동, 시즌제 이벤트, IP 확장, 팬덤 커뮤니티 확장", 60, 606, 550, 50);
    await addImage(slide, "03_trainee_index_overview.png", 638, 154, 278, 502, "cover");
    await addImage(slide, "04_ingame_choice_scene.png", 934, 154, 286, 502, "cover");
  }

  // 5
  {
    const slide = presentation.slides.add();
    addTitle(slide, 5, "프로젝트 상세 - 서비스 한눈에 보기", "메인페이지를 허브로 회원, 게임, 커뮤니티, 상점, 운영 기능이 자연스럽게 이어집니다.");
    addBullets(slide, [
      "회원 시스템, 커뮤니티, 도감/수집, 캐스팅/뽑기, 인게임, AI/실시간 채팅, 관리자 기능을 통합했습니다.",
      "기능이 따로 존재하는 것이 아니라 하나의 사용자 흐름 안에서 연결되도록 설계했습니다.",
      "메인페이지는 서비스 로비이자 콘텐츠 허브로 동작합니다.",
    ], 64, 166, 410, 232);
    addAccentNote(slide, "메인에서 주요 기능으로 바로 이동할 수 있어 서비스 진입 장벽을 낮췄습니다.", 64, 416, 410, 74);
    await addImage(slide, "05_main_feature_hub.png", 504, 154, 716, 520, "cover");
  }

  // 6
  {
    const slide = presentation.slides.add();
    addTitle(slide, 6, "프로젝트 상세 - 시스템 구조도", "웹 프론트엔드와 Spring Boot 서버를 중심으로 DB, ML, 실시간 채팅, 결제가 연결됩니다.");
    addBullets(slide, [
      "Frontend: JSP / JavaScript / CSS / JSTL",
      "Backend: Spring Boot / JPA / Security",
      "Database: H2",
      "AI/ML: Python 예측 서버",
      "Realtime: WebSocket, Payment: KakaoPay, Launcher: BAT / VBS",
    ], 70, 154, 360, 290);
    await addImage(slide, "06_system_architecture.png", 460, 150, 730, 470, "contain");
  }

  // 7
  {
    const slide = presentation.slides.add();
    addTitle(slide, 7, "프로젝트 상세 - ERD", "회원, 커뮤니티, 연습생, 포토카드, 상점, 게임, 채팅 데이터를 중심으로 설계했습니다.");
    addBullets(slide, [
      "회원 중심으로 커뮤니티, 수집, 거래, 게임 실행 기록이 연결됩니다.",
      "연습생과 포토카드, 강화와 보유 상태를 분리해 수집형 구조를 명확하게 관리합니다.",
      "게임 실행 기록과 채팅 데이터도 운영 및 확장 관점에서 분리 설계했습니다.",
    ], 60, 154, 360, 250);
    await addImage(slide, "07_erd_summary.png", 440, 140, 760, 520, "contain");
  }

  // 8
  {
    const slide = presentation.slides.add();
    addTitle(slide, 8, "메인페이지 - 첫 인상과 몰입 요소", "메인페이지는 서비스의 세계관을 전달하는 로비이자 첫 진입 경험입니다.");
    addBullets(slide, [
      "메인 히어로 배너와 브랜드 타이틀을 통해 프로젝트 정체성을 강하게 전달합니다.",
      "게임, 가이드, 도감, 게시판, 상점으로 자연스럽게 이동할 수 있도록 설계했습니다.",
      "BGM 기능을 넣어 단순 화면이 아니라 무대에 입장하는 느낌을 강화했습니다.",
    ], 60, 154, 420, 260);
    await addImage(slide, "08_main_hero_title.png", 506, 154, 500, 270, "cover");
    await addImage(slide, "09_main_bgm_ui.png", 1022, 154, 196, 144, "contain");
    addAccentNote(slide, "메인페이지는 메뉴가 아니라 ‘프로듀싱 세계에 입장하는 로비’의 역할을 수행합니다.", 60, 612, 1158, 42);
  }

  // 9
  {
    const slide = presentation.slides.add();
    addTitle(slide, 9, "메인페이지 - 대시보드형 구성", "랭킹, 인기 게시글, 추천 아이템을 한 화면에 배치해 재방문 동기를 만듭니다.");
    addBullets(slide, [
      "메인 하단에는 LIVE PICK, TOP 랭킹, 인기 게시글, 인기 아이템 요약 정보를 제공합니다.",
      "사용자는 첫 화면에서 현재 인기 콘텐츠와 주요 진입 포인트를 빠르게 파악할 수 있습니다.",
      "콘텐츠 허브 구조로 설계해 단순 진입 화면 이상의 역할을 하도록 만들었습니다.",
    ], 62, 164, 360, 260);
    await addImage(slide, "10_main_dashboard_panels.png", 448, 148, 772, 520, "cover");
  }

  // 10
  {
    const slide = presentation.slides.add();
    addTitle(slide, 10, "회원가입 / 로그인", "일반 회원가입과 소셜 로그인, 입력 검증, 이메일 인증까지 모두 지원합니다.");
    addBullets(slide, [
      "일반 회원가입 및 로그인 기능을 제공합니다.",
      "아이디 / 닉네임 중복 확인, 이메일 인증 코드 발송 및 검증을 지원합니다.",
      "비밀번호 유효성 검사와 입력값 검증을 적용했습니다.",
      "카카오 / 구글 / 네이버 기반 소셜 로그인 및 회원가입을 지원합니다.",
      "카카오 주소 API를 연동해 회원가입 입력 경험을 개선했습니다.",
    ], 56, 156, 420, 360);
    await addImage(slide, "12_signup_form.png", 500, 154, 230, 252, "contain");
    await addImage(slide, "12_signup_form2.png", 744, 154, 474, 252, "contain");
    await addImage(slide, "13_login_social.png", 500, 424, 718, 236, "contain");
  }

  // 11
  {
    const slide = presentation.slides.add();
    addTitle(slide, 11, "마이페이지 - 사용자 정보와 대표 설정", "계정 정보, 대표 연습생, 코인, 플레이 기록을 한곳에서 관리할 수 있습니다.");
    addBullets(slide, [
      "프로필 이미지, 닉네임, 이메일, 비밀번호를 수정할 수 있습니다.",
      "대표 연습생 및 프로필 카드 연습생 설정 기능을 제공합니다.",
      "보유 코인, 아이템, 최근 플레이 내역과 통계를 대시보드 형태로 확인할 수 있습니다.",
      "게임 기록과 커뮤니티 활동을 함께 보여줘 누적 활동의 가치를 드러냅니다.",
    ], 62, 156, 390, 320);
    await addImage(slide, "14_mypage_profile.png", 476, 150, 564, 514, "cover");
    await addImage(slide, "15_mypage_settings.png", 1058, 150, 160, 220, "contain");
  }

  // 12
  {
    const slide = presentation.slides.add();
    addTitle(slide, 12, "게시판 - 통합 커뮤니티 구조", "공지, 자유게시판, 라운지, 공략, 팬미팅, 신고 게시판을 통합 운영합니다.");
    addBullets(slide, [
      "게시글 작성, 조회, 수정, 삭제와 댓글/좋아요/신고 기능을 제공합니다.",
      "검색, 카테고리 분리, 필터 기능으로 원하는 게시글을 빠르게 찾을 수 있습니다.",
      "운영 공지와 유저 커뮤니티를 같은 구조 안에서 유연하게 관리합니다.",
    ], 64, 160, 378, 250);
    await addImage(slide, "17_board_list_tabs.png", 470, 154, 352, 506, "contain");
    await addImage(slide, "18_board_detail_comment.png", 842, 154, 378, 506, "contain");
  }

  // 13
  {
    const slide = presentation.slides.add();
    addTitle(slide, 13, "팬미팅 / 위치 기반 게시판", "장소와 일정, 참여 상태까지 함께 관리하는 이벤트형 커뮤니티 구조입니다.");
    addBullets(slide, [
      "팬미팅 게시판은 위치, 좌표, 일정, 모집 상태를 함께 다루는 구조입니다.",
      "지도와 캘린더를 활용해 일반 게시판보다 더 적극적인 참여 흐름을 만듭니다.",
      "참가 신청, 선정, 제외 등 운영 동선도 서비스 안에서 이어집니다.",
    ], 56, 156, 332, 250);
    await addImage(slide, "19_fanmeeting_board_map.png", 408, 150, 406, 240, "contain");
    await addImage(slide, "20_fanmeeting_calendar.png", 828, 150, 390, 240, "contain");
    await addImage(slide, "20_fanmeeting_calendar2.png", 408, 404, 810, 246, "contain");
  }

  // 14
  {
    const slide = presentation.slides.add();
    addTitle(slide, 14, "가이드 페이지", "게임 규칙과 진행 흐름을 미리 이해하도록 돕는 온보딩 화면입니다.");
    addBullets(slide, [
      "게임 진행 방식, 능력치, 턴, 이벤트, 평가 구조를 정리해 보여줍니다.",
      "초기 진입 장벽을 낮춰 사용자가 빠르게 플레이 구조를 파악할 수 있습니다.",
      "정보 전달뿐 아니라 서비스 세계관과 룰을 자연스럽게 연결하는 역할도 합니다.",
    ], 60, 156, 360, 252);
    await addImage(slide, "21_guide_hero.png", 444, 150, 380, 506, "contain");
    await addImage(slide, "22_guide_system_cards.png", 842, 150, 376, 506, "contain");
  }

  // 15
  {
    const slide = presentation.slides.add();
    addTitle(slide, 15, "도감 - 목록 화면", "연습생 도감은 수집형 콘텐츠의 핵심이며, 해금 여부를 통해 수집 욕구를 강화합니다.");
    addBullets(slide, [
      "연습생 카드 목록과 성별, 등급, 그룹, 검색, 정렬 필터를 제공합니다.",
      "기본 프로필과 능력치를 카드 단위로 빠르게 탐색할 수 있습니다.",
      "카드 해금 시스템을 통해 획득한 연습생만 상세 정보에 접근할 수 있도록 구성했습니다.",
      "미해금 카드는 잠금 상태로 보여주어 수집 목표를 명확하게 만듭니다.",
    ], 58, 156, 358, 342);
    await addImage(slide, "23_trainee_index_list.png", 436, 150, 320, 500, "contain");
    await addImage(slide, "24_trainee_index_filters.png", 772, 150, 220, 238, "contain");
    await addImage(slide, "24_1_trainee_locked_cards.png", 1008, 150, 210, 500, "contain");
  }

  // 16
  {
    const slide = presentation.slides.add();
    addTitle(slide, 16, "도감 - 상세 정보 / 포토카드 / 강화", "단순 수집을 넘어 프로필 확인, 포토카드 장착, 강화까지 이어지는 성장 구조입니다.");
    addBullets(slide, [
      "능력치, 성별, 등급, 취미, 좌우명, 인스타그램 등 상세 프로필을 제공합니다.",
      "포토카드 장착 여부와 등급에 따라 능력치 보정이 연동됩니다.",
      "강화 시스템을 통해 카드 수집이 성장 메타로 연결되도록 구성했습니다.",
    ], 60, 156, 362, 258);
    await addImage(slide, "25_trainee_detail_profile.png", 446, 150, 308, 500, "contain");
    await addImage(slide, "26_trainee_detail_photocard.png", 770, 150, 308, 500, "contain");
    await addImage(slide, "27_trainee_detail_enhance.png", 1092, 150, 126, 220, "contain");
  }

  // 17
  {
    const slide = presentation.slides.add();
    addTitle(slide, 17, "길거리 캐스팅", "새로운 연습생을 획득하는 탐색형 시스템으로, 수집의 시작점 역할을 합니다.");
    addBullets(slide, [
      "지역 선택과 탐색 흐름을 통해 길거리 캐스팅의 분위기를 서비스 안에 녹였습니다.",
      "탐색 결과는 이후 연습생 획득과 뽑기 흐름에 자연스럽게 연결됩니다.",
      "단순 획득이 아니라 이벤트를 체험하는 느낌을 주도록 설계했습니다.",
    ], 62, 160, 350, 244);
    await addImage(slide, "28_casting_map_explore.png", 438, 150, 548, 500, "contain");
    await addImage(slide, "29_casting_result.png", 1004, 220, 214, 300, "contain");
  }

  // 18
  {
    const slide = presentation.slides.add();
    addTitle(slide, 18, "상점 - 아이템 구매 시스템", "능력치 성장과 전략 소비가 연결되는 아이템 상점입니다.");
    addBullets(slide, [
      "보컬, 댄스, 스타성, 멘탈, 팀워크와 연결된 성장 아이템을 제공합니다.",
      "패키지 아이템과 개별 아이템 구매를 지원합니다.",
      "재화 소비 자체가 인게임 전략이 되도록 설계했습니다.",
    ], 60, 160, 358, 240);
    await addImage(slide, "30_shop_main.png", 440, 150, 454, 500, "contain");
    await addImage(slide, "31_shop_item_modal.png", 914, 182, 304, 436, "contain");
  }

  // 19
  {
    const slide = presentation.slides.add();
    addTitle(slide, 19, "상점 - 코인 충전 / 결제 흐름", "카카오페이 기반 코인 충전으로 서비스형 BM 확장 가능성을 확보했습니다.");
    addBullets(slide, [
      "코인 충전은 상점 구매, 연습생 뽑기, 포토카드 수집과 직접 연결됩니다.",
      "결제 플로우를 서비스 화면 안에서 자연스럽게 이어지도록 구현했습니다.",
      "실서비스 확장을 고려한 유료 재화 흐름을 검증했습니다.",
    ], 60, 160, 340, 240);
    await addImage(slide, "32_shop_coin_charge.png", 422, 150, 486, 500, "contain");
    await addImage(slide, "33_kakaopay_flow.png", 930, 190, 288, 360, "contain");
  }

  // 20
  {
    const slide = presentation.slides.add();
    addTitle(slide, 20, "가챠 / 연습생 뽑기", "등급별 연습생을 획득하고 보유 상태와 연동하는 수집 흐름입니다.");
    addBullets(slide, [
      "연속 뽑기, 결과 확인, 보유 목록 반영까지 하나의 흐름으로 구성했습니다.",
      "등급과 중복 여부를 명확히 보여주어 수집의 재미를 높였습니다.",
      "이벤트 풀과 기본 풀 구조로 확률형 콘텐츠의 확장 여지도 남겼습니다.",
    ], 60, 158, 348, 248);
    await addImage(slide, "34_gacha_main.png", 430, 150, 402, 500, "contain");
    await addImage(slide, "35_gacha_result.png", 850, 180, 368, 430, "contain");
  }

  // 21
  {
    const slide = presentation.slides.add();
    addTitle(slide, 21, "포토카드 뽑기", "연습생 수집과 별도로 포토카드 메타를 구축해 장착과 강화 흐름을 확장했습니다.");
    addBullets(slide, [
      "포토카드 전용 뽑기에서 1회, 5회, 10회 구조를 제공합니다.",
      "획득한 포토카드는 도감, 장착, 강화와 연결됩니다.",
      "연습생 수집 외에 별도 성장 루프를 제공하는 메타 콘텐츠입니다.",
    ], 60, 158, 348, 248);
    await addImage(slide, "36_photocard_pull_main.png", 430, 150, 404, 500, "contain");
    await addImage(slide, "37_photocard_pull_result.png", 852, 188, 366, 420, "contain");
  }

  // 22
  {
    const slide = presentation.slides.add();
    addTitle(slide, 22, "인게임 진입 - 게임 시작 및 그룹 선택", "게임 시작 버튼 이후, 플레이 콘셉트를 정하는 첫 선택 단계가 시작됩니다.");
    addBullets(slide, [
      "혼성, 보이그룹, 걸그룹 중 원하는 그룹 유형을 선택할 수 있습니다.",
      "그룹 선택은 이후 로스터 구성과 플레이 방향에 영향을 줍니다.",
      "단순 시작 버튼이 아니라 팀 콘셉트를 정하는 첫 전략 선택입니다.",
    ], 62, 164, 360, 252);
    await addImage(slide, "38_game_start_modal.png", 448, 150, 770, 500, "contain");
  }

  // 23
  {
    const slide = presentation.slides.add();
    addTitle(slide, 23, "인게임 진입 - 로스터 구성 화면", "본격적인 플레이 전, 멤버 조합과 아이템, 성격을 설정하는 전략 준비 단계입니다.");
    addBullets(slide, [
      "선발된 멤버와 팀 케미를 확인하며 로스터를 구성합니다.",
      "리롤 기능으로 팀 구성을 다시 시도할 수 있습니다.",
      "아이템 적용과 성격 선택으로 초반 스탯과 팀 방향을 조정할 수 있습니다.",
    ], 58, 158, 348, 256);
    await addImage(slide, "39_roster_team_build.png", 428, 148, 402, 504, "contain");
    await addImage(slide, "40_roster_reroll_item_apply.png", 846, 148, 372, 504, "contain");
  }

  // 24
  {
    const slide = presentation.slides.add();
    addTitle(slide, 24, "인게임 - 기본 플레이 화면", "좌측 팀 패널, 중앙 스토리/선택, 우측 컨디션 모니터가 한 화면에서 동시에 동작합니다.");
    addBullets(slide, [
      "인게임은 선택 기반 육성 시뮬레이션 구조로 진행됩니다.",
      "좌측에는 DAY, 요일, 시간, 피로도, 능력치 상태를 보여주는 팀 패널이 있습니다.",
      "중앙에는 현재 상황과 스토리, 선택 맥락이 표시됩니다.",
      "우측에는 집중도, 스트레스, 컨디션, 팀워크 등 현재 상태 지표를 배치했습니다.",
      "단순 텍스트가 아니라 UI 전체로 상황 몰입감을 높였습니다.",
    ], 56, 156, 344, 342);
    await addImage(slide, "41_ingame_main_full.png", 420, 148, 798, 510, "contain");
  }

  // 25
  {
    const slide = presentation.slides.add();
    addTitle(slide, 25, "인게임 - 선택지 / 결과 반영 / 능력치 변화", "사용자 입력을 ML 기반으로 해석해 게임 결과와 능력치 변화에 반영합니다.");
    addBullets(slide, [
      "사용자의 채팅 입력을 머신러닝 기반으로 분석해 행동 결과를 예측합니다.",
      "예측된 선택 성향에 따라 VOCAL, DANCE, STAR, MENTAL, TEAMWORK 변화가 적용됩니다.",
      "피로도와 상태 변화도 함께 표시해 결과를 직관적으로 이해할 수 있습니다.",
      "선택 → 예측 → 결과 반영 흐름으로 인게임 상호작용의 깊이를 높였습니다.",
    ], 58, 156, 356, 320);
    await addImage(slide, "42_ingame_chat_input.png", 432, 152, 180, 500, "contain");
    await addImage(slide, "42_ingame_chat_input2.png", 626, 152, 170, 500, "contain");
    await addImage(slide, "43_ingame_result_delta.png", 812, 152, 406, 236, "contain");
    addAccentNote(slide, "ML 예측 로그를 통해 RULE 기반 fallback 여부와 confidence를 함께 확인할 수 있도록 구성했습니다.", 812, 414, 406, 84, "#f6f1ff");
  }

  // 26
  {
    const slide = presentation.slides.add();
    addTitle(slide, 26, "인게임 - 탈락 시스템 / 상태 이상 / 진행 리스크", "팀 운영을 잘못하면 상태 악화와 탈락으로 이어지는 리스크 구조를 설계했습니다.");
    await addImage(slide, "44_ingame_elimination_risk2.png", 54, 148, 820, 514, "contain");
    addCard(slide, 896, 158, 322, 492, "#ffffffdc", 0.18);
    const riskBullets = [
      "피로도 누적",
      "상태 이상 발생",
      "선택 리스크 누적",
      "멤버 탈락 가능성",
      "팀 전체 운영 전략 필요",
    ];
    let y = 204;
    for (const item of riskBullets) {
      addCard(slide, 924, y, 22, 22, "#ffe7f1", 0.5);
      addText(slide, item, 958, y - 2, 220, 28, {
        fontSize: 20,
        bold: true,
      });
      y += 74;
    }
    addText(slide, "컨디션 19% 이하, 팀워크 0%, 스트레스 100% 같은 조건은 단순 수치가 아니라 실제 실패/탈락 결과와 연결됩니다.", 924, 528, 252, 86, {
      fontSize: 18,
      color: COLORS.inkSoft,
    });
  }

  // 27
  {
    const slide = presentation.slides.add();
    addTitle(slide, 27, "인게임 - 엔딩 / 데뷔 결과", "플레이 종료 후 최종 점수, 등급, 팀 결과, 보상을 리포트형 화면으로 제공합니다.");
    addBullets(slide, [
      "등급 연출과 함께 플레이 종료 분위기를 전달합니다.",
      "상위 멤버 4인, 최종 능력치, 랭킹, 보상 정보를 한 화면에 정리합니다.",
      "다시 플레이하고 싶은 동기를 주는 회고형 결과 화면입니다.",
    ], 58, 158, 346, 244);
    await addImage(slide, "45_ending_intro_grade.png", 426, 152, 288, 220, "contain");
    await addImage(slide, "46_ending_result_dashboard.png", 732, 152, 486, 504, "contain");
  }

  // 28
  {
    const slide = presentation.slides.add();
    addTitle(slide, 28, "랭킹 시스템", "엔딩 결과를 순위로 연결해 반복 플레이와 경쟁 요소를 강화했습니다.");
    addBullets(slide, [
      "플레이 결과를 점수 기반 순위로 제공해 성취감을 만듭니다.",
      "메인페이지와 엔딩 화면에서 랭킹으로 자연스럽게 이동할 수 있습니다.",
      "비교와 경쟁 요소를 통해 플랫폼 체류와 재도전을 유도합니다.",
    ], 60, 160, 332, 236);
    await addImage(slide, "47_ranking_list.png", 416, 148, 802, 510, "contain");
  }

  // 29
  {
    const slide = presentation.slides.add();
    addTitle(slide, 29, "AI 챗봇", "서비스 내 보조 인터페이스로서 안내와 대화형 상호작용 경험을 제공합니다.");
    addBullets(slide, [
      "AI 챗봇 위젯을 통해 사용자가 즉시 질문하고 응답을 받을 수 있습니다.",
      "안내형 기능뿐 아니라 서비스 몰입을 돕는 대화형 요소로 활용할 수 있습니다.",
      "메인 경험을 방해하지 않도록 플로팅 인터페이스로 구성했습니다.",
    ], 62, 160, 360, 244);
    await addImage(slide, "48_ai_chat_widget.png", 478, 170, 280, 420, "contain");
    addAccentNote(slide, "사용자 경험을 풍부하게 만드는 서브 인터페이스", 824, 268, 300, 56, "#f7f0ff");
  }

  // 30
  {
    const slide = presentation.slides.add();
    addTitle(slide, 30, "실시간 채팅방", "WebSocket 기반 실시간 채팅으로 팬 간 즉시 상호작용이 가능하도록 구성했습니다.");
    addBullets(slide, [
      "채팅방 목록, 참여중 탭, 비밀방 여부 등 커뮤니티 운영 요소를 제공합니다.",
      "메시지 송수신이 실시간으로 반영되어 사용자 간 즉각적인 대화가 가능합니다.",
      "플랫폼 내부 상호작용을 강화하는 핵심 실시간 기능입니다.",
    ], 58, 160, 348, 244);
    await addImage(slide, "49_chatroom_list.png", 432, 156, 360, 500, "contain");
    await addImage(slide, "50_chatroom_live_messages.png", 810, 156, 408, 500, "contain");
  }

  // 31
  {
    const slide = presentation.slides.add();
    addTitle(slide, 31, "관리자페이지 - 운영 대시보드", "회원, 게임, 상점, 게시판 데이터를 한눈에 모니터링하는 운영 중심 화면입니다.");
    addBullets(slide, [
      "총 회원 수, 총 게임 플레이, 완료 게임 수, 코인 사용량 등 KPI를 집계합니다.",
      "최근 운영 현황과 게임 추이, 페이지 분포, 코인 흐름을 함께 보여줍니다.",
      "단순 CRUD가 아니라 서비스 상태를 파악하는 운영 대시보드 역할을 수행합니다.",
    ], 56, 158, 336, 254);
    await addImage(slide, "51_admin_dashboard_overview.png", 414, 150, 804, 248, "contain");
    await addImage(slide, "52_admin_kpi_panels.png", 414, 410, 804, 242, "contain");
  }

  // 32
  {
    const slide = presentation.slides.add();
    addTitle(slide, 32, "관리자페이지 - 회원 운영", "회원 상태, 코인, 등급, 제재, 보유 자산까지 세밀하게 조정할 수 있습니다.");
    addBullets(slide, [
      "회원 목록 조회, 검색, 페이징, 상태 확인을 지원합니다.",
      "상세 모달에서 등급 조정, 코인 지급/차감, 제재, 보유 연습생/포토카드 관리를 수행할 수 있습니다.",
      "운영 관점에서 매우 높은 제어 권한을 가진 관리 화면입니다.",
    ], 56, 158, 342, 252);
    await addImage(slide, "53_admin_member_list.png", 420, 150, 380, 504, "contain");
    await addImage(slide, "54_admin_member_detail_modal.png", 816, 150, 190, 504, "contain");
    await addImage(slide, "54_admin_member_detail_modal2.png", 1018, 150, 200, 504, "contain");
  }

  // 33
  {
    const slide = presentation.slides.add();
    addTitle(slide, 33, "관리자페이지 - 게임 운영", "스토리형 게임 콘텐츠를 운영 화면에서 직접 유지보수할 수 있도록 구성했습니다.");
    addBullets(slide, [
      "게임 데이터 요약과 ML 통계, phase/choice/event 관리 동선을 제공합니다.",
      "선택지, 채팅 매핑, 이벤트 문제를 운영자가 직접 수정할 수 있습니다.",
      "확장성과 운영 효율을 높이는 콘텐츠 관리 도구입니다.",
    ], 56, 158, 334, 252);
    await addImage(slide, "55_admin_game_scene_manage.png", 412, 150, 308, 504, "contain");
    await addImage(slide, "56_admin_game_choice_manage.png", 736, 150, 238, 504, "contain");
    await addImage(slide, "57_admin_game_event_manage.png", 990, 150, 228, 504, "contain");
  }

  // 34
  {
    const slide = presentation.slides.add();
    addTitle(slide, 34, "관리자페이지 - 연습생 / 포토카드 / 강화 관리", "게임 핵심 자산 데이터를 운영자가 직접 조정할 수 있도록 구현했습니다.");
    addBullets(slide, [
      "연습생 마스터 데이터 추가, 수정, 삭제를 지원합니다.",
      "포토카드 지급 상태와 보유 등급, 강화 수치를 관리할 수 있습니다.",
      "특정 회원 대상 카드 지급과 강화 반영도 관리 화면에서 수행할 수 있습니다.",
    ], 56, 158, 344, 252);
    await addImage(slide, "58_admin_trainee_grid.png", 420, 150, 384, 504, "contain");
    await addImage(slide, "59_admin_photocard_manage.png", 824, 150, 394, 504, "contain");
  }

  // 35
  {
    const slide = presentation.slides.add();
    addTitle(slide, 35, "관리자페이지 - 게시판 / 신고 / 팬미팅 관리", "커뮤니티 안정성과 운영 효율을 위한 후방 운영 기능도 함께 구성했습니다.");
    addBullets(slide, [
      "공지사항 작성/수정/삭제와 상단 고정 처리를 할 수 있습니다.",
      "신고 접수 현황을 보고 상세 확인, 블라인드, 처리 조치를 수행할 수 있습니다.",
      "팬미팅 모집 상태와 참가자 수, 게시글 운영 상태를 함께 관리합니다.",
    ], 56, 158, 344, 252);
    await addImage(slide, "60_admin_notice_manage.png", 420, 150, 252, 504, "contain");
    await addImage(slide, "61_admin_report_manage.png", 688, 150, 252, 504, "contain");
    await addImage(slide, "62_admin_fanmeeting_manage.png", 956, 150, 262, 504, "contain");
  }

  // 36 schedule
  {
    const slide = presentation.slides.add();
    addTitle(slide, 36, "진행 프로세스 - 개발 일정", "기획부터 통합 테스트와 안정화까지 단계적으로 진행했습니다.");
    addCard(slide, 74, 170, 1134, 430, "#ffffffde", 0.18);
    const phases = [
      ["1주차", "기획 및 요구사항 정의", "#fff2f7"],
      ["2주차", "서비스 구조 설계 및 DB 설계", "#f7f1ff"],
      ["3~5주차", "핵심 기능 개발", "#fdf6ec"],
      ["6주차", "기능 통합 및 테스트", "#eefbf7"],
      ["7주차", "UI/UX 개선 및 안정화", "#eef5ff"],
    ];
    let x = 108;
    for (const [period, name, fill] of phases) {
      addCard(slide, x, 286, 190, 160, fill, 0.2);
      addText(slide, period, x + 24, 314, 142, 24, {
        fontSize: 18,
        bold: true,
        color: COLORS.pinkDeep,
      });
      addText(slide, name, x + 24, 356, 142, 64, {
        fontSize: 18,
        bold: true,
      });
      x += 208;
    }
    slide.shapes.add({
      geometry: "rect",
      position: { left: 146, top: 250, width: 930, height: 6 },
      fill: COLORS.lavender,
      line: { width: 0, fill: COLORS.lavender },
    });
  }

  // 37 roles
  {
    const slide = presentation.slides.add();
    addTitle(slide, 37, "진행 프로세스 - 역할 분담", "기능 단위가 아니라 서비스 흐름 중심으로 역할을 분리하고 최종 통합을 진행했습니다.");
    addCard(slide, 50, 148, 1180, 532, "#ffffffdc", 0.16);
    const headers = [
      { label: "문성훈", left: 70, width: 360, fill: "#fff1f7" },
      { label: "이슬기", left: 450, width: 360, fill: "#f7f0ff" },
      { label: "방혜은", left: 830, width: 360, fill: "#f7fffc" },
    ];
    for (const h of headers) {
      addCard(slide, h.left, 180, h.width, 454, h.fill, 0.18);
      addText(slide, h.label, h.left + 22, 206, h.width - 44, 28, {
        fontSize: 26,
        bold: true,
        color: COLORS.pinkDeep,
      });
    }
    addText(slide, "프로젝트 총괄\n구조 설계\n로그인/회원가입\n도감/가이드/팬미팅\n연습생/포토카드 뽑기\nML 예측 시스템 연동\n관리자 로직\n런처 통합\nBGM\n코드 통합 및 리팩토링", 92, 258, 316, 342, {
      fontSize: 17,
    });
    addText(slide, "프론트엔드\n인게임 UI / 진행 인터랙션\n선택지 결과 반영 UI\n길거리 캐스팅 UI\n마이페이지\n메인페이지 공동 구현\nAI 챗봇 UI\n공통 레이아웃", 472, 258, 316, 310, {
      fontSize: 17,
    });
    addText(slide, "상점 및 구매 흐름\n코인 차감 / 카카오페이\n게시판 CRUD\n커뮤니티 안정화\n실시간 채팅\n테스트 및 유지보수", 852, 258, 316, 250, {
      fontSize: 17,
    });
  }

  // 38 tech
  {
    const slide = presentation.slides.add();
    addTitle(slide, 38, "진행 프로세스 - 개발환경", "백엔드, 프론트엔드, AI, 빌드, 런타임을 명확히 분리해 개발했습니다.");
    const stacks = [
      ["Backend", "Java 21\nSpring Boot 4.0.5\nSpring Security\nOAuth2 Client\nSpring Data JPA\nSpring WebSocket"],
      ["Frontend", "JSP\nJavaScript\nCSS\nJSTL"],
      ["Database", "H2\nJPA"],
      ["AI / ML", "Python 예측 시스템"],
      ["Build / Runtime", "Gradle\nGradle Wrapper\nEmbedded Tomcat\nWAR 구조"],
      ["Etc", "Lombok\nDevTools\nCommons IO\nJackson Databind\nBAT / VBS Launcher"],
    ];
    let x = 70;
    let y = 170;
    for (let i = 0; i < stacks.length; i++) {
      addCard(slide, x, y, 350, 148, i % 2 === 0 ? "#fff5fa" : "#f7f2ff", 0.18);
      addText(slide, stacks[i][0], x + 20, y + 18, 310, 28, {
        fontSize: 22,
        bold: true,
        color: COLORS.pinkDeep,
      });
      addText(slide, stacks[i][1], x + 20, y + 56, 310, 82, {
        fontSize: 16,
      });
      x += 380;
      if (x > 800) {
        x = 70;
        y += 180;
      }
    }
  }

  // 39 ending
  {
    const slide = presentation.slides.add();
    addTitle(slide, 39, "마치며", "NEXT DEBUT는 단순 게임이 아니라 팬 참여형 플랫폼으로 확장 가능한 서비스입니다.");
    addCard(slide, 98, 176, 1084, 378, "#ffffffdc", 0.2);
    addText(slide, "서비스 완성도", 140, 236, 260, 36, {
      fontSize: 28,
      bold: true,
      color: COLORS.pinkDeep,
    });
    addText(slide, "게임, 커뮤니티, AI, 결제, 관리자 기능까지 하나의 서비스 흐름 안에서 통합 구현했습니다.", 140, 286, 420, 80, {
      fontSize: 22,
    });
    addText(slide, "확장 가능성", 620, 236, 260, 36, {
      fontSize: 28,
      bold: true,
      color: COLORS.lavenderDeep,
    });
    addText(slide, "연습생 성장 서사를 중심으로 엔터테인먼트 협업, 시즌 운영, IP 확장, 팬덤 커뮤니티 플랫폼으로 발전할 수 있습니다.", 620, 286, 420, 96, {
      fontSize: 22,
    });
    addAccentNote(slide, "단순 게임이 아닌, 팬 참여형 플랫폼으로 확장 가능한 서비스", 194, 576, 892, 62, "#fff1f8");
  }

  // 40 QA
  {
    const slide = presentation.slides.add();
    addBg(slide);
    addCard(slide, 118, 126, 1044, 472, "#ffffffdc", 0.22);
    addText(slide, "Q&A", 0, 236, 1280, 70, {
      fontSize: 54,
      bold: true,
      alignment: "center",
      color: COLORS.pinkDeep,
    });
    addText(slide, "감사합니다", 0, 322, 1280, 40, {
      fontSize: 28,
      bold: true,
      alignment: "center",
      color: COLORS.ink,
    });
    addText(slide, "Q&A 이후 시연을 진행하겠습니다.", 0, 378, 1280, 32, {
      fontSize: 22,
      alignment: "center",
      color: COLORS.inkSoft,
    });
  }

  const pptx = await PresentationFile.exportPptx(presentation);
  await pptx.save(PPT_PATH);
  console.log(`Saved: ${PPT_PATH}`);
}

await build();
