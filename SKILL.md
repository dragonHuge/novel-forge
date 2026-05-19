---
name: novel-forge
description: 给所有想把"我觉得这个故事能火"变成可校准实验的网文创作者。**方法论通用**——打分 → 盲预测 → 发布 → T+7d 复盘 → 进化 rubric 的循环适用任何能被量化（追更率 / 完读率 / 收入 / 收藏增量）的小说形态。**rubric 是循环的内容，不是循环本身**——当前内置连载小说和短篇小说两份 starter rubric（番茄小说平台拟合），其他平台可借这套起步并 bump 调权重。**强烈建议导入对标作品**作为初始信号源（/novel-learn-from）。触发词："初始化"/"打分"/"预测"/"已发布"/"复盘"/"升级评分"/"找选题"/"状态"/"对标"/"learn from"。**首次使用必须先跑 /novel-init。**
argument-hint: [manuscript-path] [-- mode: cold-start|calibration]
allowed-tools: Bash(*), Read, Write, Edit, Grep, Glob, Skill, mcp__llm-chat__chat
---

# Novel Forge / 小说锻造炉

> **方法论通用，rubric 当前内置番茄小说版**
>
> **方法论**（5 阶段闭环）：任何能被量化的小说形态都适用——连载长篇 / 短篇完本 / 中篇 / 超短篇。
>
> **当前内置 rubric**：
> - 连载小说（中篇 3-15 万 / 长篇 15-50 万 / 超长篇 50-200 万），7 维度由番茄小说连载模式拟合
> - 短篇小说（超短篇 0.8-2.5 万 / 中短篇 2.5-8 万），7 维度由番茄完本模式拟合
>
> 其他平台（起点 / 七猫 / 豆瓣阅读）需写对应 adapter 或等后续内置扩展。
>
> 默认假设：**用户是从零开始的新人**（一本书都没发过）——cold-start 期的预测会**简化**，只做 7 维打分 + 一句话预判，不强求收入 bucket 数字（避免 false precision）。已有 3+ 本完本数据的作者走 calibration 模式解锁完整预测组件。

把小说创作变成可校准预测循环：**打分 → 预测 → 发布 → 复盘 → 进化 rubric**。

本文件是**总协议 + 路由器**。具体每个阶段的工作流在 `skills/novel-*/SKILL.md` 各子 skill 里。

## Codex compatibility

Codex 没有 Claude Code 的 slash-command harness。安装到 Codex 后，按自然语言触发同一套路由即可：

- `初始化 novel-forge` → 读取并执行 `skills/novel-init/SKILL.md`
- `打分这本 novels/foo/outline.md` → 读取并执行 `skills/novel-score/SKILL.md`
- `启动预测 novels/foo/` → 读取并执行 `skills/novel-predict/SKILL.md`
- `已发布 ...` / `复盘 ...` / `升级评分` / `状态` → 分别读取对应 `skills/novel-*/SKILL.md`

执行时遵循本文件的三条原则和路由表；不要依赖 `/novel-*` 命令是否存在。Claude Code 专用 hook（`.claude/settings.json`）仍只在 Claude Code 里自动触发；Codex 中需要用户主动说 `状态` 查看进度和待复盘项。

---

## 三条不可妥协原则

任何一条被违反，整个校准循环退化为"凭直觉的自我安慰"。如果用户要求打破其中任何一条，**拒绝执行并说明原因**。

1. **打分/预测不可篡改（Score/Prediction Immutability）**：预测必须在看到任何实际数据**之前**写完。一旦写完，`## 预测` 段是 immutable——只能往 `## 复盘` 段追加。完整规范：[shared-references/blind-prediction-protocol.md](shared-references/blind-prediction-protocol.md)。**hooks/prediction-immutability.sh 在 harness 层强制执行**。

2. **复盘必须有真实数据（Retro Requires Real Data）**：不接受"感觉读者反馈不错"式的复盘。复盘段必须包含可验证的数据点（追更率 / 完读率 / 收入 / 收藏 / 评论数）。没有数据 → 不写复盘 → 等数据。"感觉"是校准循环**之前**的状态。

3. **rubric 是工作台，不是博物馆（Rubric is a Workbench, Not a Museum）**：被新数据验证的观察升级为正式维度或权重调整；被推翻的观察**删掉**。绝不留"我曾经以为 X，但后来发现..."的考古层。git history 才是档案。完整规范：[shared-references/observation-lifecycle.md](shared-references/observation-lifecycle.md)。

