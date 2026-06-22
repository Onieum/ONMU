import base64
import gc
import inspect
import io
import json
import os
import time
from dataclasses import dataclass
from typing import Any

from PIL import Image, ImageDraw, ImageFont, ImageStat

from prompts import (
    NEGATIVE_PROMPT,
    build_descriptor_generation_prompt,
    build_text_generation_prompt,
)


_CONFIG: "EndpointConfig | None" = None
_PIPELINE: Any | None = None


@dataclass(frozen=True)
class EndpointConfig:
    hf_token: str
    model_id: str
    model_revision: str
    device: str
    dry_run: bool
    max_steps: int
    max_width: int
    max_height: int
    max_sequence_length: int


class RequestError(ValueError):
    pass


def init() -> None:
    global _CONFIG
    _CONFIG = EndpointConfig(
        hf_token=os.environ.get("ONMU_HF_TOKEN", ""),
        model_id=os.environ.get("ONMU_OOTD_MODEL_ID", ""),
        model_revision=os.environ.get("ONMU_OOTD_MODEL_REVISION", ""),
        device=os.environ.get("ONMU_OOTD_DEVICE", "cuda"),
        dry_run=_parse_bool(os.environ.get("ONMU_OOTD_DRY_RUN", "true")),
        max_steps=_parse_int(os.environ.get("ONMU_OOTD_MAX_STEPS", "24"), 1, 48),
        max_width=_parse_int(os.environ.get("ONMU_OOTD_MAX_WIDTH", "1024"), 256, 1536),
        max_height=_parse_int(os.environ.get("ONMU_OOTD_MAX_HEIGHT", "1024"), 256, 1536),
        max_sequence_length=_parse_int(os.environ.get("ONMU_OOTD_MAX_SEQUENCE_LENGTH", "128"), 64, 512),
    )
    if not _CONFIG.dry_run:
        _load_pipeline(_CONFIG)


def run(raw_data: Any) -> dict[str, Any]:
    started = time.time()
    try:
        config = _require_config()
        payload = _parse_payload(raw_data)
        request_id = str(payload.get("requestId") or "")
        mode = str(payload.get("mode") or "").upper()

        character_image = _decode_image(payload.get("characterImageBase64"), "characterImageBase64")
        outfit_description = _clean_optional_text(payload.get("outfitDescription"))
        outfit_descriptor = payload.get("outfitDescriptor")
        prompt_override = _clean_optional_text(payload.get("promptOverride"))

        if mode not in {"TEXT_PROMPT", "PHOTO_REFERENCE"}:
            raise RequestError("mode must be TEXT_PROMPT or PHOTO_REFERENCE")

        if mode == "TEXT_PROMPT":
            if not outfit_description:
                raise RequestError("outfitDescription is required for TEXT_PROMPT")
            if outfit_descriptor:
                raise RequestError("TEXT_PROMPT cannot include outfitDescriptor")
            if payload.get("outfitImageBase64"):
                raise RequestError("TEXT_PROMPT cannot include outfitImageBase64")
            prompt = prompt_override or build_text_generation_prompt(outfit_description)
            reference_image = _prepare_reference_image(character_image, config.max_width, config.max_height)
        else:
            if outfit_description:
                raise RequestError("PHOTO_REFERENCE cannot include outfitDescription")
            if payload.get("outfitImageBase64"):
                raise RequestError("PHOTO_REFERENCE expects Vision AI outfitDescriptor, not raw outfitImageBase64")
            descriptor = _normalize_descriptor(outfit_descriptor)
            prompt = prompt_override or build_descriptor_generation_prompt(descriptor)
            reference_image = _prepare_reference_image(character_image, config.max_width, config.max_height)

        seed = _parse_optional_int(payload.get("seed"))
        steps = _clamp(_parse_optional_int(payload.get("numInferenceSteps")) or config.max_steps, 1, config.max_steps)
        guidance_scale = float(payload.get("guidanceScale") or 2.5)
        max_sequence_length = _clamp(
            _parse_optional_int(payload.get("maxSequenceLength")) or config.max_sequence_length,
            64,
            config.max_sequence_length,
        )
        use_negative_prompt = _parse_optional_bool(payload.get("useNegativePrompt"), default=False)
        use_dimensions = _parse_optional_bool(payload.get("useDimensions"), default=False)

        if config.dry_run:
            output_image = _build_dry_run_image(reference_image, mode, request_id)
        else:
            output_image = _generate_image(
                config=config,
                prompt=prompt,
                reference_image=reference_image,
                seed=seed,
                steps=steps,
                guidance_scale=guidance_scale,
                max_sequence_length=max_sequence_length,
                use_negative_prompt=use_negative_prompt,
                use_dimensions=use_dimensions,
            )

        duration_ms = int((time.time() - started) * 1000)
        return {
            "requestId": request_id,
            "status": "succeeded",
            "mode": mode,
            "mimeType": "image/png",
            "imageBase64": _encode_png(output_image),
            "seed": seed,
            "modelId": config.model_id,
            "modelRevision": config.model_revision,
            "dryRun": config.dry_run,
            "durationMs": duration_ms,
        }
    except RequestError as exc:
        return _failure("BAD_REQUEST", str(exc), started)
    except Exception as exc:
        return _failure("GENERATION_FAILED", _safe_error_message(exc), started)


