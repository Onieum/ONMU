"""Azure OpenAI GPT Image client for ONMU OOTD avatar generation."""

from __future__ import annotations

import base64
import os
from dataclasses import dataclass
from typing import Any

import httpx

from app.ootd.azureml_client import (
    DEFAULT_CHARACTER_IMAGE_BASE64,
    _descriptor_to_brief,
    _optional_int,
)


DEFAULT_IMAGE_SIZE = "1024x1024"
DEFAULT_IMAGE_QUALITY = "low"
MAX_OUTFIT_BRIEF_CHARS = 700


@dataclass(frozen=True)
class GptImageConfig:
    endpoint_url: str
    api_key: str
    api_version: str
    deployment_name: str
    timeout_seconds: float = 180.0


@dataclass(frozen=True)
class GptImageResult:
    status: str
    mode: str
    request_id: str
    image_base64: str
    mime_type: str
    dry_run: bool
    duration_ms: int | None
    error_code: str | None
    message: str | None


class GptImageOotdClient:
    def __init__(self, config: GptImageConfig | None, *, transport: httpx.AsyncBaseTransport | None = None):
        self._config = config
        self._transport = transport

    @classmethod
    def from_env(cls, *, required: bool) -> "GptImageOotdClient":
        endpoint_url = os.environ.get("ONMU_GPT_IMAGE_ENDPOINT_URL", "").strip()
        api_key = os.environ.get("ONMU_GPT_IMAGE_API_KEY", "").strip()
        api_version = os.environ.get("ONMU_GPT_IMAGE_API_VERSION", "").strip()
        deployment_name = os.environ.get("ONMU_GPT_IMAGE_DEPLOYMENT_NAME", "").strip()
        missing = [
            name
            for name, value in [
                ("ONMU_GPT_IMAGE_ENDPOINT_URL", endpoint_url),
                ("ONMU_GPT_IMAGE_API_KEY", api_key),
                ("ONMU_GPT_IMAGE_API_VERSION", api_version),
                ("ONMU_GPT_IMAGE_DEPLOYMENT_NAME", deployment_name),
            ]
            if not value
        ]
        if required and missing:
            raise RuntimeError(f"Missing required GPT Image env vars: {', '.join(missing)}")
        if missing:
            return cls(None)
        return cls(
            GptImageConfig(
                endpoint_url=endpoint_url.rstrip("/"),
                api_key=api_key,
                api_version=api_version,
                deployment_name=deployment_name,
            )
        )

    @property
    def is_configured(self) -> bool:
        return self._config is not None

    async def generate(self, request: dict[str, Any]) -> GptImageResult:
        if self._config is None:
            raise RuntimeError("GPT Image OOTD client is not configured")

        request_id = str(request.get("requestId") or "")
        mode = str(request.get("mode") or "").upper()
        prompt = build_gpt_image_avatar_prompt(request)
        image_bytes = _decode_base64_image(
            str(request.get("characterImageBase64") or DEFAULT_CHARACTER_IMAGE_BASE64)
        )
        url = (
            f"{self._config.endpoint_url}/openai/deployments/"
            f"{self._config.deployment_name}/images/edits"
        )
        params = {"api-version": self._config.api_version}
        data = {
            "prompt": prompt,
            "model": self._config.deployment_name,
            "size": DEFAULT_IMAGE_SIZE,
            "quality": DEFAULT_IMAGE_QUALITY,
            "output_format": "png",
            "n": "1",
        }
        files = {
            "image[]": ("onmu-character-reference.png", image_bytes, "image/png"),
        }

        async with httpx.AsyncClient(
            timeout=self._config.timeout_seconds,
            transport=self._transport,
        ) as client:
            response = await client.post(
                url,
                params=params,
                headers={"Authorization": f"Bearer {self._config.api_key}"},
                data=data,
                files=files,
            )
            if response.status_code in {401, 403, 404}:
                response = await client.post(
                    url,
                    params=params,
                    headers={"api-key": self._config.api_key},
                    data=data,
                    files=files,
                )

        if response.status_code >= 400:
            raise RuntimeError(_redact_secret(f"GPT Image endpoint returned HTTP {response.status_code}: {response.text}"))

        image_base64 = _extract_image_base64(response.json())
        return GptImageResult(
            status="succeeded",
            mode=mode,
            request_id=request_id,
            image_base64=image_base64,
            mime_type="image/png",
            dry_run=False,
            duration_ms=_optional_int(response.headers.get("x-ms-processing-ms")),
            error_code=None,
            message=None,
        )


