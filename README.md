# 项目二：向量索引构建与诊断能力增强

## 任务定位

优化大规模向量数据下的索引构建体验，包括构建耗时、内存占用、低召回风险提示、参数推荐、进度观测和异常场景测试。

## 当前状态

已完成阶段性交付，并提交到 OpenTenBase-Packages：

- PR #28: `Add pgvector IVFFlat index diagnostics workflow`

## 交付物

```text
docs/pgvector-index-diagnostics-report.md
docs/pgvector-production-tuning-template.md
docs/pgvector-diagnostics-local-validation.txt
patches/pgvector-ivfflat-diagnostics-tools.patch
scripts/pgvector-index-diagnostics.sh
SOP.md
```

## 核心能力

- `diagnose_ivfflat_build(...)`
- `estimate_ivfflat_build_memory_mb(...)`
- `recommend_ivfflat_lists(...)`
- `ivfflat_index_inventory`
- 低内存、低 probes、高 probes、索引清单验证。

