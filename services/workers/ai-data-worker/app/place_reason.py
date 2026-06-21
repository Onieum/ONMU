from __future__ import annotations

import logging
from typing import Any

from app.internal_callback import post_place_reason_callback
from app.place_reason_client import AzureOpenAiPlaceReasonClient
from app.worker_ai_store import WorkerAiStore

logger = logging.getLogger(__name__)

PLACE_REASON_EVENT_TYPES = {"place_candidate.created", "ai.summary.requested"}
PLACE_REASON_PROMPT_KIND = "place_reason"


async def handle_place_reason_task(event_id: str, event_type: str, payload: dict) -> dict[str, Any]:
    if event_type not in PLACE_REASON_EVENT_TYPES:
        return {
            "ok": True,
            "eventId": event_id,
            "eventType": event_type,
            "status": "ignored",
        }

    safe_payload = _safe_place_payload(payload)
    store = WorkerAiStore.from_env()
    client = AzureOpenAiPlaceReasonClient.from_env(required=False)
    job_run_id = store.start_job(
        outbox_event_id=event_id,
        job_type=event_type,
        input_metadata={
            "promptKind": PLACE_REASON_PROMPT_KIND,
            "candidateId": safe_payload.get("candidateId"),
            "groupId": safe_payload.get("groupId"),
            "planId": safe_payload.get("planId"),
            "reasonCount": len(safe_payload.get("reasons", [])),
            "hasCoordinate": bool(safe_payload.get("hasCoordinate")),
            "modelConfigured": client.is_configured,
        },
    )
    prompt_run_id: str | None = None

    try:
        if client.is_configured:
            ai_result = await client.generate_place_reason(
                event_id=event_id,
                candidate=safe_payload,
            )
            prompt_run_id = store.record_prompt(
                ai_job_run_id=job_run_id,
                prompt_kind=PLACE_REASON_PROMPT_KIND,
                model_name=client.model_name,
                status="completed",
                metadata={
                    "candidateId": safe_payload.get("candidateId"),
                    "summaryLength": len(ai_result.get("summary") or ""),
                    "reasonCount": len(ai_result.get("reasons") or []),
                    "hasCoordinate": bool(safe_payload.get("hasCoordinate")),
                },
            )
            result = {
                "status": "completed",
                "reasonSource": "azure_openai",
                "summary": ai_result.get("summary"),
                "reasons": ai_result.get("reasons") or [],
                "modelConfigured": True,
            }
        else:
            result = _fallback_result(safe_payload)
    except Exception as exc:
        logger.warning(
            "place reason worker failed event_id=%s candidate_id=%s error_type=%s",
            event_id,
            safe_payload.get("candidateId"),
            exc.__class__.__name__,
        )
        result = {
            "status": "failed",
            "reasonSource": "azure_openai",
            "summary": None,
            "reasons": [],
            "modelConfigured": client.is_configured,
            "errorCode": "AZURE_OPENAI_PLACE_REASON_FAILED",
        }
        if client.is_configured:
            prompt_run_id = store.record_prompt(
                ai_job_run_id=job_run_id,
                prompt_kind=PLACE_REASON_PROMPT_KIND,
                model_name=client.model_name,
                status="failed",
                metadata={
                    "candidateId": safe_payload.get("candidateId"),
                    "errorCode": result["errorCode"],
                    "errorType": exc.__class__.__name__,
                },
            )

    recommendation = {
        "version": "ai-place-v1",
        "aiStatus": result["status"],
        "reasonSource": result["reasonSource"],
        "reasonCount": len(result.get("reasons") or safe_payload.get("reasons", [])),
        "modelConfigured": result["modelConfigured"],
        "promptKind": PLACE_REASON_PROMPT_KIND,
    }
    store.finish_job(
        ai_job_run_id=job_run_id,
        status=result["status"],
        result_metadata={
            "candidateId": safe_payload.get("candidateId"),
            "promptRunId": prompt_run_id,
            "aiStatus": result["status"],
            "reasonSource": result["reasonSource"],
            "reasonCount": recommendation["reasonCount"],
            "callbackAttempted": True,
        },
    )

    callback = await post_place_reason_callback(
        group_id=_safe_text(safe_payload.get("groupId")),
        plan_id=_safe_text(safe_payload.get("planId")),
        candidate_id=_safe_text(safe_payload.get("candidateId")) or "",
        status=result["status"],
        summary=_safe_text(result.get("summary")),
        reasons=[_safe_text(reason) for reason in result.get("reasons", []) if _safe_text(reason)],
        recommendation=recommendation,
        job_run_id=job_run_id,
        prompt_run_id=prompt_run_id,
        error_code=_safe_text(result.get("errorCode")),
    )
    logger.info(
        "place reason worker completed event_id=%s candidate_id=%s status=%s model_configured=%s callback_status=%s",
        event_id,
        safe_payload.get("candidateId"),
        result["status"],
        client.is_configured,
        callback["status"],
    )
    return {
        "ok": result["status"] != "failed",
        "eventId": event_id,
        "eventType": event_type,
        "status": result["status"],
        "promptKind": PLACE_REASON_PROMPT_KIND,
        "jobRunId": job_run_id,
        "promptRunId": prompt_run_id,
        "callbackStatus": callback["status"],
        "result": recommendation,
    }


