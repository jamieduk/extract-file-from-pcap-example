#!/bin/bash
# (c) J~Net 2026
#
# ./stop-server.sh
#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PIDFILE="$SCRIPT_DIR/server.pid"

if [[ ! -f "$PIDFILE" ]]; then
    echo "[INFO] No server PID file found."
    exit 0
fi

srv=$(cat "$PIDFILE")

if [[ "$srv" =~ ^[0-9]+$ ]] && kill -0 "$srv" 2>/dev/null; then
    kill "$srv"
    echo "[OK] HTTP server stopped."
else
    echo "[INFO] HTTP server is not running."
fi

/usr/bin/rm -f "$PIDFILE"

