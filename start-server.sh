#!/bin/bash
# (c) J~Net 2026
#
# ./start-server.sh
#
#
#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PORT=8870

mkdir -p "$SCRIPT_DIR/www" "$SCRIPT_DIR/export"

# Create fictional test file.
printf 'Synthetic Case 20: the backup code is fictional.\n' > "$SCRIPT_DIR/www/case20.txt"

# Prevent accidentally starting multiple servers.
if [[ -f "$SCRIPT_DIR/server.pid" ]] && kill -0 "$(cat "$SCRIPT_DIR/server.pid")" 2>/dev/null; then
    echo "[INFO] HTTP server is already running."
    exit 0
fi

# Start local HTTP server.
python3 -m http.server "$PORT" --bind 127.0.0.1 -d "$SCRIPT_DIR/www" > "$SCRIPT_DIR/server.log" 2>&1 &
srv=$!

echo "$srv" > "$SCRIPT_DIR/server.pid"

# Wait for server startup.
for ((i=0;i<10;i++)); do
    if curl -fsS "http://127.0.0.1:$PORT/case20.txt" -o /dev/null 2>/dev/null; then
        echo "[OK] HTTP server started."
        echo "[INFO] Address: http://127.0.0.1:$PORT/"
        echo "[INFO] PID: $srv"
        exit 0
    fi
    sleep 0.5
done

echo "[ERROR] HTTP server failed to start."
kill "$srv" 2>/dev/null
rm -f "$SCRIPT_DIR/server.pid"
exit 1

