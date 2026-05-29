#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

echo "Waiting for Android device (USB debugging must be ON)..."
for i in $(seq 1 120); do
  DEVICE=$(adb devices | awk '/\tdevice$/{print $1; exit}')
  if [[ -n "$DEVICE" && "$DEVICE" != emulator-* ]]; then
    echo "Found device: $DEVICE"
    adb -s "$DEVICE" reverse tcp:8000 tcp:8000 || true
    exec flutter run -d "$DEVICE" \
      --dart-define=API_BASE_URL=http://127.0.0.1:8000
  fi
  sleep 2
done
echo "No device found after 4 minutes."
exit 1
