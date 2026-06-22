"""OOTD worker task handlers."""

from __future__ import annotations

import logging
import os
from typing import Any

from app.ootd.azureml_client import AzureMlOotdClient, build_azureml_request
from app.ootd.character_renderer import render_character_reference
from app.ootd.gpt_image_client import GptImageOotdClient
from app.ootd.vision_client import AzureOpenAiVisionClient, build_image_source_from_payload

logger = logging.getLogger(__name__)

PROVIDER_FLUX_AZUREML = "FLUX_AZUREML"
PROVIDER_GPT_IMAGE_AZURE_OPENAI = "GPT_IMAGE_AZURE_OPENAI"
PROVIDER_MOCK = "MOCK"


async def handle_ootd_avatar_generation(
    *,
    event_id: str,
    event_type: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    azureml_client = AzureMlOotdClient.from_env(required=False)
    gpt_image_client = GptImageOotdClient.from_env(required=False)
    vision_client = AzureOpenAiVisionClient.from_env(required=False)
    provider = resolve_image_generation_provider(
        azureml_configured=azureml_client.is_configured,
        gpt_image_configured=gpt_image_client.is_configured,
    )
    logger.info(
        "ootd worker start event_id=%s event_type=%s job_id=%s input_type=%s provider=%s azureml_configured=%s gpt_image_configured=%s vision_configured=%s",
        event_id,
        event_type,
        payload.get("jobId"),
        payload.get("inputType"),
        provider,
        azureml_client.is_configured,
        gpt_image_client.is_configured,
        vision_client.is_configured,
    )
    if provider == PROVIDER_MOCK:
        reference = render_character_reference(_character_profile_with_overrides(payload))
        logger.info(
            "ootd worker mock completed event_id=%s job_id=%s image_base64_length=%s",
            event_id,
            payload.get("jobId"),
            len(reference.image_base64),
        )
        return {
            "ok": True,
            "eventId": event_id,
            "eventType": event_type,
            "status": "completed",
            "azureMlConfigured": False,
            "gptImageConfigured": False,
            "visionConfigured": vision_client.is_configured,
            "dryRun": True,
            "mimeType": reference.mime_type,
            "imageBase64": reference.image_base64,
            "imageBase64Length": len(reference.image_base64),
            "characterReference": reference.metadata,
            "message": "Azure ML endpoint env vars are not configured; completed with character reference mock image.",
        }
    if provider == PROVIDER_GPT_IMAGE_AZURE_OPENAI and not gpt_image_client.is_configured:
        return _missing_provider_config(
            event_id=event_id,
            event_type=event_type,
            provider=provider,
            message="GPT Image provider was selected but GPT Image env vars are not configured.",
            vision_configured=vision_client.is_configured,
        )
    if provider == PROVIDER_FLUX_AZUREML and not azureml_client.is_configured:
        return _missing_provider_config(
            event_id=event_id,
            event_type=event_type,
            provider=provider,
            message="FLUX Azure ML provider was selected but Azure ML env vars are not configured.",
            vision_configured=vision_client.is_configured,
        )

    try:
        payload = _with_character_reference(payload)
        logger.info(
            "ootd worker character reference prepared event_id=%s job_id=%s",
            event_id,
            payload.get("jobId"),
        )
        payload = await _with_vision_descriptor(
            event_id=event_id,
            payload=payload,
            vision_client=vision_client,
        )
        azureml_request = build_azureml_request(event_id, payload)
        logger.info(
            "ootd worker generation request starting event_id=%s job_id=%s provider=%s has_descriptor=%s",
            event_id,
            payload.get("jobId"),
            provider,
            bool(payload.get("outfitDescriptor")),
        )
        if provider == PROVIDER_GPT_IMAGE_AZURE_OPENAI:
            result = await gpt_image_client.generate(azureml_request)
        else:
            result = await azureml_client.generate(azureml_request)
    except Exception as exc:
        logger.exception(
            "ootd worker failed event_id=%s job_id=%s error=%s",
            event_id,
            payload.get("jobId"),
            exc,
        )
        return {
            "ok": False,
            "eventId": event_id,
            "eventType": event_type,
            "status": "failed",
            "provider": provider,
            "azureMlConfigured": azureml_client.is_configured,
            "gptImageConfigured": gpt_image_client.is_configured,
            "visionConfigured": vision_client.is_configured,
            "errorCode": "OOTD_IMAGE_GENERATION_CALL_FAILED",
            "message": str(exc)[:500],
            "retryable": True,
        }

    if result.status != "succeeded":
        logger.warning(
            "ootd worker azureml returned failed status event_id=%s job_id=%s status=%s error_code=%s message=%s",
            event_id,
            payload.get("jobId"),
            result.status,
            result.error_code,
            result.message,
        )
        return {
            "ok": False,
            "eventId": event_id,
            "eventType": event_type,
            "status": "failed",
            "provider": provider,
            "azureMlConfigured": azureml_client.is_configured,
            "gptImageConfigured": gpt_image_client.is_configured,
            "visionConfigured": vision_client.is_configured,
            "generationStatus": result.status,
            "errorCode": result.error_code or "AZUREML_OOTD_GENERATION_FAILED",
            "message": result.message or "Image generation provider returned a failed status.",
            "retryable": True,
        }

    logger.info(
        "ootd worker completed event_id=%s job_id=%s provider=%s mode=%s dry_run=%s duration_ms=%s",
        event_id,
        payload.get("jobId"),
        provider,
        result.mode,
        result.dry_run,
        result.duration_ms,
    )
    return {
        "ok": True,
        "eventId": event_id,
        "eventType": event_type,
        "status": "completed",
        "provider": provider,
        "azureMlConfigured": azureml_client.is_configured,
        "gptImageConfigured": gpt_image_client.is_configured,
        "visionConfigured": vision_client.is_configured,
        "generationStatus": result.status,
        "mode": result.mode,
        "dryRun": result.dry_run,
        "mimeType": result.mime_type,
        "imageBase64": result.image_base64,
        "imageBase64Length": len(result.image_base64),
        "durationMs": result.duration_ms,
        "characterReference": payload.get("characterReferenceMetadata"),
    }


def resolve_image_generation_provider(*, azureml_configured: bool, gpt_image_configured: bool) -> str:
    configured_provider = os.environ.get("ONMU_IMAGE_GENERATION_PROVIDER", "").strip().upper()
    if configured_provider in {PROVIDER_FLUX_AZUREML, PROVIDER_GPT_IMAGE_AZURE_OPENAI}:
        return configured_provider
    if configured_provider in {"AZUREML", "AZURE_ML", "FLUX"}:
        return PROVIDER_FLUX_AZUREML
    if configured_provider in {"GPT_IMAGE", "GPT_IMAGE_2", "AZURE_OPENAI_IMAGE"}:
        return PROVIDER_GPT_IMAGE_AZURE_OPENAI
    if gpt_image_configured:
        return PROVIDER_GPT_IMAGE_AZURE_OPENAI
    if azureml_configured:
        return PROVIDER_FLUX_AZUREML
    return PROVIDER_MOCK


def _missing_provider_config(
    *,
    event_id: str,
    event_type: str,
    provider: str,
    message: str,
    vision_configured: bool,
) -> dict[str, Any]:
    logger.error("ootd worker provider config missing event_id=%s provider=%s message=%s", event_id, provider, message)
    return {
        "ok": False,
        "eventId": event_id,
        "eventType": event_type,
        "status": "failed",
        "provider": provider,
        "azureMlConfigured": False,
        "gptImageConfigured": False,
        "visionConfigured": vision_configured,
        "errorCode": "OOTD_IMAGE_PROVIDER_NOT_CONFIGURED",
        "message": message,
        "retryable": False,
    }


def _with_character_reference(payload: dict[str, Any]) -> dict[str, Any]:
    if payload.get("characterImageBase64"):
        return payload

    reference = render_character_reference(_character_profile_with_overrides(payload))
    enriched_payload = dict(payload)
    enriched_payload["characterImageBase64"] = reference.image_base64
    enriched_payload["characterImageMimeType"] = reference.mime_type
    enriched_payload["characterReferenceMetadata"] = reference.metadata
    return enriched_payload


def _character_profile_with_overrides(payload: dict[str, Any]) -> dict[str, Any]:
    profile = (
        dict(payload.get("characterProfile"))
        if isinstance(payload.get("characterProfile"), dict)
        else {}
    )
    overrides = payload.get("characterOverrides")
    if isinstance(overrides, dict):
        for key in ("hairStyle", "hairColor", "eyeStyle", "eyeColor"):
            value = overrides.get(key)
            if isinstance(value, str) and value:
                profile[key] = value
    return profile


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
        logger.info("ootd vision skipped because client is not configured event_id=%s", event_id)
        return payload

    image_source = build_image_source_from_payload(payload)
    if not image_source:
        logger.info("ootd vision skipped because image source is unavailable event_id=%s", event_id)
        return payload

    logger.info("ootd vision analysis starting event_id=%s request_id=%s", event_id, payload.get("jobId"))
    descriptor = await vision_client.analyze_outfit(
        request_id=str(payload.get("jobId") or event_id),
        image_source=image_source,
    )
    logger.info(
        "ootd vision analysis completed event_id=%s request_id=%s descriptor_keys=%s",
        event_id,
        payload.get("jobId"),
        sorted(descriptor.descriptor.keys()),
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
