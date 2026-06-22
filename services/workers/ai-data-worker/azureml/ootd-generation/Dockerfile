FROM mcr.microsoft.com/azureml/openmpi4.1.0-cuda11.8-cudnn8-ubuntu22.04

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

RUN python -m pip install --upgrade pip setuptools wheel

RUN python -m pip install \
    azureml-inference-server-http==1.3.0 \
    pillow==10.4.0 \
    numpy==1.26.4

RUN python -m pip install \
    --index-url https://download.pytorch.org/whl/cu118 \
    torch==2.7.1 \
    torchvision==0.22.1

RUN python -m pip install \
    "diffusers @ git+https://github.com/huggingface/diffusers.git" \
    "transformers>=4.53.0" \
    "accelerate>=1.8.0" \
    "safetensors>=0.5.3" \
    "huggingface_hub>=0.33.0" \
    "sentencepiece>=0.2.0" \
    "protobuf>=5.27.0"
