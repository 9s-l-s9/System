FROM docker.io/library/python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HOME=/home/docling \
    OMP_NUM_THREADS=4 \
    TORCH_HOME=/home/docling/.cache/torch \
    TORCHINDUCTOR_CACHE_DIR=/home/docling/.cache/torchinductor

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      libglib2.0-0 \
      libgl1 \
      libgomp1 \
      libx11-6 \
      libxext6 \
      libxrender1 \
      libxcb1 \
      tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip \
    && python -m pip install --extra-index-url https://download.pytorch.org/whl/cpu docling

COPY scripts/docling_skill_parse.py /opt/document-intelligence/docling_skill_parse.py

WORKDIR /work
ENTRYPOINT ["python", "/opt/document-intelligence/docling_skill_parse.py"]
