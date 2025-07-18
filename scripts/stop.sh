#!/bin/bash

# Stop the USB Camera Streamer

echo "Stopping USB Camera Streamer..."
docker-compose down

echo "Removing unused Docker resources..."
docker system prune -f

echo "USB Camera Streamer stopped."
