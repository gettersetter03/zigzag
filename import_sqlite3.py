import sqlite3
import os
import random
import string

# Configuration
num_dbs = 20
target_size_mb = 230
target_size_bytes = target_size_mb * 1024 * 1024
output_dir = "sqlite_dbs"

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

def random_string(length=100):
    """Generate a random string of specified length."""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def create_sqlite_db(db_index):
    """Create an SQLite database and populate it with random data."""
    db_path = os.path.join(output_dir, f"random_db_{db_index}.sqlite")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("CREATE TABLE IF NOT EXISTS data (id INTEGER PRIMARY KEY, value TEXT);")

    while os.path.getsize(db_path) < target_size_bytes:
        cursor.executemany("INSERT INTO data (value) VALUES (?);", 
                           [(random_string(),) for _ in range(5000)])  # Batch insert
        conn.commit()
    
    conn.close()
    print(f"Database {db_path} created successfully.")

# Generate the SQLite databases
for i in range(1, num_dbs + 1):
    create_sqlite_db(i)

print("All databases created successfully.")