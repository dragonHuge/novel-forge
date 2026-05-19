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

## 项目结构

```
novel-forge/
├── SKILL.md                    # 总协议 + 路由
├── skills/                     # 10 个子 skill
│   ├── novel-init/             # onboarding
│   ├── novel-predict/          # 盲预测
│   ├── novel-retro/            # 数据复盘
│   ├── novel-score/            # 打分（不写文件）
│   ├── novel-seed/             # 选题讨论
│   ├── novel-publish/          # 登记发布
│   ├── novel-status/           # 状态看板
│   ├── novel-learn-from/       # 对标作品导入
│   ├── novel-bump/             # 评分公式升级
│   └── novel-migrate/          # schema 迁移
├── hooks/                      # harness 强制层
├── templates/                  # 文件骨架
├── starter-rubrics/            # 初始评分卡
├── shared-references/          # 跨 skill 协议
├── adapters/                   # 平台适配器
└── migrations/                 # schema 版本管理
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
