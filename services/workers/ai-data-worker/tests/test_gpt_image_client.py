import asyncio
import base64
import json

import httpx

from app.ootd.azureml_client import DEFAULT_CHARACTER_IMAGE_BASE64
from app.ootd.gpt_image_client import (
    GptImageConfig,
    GptImageOotdClient,
    build_gpt_image_avatar_prompt,
    build_gpt_image_diary_card_prompt,
)


def test_build_gpt_image_avatar_prompt_keeps_identity_and_uses_outfit_descriptor():
    prompt = build_gpt_image_avatar_prompt(
        {
            "mode": "PHOTO_REFERENCE",
            "outfitDescriptor": {
                "top": {"category": "cardigan", "color": "cream"},
                "bottom": {"category": "skirt", "color": "black"},
                "bag": "burgundy shoulder bag",
            },
        }
    )

    assert "visible OOTD photo analysis" in prompt
    assert "cream" in prompt
    assert "black" in prompt
    assert "burgundy shoulder bag" in prompt
    assert "Keep the same face, hair, skin tone, body, pose, and pixel-art style" in prompt
    assert "Edit the visible outfit, shoes, and wearable accessories only" in prompt


def test_build_gpt_image_diary_card_prompt_contains_diary_sections():
    prompt = build_gpt_image_diary_card_prompt(
        {
            "todaysLook": "Beige and black daily outfit.",
            "hairNote": "Soft waves for today's mood.",
            "weatherText": "20C / clear",
            "moodText": "excited",
            "pointText": "Use the bag as the outfit point.",
            "tags": ["#ootd", "#dailylook"],
            "outfitInfo": {"top": "ivory knit", "bottom": "black skirt"},
        }
    )

    assert "Today's Look" in prompt
    assert "Hair" in prompt
    assert "Weather" in prompt
    assert "Mood" in prompt
    assert "Outfit Info" in prompt
    assert "Today's Tag" in prompt
    assert "Beige and black" in prompt
    assert "#dailylook" in prompt


def test_gpt_image_client_posts_edit_request_with_foundry_bearer_contract():
    seen: dict[str, object] = {}

    async def handler(request: httpx.Request) -> httpx.Response:
        seen["url"] = str(request.url)
        seen["authorization"] = request.headers.get("authorization")
        seen["api_key"] = request.headers.get("api-key")
        seen["content_type"] = request.headers.get("content-type")
        seen["body"] = await request.aread()
        return httpx.Response(
            200,
            json={"data": [{"b64_json": base64.b64encode(b"fake-png").decode("ascii")}]},
        )

    client = GptImageOotdClient(
        GptImageConfig(
            endpoint_url="https://example.openai.azure.com",
            api_key="secret-key",
            api_version="2024-02-01",
            deployment_name="gpt-image-2",
        ),
        transport=httpx.MockTransport(handler),
    )

    result = asyncio.run(
        client.generate(
            {
                "requestId": "job-1",
                "mode": "TEXT_PROMPT",
                "characterImageBase64": DEFAULT_CHARACTER_IMAGE_BASE64,
                "outfitDescription": "ivory knit top and black skirt",
            }
        )
    )

    assert result.status == "succeeded"
    assert result.request_id == "job-1"
    assert result.image_base64 == base64.b64encode(b"fake-png").decode("ascii")
    assert "/openai/deployments/gpt-image-2/images/edits" in str(seen["url"])
    assert "api-version=2024-02-01" in str(seen["url"])
    assert seen["authorization"] == "Bearer secret-key"
    assert seen["api_key"] is None
    assert str(seen["content_type"]).startswith("multipart/form-data")
    assert b'name="image"' in seen["body"]
    assert b'name="mask"' in seen["body"]
    assert b'name="prompt"' in seen["body"]
    assert b'name="size"' in seen["body"]
    assert b'ivory knit top and black skirt' in seen["body"]


def test_gpt_image_client_retries_with_api_key_header_after_foundry_404():
    calls: list[str | None] = []

    async def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request.headers.get("authorization") or request.headers.get("api-key"))
        if len(calls) == 1:
            return httpx.Response(404, json={"error": {"message": "resource not found"}})
        return httpx.Response(
            200,
            json={"data": [{"b64_json": base64.b64encode(b"ok").decode("ascii")}]},
        )

    client = GptImageOotdClient(
        GptImageConfig(
            endpoint_url="https://example.openai.azure.com",
            api_key="secret-key",
            api_version="2024-02-01",
            deployment_name="gpt-image-2",
        ),
        transport=httpx.MockTransport(handler),
    )

    result = asyncio.run(
        client.generate(
            {
                "requestId": "job-2",
                "mode": "PHOTO_REFERENCE",
                "characterImageBase64": DEFAULT_CHARACTER_IMAGE_BASE64,
                "outfitDescriptor": "cream cardigan and black skirt",
            }
        )
    )

    assert result.status == "succeeded"
    assert calls == ["Bearer secret-key", "secret-key"]


def test_gpt_image_client_rejects_response_without_image_data():
    async def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, content=json.dumps({"data": []}))

    client = GptImageOotdClient(
        GptImageConfig(
            endpoint_url="https://example.openai.azure.com",
            api_key="secret-key",
            api_version="2024-02-01",
            deployment_name="gpt-image-2",
        ),
        transport=httpx.MockTransport(handler),
    )

    try:
        asyncio.run(
            client.generate(
                {
                    "requestId": "job-3",
                    "mode": "TEXT_PROMPT",
                    "characterImageBase64": DEFAULT_CHARACTER_IMAGE_BASE64,
                    "outfitDescription": "black dress",
                }
            )
        )
    except RuntimeError as exc:
        assert "did not include data" in str(exc)
    else:
        raise AssertionError("Expected RuntimeError")
