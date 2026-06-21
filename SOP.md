# 项目二 SOP：向量索引构建与诊断能力增强

## 目标

让用户能发现“索引建得不合理、召回低、构建慢、内存不足、查询没走索引”等问题，并给出可执行优化建议。

## 阶段 1：复用项目一基线

输入项目一数据：

- recall/latency CSV。
- `EXPLAIN` plan。
- `lists/probes` 参数矩阵。
- 构建失败或低召回异常记录。

退出条件：至少有一组 L2/IP/Cosine benchmark 作为诊断经验来源。

## 阶段 2：诊断 SQL

必须提供：

```text
parse_memory_mb(text)
estimate_ivfflat_build_memory_mb(row_count,dims,lists)
recommend_ivfflat_lists(row_count,dims)
diagnose_ivfflat_build(row_count,dims,lists,probes,target_recall,maintenance_work_mem)
ivfflat_index_inventory
```

退出条件：低内存场景能返回 `risk`，合理配置能返回 `ok`。

## 阶段 3：诊断脚本

脚本必须支持：

```text
DBNAME
ROW_COUNT
DIMS
LISTS
PROBES
TARGET_RECALL
MAINTENANCE_WORK_MEM
SQL_FILE
```

退出条件：脚本能加载 SQL、执行诊断、列出 IVFFlat 索引清单。

## 阶段 4：异常场景

必须覆盖：

- `maintenance_work_mem` 过低。
- `probes/lists` 比例过低。
- `probes = lists` 延迟风险。
- 查询写法导致 IVFFlat 失效。
- 数据分布变化导致 recall 波动。

## 阶段 5：报告与模板

交付：

- 诊断报告。
- 生产调优模板。
- 本地验证记录。
- OpenTenBase 实库验证记录。

## 禁止事项

- 禁止把 heuristic 推荐写成确定性能保证。
- 禁止没有风险等级的参数推荐。
- 禁止忽略构建失败信息。
- 禁止只给 SQL，不给使用命令。

