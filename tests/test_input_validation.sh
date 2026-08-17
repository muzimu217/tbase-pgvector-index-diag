#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/scripts/pgvector-index-diagnostics.sh"

assert_rejected() {
    local name="$1"
    local value="$2"
    local expected="$3"
    local output
    local status

    set +e
    output="$(env PATH=/nonexistent "$name=$value" /bin/bash "$script" 2>&1)"
    status=$?
    set -e

    if [[ "$status" -ne 2 ]]; then
        printf 'not ok - %s exited %s instead of 2\n' "$name" "$status"
        return 1
    fi
    if [[ "$output" != *"$expected"* ]]; then
        printf 'not ok - %s returned unexpected error: %s\n' "$name" "$output"
        return 1
    fi

    printf 'ok - rejected invalid %s\n' "$name"
}

/bin/bash "$script" --help >/dev/null
printf 'ok - help path\n'

assert_rejected ROW_COUNT '1;drop table x' 'ROW_COUNT must be a positive integer'
assert_rejected DIMS '128 OR 1=1' 'DIMS must be a positive integer'
assert_rejected LISTS '-1' 'LISTS must be a positive integer'
assert_rejected PROBES '1);select 1;--' 'PROBES must be a positive integer'
assert_rejected TARGET_RECALL '0.9;select 1' 'TARGET_RECALL must be in (0, 1]'
assert_rejected MAINTENANCE_WORK_MEM "64MB';drop table x;--" 'MAINTENANCE_WORK_MEM must be a number'

printf 'All input validation tests passed.\n'
