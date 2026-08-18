#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
matrix_file="${MATRIX_FILE:-$repo_dir/tests/memory-model-matrix.tsv}"
output_dir="${OUTPUT_DIR:-$repo_dir/docs/04-数据与图表}"
csv_file="${CSV_FILE:-$output_dir/memory-model-matrix.csv}"
report_file="${REPORT_FILE:-$repo_dir/docs/03-技术文档/预测与实测验证矩阵.md}"
sql_file="${SQL_FILE:-$repo_dir/sql/02_memory_model.sql}"
mode="${MODE:-auto}"
max_real_rows="${MAX_REAL_ROWS:-100000}"
max_real_mb="${MAX_REAL_MB:-512}"
observed_log_dir="${OBSERVED_LOG_DIR:-}"

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 2
}

[[ -r "$matrix_file" ]] || fail "matrix file is not readable: $matrix_file"
mkdir -p "$output_dir" "$(dirname "$report_file")"

if [[ "$mode" != auto && "$mode" != model-only && "$mode" != real && "$mode" != indirect ]]; then
    fail "MODE must be auto, model-only, real, or indirect"
fi

psql_ready=0
if command -v psql >/dev/null 2>&1 && psql -X -Atqc 'SELECT 1' >/dev/null 2>&1; then
    psql_ready=1
fi

if [[ "$mode" == real && "$psql_ready" -ne 1 ]]; then
    fail "MODE=real requires a reachable PostgreSQL/OpenTenBase endpoint"
fi
if [[ "$mode" == indirect && "$psql_ready" -ne 1 && -z "$observed_log_dir" ]]; then
    fail "MODE=indirect requires a reachable endpoint or OBSERVED_LOG_DIR"
fi

if [[ "$mode" == auto ]]; then
    if [[ "$psql_ready" -eq 1 ]]; then
        effective_mode=real
    else
        effective_mode=model-only
    fi
else
    effective_mode="$mode"
fi

if [[ "$effective_mode" != model-only && ! -r "$sql_file" ]]; then
    fail "SQL_FILE is not readable: $sql_file"
fi

if [[ "$effective_mode" != model-only && "$psql_ready" -eq 1 ]]; then
    psql -X -v ON_ERROR_STOP=1 -f "$sql_file" >/dev/null
fi

printf 'case_id,rows,dims,lists,tier,validation_mode,sample_rows,predicted_mb,old_formula_mb,observed_mb,error_pct,status,notes\n' > "$csv_file"

awk -F '\t' -v mode="$effective_mode" -v csv="$csv_file" -v logs="$observed_log_dir" \
    -v maxrows="$max_real_rows" -v maxmb="$max_real_mb" \
    'BEGIN { OFS="," }
    function ceil(x, i) { i=int(x); return i + (x > i) }
    function aligned(x) { return int((x + 7) / 8) * 8 }
    function model_mb(rows, dims, lists, t, n, item, total) {
        t = lists * 50
        if (t < 10000) t = 10000
        n = (rows < t ? rows : t)
        item = aligned(8 + dims * 4)
        total = 32 + t * item
        total += 2 * (32 + lists * item)
        total += 4 * lists * dims
        total += 4 * lists
        total += 4 * n
        total += 4 * n * lists
        total += 4 * n
        total += 4 * lists
        total += 4 * lists * lists
        total += 4 * lists
        return int(total / 1048576) + 1
    }
    function old_mb(rows, dims, lists, vector, centroid, overhead) {
        vector = rows * dims * 4 / 1048576
        centroid = lists * dims * 4 / 1048576
        overhead = vector * 3 + lists * 0.05
        if (overhead < 32) overhead = 32
        return ceil(vector + centroid + overhead)
    }
    function observed(caseid,   file, line, mb) {
        if (logs == "") return ""
        file = logs "/" caseid ".log"
        while ((getline line < file) > 0) {
            if (match(line, /memory required is [0-9]+ MB/)) {
                mb = substr(line, RSTART, RLENGTH)
                sub(/^memory required is /, "", mb)
                sub(/ MB$/, "", mb)
                close(file)
                return mb
            }
        }
        close(file)
        return ""
    }
    NR == 1 { next }
    {
        caseid=$1; rows=$2+0; dims=$3+0; lists=$4+0; tier=$5
        predicted=model_mb(rows,dims,lists)
        old=old_mb(rows,dims,lists)
        target=(rows < (lists*50 > 10000 ? lists*50 : 10000) ? rows : (lists*50 > 10000 ? lists*50 : 10000))
        obs=observed(caseid)
        status="blocked"; note="no captured pgvector error; model-only run"
        validation=mode
        if (obs != "") {
            err=(obs-predicted)*100/predicted
            if (err < 0) err=-err
            status=(err < 5 ? "pass" : "fail")
            note="observed from " logs "/" caseid ".log"
        } else if (mode == "real" && rows <= maxrows && predicted <= maxmb) {
            note="eligible for real CREATE INDEX; run harness backend step"
        } else if (mode == "real" || mode == "indirect") {
            note="requires captured backend log; large case protected from OOM"
        }
        printf "%s,%d,%d,%d,%s,%s,%d,%d,%d,%s,%s,%s,%s\n", caseid,rows,dims,lists,tier,validation,target,predicted,old,obs,(obs==""?"":sprintf("%.4f",err)),status,note >> csv
    }' "$matrix_file"

