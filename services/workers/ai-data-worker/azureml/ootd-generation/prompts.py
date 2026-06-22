"""Prompt builders for the Azure ML OOTD generation endpoint."""

from __future__ import annotations

from typing import Any


NEGATIVE_PROMPT = """
different person, changed face, changed eyes, changed hair, changed skin tone,
changed body proportions, photo, 3d render, side view, back view, cropped body,
missing limbs, extra limbs, blurry, messy silhouette, black image
""".strip()


MAX_PROMPT_WORDS = 72
MAX_SECTION_CHARS = 96
MAX_LIST_ITEMS = 4


def build_text_generation_prompt(outfit_description: str) -> str:
    outfit_brief = _clip_text(_normalize_text(outfit_description), 280)
    return _cap_prompt(
        (
            f"Change only the outfit of this exact ONMU pixel avatar to: {outfit_brief}. "
            "Keep the same face, hair, skin tone, body, pose, and pixel-art style."
        )
    )


def build_descriptor_generation_prompt(outfit_descriptor: Any) -> str:
    outfit_brief = build_outfit_brief(outfit_descriptor)
    return _cap_prompt(
        (
            f"Change only the outfit of this exact ONMU pixel avatar to: {outfit_brief}. "
            "Keep the same face, hair, skin tone, body, pose, and pixel-art style."
        )
    )


def build_outfit_brief(outfit_descriptor: Any) -> str:
    if isinstance(outfit_descriptor, str):
        return _clip_text(_normalize_text(outfit_descriptor), 320)
    if not isinstance(outfit_descriptor, dict):
        raise TypeError("outfit_descriptor must be a string or dict")

    sections: list[str] = []
    for key, label in [
        ("top", "Top"),
        ("bottom", "Bottom"),
        ("dress", "Dress"),
        ("outerwear", "Outer"),
        ("shoes", "Shoes"),
        ("bag", "Bag"),
        ("headwear", "Headwear"),
        ("eyewear", "Eyewear"),
        ("headphones", "Headphones"),
    ]:
        text = _fashion_item_to_sentence(label, outfit_descriptor.get(key))
        if text:
            sections.append(text)

    for key, label in [
        ("accessories", "Accessories"),
        ("jewelry", "Jewelry"),
        ("colors", "Palette"),
        ("patterns", "Patterns"),
        ("materials", "Materials"),
    ]:
        text = _list_sentence(label, outfit_descriptor.get(key))
        if text:
            sections.append(text)

    if not sections:
        raise ValueError("outfit_descriptor did not contain usable fashion fields")
    return _clip_text(" ".join(sections), 360)


def _append_text_field(sections: list[str], source: dict[str, Any], key: str, label: str) -> None:
    text = _value(source.get(key))
    if text:
        sections.append(f"{label}: {_clip_text(text, MAX_SECTION_CHARS)}.")


def _fashion_item_to_sentence(label: str, item: Any) -> str:
    if item is None:
        return ""
    if isinstance(item, str):
        text = _clip_text(_normalize_text(item), MAX_SECTION_CHARS)
        return f"{label}: {text}." if text else ""
    if isinstance(item, list):
        return _list_sentence(label, item)
    if not isinstance(item, dict):
        return f"{label}: {_clip_text(str(item), MAX_SECTION_CHARS)}."

    parts: list[str] = []
    for key in [
        "category",
        "subtype",
        "color",
        "material",
        "fit",
        "silhouette",
        "graphics",
        "construction_details",
        "decorative_details",
        "logo_or_accent",
        "shape",
        "wearing_position",
    ]:
        text = _value(item.get(key))
        if text:
            parts.append(_clip_text(text, 48))
    if not parts:
        return ""
    return f"{label}: " + ", ".join(parts[:MAX_LIST_ITEMS]) + "."


def _list_sentence(label: str, value: Any) -> str:
    text = _value(value)
    return f"{label}: {_clip_text(text, MAX_SECTION_CHARS)}." if text else ""


def _value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return _normalize_text(value)
    if isinstance(value, list):
        values = [_value(item) for item in value[:MAX_LIST_ITEMS]]
        return ", ".join(item for item in values if item)
    if isinstance(value, dict):
        values = [
            _value(item)
            for item in value.values()
            if _value(item)
        ]
        return ", ".join(values[:MAX_LIST_ITEMS])
    return str(value)


def _normalize_text(value: str) -> str:
    return " ".join(value.strip().split())


def _clip_text(value: str, max_chars: int) -> str:
    value = _normalize_text(value)
    if len(value) <= max_chars:
        return value
    return value[:max_chars].rsplit(" ", 1)[0].rstrip(" ,.;:")


def _cap_prompt(prompt: str) -> str:
    words = prompt.split()
    if len(words) <= MAX_PROMPT_WORDS:
        return prompt
    return " ".join(words[:MAX_PROMPT_WORDS]).rstrip(" ,.;:") + "."
