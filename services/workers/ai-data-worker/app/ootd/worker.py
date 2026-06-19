"""OOTD worker task handlers."""

from __future__ import annotations

from typing import Any

from app.ootd.azureml_client import AzureMlOotdClient, build_azureml_request
from app.ootd.vision_client import AzureOpenAiVisionClient, build_image_source_from_payload


async def handle_ootd_avatar_generation(
    *,
    event_id: str,
    event_type: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    client = AzureMlOotdClient.from_env(required=False)
    vision_client = AzureOpenAiVisionClient.from_env(required=False)
    if not client.is_configured:
        return {
            "ok": True,
            "eventId": event_id,
            "eventType": event_type,
            "status": "accepted_mock",
            "azureMlConfigured": False,
            "visionConfigured": vision_client.is_configured,
            "message": "Azure ML endpoint env vars are not configured; task accepted in mock mode.",
        }

    try:
        payload = await _with_vision_descriptor(
            event_id=event_id,
            payload=payload,
            vision_client=vision_client,
        )
        azureml_request = build_azureml_request(event_id, payload)
        result = await client.generate(azureml_request)
    except Exception as exc:
        return {
            "ok": False,
            "eventId": event_id,
            "eventType": event_type,
            "status": "failed",
            "azureMlConfigured": True,
            "visionConfigured": vision_client.is_configured,
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
            "visionConfigured": vision_client.is_configured,
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
        "visionConfigured": vision_client.is_configured,
        "azureMlStatus": result.status,
        "mode": result.mode,
        "dryRun": result.dry_run,
        "mimeType": result.mime_type,
        "imageBase64Length": len(result.image_base64),
        "durationMs": result.duration_ms,
    }


async def _with_vision_descriptor(
    *,
    event_id: str,
    payload: dict[str, Any],
    vision_client: AzureOpenAiVisionClient,
) -> dict[str, Any]:
    input_type = str(payload.get("inputType") or payload.get("mode") or "").upper()
    if input_type != "PHOTO_REFERENCE":
        return payload
    if payload.get("outfitDescriptor"):
        return payload
    if not vision_client.is_configured:
        return payload

    image_source = build_image_source_from_payload(payload)
    if not image_source:
        return payload

    descriptor = await vision_client.analyze_outfit(
        request_id=str(payload.get("jobId") or event_id),
        image_source=image_source,
    )
    enriched_payload = dict(payload)
    enriched_payload["outfitDescriptor"] = descriptor.descriptor
    enriched_payload["visionMetadata"] = {
        "provider": "azure-openai",
        "deployment": descriptor.model,
        "apiVersion": descriptor.api_version,
        "rawTextLength": len(descriptor.raw_text),
    }
    return enriched_payload
