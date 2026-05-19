---
name: novel-predict
description: 校准闭环的核心动作——在发布前写一份 immutable 盲预测日志。预测一旦写完不可改，由 hook 强制保护。
trigger-words: "预测"/"predict"/"启动预测"/"写预测"
allowed-tools: Read, Write, Edit, Bash, Glob
---

# novel-predict

> 给即将发布的作品写一份 **immutable 盲预测**。
>
> 这是校准循环的核心动作：预测时不允许看到任何已发布后的表现数据。
> 写完后由 `hooks/prediction-immutability.sh` 强制保护 `## 预测` 段——任何 Agent 或人工均无法修改。

---

## 前置条件

1. `.novel-state.json` 必须存在。不存在 → 强制路由到 `/novel-init` 并终止当前流程
2. 作品目录下有 `创作设定.md`（含 `## 立项评分` 段）或 `outline.md` / `manuscript.md`
3. 对应作品尚无预测文件（`predictions/` 下无同名文件），否则提示已有预测存在

---

## 执行流程（6 阶段）

### Phase 0 — Blind Check（盲条件确认）

**必须先问用户**：

> 你是否已经看到过这部作品发布后的任何数据？（收藏数 / 阅读量 / 收入 / 签约结果 / 评论 / 排名）

- 用户回答 **"没有"** → 正常继续，header 标注 `预测时数据状态: blind`
- 用户回答 **"看过一些"** → 标注 `预测时数据状态: non_blind`，在 header 追加 `non_blind_reason: {用户说明}`
- 用户回答 **含糊** → 追问一次，仍含糊则标注 `non_blind`

**参考**：[shared-references/blind-prediction-protocol.md](../../shared-references/blind-prediction-protocol.md) 完整定义了什么打破盲、什么不打破盲。

---

### Phase 1 — Read Work Info（读取作品信息）

按顺序读取以下文件（存在才读）：

1. `创作设定.md` → 提取 `## 立项评分` 段的分数和维度明细
2. `novels/<book-slug>/meta.json` → 品类、题材、字数、目标平台
3. `novels/<book-slug>/outline.md` 或 `manuscript.md` → 了解核心卖点与结构
4. 质量审核报告（如 `novels/<book-slug>/quality-review.md`）→ 参考第三方审阅意见
5. 合规检查报告（如 `novels/<book-slug>/compliance-check.md`）→ 参考平台规则适配
6. `.novel-state.json` → 取 `calibration_samples` 和 `rubric_version`

---

### Phase 2 — Reasoning（推理打分）

对 **7+2 维度** 逐一打分（1-5 分）并给出一句话理由：

**7 维度（来自当前 rubric）**：

1. 标题点击感
2. 开局炸裂度
3. 情绪强度
4. 反转空间
5. 30% 试读卡点
6. 独特性
7. 题材匹配度

**+2 附加维度**：

8. 市场时机 — 当前平台/品类是否处于红利期或饱和期
9. 题材热度 — 该题材近期的平台推荐力度与读者搜索趋势

**锚点对比**：

从 `predictions/` 目录中找 2-4 部已有预测（优先有复盘数据的），作为对照：
- 品类相同或相近
- 立项评分接近（±5 分范围内）
- 有复盘数据的优先（可看预测 vs 实际偏差方向）

如果 `predictions/` 为空（首次预测），锚点对比段留空并注明"无历史锚点"。

---

### Phase 3 — Generate Prediction（生成预测）

使用 `templates/prediction.template.md` 模板填充所有字段。

**核心预测组件**：

| 组件 | cold-start（样本 < 3） | calibration（样本 >= 3） |
|------|------------------------|--------------------------|
| 签约概率 | 只给 yes/no | yes/no + 概率百分比 |
| 首周收藏 | 不预测 | 区间（如 500-1200） |
| 收入档位 | 只给一个档位 | S/A/B/C/D 概率分布 |
| 反事实场景 | 简化（1 句） | 完整（3 场景） |
| 锚点对比 | 留空或 1 条 | 2-4 条 |

**Cold-start 简化规则**（`calibration_samples == 0` 时）：

- 在预测文件 header 追加 `notice: 纪律训练期——本次预测以建立习惯为目的，置信度极低`
- 核心预测简化为：签约 yes/no + 收入档位（单选，无概率分布）
- 首周收藏、反事实场景可省略
- 仍必须填写推理因素表和一句话理由（这是训练判断力的核心）

**置信度计算**（基于 `calibration_samples`）：

| 样本数 | 置信度标签 |
|--------|-----------|
| 0 | 极低 |
| 1-2 | 低 |
| 3-5 | 偏低 |
| 6-10 | 中 |
| 11-20 | 较高 |
| 21+ | 高 |

