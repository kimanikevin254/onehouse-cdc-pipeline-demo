#!/bin/bash
echo "Stopping and removing containers..."
docker compose -f datalake-docker-compose.yml down

echo "Removing hive metastore database volume..."
# Get the project name and construct the volume name
PROJECT_NAME=$(basename $(pwd))
docker volume rm ${PROJECT_NAME}_hive-metastore-db-data 2>/dev/null || true

echo "Starting services..."
docker compose -f datalake-docker-compose.yml up -d