# Remote Server Deployment Guide

## Prerequisites on Remote Server (@lolobotlab)

1. **Docker and Docker Compose installed**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **USB Camera connected and recognized**
   ```bash
   # Check for USB cameras
   lsusb | grep -i camera
   ls -la /dev/video*
   v4l2-ctl --list-devices
   ```

## Deployment Methods

### Method 1: Using Docker Registry (Recommended)

1. **Push image to Docker Hub (from your local machine)**
   ```bash
   # Build and tag the image
   docker-compose build
   docker tag usb-camera-streamer-usb-camera-streamer:latest loack25/lolobotlab:usb-camera-streamer
   
   # Login and push
   docker login
   docker push your-username/usb-camera-streamer:latest
   ```

2. **Deploy on remote server**
   ```bash
   # Create project directory
   mkdir -p ~/usb-camera-streamer
   cd ~/usb-camera-streamer
   
   # Download docker-compose file (or copy it)
   wget https://raw.githubusercontent.com/your-repo/usb-camera-streamer/main/docker-compose.remote.yml
   # OR copy the file manually
   
   # Update the image name in docker-compose.remote.yml
   # Then start the service
   docker-compose -f docker-compose.remote.yml pull
   docker-compose -f docker-compose.remote.yml up -d
   ```

### Method 2: Direct Docker Export/Import

1. **Export image from local machine**
   ```bash
   docker save usb-camera-streamer-usb-camera-streamer:latest | gzip > usb-camera-streamer.tar.gz
   ```

2. **Transfer to remote server**
   ```bash
   scp usb-camera-streamer.tar.gz user@lolobotlab:~/
   ```

3. **Import and run on remote server**
   ```bash
   # Import the image
   gunzip -c usb-camera-streamer.tar.gz | docker load
   
   # Run the container
   docker run -d \
     --name usb-camera-streamer \
     --privileged \
     --restart unless-stopped \
     -p 5000:5000 \
     -p 8080:8080 \
     -v /dev:/dev \
     -e PYTHONUNBUFFERED=1 \
     usb-camera-streamer-usb-camera-streamer:latest
   ```

### Method 3: Build on Remote Server

1. **Copy source code to remote server**
   ```bash
   scp -r usb-camera-streamer/ user@lolobotlab:~/
   ```

2. **Build and run on remote server**
   ```bash
   cd ~/usb-camera-streamer
   docker-compose build
   docker-compose up -d
   ```

## Post-Deployment

### 1. Verify the deployment
```bash
# Check container status
docker ps

# Check logs
docker logs usb-camera-streamer

# Check if ports are open
netstat -tlnp | grep -E "(5000|8080)"
```

### 2. Test the application
```bash
# Test web interface
curl http://localhost:5000

# Test API
curl http://localhost:5000/api/cameras
curl http://localhost:5000/api/stream/status
```

### 3. Access from external network
- Web Interface: `http://lolobotlab:5000`
- Video Stream: `http://lolobotlab:8080/stream`

## Firewall Configuration

If you have a firewall enabled, make sure to open the necessary ports:

```bash
# UFW (Ubuntu)
sudo ufw allow 5000
sudo ufw allow 8080

# iptables
sudo iptables -A INPUT -p tcp --dport 5000 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

## Troubleshooting

### Camera not detected
```bash
# Check USB devices
lsusb

# Check video devices
ls -la /dev/video*

# Check permissions
ls -la /dev/video0

# If needed, add user to video group
sudo usermod -a -G video $USER

# Check v4l2 tools
v4l2-ctl --list-devices
v4l2-ctl --device /dev/video0 --info
```

### Container issues
```bash
# Check container logs
docker logs usb-camera-streamer

# Check if container has access to devices
docker exec usb-camera-streamer ls -la /dev/video*

# Restart container
docker restart usb-camera-streamer
```

### Network issues
```bash
# Check if ports are bound
netstat -tlnp | grep docker

# Check if services are running
curl http://localhost:5000/api/stream/status
```

## Updating the Application

```bash
# Pull latest image
docker-compose -f docker-compose.remote.yml pull

# Restart with new image
docker-compose -f docker-compose.remote.yml up -d

# Or if using direct docker run
docker pull your-username/usb-camera-streamer:latest
docker stop usb-camera-streamer
docker rm usb-camera-streamer
# Then run the docker run command again
```

## Monitoring

### Check application health
```bash
# Container status
docker ps

# Resource usage
docker stats usb-camera-streamer

# Logs
docker logs -f usb-camera-streamer
```

### Systemd service (optional)
Create a systemd service for automatic startup:

```bash
sudo nano /etc/systemd/system/usb-camera-streamer.service
```

```ini
[Unit]
Description=USB Camera Streamer
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/home/user/usb-camera-streamer
ExecStart=/usr/local/bin/docker-compose -f docker-compose.remote.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.remote.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable usb-camera-streamer
sudo systemctl start usb-camera-streamer
```
