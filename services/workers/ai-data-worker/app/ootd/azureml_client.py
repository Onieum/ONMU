"""Azure ML client for ONMU OOTD avatar generation."""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

import httpx


DEFAULT_CHARACTER_IMAGE_BASE64 = (
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
)


@dataclass(frozen=True)
class AzureMlOotdConfig:
    endpoint_url: str
    endpoint_key: str
    timeout_seconds: float = 180.0


@dataclass(frozen=True)
class AzureMlOotdResult:
    status: str
    mode: str
    request_id: str
    image_base64: str
    mime_type: str
    dry_run: bool
    duration_ms: int | None
    error_code: str | None
    message: str | None


class AzureMlOotdClient:
    def __init__(self, config: AzureMlOotdConfig | None):
        self._config = config

    @classmethod
    def from_env(cls, *, required: bool) -> "AzureMlOotdClient":
        endpoint_url = os.environ.get("ONMU_AZUREML_ENDPOINT_URL", "").strip()
        endpoint_key = os.environ.get("ONMU_AZUREML_ENDPOINT_KEY", "").strip()
        if required and (not endpoint_url or not endpoint_key):
            raise RuntimeError("ONMU_AZUREML_ENDPOINT_URL and ONMU_AZUREML_ENDPOINT_KEY are required")
        if not endpoint_url or not endpoint_key:
            return cls(None)
        return cls(AzureMlOotdConfig(endpoint_url=endpoint_url, endpoint_key=endpoint_key))

    @property
    def is_configured(self) -> bool:
        return self._config is not None

    async def generate(self, request: dict[str, Any]) -> AzureMlOotdResult:
        if self._config is None:
            raise RuntimeError("Azure ML OOTD client is not configured")

        headers = {
            "Authorization": f"Bearer {self._config.endpoint_key}",
            "Content-Type": "application/json",
        }
        async with httpx.AsyncClient(timeout=self._config.timeout_seconds) as client:
            response = await client.post(self._config.endpoint_url, json=request, headers=headers)

        if response.status_code >= 400:
            raise RuntimeError(_redact_secret(f"Azure ML endpoint returned HTTP {response.status_code}: {response.text}"))

        body = response.json()
        return AzureMlOotdResult(
            status=str(body.get("status") or "unknown"),
            mode=str(body.get("mode") or request.get("mode") or ""),
            request_id=str(body.get("requestId") or request.get("requestId") or ""),
            image_base64=str(body.get("imageBase64") or ""),
            mime_type=str(body.get("mimeType") or "image/png"),
            dry_run=bool(body.get("dryRun")),
            duration_ms=_optional_int(body.get("durationMs")),
            error_code=body.get("errorCode"),
            message=body.get("message"),
        )


def build_azureml_request(event_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    input_type = str(payload.get("inputType") or payload.get("mode") or "").upper()
    character_image = str(payload.get("characterImageBase64") or DEFAULT_CHARACTER_IMAGE_BASE64)
    request_id = str(payload.get("jobId") or event_id)

    if input_type == "TEXT_PROMPT":
        outfit_description = str(payload.get("outfitDescription") or "").strip()
        if not outfit_description:
            raise ValueError("outfitDescription is required for TEXT_PROMPT")
        return {
            "requestId": request_id,
            "mode": "TEXT_PROMPT",
            "characterImageBase64": character_image,
            "outfitDescription": outfit_description,
        }

    if input_type == "PHOTO_REFERENCE":
        descriptor = payload.get("outfitDescriptor")
        if not descriptor:
            descriptor = _fallback_descriptor(payload)
        return {
            "requestId": request_id,
            "mode": "PHOTO_REFERENCE",
            "characterImageBase64": character_image,
            "outfitDescriptor": descriptor,
        }

    raise ValueError("inputType must be TEXT_PROMPT or PHOTO_REFERENCE")


def _fallback_descriptor(payload: dict[str, Any]) -> dict[str, Any]:
    media = payload.get("outfitPhotoMedia") if isinstance(payload.get("outfitPhotoMedia"), dict) else {}
    return {
        "style_name": "Vision descriptor pending",
        "overall_aesthetic": "Use the uploaded outfit photo as the source once Vision AI is connected.",
        "top": "unknown visible top from outfit photo",
        "bottom": "unknown visible bottom from outfit photo",
        "shoes": "unknown visible shoes from outfit photo",
        "accessories": [],
        "styling_notes": f"Vision AI has not produced a descriptor yet. mediaId={media.get('id', '-')}",
        "uncertainty": ["Vision AI descriptor is pending; this placeholder is for dry-run plumbing only."],
    }


def _optional_int(value: Any) -> int | None:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _redact_secret(value: str) -> str:
    endpoint_key = os.environ.get("ONMU_AZUREML_ENDPOINT_KEY", "")
    if endpoint_key:
        value = value.replace(endpoint_key, "<redacted>")
    return value
