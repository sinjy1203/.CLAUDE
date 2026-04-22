---
name: polyglot-monorepo
description: >
  Frontend (TypeScript/React/Vite/pnpm) + Backend (Kotlin/Spring Boot/Gradle) + AI (Python/FastAPI/uv)
  세 가지 언어로 구성된 모노레포 디렉토리 구조를 구성할 때 사용하는 스킬.
  트리거: 새 모노레포 프로젝트 세팅, 모노레포 디렉토리 구성 요청, 세 서비스(frontend/backend/ai) 초기 구성.
---

# Polyglot Monorepo 구성 스킬

## 기술 스택

| 서비스 | 언어 | 프레임워크 | 패키지 매니저 |
|--------|------|------------|---------------|
| frontend | TypeScript | React + Vite | pnpm |
| backend | Kotlin | Spring Boot | Gradle |
| ai | Python | FastAPI | uv |

## 생성할 디렉토리 구조

```
PROJECT_ROOT/
├── frontend/
│   ├── Dockerfile
│   └── README.md
├── backend/
│   ├── Dockerfile
│   └── README.md
├── ai/
│   ├── Dockerfile
│   └── README.md
├── infra/
│   ├── docker-compose.yml      # 운영 (전체 스택)
│   └── docker-compose.db.yml   # 개발 (PostgreSQL만)
├── Makefile
├── .gitignore
├── .editorconfig
└── README.md
```

## 워크플로우

### 1. 프로젝트 이름 확인

사용자에게 프로젝트 이름을 확인한다. 이후 모든 파일에서 `PROJECT_NAME` 플레이스홀더를 실제 이름으로 치환한다.

### 2. assets/template 파일을 기반으로 생성

`assets/template/` 하위의 모든 파일을 참고하여 프로젝트 루트에 생성한다.
파일 내 `PROJECT_NAME`을 실제 프로젝트 이름으로 치환한다.

치환 대상:
- `infra/docker-compose.yml` — POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, SPRING_DATASOURCE_URL
- `infra/docker-compose.db.yml` — POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
- `Makefile` — 상단 주석

### 3. README.md 작성

루트 README.md와 각 서비스(frontend/backend/ai) README.md를 프로젝트에 맞게 작성한다.

**루트 README.md 구조:**
- 프로젝트 설명 한 줄
- `## 시작하기` — 필수 도구 테이블(서비스별), Frontend/Backend/AI 각 서비스 설명 및 주요 명령어
- `## Makefile 명령어` — 의존성 설치 / 개발 서버 / 테스트 / 운영 서버 단계별 테이블
- `## 디렉토리 구조` — 트리 구조

**루트 README.md 필수 도구 테이블:**

| 서비스 | 필요 도구 |
|--------|----------|
| Frontend | Node.js 20+, pnpm |
| Backend | Java 21+ |
| AI | uv |
| DB / 운영 서버 | Docker |

**개발 서버 섹션 주의:** `make db`로 PostgreSQL을 먼저 실행해야 한다고 명시한다.

**각 서비스 README.md:** 기술 스택, 포트, 시작 방법(`make` 명령어), 주요 명령어

## 포트 기본값

| 서비스 | 포트 |
|--------|------|
| Frontend | 3000 |
| Backend | 8080 |
| AI | 8001 |
| PostgreSQL | 5432 |

## Makefile 명령어 구조

4단계로 구성하며, 각 단계에 전체 실행 타겟과 서비스별 타겟이 함께 있다.

| 단계 | 전체 | 서비스별 |
|------|------|---------|
| 의존성 설치 | `install` | `install-fe` / `install-be` / `install-ai` |
| 개발 서버 | `db` / `db-down` / `dev-local` | `dev-fe` / `dev-be` / `dev-ai` |
| 테스트 | `test` | `test-fe` / `test-be` / `test-ai` |
| 운영 서버 | `prod` / `prod-down` | — |

**빌드 타겟 없음.** 운영 배포는 Dockerfile 내부에서 빌드가 처리되므로 Makefile에 별도 빌드 타겟을 두지 않는다.

## 주의사항

- `.github/` 워크플로우는 기본적으로 생성하지 않는다 (CI/CD는 별도 요청 시 추가)
- `infra/deploy/` 하위 폴더는 배포 전략이 정해진 후 추가한다
- Redis는 포함하지 않는다
- 루트 README.md에 기술 스택 테이블, 서비스 포트 테이블은 포함하지 않는다