if [[ "$effective_mode" == real && "$psql_ready" -eq 1 ]]; then
    run_log_dir="${observed_log_dir:-$output_dir/raw-memory-errors}"
    mkdir -p "$run_log_dir"

    while IFS=$'\t' read -r case_id rows dims lists tier; do
        [[ "$case_id" == case_id ]] && continue
        [[ "$rows" =~ ^[1-9][0-9]*$ && "$dims" =~ ^[1-9][0-9]*$ && "$lists" =~ ^[1-9][0-9]*$ ]] ||
            fail "invalid matrix row for $case_id"

        predicted="$(awk -F, -v id="$case_id" '$1==id {print $8}' "$csv_file")"
        if (( rows > max_real_rows || predicted > max_real_mb || predicted <= 1 )); then
            continue
        fi

        log_file="$run_log_dir/$case_id.log"
        [[ -s "$log_file" ]] && continue

        target=$((lists * 50))
        if (( target < 10000 )); then
            target=10000
        fi
        sample_rows="$rows"
        if (( sample_rows > target )); then
            sample_rows="$target"
        fi
        threshold=$((predicted - 1))

        set +e
        psql -X -v ON_ERROR_STOP=1 -d "${PGDATABASE:-postgres}" >"$log_file" 2>&1 <<SQL
CREATE EXTENSION IF NOT EXISTS vector;
DROP TABLE IF EXISTS pgvector_bench.w2_memory_case;
CREATE TABLE pgvector_bench.w2_memory_case (
    id bigint PRIMARY KEY,
    embedding vector(${dims}) NOT NULL
);
INSERT INTO pgvector_bench.w2_memory_case (id, embedding)
SELECT g, array_fill(0.001::real, ARRAY[${dims}])::vector
FROM generate_series(1, ${sample_rows}) AS s(g);
SET maintenance_work_mem = '${threshold}MB';
CREATE INDEX w2_memory_case_idx
ON pgvector_bench.w2_memory_case USING ivfflat (embedding vector_l2_ops)
WITH (lists = ${lists});
DROP TABLE pgvector_bench.w2_memory_case;
SQL
        psql_status=$?
        set -e

        observed="$(sed -nE 's/.*memory required is ([0-9]+) MB.*/\1/p' "$log_file" | head -n 1)"
        if [[ -n "$observed" ]]; then
            error_pct="$(awk -v a="$observed" -v b="$predicted" 'BEGIN{d=(a-b)*100/b;if(d<0)d=-d;printf "%.4f",d}')"
            if awk -v e="$error_pct" 'BEGIN{exit !(e < 5)}'; then
                status=pass
            else
                status=fail
            fi
            note="captured real CREATE INDEX stderr: $log_file"
        elif [[ "$psql_status" -eq 0 ]]; then
            status=fail
            error_pct=""
            note="CREATE INDEX unexpectedly succeeded below predicted threshold: $log_file"
        else
            status=blocked
            error_pct=""
            note="backend run failed without pgvector memory error: $log_file"
        fi

        awk -F, -v OFS=, -v id="$case_id" -v obs="$observed" -v err="$error_pct" \
            -v status="$status" -v note="$note" \
            'NR==1 || $1!=id {print; next} {$10=obs; $11=err; $12=status; $13=note; print}' \
            "$csv_file" > "$csv_file.tmp"
        mv "$csv_file.tmp" "$csv_file"
    done < "$matrix_file"
    observed_log_dir="$run_log_dir"
