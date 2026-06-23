from __future__ import annotations

import asyncio
import base64
import json
from io import BytesIO

import httpx
from PIL import Image

from app.ootd.gpt_image_client import GptImageConfig
from app.ootd.gpt_image_client import GptImageOotdClient
from app.ootd.gpt_image_client import build_gpt_image_avatar_prompt
from app.ootd.gpt_image_client import build_gpt_image_diary_card_prompt


def _png_base64(color: tuple[int, int, int, int], *, size: tuple[int, int] = (1024, 1024)) -> str:
    image = Image.new("RGBA", size, color)
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def test_photo_prompt_uses_photo_first_and_profile_only_as_fallback() -> None:
    prompt = build_gpt_image_avatar_prompt(
        {
            "mode": "PHOTO_REFERENCE",
            "outfitDescriptor": {
                "hair": {"style": "half-up tied dark wavy hair visible under a white and green cap"},
                "headwear": {"type": "white and green baseball cap with CBO lettering"},
                "upper_body": {"item": "black rugby shirt with white horizontal stripes"},
                "lower_body": {"item": "very wide gray washed denim jeans"},
                "pixel_avatar_translation": {
                    "generation_brief": "black striped rugby shirt, gray wide jeans, white green cap, dark half-up hair",
                    "must_use_photo_features": ["half-up tied dark hair", "white and green CBO cap"],
                    "must_use_profile_fallback_for": ["eyes", "mouth"],
                },
            },
            "characterProfile": {"skinToneIndex": 0, "hairStyleIndex": 2, "hairColorIndex": 8, "eyeColorIndex": 6},
        }
    )

    assert "Generate only the full-body ONMU OOTD avatar sticker" in prompt
    assert "visible OOTD photo analysis as the primary evidence" in prompt
    assert "Use the ONMU profile fallback only" in prompt
    assert "If the photo shows a hairstyle, hat, glasses, bag, or accessory" in prompt
    assert "half-up tied dark hair" in prompt
    assert "purple/violet hair" in prompt
    assert "purple/violet eyes" in prompt
    assert "No diary page" in prompt
    assert "full mobile OOTD diary scrapbook page" not in prompt


def test_text_prompt_uses_text_and_profile_for_missing_details() -> None:
    prompt = build_gpt_image_avatar_prompt(
        {
            "mode": "TEXT_PROMPT",
            "outfitDescription": "Oversized navy hoodie, ivory cargo skirt, silver headphones, black boots.",
            "characterProfile": {
                "skinTone": "skin_0",
                "hairStyle": "hair_style_0",
                "hairColor": "hair_color_8",
                "eyeStyle": "eye_style_0",
                "eyeColor": "eye_color_6",
            },
        }
    )

    assert "from the user's text description" in prompt
    assert "If the text explicitly describes hair" in prompt
    assert "Oversized navy hoodie" in prompt
    assert "purple/violet hair" in prompt
    assert "purple/violet eyes" in prompt
    assert "very fair peach skin" in prompt
    assert "preserve the profile hairstyle" in prompt
    assert "No diary page" in prompt


def test_diary_card_prompt_reserves_empty_center_for_compositing() -> None:
    prompt = build_gpt_image_diary_card_prompt(
        {
            "todaysLook": "???? ?? ??? ??? ????",
            "weatherText": "rainy",
            "moodText": "tired",
            "pointText": "??? ?? ???",
            "tags": ["#ootd", "#dailylook"],
            "outfitInfo": {"top": "ivory knit", "bottom": "black skirt"},
        }
    )

    assert "Reserve a large clean empty center area" in prompt
    assert "Do not draw a person, avatar, mannequin" in prompt
    assert "Do not place text, stickers, arrows, cards, or tape over the center area" in prompt
    assert "Today's Look" in prompt
    assert "??? ?? ???" in prompt


def test_gpt_image_client_posts_avatar_and_diary_generation_requests_with_foundry_bearer_contract() -> None:
    asyncio.run(_assert_gpt_image_client_posts_avatar_and_diary_generation_requests_with_foundry_bearer_contract())


