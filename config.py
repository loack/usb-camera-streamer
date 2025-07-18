# USB Camera Streamer Configuration

# Flask Application Settings
FLASK_HOST = "0.0.0.0"
FLASK_PORT = 5000
FLASK_DEBUG = False

# ustreamer Settings
USTREAMER_HOST = "0.0.0.0"
USTREAMER_PORT = 8080
USTREAMER_WORKERS = 2
USTREAMER_QUALITY = 80

# Default Stream Settings
DEFAULT_WIDTH = 640
DEFAULT_HEIGHT = 480
DEFAULT_FPS = 30
DEFAULT_FORMAT = "MJPEG"

# Camera Detection Settings
MAX_CAMERA_CHECK = 10  # Check /dev/video0 to /dev/video9
CAMERA_CHECK_TIMEOUT = 5  # Timeout in seconds for camera detection

# Logging Settings
LOG_LEVEL = "INFO"
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
