"""Azure OpenAI text client for place recommendation explanations."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import Any

import httpx

PLACE_REASON_SYSTEM_PROMPT = (
    "너는 ONMU 약속 장소 후보를 설명하는 보조자다. "
    "사용자가 볼 문장만 JSON으로 반환한다. provider 이름, 내부 점수, raw query, raw body, token, secret은 절대 쓰지 않는다."
)

PLACE_REASON_USER_PROMPT = (
    "아래 안전 메타데이터만 보고 장소 후보 설명을 만든다. "
    "summary는 80자 이내 한국어 한 문장, reasons는 최대 3개, 각 60자 이내로 작성한다. "
    "추천은 결정을 대신하지 않고 비교를 돕는 표현만 사용한다."
)


@dataclass(frozen=True)
class PlaceReasonConfig:
    endpoint_url: str
    deployment_name: str
    api_key: str
    api_version: str
    timeout_seconds: float = 45.0


class AzureOpenAiPlaceReasonClient:
    def __init__(self, config: PlaceReasonConfig | None):
        self._config = config

    @classmethod
    def from_env(cls, *, required: bool) -> "AzureOpenAiPlaceReasonClient":
        endpoint_url = os.environ.get("ONMU_PLACE_REASON_OPENAI_ENDPOINT_URL", "").strip()
        deployment_name = os.environ.get("ONMU_PLACE_REASON_OPENAI_DEPLOYMENT_NAME", "").strip()
        api_key = os.environ.get("ONMU_PLACE_REASON_OPENAI_API_KEY", "").strip()
        api_version = os.environ.get("ONMU_PLACE_REASON_OPENAI_API_VERSION", "").strip()
        missing = [
            name
            for name, value in [
                ("ONMU_PLACE_REASON_OPENAI_ENDPOINT_URL", endpoint_url),
                ("ONMU_PLACE_REASON_OPENAI_DEPLOYMENT_NAME", deployment_name),
                ("ONMU_PLACE_REASON_OPENAI_API_KEY", api_key),
                ("ONMU_PLACE_REASON_OPENAI_API_VERSION", api_version),
            ]
            if not value
        ]
        if required and missing:
            raise RuntimeError(f"Missing required Place Reason env vars: {', '.join(missing)}")
        if missing:
            return cls(None)
        return cls(
            PlaceReasonConfig(
                endpoint_url=endpoint_url.rstrip("/"),
                deployment_name=deployment_name,
                api_key=api_key,
                api_version=api_version,
            )
        )

    @property
    def is_configured(self) -> bool:
        return self._config is not None

    @property
    def model_name(self) -> str | None:
        return None if self._config is None else self._config.deployment_name

    async def generate_place_reason(
        self,
        *,
        event_id: str,
        candidate: dict[str, Any],
    ) -> dict[str, Any]:
        if self._config is None:
            raise RuntimeError("Azure OpenAI place reason client is not configured")

        url = (
            f"{self._config.endpoint_url}/openai/deployments/"
            f"{self._config.deployment_name}/chat/completions"
        )
        body = {
            "messages": [
                {"role": "system", "content": PLACE_REASON_SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": (
                        f"{PLACE_REASON_USER_PROMPT}\n\n"
                        f"event_id: {event_id}\n"
                        f"candidate_metadata: {json.dumps(candidate, ensure_ascii=False)}"
                    ),
                },
            ],
            "max_tokens": 700,
            "temperature": 0.2,
            "top_p": 0.3,
            "response_format": {"type": "json_object"},
        }
        headers = {
            "api-key": self._config.api_key,
            "Content-Type": "application/json",
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
            raise RuntimeError(_redact_secret(f"Azure OpenAI place reason returned HTTP {response.status_code}"))

        raw_text = _extract_message_text(response.json())
        parsed = _parse_json(raw_text)
        return {
            "summary": _clean_text(parsed.get("summary"), 180),
            "reasons": _clean_reasons(parsed.get("reasons")),
        }


def _extract_message_text(body: dict[str, Any]) -> str:
    choices = body.get("choices")
    if not isinstance(choices, list) or not choices:
        raise RuntimeError("Azure OpenAI place reason response did not include choices")
    message = choices[0].get("message") if isinstance(choices[0], dict) else None
    content = message.get("content") if isinstance(message, dict) else None
    if not isinstance(content, str) or not content.strip():
        raise RuntimeError("Azure OpenAI place reason response did not include message content")
    return content.strip()


def _parse_json(raw_text: str) -> dict[str, Any]:
    text = _strip_markdown_json_fence(raw_text)
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError as exc:
        raise RuntimeError("Azure OpenAI place reason returned non-JSON content") from exc
    if not isinstance(parsed, dict):
        raise RuntimeError("Azure OpenAI place reason JSON must be an object")
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


def _clean_text(value: Any, limit: int) -> str | None:
    if not isinstance(value, str):
        return None
    text = " ".join(value.strip().split())
    return text[:limit] if text else None


def _clean_reasons(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    result: list[str] = []
    for item in value:
        text = _clean_text(item, 120)
        if text and text not in result:
            result.append(text)
        if len(result) >= 3:
            break
    return result


def _redact_secret(value: str) -> str:
    for env_name in ["ONMU_PLACE_REASON_OPENAI_API_KEY"]:
        secret = os.environ.get(env_name, "")
        if secret:
            value = value.replace(secret, "<redacted>")
    return value[:800]
