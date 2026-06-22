"""Azure GPT Image client for ONMU OOTD image generation."""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

import httpx

from app.ootd.azureml_client import _optional_int


DEFAULT_IMAGE_SIZE = "1024x1024"
DEFAULT_IMAGE_QUALITY = "low"
MAX_OUTFIT_BRIEF_CHARS = 900


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
        mode = str(request.get("mode") or request.get("inputType") or "").upper()
        prompt = build_gpt_image_avatar_prompt(request)
        url = (
            f"{self._config.endpoint_url}/openai/deployments/"
            f"{self._config.deployment_name}/images/generations"
        )
        params = {"api-version": self._config.api_version}
        body = {
            "prompt": prompt,
            "size": DEFAULT_IMAGE_SIZE,
            "quality": DEFAULT_IMAGE_QUALITY,
            "output_compression": 100,
            "output_format": "png",
            "n": 1,
        }

        async with httpx.AsyncClient(
            timeout=self._config.timeout_seconds,
            transport=self._transport,
        ) as client:
            response = await client.post(
                url,
                params=params,
                headers={
                    "Authorization": f"Bearer {self._config.api_key}",
                    "Content-Type": "application/json",
                },
                json=body,
            )
            if response.status_code in {401, 403, 404}:
                response = await client.post(
                    url,
                    params=params,
                    headers={
                        "api-key": self._config.api_key,
                        "Content-Type": "application/json",
                    },
                    json=body,
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
    """Build the prompt used by GPT Image for the OOTD character image."""

    mode = str(request.get("mode") or request.get("inputType") or "").upper()
    style_brief = _outfit_brief_from_request(request)
    profile_brief = _profile_reference_brief(request.get("characterProfile"))

    if mode == "PHOTO_REFERENCE":
        return f"""
Create a full-body ONMU OOTD character image.

Source priority:
1. Use the visible OOTD photo analysis as the primary evidence for every visible feature.
2. Preserve visible outfit, headwear, hair shape, hair color, visible skin tone, pose, silhouette, shoes, bags, and accessories from the photo analysis.
3. Use the ONMU profile fallback only for details that are hidden, cropped out, blurry, or not described.
4. If the photo shows a hairstyle or hat that ONMU profile parts do not have, use the photo hairstyle or hat anyway.
5. Do not force the profile character hairstyle, hair color, eye color, skin tone, or outfit over visible photo evidence.

Visible OOTD photo/style analysis:
{style_brief}

Profile fallback for hidden or missing details:
{profile_brief}

Rendering requirements:
- Cute Korean diary-app character.
- Full-body, centered, front-facing or near-front pose.
- Clean pixel-art inspired avatar style with readable sprite proportions.
- The result should look like one coherent OOTD character, not a pasted collage.
- Plain transparent or simple light neutral background.
- No diary page, no UI frame, no labels, no captions, no text.
""".strip()

    return f"""
Create a full-body ONMU OOTD character image from the user's text description.

Use the text description as the outfit and styling source.
Use the ONMU profile fallback for details the text does not specify, such as hair, eyes, mouth, skin tone, body proportions, or overall character mood.
If the text explicitly describes hair, eyes, accessories, or pose, the text wins over the profile fallback.

Outfit and style request:
{style_brief}

Profile fallback for missing text details:
{profile_brief}

Rendering requirements:
- Cute Korean diary-app character.
- Full-body, centered, front-facing or near-front pose.
- Clean pixel-art inspired avatar style with readable sprite proportions.
- Apply the described outfit, shoes, bags, and accessories clearly.
- Plain transparent or simple light neutral background.
- No diary page, no UI frame, no labels, no captions, no text.
""".strip()


def build_gpt_image_diary_card_prompt(metadata: dict[str, Any]) -> str:
    todays_look = _clean_text(metadata.get("todaysLook")) or "A cozy daily outfit record."
    hair_note = _clean_text(metadata.get("hairNote")) or "Hair style matched today's mood."
    weather = _clean_text(metadata.get("weatherText")) or "clear"
    mood = _clean_text(metadata.get("moodText")) or "happy"
    point = _clean_text(metadata.get("pointText")) or "Today's outfit point."
    tags = _value_to_text(metadata.get("tags")) or "#ootd #dailylook"
    outfit_info = _value_to_text(metadata.get("outfitInfo")) or "top, bottom, shoes, accessories"
    return (
        "Create a cute Korean mobile diary scrapbook card image for an OOTD record. "
        "Use a warm ivory paper background with a subtle square grid notebook pattern, "
        "soft beige and pink tones, tape stickers, paper clips, hearts, sparkles, arrows, and small doodles. "
        "Reserve a clean empty center area where the ONMU character sticker will be composited later. "
        "Do not draw a full character in the center area. "
        "Do not include phone status bars, app navigation buttons, edit buttons, or delete buttons. "
        "Add legible Korean diary handwriting inside separate memo cards. "
        f"Today's Look: {todays_look}. "
        f"Hair: {hair_note}. "
        f"Weather: {weather}. "
        f"Mood: {mood}. "
        f"Outfit Info: {outfit_info}. "
        f"Point: {point}. "
        f"Today's Tag: {tags}. "
        "Keep all text inside cards, avoid cropped stickers, and keep the center character area unobstructed."
    )


def _outfit_brief_from_request(request: dict[str, Any]) -> str:
    descriptor = request.get("outfitDescriptor")
    if isinstance(descriptor, dict):
        descriptor_brief = _descriptor_to_brief(descriptor)
        if descriptor_brief:
            return _clip_text(descriptor_brief, MAX_OUTFIT_BRIEF_CHARS)

    description = str(request.get("outfitDescription") or "").strip()
    if description:
        return _clip_text(description, MAX_OUTFIT_BRIEF_CHARS)

    return "A casual daily OOTD with clear clothing, shoes, and accessories."


def _descriptor_to_brief(descriptor: dict[str, Any]) -> str:
    translation = descriptor.get("pixel_avatar_translation")
    if isinstance(translation, dict):
        generation_brief = str(translation.get("generation_brief") or "").strip()
        if generation_brief:
            parts = [generation_brief]
            photo_features = _string_list(translation.get("must_use_photo_features"))
            fallback_features = _string_list(translation.get("must_use_profile_fallback_for"))
            if photo_features:
                parts.append("Visible photo features that must be preserved: " + "; ".join(photo_features))
            if fallback_features:
                parts.append("Use profile fallback only for: " + "; ".join(fallback_features))
            return "\n".join(parts)

    diary = descriptor.get("outfit_info_for_diary")
    outfit_info = diary.get("outfit_info") if isinstance(diary, dict) else None

    parts: list[str] = []
    for key in ("overall_aesthetic", "style_summary", "styling_notes"):
        value = str(descriptor.get(key) or "").strip()
        if value:
            parts.append(value)

    for key in ("hair", "headwear", "upper_body", "lower_body", "one_piece", "shoes", "socks", "pose_and_silhouette"):
        value = _compact_descriptor_value(key, descriptor.get(key))
        if value:
            parts.append(value)

    for key in ("bags_and_carried_items", "jewelry_and_accessories", "logos_text_graphics", "construction_details", "materials", "colors"):
        values = _string_list(descriptor.get(key))
        if values:
            parts.append(f"{key}: " + "; ".join(values))

    if isinstance(outfit_info, dict):
        info_values = [f"{key}: {value}" for key, value in outfit_info.items() if str(value or "").strip()]
        if info_values:
            parts.append("Diary outfit info: " + "; ".join(info_values))

    fallback = descriptor.get("fallback_to_profile_character")
    if isinstance(fallback, dict):
        fallback_bits = [f"{key}={value}" for key, value in fallback.items() if str(value or "").strip()]
        if fallback_bits:
            parts.append("Fallback plan: " + "; ".join(fallback_bits))

    return "\n".join(parts).strip()


def _profile_reference_brief(profile: Any) -> str:
    if not isinstance(profile, dict):
        return "Use the user's ONMU profile character settings only for hidden or missing details."

    fields = []
    for key in (
        "skinToneIndex",
        "hairStyleIndex",
        "hairColorIndex",
        "eyeStyleIndex",
        "eyeColorIndex",
        "mouthIndex",
        "topIndex",
        "bottomIndex",
    ):
        if key in profile and profile.get(key) is not None:
            fields.append(f"{key}: {profile.get(key)}")
    if not fields:
        return "Use the user's ONMU profile character settings only for hidden or missing details."
    return "Profile character part indices for fallback only: " + ", ".join(fields)


def _compact_descriptor_value(label: str, value: Any) -> str:
    if isinstance(value, dict):
        bits = []
        for key, nested in value.items():
            if isinstance(nested, dict):
                nested_bits = [f"{nested_key} {nested_value}" for nested_key, nested_value in nested.items() if str(nested_value or "").strip()]
                if nested_bits:
                    bits.append(f"{key}: " + ", ".join(nested_bits))
            elif isinstance(nested, list):
                listed = _string_list(nested)
                if listed:
                    bits.append(f"{key}: " + ", ".join(listed))
            elif str(nested or "").strip():
                bits.append(f"{key}: {nested}")
        return f"{label}: " + "; ".join(bits) if bits else ""
    if isinstance(value, list):
        listed = _string_list(value)
        return f"{label}: " + "; ".join(listed) if listed else ""
    text = str(value or "").strip()
    return f"{label}: {text}" if text else ""


def _string_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    results: list[str] = []
    for item in value:
        if isinstance(item, dict):
            text = ", ".join(f"{key} {nested}" for key, nested in item.items() if str(nested or "").strip())
        else:
            text = str(item or "").strip()
        if text:
            results.append(text)
    return results


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


def _clean_text(value: Any) -> str:
    if value is None or not isinstance(value, str):
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
