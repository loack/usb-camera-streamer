#!/bin/bash

# Development setup script

echo "Setting up development environment..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Please install pip3 first."
    exit 1
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

# Check if v4l-utils is installed
if ! command -v v4l2-ctl &> /dev/null; then
    echo "v4l-utils is not installed. Installing..."
    
    # Detect OS and install accordingly
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y v4l-utils ustreamer
        elif command -v yum &> /dev/null; then
            sudo yum install -y v4l-utils ustreamer
        elif command -v pacman &> /dev/null; then
            sudo pacman -S v4l-utils ustreamer
        else
            echo "Please install v4l-utils and ustreamer manually for your distribution"
        fi
    else
        echo "Please install v4l-utils and ustreamer manually for your OS"
    fi
fi

# List available cameras
echo ""
echo "Available cameras:"
ls -la /dev/video* 2>/dev/null || echo "No video devices found"

echo ""
echo "Development environment setup complete!"
echo "Run 'python3 app.py' to start the development server"
