"""Character reference image rendering for OOTD generation.

The mobile app stores and renders ONMU characters as layered pixel assets.
The OOTD AI endpoint, however, needs a single reference PNG. This module
recreates the Flutter layer order on the worker side and intentionally omits
the clothing layer so the model can edit only the outfit.
"""

from __future__ import annotations

import base64
import io
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image


HAIR_COLORS = [
    "#1E1E1E",
    "#7A5230",
    "#E7D08B",
    "#F5F5F5",
    "#E6A3C6",
    "#C94B4B",
    "#7FA9E6",
    "#7ED8B6",
    "#9A79D8",
    "#9AD64D",
]

EYE_COLOR_NAMES = [
    "black",
    "brown",
    "blue",
    "pink",
    "green",
    "gray",
    "purple",
    "gold",
]


@dataclass(frozen=True)
class CharacterReferenceResult:
    image_base64: str
    mime_type: str
    metadata: dict[str, Any]


@dataclass(frozen=True)
class CharacterParts:
    gender: str
    skin_tone_index: int
    hair_style_index: int
    hair_color_index: int
    eye_shape_index: int
    eye_color_index: int

    @staticmethod
    def from_profile(profile: dict[str, Any]) -> "CharacterParts":
        return CharacterParts(
            gender=_gender(_profile_value(profile, "gender")),
            skin_tone_index=_skin_tone_index(_profile_value(profile, "skinTone", "skinToneIndex")),
            hair_style_index=_hair_style_index(_profile_value(profile, "hairStyle", "hairStyleIndex")),
            hair_color_index=_hair_color_index(_profile_value(profile, "hairColor", "hairColorIndex")),
            eye_shape_index=_eye_shape_index(_profile_value(profile, "eyeStyle", "eyeShapeIndex")),
            eye_color_index=_eye_color_index(_profile_value(profile, "eyeColor", "eyeColorIndex")),
        )


class CharacterReferenceRenderer:
    def __init__(self, asset_root: Path | None = None):
        self.asset_root = asset_root or _default_asset_root()

    @property
    def is_ready(self) -> bool:
        return (self.asset_root / "mouth.png").exists()

    def render(self, profile: dict[str, Any] | None) -> CharacterReferenceResult:
        parts = CharacterParts.from_profile(profile or {})
        paths = self._asset_paths(parts)
        body = self._open(paths["body"])
        canvas = Image.new("RGBA", body.size, (0, 0, 0, 0))

        self._composite(canvas, body)
        self._composite(canvas, self._open(paths["eyes"]))
        self._composite(canvas, self._tint(self._open(paths["hair_silhouette"]), HAIR_COLORS[parts.hair_color_index]))
        self._composite(canvas, self._open(paths["hair_outline"]))

        mouth = self._open(paths["mouth"])
        # Flutter renders the female mouth with:
        # Offset(-size * (16 / 1920), -size * (16 / 1920)).
        # The worker composites the original 1920px character asset canvas, so
        # the equivalent source-space offset is -16px on both axes.
        mouth_offset = (-16, -16) if parts.gender == "female" else (0, 0)
        self._composite(canvas, mouth, mouth_offset)

        buffer = io.BytesIO()
        canvas.save(buffer, format="PNG")
        return CharacterReferenceResult(
            image_base64=base64.b64encode(buffer.getvalue()).decode("ascii"),
            mime_type="image/png",
            metadata={
                "assetRoot": str(self.asset_root),
                "gender": parts.gender,
                "skinToneIndex": parts.skin_tone_index,
                "hairStyleIndex": parts.hair_style_index,
                "hairColorIndex": parts.hair_color_index,
                "eyeShapeIndex": parts.eye_shape_index,
                "eyeColorIndex": parts.eye_color_index,
                "clothingLayerIncluded": False,
            },
        )

    def _asset_paths(self, parts: CharacterParts) -> dict[str, Path]:
        gender_path = "female" if parts.gender == "female" else "male"
        body_prefix = "girl_skin_base_0" if parts.gender == "female" else "boy_skin_base_0"
        eye_prefix = "girl_eye_0" if parts.gender == "female" else "boy_eye_0"
        hair_prefix = "hair_girl_0" if parts.gender == "female" else "hair_boy_0"

        eye_path: Path
        if parts.gender == "female" and parts.eye_shape_index == 2:
            eye_path = self.asset_root / "female" / "eyes" / "girl_eye_03.PNG"
        else:
            eye_path = (
                self.asset_root
                / gender_path
                / "eyes"
                / f"{eye_prefix}{parts.eye_shape_index + 1}_{EYE_COLOR_NAMES[parts.eye_color_index]}.PNG"
            )

        return {
            "body": self.asset_root / gender_path / "body" / f"{body_prefix}{parts.skin_tone_index + 1}.PNG",
            "eyes": eye_path,
            "hair_silhouette": self.asset_root
            / gender_path
            / "hair"
            / f"{hair_prefix}{parts.hair_style_index + 1}_silhouette.PNG",
            "hair_outline": self.asset_root / gender_path / "hair" / f"{hair_prefix}{parts.hair_style_index + 1}.PNG",
            "mouth": self.asset_root / "mouth.png",
        }

    def _open(self, path: Path) -> Image.Image:
        if not path.exists():
            raise FileNotFoundError(f"Character asset is missing: {path}")
        return Image.open(path).convert("RGBA")

    @staticmethod
    def _composite(canvas: Image.Image, layer: Image.Image, offset: tuple[int, int] = (0, 0)) -> None:
        if layer.size != canvas.size:
            fitted = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
            fitted.alpha_composite(layer, offset)
            layer = fitted
            offset = (0, 0)
        canvas.alpha_composite(layer, offset)

    @staticmethod
    def _tint(layer: Image.Image, color_hex: str) -> Image.Image:
        color = _hex_to_rgba(color_hex)
        tinted = Image.new("RGBA", layer.size, color)
        tinted.putalpha(layer.getchannel("A"))
        return tinted


