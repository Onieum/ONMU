from app.ootd.worker import (
    PROVIDER_FLUX_AZUREML,
    PROVIDER_GPT_IMAGE_AZURE_OPENAI,
    PROVIDER_MOCK,
    resolve_image_generation_provider,
)


def test_resolve_provider_prefers_explicit_gpt_image(monkeypatch):
    monkeypatch.setenv("ONMU_IMAGE_GENERATION_PROVIDER", "GPT_IMAGE_AZURE_OPENAI")

    assert (
        resolve_image_generation_provider(
            azureml_configured=True,
            gpt_image_configured=False,
        )
        == PROVIDER_GPT_IMAGE_AZURE_OPENAI
    )


def test_resolve_provider_prefers_configured_gpt_image_without_explicit_env(monkeypatch):
    monkeypatch.delenv("ONMU_IMAGE_GENERATION_PROVIDER", raising=False)

    assert (
        resolve_image_generation_provider(
            azureml_configured=True,
            gpt_image_configured=True,
        )
        == PROVIDER_GPT_IMAGE_AZURE_OPENAI
    )


def test_resolve_provider_falls_back_to_flux_when_only_azureml_configured(monkeypatch):
    monkeypatch.delenv("ONMU_IMAGE_GENERATION_PROVIDER", raising=False)

    assert (
        resolve_image_generation_provider(
            azureml_configured=True,
            gpt_image_configured=False,
        )
        == PROVIDER_FLUX_AZUREML
    )


def test_resolve_provider_uses_mock_when_no_provider_is_configured(monkeypatch):
    monkeypatch.delenv("ONMU_IMAGE_GENERATION_PROVIDER", raising=False)

    assert (
        resolve_image_generation_provider(
            azureml_configured=False,
            gpt_image_configured=False,
        )
        == PROVIDER_MOCK
    )
