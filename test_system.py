#!/usr/bin/env python3
"""
Test script for USB Camera Streamer
"""

import subprocess
import requests
import time
import sys
import os

def test_system_dependencies():
    """Test if required system dependencies are available"""
    print("Testing system dependencies...")
    
    # Test v4l2-ctl
    try:
        result = subprocess.run(['v4l2-ctl', '--version'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print("✓ v4l2-ctl is available")
        else:
            print("✗ v4l2-ctl not working properly")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("✗ v4l2-ctl not found")
        return False
    
    # Test ustreamer
    try:
        result = subprocess.run(['ustreamer', '--help'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print("✓ ustreamer is available")
        else:
            print("✗ ustreamer not working properly")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("✗ ustreamer not found")
        return False
    
    return True

def test_camera_devices():
    """Test if camera devices are available"""
    print("\nTesting camera devices...")
    
    devices_found = []
    for i in range(10):
        device_path = f"/dev/video{i}"
        if os.path.exists(device_path):
            devices_found.append(device_path)
    
    if devices_found:
        print(f"✓ Found {len(devices_found)} video devices: {', '.join(devices_found)}")
        
        # Test first device
        try:
            result = subprocess.run(['v4l2-ctl', '--device', devices_found[0], '--info'], 
                                  capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                print(f"✓ {devices_found[0]} is accessible")
                return True
            else:
                print(f"✗ {devices_found[0]} not accessible")
                return False
        except subprocess.TimeoutExpired:
            print(f"✗ Timeout accessing {devices_found[0]}")
            return False
    else:
        print("✗ No video devices found")
        return False

def test_python_dependencies():
    """Test if Python dependencies are available"""
    print("\nTesting Python dependencies...")
    
    try:
        import flask
        print("✓ Flask is available")
    except ImportError:
        print("✗ Flask not found")
        return False
    
    try:
        import psutil
        print("✓ psutil is available")
    except ImportError:
        print("✗ psutil not found")
        return False
    
    try:
        import requests
        print("✓ requests is available")
    except ImportError:
        print("✗ requests not found")
        return False
    
    return True

def test_docker():
    """Test if Docker is available"""
    print("\nTesting Docker...")
    
    try:
        result = subprocess.run(['docker', '--version'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print("✓ Docker is available")
            print(f"  Version: {result.stdout.strip()}")
        else:
            print("✗ Docker not working properly")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("✗ Docker not found")
        return False
    
    try:
        result = subprocess.run(['docker-compose', '--version'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print("✓ Docker Compose is available")
            print(f"  Version: {result.stdout.strip()}")
        else:
            print("✗ Docker Compose not working properly")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("✗ Docker Compose not found")
        return False
    
    return True

def main():
    """Run all tests"""
    print("USB Camera Streamer - System Test")
    print("=" * 40)
    
    all_tests_passed = True
    
    # Test system dependencies
    if not test_system_dependencies():
        all_tests_passed = False
    
    # Test camera devices
    if not test_camera_devices():
        all_tests_passed = False
    
    # Test Python dependencies
    if not test_python_dependencies():
        all_tests_passed = False
    
    # Test Docker
    if not test_docker():
        all_tests_passed = False
    
    print("\n" + "=" * 40)
    if all_tests_passed:
        print("✓ All tests passed! System is ready for USB Camera Streamer.")
        return 0
    else:
        print("✗ Some tests failed. Please check the requirements.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
