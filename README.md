# USB Camera Streamer

A containerized web application for managing USB camera streaming using ustreamer. Built with Flask, Python, and Alpine Linux for lightweight deployment.

## Features

- **Camera Discovery**: Automatically detects and lists available USB cameras
- **Web Interface**: Easy-to-use web interface for camera management
- **Flexible Settings**: Configure resolution, FPS, and video format
- **Real-time Streaming**: Live video streaming via ustreamer
- **REST API**: Full API for programmatic control
- **Containerized**: Docker support for easy deployment
- **Lightweight**: Alpine Linux base for minimal resource usage

## Quick Start

### Prerequisites

- Docker and Docker Compose
- USB cameras connected to the host system
- Linux host (for USB device access)

### Run with Docker Compose

1. Clone or download this project
2. Navigate to the project directory
3. Start the application:

```bash
docker-compose up -d
```

4. Open your web browser and go to: `http://localhost:5000`

### Manual Docker Build

```bash
# Build the image
docker build -t usb-camera-streamer .

# Run the container
docker run -d \
  --name usb-camera-streamer \
  --privileged \
  -p 5000:5000 \
  -p 8080:8080 \
  -v /dev:/dev \
  usb-camera-streamer
```

## Usage

### Web Interface

1. **Access the Control Panel**: Navigate to `http://localhost:5000`
2. **Select Camera**: Choose from available USB cameras
3. **Configure Settings**: 
   - Select video format (MJPEG, YUYV, H264)
   - Choose resolution (predefined or custom)
   - Set FPS (frames per second)
4. **Start Streaming**: Click "Start Stream"
5. **View Stream**: Click "View Stream" or go to `http://localhost:8080/stream`

### API Endpoints

#### Get Available Cameras
```http
GET /api/cameras
```

Returns a list of available USB cameras with their capabilities.

#### Start Stream
```http
POST /api/stream/start
Content-Type: application/json

{
  "device": "/dev/video0",
  "width": 1280,
  "height": 720,
  "fps": 30,
  "format": "MJPEG"
}
```

#### Stop Stream
```http
POST /api/stream/stop
```

#### Get Stream Status
```http
GET /api/stream/status
```

Returns current streaming status and settings.

## Configuration

### Video Devices

The application automatically detects USB cameras as `/dev/videoX` devices. Make sure your cameras are properly connected and recognized by the host system.

Check available devices:
```bash
ls -la /dev/video*
v4l2-ctl --list-devices
```

### Supported Formats

- **MJPEG**: Compressed video format, good for network streaming
- **YUYV**: Uncompressed format, higher quality but more bandwidth
- **H264**: Hardware-encoded format (if supported by camera)

### Common Resolutions

- 640x480 (VGA)
- 800x600 (SVGA)
- 1024x768 (XGA)
- 1280x720 (HD)
- 1920x1080 (Full HD)

## Development

### Local Development

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Install system dependencies (Ubuntu/Debian):
```bash
sudo apt-get update
sudo apt-get install v4l-utils ustreamer
```

3. Run the application:
```bash
python3 app.py
```

### Project Structure

```
usb-camera-streamer/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker image configuration
├── docker-compose.yml    # Docker Compose configuration
├── README.md            # This file
└── templates/           # HTML templates
    ├── index.html       # Main control panel
    └── stream.html      # Stream viewing page
```

## Troubleshooting

### Camera Not Detected

1. Check if the camera is recognized by the host:
```bash
lsusb | grep -i camera
ls -la /dev/video*
```

2. Verify camera permissions:
```bash
ls -la /dev/video0
# Should show read/write permissions
```

3. Test camera manually:
```bash
v4l2-ctl --device /dev/video0 --info
v4l2-ctl --device /dev/video0 --list-formats
```

### Stream Not Starting

1. Check container logs:
```bash
docker-compose logs usb-camera-streamer
```

2. Verify ustreamer process:
```bash
docker exec usb-camera-streamer ps aux | grep ustreamer
```

3. Test ustreamer manually:
```bash
docker exec -it usb-camera-streamer ustreamer --device /dev/video0 --host 0.0.0.0 --port 8080
```

### Permission Issues

The container runs in privileged mode to access USB devices. If you encounter permission issues:

1. Ensure the container has privileged access
2. Check that `/dev` is properly mounted
3. Verify USB device permissions on the host

### Network Issues

- Web interface: `http://localhost:5000`
- Video stream: `http://localhost:8080/stream`
- Check that ports 5000 and 8080 are not blocked by firewall

## Advanced Configuration

### Multiple Cameras

To support more cameras, add additional device mappings in `docker-compose.yml`:

```yaml
devices:
  - /dev/video0:/dev/video0
  - /dev/video1:/dev/video1
  - /dev/video2:/dev/video2
  # Add more as needed
```

### Custom ustreamer Options

Modify the `start_stream` method in `app.py` to add custom ustreamer parameters:

```python
cmd = [
    'ustreamer',
    '--device', device,
    '--host', '0.0.0.0',
    '--port', '8080',
    '--resolution', f"{width}x{height}",
    '--desired-fps', str(fps),
    '--format', format.upper(),
    '--workers', '2',
    '--quality', '80',        # JPEG quality
    '--brightness', '50',     # Camera brightness
    '--contrast', '50'        # Camera contrast
]
```

### Environment Variables

You can configure the application using environment variables:

- `FLASK_HOST`: Flask host (default: 0.0.0.0)
- `FLASK_PORT`: Flask port (default: 5000)
- `USTREAMER_PORT`: ustreamer port (default: 8080)

## Security Considerations

- The application runs with privileged Docker access for USB device control
- No authentication is implemented - secure your network accordingly
- Consider using HTTPS in production environments
- Limit network access to trusted clients

## License

This project is provided as-is for educational and development purposes. Please respect camera privacy and applicable laws when using this software.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues, questions, or contributions, please refer to the project documentation or create an issue in the repository.
