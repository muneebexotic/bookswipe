# BookSwipe Supabase Schema

Complete database schema ready to paste into Supabase SQL Editor.

## Tables

```sql
-- ============================================================================
-- BOOKS TABLE - Enriched catalog (backend writes, users read)
-- ============================================================================
CREATE TABLE books (
  isbn TEXT PRIMARY KEY,
  
  -- Basic metadata
  title TEXT NOT NULL,
  author TEXT,
  cover_url TEXT,
  description TEXT,
  page_count INTEGER,
  publish_year INTEGER,
  
  -- AI-enriched metadata
  spice_rating INTEGER CHECK (spice_rating >= 1 AND spice_rating <= 5),
  tropes TEXT[] DEFAULT '{}',
  moods TEXT[] DEFAULT '{}',
  trigger_warnings TEXT[] DEFAULT '{}',
  generated_hook TEXT CHECK (LENGTH(generated_hook) <= 280),
  
  -- Enrichment status
  is_enriched INTEGER DEFAULT 0, -- 0=pending, 1=success, -1=failed
  enrichment_error TEXT,
  
  -- Popularity tracking
  popularity_score INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- USER_BOOKS - Swipe decisions, shelves, ratings
-- ============================================================================
CREATE TABLE user_books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  isbn TEXT REFERENCES books(isbn) ON DELETE CASCADE,
  
  -- Status: 'liked', 'passed', 'reading', 'finished', 'dnf'
  status TEXT NOT NULL CHECK (status IN ('liked', 'passed', 'reading', 'finished', 'dnf')),
  
  -- User's personal rating and notes
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  notes TEXT,
  
  -- Timestamps
  swiped_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, isbn)
);

-- ============================================================================
-- USER_PREFERENCES - Filter settings for personalized swipes
-- ============================================================================
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Spice level filters
  min_spice INTEGER DEFAULT 1,
  max_spice INTEGER DEFAULT 5,
  
  -- Trope and mood preferences
  preferred_tropes TEXT[] DEFAULT '{}',
  excluded_tropes TEXT[] DEFAULT '{}',
  preferred_moods TEXT[] DEFAULT '{}',
  
  -- Content warnings to avoid
  hide_trigger_warnings TEXT[] DEFAULT '{}',
  
  -- Page count filters
  min_pages INTEGER,
  max_pages INTEGER,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- READING_LISTS - Custom collections (TBR, favorites, etc.)
-- ============================================================================
CREATE TABLE reading_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reading_list_books (
  list_id UUID REFERENCES reading_lists(id) ON DELETE CASCADE,
  isbn TEXT REFERENCES books(isbn) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (list_id, isbn)
);

-- ============================================================================
-- ENRICHMENT_QUEUE - Optional: Track enrichment jobs
-- ============================================================================
CREATE TABLE enrichment_queue (
  isbn TEXT PRIMARY KEY REFERENCES books(isbn) ON DELETE CASCADE,
  priority INTEGER DEFAULT 0,
  attempts INTEGER DEFAULT 0,
  last_error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Indexes

```sql
-- ============================================================================
-- BOOKS INDEXES
-- ============================================================================
-- Fast random selection of enriched books
CREATE INDEX idx_books_enriched ON books(is_enriched, isbn) WHERE is_enriched = 1;

-- Filter by spice level
CREATE INDEX idx_books_spice ON books(spice_rating) WHERE is_enriched = 1;

-- Multi-column filter index
CREATE INDEX idx_books_filters ON books(is_enriched, spice_rating, publish_year) WHERE is_enriched = 1;

-- Full-text search
CREATE INDEX idx_books_title ON books USING GIN (to_tsvector('english', title));
CREATE INDEX idx_books_author ON books USING GIN (to_tsvector('english', author));

-- Popularity sorting
CREATE INDEX idx_books_popularity ON books(popularity_score DESC) WHERE is_enriched = 1;

-- ============================================================================
-- USER_BOOKS INDEXES
-- ============================================================================
-- User's library queries
CREATE INDEX idx_user_books_user_status ON user_books(user_id, status);
CREATE INDEX idx_user_books_user_created ON user_books(user_id, created_at DESC);

-- Book interaction lookups
CREATE INDEX idx_user_books_isbn ON user_books(isbn);

-- Recent swipes
CREATE INDEX idx_user_books_swiped ON user_books(user_id, swiped_at DESC);

-- ============================================================================
-- USER_PREFERENCES INDEXES
-- ============================================================================
CREATE INDEX idx_user_preferences_user ON user_preferences(user_id);

