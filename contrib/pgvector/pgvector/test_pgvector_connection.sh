#!/bin/bash

# Database connection parameters
# You might need to adjust these based on your configuration
DB_NAME="testHarmony"
DB_USER=$(whoami) # Default to current user, often works for local dev
# DB_PORT="5432" 

# Check if psql is available
PG_BIN="/home/lichengqi/pgsql/bin"
PSQL="$PG_BIN/psql"

if [ ! -x "$PSQL" ]; then
    echo "psql not found at $PSQL. Checking PATH..."
    if ! command -v psql &> /dev/null; then
        echo "psql command not found. Please ensure PostgreSQL bin directory is in your PATH."
        exit 1
    else
        PSQL="psql"
    fi
fi

echo "Testing PostgreSQL connection..."
# Try to connect. We use -w to not prompt for password (assumes trust auth or .pgpass)
"$PSQL" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Connection successful."
else
    echo "Failed to connect to database '$DB_NAME'. Please check if the server is running and accepting connections."
    exit 1
fi

echo "Testing pgvector extension..."

# Create extension
echo "Creating extension vector if not exists..."
"$PSQL" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;"

if [ $? -ne 0 ]; then
    echo "Failed to create extension vector."
    exit 1
fi

# Create table
echo "Creating test table 'test_vector'..."
"$PSQL" -d "$DB_NAME" -c "DROP TABLE IF EXISTS test_vector;"
"$PSQL" -d "$DB_NAME" -c "CREATE TABLE test_vector (id serial PRIMARY KEY, embedding vector(3));"

# Insert data
echo "Inserting data..."
"$PSQL" -d "$DB_NAME" -c "INSERT INTO test_vector (embedding) VALUES ('[1,2,3]'), ('[4,5,6]'), ('[7,8,9]');"

# Query data
echo "Querying nearest neighbors to [1,2,3]..."
RESULT=$("$PSQL" -d "$DB_NAME" -t -c "SELECT id, embedding FROM test_vector ORDER BY embedding <-> '[1,2,3]' LIMIT 1;")

echo "Result: $RESULT"

# Check if result contains the expected vector
if [[ $RESULT == *"1 | [1,2,3]"* ]] || [[ $RESULT == *"[1,2,3]"* ]]; then
    echo "pgvector test passed successfully!"
else
    echo "pgvector test failed. Unexpected result."
    exit 1
fi

# Cleanup
echo "Cleaning up..."
"$PSQL" -d "$DB_NAME" -c "DROP TABLE test_vector;"

echo "Done."
