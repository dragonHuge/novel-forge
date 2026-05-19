---
name: novel-status
description: novel-forge 状态看板。显示校准进度、待复盘、rubric 版本、下一步建议。纯只读，无副作用，任意时刻可调。
argument-hint:
allowed-tools: Read, Bash, Glob
---

# novel-status

> **定位**：只读状态看板。快速回答「我现在该做什么」。

## 触发词

- "状态" / "看板" / "status" / "calibration-status" / "我现在该做什么" / "进度"

## 前置条件

- `.novel-state.json` 必须存在（否则路由到 `/novel-init`）

---

## 执行流程

### Step 1：读取数据源

```bash
# 必读
Read .novel-state.json

# 扫描
Glob novels/*/outline.md        → 在写作品数
Glob novels/*/manuscript.md     → 在写短篇数
Glob archive/*/                 → 已完结作品数
Glob predictions/*.md           → 预测文件数
Glob predictions/*.md           → 含 "## 复盘" 段的文件数（有效校准样本）

# 可选
Read rubric_notes.md            → 提取当前版本号
Read candidates.md              → 选题池条目数
```

### Step 2：计算指标

| 指标 | 计算方式 |
|------|----------|
| calibration_samples | `.novel-state.json` 中的值 |
| confidence_tier | 0-2 → "cold-start" / 3-7 → "warming" / 8+ → "calibrated" |
| pending_retros | `.novel-state.json` 中的 `pending_retros` 数组 |
| retro_age | 每条 pending_retro 距今天数 |
| rubric_version | 从 `rubric_notes.md` 第一个 `## 当前版本：` 提取 |
| bump_suggested | `calibration_samples - calibration_samples_at_last_bump >= 5` |
| consecutive_errors | `.novel-state.json` 中 `consecutive_directional_errors` 长度 |
| novels_in_progress | novels/ 下的子目录数 |
| predictions_count | predictions/ 下 .md 文件数（不含 .gitkeep） |

### Step 3：输出看板

格式固定，紧凑输出，不超过 15 行正文：

```
========== novel-forge 状态看板 ==========

校准进度:  {calibration_samples} 样本 | 置信层: {confidence_tier}
rubric:    {rubric_version} {bump_suggested ? "| 建议升级" : ""}
连续偏差:  {consecutive_errors} 次 {>= 3 ? "| 需要关注" : ""}

在写作品:  {novels_in_progress} 部
预测文件:  {predictions_count} 份
选题池:    {candidates_count} 条

待复盘:
{pending_retros 为空 → "  (无)"}
{否则逐条列出 → "  - {book_slug} (已过 {age} 天)"}

最近动态:
  预测: {last_prediction_at || "从未"}
  发布: {last_published_at || "从未"}
  复盘: {last_retro_at || "从未"}

下一步: {next_action}
==========================================
```

### Step 4：下一步建议逻辑

按优先级从高到低，命中第一条即输出：

| 优先级 | 条件 | 建议 |
|--------|------|------|
| 1 | pending_retros 中有 age >= 7 天的条目 | 「有作品已过复盘窗口，建议运行 /novel-retro {slug}」 |
| 2 | consecutive_errors >= 3 | 「连续偏差 >= 3 次，建议运行 /novel-bump 检查 rubric 是否需要调整」 |
| 3 | bump_suggested = true | 「校准池增长 5+ 样本，可以考虑运行 /novel-bump 升级 rubric」 |
| 4 | novels_in_progress > 0 且 predictions_count == 0 | 「有在写作品但无预测记录，建议运行 /novel-predict」 |
| 5 | novels_in_progress == 0 且 candidates_count == 0 | 「空空如也，建议运行 /novel-seed 找选题，或 /novel-learn-from 导入对标」 |
| 6 | novels_in_progress == 0 且 candidates_count > 0 | 「选题池有 {n} 条待立项，建议挑一个开写」 |
| 7 | 其他 | 「一切正常，继续写作」 |

---

## 安全规则

- **纯只读**：不修改任何文件，不写入任何状态
- **不触发其他 skill**：只输出建议文案，不自动路由
- **容错**：缺失的文件/目录不报错，对应指标显示 0 或 "从未"
- **快速**：不执行网络请求，不调用外部模型，耗时应在 1 秒内

---

## Refusals

- 「帮我顺便把待复盘的都复盘了」 → 拒绝。status 是只读看板，复盘请单独调 /novel-retro
- 「修改一下 state 里的数据」 → 拒绝。不做任何写入

---

## 与其他 skill 的关系

- **被路由到**：用户说 "状态" / "status" 时由主 SKILL.md 路由到此
- **路由出去**：通过"下一步建议"引导用户到正确的下一个 skill
- **Hook 依赖**：`hooks/session-start.sh` 可在会话开始时自动调用本 skill 输出简要状态
