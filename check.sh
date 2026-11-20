#!/bin/bash
#
# ./check.sh
#
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "Compare hashes!"
sha256sum www/case20.txt export/case20.txt
