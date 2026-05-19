---
name: novel-init
description: novel-forge 首次 onboarding 与项目脚手架创建。5 个问题建立创作者画像，然后生成完整项目结构。所有其他子 skill 在 .novel-state.json 不存在时自动路由到此。
argument-hint: [--force] (强制重新初始化，需确认覆盖)
allowed-tools: Bash, Read, Write, Edit, Glob
---

# novel-init

> **定位**：novel-forge 的入口 skill。首次使用时执行，创建项目脚手架并初始化状态文件。

## 触发词

- "初始化" / "init" / "首次使用" / "setup novel-forge" / "我是新用户"

## 前置条件

- 无（这是入口）
- 如果 `.novel-state.json` 已存在且未传 `--force`，提示「已初始化，如需重置请说 `init --force`」

---

## 执行流程

### Phase 1：创作者画像采集（5 问）

逐题问，不要一次全抛。每题等用户回答后再问下一题。

```
Q1: 你写什么品类？
    选项：短篇（0.8-8 万字）/ 中篇（8-15 万字）/ 长篇（15-50 万字）/ 超长篇（50-200 万字）/ 混合
    → 写入 state.novel_form

Q2: 你在哪个平台发？
    选项：番茄小说 / 起点中文网 / 七猫 / 豆瓣阅读 / 其他（请说明）
    → 写入 state.platform
    → 如果不是番茄，提示：当前内置 rubric 按番茄拟合，其他平台需要更多校准轮次

Q3: 你之前发过作品吗？
    是 → 追问：发了多少部？完结了几部？有数据吗（追更率/完读率/收入）？
         → 写入 state.published_count, state.has_historical_data
    否 → state.published_count = 0, state.has_historical_data = false

Q4: 你有对标作者或作品吗？
    是 → 记录对标信息，后续建议跑 /novel-learn-from
         → 写入 state.has_benchmarks = true
    否 → state.has_benchmarks = false
         → 建议：cold-start 期强烈建议至少找 1 个对标，作为初始信号源

Q5: 确认创建项目脚手架？
    → 展示将要创建的目录结构
    → 用户确认后执行 Phase 2
```

### Phase 2：创建脚手架

在**当前工作目录**下创建以下结构：

```bash
# 目录
mkdir -p novels/
mkdir -p archive/
mkdir -p predictions/
mkdir -p samples/

# 占位文件
touch predictions/.gitkeep
touch samples/.gitkeep
```

### Phase 3：生成配置文件

#### .novel-state.json

从 `templates/novel-state.template.json` 复制，填入：
- `initialized_at`: 当前 ISO 8601 时间戳
- `platform`: Q2 回答对应的值（fanqie / qidian / qimao / douban / other）
- `schema_version`: "1.0"
- 其余字段保持模板默认值

#### rubric_notes.md

从 `templates/rubric_notes.template.md` 复制，不做修改。

#### candidates.md

创建空选题池：

```markdown
# 选题池（candidates）

> 被 /novel-seed 和 /novel-learn-from 维护。
> 格式：每条一个 H2，含 composite 分 + 一句 rationale。

---

<!-- 运行 /novel-seed 或 /novel-learn-from 后这里会有内容 -->
```

#### .claude/settings.json

创建 Claude Code hook 注册（如果 `.claude/` 不存在则新建）：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "bash hooks/prediction-immutability.sh \"$TOOL_INPUT\""
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "bash hooks/score-immutability.sh \"$TOOL_INPUT\""
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "command": "bash hooks/session-start.sh"
      }
    ]
  }
}
```

> **注意**：hook 路径指向 novel-forge skill 安装位置的 `hooks/` 目录。如果 skill 安装在 `~/.claude/skills/novel-forge/`，则路径应为绝对路径。运行时检测实际安装位置并写入正确路径。

### Phase 4：.gitignore 追加

检查项目根目录 `.gitignore`，如果没有以下条目则追加：

```
.novel-cache/
content.db
```

### Phase 5：完成输出

输出创建摘要：

```
novel-forge 初始化完成

  品类: {form}
  平台: {platform}
  历史作品: {published_count} 部
  对标: {有/无}
  rubric 版本: v0（初始基线）
  模式: cold-start

下一步建议:
  {根据画像给出}
```

---

## 下一步建议逻辑

| 条件 | 建议 |
|------|------|
| has_benchmarks = true | 「建议立即运行 /novel-learn-from 导入对标作品，建立初始信号」 |
| has_historical_data = true | 「建议运行 /novel-learn-from 导入自己的历史作品，快速建立校准基线」 |
| 两者都没有 | 「建议先运行 /novel-seed 找一个选题开始，或找一个对标账号跑 /novel-learn-from」 |

---

## 安全规则

- **绝不覆盖已有文件**：如果目标文件已存在，跳过并告知用户（除非 `--force` 且用户已确认）
- **不写入 novels/ 内容**：init 只建骨架，不帮用户写任何创作内容
- **不假设题材**：Q1-Q4 必须等用户回答，不自行填默认值
- **中文交互**：所有问题和输出使用中文，技术术语保持英文

---

## Refusals

- 「帮我直接建好一本书的大纲」 → 拒绝。init 只建脚手架，创作内容不在本 skill 范围
- 「跳过问题直接初始化」 → 拒绝。画像信息影响后续所有 skill 的行为，不可跳过
- 「用我上一个项目的配置」 → 拒绝。每个项目独立初始化，不继承其他项目状态

---

## 与其他 skill 的关系

- **被路由到**：任何子 skill 检测到 `.novel-state.json` 不存在时自动重定向到 novel-init
- **路由出去**：完成后根据画像建议 `/novel-learn-from` 或 `/novel-seed`
- **Hook 安装**：Phase 3 注册的 hook 被 `/novel-predict` 和 `/novel-score` 的 immutability 检查依赖
