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
- If Azure OpenAI place-reason env vars are configured, the worker runs a
  JSON-only prompt and returns user-facing `summary`/`reasons`.
- If Azure OpenAI is not configured, the worker completes with the safe
  rule-based explanation Spring already stored.
- If `ONMU_WORKER_AI_DATABASE_URL` or `DATABASE_URL` is configured, the worker
  stores job/prompt metadata in `worker_ai.ai_job_runs` and
  `worker_ai.prompt_runs`. Missing DB config does not block task completion.
- If `ONMU_INTERNAL_CALLBACK_BASE_URL` and `ONMU_INTERNAL_SECRET` are
  configured, the worker posts the result to Spring
  `/api/v1/internal/callbacks/place-reason`; otherwise callback is skipped.

Spring routes this path with:

```text
ONMU_PLACE_REASON_WORKER_URL=http://localhost:8090/tasks/place-reason
```

Azure OpenAI place-reason runtime env:

```text
ONMU_PLACE_REASON_OPENAI_ENDPOINT_URL
ONMU_PLACE_REASON_OPENAI_DEPLOYMENT_NAME
ONMU_PLACE_REASON_OPENAI_API_KEY
ONMU_PLACE_REASON_OPENAI_API_VERSION
```

Spring callback/runtime env:

```text
ONMU_INTERNAL_CALLBACK_BASE_URL
ONMU_INTERNAL_SECRET
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
`/readyz` reports configuration booleans for Azure ML, Vision, place-reason AI,
and worker_ai persistence. It does not print secret values.

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
2. Blob read/write integration for private media URLs.
3. Idempotent job handling tests across repeated outbox dispatches.
4. Worker-side persistence for Vision prompt/response metadata.

Do not commit secret values or generated Azure ML deployment files.