async def _assert_gpt_image_client_posts_avatar_and_diary_generation_requests_with_foundry_bearer_contract() -> None:
    captured: list[dict[str, object]] = []
    avatar_png = _png_base64((255, 255, 255, 255), size=(320, 640))
    diary_png = _png_base64((250, 244, 236, 255))

    async def handler(request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content.decode("utf-8"))
        captured.append({"url": str(request.url), "headers": dict(request.headers), "body": body})
        image = avatar_png if len(captured) == 1 else diary_png
        return httpx.Response(
            200,
            json={"data": [{"b64_json": image}]},
            headers={"x-ms-processing-ms": "1234"},
        )

    client = GptImageOotdClient(
        GptImageConfig(
            endpoint_url="https://example.cognitiveservices.azure.com",
            api_key="secret-key",
            api_version="2024-02-01",
            deployment_name="gpt-image-2",
        ),
        transport=httpx.MockTransport(handler),
    )

    result = await client.generate(
        {
            "requestId": "job-1",
            "mode": "PHOTO_REFERENCE",
            "outfitDescriptor": {
                "style_summary": "beige cardigan and black skirt",
                "outfit_info_for_diary": {"pointText": "burgundy bag point"},
            },
            "characterProfile": {"hairStyleIndex": 1},
        }
    )

    assert result.status == "succeeded"
    assert result.request_id == "job-1"
    assert result.duration_ms == 2468
    assert len(captured) == 2
    for item in captured:
        assert "/openai/deployments/gpt-image-2/images/generations" in str(item["url"])
        assert "api-version=2024-02-01" in str(item["url"])
        assert item["headers"]["authorization"] == "Bearer secret-key"
        body = item["body"]
        assert isinstance(body, dict)
        assert body["size"] == "1024x1536"
        assert body["quality"] == "low"
        assert body["output_format"] == "png"
        assert body["output_compression"] == 100
        assert body["n"] == 1

    avatar_prompt = str(captured[0]["body"]["prompt"])
    diary_prompt = str(captured[1]["body"]["prompt"])
    assert "Generate only the full-body ONMU OOTD avatar sticker" in avatar_prompt
    assert "beige cardigan and black skirt" in avatar_prompt
    assert "Reserve a large clean empty center area" in diary_prompt
    assert "burgundy bag point" in diary_prompt
    decoded = Image.open(BytesIO(base64.b64decode(result.image_base64)))
    assert decoded.size == (1024, 1536)


def test_gpt_image_client_retries_with_api_key_for_openai_account_style_auth() -> None:
    asyncio.run(_assert_gpt_image_client_retries_with_api_key_for_openai_account_style_auth())


async def _assert_gpt_image_client_retries_with_api_key_for_openai_account_style_auth() -> None:
    auth_headers: list[str] = []
    avatar_png = _png_base64((255, 255, 255, 255), size=(320, 640))
    diary_png = _png_base64((250, 244, 236, 255))

    async def handler(request: httpx.Request) -> httpx.Response:
        auth_headers.append(request.headers.get("authorization") or request.headers.get("api-key") or "")
        if len(auth_headers) == 1:
            return httpx.Response(404, json={"error": {"message": "Resource not found"}})
        image = avatar_png if len(auth_headers) == 2 else diary_png
        return httpx.Response(200, json={"data": [{"b64_json": image}]})

    client = GptImageOotdClient(
        GptImageConfig(
            endpoint_url="https://example.openai.azure.com",
            api_key="secret-key",
            api_version="2025-04-01",
            deployment_name="gpt-image-2",
        ),
        transport=httpx.MockTransport(handler),
    )

    result = await client.generate({"requestId": "job-2", "mode": "TEXT_PROMPT", "outfitDescription": "red cardigan"})

    assert result.status == "succeeded"
    assert auth_headers == ["Bearer secret-key", "secret-key", "Bearer secret-key"]