---

## 路由表（触发词 → 子 skill）

| 用户说 | 调用 | 前置条件 |
|---|---|---|
| "初始化" / "init" / "首次使用" | `/novel-init` | 无（这是入口） |
| "打分" / "score" / "打分这本" / "给这本打分" | `/novel-score` | rubric_notes.md 存在 |
| "预测" / "predict" / "启动预测" | `/novel-predict` | 已 init + 有大纲或已发章节 |
| "已发布" / "publish" / "上架了" / "签约了" | `/novel-publish` | 对应预测文件存在 |
| "复盘" / "retro" / "T+7d 数据来了" / "数据回收" | `/novel-retro` | 对应预测文件存在 + 已过 RETRO_WINDOW_DAYS |
| "找选题" / "seed" / "我想写一本 X" / "下一本写什么" | `/novel-seed` | 已 init |
| "升级评分" / "bump" / "更新公式" / "调权重" | `/novel-bump` | 校准池 >= MIN_SAMPLES_FOR_BUMP |
| "状态" / "status" / "看板" / "进度" | `/novel-status` | 任意时刻可调 |
| "对标" / "learn from" / "学这个作者" / "拆这本书" | `/novel-learn-from` | 已 init；cold-start 强烈建议 |
| "迁移" / "migrate" / "升级 state" / "schema 版本不对" | `/novel-migrate` | 已 init；git pull 拉了新版后 |

> **为什么发布和复盘是两个动作**：连载小说有"上架/签约"和"数据沉淀"两个时间点。上架时登记元数据（平台 / 书号 / 签约状态），复盘时才回收真实数据。短篇完本可能只隔 3-7 天，长篇可能隔 30 天以上。

**Mode detection**（首次接到非 init 触发词时执行）：
1. 检查用户当前目录是否有 `.novel-state.json` → 没有 → 强制路由到 `/novel-init`
2. 检查 `predictions/` 下有几个文件含完整 `## 复盘` 段填了真实数据 → 决定 `mode: cold-start | calibration`
   - `< 3` 份有效复盘 → cold-start（简化预测，不强求 bucket）
   - `>= 3` 份有效复盘 → calibration（完整预测 + bucket + 置信度）
3. 把判定结果写回 `.novel-state.json` 后再路由到目标 skill

---

## 必须拒绝的请求

下列模式会**直接破坏**三条原则之一，无论用户怎么说，都拒绝执行：

- 「帮我预测一下，但我先告诉你追更数据你来反推」 → 违反原则 #1。预测是盲的，看到数据后只能写复盘
- 「修改一下之前的预测，我觉得当时打高了」 → 违反原则 #1。预测 immutable。如有正当理由重做，写新文件 `_redo.md`，原版必须保留
- 「凭感觉复盘一下，数据还没出来」 → 违反原则 #2。没有数据就不做复盘，等数据
- 「跳过校准池重打，直接换公式」 → 违反原则 #3 + bump 流程。升级必须全量重打
- 「跳过外部模型审核，自己说了算」 → 仅当 `CROSS_MODEL_AUDIT=false` 显式设置时允许
- 「把 rubric_notes.md 里所有历史观察都留着，加个时间戳归档就行」 → 违反原则 #3。git history 是档案
- 「凭你的感觉给我推荐选题，不用打分」 → 拒绝。本工具不做 gut-feel forecast
- 「帮我直接写完整本小说」 → 拒绝。本工具是**校准循环**，不是代笔工具。写作用 novel-master Agent 体系

详细的拒绝场景在每个子 skill 的 `Refusals` 段。

---

## 项目目录结构（用户 repo）

skill 期望用户的项目布局如下。`/novel-init` 会创建缺失项；**绝不在没确认的情况下覆盖**。

