# W1 Memory Model Smoke Validation

Date: 2026-08-18

## Source and ABI checks

- Model source: OpenTenBase bundled pgvector 0.8.0.
- Allocation source: `src/ivfkmeans.c:277-299`.
- Sampling source: `src/ivfbuild.c:403-415`.
- ABI verifier: `tools/verify_ivfflat_sizes.c` compiled with the same OpenTenBase
  macros and include paths as `src/ivfutils.o`.
- Verified constants: `VectorArrayData=32`, vector header `=8`, maximum alignment
  `=8`, aligned 128-dimensional vector item `=520` bytes.

## SQL smoke results

The updated delivery patch applied cleanly into an empty tree and produced a
292-line combined diagnostics SQL file with SHA256:

```text
599c853419fd00ad8169121a76cac225e8a1121a2b02e17713cb71c5996f784f
```

| rows | dims | lists | total bytes | total MiB | required MB |
|---:|---:|---:|---:|---:|---:|
| 100000 | 128 | 100 | 9,476,496 | 9.037 | 10 |
| 100000 | 128 | 1000 | 231,964,096 | 221.218 | 222 |
| 200000 | 384 | 8192 | 7,494,036,064 | 7,146.870 | 7,147 |

For `100000/128/1000`, `ivfflat_memory_breakdown()` returned exactly 11 rows
whose sum was 231,964,096 bytes. The largest allocations were
`lowerBoundSize=200,000,000`, `samplesSize=26,000,032`, and
`halfcdistSize=4,000,000` bytes.

## Actual pgvector error check

A 1000-row, 128-dimensional replicated table was created inside a transaction
with `lists=1000` and `maintenance_work_mem=1MB`.

```text
predicted_required_mb = 34
ERROR: memory required is 34 MB, maintenance_work_mem is 1 MB
```

The negative test intentionally returned a nonzero status. After the connection
closed, `to_regclass('public.memory_probe_w1') IS NULL` returned true, confirming
that the test transaction was rolled back.

## Combined delivery patch check

The 292-line SQL restored from the delivery patch was loaded in an OpenTenBase
transaction. Schema versions 1 and 2 were present, the diagnostic function kept
its `check_name/status/detail/recommendation` output contract, and the inventory
view executed successfully. For the 34 MB case, `1MB` returned `risk`; the bare
PostgreSQL GUC value `65536` was parsed as 64 MB and returned `ok`. The transaction
ended with `ROLLBACK`.

## Verdict

The first source-derived model smoke is supported for the tested `vector` case.
This is one real error comparison, not the W2 accuracy matrix; no claim of less
than 5% error across the parameter space is made yet.
