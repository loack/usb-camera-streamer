#!/bin/bash

# Build and start the USB Camera Streamer

echo "Building USB Camera Streamer..."
docker-compose build

echo "Starting USB Camera Streamer..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 5

echo "Checking service status..."
docker-compose ps

echo ""
echo "USB Camera Streamer is now running!"
echo "Web Interface: http://localhost:5000"
echo "Video Stream: http://localhost:8080/stream"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
