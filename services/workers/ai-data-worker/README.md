# FastAPI AI/Data Worker Scaffold

`services/workers/ai-data-worker`는 ONMU의 내부 FastAPI worker 위치다. Flutter가 직접 호출하는 공개 API가 아니라, Spring Main API가 queue/outbox를 통해 호출할 내부 실행 단위로 둔다.

이번 작업 범위는 ACA 배포 준비를 위한 최소 자산 정리다. 외부 AI provider 연동, analytics/reporting 적재, 실제 job consumer는 아직 포함하지 않는다.

## 책임

- Spring Boot outbox/queue job 소비
- `worker_ai` schema에 worker 상태와 metadata 기록
- 이후 sprint에서 place explanation, record/OOTD summary, recommendation helper data 생성
- 실패 metadata를 안전하게 반환해 Spring이 fallback 응답을 만들 수 있게 지원

## Migration 소유권

Alembic은 `worker_ai` schema만 소유한다.

- `worker_ai.ai_job_runs`
- `worker_ai.prompt_runs`
- `worker_ai.feature_extraction_jobs`

Alembic이 `users`, `groups`, `plans`, `votes`, `settlements` 같은 core domain table을 직접 생성하거나 변경하면 안 된다.

## 로컬 실행과 컨테이너

최소 실행 자산은 준비되어 있다.

- `pyproject.toml`
- `/healthz`
- `Dockerfile`

로컬 실행 예:

```powershell
cd services\workers\ai-data-worker
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

컨테이너 빌드 예:

```powershell
cd services\workers\ai-data-worker
docker build -t onmu-ai-data-worker:local .
docker run --rm -p 8000:8000 onmu-ai-data-worker:local
```

ACA 기준으로는 worker가 외부 공개 endpoint가 아니라도 `/healthz` probe를 내부적으로 사용한다.

## 남은 TODO

1. queue/outbox consumer adapter 추가
2. `worker_ai` job status persistence 추가
3. SQLAlchemy/Alembic runtime wiring 보강
4. idempotent job handling test 추가

secret 값은 이 디렉터리에 두지 않는다.