def _require_config() -> EndpointConfig:
    if _CONFIG is None:
        init()
    if _CONFIG is None:
        raise RuntimeError("Endpoint configuration was not initialized")
    return _CONFIG


def _parse_payload(raw_data: Any) -> dict[str, Any]:
    if isinstance(raw_data, dict):
        return raw_data
    if isinstance(raw_data, bytes):
        raw_data = raw_data.decode("utf-8")
    if isinstance(raw_data, str):
        try:
            value = json.loads(raw_data)
        except json.JSONDecodeError as exc:
            raise RequestError("Request body must be valid JSON") from exc
        if isinstance(value, dict):
            return value
    raise RequestError("Request body must be a JSON object")


def _decode_image(value: Any, field_name: str) -> Image.Image:
    if not value or not isinstance(value, str):
        raise RequestError(f"{field_name} is required")
    if "," in value and value.strip().startswith("data:"):
        value = value.split(",", 1)[1]
    try:
        raw = base64.b64decode(value, validate=True)
        return Image.open(io.BytesIO(raw)).convert("RGBA")
    except Exception as exc:
        raise RequestError(f"{field_name} must be a valid base64 image") from exc


def _encode_png(image: Image.Image) -> str:
    output = io.BytesIO()
    image.save(output, format="PNG")
    return base64.b64encode(output.getvalue()).decode("ascii")


def _fit_image(image: Image.Image, max_width: int, max_height: int) -> Image.Image:
    output = image.copy()
    output.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)
    return output


def _prepare_reference_image(image: Image.Image, max_width: int, max_height: int) -> Image.Image:
    """Place the avatar on a light square canvas before FLUX Kontext sees it.

    The character renderer commonly emits RGBA/transparent PNGs. PIL's direct
    RGBA -> RGB conversion turns transparent pixels black, and Kontext can then
    learn the black rectangle as part of the reference. A warm off-white canvas
    keeps the reference readable and prevents all-black generations.
    """
    canvas = Image.new("RGB", (max_width, max_height), (255, 250, 245))
    avatar = image.convert("RGBA")
    avatar.thumbnail((int(max_width * 0.86), int(max_height * 0.86)), Image.Resampling.LANCZOS)
    left = (max_width - avatar.width) // 2
    top = (max_height - avatar.height) // 2
    canvas.paste(avatar.convert("RGB"), (left, top), avatar.getchannel("A"))
    return canvas


