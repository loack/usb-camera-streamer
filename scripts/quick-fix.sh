#!/bin/bash

echo "🔧 USB Camera Streamer - Quick Fix Script"
echo "========================================="

# Stop current container
echo "🛑 Stopping current container..."
docker-compose down

# Check for USB cameras on host
echo "📹 Checking for USB cameras on host..."
if ls /dev/video* 1> /dev/null 2>&1; then
    echo "✅ Video devices found:"
    ls -la /dev/video*
    
    # Test v4l2-ctl on host
    if command -v v4l2-ctl &> /dev/null; then
        echo "🔍 Camera info from host:"
        v4l2-ctl --list-devices 2>/dev/null || echo "No cameras detected by v4l2-ctl"
    else
        echo "⚠️ v4l-utils not installed on host, installing..."
        sudo apt-get update && sudo apt-get install -y v4l-utils
    fi
else
    echo "❌ No video devices found. Please check:"
    echo "   1. USB camera is connected"
    echo "   2. Camera is recognized by system (lsusb)"
    echo "   3. Kernel modules are loaded (lsmod | grep uvc)"
    exit 1
fi

# Fix permissions
echo "🔐 Fixing video device permissions..."
sudo chmod 666 /dev/video* 2>/dev/null || echo "No video devices to fix"

# Add user to video group
echo "👥 Adding user to video group..."
sudo usermod -a -G video $USER

# Create fixed docker-compose file
echo "📝 Creating fixed docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  usb-camera-streamer:
    image: docker.io/loack25/lolobotlab:usb-camera-streamer
    container_name: usb-camera-streamer
    restart: unless-stopped
    ports:
      - "5000:5000"
      - "8080:8080"
    devices:
      - /dev/video0:/dev/video0
      - /dev/video1:/dev/video1
      - /dev/video2:/dev/video2
      - /dev/video3:/dev/video3
    privileged: true
    volumes:
      - /dev:/dev
    environment:
      - PYTHONUNBUFFERED=1
      - FLASK_HOST=0.0.0.0
      - FLASK_PORT=5000
      - USTREAMER_PORT=8080
    networks:
      - camera-network
    user: root  # Run as root to avoid permission issues

networks:
  camera-network:
    driver: bridge
EOF

# Start with the fixed configuration
echo "🚀 Starting USB Camera Streamer with fixed configuration..."
docker-compose pull
docker-compose up -d

# Wait for startup
echo "⏳ Waiting for service to start..."
sleep 10

# Check container logs
echo "📝 Container logs:"
docker logs --tail 20 usb-camera-streamer

# Test the API
echo "🧪 Testing camera detection API..."
sleep 5
curl -s http://localhost:5000/api/cameras | python3 -m json.tool 2>/dev/null || echo "❌ API not responding"

echo ""
echo "✅ Quick fix completed!"
echo "🌐 Access the interface at: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "If cameras are still not detected, run the full debug script:"
echo "   chmod +x debug-cameras.sh && ./debug-cameras.sh"