def build_gpt_image_avatar_prompt(request: dict[str, Any]) -> str:
    outfit_brief = _outfit_brief_from_request(request)
    return (
        "Edit the provided ONMU pixel avatar. "
        "Change only the outfit of this exact ONMU pixel avatar to: "
        f"{outfit_brief}. "
        "Keep the same face, eyes, mouth, hairstyle, hair color, skin tone, body proportions, "
        "front-facing pose, sprite scale, and clean pixel-art style. "
        "Do not redesign the character. Do not change the character identity. "
        "Do not change the background into a scene. "
        "Make the clothing cute, clear, readable, and wearable as pixel avatar equipment. "
        "Preserve visible outfit details such as garment type, colors, shoes, bag, hat, glasses, "
        "jewelry, socks, graphics, ribbons, buttons, pleats, trims, and accessories when present. "
        "Return one centered full-body ONMU-style pixel art avatar."
    )


def build_gpt_image_diary_card_prompt(metadata: dict[str, Any]) -> str:
    todays_look = _clean_text(metadata.get("todaysLook")) or "오늘의 코디를 귀엽게 기록했어요."
    hair_note = _clean_text(metadata.get("hairNote")) or "오늘 스타일에 맞춘 헤어 포인트"
    weather = _clean_text(metadata.get("weatherText")) or "맑음"
    mood = _clean_text(metadata.get("moodText")) or "행복"
    point = _clean_text(metadata.get("pointText")) or "오늘 코디의 포인트"
    tags = _value_to_text(metadata.get("tags")) or "#ootd #오늘의코디"
    outfit_info = _value_to_text(metadata.get("outfitInfo")) or "상의, 하의, 신발, 소품"
    return (
        "Create a cute Korean mobile diary scrapbook card image for an OOTD record. "
        "Use a warm ivory paper background with a subtle square grid notebook pattern, "
        "soft beige and pink tones, tape stickers, paper clips, hearts, sparkles, arrows, and small doodles. "
        "Place the provided ONMU pixel avatar in the center with a soft cutout sticker border. "
        "Keep the avatar face, hair, skin tone, eyes, and body identity unchanged. "
        "Do not include phone status bars, app navigation buttons, edit buttons, or delete buttons. "
        "Add legible Korean diary handwriting inside separate memo cards. "
        f"Today's Look: {todays_look}. "
        f"Hair: {hair_note}. "
        f"Weather: {weather}. "
        f"Mood: {mood}. "
        f"Outfit Info: {outfit_info}. "
        f"Point: {point}. "
        f"Today's Tag: {tags}. "
        "Keep all text inside cards, avoid cropped stickers, and do not cover the character."
    )


def _outfit_brief_from_request(request: dict[str, Any]) -> str:
    description = _clean_text(request.get("outfitDescription"))
    if description:
        return _clip_text(description, MAX_OUTFIT_BRIEF_CHARS)
    descriptor = request.get("outfitDescriptor")
    if descriptor:
        return _clip_text(_descriptor_to_brief(descriptor), MAX_OUTFIT_BRIEF_CHARS)
    return "a cute daily outfit that matches the user's OOTD reference"


def _extract_image_base64(body: dict[str, Any]) -> str:
    data = body.get("data")
    if not isinstance(data, list) or not data:
        raise RuntimeError("GPT Image response did not include data")
    first = data[0]
    if not isinstance(first, dict):
        raise RuntimeError("GPT Image response data item must be an object")
    image_base64 = first.get("b64_json")
    if not isinstance(image_base64, str) or not image_base64.strip():
        raise RuntimeError("GPT Image response did not include b64_json")
    return image_base64.strip()


def _decode_base64_image(value: str) -> bytes:
    if "," in value and value.strip().startswith("data:"):
        value = value.split(",", 1)[1]
    try:
        return base64.b64decode(value, validate=True)
    except Exception as exc:
        raise ValueError("characterImageBase64 must be a valid base64 image") from exc


def _clean_text(value: Any) -> str:
    if value is None:
        return ""
    if not isinstance(value, str):
        return ""
    return " ".join(value.strip().split())


def _value_to_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return _clean_text(value)
    if isinstance(value, list):
        return ", ".join(_value_to_text(item) for item in value if _value_to_text(item))
    if isinstance(value, dict):
        return ", ".join(f"{key}: {_value_to_text(item)}" for key, item in value.items() if _value_to_text(item))
    return str(value)


def _clip_text(value: str, max_chars: int) -> str:
    value = " ".join(value.strip().split())
    if len(value) <= max_chars:
        return value
    return value[:max_chars].rsplit(" ", 1)[0].rstrip(" ,.;:")


def _redact_secret(value: str) -> str:
    for env_name in [
        "ONMU_GPT_IMAGE_API_KEY",
        "ONMU_AZUREML_ENDPOINT_KEY",
        "ONMU_VISION_API_KEY",
        "ONMU_HF_TOKEN",
    ]:
        secret = os.environ.get(env_name, "")
        if secret:
            value = value.replace(secret, "<redacted>")
    return value[:800]