-- ============================================================================
-- READING_LISTS INDEXES
-- ============================================================================
CREATE INDEX idx_reading_lists_user ON reading_lists(user_id);
CREATE INDEX idx_reading_list_books_list ON reading_list_books(list_id);

-- ============================================================================
-- ENRICHMENT_QUEUE INDEXES
-- ============================================================================
CREATE INDEX idx_enrichment_queue_priority ON enrichment_queue(priority DESC, created_at ASC);
```

## Triggers

```sql
-- ============================================================================
-- AUTO-UPDATE TIMESTAMPS
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER books_updated_at 
  BEFORE UPDATE ON books 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_books_updated_at 
  BEFORE UPDATE ON user_books 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_preferences_updated_at 
  BEFORE UPDATE ON user_preferences 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER reading_lists_updated_at 
  BEFORE UPDATE ON reading_lists 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

## Functions

```sql
-- ============================================================================
-- UPDATE BOOK POPULARITY SCORES
-- ============================================================================
CREATE OR REPLACE FUNCTION update_book_popularity()
RETURNS void AS $$
UPDATE books 
SET popularity_score = (
  SELECT COUNT(*) 
  FROM user_books 
  WHERE user_books.isbn = books.isbn 
    AND status IN ('liked', 'reading', 'finished')
);
$$ LANGUAGE sql;

-- Run this periodically (e.g., daily via cron job or Supabase Edge Function)
```

## Row Level Security (RLS)

```sql
-- ============================================================================
-- ENABLE RLS
-- ============================================================================
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_list_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrichment_queue ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- BOOKS POLICIES
-- ============================================================================
-- Public read access
CREATE POLICY "Books are publicly readable" 
  ON books FOR SELECT 
  USING (true);

-- Service role can write (for enrichment API)
CREATE POLICY "Service role can insert books" 
  ON books FOR INSERT 
  TO service_role
  WITH CHECK (true);

CREATE POLICY "Service role can update books" 
  ON books FOR UPDATE 
  TO service_role
  USING (true);

-- ============================================================================
-- USER_BOOKS POLICIES
-- ============================================================================
CREATE POLICY "Users can view own books" 
  ON user_books FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own books" 
  ON user_books FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own books" 
  ON user_books FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own books" 
  ON user_books FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================================================
-- USER_PREFERENCES POLICIES
-- ============================================================================
CREATE POLICY "Users can view own preferences" 
  ON user_preferences FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" 
  ON user_preferences FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" 
  ON user_preferences FOR UPDATE 
  USING (auth.uid() = user_id);

-- ============================================================================
-- READING_LISTS POLICIES
-- ============================================================================
CREATE POLICY "Users can view own or public lists" 
  ON reading_lists FOR SELECT 
  USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can insert own lists" 
  ON reading_lists FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own lists" 
  ON reading_lists FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own lists" 
  ON reading_lists FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================================================
-- READING_LIST_BOOKS POLICIES
-- ============================================================================
CREATE POLICY "Users can view list books" 
  ON reading_list_books FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM reading_lists 
      WHERE id = list_id 
        AND (user_id = auth.uid() OR is_public = true)
    )
  );

CREATE POLICY "Users can manage own list books" 
  ON reading_list_books FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM reading_lists 
      WHERE id = list_id 
        AND user_id = auth.uid()
    )
  );

-- ============================================================================
-- ENRICHMENT_QUEUE POLICIES
-- ============================================================================
-- Service role only (for enrichment API)
CREATE POLICY "Service role can manage queue" 
  ON enrichment_queue FOR ALL 
  TO service_role
  USING (true);
```

## Usage Notes

### Swipe Feed Query
```sql
-- Get books user hasn't swiped yet, filtered by preferences
SELECT b.* 
FROM books b
LEFT JOIN user_books ub ON b.isbn = ub.isbn AND ub.user_id = auth.uid()
LEFT JOIN user_preferences up ON up.user_id = auth.uid()
WHERE b.is_enriched = 1
  AND ub.isbn IS NULL -- Not swiped yet
  AND b.spice_rating BETWEEN COALESCE(up.min_spice, 1) AND COALESCE(up.max_spice, 5)
ORDER BY RANDOM()
LIMIT 20;
```

### User's Library Query
```sql
-- Get user's liked books
SELECT b.*, ub.rating, ub.notes, ub.swiped_at
FROM user_books ub
JOIN books b ON ub.isbn = b.isbn
WHERE ub.user_id = auth.uid()
  AND ub.status = 'liked'
ORDER BY ub.swiped_at DESC;
```

### Trending Books Query
```sql
-- Get popular books
SELECT * FROM books
WHERE is_enriched = 1
ORDER BY popularity_score DESC, created_at DESC
LIMIT 50;
```
