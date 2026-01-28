import httpx
from typing import Optional
from pydantic import BaseModel


class OpenLibraryBook(BaseModel):
    """Raw book data from Open Library API"""
    isbn: str
    title: str
    author: Optional[str] = None
    description: Optional[str] = None
    cover_url: Optional[str] = None
    page_count: Optional[int] = None
    publish_year: Optional[int] = None


async def fetch_book_from_open_library(isbn: str) -> Optional[OpenLibraryBook]:
    """
    Fetch book data from Open Library API.
    Returns None if book not found.
    """
    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
        # Try ISBN endpoint first
        url = f"https://openlibrary.org/isbn/{isbn}.json"
        
        try:
            print(f"Fetching from URL: {url}")  # Debug log
            response = await client.get(url)
            print(f"Response status: {response.status_code}")  # Debug log
            
            if response.status_code != 200:
                print(f"Non-200 status code: {response.status_code}")
                return None
            
            data = response.json()
            print(f"Got data keys: {list(data.keys())}")  # Debug log
            
            # Extract title
            title = data.get("title", "Unknown Title")
            
            # Extract description (can be string or dict)
            description = None
            desc_raw = data.get("description")
            if isinstance(desc_raw, str):
                description = desc_raw
            elif isinstance(desc_raw, dict):
                description = desc_raw.get("value")
            
            # Get cover URL (using cover ID)
            cover_url = None
            covers = data.get("covers", [])
            if covers:
                cover_id = covers[0]
                cover_url = f"https://covers.openlibrary.org/b/id/{cover_id}-L.jpg"
            
            # Get page count
            page_count = data.get("number_of_pages")
            
            # Get author (need to fetch from works)
            author = None
            authors_refs = data.get("authors", [])
            if authors_refs:
                author_key = authors_refs[0].get("key")
                if author_key:
                    author_resp = await client.get(f"https://openlibrary.org{author_key}.json")
                    if author_resp.status_code == 200:
                        author_data = author_resp.json()
                        author = author_data.get("name")
            
            # Get publish year
            publish_year = data.get("publish_date")
            if publish_year:
                # Try to extract year from various formats
                import re
                year_match = re.search(r'\d{4}', str(publish_year))
                publish_year = int(year_match.group()) if year_match else None
            
            # If no description from edition, try the work
            if not description:
                works = data.get("works", [])
                if works:
                    work_key = works[0].get("key")
                    if work_key:
                        work_resp = await client.get(f"https://openlibrary.org{work_key}.json")
                        if work_resp.status_code == 200:
                            work_data = work_resp.json()
                            desc_raw = work_data.get("description")
                            if isinstance(desc_raw, str):
                                description = desc_raw
                            elif isinstance(desc_raw, dict):
                                description = desc_raw.get("value")
            
            return OpenLibraryBook(
                isbn=isbn,
                title=title,
                author=author,
                description=description,
                cover_url=cover_url,
                page_count=page_count,
                publish_year=publish_year
            )
            
        except Exception as e:
            print(f"Error fetching book {isbn}: {e}")
            return None
