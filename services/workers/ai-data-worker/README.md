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
- Azure OpenAI Vision outfit analysis for photo mode when these env vars are present:
  - `ONMU_VISION_ENDPOINT_URL`
  - `ONMU_VISION_DEPLOYMENT_NAME`
  - `ONMU_VISION_API_KEY`
  - `ONMU_VISION_API_VERSION`

Photo mode first tries to turn the outfit photo into a detailed fashion
descriptor with Azure OpenAI Vision. The worker accepts either
`outfitPhotoImageBase64` or `outfitPhotoMedia.publicUrl` as the image source.
If Vision configuration or an accessible image source is missing, the worker
falls back to a placeholder descriptor only for dry-run plumbing tests.

## Place recommendation explanation

Spring Main API owns the public place-search and place-candidate contracts. The
worker only consumes private outbox tasks.

- `/tasks/place-reason` accepts `place_candidate.created` and
  `ai.summary.requested` events.
- The current implementation acknowledges the task and returns safe metadata for
  the rule-based explanation that Spring already stored.
- Later Azure OpenAI prompt execution should persist prompt/run metadata under
  `worker_ai` and return a Spring-readable completion status through the internal
  callback path.

Spring routes this path with:

```text
ONMU_PLACE_REASON_WORKER_URL=http://localhost:8090/tasks/place-reason
```

Do not include provider raw response bodies, raw queries, OAuth data, tokens, or
user PII in worker logs or task results. Flutter must never call this endpoint
directly.

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

## Azure OpenAI Vision smoke test

After these Key Vault secrets exist:

```text
staging-vision-endpoint-url
staging-vision-deployment-name
staging-vision-api-key
staging-vision-api-version
```

run:

```powershell
cd <repo-root>
.\scripts\azureml\test-ootd-vision-smoke.ps1 -ImagePath C:\path\to\outfit.png
```

The smoke script verifies that the configured Vision deployment returns a
parseable outfit descriptor JSON. It does not print API keys. It writes the
descriptor under `.generated/`, which is gitignored.

## Remaining TODO

1. Event Hubs consumer adapter.
2. Worker-side job status persistence.
3. Blob read/write integration for private media URLs.
4. Spring internal callback for completed/failed jobs.
5. Idempotent job handling tests.
6. Worker-side persistence for Vision prompt/response metadata.

Do not commit secret values or generated Azure ML deployment files.
