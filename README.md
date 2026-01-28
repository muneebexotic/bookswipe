# BookSwipe Enrichment API

Minimal FastAPI backend that enriches book metadata using AI. Writes directly to Supabase.

## What This Does

```
ISBN → Open Library → AI Analysis → Supabase
```

1. Fetches basic metadata from Open Library
2. Uses AI (Groq/Ollama) to extract:
   - Spice rating (1-5)
   - Tropes, Moods, Trigger warnings
   - Catchy hook for swipe cards
3. Saves to your `books` table in Supabase

## Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/books/enrich` | Enrich one book |
| `POST` | `/api/v1/books/enrich/bulk` | Enrich up to 50 books |

## Setup

```bash
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your Supabase + Groq keys
uvicorn app.main:app --reload
```

## Architecture

```
Flutter ──────────────> Supabase (all CRUD)
   │
   └─ POST /enrich ──> This API ──> AI ──> Supabase
```

No SQLAlchemy. No ORM. Just Supabase client.
