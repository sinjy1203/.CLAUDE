# ============================================
# PROJECT_NAME 모노레포 통합 명령어
# ============================================

.PHONY: install install-fe install-be install-ai \
        db db-down dev-local dev-fe dev-be dev-ai \
        test test-fe test-be test-ai \
        prod prod-down

# --- 의존성 설치 ---
install: install-fe install-be install-ai

install-fe:
	cd frontend && pnpm install

install-be:
	cd backend && ./gradlew dependencies

install-ai:
	cd ai && uv sync

# --- 개발 서버 ---
db:
	docker compose -f infra/docker-compose.db.yml up -d

db-down:
	docker compose -f infra/docker-compose.db.yml down

dev-local:
	$(MAKE) -j3 dev-fe dev-be dev-ai

dev-fe:
	cd frontend && pnpm dev

dev-be:
	cd backend && ./gradlew bootRun

dev-ai:
	cd ai && uv run uvicorn src.api.main:app --reload --port 8001

# --- 테스트 ---
test: test-fe test-be test-ai

test-fe:
	cd frontend && pnpm test

test-be:
	cd backend && ./gradlew test

test-ai:
	cd ai && uv run pytest

# --- 운영 서버 ---
prod:
	docker compose -f infra/docker-compose.yml up --build

prod-down:
	docker compose -f infra/docker-compose.yml down
