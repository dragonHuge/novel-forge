<h1 align="center">Novel Forge</h1>

<p align="center">
给网文创作者的 AI 校准工作流 —— 把"凭感觉写"变成"用数据进化"
</p>

<p align="center">
  <strong>简体中文</strong>
  &nbsp;·&nbsp;
  <a href="docs/README_EN.md"><strong>English</strong></a>
</p>

<p align="center">
<a href="CHANGELOG.md"><img src="https://img.shields.io/badge/version-v0.1.0-orange" alt="Version"></a>
&nbsp;
<a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
</p>

---

## 它解决什么问题

大多数网文作者在重复一个循环：

> 写完 → 发布 → 看数据 → 什么都没学到 → 继续凭感觉写

写了 50 本书的人，判断力可能只比写了 1 本的人强 10%。因为没有人在每次发布前把自己的判断白纸黑字写下来，更没人发完之后认真对账"我哪里判断对了、哪里判断错了"。

**Novel Forge** 让每一本书变成一次校准实验：

📊 立项评分 → 🎯 盲预测 → 🚀 发布 → 📈 T+7d 数据复盘 → 🧬 进化评分公式

一个月 = 你对自己作品的判断力可量化地提升。
三个月 = 你有一套只属于你的选题公式。

---

## 和其他"AI 写作工具"的区别

| 其他工具 | Novel Forge |
|---------|-------------|
| AI 帮你写小说 | AI **帮你校准判断力** —— 小说还是你写 |
| 发 10 个版本 A/B 测 | 发一本 —— **发之前写预测，发之后用数据对账** |
| 静态模板 | **进化的评分公式** —— 三个月后的公式不是起步时那个 |
| 通用建议 | **只服务你一个账号** —— 从你的历史数据中校准 |

一句话：其他工具帮你"写更多"，这个帮你"判断更准"。

---

## 工作流程

```
立项评分（7 维度量化筛选）
    ↓
盲预测（签约概率 + 收入档位 + 概率分布）  ← hook 强制不可改
    ↓
发布（上传平台）
    ↓
T+7d 数据复盘（预测 vs 实际，逐项对账）
    ↓
观察沉淀 → 积累到 5+ 样本 → 评分公式升级
    ↓
回到第一步，更准
```

---

## 三条不可妥协的原则

1. **盲预测不可变** —— 预测必须在看到任何真实数据之前写完。一旦落盘，hook 强制锁定。想重做？只能建 `_redo.md` 新文件。
2. **复盘必须有数据** —— 没有平台后台的真实数字，不允许写复盘。感想不是复盘，数据对账才是。
3. **评分公式是工作台不是博物馆** —— 被数据推翻的观察直接删，被验证的观察吸收为正式维度。git history 才是档案。

---

## 安装

```bash
git clone https://github.com/dragonHuge/novel-forge.git
cd novel-forge
bash install.sh
```

10 个子 skill 通过 symlink 注册到 `~/.claude/skills/`。

**支持环境**: Claude Code（默认）· Codex（`bash install.sh --codex`）· 两者（`bash install.sh --all`）

---

## 快速开始

在你的小说项目目录打开 Claude Code：

```
初始化
```

5 个问题完成 onboarding。之后：

```
打分这个创意                    → 7 维度评分
启动预测 《书名》               → 生成 immutable 预测文件
已发布 《书名》                 → 登记上传，推入待复盘队列
复盘 《书名》                   → T+7d 数据对账
状态                           → 查看校准进度
```

---

## 评分体系

内置两套 starter rubric：

- **短篇小说**（完本签约）：标题点击感 / 开局炸裂度 / 情绪强度 / 反转空间 / 30%卡点 / 独特性 / 题材匹配度
- **连载小说**（日更模式）：标题点击感 / 开局炸裂度 / 情绪强度 / 反转空间 / 追更粘性 / 独特性 / 题材匹配度

评分公式从 v0（等权）起步，随你的数据积累自动进化。

---

## 平台支持

| 平台 | 状态 |
|------|------|
| 番茄小说 | ✅ 内置 adapter |
| 起点中文网 | 🔲 计划中 |
| 七猫小说 | 🔲 计划中 |
| 豆瓣阅读 | 🔲 计划中 |