---

### Phase 4 — User Review（用户审阅）

将完整预测草稿展示给用户，要求明确回复：

- **"ok"** / **"没问题"** → 进入 Phase 5
- **字段级修正** → 记录用户修改了哪些字段，在 header 中标注 `User Override: {修改的字段列表}`
- **重大分歧**（如用户认为应该 S 档但 AI 预测 C 档）→ 记录双方理由，最终以用户决定为准，header 标注 `User Override: 收入档位 (AI: C → User: S, reason: {用户理由})`

**禁止**：用户在此阶段透露已看到的实际数据来修正预测。如果用户说"我看到收藏已经有 xxx 了"→ 预测作废，标记 `non_blind`。

---

### Phase 5 — Write & Lock（写入并锁定）

1. **生成文件名**：`predictions/YYYY-MM-DD_《书名》.md`
   - 日期为当天（预测写入日）
   - 书名取 `meta.json` 中的 title 字段

2. **写入预测文件**：使用 Write 工具写入完整内容

3. **更新 .novel-state.json**（Read-Modify-Write 原子操作）：
   ```jsonc
   {
     "last_prediction_at": "当前 ISO 8601 时间",
     "last_prediction_file": "predictions/YYYY-MM-DD_《书名》.md",
     "pending_retros": [...existing, "《书名》"]  // 追加
   }
   ```

4. **输出提醒**：
   > 预测已锁定。下一步：
   > 1. 发布后跑 `/novel-publish` 登记发布元数据
   > 2. T+7 天后（短篇）或 T+30 天后（连载）跑 `/novel-retro` 复盘

---

## Refusals（必须拒绝的场景）

| 场景 | 拒绝理由 |
|------|----------|
| 用户要求"帮我预测但我先告诉你数据" | 违反盲预测协议——看到数据后只能写复盘 |
| 用户要求修改已存在的预测文件 | `## 预测` 段 immutable，hook 层强制保护 |
| 用户没有任何作品信息就要预测 | 无输入无法打分——先完成立项和大纲 |
| 用户说"随便预测一下，不用太认真" | 拒绝。每次预测都是校准样本，必须认真对待 |
| `.novel-state.json` 不存在 | 路由到 `/novel-init`，不自行创建 state 文件 |

---

## 边界情况

### 重做预测（_redo.md）

当作品在预测后发生**重大变更**（如推翻大纲重写、更换核心题材）时：

1. 原预测文件保持不动（hook 强制）
2. 创建新文件：`predictions/YYYY-MM-DD_《书名》_redo.md`
3. Header 追加：`redo_reason: {原因}` + `original_file: {原文件路径}`
4. 正常执行 Phase 0-5

**不合法的重做理由**：
- "预测写低了想改高" → 不允许
- "看到数据不好想调低" → 盲已破，预测作废
- "觉得写得不详细" → 在 `## 复盘` 段补充

### 同一作品多次预测

一部作品只允许一份预测文件（或一份 `_redo.md`）。如果 `predictions/` 下已有同名文件：
- 提示用户已有预测存在
- 如果是合法重做场景 → 走 `_redo.md` 流程
- 如果不是 → 拒绝

---

## 与其他模块的关系

| 模块 | 关系 |
|------|------|
| `/novel-init` | 前置依赖——state 文件由 init 创建 |
| `/novel-score` | 可选前置——如果已有打分可直接引用，无需重新打分 |
| `/novel-publish` | 下游——发布后登记元数据 |
| `/novel-retro` | 下游——复盘时以本预测为对照基准 |
| `/novel-bump` | 间接——当 `consecutive_directional_errors >= 3` 时 retro 会建议 bump |
| `hooks/prediction-immutability.sh` | 强制层——保护 `## 预测` 段不可修改 |

---

## 输出示例（cold-start）

```markdown
# 《末世囤货：全球崩坏我无敌》 — 发布预测

**Work ID**: a3f2c9b1e8d0
**品类**: 中短篇
**题材**: 末世生存
**关联文件**: novels/moshi-tun/创作设定.md
**立项评分**: 27/35
**Rubric Version**: v1.0
**预测时间**: 2026-05-19
**校准样本数**: 0
**置信度**: 极低
**Scored By**: claude
**User Override**: none
**预测时数据状态**: blind
**notice**: 纪律训练期——本次预测以建立习惯为目的，置信度极低

---

## 预测

### 核心预测

- **签约通过**: yes
- **收入档位**: B

### 一句话理由

末世囤货题材热度稳定 + 开篇死局设计强，但独特性一般（同期 3 本相似设定），中枢判断签约无悬念但收入难破 A 档。

...
```
