#!/bin/bash

# USB Camera Streamer - Deployment Script
# This script builds, tags, and pushes the Docker image to a registry

# Configuration
IMAGE_NAME="usb-camera-streamer"
REGISTRY="docker.io"  # Change this to your registry (e.g., ghcr.io, your-registry.com)
USERNAME="your-username"  # Change this to your Docker Hub username or registry username
VERSION="latest"

echo "🚀 USB Camera Streamer Deployment Script"
echo "=========================================="

# Build the image
echo "📦 Building Docker image..."
docker-compose build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build completed successfully!"

# Tag the image
LOCAL_IMAGE="usb-camera-streamer-usb-camera-streamer:latest"
REMOTE_IMAGE="$REGISTRY/$USERNAME/$IMAGE_NAME:$VERSION"

echo "🏷️  Tagging image..."
docker tag $LOCAL_IMAGE $REMOTE_IMAGE

if [ $? -ne 0 ]; then
    echo "❌ Tagging failed!"
    exit 1
fi

echo "✅ Image tagged as: $REMOTE_IMAGE"

# Ask user if they want to push
read -p "🤔 Do you want to push the image to the registry? (y/N): " push_confirm

if [[ $push_confirm =~ ^[Yy]$ ]]; then
    echo "🔐 Please make sure you're logged in to the registry:"
    echo "   docker login $REGISTRY"
    echo ""
    
    read -p "Are you logged in? (y/N): " login_confirm
    
    if [[ $login_confirm =~ ^[Yy]$ ]]; then
        echo "⬆️  Pushing image to registry..."
        docker push $REMOTE_IMAGE
        
        if [ $? -eq 0 ]; then
            echo "✅ Image pushed successfully!"
            echo "📋 Deployment information:"
            echo "   Image: $REMOTE_IMAGE"
            echo "   Pull command: docker pull $REMOTE_IMAGE"
            echo "   Run command: docker run -d --privileged --name usb-camera-streamer -p 5000:5000 -p 8080:8080 -v /dev:/dev $REMOTE_IMAGE"
        else
            echo "❌ Push failed!"
            exit 1
        fi
    else
        echo "ℹ️  Skipping push. Login first with: docker login $REGISTRY"
    fi
else
    echo "ℹ️  Skipping push to registry."
fi

echo ""
echo "🎯 Next steps for remote deployment:"
echo "1. Copy the docker-compose.yml to your remote server"
echo "2. On the remote server, run: docker-compose pull && docker-compose up -d"
echo "3. Or use the direct docker run command shown above"
echo ""
echo "🌐 Once deployed, access the application at:"
echo "   Web Interface: http://your-server-ip:5000"
echo "   Video Stream: http://your-server-ip:8080/stream"
