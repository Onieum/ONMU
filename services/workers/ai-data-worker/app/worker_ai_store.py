from __future__ import annotations

import json
import os
import uuid
from dataclasses import dataclass
from typing import Any

try:
    from sqlalchemy import create_engine, text
    from sqlalchemy.engine import Engine
except Exception:  # pragma: no cover - optional runtime dependency guard
    create_engine = None
    text = None
    Engine = Any


@dataclass
class WorkerAiStore:
    database_url: str | None
    engine: Engine | None = None

    @classmethod
    def from_env(cls) -> "WorkerAiStore":
        database_url = (
            os.environ.get("ONMU_WORKER_AI_DATABASE_URL")
            or os.environ.get("DATABASE_URL")
            or ""
        ).strip()
        if not database_url or create_engine is None:
            return cls(None, None)
        try:
            return cls(database_url, create_engine(database_url, pool_pre_ping=True))
        except Exception:
            return cls(None, None)

    @property
    def is_configured(self) -> bool:
        return self.engine is not None

    def start_job(
        self,
        *,
        outbox_event_id: str,
        job_type: str,
        input_metadata: dict[str, Any],
    ) -> str | None:
        if self.engine is None or text is None:
            return None
        job_id = str(uuid.uuid4())
        try:
            with self.engine.begin() as connection:
                connection.execute(
                    text(
                        """
                        insert into worker_ai.ai_job_runs
                          (id, outbox_event_id, job_type, status, input_metadata, result_metadata)
                        values
                          (:id, :outbox_event_id, :job_type, 'running',
                           cast(:input_metadata as jsonb), '{}'::jsonb)
                        """
                    ),
                    {
                        "id": job_id,
                        "outbox_event_id": _uuid_or_none(outbox_event_id),
                        "job_type": job_type,
                        "input_metadata": _json(input_metadata),
                    },
                )
            return job_id
        except Exception:
            return None

    def record_prompt(
        self,
        *,
        ai_job_run_id: str | None,
        prompt_kind: str,
        model_name: str | None,
        status: str,
        metadata: dict[str, Any],
    ) -> str | None:
        if self.engine is None or text is None:
            return None
        prompt_id = str(uuid.uuid4())
        try:
            with self.engine.begin() as connection:
                connection.execute(
                    text(
                        """
                        insert into worker_ai.prompt_runs
                          (id, ai_job_run_id, prompt_kind, model_name, status, metadata)
                        values
                          (:id, :ai_job_run_id, :prompt_kind, :model_name, :status,
                           cast(:metadata as jsonb))
                        """
                    ),
                    {
                        "id": prompt_id,
                        "ai_job_run_id": _uuid_or_none(ai_job_run_id),
                        "prompt_kind": prompt_kind,
                        "model_name": model_name,
                        "status": status,
                        "metadata": _json(metadata),
                    },
                )
            return prompt_id
        except Exception:
            return None

    def finish_job(
        self,
        *,
        ai_job_run_id: str | None,
        status: str,
        result_metadata: dict[str, Any],
    ) -> None:
        if self.engine is None or text is None or not ai_job_run_id:
            return
        try:
            with self.engine.begin() as connection:
                connection.execute(
                    text(
                        """
                        update worker_ai.ai_job_runs
                        set status = :status,
                            result_metadata = cast(:result_metadata as jsonb),
                            updated_at = now()
                        where id = :id
                        """
                    ),
                    {
                        "id": ai_job_run_id,
                        "status": status,
                        "result_metadata": _json(result_metadata),
                    },
                )
        except Exception:
            return


def _uuid_or_none(value: str | None) -> str | None:
    if not value:
        return None
    try:
        return str(uuid.UUID(str(value)))
    except ValueError:
        return None


def _json(value: dict[str, Any]) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
