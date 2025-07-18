#!/bin/bash

# USB Camera Streamer - Remote Server Setup Script
# Run this script on your remote server (@lolobotlab)

set -e

echo "🎯 USB Camera Streamer - Remote Server Setup"
echo "============================================="

# Configuration
PROJECT_DIR="$HOME/usb-camera-streamer"
DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/docker/compose/v2.23.0/bin/compose/docker-compose-linux-x86_64"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Please don't run this script as root"
    exit 1
fi

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and log back in for group changes to take effect."
else
    echo "✅ Docker is already installed"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo curl -L "$DOCKER_COMPOSE_URL" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose is already installed"
fi

# Check for USB cameras
echo "📹 Checking for USB cameras..."
if ls /dev/video* 1> /dev/null 2>&1; then
    echo "✅ Video devices found:"
    ls -la /dev/video*
else
    echo "⚠️  No video devices found. Make sure your USB camera is connected."
fi

# Check v4l-utils
if ! command -v v4l2-ctl &> /dev/null; then
    echo "📦 Installing v4l-utils..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y v4l-utils
    elif command -v yum &> /dev/null; then
        sudo yum install -y v4l-utils
    else
        echo "⚠️  Please install v4l-utils manually"
    fi
else
    echo "✅ v4l-utils is already installed"
fi

# Create project directory
echo "📁 Creating project directory..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create docker-compose.yml file
echo "📝 Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  usb-camera-streamer:
    image: docker.io/loack25/lolobotlab:usb-camera-streamer  # Update this with your actual image
    container_name: usb-camera-streamer
    restart: unless-stopped
    ports:
      - "5000:5000"   # Flask web interface
      - "8080:8080"   # ustreamer video stream
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
    networks:
      - camera-network
    user: root

networks:
  camera-network:
    driver: bridge
EOF

echo "✅ Docker Compose file created at $PROJECT_DIR/docker-compose.yml"

# Create start script
echo "📝 Creating start script..."
cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting USB Camera Streamer..."
docker-compose pull
docker-compose up -d
echo "✅ USB Camera Streamer started!"
echo "🌐 Web Interface: http://$(hostname -I | awk '{print $1}'):5000"
echo "📹 Video Stream: http://$(hostname -I | awk '{print $1}'):8080/stream"
EOF

chmod +x start.sh

# Create stop script
echo "📝 Creating stop script..."
cat > stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping USB Camera Streamer..."
docker-compose down
echo "✅ USB Camera Streamer stopped!"
EOF

chmod +x stop.sh

# Create status script
echo "📝 Creating status script..."
cat > status.sh << 'EOF'
#!/bin/bash
echo "📊 USB Camera Streamer Status"
echo "============================"
echo "🐳 Container Status:"
docker ps --filter name=usb-camera-streamer

echo ""
echo "📹 Video Devices:"
ls -la /dev/video* 2>/dev/null || echo "No video devices found"

echo ""
echo "🌐 Port Status:"
netstat -tlnp 2>/dev/null | grep -E "(5000|8080)" || echo "Ports not open"

echo ""
echo "📝 Recent Logs:"
docker logs --tail 10 usb-camera-streamer 2>/dev/null || echo "Container not running"
EOF

chmod +x status.sh

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Edit docker-compose.yml and update the image name to your actual image"
echo "2. Run: ./start.sh to start the application"
echo "3. Check status with: ./status.sh"
echo "4. Stop with: ./stop.sh"
echo ""
echo "📁 Project location: $PROJECT_DIR"
echo "🌐 Access URL: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "⚠️  Note: If you just installed Docker, please log out and log back in before running ./start.sh"
