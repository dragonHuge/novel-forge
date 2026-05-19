---
name: novel-migrate
description: Schema 版本迁移。用户 git pull 更新 novel-forge 后，如果 .novel-state.json 的 schema_version 低于当前版本，执行迁移链升级。
argument-hint: []
allowed-tools: Read, Write, Edit, Bash
---

# novel-migrate — Schema 迁移

> 触发词："迁移"/"migrate"/"schema 版本不对"/"升级 state"

## 定位

novel-forge 的 `.novel-state.json` 有 `schema_version` 字段。当项目升级引入不兼容的 schema 变更时，用户需要跑 `/migrate` 升级状态文件。

## 流程

1. 读 `.novel-state.json` 的 `schema_version`
2. 读 `migrations/registry.md` 获取当前最新版本和迁移链
3. 如果版本已是最新 → 提示"已是最新，无需迁移"
4. 否则按顺序执行每一步迁移文件（`migrations/<from>-to-<to>.md`）
5. 每步成功后更新 `schema_version`
6. 全部完成后报告："迁移完成 vX → vY"

## 规则

- **幂等**：跑两次结果一样
- **失败不前进**：中间步骤失败 → 停在中间版本，不继续
- **备份**：迁移前自动复制 `.novel-state.json` 为 `.novel-state.json.backup`
- **原子写入**：每步写临时文件，成功后 rename

## 当前状态

v0.1.0 只有 schema 1.0，无需迁移。此 skill 在 schema 1.1 引入时激活。

## 迁移注册表

见 `migrations/registry.md`（当前为空，首次 breaking change 时创建）。