def _build_dry_run_image(reference_image: Image.Image, mode: str, request_id: str) -> Image.Image:
    canvas = Image.new("RGB", (768, 1024), (255, 250, 245))
    draw = ImageDraw.Draw(canvas)
    preview = _fit_image(reference_image, 600, 660)
    canvas.paste(preview, ((768 - preview.width) // 2, 120))
    font = ImageFont.load_default()
    lines = [
        "ONMU OOTD DRY RUN",
        f"mode: {mode}",
        f"request: {request_id or '-'}",
        "No FLUX model was loaded.",
    ]
    y = 820
    for line in lines:
        draw.text((64, y), line, fill=(70, 50, 45), font=font)
        y += 34
    return canvas


def _generate_image(
    *,
    config: EndpointConfig,
    prompt: str,
    reference_image: Image.Image,
    seed: int | None,
    steps: int,
    guidance_scale: float,
    max_sequence_length: int,
    use_negative_prompt: bool,
    use_dimensions: bool,
) -> Image.Image:
    pipe = _load_pipeline(config)
    kwargs: dict[str, Any] = {
        "prompt": prompt,
        "image": reference_image,
        "num_inference_steps": steps,
        "guidance_scale": guidance_scale,
    }
    if use_negative_prompt:
        kwargs["negative_prompt"] = NEGATIVE_PROMPT
    if use_dimensions:
        kwargs["height"] = reference_image.height
        kwargs["width"] = reference_image.width
    if max_sequence_length > 0:
        kwargs["max_sequence_length"] = max_sequence_length

    try:
        signature = inspect.signature(pipe.__call__)
        accepted = set(signature.parameters.keys())
        kwargs = {key: value for key, value in kwargs.items() if key in accepted}

        if seed is not None and "generator" in accepted:
            import torch

            device = "cuda" if config.device == "cuda" and torch.cuda.is_available() else "cpu"
            kwargs["generator"] = torch.Generator(device=device).manual_seed(seed)

        import torch

        with torch.inference_mode():
            result = pipe(**kwargs)
    except TypeError as exc:
        raise RuntimeError("FLUX Kontext pipeline call signature did not match the scaffold") from exc
    finally:
        gc.collect()
        try:
            import torch

            if torch.cuda.is_available():
                torch.cuda.empty_cache()
        except Exception:
            pass

    images = getattr(result, "images", None)
    if not images:
        raise RuntimeError("FLUX Kontext pipeline did not return images")
    output_image = images[0].convert("RGB")
    _raise_if_all_black(output_image)
    return output_image


def _raise_if_all_black(image: Image.Image) -> None:
    stat = ImageStat.Stat(image)
    extrema = image.getextrema()
    max_channel = max(channel_max for _channel_min, channel_max in extrema)
    mean = sum(stat.mean) / len(stat.mean)
    if max_channel <= 4 and mean <= 2:
        raise RuntimeError(
            "FLUX Kontext returned an all-black image. "
            "This usually means the reference preprocessing or generation settings are invalid."
        )


def _load_pipeline(config: EndpointConfig) -> Any:
    global _PIPELINE
    if _PIPELINE is not None:
        return _PIPELINE
    if not config.hf_token:
        raise RuntimeError("ONMU_HF_TOKEN is required when dry run is disabled")
    if not config.model_id or not config.model_revision:
        raise RuntimeError("ONMU_OOTD_MODEL_ID and ONMU_OOTD_MODEL_REVISION are required")

    import torch
    from diffusers import FluxKontextPipeline

    dtype = torch.float16 if config.device == "cuda" and torch.cuda.is_available() else torch.float32
    pipe = FluxKontextPipeline.from_pretrained(
        config.model_id,
        revision=config.model_revision,
        token=config.hf_token,
        torch_dtype=dtype,
    )
    if config.device == "cuda" and torch.cuda.is_available():
        if hasattr(pipe, "enable_attention_slicing"):
            pipe.enable_attention_slicing()
        if hasattr(pipe, "enable_vae_slicing"):
            pipe.enable_vae_slicing()
        if hasattr(pipe, "enable_vae_tiling"):
            pipe.enable_vae_tiling()
        if hasattr(pipe, "enable_model_cpu_offload"):
            pipe.enable_model_cpu_offload()
        elif hasattr(pipe, "enable_sequential_cpu_offload"):
            pipe.enable_sequential_cpu_offload()
        else:
            pipe.to("cuda")
    _PIPELINE = pipe
    return _PIPELINE


def _clean_optional_text(value: Any) -> str:
    if value is None:
        return ""
    if not isinstance(value, str):
        raise RequestError("outfitDescription must be a string")
    return " ".join(value.strip().split())


def _normalize_descriptor(value: Any) -> str | dict[str, Any]:
    if value is None:
        raise RequestError("outfitDescriptor is required for PHOTO_REFERENCE")
    if isinstance(value, str):
        descriptor = " ".join(value.strip().split())
        if not descriptor:
            raise RequestError("outfitDescriptor cannot be blank")
        return descriptor
    if isinstance(value, dict):
        if not value:
            raise RequestError("outfitDescriptor cannot be empty")
        return value
    raise RequestError("outfitDescriptor must be a string or JSON object")


def _parse_bool(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "y", "on"}


def _parse_int(value: str, minimum: int, maximum: int) -> int:
    try:
        parsed = int(value)
    except ValueError:
        return minimum
    return _clamp(parsed, minimum, maximum)


def _parse_optional_int(value: Any) -> int | None:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise RequestError("Numeric fields must be integers") from exc


def _parse_optional_bool(value: Any, *, default: bool) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized in {"1", "true", "yes", "y", "on"}:
            return True
        if normalized in {"0", "false", "no", "n", "off"}:
            return False
    if isinstance(value, (int, float)):
        return bool(value)
    raise RequestError("Boolean fields must be true or false")


def _clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, value))


def _safe_error_message(exc: Exception) -> str:
    message = str(exc) or exc.__class__.__name__
    token = os.environ.get("ONMU_HF_TOKEN")
    if token:
        message = message.replace(token, "<redacted>")
    return message[:500]


def _failure(code: str, message: str, started: float) -> dict[str, Any]:
    return {
        "status": "failed",
        "errorCode": code,
        "message": message,
        "durationMs": int((time.time() - started) * 1000),
    }
