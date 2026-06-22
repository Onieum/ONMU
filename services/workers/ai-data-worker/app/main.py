import logging

from fastapi import FastAPI
from pydantic import BaseModel, Field

from app.ootd.azureml_client import AzureMlOotdClient
from app.ootd.character_renderer import CharacterReferenceRenderer
from app.ootd.gpt_image_client import GptImageOotdClient
from app.ootd.vision_client import AzureOpenAiVisionClient
from app.ootd.worker import handle_ootd_avatar_generation, resolve_image_generation_provider
from app.place_reason_client import AzureOpenAiPlaceReasonClient
from app.place_reason import handle_place_reason_task
from app.worker_ai_store import WorkerAiStore

app = FastAPI(title="ONMU AI/Data Worker", version="0.1.0")
logger = logging.getLogger(__name__)


@app.get("/healthz")
def healthz() -> dict[str, bool | str]:
    return {"ok": True, "service": "onmu-ai-data-worker"}


@app.get("/readyz")
def readyz() -> dict[str, bool | str]:
    azureml_configured = AzureMlOotdClient.from_env(required=False).is_configured
    gpt_image_configured = GptImageOotdClient.from_env(required=False).is_configured
    vision_configured = AzureOpenAiVisionClient.from_env(required=False).is_configured
    place_reason_configured = AzureOpenAiPlaceReasonClient.from_env(required=False).is_configured
    worker_ai_store_configured = WorkerAiStore.from_env().is_configured
    character_renderer_ready = CharacterReferenceRenderer().is_ready
    image_generation_provider = resolve_image_generation_provider(
        azureml_configured=azureml_configured,
        gpt_image_configured=gpt_image_configured,
    )
    return {
        "ok": True,
        "service": "onmu-ai-data-worker",
        "mode": image_generation_provider.lower(),
        "imageGenerationProvider": image_generation_provider,
        "azureMlConfigured": azureml_configured,
        "gptImageConfigured": gpt_image_configured,
        "visionConfigured": vision_configured,
        "placeReasonConfigured": place_reason_configured,
        "workerAiStoreConfigured": worker_ai_store_configured,
        "characterRendererReady": character_renderer_ready,
    }


class OutboxTaskRequest(BaseModel):
    eventId: str
    eventType: str
    payload: dict = Field(default_factory=dict)


@app.post("/tasks/ootd")
async def handle_ootd_task(request: OutboxTaskRequest) -> dict:
    logger.info(
        "ootd task received event_id=%s event_type=%s",
        request.eventId,
        request.eventType,
    )
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


@app.post("/tasks/place-reason")
async def handle_place_reason_outbox_task(request: OutboxTaskRequest) -> dict:
    logger.info(
        "place reason task received event_id=%s event_type=%s",
        request.eventId,
        request.eventType,
    )
    return await handle_place_reason_task(
        event_id=request.eventId,
        event_type=request.eventType,
        payload=request.payload,
    )
