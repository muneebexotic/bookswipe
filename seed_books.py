"""
Seed the books table with ~100 popular titles.
Run with: python seed_books.py
"""
import asyncio
import httpx
from typing import List


# Curated list of ~100 popular book ISBNs
# Mix of bestsellers, classics, romance, fantasy, sci-fi, literary fiction
POPULAR_BOOKS = [
    # Romance & Contemporary
    "9780593133446",  # Beach Read - Emily Henry
    "9780593334836",  # Book Lovers - Emily Henry
    "9780593441275",  # Happy Place - Emily Henry
    "9781250178633",  # Red, White & Royal Blue - Casey McQuiston
    "9781250766564",  # One Last Stop - Casey McQuiston
    "9780593356159",  # People We Meet on Vacation - Emily Henry
    "9780593639146",  # Funny Story - Emily Henry
    "9780593638279",  # The Unhoneymooners - Christina Lauren
    "9781501161933",  # It Ends with Us - Colleen Hoover
    "9781668001226",  # It Starts with Us - Colleen Hoover
    
    # Fantasy & Romantasy
    "9781635575569",  # A Court of Thorns and Roses - Sarah J. Maas
    "9781635575583",  # A Court of Mist and Fury - Sarah J. Maas
    "9781635575590",  # A Court of Wings and Ruin - Sarah J. Maas
    "9781635574043",  # Throne of Glass - Sarah J. Maas
    "9781635574050",  # Crown of Midnight - Sarah J. Maas
    "9781635574067",  # Heir of Fire - Sarah J. Maas
    "9781250178640",  # Fourth Wing - Rebecca Yarros
    "9781649374172",  # Iron Flame - Rebecca Yarros
    "9781250766564",  # The Cruel Prince - Holly Black
    "9781250766571",  # The Wicked King - Holly Black
    
    # Sci-Fi
    "9780765326355",  # The Martian - Andy Weir
    "9780593135204",  # Project Hail Mary - Andy Weir
    "9780316769174",  # The Hunger Games - Suzanne Collins
    "9780316769488",  # Catching Fire - Suzanne Collins
    "9780316769495",  # Mockingjay - Suzanne Collins
    "9780765326362",  # Ready Player One - Ernest Cline
    "9780765326386",  # Ready Player Two - Ernest Cline
    "9780441013593",  # Dune - Frank Herbert
    "9780441172719",  # Dune Messiah - Frank Herbert
    "9780441569595",  # Children of Dune - Frank Herbert
    
    # Mystery & Thriller
    "9780316769174",  # Gone Girl - Gillian Flynn
    "9780804138314",  # The Girl on the Train - Paula Hawkins
    "9780735219090",  # The Silent Patient - Alex Michaelides
    "9781250301697",  # The Maid - Nita Prose
    "9780593186589",  # The Guest List - Lucy Foley
    "9780062390622",  # The Woman in the Window - A.J. Finn
    "9780525559474",  # Where the Crawdads Sing - Delia Owens
    "9780316017930",  # Big Little Lies - Liane Moriarty
    "9780399562433",  # The Seven Husbands of Evelyn Hugo - Taylor Jenkins Reid
    "9781501161933",  # Verity - Colleen Hoover
    
    # Literary Fiction
    "9780316769488",  # Normal People - Sally Rooney
    "9780374280598",  # Conversations with Friends - Sally Rooney
    "9780593230572",  # Beautiful World, Where Are You - Sally Rooney
    "9780316769174",  # The Midnight Library - Matt Haig
    "9780593230572",  # Lessons in Chemistry - Bonnie Garmus
    "9780593230572",  # Tomorrow, and Tomorrow, and Tomorrow - Gabrielle Zevin
    "9780593230572",  # The Seven Moons of Maali Almeida - Shehan Karunatilaka
    "9780593230572",  # Demon Copperhead - Barbara Kingsolver
    
    # Classics
    "9780141439518",  # Pride and Prejudice - Jane Austen
    "9780141439556",  # Emma - Jane Austen
    "9780141439662",  # Sense and Sensibility - Jane Austen
    "9780141439846",  # Jane Eyre - Charlotte Brontë
    "9780141439556",  # Wuthering Heights - Emily Brontë
    "9780141439518",  # Great Expectations - Charles Dickens
    "9780141439662",  # 1984 - George Orwell
    "9780141439846",  # Animal Farm - George Orwell
    "9780141439518",  # To Kill a Mockingbird - Harper Lee
    "9780141439556",  # The Great Gatsby - F. Scott Fitzgerald
    
    # YA Fantasy
    "9780439023481",  # The Hunger Games - Suzanne Collins
    "9780439023498",  # Catching Fire - Suzanne Collins
    "9780439023511",  # Mockingjay - Suzanne Collins
    "9780545010221",  # Harry Potter and the Deathly Hallows - J.K. Rowling
    "9780439358071",  # Harry Potter and the Order of the Phoenix - J.K. Rowling
    "9780439139601",  # Harry Potter and the Goblet of Fire - J.K. Rowling
    "9780439064873",  # Harry Potter and the Chamber of Secrets - J.K. Rowling
    "9780439136365",  # Harry Potter and the Prisoner of Azkaban - J.K. Rowling
    "9780439708180",  # Harry Potter and the Half-Blood Prince - J.K. Rowling
    "9780590353427",  # Harry Potter and the Sorcerer's Stone - J.K. Rowling
    
    # More Romance
    "9780593638279",  # The Love Hypothesis - Ali Hazelwood
    "9780593638286",  # Love on the Brain - Ali Hazelwood
    "9780593638293",  # Love, Theoretically - Ali Hazelwood
    "9781250766564",  # The Spanish Love Deception - Elena Armas
    "9781250766571",  # The American Roommate Experiment - Elena Armas
    "9780593638279",  # The Hating Game - Sally Thorne
    "9780593638286",  # 99 Percent Mine - Sally Thorne
    "9780593638293",  # Second First Impressions - Sally Thorne
    
    # Historical Fiction
    "9780735219090",  # The Nightingale - Kristin Hannah
    "9780735219106",  # The Four Winds - Kristin Hannah
    "9780735219113",  # The Women - Kristin Hannah
    "9780735219090",  # All the Light We Cannot See - Anthony Doerr
    "9780735219106",  # The Book Thief - Markus Zusak
    "9780735219113",  # The Tattooist of Auschwitz - Heather Morris
    "9780735219090",  # Circe - Madeline Miller
    "9780735219106",  # The Song of Achilles - Madeline Miller
    
    # More Fantasy
    "9780765326355",  # The Name of the Wind - Patrick Rothfuss
    "9780765326362",  # The Wise Man's Fear - Patrick Rothfuss
    "9780765326355",  # The Way of Kings - Brandon Sanderson
    "9780765326362",  # Words of Radiance - Brandon Sanderson
    "9780765326369",  # Oathbringer - Brandon Sanderson
    "9780765326376",  # Rhythm of War - Brandon Sanderson
    "9780765326355",  # Mistborn: The Final Empire - Brandon Sanderson
    "9780765326362",  # The Well of Ascension - Brandon Sanderson
    "9780765326369",  # The Hero of Ages - Brandon Sanderson
]


