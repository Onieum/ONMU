# FastAPI AI/Data Worker Scaffold

`services/workers/ai-data-worker` is the confirmed FastAPI worker location. It is not a public API for Flutter. Spring Boot Main API calls it through queue/outbox and owns user-facing `/api/v1` responses.

This PR adds a scaffold only. It does not connect external AI providers or future analytics/reporting systems.

## Responsibilities

- Consume AI/Data outbox jobs from Spring Boot.
- Write worker status and metadata to `worker_ai` schema.
- Generate place explanation, record/OOTD summary, and recommendation helper data in later sprints.
- Return failure metadata safely so Spring Boot can provide fallback responses.

## Migration Ownership

Alembic owns only the `worker_ai` schema:

- `worker_ai.ai_job_runs`
- `worker_ai.prompt_runs`
- `worker_ai.feature_extraction_jobs`

Alembic must not create or alter core domain tables such as `users`, `groups`, `plans`, `votes`, or `settlements`.

## Local TODO

1. Add `pyproject.toml` with FastAPI, Pydantic, SQLAlchemy, Alembic, pytest.
2. Add queue/outbox consumer adapter.
3. Add `/healthz` for worker process health.
4. Add job status persistence in `worker_ai`.
5. Add tests for idempotent job handling.

No secret values belong in this directory.
