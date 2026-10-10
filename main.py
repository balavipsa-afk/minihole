"""Application entry point; network binds come from the environment."""
from minihole.api import app
from minihole.config import get_settings

if __name__ == "__main__":
    import uvicorn
    settings = get_settings()
    uvicorn.run(app, host=settings.api_host, port=settings.api_port)