fi

pass_count="$(awk -F, 'NR>1 && $12=="pass" {n++} END{print n+0}' "$csv_file")"
blocked_count="$(awk -F, 'NR>1 && $12=="blocked" {n++} END{print n+0}' "$csv_file")"
fail_count="$(awk -F, 'NR>1 && $12=="fail" {n++} END{print n+0}' "$csv_file")"
case_count="$(awk -F, 'NR>1 {n++} END{print n+0}' "$csv_file")"
report_csv="${csv_file#$repo_dir/}"
report_logs="${observed_log_dir:-未提供}"
if [[ "$report_logs" == "$repo_dir"/* ]]; then
    report_logs="${report_logs#$repo_dir/}"
fi

{
    printf '# IVFFlat 预测与实测验证矩阵\n\n'
    printf '> 生成命令：`MODE=%s tools/validate_memory_model.sh`。\n\n' "$effective_mode"
    printf '## 当前状态\n\n'
    printf '%s 组配置；%s 组通过，%s 组失败，%s 组尚未取得后端报错原文。\n\n' "$case_count" "$pass_count" "$fail_count" "$blocked_count"
    if [[ "$blocked_count" -gt 0 ]]; then
        printf '**G4 尚未判定。** 本次运行没有把模型值当作实测值；需要在 OpenTenBase + pgvector 端点运行真实或间接阈值验证，并把每组的原始 stderr 放入 `OBSERVED_LOG_DIR/<case_id>.log`。\n\n'
    fi
    printf '## 分层方法\n\n'
    printf '%s\n' '- `small`/`saturated`：在资源上限内创建实际 IVFFlat 索引，`maintenance_work_mem` 设为预测值以下，捕获 pgvector 的 `memory required is X MB`。'
    printf '%s\n' '- `large`：默认不创建可能耗尽 3.7 GiB 开发机的索引；使用同一端点的阈值触发路径或预先归档的原始 stderr，单独标注为间接验证。'
    printf '%s\n\n' '- 误差定义：`abs(observed - predicted) / predicted * 100`；`<5%` 才计为通过。'
    printf '## 必含旧公式失效场景\n\n'
    printf '| 场景 | 新模型 MB | 旧公式 MB |\n|---|---:|---:|\n'
    awk -F, 'NR>1 && $1 ~ /^old-fail/ {printf "| %s / %sd / lists=%s | %s | %s |\n", $2,$3,$4,$8,$9}' "$csv_file"
    printf '\n> 口径核对：按当前仓库的 `ivfkmeans.c:277-299` 和 `VECTOR_ARRAY_SIZE` 逐项计算，100k/128d/lists=32768 为 17,459 MB。监督清单中曾写约 16,695 MB；该差异应在后端原始错误取得后再裁决，不能为了贴合预期值修改源码推导。\n'
    printf '\n## 结果文件\n\n- CSV：`%s`\n- 原始后端日志目录：`%s`\n' "$report_csv" "$report_logs"
} > "$report_file"

printf 'W2 matrix: %s cases, %s pass, %s fail, %s blocked\n' "$case_count" "$pass_count" "$fail_count" "$blocked_count"
printf 'CSV: %s\nReport: %s\n' "$csv_file" "$report_file"

if [[ "$fail_count" -gt 0 ]]; then
    exit 1
fi
