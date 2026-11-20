
#!/bin/bash
# (c) J~Net 2026
#
# ./read.sh
#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE="$SCRIPT_DIR/evidence.pcapng"
ORIGINAL="$SCRIPT_DIR/www/case20.txt"
EXPORT="$SCRIPT_DIR/export"

# Check dependencies.
if ! command -v tshark >/dev/null 2>&1; then
    echo "[ERROR] tshark is not installed."
    exit 1
fi

# Check capture exists.
if [[ ! -f "$CAPTURE" ]]; then
    echo "[ERROR] evidence.pcapng not found."
    echo "[INFO] Run ./capture.sh first."
    exit 1
fi

mkdir -p "$EXPORT"

echo
echo "========== CAPTURED HTTP TRAFFIC =========="
echo

tshark -r "$CAPTURE" \
    -d tcp.port==8870,http \
    -Y http \
    -T fields \
    -e frame.number \
    -e http.request.uri \
    -e http.response.code

echo
echo "========== EXTRACTING HTTP OBJECTS =========="
echo

tshark -r "$CAPTURE" \
    -d tcp.port==8870,http \
    --export-objects "http,$EXPORT" \
    -q

echo "[OK] HTTP extraction complete."

# Check extracted file.
EXTRACTED="$EXPORT/case20.txt"

if [[ ! -f "$ORIGINAL" || ! -f "$EXTRACTED" ]]; then
    echo "[ERROR] Original or extracted file is missing."
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

