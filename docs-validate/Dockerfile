FROM python:3.12-slim

WORKDIR /workspace

RUN pip install --no-cache-dir "mkdocs-material>=9.0.0" mike

CMD ["mkdocs", "build", "--strict"]
