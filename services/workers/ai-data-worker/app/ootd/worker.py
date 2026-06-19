"""OOTD worker task handlers."""

from __future__ import annotations

from typing import Any

from app.ootd.azureml_client import AzureMlOotdClient, build_azureml_request


async def handle_ootd_avatar_generation(
    *,
    event_id: str,
    event_type: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    client = AzureMlOotdClient.from_env(required=False)
    if not client.is_configured:
        return {
            "ok": True,
            "eventId": event_id,
            "eventType": event_type,
            "status": "accepted_mock",
            "azureMlConfigured": False,
            "message": "Azure ML endpoint env vars are not configured; task accepted in mock mode.",
        }

    try:
        azureml_request = build_azureml_request(event_id, payload)
        result = await client.generate(azureml_request)
    except Exception as exc:
        return {
            "ok": False,
            "eventId": event_id,
            "eventType": event_type,
            "status": "failed",
            "azureMlConfigured": True,
            "errorCode": "AZUREML_OOTD_CALL_FAILED",
            "message": str(exc)[:500],
            "retryable": True,
        }

    if result.status != "succeeded":
        return {
            "ok": False,
            "eventId": event_id,
            "eventType": event_type,
            "status": "failed",
            "azureMlConfigured": True,
            "azureMlStatus": result.status,
            "errorCode": result.error_code or "AZUREML_OOTD_GENERATION_FAILED",
            "message": result.message or "Azure ML endpoint returned a failed status.",
            "retryable": True,
        }

    return {
        "ok": True,
        "eventId": event_id,
        "eventType": event_type,
        "status": "completed",
        "azureMlConfigured": True,
        "azureMlStatus": result.status,
        "mode": result.mode,
        "dryRun": result.dry_run,
        "mimeType": result.mime_type,
        "imageBase64Length": len(result.image_base64),
        "durationMs": result.duration_ms,
    }
