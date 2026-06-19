from fastapi import FastAPI
from pydantic import BaseModel, Field

from app.ootd.azureml_client import AzureMlOotdClient
from app.ootd.worker import handle_ootd_avatar_generation

app = FastAPI(title="ONMU AI/Data Worker", version="0.1.0")


@app.get("/healthz")
def healthz() -> dict[str, bool | str]:
    return {"ok": True, "service": "onmu-ai-data-worker"}


@app.get("/readyz")
def readyz() -> dict[str, bool | str]:
    return {
        "ok": True,
        "service": "onmu-ai-data-worker",
        "mode": "azureml" if AzureMlOotdClient.from_env(required=False).is_configured else "mock",
    }


class OutboxTaskRequest(BaseModel):
    eventId: str
    eventType: str
    payload: dict = Field(default_factory=dict)


@app.post("/tasks/ootd")
async def handle_ootd_task(request: OutboxTaskRequest) -> dict:
    if request.eventType == "ootd.avatar_generation.requested":
        return await handle_ootd_avatar_generation(
            event_id=request.eventId,
            event_type=request.eventType,
            payload=request.payload,
        )

    return {
        "ok": True,
        "eventId": request.eventId,
        "eventType": request.eventType,
        "status": "ignored",
    }
