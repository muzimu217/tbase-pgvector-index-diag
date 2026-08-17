# W0 Hardening Validation

Date: 2026-08-18

## Local checks

```bash
bash -n scripts/pgvector-index-diagnostics.sh
bash -n tests/test_input_validation.sh
tests/test_input_validation.sh
git apply --check --verbose patches/pgvector-ivfflat-diagnostics-tools.patch
```

The validation test rejected malformed values for `ROW_COUNT`, `DIMS`,
`LISTS`, `PROBES`, `TARGET_RECALL`, and `MAINTENANCE_WORK_MEM` before `psql`
could run. The required injection case `ROW_COUNT="1;drop table x"` exited with
status 2 and the message `ROW_COUNT must be a positive integer`.

The patch applied cleanly into an empty temporary tree and produced a 210-line
SQL file with SHA256:

```text
8344448a0769cb0c1177bc6b4d6ac86d526dd77e8047ea64c2c6bd9b7350f598
```

## OpenTenBase transaction check

The extracted SQL file was loaded through the Coordinator inside one explicit
transaction. All objects and test calls succeeded, and the transaction was
rolled back after inspection.

| Assertion | Result |
|---|---:|
| `parse_memory_mb('65536') = 64` | true |
| `parse_memory_mb('64MB') = 64` | true |
| `parse_memory_mb('1024kB') = 1` | true |
| Four diagnostic functions have a fixed trusted search path | true |
| Schema version row is `1 / W0 correctness and security hardening` | true |
| Transaction ended with `ROLLBACK` | true |

The run validates W0 correctness and security behavior only. It does not
validate the deprecated first-generation IVFFlat build-memory estimate; that
formula is replaced and measured separately in W1.

