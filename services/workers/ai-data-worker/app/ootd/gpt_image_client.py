"""Azure GPT Image client for ONMU OOTD image generation."""

from __future__ import annotations

import base64
import os
import re
from dataclasses import dataclass
from io import BytesIO
from typing import Any

import httpx
from PIL import Image
from PIL import ImageChops
from PIL import ImageOps

from app.ootd.azureml_client import _optional_int


DEFAULT_IMAGE_SIZE = "1024x1536"
DEFAULT_IMAGE_QUALITY = "low"
MAX_OUTFIT_BRIEF_CHARS = 900
DIARY_CANVAS_WIDTH = 1024
DIARY_CANVAS_HEIGHT = 1536
AVATAR_TARGET_HEIGHT = 720
AVATAR_MAX_WIDTH = 560


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
    avatar_base64: str | None = None


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
        avatar_prompt = build_gpt_image_avatar_prompt(request)
        diary_prompt = build_gpt_image_diary_card_prompt(_diary_metadata_from_request(request))
        url = (
            f"{self._config.endpoint_url}/openai/deployments/"
            f"{self._config.deployment_name}/images/generations"
        )
        params = {"api-version": self._config.api_version}

        async with httpx.AsyncClient(
            timeout=self._config.timeout_seconds,
            transport=self._transport,
        ) as client:
            avatar_base64, avatar_ms = await self._post_generation(
                client,
                url,
                params,
                prompt=avatar_prompt,
            )
            diary_base64, diary_ms = await self._post_generation(
                client,
                url,
                params,
                prompt=diary_prompt,
            )

        image_base64, avatar_base64_trimmed = _compose_ootd_diary_image(diary_base64, avatar_base64)
        duration_ms = _sum_optional_ints(avatar_ms, diary_ms)
        return GptImageResult(
            status="succeeded",
            mode=mode,
            request_id=request_id,
            image_base64=image_base64,
            mime_type="image/png",
            dry_run=False,
            duration_ms=duration_ms,
            error_code=None,
            message=None,
            avatar_base64=avatar_base64_trimmed,
        )

    async def _post_generation(
        self,
        client: httpx.AsyncClient,
        url: str,
        params: dict[str, str],
        *,
        prompt: str,
    ) -> tuple[str, int | None]:
        body = {
            "prompt": prompt,
            "size": DEFAULT_IMAGE_SIZE,
            "quality": DEFAULT_IMAGE_QUALITY,
            "output_compression": 100,
            "output_format": "png",
            "n": 1,
        }
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

        return _extract_image_base64(response.json()), _optional_int(response.headers.get("x-ms-processing-ms"))


