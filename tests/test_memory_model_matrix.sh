#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ivfflat-matrix.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

MODE=model-only \
OUTPUT_DIR="$tmp_dir/data" \
REPORT_FILE="$tmp_dir/report.md" \
"$repo_dir/tools/validate_memory_model.sh" >/dev/null

csv="$tmp_dir/data/memory-model-matrix.csv"
[[ "$(wc -l < "$csv")" -eq 21 ]] || {
    printf 'not ok - expected 20 matrix rows\n'
    exit 1
}

awk -F, '
    NR == 1 { next }
    $1 == "old-fail-01" && $8 != 10 { exit 1 }
    $1 == "old-fail-02" && $8 != 506 { exit 1 }
    $1 == "old-fail-03" && $8 != 7147 { exit 1 }
    $1 == "old-fail-04" && $8 != 17459 { exit 1 }
    $12 != "blocked" { exit 1 }
    END { print "ok - model-only matrix has 20 blocked, non-fabricated rows" }
' "$csv"

grep -q 'G4 尚未判定' "$tmp_dir/report.md"
printf 'ok - blocked report keeps the G4 gate explicit\n'
