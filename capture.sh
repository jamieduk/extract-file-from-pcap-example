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

# Check capture permissions.
if ! tshark -D >/dev/null 2>"$ERROR_LOG"; then
    echo "[ERROR] Cannot access packet capture interface."
    cat "$ERROR_LOG"
    echo "[INFO] Check dumpcap permissions."
    exit 1
fi

# Stop capture and apply permissions.
stop_capture() {
    [[ "$stopped" -eq 1 ]] && return
    stopped=1

    echo
    echo "[INFO] Stopping packet capture..."

    # Stop TShark cleanly.
    if [[ -n "$capture_pid" ]]; then
        kill -INT "$capture_pid" 2>/dev/null
        wait "$capture_pid"
        status=$?
        capture_pid=""
    else
        status=1
    fi

    # Set capture ownership and permissions.
    if [[ -f "$OUTPUT" ]]; then
        if ! chown "$(id -u):$(id -g)" "$OUTPUT" || ! chmod 644 "$OUTPUT"; then
            echo "[ERROR] Unable to set capture file permissions."
            exit 1
        fi

        echo "[OK] Capture stopped."
        echo "[OK] Saved: $OUTPUT"
        echo "[INFO] Size: $(du -h "$OUTPUT" | awk '{print $1}')"
        echo "[INFO] Permissions: $(stat -c '%U:%G %a' "$OUTPUT")"
    else
        echo "[ERROR] Capture file is missing."
        exit 1
    fi

    if [[ "$status" -ne 0 ]]; then
        echo "[WARNING] TShark returned exit code $status."
        cat "$ERROR_LOG"
    fi

    exit 0
}

# Handle CTRL+C and termination.
trap stop_capture INT TERM

# Remove old capture.
rm -f "$OUTPUT" "$ERROR_LOG"

# Start continuous capture.
echo "[INFO] Starting continuous packet capture..."

tshark -i "$INTERFACE" -f "tcp port $PORT" -w "$OUTPUT" 2>"$ERROR_LOG" &
capture_pid=$!

sleep 2

# Check capture process.
if ! kill -0 "$capture_pid" 2>/dev/null; then
    wait "$capture_pid"
    status=$?
    capture_pid=""

    echo "[ERROR] TShark exited (code $status)."
    cat "$ERROR_LOG"
    exit 1
fi

echo
echo "======================================"
echo "       HTTP PACKET CAPTURE"
echo "======================================"
echo
echo "[INFO] Interface: $INTERFACE"
echo "[INFO] Port: $PORT"
echo "[INFO] Output: evidence.pcapng"
echo
echo "Capture running continuously..."
echo
echo "Press S to stop capture."
echo "Press CTRL+C to stop capture."
echo

# Monitor capture and keyboard.
while true; do

    # Check TShark process.
    if ! kill -0 "$capture_pid" 2>/dev/null; then
        wait "$capture_pid"
        status=$?
        capture_pid=""

        echo "[ERROR] TShark exited (code $status)."
        cat "$ERROR_LOG"

        # Preserve permissions on any partial capture.
        if [[ -f "$OUTPUT" ]]; then
            chown "$(id -u):$(id -g)" "$OUTPUT"
            chmod 644 "$OUTPUT"
        fi

        exit 1
    fi

    # Check keyboard input.
    if read -rsn1 -t 0.5 key; then
        if [[ "$key" == "s" || "$key" == "S" ]]; then
            stop_capture
        fi
    fi

done

