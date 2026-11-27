"""Application settings, read from environment variables only."""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # No env_file: inside the container, Compose injects only the variables this service needs.
    model_config = SettingsConfigDict(extra="ignore")

    # An unexpected value stops the application at startup (fail closed).
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"


@lru_cache
def get_settings() -> Settings:
    """Read and validate the settings once, then reuse them."""
    return Settings()
