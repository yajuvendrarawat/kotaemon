# Lite version
FROM python:3.10-slim AS lite

# Common dependencies
#RUN apt-get update -qqy && \
#    apt-get install -y --no-install-recommends \
#      ssh \
#      git \
#      gcc \
#      g++ \
#      poppler-utils \
#      libpoppler-dev \
#      unzip \
#      curl \
#      cargo

# Set environment variables
#ENV PYTHONDONTWRITEBYTECODE=1
#ENV PYTHONUNBUFFERED=1
#ENV PYTHONIOENCODING=UTF-8

# Create working directory
#WORKDIR /app

# Download pdfjs
#COPY scripts/download_pdfjs.sh /app/scripts/download_pdfjs.sh
#RUN chmod +x /app/scripts/download_pdfjs.sh
#ENV PDFJS_PREBUILT_DIR="/app/libs/ktem/ktem/assets/prebuilt/pdfjs-dist"
#RUN bash scripts/download_pdfjs.sh $PDFJS_PREBUILT_DIR

# Copy contents
#COPY . /app

# Install pip packages
#RUN --mount=type=ssh  \
#    --mount=type=cache,target=/root/.cache/pip  \
#    pip install -e "libs/kotaemon" \
#    && pip install -e "libs/ktem" \
#    && pip install graphrag future \
#    && pip install "pdfservices-sdk@git+https://github.com/niallcm/pdfservices-python-sdk.git@bump-and-unfreeze-requirements"

# Clean up
#RUN apt-get autoremove \
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/* \
#    && rm -rf ~/.cache

#CMD ["python", "app.py"]

# Full version
FROM lite AS full

# Additional dependencies for full version
RUN apt-get update -qqy && \
    apt-get install -y --no-install-recommends \
      tesseract-ocr \
      tesseract-ocr-jpn \
      libsm6 \
      libxext6 \
      libreoffice \
      ffmpeg \
      libmagic-dev

# Install torch and torchvision for unstructured
RUN --mount=type=ssh  \
    --mount=type=cache,target=/root/.cache/pip  \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Copy contents
COPY . /app
COPY .env.example /app/.env

# Install additional pip packages
RUN --mount=type=ssh  \
    --mount=type=cache,target=/root/.cache/pip  \
    pip install -e "libs/kotaemon[adv]" \
    && pip install unstructured[all-docs]

# Clean up
RUN apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf ~/.cache

# Download nltk packages as required for unstructured
RUN python -c "from unstructured.nlp.tokenize import _download_nltk_packages_if_not_present; _download_nltk_packages_if_not_present()"

#CMD ["python", "app.py"]
EXPOSE 7860
ENTRYPOINT ["python", "app.py", "--server.port=7860", "--server.address=0.0.0.0"]
