from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.books import router as books_router

app = FastAPI(
    title="BookSwipe API",
    description="AI-Enriched Book Metadata Service",
    version="0.2.0"
)

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Only books router (enrichment endpoints)
app.include_router(books_router, prefix="/api/v1")


@app.get("/")
async def root():
    return {
        "app": "BookSwipe Enrichment API",
        "version": "0.2.0",
        "note": "For CRUD operations, use Supabase directly",
        "docs": "/docs"
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}
