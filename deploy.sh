#!/bin/bash
set -e

PROJECT_DIR="/opt/shvirtd-example-python"
REPO_URL="https://github.com/Dmitriy-py/shvirtd-example-python.git"
SERVICE_URL="http://127.0.0.1:8090"

echo "Starting deployment..."


if [ -d "$PROJECT_DIR" ]; then
    echo "Stopping existing project..."
    cd "$PROJECT_DIR"
    docker compose down
fi

echo "Pruning unused Docker resources..."
docker system prune -f
docker volume prune -f
docker network prune -f


if [ -d "$PROJECT_DIR" ]; then
    sudo rm -rf "$PROJECT_DIR"
fi

echo "Cloning repository from $REPO_URL to /opt..."
sudo git clone "$REPO_URL" /opt/shvirtd-example-python

sudo chown -R $USER:$USER "$PROJECT_DIR"

echo "Building and starting containers..."
cd "$PROJECT_DIR"

if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo "ERROR: .env file not found in $PROJECT_DIR. Please create it manually."
    exit 1
fi

docker compose up -d --build

echo "Waiting 60 seconds for service initialization..."
sleep 60

STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" $SERVICE_URL)

if [ "$STATUS_CODE" -eq 200 ]; then
    echo "SUCCESS: Service is reachable at $SERVICE_URL (HTTP $STATUS_CODE)"
else
    echo "FAILURE: Service check failed (HTTP $STATUS_CODE)."
    echo "Checking Docker logs..."
    docker logs mysql-db-compose || true
    docker logs web-app-compose || true
    exit 1
fi

echo "Deployment finished successfully."
