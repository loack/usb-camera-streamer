# PowerShell script to start USB Camera Streamer on Windows

Write-Host "Building USB Camera Streamer..." -ForegroundColor Green
docker-compose build

Write-Host "Starting USB Camera Streamer..." -ForegroundColor Green
docker-compose up -d

Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "Checking service status..." -ForegroundColor Green
docker-compose ps

Write-Host ""
Write-Host "USB Camera Streamer is now running!" -ForegroundColor Green
Write-Host "Web Interface: http://localhost:5000" -ForegroundColor Cyan
Write-Host "Video Stream: http://localhost:8080/stream" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view logs: docker-compose logs -f" -ForegroundColor Yellow
Write-Host "To stop: docker-compose down" -ForegroundColor Yellow
