# ONMU OOTD Azure ML endpoint scaffold

This directory contains the Azure ML managed online endpoint scaffold for
the ONMU OOTD avatar generation MVP.

The endpoint is intentionally isolated from the FastAPI worker runtime. The
worker should call this endpoint after reading an OOTD job and preparing a
character reference image plus either an outfit reference image or an outfit
text prompt.

## Cost policy

- Use one deployment only: `blue`.
- Start with `Standard_NC4as_T4_v3` because it is the lowest-cost T4 GPU option
  visible in Korea Central and is enough for an MVP smoke test path.
- Keep `instance_count = 1`; do not create a compute instance or compute
  cluster for this flow.
- Deploy with `ONMU_OOTD_DRY_RUN=true` first. This verifies endpoint wiring
  without downloading FLUX.1-Kontext-dev or occupying GPU memory.
- Dry-run deployment uses `Dockerfile.dryrun`, a minimal Azure ML inference
  image with only Pillow/Numpy. This avoids failing or paying for the full
  Torch/Diffusers/FLUX image build while the endpoint wiring is being tested.
- Flip `ONMU_OOTD_DRY_RUN=false` only when you are ready to pay for an actual
  model load and generation test.
- Generate one image per request in MVP. Multiple candidates multiply latency
  and GPU time.
- Cap inference steps via `ONMU_OOTD_MAX_STEPS` and request validation. The
  default is 24 steps.

Managed online endpoints do not behave like scale-to-zero serverless functions.
While an endpoint deployment is live, the GPU instance can incur cost. Delete
or stop the deployment after MVP smoke testing if the team is not actively
using it.

## Key Vault inputs

These secrets must exist before deployment:

```text
staging-hf-token
staging-ootd-model-id
staging-ootd-model-revision
```

These secrets are written after a successful Azure ML endpoint deployment:

```text
staging-azureml-endpoint-url
staging-azureml-endpoint-key
```

Vision settings are separate and are not required for this endpoint scaffold:

```text
staging-vision-api-key
staging-vision-api-version
staging-vision-deployment-name
staging-vision-endpoint-url
```

## Deploy

From the repository root:

```powershell
.\scripts\azureml\deploy-ootd-generation.ps1 -Apply -WriteEndpointSecrets
```

Dry-run deployment is the default. It lets the team verify Azure ML endpoint
creation and Spring/worker integration without running FLUX.

To run the actual model:

```powershell
.\scripts\azureml\deploy-ootd-generation.ps1 -Apply -WriteEndpointSecrets -DryRun false
```

## Request contract

Text mode:

```json
{
  "requestId": "job_001",
  "mode": "TEXT_PROMPT",
  "characterImageBase64": "<png base64>",
  "outfitDescription": "white short sleeve blouse, navy pleated skirt, white socks, white sneakers",
  "seed": 1234
}
```

Photo mode after Vision AI extraction:

```json
{
  "requestId": "job_002",
  "mode": "PHOTO_REFERENCE",
  "characterImageBase64": "<png base64>",
  "outfitDescriptor": {
    "top": "white sailor-collar short sleeve blouse with navy ribbon detail",
    "bottom": "navy pleated mini skirt",
    "shoes": "white low-top sneakers with blue accents",
    "accessories": ["black over-ear headphones"]
  },
  "seed": 1234
}
```

The endpoint rejects hybrid input. The product flow supports either outfit
photo input or outfit text input, not both at once.

## Why raw OOTD photos are not sent to this endpoint

The final ONMU flow uses Vision AI before Azure ML:

```text
OOTD photo
-> Vision AI outfit descriptor
-> prompt builder
-> Azure ML OOTD endpoint
```

This endpoint receives the fixed character image plus the Vision AI descriptor.
It does not receive the raw OOTD photo. This keeps the generation prompt more
controlled and prevents the model from copying the real person's face or body
from the outfit photo.
