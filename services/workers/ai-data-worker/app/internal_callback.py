from __future__ import annotations

import os
from typing import Any

import httpx


async def post_place_reason_callback(
    *,
    group_id: str | None,
    plan_id: str | None,
    candidate_id: str,
    status: str,
    summary: str | None,
    reasons: list[str],
    recommendation: dict[str, Any],
    job_run_id: str | None,
    prompt_run_id: str | None,
    error_code: str | None,
) -> dict[str, Any]:
    base_url = os.environ.get("ONMU_INTERNAL_CALLBACK_BASE_URL", "").strip().rstrip("/")
    internal_secret = os.environ.get("ONMU_INTERNAL_SECRET", "").strip()
    if not base_url or not internal_secret:
        return {"ok": True, "status": "skipped"}

    body = {
        "groupId": group_id,
        "planId": plan_id,
        "candidateId": candidate_id,
        "status": status,
        "summary": summary,
        "reasons": reasons,
        "recommendation": recommendation,
        "jobRunId": job_run_id,
        "promptRunId": prompt_run_id,
        "errorCode": error_code,
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"{base_url}/api/v1/internal/callbacks/place-reason",
            headers={"X-Internal-Secret": internal_secret},
            json=body,
        )
    if response.status_code >= 400:
        raise RuntimeError(f"Spring place reason callback returned HTTP {response.status_code}")
    return {"ok": True, "status": "posted", "statusCode": response.status_code}
