import sqlite3
import os
import random
import string
from multiprocessing import Pool
import sys

# Configuration
num_dbs = 20
target_size_mb = 230
target_size_bytes = target_size_mb * 1024 * 1024
output_dir = "sqlite_dbs"

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Pre-generate a pool of random strings to avoid generating them repeatedly
def generate_string_pool(pool_size=10000, length=100):
    """Pre-generate a pool of random strings."""
    chars = string.ascii_letters + string.digits
    return [''.join(random.choices(chars, k=length)) for _ in range(pool_size)]

def create_sqlite_db(db_index):
    """Create an SQLite database and populate it with random data."""
    db_path = os.path.join(output_dir, f"random_db_{db_index}.sqlite")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Optimize SQLite settings
    cursor.execute("PRAGMA journal_mode = WAL")  # Write-Ahead Logging
    cursor.execute("PRAGMA synchronous = NORMAL")
    cursor.execute("PRAGMA cache_size = -2000000")  # Use 2GB memory for cache
    cursor.execute("PRAGMA temp_store = MEMORY")
    
    cursor.execute("CREATE TABLE IF NOT EXISTS data (id INTEGER PRIMARY KEY, value TEXT);")
    
    # Pre-generate string pool
    string_pool = generate_string_pool()
    batch_size = 50000  # Larger batch size
    check_size_frequency = 5  # Check file size every 5 batches
    
    batch_count = 0
    while True:
        # Start transaction
        cursor.execute("BEGIN TRANSACTION")
        
        # Insert a large batch of records
        cursor.executemany(
            "INSERT INTO data (value) VALUES (?)",
            [(random.choice(string_pool),) for _ in range(batch_size)]
        )
        
        # Commit the transaction
        conn.commit()
        
        batch_count += 1
        
        # Check file size less frequently
        if batch_count % check_size_frequency == 0:
            if os.path.getsize(db_path) >= target_size_bytes:
                break
    
    conn.close()
    print(f"Database {db_path} created successfully.", file=sys.stderr)

def main():
    # Use multiprocessing to create databases in parallel
    with Pool() as pool:
        pool.map(create_sqlite_db, range(1, num_dbs + 1))

if __name__ == '__main__':
    main()