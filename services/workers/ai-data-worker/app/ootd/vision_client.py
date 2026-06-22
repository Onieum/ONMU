"""Azure OpenAI Vision client for OOTD outfit analysis."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import Any

import httpx

from app.ootd.prompts import (
    VISION_OUTFIT_DESCRIPTOR_PROMPT,
    VISION_OUTFIT_DESCRIPTOR_SYSTEM_RULES,
)


@dataclass(frozen=True)
class VisionConfig:
    endpoint_url: str
    deployment_name: str
    api_key: str
    api_version: str
    timeout_seconds: float = 90.0


@dataclass(frozen=True)
class VisionOutfitDescriptor:
    descriptor: dict[str, Any]
    raw_text: str
    model: str
    api_version: str


class AzureOpenAiVisionClient:
    def __init__(self, config: VisionConfig | None):
        self._config = config

    @classmethod
    def from_env(cls, *, required: bool) -> "AzureOpenAiVisionClient":
        endpoint_url = os.environ.get("ONMU_VISION_ENDPOINT_URL", "").strip()
        deployment_name = os.environ.get("ONMU_VISION_DEPLOYMENT_NAME", "").strip()
        api_key = os.environ.get("ONMU_VISION_API_KEY", "").strip()
        api_version = os.environ.get("ONMU_VISION_API_VERSION", "").strip()
        missing = [
            name
            for name, value in [
                ("ONMU_VISION_ENDPOINT_URL", endpoint_url),
                ("ONMU_VISION_DEPLOYMENT_NAME", deployment_name),
                ("ONMU_VISION_API_KEY", api_key),
                ("ONMU_VISION_API_VERSION", api_version),
            ]
            if not value
        ]
        if required and missing:
            raise RuntimeError(f"Missing required Vision env vars: {', '.join(missing)}")
        if missing:
            return cls(None)
        return cls(
            VisionConfig(
                endpoint_url=endpoint_url.rstrip("/"),
                deployment_name=deployment_name,
                api_key=api_key,
                api_version=api_version,
            )
        )

    @property
    def is_configured(self) -> bool:
        return self._config is not None

    async def analyze_outfit(
        self,
        *,
        request_id: str,
        image_source: str,
    ) -> VisionOutfitDescriptor:
        if self._config is None:
            raise RuntimeError("Azure OpenAI Vision client is not configured")
        if not image_source:
            raise ValueError("image_source is required")

        url = (
            f"{self._config.endpoint_url}/openai/deployments/"
            f"{self._config.deployment_name}/chat/completions"
        )
        headers = {
            "api-key": self._config.api_key,
            "Content-Type": "application/json",
        }
        body = {
            "messages": [
                {
                    "role": "system",
                    "content": VISION_OUTFIT_DESCRIPTOR_SYSTEM_RULES,
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": f"{VISION_OUTFIT_DESCRIPTOR_PROMPT}\n\nrequest_id: {request_id}",
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": image_source,
                                "detail": "high",
                            },
                        },
                    ],
                },
            ],
            "max_tokens": 4096,
            "temperature": 0.1,
            "top_p": 0.2,
            "response_format": {"type": "json_object"},
        }

        async with httpx.AsyncClient(timeout=self._config.timeout_seconds) as client:
            response = await client.post(
                url,
                params={"api-version": self._config.api_version},
                headers=headers,
                json=body,
            )
            if response.status_code >= 400 and "response_format" in response.text:
                fallback_body = dict(body)
                fallback_body.pop("response_format", None)
                response = await client.post(
                    url,
                    params={"api-version": self._config.api_version},
                    headers=headers,
                    json=fallback_body,
                )

        if response.status_code >= 400:
            raise RuntimeError(
                _redact_secret(
                    f"Azure OpenAI Vision returned HTTP {response.status_code}: {response.text}"
                )
            )

        raw_text = _extract_message_text(response.json())
        descriptor = _parse_descriptor(raw_text)
        return VisionOutfitDescriptor(
            descriptor=descriptor,
            raw_text=raw_text,
            model=self._config.deployment_name,
            api_version=self._config.api_version,
        )


def build_image_source_from_payload(payload: dict[str, Any]) -> str:
    base64_value = _clean_optional_text(payload.get("outfitPhotoImageBase64"))
    if base64_value:
        if base64_value.startswith("data:"):
            return base64_value
        return f"data:image/png;base64,{base64_value}"

    media = payload.get("outfitPhotoMedia")
    if isinstance(media, dict):
        public_url = _clean_optional_text(media.get("publicUrl"))
        if public_url.startswith("http://") or public_url.startswith("https://"):
            return public_url
    return ""


def _extract_message_text(body: dict[str, Any]) -> str:
    choices = body.get("choices")
    if not isinstance(choices, list) or not choices:
        raise RuntimeError("Azure OpenAI Vision response did not include choices")
    message = choices[0].get("message") if isinstance(choices[0], dict) else None
    content = message.get("content") if isinstance(message, dict) else None
    if not isinstance(content, str) or not content.strip():
        raise RuntimeError("Azure OpenAI Vision response did not include message content")
    return content.strip()


def _parse_descriptor(raw_text: str) -> dict[str, Any]:
    raw_text = _strip_markdown_json_fence(raw_text)
    try:
        parsed = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        raise RuntimeError("Azure OpenAI Vision returned non-JSON content") from exc
    if not isinstance(parsed, dict) or not parsed:
        raise RuntimeError("Azure OpenAI Vision descriptor must be a non-empty JSON object")
    return parsed


def _strip_markdown_json_fence(value: str) -> str:
    text = value.strip()
    if not text.startswith("```"):
        return text
    lines = text.splitlines()
    if lines and lines[0].strip().startswith("```"):
        lines = lines[1:]
    if lines and lines[-1].strip() == "```":
        lines = lines[:-1]
    return "\n".join(lines).strip()


def _clean_optional_text(value: Any) -> str:
    if value is None:
        return ""
    if not isinstance(value, str):
        return ""
    return value.strip()


def _redact_secret(value: str) -> str:
    for env_name in ["ONMU_VISION_API_KEY", "ONMU_AZUREML_ENDPOINT_KEY", "ONMU_HF_TOKEN"]:
        secret = os.environ.get(env_name, "")
        if secret:
            value = value.replace(secret, "<redacted>")
    return value[:800]