def _fallback_result(payload: dict[str, Any]) -> dict[str, Any]:
    reasons = payload.get("reasons")
    if not isinstance(reasons, list) or not reasons:
        reasons = _rule_based_reasons(payload)
    return {
        "status": "completed",
        "reasonSource": "rule_based_worker",
        "summary": payload.get("summary") or "팀원이 비교하기 쉬운 장소 후보예요.",
        "reasons": reasons[:3],
        "modelConfigured": False,
    }


def _rule_based_reasons(payload: dict[str, Any]) -> list[str]:
    reasons: list[str] = []
    if payload.get("distanceLabel"):
        reasons.append(f"{payload['distanceLabel']} 기준으로 이동 부담을 비교할 수 있어요.")
    if payload.get("travelTimeLabel"):
        reasons.append(f"{payload['travelTimeLabel']} 기준으로 일정 동선을 가늠할 수 있어요.")
    if payload.get("hasCoordinate"):
        reasons.append("지도에서 위치를 확인할 수 있어 일정에 추가하기 쉬워요.")
    if not reasons:
        reasons.append("팀원들과 함께 후보로 비교할 수 있어요.")
    return reasons


def _safe_place_payload(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "groupId": _safe_text(payload.get("groupId")),
        "planId": _safe_text(payload.get("planId")),
        "candidateId": _safe_text(payload.get("candidateId")),
        "name": _safe_text(payload.get("name")),
        "category": _safe_text(payload.get("category")),
        "summary": _safe_text(payload.get("summary"), limit=180),
        "reasons": _safe_text_list(payload.get("reasons"), limit=120, max_items=3),
        "distanceLabel": _safe_text(payload.get("distanceLabel")),
        "travelTimeLabel": _safe_text(payload.get("travelTimeLabel")),
        "priceLabel": _safe_text(payload.get("priceLabel")),
        "openingLabel": _safe_text(payload.get("openingLabel")),
        "reasonCount": _safe_int(payload.get("reasonCount")),
        "hasCoordinate": bool(payload.get("hasCoordinate")),
        "sourceType": _safe_text(payload.get("sourceType")),
    }


def _safe_text_list(value: object, *, limit: int, max_items: int) -> list[str]:
    if not isinstance(value, list):
        return []
    result: list[str] = []
    for item in value:
        text = _safe_text(item, limit=limit)
        if text and text not in result:
            result.append(text)
        if len(result) >= max_items:
            break
    return result


def _safe_text(value: object, *, limit: int = 120) -> str | None:
    if not isinstance(value, str):
        return None
    text = " ".join(value.strip().split())
    if not text:
        return None
    return text[:limit]


def _safe_int(value: object) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return max(value, 0)
    if isinstance(value, str) and value.isdigit():
        return int(value)
    return 0
