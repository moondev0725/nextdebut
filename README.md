<div align="center">

![NEXTDEBUT Logo](assets/nextdebut-logo.png)

# NEXTDEBUT

아이돌 육성, 커뮤니티, 소셜 로그인, 결제, AI 보조 기능을 하나로 담은 Spring Boot 기반 웹 프로젝트

</div>

## Overview

NEXTDEBUT는 사용자가 연습생을 성장시키고, 게임 플레이로 재화를 획득하고, 상점과 뽑기 시스템을 활용하며, 커뮤니티와 개인화 기능까지 함께 이용할 수 있도록 구성한 웹 서비스입니다.

### 핵심 포인트

- 아이돌 연습생 육성 중심의 게임형 서비스
- 일반 로그인과 카카오 / 구글 / 네이버 소셜 로그인 지원
- 포토카드, 상점, 재화, 결제 흐름까지 연결된 순환 구조
- 커뮤니티와 사용자별 데이터 기반 기능 제공
- Python ML 서버와 연동되는 일부 보조 기능 포함

## Features

| 구분 | 내용 |
| --- | --- |
| 인증 | 일반 회원가입 / 로그인, 아이디·닉네임 중복 확인, 이메일 인증, 비밀번호 유효성 검사 |
| 소셜 로그인 | 카카오, 구글, 네이버 로그인 및 회원가입 |
| 게임 | 게임 플레이, 재화 획득, 성장 요소 연동 |
| 소비 시스템 | 상점 아이템 구매, 연습생 뽑기, 포토카드 뽑기 |
| 결제 | 카카오페이 기반 재화 충전 |
| 사용자 경험 | 로그인 후 개인화된 기능 및 사용자별 데이터 접근 |
| 확장 기능 | 커뮤니티, WebSocket, Python ML 연동 |

## Tech Stack

- Java 21
- Spring Boot 4
- Spring Security
- Spring Data JPA
- JSP
- H2 Database
- WebSocket
- Python ML

## Quick Start

프로젝트 실행은 아래 순서로 진행하면 됩니다.

1. 프로젝트 폴더는 항상 바탕화면에 둡니다.
2. 프로젝트 폴더로 이동합니다.
3. `바탕화면바로가기생성기.bat`를 실행해서 바탕화면에 런처를 생성합니다.
4. 기존 런처가 있다면 삭제 후 다시 생성합니다.
5. 바탕화면에 생성된 런처를 실행합니다.
6. 런처에서 `Server On` 버튼을 눌러 서버를 시작합니다.
7. 사용 후 `Server Off` 버튼으로 서버를 종료합니다.

## Access

- 메인 서비스: `http://localhost:8181`
- H2 콘솔: `http://localhost:8181/h2-console`

## Environment

OAuth, AI API 키 같은 민감한 값은 `src/main/resources/application-local.properties` 또는 환경 변수로 분리해서 관리하는 것을 권장합니다.

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

## Project Structure

```text
src/main/java        Java 소스
src/main/webapp      JSP 뷰
src/main/resources   설정 및 정적 리소스
python-ml            Python ML 서버 및 데이터
tools                실행 및 유틸 스크립트
outputs              PPT 및 산출물 파일
data                 로컬 H2 데이터베이스 파일
```

## Notes

- 기본 포트는 `8181`입니다.
- 로컬 DB는 `data/` 경로의 H2 파일 DB를 사용합니다.
- 프로젝트 실행 전 Java 21 환경을 권장합니다.
- 저장소에는 개발 과정에서 생성된 일부 로그, 데이터, 산출물이 포함되어 있을 수 있습니다.
