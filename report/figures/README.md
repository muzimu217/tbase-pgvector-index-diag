# Figure catalog

The three current report figures are generated from the local data snapshots below. Each output has an SVG vector file and a PNG preview. The audit TSV was captured from the authorized OpenTenBase endpoint with a rollback transaction; it includes the predicted build-memory and current `maintenance_work_mem` columns.

| Figure | Script | Data | Output |
|---|---|---|---|
| Formula comparison | `scripts/01_formula_log.py` | `data/memory_model_matrix.csv` | `output/01_formula_log.svg` |
| Error matrix | `scripts/02_error_matrix.py` | `data/memory_model_matrix.csv` | `output/02_error_matrix.svg` |
| Zero-parameter audit | `scripts/03_audit_table.py` | `data/audit-zero-param-full.tsv` | `output/03_audit_table.svg` |

Rebuild all three from the repository root with:

```bash
for script in report/figures/scripts/0*.py; do python3 "$script"; done
```

