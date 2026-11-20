
#!/bin/bash
# (c) J~Net 2026
#
# ./capture.sh
#
# Press S to stop capture.
# Alternatively press CTRL+C.
#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PORT=8870
INTERFACE="lo"
OUTPUT="$SCRIPT_DIR/evidence.pcapng"
ERROR_LOG="$SCRIPT_DIR/capture-error.log"
capture_pid=""
stopped=0

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

# Check capture interface.
echo "[INFO] Checking capture interface..."

if ! tshark -D >/dev/null 2>"$ERROR_LOG"; then
    echo "[ERROR] Unable to access capture interfaces."
    cat "$ERROR_LOG"
    exit 1
fi

# Stop capture cleanly.
stop_capture() {
    [[ "$stopped" -eq 1 ]] && return
    stopped=1

    echo
    echo "[INFO] Stopping packet capture..."

    if [[ -n "$capture_pid" ]]; then
        kill -INT "$capture_pid" 2>/dev/null
        wait "$capture_pid"
        status=$?
        capture_pid=""
    fi

    if [[ -s "$OUTPUT" ]]; then
        echo "[OK] Packet capture saved: $OUTPUT"
        echo "[INFO] Capture size: $(du -h "$OUTPUT" | awk '{print $1}')"
    else
        echo "[ERROR] Capture file is empty or missing."
    fi

    if [[ -s "$ERROR_LOG" ]]; then
        echo
        echo "[INFO] TShark diagnostic output:"
        cat "$ERROR_LOG"
    fi

    exit 0
}

# Handle CTRL+C and termination.
trap stop_capture INT TERM

# Prepare output files.
rm -f "$OUTPUT" "$ERROR_LOG"

# Start continuous capture.
echo "[INFO] Starting continuous packet capture..."

tshark -i "$INTERFACE" -f "tcp port $PORT" -w "$OUTPUT" 2>"$ERROR_LOG" &
capture_pid=$!

sleep 2

# Check whether TShark started.
if ! kill -0 "$capture_pid" 2>/dev/null; then
    wait "$capture_pid"
    status=$?
    capture_pid=""

    echo "[ERROR] TShark stopped unexpectedly (exit code $status)."
    cat "$ERROR_LOG"
    exit 1
fi

# Display capture information.
echo
echo "======================================"
echo "       HTTP PACKET CAPTURE"
echo "======================================"
echo
echo "[INFO] Interface: $INTERFACE"
echo "[INFO] Port: $PORT"
echo "[INFO] Output: evidence.pcapng"
echo
echo "Capture is running continuously."
echo
echo "You can now access the HTTP server:"
echo "http://127.0.0.1:$PORT/"
echo
echo "======================================"
echo " Press S to stop capture"
echo " Press CTRL+C to stop capture"
echo "======================================"
echo

# Monitor keyboard input and capture process.
while true; do

    # Check whether TShark is still running.
    if ! kill -0 "$capture_pid" 2>/dev/null; then
        wait "$capture_pid"
        status=$?
        capture_pid=""

        echo
        echo "[ERROR] TShark exited (code $status)."

        if [[ -s "$ERROR_LOG" ]]; then
            cat "$ERROR_LOG"
        fi

        exit 1
    fi

    # Read keyboard input.
    if read -rsn1 -t 0.5 key; then
        if [[ "$key" == "s" || "$key" == "S" ]]; then
            stop_capture
        fi
    fi

done

