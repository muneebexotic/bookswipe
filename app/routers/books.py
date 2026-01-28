"""
Book enrichment endpoints - AI-powered metadata extraction.
All other book operations should be done directly via Supabase.
"""
from fastapi import APIRouter, HTTPException

from app.schemas.book import BookResponse, EnrichmentRequest, BulkEnrichmentRequest
from app.services.enrichment import enrich_book_metadata, bulk_enrich_books

router = APIRouter(prefix="/books", tags=["books"])


@router.post("/enrich", response_model=BookResponse)
async def enrich_book(request: EnrichmentRequest):
    """
    Fetch a book by ISBN, enrich with AI metadata, and save to Supabase.
    """
    book = await enrich_book_metadata(request.isbn)
    
    if not book:
        raise HTTPException(
            status_code=404,
            detail=f"Book with ISBN {request.isbn} not found in Open Library"
        )
    
    return book


@router.post("/enrich/bulk", response_model=list[BookResponse])
async def enrich_books_bulk(request: BulkEnrichmentRequest):
    """
    Enrich multiple books by ISBN. Max 50 at a time.
    """
    books = await bulk_enrich_books(request.isbns)
    return books
