#!/usr/bin/env python3
"""
USB Camera Streamer with ustreamer
A Flask web application to manage USB cameras and streaming
"""

import os
import subprocess
import json
import signal
from flask import Flask, render_template, request, jsonify, Response
from threading import Thread
import time
import re
import logging

# Import configuration
try:
    from config import *
except ImportError:
    # Default configuration if config.py doesn't exist
    FLASK_HOST = "0.0.0.0"
    FLASK_PORT = 5000
    FLASK_DEBUG = False
    USTREAMER_HOST = "0.0.0.0"
    USTREAMER_PORT = 8080
    USTREAMER_WORKERS = 2
    USTREAMER_QUALITY = 80
    DEFAULT_WIDTH = 640
    DEFAULT_HEIGHT = 480
    DEFAULT_FPS = 30
    DEFAULT_FORMAT = "MJPEG"
    MAX_CAMERA_CHECK = 10
    CAMERA_CHECK_TIMEOUT = 5
    LOG_LEVEL = "INFO"
    LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

# Configure logging
logging.basicConfig(level=getattr(logging, LOG_LEVEL), format=LOG_FORMAT)
logger = logging.getLogger(__name__)

app = Flask(__name__)

class CameraManager:
    def __init__(self):
        self.current_stream = None
        self.ustreamer_process = None
        self.stream_settings = {
            'device': '/dev/video0',
            'width': DEFAULT_WIDTH,
            'height': DEFAULT_HEIGHT,
            'fps': DEFAULT_FPS,
            'format': DEFAULT_FORMAT
        }
    
    def get_available_cameras(self):
        """List all available USB cameras"""
        cameras = []
        try:
            # List video devices
            for device_num in range(MAX_CAMERA_CHECK):  # Check video0 to videoN
                device_path = f"/dev/video{device_num}"
                if os.path.exists(device_path):
                    try:
                        # Get camera info using v4l2-ctl
                        result = subprocess.run([
                            'v4l2-ctl', '--device', device_path, '--info'
                        ], capture_output=True, text=True, timeout=CAMERA_CHECK_TIMEOUT)
                        
                        if result.returncode == 0:
                            # Parse camera name from output
                            lines = result.stdout.split('\n')
                            card_name = "Unknown Camera"
                            for line in lines:
                                if 'Card type' in line:
                                    card_name = line.split(':')[1].strip()
                                    break
                            
                            # Get supported formats and resolutions
                            formats = self.get_camera_formats(device_path)
                            
                            cameras.append({
                                'device': device_path,
                                'name': card_name,
                                'formats': formats
                            })
                    except subprocess.TimeoutExpired:
                        logger.warning(f"Timeout checking {device_path}")
                    except Exception as e:
                        logger.warning(f"Error checking {device_path}: {e}")
        except Exception as e:
            logger.error(f"Error listing cameras: {e}")
        
        return cameras
    
    def get_camera_formats(self, device_path):
        """Get supported formats and resolutions for a camera"""
        formats = []
        try:
            # Get pixel formats
            result = subprocess.run([
                'v4l2-ctl', '--device', device_path, '--list-formats'
            ], capture_output=True, text=True, timeout=5)
            
            pixel_formats = []
            if result.returncode == 0:
                lines = result.stdout.split('\n')
                for line in lines:
                    if 'Pixel Format' in line and "'" in line:
                        # Extract format like 'MJPG' from the line
                        match = re.search(r"'([^']+)'", line)
                        if match:
                            pixel_formats.append(match.group(1))
            
            # Get frame sizes for each format
            for fmt in pixel_formats:
                try:
                    result = subprocess.run([
                        'v4l2-ctl', '--device', device_path, 
                        '--list-framesizes', fmt
                    ], capture_output=True, text=True, timeout=5)
                    
                    resolutions = []
                    if result.returncode == 0:
                        lines = result.stdout.split('\n')
                        for line in lines:
                            if 'Size:' in line and 'x' in line:
                                # Extract resolution like "640x480"
                                match = re.search(r'(\d+)x(\d+)', line)
                                if match:
                                    width, height = match.groups()
                                    resolutions.append({
                                        'width': int(width),
                                        'height': int(height)
                                    })
                    
                    if resolutions:
                        formats.append({
                            'format': fmt,
                            'resolutions': resolutions
                        })
                except subprocess.TimeoutExpired:
                    continue
                except Exception as e:
                    logger.warning(f"Error getting frame sizes for {fmt}: {e}")
        
        except Exception as e:
            logger.error(f"Error getting formats for {device_path}: {e}")
        
        return formats
    
    def start_stream(self, device, width=DEFAULT_WIDTH, height=DEFAULT_HEIGHT, fps=DEFAULT_FPS, format=DEFAULT_FORMAT):
        """Start ustreamer with specified parameters"""
        self.stop_stream()
        
        try:
            # Update settings
            self.stream_settings.update({
                'device': device,
                'width': width,
                'height': height,
                'fps': fps,
                'format': format
            })
            
            # Build ustreamer command
            cmd = [
                'ustreamer',
                '--device', device,
                '--host', USTREAMER_HOST,
                '--port', str(USTREAMER_PORT),
                '--resolution', f"{width}x{height}",
                '--desired-fps', str(fps),
                '--format', format.upper(),
                '--workers', str(USTREAMER_WORKERS),
                '--quality', str(USTREAMER_QUALITY)
            ]
            
            logger.info(f"Starting ustreamer with command: {' '.join(cmd)}")
            
            # Start ustreamer process
            self.ustreamer_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                preexec_fn=os.setsid if hasattr(os, 'setsid') else None
            )
            
            # Wait a moment to check if it started successfully
            time.sleep(2)
            if self.ustreamer_process.poll() is None:
                self.current_stream = self.stream_settings.copy()
                logger.info("ustreamer started successfully")
                return True
            else:
                stdout, stderr = self.ustreamer_process.communicate()
                logger.error(f"ustreamer failed to start: {stderr.decode()}")
                return False
                
        except Exception as e:
            logger.error(f"Error starting stream: {e}")
            return False
    
    def stop_stream(self):
        """Stop the current ustreamer process"""
        if self.ustreamer_process:
            try:
                # Kill the process group to ensure all child processes are terminated
                if hasattr(os, 'killpg'):
                    os.killpg(os.getpgid(self.ustreamer_process.pid), signal.SIGTERM)
                else:
                    self.ustreamer_process.terminate()
                
                # Wait for process to terminate
                try:
                    self.ustreamer_process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    if hasattr(os, 'killpg'):
                        os.killpg(os.getpgid(self.ustreamer_process.pid), signal.SIGKILL)
                    else:
                        self.ustreamer_process.kill()
                
                logger.info("ustreamer stopped")
            except Exception as e:
                logger.error(f"Error stopping stream: {e}")
            finally:
                self.ustreamer_process = None
                self.current_stream = None
    
    def get_stream_status(self):
        """Get current stream status"""
        if self.ustreamer_process and self.ustreamer_process.poll() is None:
            return {
                'running': True,
                'settings': self.current_stream
            }
        else:
            return {
                'running': False,
                'settings': None
            }

