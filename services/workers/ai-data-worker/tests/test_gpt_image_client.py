from __future__ import annotations

import base64
import asyncio
import json

import httpx

from app.ootd.gpt_image_client import GptImageConfig
from app.ootd.gpt_image_client import GptImageOotdClient
from app.ootd.gpt_image_client import build_gpt_image_avatar_prompt


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
            "characterProfile": {"hairStyleIndex": 2, "hairColorIndex": 5, "eyeColorIndex": 3},
        }
    )

    assert "visible OOTD photo analysis as the primary evidence" in prompt
    assert "Use the ONMU profile fallback only" in prompt
    assert "photo hairstyle or hat anyway" in prompt
    assert "half-up tied dark hair" in prompt
    assert "Profile character part indices for fallback only" in prompt
    assert "No diary page" in prompt


def test_text_prompt_uses_text_and_profile_for_missing_details() -> None:
    prompt = build_gpt_image_avatar_prompt(
        {
            "mode": "TEXT_PROMPT",
            "outfitDescription": "Oversized navy hoodie, ivory cargo skirt, silver headphones, black boots.",
            "characterProfile": {"hairStyleIndex": 1, "eyeColorIndex": 4},
        }
    )

    assert "from the user's text description" in prompt
    assert "If the text explicitly describes hair" in prompt
    assert "Oversized navy hoodie" in prompt
    assert "Profile character part indices for fallback only" in prompt
    assert "No diary page" in prompt


def test_gpt_image_client_posts_generation_request_with_foundry_bearer_contract() -> None:
    asyncio.run(_assert_gpt_image_client_posts_generation_request_with_foundry_bearer_contract())


async def _assert_gpt_image_client_posts_generation_request_with_foundry_bearer_contract() -> None:
    captured: dict[str, object] = {}

    async def handler(request: httpx.Request) -> httpx.Response:
        captured["url"] = str(request.url)
        captured["headers"] = dict(request.headers)
        captured["body"] = json.loads(request.content.decode("utf-8"))
        return httpx.Response(
            200,
            json={"data": [{"b64_json": base64.b64encode(b"png").decode("ascii")}]},
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
            "outfitDescriptor": {"style_summary": "beige cardigan and black skirt"},
            "characterProfile": {"hairStyleIndex": 1},
        }
    )

    assert result.status == "succeeded"
    assert result.request_id == "job-1"
    assert result.duration_ms == 1234
    assert "/openai/deployments/gpt-image-2/images/generations" in str(captured["url"])
    assert "api-version=2024-02-01" in str(captured["url"])
    assert captured["headers"]["authorization"] == "Bearer secret-key"
    body = captured["body"]
    assert isinstance(body, dict)
    assert body["size"] == "1024x1024"
    assert body["quality"] == "low"
    assert body["output_format"] == "png"
    assert body["output_compression"] == 100
    assert body["n"] == 1
    assert "beige cardigan and black skirt" in str(body["prompt"])


def test_gpt_image_client_retries_with_api_key_for_openai_account_style_auth() -> None:
    asyncio.run(_assert_gpt_image_client_retries_with_api_key_for_openai_account_style_auth())


async def _assert_gpt_image_client_retries_with_api_key_for_openai_account_style_auth() -> None:
    auth_headers: list[str] = []

    async def handler(request: httpx.Request) -> httpx.Response:
        auth_headers.append(request.headers.get("authorization") or request.headers.get("api-key") or "")
        if len(auth_headers) == 1:
            return httpx.Response(404, json={"error": {"message": "Resource not found"}})
        return httpx.Response(200, json={"data": [{"b64_json": base64.b64encode(b"png").decode("ascii")}]})

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
    assert auth_headers == ["Bearer secret-key", "secret-key"]
