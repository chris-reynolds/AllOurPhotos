# Build context must be the allourphotos/ project root:
#   docker build -f pyserver/Dockerfile -t aop:latest .

FROM python:3.12-slim

WORKDIR /app

COPY pyserver/requirements.txt .
RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config \
        default-libmysqlclient-dev \
        build-essential \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get purge -y --auto-remove build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY pyserver/src/ ./src/

# Flutter web build output — run 'flutter build web' in all_our_photos_app/ first
COPY all_our_photos_app/build/web/ ./frontend/

EXPOSE 8000

CMD ["uvicorn", "src.aopservermain:app", "--host", "0.0.0.0", "--port", "8000"]
