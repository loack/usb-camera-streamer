#!/bin/bash

echo "🔍 USB Camera Debugging Script"
echo "=============================="

echo ""
echo "1. 📹 Checking video devices on host system:"
ls -la /dev/video* 2>/dev/null || echo "❌ No video devices found on host"

echo ""
echo "2. 🐳 Checking if container is running:"
docker ps --filter name=usb-camera-streamer

echo ""
echo "3. 📝 Container logs (last 20 lines):"
docker logs --tail 20 usb-camera-streamer 2>/dev/null || echo "❌ Container not running or no logs"

echo ""
echo "4. 🔧 Checking video devices inside container:"
docker exec usb-camera-streamer ls -la /dev/video* 2>/dev/null || echo "❌ No video devices accessible in container"

echo ""
echo "5. 🛠️ Checking v4l-utils in container:"
docker exec usb-camera-streamer v4l2-ctl --list-devices 2>/dev/null || echo "❌ v4l2-ctl not available or no devices"

echo ""
echo "6. 🧪 Testing camera detection API:"
curl -s http://localhost:5000/api/cameras | python3 -m json.tool 2>/dev/null || echo "❌ Could not reach camera API"

echo ""
echo "7. 📊 Container resource usage:"
docker stats --no-stream usb-camera-streamer 2>/dev/null || echo "❌ Container not running"

echo ""
echo "8. 🔍 USB devices on host:"
lsusb | grep -i camera || lsusb | grep -i video || echo "❌ No USB cameras found"

echo ""
echo "9. 🐧 Kernel modules:"
lsmod | grep uvc || echo "⚠️ UVC driver not loaded"
