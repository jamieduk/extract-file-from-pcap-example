#!/bin/bash
# (c) J~Net 2026
#
# ./read.sh
#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE="$SCRIPT_DIR/evidence.pcapng"
ORIGINAL="$SCRIPT_DIR/www/case20.txt"
EXPORT="$SCRIPT_DIR/export"
EXTRACTED="$EXPORT/case20.txt"
RUN_USER="$(id -un)"

# Check dependencies.
for cmd in tshark sha256sum cmp sudo; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Missing dependency: $cmd"
        exit 1
    fi
done

# Check capture exists.
if [[ ! -f "$CAPTURE" ]]; then
    echo "[ERROR] evidence.pcapng not found."
    echo "[INFO] Run ./capture.sh first."
    exit 1
fi

# Check original exists.
if [[ ! -f "$ORIGINAL" ]]; then
    echo "[ERROR] Original test file not found."
    exit 1
fi

# Check ownership and permissions.
if [[ ! -r "$CAPTURE" ]]; then
    echo "[ERROR] Current user cannot read evidence.pcapng."
    echo "[INFO] File owner: $(stat -c '%U:%G %a' "$CAPTURE")"
    exit 1
fi

mkdir -p "$EXPORT"

echo
echo "========== CAPTURED HTTP TRAFFIC =========="
echo

if ! sudo -u "$RUN_USER" tshark -r "$CAPTURE" \
    -d tcp.port==8870,http \
    -Y http \
    -T fields \
    -e frame.number \
    -e http.request.uri \
    -e http.response.code; then
    echo "[ERROR] Unable to read captured HTTP traffic."
    exit 1
fi

echo
echo "========== EXTRACTING HTTP OBJECTS =========="
echo

if ! sudo -u "$RUN_USER" tshark -r "$CAPTURE" \
    -d tcp.port==8870,http \
    --export-objects "http,$EXPORT" \
    -q; then
    echo "[ERROR] HTTP extraction failed."
    exit 1
fi

echo "[OK] HTTP extraction complete."

# Check extracted file.
if [[ ! -f "$EXTRACTED" ]]; then
    echo "[ERROR] Extracted file is missing."
    exit 1
fi

echo
echo "========== SHA256 VERIFICATION =========="
echo

sha256sum "$ORIGINAL" "$EXTRACTED"

echo
echo "========== FILE COMPARISON =========="
echo

if cmp -s "$ORIGINAL" "$EXTRACTED"; then
    echo "[OK] Files are identical."
    echo "[OK] Extraction successfully verified."
else
    echo "[ERROR] Files do not match."
    exit 1
fi

echo
echo "========== COMPLETE =========="

