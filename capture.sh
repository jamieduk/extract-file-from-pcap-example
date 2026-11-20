
#!/bin/bash
# (c) J~Net 2026
#
# ./capture.sh
# Press S to stop capture or CTRL+C.
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

# Stop capture cleanly.
stop_capture() {
    if [[ -n "$capture_pid" ]] && kill -0 "$capture_pid" 2>/dev/null; then
        echo
        echo "[INFO] Stopping packet capture..."
        kill -INT "$capture_pid" 2>/dev/null
        wait "$capture_pid" 2>/dev/null
    fi

    capture_pid=""
    echo "[OK] Packet capture saved: $OUTPUT"
    exit 0
}

# Handle CTRL+C.
trap stop_capture INT TERM

# Start continuous capture.
rm -f "$OUTPUT"

echo "[INFO] Starting continuous packet capture..."
tshark -i lo -f "tcp port $PORT" -w "$OUTPUT" >/dev/null 2>&1 &
capture_pid=$!

sleep 1

if ! kill -0 "$capture_pid" 2>/dev/null; then
    echo "[ERROR] Unable to start packet capture."
    wait "$capture_pid"
    exit 1
fi

echo
echo "======================================"
echo " HTTP PACKET CAPTURE RUNNING"
echo "======================================"
echo
echo "[INFO] Interface: lo"
echo "[INFO] Port: $PORT"
echo "[INFO] Output: evidence.pcapng"
echo
echo "Access the test server or generate HTTP traffic."
echo
echo "Press S to stop capture."
echo "Press CTRL+C to stop capture."
echo

# Monitor keyboard input.
while true; do
    read -rsn1 -t 0.5 key

    if [[ "$key" == "s" || "$key" == "S" ]]; then
        stop_capture
    fi

    if ! kill -0 "$capture_pid" 2>/dev/null; then
        wait "$capture_pid"
        capture_pid=""
        echo "[ERROR] TShark stopped unexpectedly."
        exit 1
    fi
done

