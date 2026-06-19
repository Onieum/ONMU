"""Prompt builders for the Azure ML OOTD generation endpoint."""

from __future__ import annotations

from typing import Any


NEGATIVE_PROMPT = """
different person, changed face, changed facial structure, changed eye shape,
changed eye color, changed hairstyle, changed hair color, changed skin tone,
changed body proportions, realistic photo, semi-realistic illustration,
anime illustration, 3d render, copied real human face, copied real human body,
background copied from outfit photo, side view, back view, cropped body,
missing legs, missing arms, extra limbs, distorted hands, blurry pixel art,
low readability, messy silhouette
""".strip()


CHARACTER_LOCK = """
STRICT CHARACTER LOCK:
- Preserve the exact same face shape.
- Preserve the exact same eye shape, eye size, and eye color.
- Preserve the exact same eyebrows and facial features.
- Preserve the exact same skin tone.
- Preserve the exact same hairstyle, hair length, hair shape, and hair color.
- Preserve the exact same head size and body proportions.
- Preserve the exact same front-facing standing sprite pose.
- Preserve the ONMU cute Korean mobile app pixel-art style.
- Do not redesign the character.
- Do not generate a new character.
- Do not alter the character silhouette except where clothing naturally affects it.
""".strip()


ALLOWED_CHANGES = """
Allowed modifications:
- clothing
- shoes
- socks
- bags
- hats
- glasses
- headphones
- scarves
- belts
- jewelry
- wearable accessories

If an outfit exposes arms, legs, neck, or feet, keep the same skin tone as the
reference character. If the outfit includes hats, glasses, headphones, ribbons,
bags, scarves, belts, or jewelry, add them as wearable equipment without
changing the original face, eyes, or hair identity.
""".strip()


PIXEL_REQUIREMENTS = """
Pixel-art output requirements:
- front-facing full-body avatar
- game character sprite
- clean readable pixel art
- transparent or clean light background
- consistent sprite scale
- clothing designed as wearable avatar equipment
- one final image only
""".strip()


def build_text_generation_prompt(outfit_description: str) -> str:
    outfit_brief = _normalize_text(outfit_description)
    return _join_prompt(
        [
            "Character-preserving outfit edit.",
            "Use the uploaded pixel avatar as the base character.",
            CHARACTER_LOCK,
            ALLOWED_CHANGES,
            "Apply the following user-provided outfit description exactly:",
            outfit_brief,
            _detail_preservation_rules(),
            PIXEL_REQUIREMENTS,
            "Outfit swap only. Character identity must remain unchanged.",
        ]
    )


def build_descriptor_generation_prompt(outfit_descriptor: Any) -> str:
    outfit_brief = build_outfit_brief(outfit_descriptor)
    return _join_prompt(
        [
            "Character-preserving outfit edit.",
            "Use the uploaded pixel avatar as the base character.",
            CHARACTER_LOCK,
            ALLOWED_CHANGES,
            "Apply the following Vision AI fashion brief exactly:",
            outfit_brief,
            _detail_preservation_rules(),
            PIXEL_REQUIREMENTS,
            "Outfit swap only. Character identity must remain unchanged.",
        ]
    )


def build_outfit_brief(outfit_descriptor: Any) -> str:
    if isinstance(outfit_descriptor, str):
        return _normalize_text(outfit_descriptor)
    if not isinstance(outfit_descriptor, dict):
        raise TypeError("outfit_descriptor must be a string or dict")

    sections: list[str] = []
    for key, label in [
        ("style_name", "Style name"),
        ("overall_aesthetic", "Overall aesthetic"),
    ]:
        text = _value(outfit_descriptor.get(key))
        if text:
            sections.append(f"{label}: {text}.")

    for key, label in [
        ("top", "Top"),
        ("bottom", "Bottom"),
        ("dress", "Dress"),
        ("outerwear", "Outerwear"),
        ("shoes", "Shoes"),
        ("socks", "Socks"),
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
        ("other_accessories", "Other accessories"),
        ("materials", "Visible materials"),
        ("colors", "Color palette"),
        ("patterns", "Patterns"),
    ]:
        text = _list_sentence(label, outfit_descriptor.get(key))
        if text:
            sections.append(text)

    for key, label in [
        ("silhouette", "Overall silhouette"),
        ("styling_notes", "Styling notes"),
    ]:
        text = _value(outfit_descriptor.get(key))
        if text:
            sections.append(f"{label}: {text}.")

    uncertainty = _list_sentence("Uncertain details to keep subtle", outfit_descriptor.get("uncertainty"))
    if uncertainty:
        sections.append(uncertainty)

    if not sections:
        raise ValueError("outfit_descriptor did not contain usable fashion fields")
    return "\n".join(f"- {section}" for section in sections)


def _fashion_item_to_sentence(label: str, item: Any) -> str:
    if item is None:
        return ""
    if isinstance(item, str):
        text = _normalize_text(item)
        return f"{label}: {text}." if text else ""
    if isinstance(item, list):
        return _list_sentence(label, item)
    if not isinstance(item, dict):
        return f"{label}: {item}."

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
        "sole",
        "logo_or_accent",
        "shape",
        "wearing_position",
    ]:
        text = _value(item.get(key))
        if text:
            parts.append(f"{key.replace('_', ' ')}: {text}")
    if not parts:
        return ""
    return f"{label}: " + "; ".join(parts) + "."


def _detail_preservation_rules() -> str:
    return """
Preserve important garment details:
- logos
- prints
- ribbons
- embroidery
- lettering
- patches
- lace
- buttons
- zippers
- pockets
- collars
- cuffs
- seams
- pleats
- gathers
- ruffles
- trims
- hems
- fabric folds and wrinkles
- material texture
- accessory placement
""".strip()


def _list_sentence(label: str, value: Any) -> str:
    text = _value(value)
    return f"{label}: {text}." if text else ""


def _value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return _normalize_text(value)
    if isinstance(value, list):
        values = [_value(item) for item in value]
        return ", ".join(item for item in values if item)
    if isinstance(value, dict):
        values = [
            f"{key.replace('_', ' ')}: {_value(item)}"
            for key, item in value.items()
            if _value(item)
        ]
        return "; ".join(values)
    return str(value)


def _normalize_text(value: str) -> str:
    return " ".join(value.strip().split())


def _join_prompt(parts: list[str]) -> str:
    return "\n\n".join(part.strip() for part in parts if part and part.strip())