def render_character_reference(profile: dict[str, Any] | None) -> CharacterReferenceResult:
    return CharacterReferenceRenderer().render(profile)


def _default_asset_root() -> Path:
    configured = os.environ.get("ONMU_CHARACTER_ASSET_ROOT", "").strip()
    if configured:
        return Path(configured)
    return Path(__file__).resolve().parents[2] / "assets" / "character"


def _hex_to_rgba(value: str) -> tuple[int, int, int, int]:
    text = value.strip().lstrip("#")
    return (int(text[0:2], 16), int(text[2:4], 16), int(text[4:6], 16), 255)


def _indexed_value(value: Any, prefix: str, *, fallback: int = 0, minimum: int = 0, maximum: int = 99) -> int:
    if isinstance(value, int):
        return _clamp(value, minimum, maximum)
    text = str(value or "").strip()
    match = re.match(rf"^{re.escape(prefix)}_(-?\d+)$", text)
    if match:
        return _clamp(int(match.group(1)), minimum, maximum)
    return _clamp(fallback, minimum, maximum)


def _clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, value))


def _gender(value: Any) -> str:
    text = str(value or "").strip().lower()
    return "male" if text == "male" else "female"


def _profile_value(profile: dict[str, Any], *keys: str) -> Any:
    for key in keys:
        if key in profile and profile[key] is not None:
            return profile[key]
    return None


def _hair_color_index(value: Any) -> int:
    return _indexed_value(value, "hair_color", fallback=0, minimum=0, maximum=len(HAIR_COLORS) - 1)


def _eye_color_index(value: Any) -> int:
    return _indexed_value(value, "eye_color", fallback=0, minimum=0, maximum=len(EYE_COLOR_NAMES) - 1)


def _skin_tone_index(value: Any) -> int:
    return _indexed_value(value, "skin", fallback=0, minimum=0, maximum=4)


def _hair_style_index(value: Any) -> int:
    return _indexed_value(value, "hair_style", fallback=0, minimum=0, maximum=7)


def _eye_shape_index(value: Any) -> int:
    return _indexed_value(value, "eye_style", fallback=0, minimum=0, maximum=4)
