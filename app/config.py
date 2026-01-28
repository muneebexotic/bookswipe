from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Supabase
    supabase_url: str = ""
    supabase_service_key: str = ""  # Service role key for backend writes
    
    # LLM Provider: "ollama" (local free) or "groq" (cloud free tier)
    llm_provider: str = "groq"
    
    # Groq settings (free tier: https://console.groq.com)
    groq_api_key: str = ""
    groq_model: str = "llama-3.1-8b-instant"
    
    # Ollama settings (local, completely free)
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "llama3.2"

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()


# Supabase client singleton
_supabase_client = None

def get_supabase():
    """Get Supabase client instance."""
    global _supabase_client
    if _supabase_client is None:
        from supabase import create_client
        settings = get_settings()
        _supabase_client = create_client(settings.supabase_url, settings.supabase_service_key)
    return _supabase_client
