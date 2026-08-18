#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
for script in report/figures/scripts/0*.py; do python3 "$script"; done
if command -v pandoc >/dev/null 2>&1 && command -v xelatex >/dev/null 2>&1; then
  printf '%s\n' 'pandoc/xelatex detected; using the portable ReportLab builder for this repository.'
fi
PYTHON_BIN="${PYTHON_BIN:-python3}"
if [ -x "/Users/blackevil/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3" ] && [ -z "${PYTHON_BIN_OVERRIDE:-}" ]; then
  PYTHON_BIN="/Users/blackevil/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
fi
"$PYTHON_BIN" report/build_report.py