# Initialize camera manager
camera_manager = CameraManager()

@app.route('/')
def index():
    """Main page"""
    return render_template('index.html')

@app.route('/api/cameras')
def api_cameras():
    """API endpoint to get available cameras"""
    cameras = camera_manager.get_available_cameras()
    return jsonify(cameras)

@app.route('/api/stream/start', methods=['POST'])
def api_start_stream():
    """API endpoint to start streaming"""
    data = request.get_json()
    
    device = data.get('device', '/dev/video0')
    width = int(data.get('width', 640))
    height = int(data.get('height', 480))
    fps = int(data.get('fps', 30))
    format = data.get('format', 'MJPEG')
    
    success = camera_manager.start_stream(device, width, height, fps, format)
    
    return jsonify({
        'success': success,
        'message': 'Stream started successfully' if success else 'Failed to start stream'
    })

@app.route('/api/stream/stop', methods=['POST'])
def api_stop_stream():
    """API endpoint to stop streaming"""
    camera_manager.stop_stream()
    return jsonify({
        'success': True,
        'message': 'Stream stopped'
    })

@app.route('/api/stream/status')
def api_stream_status():
    """API endpoint to get stream status"""
    status = camera_manager.get_stream_status()
    return jsonify(status)

@app.route('/stream')
def stream_page():
    """Stream viewing page"""
    return render_template('stream.html')

if __name__ == '__main__':
    # Cleanup on exit
    import atexit
    atexit.register(camera_manager.stop_stream)
    
    # Run Flask app
    app.run(host=FLASK_HOST, port=FLASK_PORT, debug=FLASK_DEBUG)
