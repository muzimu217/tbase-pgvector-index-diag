#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
for script in report/figures/scripts/0*.py; do python3 "$script"; done
if command -v pandoc >/dev/null 2>&1 && command -v xelatex >/dev/null 2>&1; then
  printf '%s\n' 'pandoc/xelatex detected; using the portable ReportLab builder for this repository.'
fi
PYTHON_BIN="${PYTHON_BIN:-python3}"
"$PYTHON_BIN" report/build_report.py