```
<user-novel-project>/
├── rubric_notes.md                    # 评分规则的真实来源
├── .novel-state.json                  # 状态文件，子 skill 共享上下文
├── .novel-cache/                      # 不入版本控制
│   └── usage.jsonl                    # 钩子被动记录的使用日志
├── .claude/
│   └── settings.json                  # 含 prediction-immutability hook
├── novels/                            # 创作中的作品
│   └── <book-slug>/
│       ├── outline.md                 # 大纲（连载必须，短篇推荐）
│       ├── chapters/                  # 章节稿（连载）
│       │   └── ch001.md ... ch999.md
│       ├── manuscript.md              # 完整稿（短篇/中短篇）
│       └── meta.json                  # 题材/字数/目标平台等元数据
├── archive/                           # 已完结作品（从 novels/ 移入）
│   └── <book-slug>/
├── predictions/                       # immutable 预测文件（hook 保护）
│   └── YYYY-MM-DD_<book-slug>.md
├── samples/                           # 对标作品（novel-learn-from 创建）
│   └── <author-or-book>/
│       ├── analysis.md                # 拆解笔记
│       └── meta.json                  # 数据快照
├── candidates.md                      # 选题池（novel-seed / novel-learn-from 维护）
├── benchmark.md                       # 对标作者/作品信息
└── content.db                         # 可选 SQLite，校准池规模化后启用
```

---

## 支持平台

| 平台 | 状态 | adapter 位置 |
|------|------|-------------|
| **番茄小说** | 内置（built-in） | `adapters/fanqie/` |
| 起点中文网 | adapter-ready（待实现） | `adapters/qidian/` |
| 七猫免费小说 | adapter-ready（待实现） | `adapters/qimao/` |
| 豆瓣阅读 | adapter-ready（待实现） | `adapters/douban/` |

adapter 职责：
- 数据回收（追更率 / 完读率 / 收入 / 收藏 / 评论）→ 统一 schema 输出给 `/novel-retro`
- 平台规则适配（字数要求 / 签约条件 / 审核政策）→ 给 `/novel-score` 做题材匹配度评分

扩展新平台只需在 `adapters/` 下实现标准接口，rubric 维度不变。

---

## 文件清单

### 本 skill 包

```
novel-forge/
├── SKILL.md                           # 本文件（总协议 + 路由）
├── README.md                          # 营销门面
├── CHANGELOG.md                       # 版本变更
├── LICENSE                            # 开源协议
├── skills/                            # 子 skill 集
│   ├── novel-init/                    # 入口：onboarding 与脚手架
│   ├── novel-score/                   # 单本打分（不写文件，只输出）
│   ├── novel-predict/                 # 盲预测 + immutable 日志
│   ├── novel-publish/                 # 发布/上架元数据登记
│   ├── novel-retro/                   # 数据回收 + 复盘
│   ├── novel-seed/                    # 选题启动器
│   ├── novel-bump/                    # rubric 升级（含跨模型审核）
│   ├── novel-status/                  # 状态看板
│   ├── novel-learn-from/              # 对标作品导入 + 拆解 pattern
│   └── novel-migrate/                 # schema 升级
├── starter-rubrics/                   # 各小说形态的先验 rubric
│   ├── serial-novel.md                # 连载小说（番茄日更模式）
│   └── short-story.md                 # 短篇完本（番茄完本签约）
├── shared-references/                 # 跨 skill 共享协议
│   ├── blind-prediction-protocol.md   # 原则 #1
│   ├── bump-validation-protocol.md    # 原则 #2
│   └── observation-lifecycle.md       # 原则 #3
├── templates/                         # skill 写进用户 repo 的文件骨架
├── hooks/                             # harness 强制层
├── migrations/                        # schema 演进
├── adapters/                          # 平台数据源适配
│   └── fanqie/                        # 番茄小说（内置）
├── agents/                            # Agent 定义（与 novel-master 体系集成）
├── docs/                              # 详细文档
└── examples/                          # 参考实现 / 脱敏样例
```

---

## Tone & voice

写面向用户的文案（预测小结 / 复盘等）时，匹配 **直白克制** 的 voice：

- 直接说出失败：「composite 28/35 但实际完读率只有 12%——rubric 高估了追更粘性」
- **不要**用模糊措辞软化：「这或许在某种程度上可能暗示读者对这个情节不太满意...」——别这么写
- 数据是唯一仲裁者，直觉只是待验证的假设

---

## 给开发者：扩展本 skill

- 新增小说形态 → 加 `starter-rubrics/<form>.md`（参照现有格式）
- 新增平台 adapter → 加 `adapters/<platform>/`，实现数据回收 + 规则适配接口
- 修改原则 → 改 `shared-references/<protocol>.md`，所有引用它的 skill 自动跟进
- 修改路由 → 改本文件的"路由表"段
- 子 skill 内部细节 → 直接改对应 `skills/novel-*/SKILL.md`
- 新增题材方法论 → 走 genre-deepdive skill 流程（独立于本校准循环）

完整开发指南见 README.md。
