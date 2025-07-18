# USB Camera Streamer - Debugging Guide

## Issue: No cameras are listed in the web interface

When you can access the web page but no cameras are listed, here's how to debug the issue step by step.

## Quick Debug Script

Run this script on your remote server to diagnose the issue:

```bash
# Copy the debug-cameras.sh script to your server and run:
chmod +x debug-cameras.sh
./debug-cameras.sh
```

## Manual Debugging Steps

### 1. Check if USB cameras are connected and recognized by the host

```bash
# Check if any USB cameras are connected
lsusb | grep -i camera
lsusb | grep -i video

# Check video devices on the host
ls -la /dev/video*

# Check what cameras are detected by v4l2
v4l2-ctl --list-devices
```

### 2. Check container status and logs

```bash
# Check if container is running
docker ps --filter name=usb-camera-streamer

# Check container logs for errors
docker logs usb-camera-streamer

# Check last 50 lines with timestamps
docker logs --timestamps --tail 50 usb-camera-streamer
```

### 3. Check if video devices are accessible inside the container

```bash
# Check video devices inside container
docker exec usb-camera-streamer ls -la /dev/video*

# Test v4l2-ctl inside container
docker exec usb-camera-streamer v4l2-ctl --list-devices

# Test if we can get camera info
docker exec usb-camera-streamer v4l2-ctl --device /dev/video0 --info
```

### 4. Test the camera detection API directly

```bash
# Test the cameras API endpoint
curl -s http://localhost:5000/api/cameras | python3 -m json.tool

# If the above fails, try with explicit IP
curl -s http://192.168.1.10:5000/api/cameras | python3 -m json.tool
```

### 5. Check permissions and container privileges

```bash
# Check if container is running with privileged mode
docker inspect usb-camera-streamer | grep -i privileged

# Check device mounts
docker inspect usb-camera-streamer | grep -A 10 -B 10 "Devices"
```

## Common Issues and Solutions

### Issue 1: No USB cameras connected
**Symptoms:** `ls -la /dev/video*` shows "No such file or directory"
**Solution:** 
- Connect a USB camera
- Check if the camera is recognized: `lsusb`
- Try a different USB port

### Issue 2: Permission denied accessing video devices
**Symptoms:** Container logs show permission errors
**Solutions:**
```bash
# Option 1: Add your user to video group (then restart)
sudo usermod -a -G video $USER

# Option 2: Change video device permissions
sudo chmod 666 /dev/video*

# Option 3: Run container with privileged mode (already done in compose file)
```

### Issue 3: v4l-utils not working in container
**Symptoms:** `v4l2-ctl` commands fail inside container
**Solution:** Rebuild the image to ensure v4l-utils is properly installed

### Issue 4: Container running as non-root user
**Symptoms:** Permission errors even with privileged mode
**Solution:** Temporarily run as root user by modifying the Dockerfile

### Issue 5: Wrong docker-compose file being used
**Symptoms:** Image not found or wrong configuration
**Solution:** Make sure you're using the correct docker-compose file with the right image name

## Fixed Docker Compose Configuration

Make sure your `docker-compose.yml` on the remote server looks like this:

```yaml
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
    user: root  # Add this line to run as root if permission issues persist

networks:
  camera-network:
    driver: bridge
```

## Testing Camera Detection Logic

You can test the camera detection logic directly:

```bash
# Test camera detection manually
docker exec usb-camera-streamer python3 -c "
import subprocess
import os

# Check if video devices exist
for i in range(10):
    device = f'/dev/video{i}'
    if os.path.exists(device):
        print(f'Found device: {device}')
        try:
            result = subprocess.run(['v4l2-ctl', '--device', device, '--info'], 
                                  capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                print(f'Device {device} is accessible')
                print(result.stdout[:200])
            else:
                print(f'Device {device} error: {result.stderr}')
        except Exception as e:
            print(f'Exception for {device}: {e}')
    else:
        print(f'Device {device} does not exist')
"
```

## Next Steps Based on Results

1. **If no video devices exist on host:** Connect USB camera and check `lsusb`
2. **If devices exist but not accessible in container:** Check permissions and privileged mode
3. **If devices accessible but v4l2-ctl fails:** Check if v4l-utils is properly installed
4. **If v4l2-ctl works but API returns empty:** Check application logs for Python errors
5. **If all works but frontend shows no cameras:** Check browser network tab for API call failures
