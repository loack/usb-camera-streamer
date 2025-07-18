# USB Camera Streamer - Deployment Script (PowerShell)
# This script builds, tags, and pushes the Docker image to a registry

# Configuration
$IMAGE_NAME = "usb-camera-streamer"
$REGISTRY = "docker.io"  # Change this to your registry (e.g., ghcr.io, your-registry.com)
$USERNAME = "your-username"  # Change this to your Docker Hub username or registry username
$VERSION = "latest"

Write-Host "🚀 USB Camera Streamer Deployment Script" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Build the image
Write-Host "📦 Building Docker image..." -ForegroundColor Yellow
docker-compose build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green

# Tag the image
$LOCAL_IMAGE = "usb-camera-streamer-usb-camera-streamer:latest"
$REMOTE_IMAGE = "$REGISTRY/$USERNAME/$IMAGE_NAME`:$VERSION"

Write-Host "🏷️  Tagging image..." -ForegroundColor Yellow
docker tag $LOCAL_IMAGE $REMOTE_IMAGE

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Tagging failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Image tagged as: $REMOTE_IMAGE" -ForegroundColor Green

# Ask user if they want to push
$push_confirm = Read-Host "🤔 Do you want to push the image to the registry? (y/N)"

if ($push_confirm -match "^[Yy]$") {
    Write-Host "🔐 Please make sure you're logged in to the registry:" -ForegroundColor Yellow
    Write-Host "   docker login $REGISTRY" -ForegroundColor Cyan
    Write-Host ""
    
    $login_confirm = Read-Host "Are you logged in? (y/N)"
    
    if ($login_confirm -match "^[Yy]$") {
        Write-Host "⬆️  Pushing image to registry..." -ForegroundColor Yellow
        docker push $REMOTE_IMAGE
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Image pushed successfully!" -ForegroundColor Green
            Write-Host "📋 Deployment information:" -ForegroundColor Cyan
            Write-Host "   Image: $REMOTE_IMAGE" -ForegroundColor White
            Write-Host "   Pull command: docker pull $REMOTE_IMAGE" -ForegroundColor White
            Write-Host "   Run command: docker run -d --privileged --name usb-camera-streamer -p 5000:5000 -p 8080:8080 -v /dev:/dev $REMOTE_IMAGE" -ForegroundColor White
        } else {
            Write-Host "❌ Push failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "ℹ️  Skipping push. Login first with: docker login $REGISTRY" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  Skipping push to registry." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Next steps for remote deployment:" -ForegroundColor Cyan
Write-Host "1. Copy the docker-compose.yml to your remote server" -ForegroundColor White
Write-Host "2. On the remote server, run: docker-compose pull && docker-compose up -d" -ForegroundColor White
Write-Host "3. Or use the direct docker run command shown above" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Once deployed, access the application at:" -ForegroundColor Cyan
Write-Host "   Web Interface: http://your-server-ip:5000" -ForegroundColor White
Write-Host "   Video Stream: http://your-server-ip:8080/stream" -ForegroundColor White
