# Changelog

## [0.1.0] - 2026-05-17

### Added
- 核心校准闭环：立项评分 → 盲预测 → 发布 → T+7d 数据复盘
- 10 个子 skill：init / predict / retro / score / seed / publish / status / learn-from / bump / migrate
- 3 个 hook 脚本：prediction-immutability / score-immutability / session-start
- 2 套 starter rubric：短篇小说 + 连载小说
- 番茄小说 adapter（手动数据收集）
- install.sh / uninstall.sh（Claude Code + Codex 双环境）
- 预测模板 + 状态文件 schema v1.0
- 盲预测协议 + 观察生命周期 + 状态管理 shared-references
