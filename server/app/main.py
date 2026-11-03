import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# The Flutter web client is served from a different origin, so browsers need CORS.
# Comma-separated list, e.g. "http://client.home.hub,http://localhost:8080".
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("CORS_ALLOW_ORIGINS", "*").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root():
    return {"Hello": "Hello from home hub"}


@app.get("/health")
def health():
    """Liveness probe: the process is up and serving requests. Used by the container healthcheck."""
    return {"status": "ok"}
