from __future__ import annotations


PLACE_REASON_EVENT_TYPES = {"place_candidate.created", "ai.summary.requested"}


def handle_place_reason_task(event_id: str, event_type: str, payload: dict) -> dict:
    if event_type not in PLACE_REASON_EVENT_TYPES:
        return {
            "ok": True,
            "eventId": event_id,
            "eventType": event_type,
            "status": "ignored",
        }

    reason_count = _safe_int(payload.get("reasonCount"))
    has_coordinate = bool(payload.get("hasCoordinate"))
    return {
        "ok": True,
        "eventId": event_id,
        "eventType": event_type,
        "status": "accepted",
        "promptKind": "place_reason",
        "result": {
            "reasonSource": "rule_based_worker",
            "reasonCount": reason_count,
            "hasCoordinate": has_coordinate,
            "aiStatus": "not_requested",
        },
    }


def _safe_int(value: object) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return max(value, 0)
    if isinstance(value, str) and value.isdigit():
        return int(value)
    return 0