def build_gpt_image_avatar_prompt(request: dict[str, Any]) -> str:
    """Build the prompt used by GPT Image for the OOTD diary result image."""

    mode = str(request.get("mode") or request.get("inputType") or "").upper()
    style_brief = _outfit_brief_from_request(request)
    profile_brief = _profile_reference_brief(request.get("characterProfile"))

    if mode == "PHOTO_REFERENCE":
        return f"""
Generate only the full-body ONMU OOTD avatar sticker.

Source priority:
1. Use the visible OOTD photo analysis as the primary evidence for every visible feature.
2. Preserve visible outfit, headwear, hairstyle, hair color, visible skin tone, pose, silhouette, shoes, bags, and accessories from the photo analysis.
3. Use the ONMU profile fallback only for details that are hidden, cropped out, blurry, or not described in the photo.
4. If the photo shows a hairstyle, hat, glasses, bag, or accessory that ONMU profile parts do not have, still use the photo feature.
5. Do not force profile hair, eye, skin, face, or outfit details over visible photo evidence.
6. If the face or eyes are hidden, keep a cute ONMU avatar face using the profile eye color/style and skin tone.

Visible OOTD photo/style analysis:
{style_brief}

Profile fallback for hidden or missing details:
{profile_brief}

Outfit lock:
- The visible outfit analysis is a strict clothing specification, not a loose inspiration.
- Do not replace garment categories. If the photo has pants, generate pants, not a skirt or dress. If the photo has a skirt, generate a skirt, not pants or a dress. If the photo has a dress, generate a dress, not separated top and bottom.
- Do not replace footwear categories. Sneakers must stay sneakers, loafers must stay loafers, boots must stay boots, sandals must stay sandals.
- Do not replace outerwear, tops, bottoms, bags, hats, glasses, belts, socks, jewelry, or handheld items with different item types.
- Preserve the exact visible color family, color placement, fabric/material impression, fit, length, rise, volume, sleeve shape, neckline/collar, hem shape, layering order, and silhouette.
- Preserve visible graphics, logos, lettering, patches, stripes, checks, embroidery, lace, buttons, zippers, pockets, seams, straps, chains, charms, and decorative details.
- Do not simplify, beautify, feminize, masculinize, formalize, casualize, or restyle the outfit into a different fashion look.
- If a detail is uncertain, keep it understated rather than inventing a new fashion item.

Rendering requirements:
- One single full-body ONMU pixel-art avatar sticker, centered.
- No diary page, no notebook background, no labels, no memo cards, no phone UI, no buttons.
- warm ivory paper background is acceptable because this sticker will be composited onto a diary card later.
- After preserving the exact outfit first, render the character as a cute and charming ONMU-like pixel avatar: front-facing full-body game sprite, semi-chibi proportions with a 4 to 4.5 head-to-body ratio, slightly taller and slender silhouette, large expressive eyes, small simple mouth, high-resolution clean pixel art, fine pixel density, thin and soft dark outlines, highly detailed pixel art with exquisite shading, rendering visible intricate accessories precisely (such as necklace pendants, pant chains, or headwear if and only if they are present in the photo analysis) without creating or inventing any non-existent accessories.
- Do not render as a painterly illustration, semi-realistic anime character, fashion sketch, 3D model, photo, or smooth vector art.
- Apply the visible outfit, shoes, bags, headwear, hair, and accessories clearly.
- Preserve visible photo identity cues, and use the profile only for hidden or missing facial/character details.
- Full body visible from head to shoes, clean silhouette, no cropped feet, no extra characters.
""".strip()

    return f"""
Generate only the full-body ONMU OOTD avatar sticker from the user's text description.

Use the text description as the outfit and styling source.
Use the ONMU profile fallback as the character identity for details the text does not specify, such as hairstyle, hair color, eye style, eye color, mouth, skin tone, body proportions, and overall character mood.
If the text explicitly describes hair, eyes, accessories, or pose, the text wins over the profile fallback.
If the text only describes clothes, preserve the profile hairstyle, profile hair color, profile eye color, profile skin tone, and profile face.

Outfit and style request:
{style_brief}

Profile fallback for missing text details:
{profile_brief}

Outfit lock:
- The user's text description is a strict clothing specification, not a loose inspiration.
- Do not replace garment categories. If the text says pants, generate pants, not a skirt or dress. If the text says skirt, generate a skirt, not pants or a dress. If the text says dress, generate a dress, not separated top and bottom.
- Do not replace footwear categories. Sneakers must stay sneakers, loafers must stay loafers, boots must stay boots, sandals must stay sandals.
- Do not replace outerwear, tops, bottoms, bags, hats, glasses, belts, socks, jewelry, or handheld items with different item types.
- Preserve the requested color family, color placement, fabric/material impression, fit, length, rise, volume, sleeve shape, neckline/collar, hem shape, layering order, and silhouette.
- Preserve requested graphics, logos, lettering, patches, stripes, checks, embroidery, lace, buttons, zippers, pockets, seams, straps, chains, charms, and decorative details.
- Do not simplify, beautify, feminize, masculinize, formalize, casualize, or restyle the outfit into a different fashion look.
- If a detail is not specified, use the ONMU profile fallback for character features and keep clothing details simple rather than inventing a different outfit.

Rendering requirements:
- One single full-body ONMU pixel-art avatar sticker, centered.
- No diary page, no notebook background, no labels, no memo cards, no phone UI, no buttons.
- Plain transparent or warm ivory paper background is acceptable because this sticker will be composited onto a diary card later.
- After preserving the exact outfit first, render the character as a cute and charming ONMU-like pixel avatar: front-facing full-body game sprite, semi-chibi proportions with a 4 to 4.5 head-to-body ratio, slightly taller and slender silhouette, large expressive eyes, small simple mouth, high-resolution clean pixel art, fine pixel density, thin and soft dark outlines, highly detailed pixel art with exquisite shading, rendering described intricate accessories precisely (such as necklace pendants, pant chains, or headwear if and only if they are explicitly mentioned in the text description) without creating or inventing any non-existent accessories.
- Do not render as a painterly illustration, semi-realistic anime character, fashion sketch, 3D model, photo, or smooth vector art.
- Apply the described outfit, shoes, bags, and accessories clearly.
- Preserve the profile hairstyle, hair color, eye color, skin tone, and face unless the text explicitly changes them.
- Full body visible from head to shoes, clean silhouette, no cropped feet, no extra characters.
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
        "Reserve a large clean empty center area where the ONMU character sticker will be composited later. "
        "The empty center should be light, unobstructed, and sized for one full-body character sticker. "
        "Do not draw a person, avatar, mannequin, clothing model, face, or body in the center area. "
        "Do not place text, stickers, arrows, cards, or tape over the center area. "
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



def _diary_metadata_from_request(request: dict[str, Any]) -> dict[str, Any]:
    descriptor = request.get("outfitDescriptor")
    diary = descriptor.get("outfit_info_for_diary") if isinstance(descriptor, dict) else None
    metadata: dict[str, Any] = diary.copy() if isinstance(diary, dict) else {}

    for source_key, target_key in [
        ("todayLook", "todaysLook"),
        ("todaysLook", "todaysLook"),
        ("hairNote", "hairNote"),
        ("weather", "weatherText"),
        ("weatherText", "weatherText"),
        ("mood", "moodText"),
        ("moodText", "moodText"),
        ("point", "pointText"),
        ("pointText", "pointText"),
        ("tags", "tags"),
        ("rating", "rating"),
    ]:
        value = request.get(source_key)
        if value not in (None, "", []):
            metadata[target_key] = value

    if "outfitInfo" not in metadata:
        if isinstance(descriptor, dict):
            outfit_info = descriptor.get("outfit_info") or descriptor.get("outfitInfo")
            if outfit_info:
                metadata["outfitInfo"] = outfit_info
        if "outfitInfo" not in metadata:
            metadata["outfitInfo"] = _outfit_brief_from_request(request)

    if "todaysLook" not in metadata:
        metadata["todaysLook"] = _clip_text(_outfit_brief_from_request(request), 180)
    return metadata

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
            text_features = _string_list(translation.get("must_use_text_features"))
            fallback_features = _string_list(translation.get("must_use_profile_fallback_for"))
            if photo_features:
                parts.append("Visible photo features that must be preserved: " + "; ".join(photo_features))
            if text_features:
                parts.append("Explicit text features that must be preserved: " + "; ".join(text_features))
            if fallback_features:
                parts.append(
                    "Use the ONMU profile fallback as mandatory identity lock only for: "
                    + "; ".join(fallback_features)
                )
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

    gender = _clean_text(profile.get("gender"))
    skin_index = _indexed_profile_value(profile, "skinTone", "skinToneIndex", "skin")
    hair_style_index = _indexed_profile_value(profile, "hairStyle", "hairStyleIndex", "hair_style")
    hair_color_index = _indexed_profile_value(profile, "hairColor", "hairColorIndex", "hair_color")
    eye_style_index = _indexed_profile_value(profile, "eyeStyle", "eyeStyleIndex", "eye_style")
    eye_color_index = _indexed_profile_value(profile, "eyeColor", "eyeColorIndex", "eye_color")
    clothes_index = _indexed_profile_value(profile, "clothes", "topStyleIndex", "top")

    details: list[str] = []
    if gender:
        details.append(f"gender presentation: {_gender_description(gender)}")
    if skin_index is not None:
        details.append(f"skin tone: {_skin_tone_description(skin_index)}")
    if hair_style_index is not None:
        details.append(f"hairstyle: {_hair_style_description(hair_style_index)}")
    if hair_color_index is not None:
        details.append(f"hair color: {_hair_color_description(hair_color_index)}")
    if eye_style_index is not None:
        details.append(f"eye style: {_eye_style_description(eye_style_index)}")
    if eye_color_index is not None:
        details.append(f"eye color: {_eye_color_description(eye_color_index)}")
    if clothes_index is not None:
        details.append(f"default profile outfit slot: {clothes_index}")

    if not details:
        return "Use the user's ONMU profile character settings only for hidden or missing details."

    return (
        "ONMU profile fallback details for hidden or unspecified character features: "
        + "; ".join(details)
        + ". Exact profile colors and identity locks above are mandatory whenever a feature is listed as profile fallback. "
        + "Use these details strongly for text-only requests and only as fallback for photo requests."
    )


def _indexed_profile_value(profile: dict[str, Any], string_key: str, index_key: str, prefix: str) -> int | None:
    if index_key in profile and profile.get(index_key) is not None:
        try:
            return int(profile.get(index_key))
        except (TypeError, ValueError):
            pass
    value = profile.get(string_key)
    if value is None:
        return None
    match = re.search(rf"{re.escape(prefix)}_(-?\d+)", str(value))
    if match:
        try:
            return int(match.group(1))
        except ValueError:
            return None
    return None


def _gender_description(value: str) -> str:
    normalized = value.strip().lower()
    return {
        "male": "male-presenting ONMU avatar",
        "man": "male-presenting ONMU avatar",
        "boy": "male-presenting ONMU avatar",
        "female": "female-presenting ONMU avatar",
        "woman": "female-presenting ONMU avatar",
        "girl": "female-presenting ONMU avatar",
    }.get(normalized, f"{value} ONMU avatar presentation")


def _skin_tone_description(index: int) -> str:
    return {
        0: "very fair peach skin (#FEE7DA)",
        1: "light warm peach skin (#F5CDA7)",
        2: "warm tan skin (#E0A96D)",
        3: "deep warm brown skin (#96613F)",
        4: "dark brown skin (#4D2C19)",
    }.get(index, f"profile skin tone slot {index}")


def _hair_color_description(index: int) -> str:
    return {
        0: "black hair (#1E1E1E)",
        1: "brown hair (#7A5230)",
        2: "blonde hair (#E7D08B)",
        3: "white or silver hair (#F5F5F5)",
        4: "soft pink hair (#E6A3C6)",
        5: "red hair (#C94B4B)",
        6: "blue hair (#7FA9E6)",
        7: "mint hair (#7ED8B6)",
        8: "purple/violet hair (#9A79D8)",
        9: "lime green hair (#9AD64D)",
    }.get(index, f"profile hair color slot {index}")


def _eye_color_description(index: int) -> str:
    return {
        0: "black or dark gray eyes (#3A3A3A)",
        1: "brown eyes (#8B5A3C)",
        2: "blue eyes (#4F8FD9)",
        3: "pink eyes (#D86A9C)",
        4: "green eyes (#6FA45A)",
        5: "gray eyes (#7A7A7A)",
        6: "purple/violet eyes (#8A6BB8)",
        7: "gold or amber eyes (#C99652)",
    }.get(index, f"profile eye color slot {index}")


def _hair_style_description(index: int) -> str:
    return {
        0: "long straight center-part hair",
        1: "soft long wavy hair",
        2: "layered long hair",
        3: "short bob or medium-length hair",
        4: "asymmetric tied side ponytail hair",
        5: "twin-tail or decorated long hair",
    }.get(index, f"profile hairstyle slot {index}")


def _eye_style_description(index: int) -> str:
    return {
        0: "soft round anime eyes",
        1: "slim gentle eyes",
        2: "bright rounded eyes",
        3: "sleepy downturned eyes",
        4: "sharp cat-like eyes",
        5: "cute smiling eyes",
    }.get(index, f"profile eye style slot {index}")


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



def _compose_ootd_diary_image(diary_base64: str, avatar_base64: str) -> tuple[str, str]:
    diary = ImageOps.fit(
        _decode_png(diary_base64).convert("RGBA"),
        (DIARY_CANVAS_WIDTH, DIARY_CANVAS_HEIGHT),
        method=Image.Resampling.LANCZOS,
    )
    trimmed_avatar = _trim_avatar_background(_decode_png(avatar_base64).convert("RGBA"))
    avatar = _resize_avatar_for_diary(trimmed_avatar)

    x = (DIARY_CANVAS_WIDTH - avatar.width) // 2
    y = int(DIARY_CANVAS_HEIGHT * 0.28)
    diary.alpha_composite(avatar, (x, y))

    # Save diary composite
    diary_buffer = BytesIO()
    diary.save(diary_buffer, format="PNG")
    diary_result = base64.b64encode(diary_buffer.getvalue()).decode("ascii")

    # Save trimmed transparent avatar
    avatar_buffer = BytesIO()
    trimmed_avatar.save(avatar_buffer, format="PNG")
    avatar_result = base64.b64encode(avatar_buffer.getvalue()).decode("ascii")

    return diary_result, avatar_result


def _decode_png(image_base64: str) -> Image.Image:
    try:
        return Image.open(BytesIO(base64.b64decode(image_base64))).convert("RGBA")
    except Exception as exc:  # pragma: no cover - defensive guard for provider payloads
        raise RuntimeError("GPT Image response contained invalid PNG base64") from exc


def _trim_avatar_background(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    if alpha.getextrema()[0] < 255:
        bbox = alpha.getbbox()
        if bbox:
            return image.crop(_pad_bbox(bbox, image.size, 12))

    background = Image.new("RGBA", image.size, image.getpixel((0, 0)))
    diff = ImageChops.difference(image, background).convert("L")
    mask = diff.point(lambda value: 255 if value > 18 else 0)
    bbox = mask.getbbox()
    if not bbox:
        return image
    return image.crop(_pad_bbox(bbox, image.size, 12))


def _pad_bbox(bbox: tuple[int, int, int, int], size: tuple[int, int], padding: int) -> tuple[int, int, int, int]:
    left, top, right, bottom = bbox
    width, height = size
    return (
        max(0, left - padding),
        max(0, top - padding),
        min(width, right + padding),
        min(height, bottom + padding),
    )


def _resize_avatar_for_diary(avatar: Image.Image) -> Image.Image:
    if avatar.height <= 0 or avatar.width <= 0:
        return avatar
    scale = AVATAR_TARGET_HEIGHT / avatar.height
    if avatar.width * scale > AVATAR_MAX_WIDTH:
        scale = AVATAR_MAX_WIDTH / avatar.width
    width = max(1, int(avatar.width * scale))
    height = max(1, int(avatar.height * scale))
    return avatar.resize((width, height), Image.Resampling.LANCZOS)


def _sum_optional_ints(*values: int | None) -> int | None:
    present = [value for value in values if value is not None]
    return sum(present) if present else None

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
