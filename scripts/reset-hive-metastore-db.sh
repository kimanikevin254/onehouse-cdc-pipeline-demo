#!/bin/bash
echo "Stopping and removing containers..."
docker compose -f datalake-docker-compose.yml down

echo "Removing hive metastore database volume..."
docker volume rm $(docker compose -f datalake-docker-compose.yml config --volumes | grep hive-metastore-db-data) 2>/dev/null || true

echo "Starting services..."
docker compose -f datalake-docker-compose.yml up -d