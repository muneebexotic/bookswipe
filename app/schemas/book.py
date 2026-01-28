from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class BookBase(BaseModel):
    isbn: str
    title: str
    author: Optional[str] = None


class BookCreate(BaseModel):
    isbn: str = Field(..., min_length=10, max_length=13)


class BookResponse(BaseModel):
    isbn: str
    title: str
    author: Optional[str]
    cover_url: Optional[str]
    description: Optional[str]
    page_count: Optional[int]
    publish_year: Optional[int]
    
    # Deep metadata
    spice_rating: Optional[int]
    tropes: Optional[list[str]]
    moods: Optional[list[str]]
    trigger_warnings: Optional[list[str]]
    generated_hook: Optional[str]
    
    # Status
    is_enriched: int
    enrichment_error: Optional[str]
    created_at: Optional[datetime]

    class Config:
        from_attributes = True


class BookCard(BaseModel):
    """Minimal data for swipe card UI"""
    isbn: str
    title: str
    author: Optional[str]
    cover_url: Optional[str]
    generated_hook: Optional[str]
    spice_rating: Optional[int]
    tropes: Optional[list[str]]
    moods: Optional[list[str]]

    class Config:
        from_attributes = True


class EnrichmentRequest(BaseModel):
    isbn: str = Field(..., min_length=10, max_length=13)


class BulkEnrichmentRequest(BaseModel):
    isbns: list[str] = Field(..., min_length=1, max_length=50)