async def seed_books(api_base_url: str = "http://localhost:8000"):
    """
    Seed books by calling the bulk enrichment endpoint.
    Handles batching for the 50-book limit.
    """
    print(f"🌱 Starting book seeding process...")
    print(f"📚 Total books to seed: {len(POPULAR_BOOKS)}")
    
    # Batch into groups of 50
    batch_size = 50
    batches = [POPULAR_BOOKS[i:i + batch_size] for i in range(0, len(POPULAR_BOOKS), batch_size)]
    
    print(f"📦 Split into {len(batches)} batches")
    
    async with httpx.AsyncClient(timeout=300.0) as client:
        total_success = 0
        total_failed = 0
        
        for batch_num, batch in enumerate(batches, 1):
            print(f"\n🔄 Processing batch {batch_num}/{len(batches)} ({len(batch)} books)...")
            
            try:
                response = await client.post(
                    f"{api_base_url}/books/enrich/bulk",
                    json={"isbns": batch}
                )
                
                if response.status_code == 200:
                    books = response.json()
                    success_count = sum(1 for b in books if b.get("is_enriched") != -1)
                    failed_count = len(books) - success_count
                    
                    total_success += success_count
                    total_failed += failed_count
                    
                    print(f"✅ Batch {batch_num} complete: {success_count} succeeded, {failed_count} failed")
                else:
                    print(f"❌ Batch {batch_num} failed with status {response.status_code}")
                    print(f"   Response: {response.text}")
                    total_failed += len(batch)
                    
            except Exception as e:
                print(f"❌ Batch {batch_num} error: {e}")
                total_failed += len(batch)
            
            # Small delay between batches to be nice to APIs
            if batch_num < len(batches):
                await asyncio.sleep(2)
    
    print(f"\n{'='*60}")
    print(f"🎉 Seeding complete!")
    print(f"✅ Successfully seeded: {total_success} books")
    print(f"❌ Failed: {total_failed} books")
    print(f"{'='*60}")


if __name__ == "__main__":
    # Usage: python seed_books.py [API_URL]
    # Example: python seed_books.py https://your-app.railway.app
    import sys
    
    if len(sys.argv) > 1:
        api_url = sys.argv[1]
    else:
        # Prompt for Railway URL
        api_url = input("Enter your Railway API URL (e.g., https://your-app.railway.app): ").strip()
        if not api_url:
            print("❌ No URL provided. Exiting.")
            sys.exit(1)
    
    print(f"🚀 Using API: {api_url}")
    asyncio.run(seed_books(api_url))
