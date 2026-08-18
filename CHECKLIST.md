# W0 Hardening Checklist

- [x] Archive the unmodified OpenTenBase TAP baseline and raw logs.
- [x] T2.0.1 remove or correct the nonexistent AI SOP deliverable.
- [x] T2.0.2 correct the local validation result path.
- [x] T2.0.3 describe historical PR #28 accurately.
- [x] T2.0.4 parse bare PostgreSQL memory values as kB.
- [x] T2.0.5 remove the unreachable mixed-case unit branch.
- [x] T2.0.6 validate every value interpolated into SQL.
- [x] T2.0.7 fix SQL function search paths and add schema version tracking.
- [x] T2.0.8 remove tracked agent configuration files.
- [x] Run shell syntax and malicious-input tests.
- [x] Validate the SQL patch structure and W0 static assertions.
- [x] Review the staged diff without adding unrelated untracked documents.

## W1 Memory Model

- [x] Translate all 11 `ivfkmeans.c` allocation quantities.
- [x] Translate `VECTOR_ARRAY_SIZE` with verified 32-byte header and 8-byte alignment.
- [x] Separate target sample capacity from actual sampled rows.
- [x] Preserve pgvector's `totalSize / MiB + 1` error-message rounding.
- [x] Run three SQL smoke configurations.
- [x] Match one real pgvector low-memory error exactly.
- [x] Document the derivation and first-result limitations.
- [x] Replace the deprecated formula in the delivery patch.
- [ ] Run the W2 20-case prediction-versus-error matrix.
- [~] Define the W2 20-case matrix and resource-aware validation harness (`tools/validate_memory_model.sh`).
- [x] Add database-independent matrix self-test for case count and source-derived values.
- [ ] Capture OpenTenBase backend stderr for all 20 cases and verify error below 5%.
