"""Prompt templates for the OOTD Vision AI stage."""

VISION_OUTFIT_DESCRIPTOR_SYSTEM_RULES = """
You must describe clothing and wearable items only.
Never identify or describe the person.
Never infer protected or sensitive attributes.
Return JSON only.
""".strip()


VISION_OUTFIT_DESCRIPTOR_PROMPT = """
You are a professional fashion analyst and clothing design extractor for a
pixel avatar generation pipeline.

Analyze the uploaded outfit photo and describe ONLY visible wearable fashion
items.

Ignore and never describe:
- face
- hairstyle
- hair color
- eyes
- body shape
- gender
- age
- attractiveness
- pose
- background
- location

Focus exclusively on:
- clothing
- footwear
- socks
- bags
- hats
- eyewear
- headphones
- jewelry
- scarves
- belts
- wearable accessories
- colors
- materials
- patterns
- construction details
- styling details

For every visible fashion item, extract:
1. item category
2. garment subtype
3. primary and secondary colors
4. material or material-like visual texture
5. silhouette and fit
6. graphic details such as logos, prints, lettering, patches, embroidery,
   ribbons, lace, trims, buttons, zippers, pockets, seams, cuffs, collars,
   pleats, frills, distressed areas, washed texture, or stitching
7. accessory shape, color, material, and wearing position
8. how the items combine into a coherent outfit

Be extremely detailed. Do not summarize. Do not omit small decorative elements.
If a detail is visible but uncertain, include it in "uncertainty" instead of
guessing. If an item is not visible, use null.

Return strict JSON only. Do not wrap the JSON in markdown.

Schema:
{
  "style_name": "",
  "overall_aesthetic": "",
  "top": {
    "category": "",
    "subtype": "",
    "color": "",
    "material": "",
    "fit": "",
    "silhouette": "",
    "graphics": "",
    "construction_details": [],
    "decorative_details": []
  },
  "bottom": {
    "category": "",
    "subtype": "",
    "color": "",
    "material": "",
    "fit": "",
    "silhouette": "",
    "graphics": "",
    "construction_details": [],
    "decorative_details": []
  },
  "dress": null,
  "outerwear": null,
  "shoes": {
    "category": "",
    "subtype": "",
    "color": "",
    "material": "",
    "sole": "",
    "logo_or_accent": "",
    "shape": ""
  },
  "socks": null,
  "bag": null,
  "headwear": null,
  "eyewear": null,
  "headphones": null,
  "jewelry": [],
  "other_accessories": [],
  "materials": [],
  "colors": [],
  "patterns": [],
  "silhouette": "",
  "styling_notes": "",
  "uncertainty": []
}
""".strip()

