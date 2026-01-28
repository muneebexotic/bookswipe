import json
import re
from typing import Optional
from pydantic import BaseModel, Field

from app.config import get_settings, get_supabase
from app.services.open_library import fetch_book_from_open_library


class EnrichedMetadata(BaseModel):
    """Schema for AI-extracted book metadata"""
    spice_rating: int = Field(
        description="Spice/heat level 1-5. 1=Fade to black/clean, 5=Explicit"
    )
    tropes: list[str] = Field(
        description="Top 5 book tropes"
    )
    moods: list[str] = Field(
        description="3-5 mood descriptors"
    )
    trigger_warnings: list[str] = Field(
        description="Potential content warnings. Empty list if none."
    )
    generated_hook: str = Field(
        description="Punchy 1-sentence hook under 140 characters"
    )


ENRICHMENT_PROMPT = """You are a book metadata analyst. Analyze this book and extract metadata.

Book Title: {title}
Author: {author}
Description: {description}

Extract:
1. spice_rating (1-5): 1=Clean, 2=Mild, 3=Moderate steam, 4=Steamy, 5=Explicit
2. tropes: Top 5 tropes (e.g., "Enemies to Lovers", "Found Family", "Slow Burn")
3. moods: 3-5 moods (e.g., "Dark", "Hopeful", "Angsty", "Funny")
4. trigger_warnings: Content warnings (empty list if none)
5. generated_hook: Punchy 1-sentence summary under 140 chars

Respond ONLY with valid JSON, no other text:
{{"spice_rating": 1, "tropes": ["trope1"], "moods": ["mood1"], "trigger_warnings": [], "generated_hook": "hook text"}}"""


def get_llm_client():
    """Get the appropriate LLM client based on settings."""
    settings = get_settings()
    
    if settings.llm_provider == "groq":
        from langchain_groq import ChatGroq
        return ChatGroq(
            model=settings.groq_model,
            api_key=settings.groq_api_key,
            temperature=0.3
        )
    else:  # ollama
        from langchain_ollama import ChatOllama
        return ChatOllama(
            model=settings.ollama_model,
            base_url=settings.ollama_base_url,
            temperature=0.3
        )


def parse_llm_response(response_text: str) -> dict:
    """Extract JSON from LLM response, handling markdown code blocks."""
    # Try to find JSON in code blocks first
    json_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', response_text)
    if json_match:
        response_text = json_match.group(1)
    
    # Try to find raw JSON object
    json_match = re.search(r'\{[\s\S]*\}', response_text)
    if json_match:
        response_text = json_match.group(0)
    
    return json.loads(response_text)


async def enrich_book_metadata(isbn: str) -> Optional[dict]:
    """
    Main enrichment pipeline:
    1. Fetch raw data from Open Library
    2. Analyze with LLM (Groq or Ollama)
    3. Save enriched book to Supabase
    """
    supabase = get_supabase()
    
    # Check if book already exists and is enriched
    existing = supabase.table("books").select("*").eq("isbn", isbn).execute()
    if existing.data and existing.data[0].get("is_enriched") == 1:
        return existing.data[0]
    
    # Step 1: Fetch from Open Library
    raw_book = await fetch_book_from_open_library(isbn)
    
    if not raw_book:
        return None
    
    # Prepare base book data
    book_data = {
        "isbn": isbn,
        "title": raw_book.title,
        "author": raw_book.author,
        "cover_url": raw_book.cover_url,
        "description": raw_book.description,
        "page_count": raw_book.page_count,
        "publish_year": raw_book.publish_year,
    }
    
    # Step 2: AI Enrichment (only if we have a description)
    if not raw_book.description:
        book_data["is_enriched"] = -1
        book_data["enrichment_error"] = "No description available from Open Library"
        book_data["generated_hook"] = f"Discover '{raw_book.title}' by {raw_book.author or 'Unknown'}"[:140]
    else:
        try:
            llm = get_llm_client()
            
            prompt = ENRICHMENT_PROMPT.format(
                title=raw_book.title,
                author=raw_book.author or "Unknown",
                description=raw_book.description[:2000]
            )
            
            response = await llm.ainvoke(prompt)
            result = parse_llm_response(response.content)
            
            book_data["spice_rating"] = result.get("spice_rating", 1)
            book_data["tropes"] = result.get("tropes", [])[:5]
            book_data["moods"] = result.get("moods", [])[:5]
            book_data["trigger_warnings"] = result.get("trigger_warnings", [])
            book_data["generated_hook"] = result.get("generated_hook", "")[:140]
            book_data["is_enriched"] = 1
            book_data["enrichment_error"] = None
            
        except Exception as e:
            book_data["is_enriched"] = -1
            book_data["enrichment_error"] = str(e)
            book_data["generated_hook"] = f"Discover '{raw_book.title}' by {raw_book.author or 'Unknown'}"[:140]
    
    # Step 3: Upsert to Supabase
    result = supabase.table("books").upsert(book_data, on_conflict="isbn").execute()
    
    return result.data[0] if result.data else book_data


async def bulk_enrich_books(isbns: list[str]) -> list[dict]:
    """Enrich multiple books."""
    results = []
    for isbn in isbns:
        book = await enrich_book_metadata(isbn)
        if book:
            results.append(book)
    return results
