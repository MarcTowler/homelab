#!/bin/bash
# Fitbit Container Fix Script

echo "?? FITBIT CONTAINER FIX"
echo "======================================"
cd /opt/fitbit-grafana

# Check current docker compose status
echo "Current docker compose status:"
docker compose ps

# If fitbit-fetch-data is not running, start it
echo ""
echo "Starting fitbit-fetch-data container..."
docker compose up -d fitbit-fetch-data

# Wait a moment for it to start
sleep 3

# Check status again
echo ""
echo "Updated status:"
docker compose ps

# Check logs to see if it's running correctly
echo ""
echo "Recent logs from fitbit-fetch-data:"
docker compose logs fitbit-fetch-data --tail=20

echo ""
echo "======================================"
echo "? Fix complete. Container should now be collecting data."