---

## 技术架构

### 设计哲学

Novel Forge 不是一个"大而全的 AI 写作 App"，是一组**可组合的 AI Agent Skill**。它跑在 Claude Code / Codex 里，和你的写作项目共享同一个工作目录。

核心设计原则：
- **纪律不靠自觉** —— hook 在 harness 层强制执行，不是"建议你不要改预测"，是"你改不了"
- **状态集中** —— 一个 `.novel-state.json` 是全部运行时状态的 single source of truth
- **Skill 职责单一** —— 每个 skill 只做一件事，只读/写它该碰的文件
- **数据源可插拔** —— adapter 模式隔离平台差异，换平台不改核心逻辑

### 整体架构图

```
┌─────────────────────────────────────────────────────┐
│                   Claude Code / Codex                │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │              SKILL.md (总协议)                  │  │
│  │     触发词路由 → 分发到对应子 skill             │  │
│  └───────────────┬───────────────────────────────┘  │
│                  │                                   │
│  ┌───────────────▼───────────────────────────────┐  │
│  │             10 个子 Skill                      │  │
│  │                                               │  │
│  │  novel-init    novel-score    novel-predict    │  │
│  │  novel-publish novel-retro   novel-status     │  │
│  │  novel-seed    novel-learn-from               │  │
│  │  novel-bump    novel-migrate                  │  │
│  └───────────────┬───────────────────────────────┘  │
│                  │                                   │
│  ┌───────────────▼───────────────────────────────┐  │
│  │            Hooks (harness 强制层)              │  │
│  │                                               │  │
│  │  PreToolUse:                                  │  │
│  │    score-immutability.sh   → 锁立项评分段      │  │
│  │    prediction-immutability.sh → 锁预测段       │  │
│  │  SessionStart:                                │  │
│  │    session-start.sh → 校准状态仪表盘           │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
   .novel-state.json  predictions/  rubric_notes.md
   (运行时状态)       (不可变预测)   (进化的评分公式)
```

### Hook 系统

Hook 是 Claude Code 的 harness 能力——在工具调用前/后执行 shell 脚本，返回非零退出码即阻塞操作。

| Hook | 事件 | 拦截逻辑 |
|------|------|---------|
| `score-immutability.sh` | PreToolUse(Edit\|Write) | 拦截对 `创作设定.md` 中 `## 立项评分` 段的修改 |
| `prediction-immutability.sh` | PreToolUse(Edit\|Write) | 拦截对 `predictions/*.md` 中 `## 预测` 段的修改 |
| `session-start.sh` | SessionStart | 读 `.novel-state.json`，输出校准仪表盘到 Claude 上下文 |

技术实现：读 stdin 的 JSON（含 `tool_name`、`tool_input.file_path`、`tool_input.old_string`），用 awk 提取目标段落，grep -F 判断编辑是否触及受保护区间。

### 状态管理

`.novel-state.json`（schema v1.0）是唯一的运行时状态文件：

```json
{
  "schema_version": "1.0",
  "rubric_version": "v0",
  "platform": "fanqie",
  "calibration_samples": 0,
  "pending_retros": [],
  "consecutive_directional_errors": [],
  "last_prediction_at": null,
  "last_retro_at": null,
  "initialized_at": "2026-05-17T00:00:00+08:00"
}
```

设计约束：
- **原子写入**：写临时文件 → `os.replace()` 防损坏
- **单写者**：每个字段只有一个 skill 负责更新
- **向前兼容**：新版本 skill 读旧 state 用 `get(field, default)`
- **schema 迁移**：`schema_version` 变更走 `migrations/` 链式升级

### 校准飞轮（数据流）

```
novel-score          novel-predict         novel-publish        novel-retro
    │                     │                     │                    │
    │ 7维打分             │ 生成预测文件          │ 登记发布时间        │ 写入复盘段
    │ (只输出)            │ (predictions/*.md)   │ (更新header)       │ (对账+观察)
    ▼                     ▼                     ▼                    ▼
                   .novel-state.json ◄──────── 每步都更新 ────────────┘
                          │
                          │ calibration_samples >= 5
                          │ consecutive_errors >= 3
                          ▼
                    novel-bump
                    (升级 rubric_notes.md)
```

