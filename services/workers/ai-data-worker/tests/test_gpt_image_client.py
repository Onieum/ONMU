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

    assert "Change only the outfit" in prompt
    assert "cream" in prompt
    assert "black" in prompt
    assert "burgundy shoulder bag" in prompt
    assert "Keep the same face" in prompt
    assert "Do not redesign the character" in prompt


def test_build_gpt_image_diary_card_prompt_contains_diary_sections():
    prompt = build_gpt_image_diary_card_prompt(
        {
            "todaysLook": "베이지와 블랙 조합이 단정한 룩이에요.",
            "hairNote": "웨이브를 살짝 넣었어요.",
            "weatherText": "20°C / 맑음",
            "moodText": "신나요!",
            "pointText": "가방으로 포인트 주기!",
            "tags": ["#ootd", "#데이트룩"],
            "outfitInfo": {"top": "아이보리 니트", "bottom": "블랙 스커트"},
        }
    )

    assert "Today's Look" in prompt
    assert "Hair" in prompt
    assert "Weather" in prompt
    assert "Mood" in prompt
    assert "Outfit Info" in prompt
    assert "Today's Tag" in prompt
    assert "베이지와 블랙" in prompt
    assert "#데이트룩" in prompt


def test_gpt_image_client_posts_image_edit_request_with_bearer_auth():
    seen: dict[str, object] = {}

    async def handler(request: httpx.Request) -> httpx.Response:
        seen["url"] = str(request.url)
        seen["authorization"] = request.headers.get("authorization")
        seen["content_type"] = request.headers.get("content-type")
        body = await request.aread()
        seen["body"] = body.decode("utf-8", errors="ignore")
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
    assert str(seen["content_type"]).startswith("multipart/form-data")
    assert "ivory knit top and black skirt" in str(seen["body"])


def test_gpt_image_client_retries_with_api_key_header_after_auth_failure():
    calls: list[str | None] = []

    async def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request.headers.get("authorization") or request.headers.get("api-key"))
        if len(calls) == 1:
            return httpx.Response(401, json={"error": {"message": "bad bearer"}})
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
