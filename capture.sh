#!/bin/bash
# (c) J~Net 2026
#
# ./capture.sh
#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PORT=8870
OUTPUT="$SCRIPT_DIR/evidence.pcapng"
capture_pid=""

# Check required tools.
for cmd in tshark curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Missing dependency: $cmd"
        exit 1
    fi
done

# Check HTTP server.
if ! curl -fsS "http://127.0.0.1:$PORT/case20.txt" -o /dev/null; then
    echo "[ERROR] HTTP server is not running."
    echo "[INFO] Run ./start-server.sh first."
    exit 1
fi

# Capture loopback HTTP traffic.
rm -f "$OUTPUT"

tshark -i lo -f "tcp port $PORT" -w "$OUTPUT" >/dev/null 2>&1 &
capture_pid=$!

sleep 1

if ! kill -0 "$capture_pid" 2>/dev/null; then
    echo "[ERROR] Unable to start packet capture."
    exit 1
fi

# Generate HTTP traffic.
echo "[INFO] Requesting test file..."

if ! curl -fsS "http://127.0.0.1:$PORT/case20.txt" -o /dev/null; then
    echo "[ERROR] HTTP request failed."
    kill -INT "$capture_pid" 2>/dev/null
    wait "$capture_pid" 2>/dev/null
    exit 1
fi

sleep 1

# Stop capture cleanly.
kill -INT "$capture_pid" 2>/dev/null
wait "$capture_pid" 2>/dev/null
capture_pid=""

echo "[OK] Packet capture saved: $OUTPUT"