### Adapter 模式

平台差异通过 adapter 隔离：

```
adapters/
├── fanqie/          # 番茄小说：收入档位 S/A/B/C/D，复盘窗口 7d/30d
├── qidian/          # 起点：月票/推荐票/均订，复盘窗口 30d (计划中)
└── qimao/           # 七猫：(计划中)
```

每个 adapter 定义：可收集指标、收入档位边界、复盘窗口、数据收集方式（手动/自动）。核心 skill 逻辑不感知平台细节。

### 子 Skill 职责矩阵

| Skill | 读 | 写 | 关键约束 |
|-------|----|----|---------|
| novel-init | — | 所有脚手架文件 | 不覆盖已有文件 |
| novel-score | 创作设定 + rubric | 无（只输出） | 纯只读 |
| novel-predict | 创作设定 + 审核报告 + state | predictions/*.md + state | 盲检 + 不可变 |
| novel-publish | predictions/*.md + state | header + state | 不碰预测段 |
| novel-retro | predictions/*.md + state + rubric | 复盘段 + state + rubric_notes | hash 校验 |
| novel-status | state + predictions/ + novels/ | 无（只输出） | 纯只读 |
| novel-seed | candidates.md | candidates.md | 不做精确打分 |
| novel-learn-from | 对标作品 | samples/ + rubric_notes | 不计入 calibration |
| novel-bump | rubric_notes + predictions/ | rubric_notes + state | 全量重打分验证 |
| novel-migrate | state + migrations/ | state | 幂等 + 备份 |

### 安装原理

`install.sh` 把每个 `skills/<name>/` 目录 symlink 到 `~/.claude/skills/<name>`。Claude Code 启动时扫描该目录，自动注册所有 skill 的触发词。Symlink 模式下修改源文件立即生效；`--copy` 模式冻结版本。

## 项目结构

```
novel-forge/
├── SKILL.md                    # 总协议 + 路由（Agent 的入口）
├── skills/                     # 10 个子 skill（各自独立 SKILL.md）
│   ├── novel-init/             # onboarding（5 问题 → 脚手架）
│   ├── novel-predict/          # 盲预测（6 phase → immutable 文件）
│   ├── novel-retro/            # 数据复盘（6 phase → 对账 + 观察）
│   ├── novel-score/            # 打分（只读输出，不写文件）
│   ├── novel-seed/             # 选题讨论（一次一个深挖）
│   ├── novel-publish/          # 发布登记（轻量元数据更新）
│   ├── novel-status/           # 状态看板（只读仪表盘）
│   ├── novel-learn-from/       # 对标作品导入（冷启动信号）
│   ├── novel-bump/             # 评分公式升级（最高风险动作）
│   └── novel-migrate/          # schema 迁移（幂等升级链）
├── hooks/                      # harness 强制层（shell 脚本）
│   ├── prediction-immutability.sh
│   ├── score-immutability.sh
│   └── session-start.sh
├── templates/                  # 文件骨架（init 时生成到用户项目）
├── starter-rubrics/            # 初始评分卡（短篇 + 连载）
├── shared-references/          # 跨 skill 协议文档
│   ├── blind-prediction-protocol.md
│   ├── state-management.md
│   └── observation-lifecycle.md
├── adapters/                   # 平台适配器（可插拔）
│   └── fanqie/
├── migrations/                 # schema 版本管理
│   └── registry.md
├── install.sh / uninstall.sh   # 一键安装/卸载
└── README.md / LICENSE / CHANGELOG.md
```

---

## Roadmap

- [x] v0.1.0 — 核心闭环（评分 → 预测 → 发布 → 复盘）
- [ ] v0.2.0 — 评分公式自动进化（bump + 跨模型审核）
- [ ] v0.3.0 — 对标作品导入（learn-from）
- [ ] v0.4.0 — 起点/七猫 adapter
- [ ] v1.0.0 — 浏览器自动化数据采集

---

## License

MIT. 商用、修改、闭源集成均可。

---

*不是作弊，是校准。和计算器一样，和搜索引擎一样。*
*未来不奖励努力，奖励看得准的人。*
