# FastAPI AI/Data Worker Scaffold

`services/workers/ai-data-worker` is the private ONMU AI/Data worker. Flutter must not call this service directly. Spring Main API owns public `/api/v1` contracts and dispatches outbox/queue tasks to this worker.

## Responsibilities

- Consume Spring outbox/queue jobs.
- Own only the `worker_ai` schema when worker-side persistence is introduced.
- Call external AI providers such as Azure ML and Vision AI.
- Return safe status/error metadata so Spring can expose fallback UX.

## OOTD generation MVP

The current OOTD path supports:

- `/tasks/ootd` for `ootd.avatar_generation.requested` events.
- Mock acceptance when Azure ML endpoint env vars are absent.
- Azure ML dry-run call when these env vars are present:
  - `ONMU_AZUREML_ENDPOINT_URL`
  - `ONMU_AZUREML_ENDPOINT_KEY`

Photo mode expects a Vision AI outfit descriptor before calling Azure ML. Until Vision AI is connected, the worker uses a placeholder descriptor only for dry-run plumbing tests.

## Migration ownership

Alembic may own worker-only tables such as:

- `worker_ai.ai_job_runs`
- `worker_ai.prompt_runs`
- `worker_ai.feature_extraction_jobs`

Alembic must not create or modify core domain tables such as `users`, `groups`, `plans`, `votes`, `settlements`, `records`, or `record_media`.

## Local run

```powershell
cd services\workers\ai-data-worker
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## Container run

```powershell
cd services\workers\ai-data-worker
docker build -t onmu-ai-data-worker:local .
docker run --rm -p 8000:8000 onmu-ai-data-worker:local
```

ACA should use `/healthz` for liveness and `/readyz` for readiness.

## Azure ML smoke test

After `staging-azureml-endpoint-url` and `staging-azureml-endpoint-key` exist in Key Vault:

```powershell
cd <repo-root>
.\scripts\azureml\test-ootd-generation-smoke.ps1
```

The smoke script does not print endpoint keys. It writes the returned dry-run image under `.generated/`, which is gitignored.

## Remaining TODO

1. Event Hubs consumer adapter.
2. Worker-side job status persistence.
3. Blob read/write integration.
4. Vision AI descriptor adapter.
5. Spring internal callback for completed/failed jobs.
6. Idempotent job handling tests.

Do not commit secret values or generated Azure ML deployment files.
