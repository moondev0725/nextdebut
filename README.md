# NEXTDEBUT

NEXTDEBUT는 아이돌 육성 게임과 커뮤니티, 결제, 소셜 로그인 기능을 결합한 Spring Boot 기반 웹 프로젝트입니다.

## 주요 기능

- 회원가입 / 로그인
- 카카오 / 구글 / 네이버 소셜 로그인
- 이메일 인증 및 입력값 검증
- 연습생 육성 및 게임 플레이
- 포토카드, 상점, 재화 시스템
- 커뮤니티 및 사용자별 데이터 기반 서비스
- 카카오페이 결제 연동

## 기술 스택

- Java 21
- Spring Boot 4
- Spring Security
- Spring Data JPA
- JSP
- H2 Database
- WebSocket
- Python ML 연동

## 실행 방법

### 1. 프로젝트 실행

```bash
./gradlew bootRun
```

Windows에서는 아래 파일로도 실행할 수 있습니다.

```powershell
NEXTDEBUT.bat
```

### 2. 접속 주소

- 메인 앱: `http://localhost:8181`
- H2 콘솔: `http://localhost:8181/h2-console`

## 환경 설정

OAuth, AI API 키 등 민감한 값은 `src/main/resources/application-local.properties` 또는 환경 변수로 분리해서 사용하는 것을 권장합니다.

예시:

```properties
OAUTH_KAKAO_CLIENT_ID=...
OAUTH_KAKAO_CLIENT_SECRET=...
OAUTH_GOOGLE_CLIENT_ID=...
OAUTH_GOOGLE_CLIENT_SECRET=...
OAUTH_NAVER_CLIENT_ID=...
OAUTH_NAVER_CLIENT_SECRET=...
GEMINI_API_KEY=...
APP_SECURITY_JUMIN_KEY=...
```

## 프로젝트 구조

```text
src/main/java        Java 소스
src/main/webapp      JSP 뷰
src/main/resources   설정 및 정적 리소스
python-ml            Python ML 서버 및 데이터
tools                실행/배포/유틸 스크립트
outputs              산출물 및 PPT 관련 파일
```

## 참고

- 기본 포트는 `8181`입니다.
- 로컬 DB는 `data/` 경로의 H2 파일 DB를 사용합니다.
- 실행 전 Java 21 환경이 준비되어 있는지 확인해 주세요.
