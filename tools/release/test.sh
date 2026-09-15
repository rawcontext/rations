#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
exec /usr/bin/python3 -m unittest discover -p '*_test.py'
