# 状态管理（.novel-state.json）

> 校准闭环的持久化状态文件，记录当前校准进度与待办。

---

## Schema 版本

当前版本：**v1.0**

schema 变更时通过 `migrations/` 目录下的迁移脚本升级，旧版本 state 文件可平滑迁移到新版本。

---

## 完整字段定义

```jsonc
{
  // 必填字段
  "schema_version": "1.0",           // 字符串，当前 schema 版本号
  "calibration_samples": 0,          // 整数，已完成的 预测→复盘 闭环次数
  "created_at": "2026-05-19T10:00:00+08:00",  // ISO 8601，state 文件创建时间

  // 时间戳（nullable）
  "last_prediction_at": null,        // ISO 8601 或 null，最近一次写入预测的时间
  "last_retro_at": null,             // ISO 8601 或 null，最近一次完成复盘的时间
  "last_bump_at": null,              // ISO 8601 或 null，最近一次 rubric bump 的时间

  // 待办列表
  "pending_retros": [],              // 字符串数组，待复盘的作品标识（如书名或文件路径）

  // rubric 信息
  "rubric_version": "1.0",           // 字符串，当前使用的评分公式版本
  "rubric_dimensions": 9,            // 整数，评分维度数量

  // 可选扩展
  "active_works": [],                // 字符串数组，当前进行中的作品
  "notes": ""                        // 字符串，自由备注
}
```

---

## 字段语义

| 字段 | 类型 | 更新时机 | 说明 |
|------|------|----------|------|
| `schema_version` | string | 迁移时 | 不可手动修改，只有迁移脚本写入 |
| `calibration_samples` | int | 复盘完成时 +1 | 预测→发布→复盘 三步都完成才计数 |
| `created_at` | ISO 8601 | 仅创建时 | 一旦写入不再变更 |
| `last_prediction_at` | ISO 8601 \| null | 写入预测时 | 记录最新一次预测时间 |
| `last_retro_at` | ISO 8601 \| null | 复盘完成时 | 记录最新一次复盘时间 |
| `last_bump_at` | ISO 8601 \| null | rubric bump 时 | 记录最新一次公式升级时间 |
| `pending_retros` | string[] | 发布时追加，复盘时移除 | FIFO 顺序 |
| `rubric_version` | string | bump 时 | 与 rubric 定义文件中的版本号一致 |
| `rubric_dimensions` | int | bump 时 | 评分维度总数 |
| `active_works` | string[] | 立项时追加，归档时移除 | 当前活跃作品标识 |
| `notes` | string | 任意时刻 | 人工备注，不参与逻辑 |

---

## 读-改-写协议（Read-Modify-Write）

所有对 `.novel-state.json` 的修改必须遵循以下原子操作模式：

```
1. READ   — 读取当前文件全部内容并解析 JSON
2. MODIFY — 在内存中修改需要变更的字段
3. WRITE  — 将完整 JSON 写回文件（非追加，是全量覆盖）
```

### 规则

- **禁止部分写入**：不能只写某个字段而丢弃其他字段
- **禁止并发写入**：同一时刻只能有一个 Agent/进程修改 state 文件
- **读后即写**：读取和写入之间不应有长时间间隔或用户交互
- **写入前验证**：写入前 JSON 必须通过 schema 验证（至少确保必填字段存在）

### 原子写入模式

推荐使用临时文件 + 重命名的方式确保写入原子性：

```bash
# 伪代码
tmp=$(mktemp .novel-state.json.XXXXXX)
echo "$new_json" > "$tmp"
mv "$tmp" .novel-state.json
```

对于 Claude Code Agent，由于 Write 工具本身是原子的，直接使用 Write 工具覆写即可。但必须确保写入的是**完整** JSON，不是部分片段。

---

## 置信度层级

`calibration_samples` 数值对应以下置信度，由 `session-start.sh` 展示：

| 样本数 | 置信度 | 含义 |
|--------|--------|------|
| 0 | 极低 | 纪律训练期，预测主要为了建立习惯 |
| 1-2 | 低 | 方向参考，不可用于决策 |
| 3-5 | 偏低 | 有参考价值，可辅助判断 |
| 6-10 | 中 | 可辅助决策，rubric 开始收敛 |
| 11-20 | 较高 | rubric 趋稳，预测有实际指导意义 |
| 21+ | 高 | 数据驱动，可作为重要决策依据 |

---

## 初始化

首次使用时由 `init` 流程创建，最小可用的初始 state：

```json
{
  "schema_version": "1.0",
  "calibration_samples": 0,
  "created_at": "2026-05-19T10:00:00+08:00",
  "last_prediction_at": null,
  "last_retro_at": null,
  "last_bump_at": null,
  "pending_retros": [],
  "rubric_version": "1.0",
  "rubric_dimensions": 9,
  "active_works": [],
  "notes": ""
}
```

---

## 迁移

当 schema 需要变更时：

1. 在 `migrations/` 下新建迁移文件（如 `v1.0_to_v1.1.md`）
2. 迁移文件定义：新增/删除/重命名的字段、默认值、数据转换逻辑
3. 迁移必须幂等：运行两次结果一致
4. 迁移失败时停在当前版本，不前进
