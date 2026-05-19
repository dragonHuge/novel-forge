---
name: novel-publish
description: 轻量发布登记——标记作品已上架/已发布，更新元数据并加入待复盘队列。只动元数据，不动预测段。
argument-hint: [书名] [平台链接]
trigger: "已发布"/"已上传"/"publish"/"刚发了"/"上传完了"/"上架了"/"签约了"
allowed-tools: Read, Edit, Bash
---

# novel-publish — 发布登记

> **轻量动作，只更新元数据**。不修改预测段任何字符（immutability 原则），不做质量审核。
>
> 定位：在"预测"和"复盘"之间插入一个时间戳锚点——告诉系统"这本书从什么时候开始算 T+0"。

---

## 触发条件

用户说以下任一时路由到本 skill：

- "已发布" / "已上传" / "publish" / "刚发了" / "上传完了"
- "上架了" / "签约了"
- "已发布《XXX》" / "《XXX》上传完了 [链接]"

## 前置条件

1. `.novel-state.json` 存在 → 否则路由到 `/novel-init`
2. 用户提供了书名（或可从上下文推断）→ 否则反问

---

## 执行流程

### Step 1: 识别目标作品

从用户输入中提取：
- **书名**（必须）：匹配 `predictions/` 下的文件名（格式 `YYYY-MM-DD_<book-slug>.md`）
- **平台链接**（可选）：如果用户提供了 URL
- **平台**（可选）：从链接或上下文推断（fanqie / qidian / qimao / douban）

如果用户只说"已发布"没给书名 → 回复：
> 发布了哪本？给我书名或预测文件路径。

### Step 2: 查找预测文件

1. 在 `predictions/` 目录下搜索匹配的文件
2. 匹配逻辑：文件名含 book-slug **或** 文件内标题含用户给的书名

**如果找不到预测文件**：
> 没找到《{书名}》的预测文件。建议先跑 `/predict` 再发布——否则丢失校准机会。
>
> 是否继续登记发布？（只更新 state，不创建预测文件）

- 用户确认 → 跳过 Step 3，只执行 Step 4
- 用户取消 → 结束

### Step 3: 更新预测文件 header

在预测文件的 frontmatter 区域（`---` 上方）追加或更新以下字段：

```
**Published at**: {YYYY-MM-DD HH:mm}
**Platform URL**: {用户提供的链接，没有则写 "待补"}
**Platform**: {fanqie / qidian / qimao / douban / unknown}
```

**硬规则**：
- 只动 header 区域（`## 预测` 之前的部分）
- **绝不修改 `## 预测` 段及以下的任何内容**（immutability 原则 #1）
- 如果 header 已有 `Published at` 字段 → 提示"这本已经登记过发布了"，显示已有信息，问是否要更新

### Step 4: 更新 .novel-state.json

读取当前 state，更新以下字段：

```json
{
  "last_published_at": "2026-05-19T14:30:00+08:00",
  "pending_retros": [
    ...existing,
    {
      "prediction_file": "predictions/2026-05-15_book-slug.md",
      "published_at": "2026-05-19T14:30:00+08:00",
      "retro_eligible_at": "2026-05-26T14:30:00+08:00",
      "book_name": "书名",
      "platform": "fanqie"
    }
  ]
}
```

字段说明：
- `last_published_at`：当前 ISO 8601 时间戳
- `pending_retros`：追加新条目（不覆盖已有的）
- `retro_eligible_at`：published_at + RETRO_WINDOW_DAYS（默认 7 天，连载可能更长）

### Step 5: 输出确认

```
已登记《{书名}》发布。

- 发布时间：{YYYY-MM-DD HH:mm}
- 平台：{platform}
- 预测文件：{path}（已更新 header）
- 复盘窗口：T+7d（{retro_eligible_at}）

T+7 天后记得跑 `/retro《{书名}》` 复盘。
```

---

## RETRO_WINDOW_DAYS 规则

| 品类 | 默认复盘窗口 | 说明 |
|------|-------------|------|
| 超短篇 / 短篇完本 | 7 天 | 数据沉淀快 |
| 中篇完本 | 14 天 | 需要更长推荐周期 |
| 连载 | 30 天 | 追更数据需要 4 周才稳定 |

品类从预测文件的 `品类` 字段读取；读不到默认 7 天。

---

## 边界 & 拒绝

- **不修改预测段**：`## 预测` 以下的内容是 immutable，本 skill 不碰
- **不做质量审核**：不检查稿件质量、不给改稿建议（那是写作阶段的事）
- **不做复盘**：即使用户同时给了数据（"刚发了，追更率 15%"），也不在此做复盘。回复："数据记着了，但复盘要等 T+7d 数据稳定后跑 `/retro`。"
- **不创建预测文件**：如果没有预测文件，只登记 state，不补建预测（补建的话违反"盲预测"原则）
- **不重复登记**：同一本书如果 pending_retros 里已有且未复盘 → 提示已登记，问是否要更新发布时间

---

## 异常处理

| 场景 | 处理 |
|------|------|
| `.novel-state.json` 不存在 | 路由到 `/novel-init` |
| `predictions/` 目录不存在 | 警告 + 只更新 state |
| 预测文件已有 `## 复盘` 段且非空 | 这本已经复盘过了，不需要再登记发布 |
| 用户给的链接格式异常 | 照存，不校验链接有效性（用户可能给内部后台链接） |
| pending_retros 已有同名书 | 提示已登记，问用户是"更新发布时间"还是"取消" |

---

## 与其他 skill 的关系

| skill | 关系 |
|-------|------|
| novel-predict | publish 是 predict 的下游——先预测，再发布 |
| novel-retro | publish 把作品加入 pending_retros 队列，retro 从队列取出复盘 |
| novel-status | status 会显示 pending_retros 列表和各自的复盘倒计时 |
| novel-init | state 文件不存在时自动路由到 init |
