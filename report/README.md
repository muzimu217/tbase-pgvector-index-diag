# 项目二技术报告

本目录是“OpenTenBase pgvector 向量索引构建与诊断能力增强”的报告源文件。最终 PDF 必须以 SQL、验证脚本、固定矩阵、原始 stderr 和 SHA256 清单为真相源。

## 当前状态

- 报告骨架：十章已建立。
- 初稿：`01-摘要.md`、`02-背景与任务对齐.md` 已完成。
- 核心门禁：G4（内存模型）和 G10（零参数目录审计）已通过。
- 下一步：从 `docs/04-数据与图表/memory-model-matrix.csv` 生成图表，并补充 W3 构建耗时证据后排版 PDF。

## 章节与证据绑定

| 章节 | 主要证据 | 状态 |
|---|---|---|
| 01 摘要 | `docs/03-技术文档/预测与实测验证矩阵.md`、CSV、审计日志 | 初稿 |
| 02 背景与任务对齐 | `PLAN.md`、`README.md`、W0/W1/W2 文档 | 初稿 |
| 03 环境与可复现声明 | `tests/README.md`、远端记录、SHA256SUMS | 骨架 |
| 04 方法学 | `sql/02_memory_model.sql`、`tools/validate_memory_model.sh` | 骨架 |
| 05 实现与架构 | `sql/04_catalog_introspect.sql`、`sql/05_audit.sql` | 骨架 |
| 06 实验设计 | `tests/memory-model-matrix.tsv`、W2 harness | 骨架 |
| 07 结果与图表 | `memory-model-matrix.csv`、20 份 raw stderr、审计日志 | 骨架 |
| 08 局限与风险 | W2 分层说明、TAP README、`PLAN.md` | 骨架 |
| 09 贡献与后续计划 | G4/G10 证据、W3 待办 | 骨架 |
| 10 附录与复现命令 | `tests/README.md`、SQL 测试、验证脚本 | 骨架 |

## 写作边界

5 个 `real-threshold` 场景只证明阈值触发路径中的后端报错与模型一致，不是巨型索引已成功构建；`possible_seqscan` 是静态目录风险，不是 EXPLAIN 结果；HNSW 的 IVFFlat 专属字段保持空值；`reltuples` 是统计估计。

