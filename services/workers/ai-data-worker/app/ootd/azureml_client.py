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


DEFAULT_GUIDANCE_SCALE = 2.5
DEFAULT_MAX_SEQUENCE_LENGTH = 128
DEFAULT_NUM_INFERENCE_STEPS = 8
MAX_OUTFIT_BRIEF_CHARS = 360


def build_azureml_request(event_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    input_type = str(payload.get("inputType") or payload.get("mode") or "").upper()
    character_image = str(payload.get("characterImageBase64") or DEFAULT_CHARACTER_IMAGE_BASE64)
    request_id = str(payload.get("jobId") or event_id)
    common = {
        "requestId": request_id,
        "characterImageBase64": character_image,
        "guidanceScale": DEFAULT_GUIDANCE_SCALE,
        "maxSequenceLength": DEFAULT_MAX_SEQUENCE_LENGTH,
        "numInferenceSteps": DEFAULT_NUM_INFERENCE_STEPS,
        "useDimensions": False,
        "useNegativePrompt": False,
    }

    if input_type == "TEXT_PROMPT":
        outfit_description = str(payload.get("outfitDescription") or "").strip()
        if not outfit_description:
            raise ValueError("outfitDescription is required for TEXT_PROMPT")
        return {
            **common,
            "mode": "TEXT_PROMPT",
            "outfitDescription": outfit_description,
            "promptOverride": _build_prompt_override(outfit_description),
        }

    if input_type == "PHOTO_REFERENCE":
        descriptor = payload.get("outfitDescriptor")
        if not descriptor:
            descriptor = _fallback_descriptor(payload)
        return {
            **common,
            "mode": "PHOTO_REFERENCE",
            "outfitDescriptor": descriptor,
            "promptOverride": _build_prompt_override(_descriptor_to_brief(descriptor)),
        }

    raise ValueError("inputType must be TEXT_PROMPT or PHOTO_REFERENCE")


def _build_prompt_override(outfit_brief: str) -> str:
    brief = _clip_text(" ".join(outfit_brief.split()), MAX_OUTFIT_BRIEF_CHARS) or "cute daily outfit"
    return (
        "Change only the outfit of this exact ONMU pixel avatar to: "
        f"{brief}. "
        "Keep the same face, hair, skin tone, body, pose, and pixel-art style."
    )


def _descriptor_to_brief(descriptor: Any) -> str:
    if isinstance(descriptor, str):
        return _clip_text(descriptor, MAX_OUTFIT_BRIEF_CHARS)
    if not isinstance(descriptor, dict):
        return "cute daily outfit"

    parts: list[str] = []
    for key in (
        "top",
        "bottom",
        "dress",
        "outerwear",
        "shoes",
        "bag",
        "headwear",
        "eyewear",
        "headphones",
    ):
        text = _value(descriptor.get(key))
        if text:
            parts.append(f"{key}: {text}")

    for key in ("accessories", "jewelry", "colors", "patterns", "materials", "point", "styling_notes", "overall_aesthetic"):
        text = _value(descriptor.get(key))
        if text:
            parts.append(f"{key}: {text}")

    return _clip_text("; ".join(parts), MAX_OUTFIT_BRIEF_CHARS) or "cute daily outfit"


def _value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return " ".join(value.strip().split())
    if isinstance(value, list):
        return ", ".join(_value(item) for item in value[:4] if _value(item))
    if isinstance(value, dict):
        return ", ".join(_value(item) for item in value.values() if _value(item))
    return str(value)


def _clip_text(value: str, max_chars: int) -> str:
    value = " ".join(value.strip().split())
    if len(value) <= max_chars:
        return value
    return value[:max_chars].rsplit(" ", 1)[0].rstrip(" ,.;:")


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
