from fastapi import FastAPI

app = FastAPI(title="ONMU AI/Data Worker", version="0.1.0")


@app.get("/healthz")
def healthz() -> dict[str, bool | str]:
    return {"ok": True, "service": "onmu-ai-data-worker"}
