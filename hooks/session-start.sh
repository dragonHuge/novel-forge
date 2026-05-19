#!/usr/bin/env bash
#
# novel-forge / session-start hook
#
# SessionStart → 读 .novel-state.json，输出 4-6 行校准状态仪表盘。
# 非 novel-forge 项目（无 .novel-state.json）静默退出。
#
# NOTE: chmod +x at install time

set -uo pipefail

STATE_FILE=".novel-state.json"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "[novel-forge] jq 未安装，跳过状态仪表盘" >&2
  exit 0
fi

cal_samples=$(jq -r '.calibration_samples // 0' "$STATE_FILE" 2>/dev/null || echo "0")
schema_ver=$(jq -r '.schema_version // "?"' "$STATE_FILE" 2>/dev/null || echo "?")
last_pred=$(jq -r '.last_prediction_at // "—"' "$STATE_FILE" 2>/dev/null || echo "—")
last_retro=$(jq -r '.last_retro_at // "—"' "$STATE_FILE" 2>/dev/null || echo "—")

pending_count=$(jq -r '.pending_retros | length // 0' "$STATE_FILE" 2>/dev/null || echo "0")

# 置信度标签
if   (( cal_samples == 0 )); then confidence="🔴 极低（纪律训练期）"
elif (( cal_samples <= 2 )); then confidence="🟠 低（方向参考）"
elif (( cal_samples <= 5 )); then confidence="🟡 偏低（有参考价值）"
elif (( cal_samples <= 10 )); then confidence="🟢 中（可辅助决策）"
elif (( cal_samples <= 20 )); then confidence="🟢 较高（rubric 趋稳）"
else confidence="🔵 高（数据驱动）"
fi

# 待上传数量
upload_count=0
if [[ -d "c-待上传" ]]; then
  upload_count=$(find "c-待上传" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
fi

# 截断日期到日（去掉时分秒）
fmt_date() {
  local d="$1"
  if [[ "$d" == "—" || "$d" == "null" || -z "$d" ]]; then
    echo "—"
  else
    echo "${d:0:10}"
  fi
}

cat <<EOF
novel-forge 校准 — 状态（schema ${schema_ver}）
校准样本: ${cal_samples} · 置信度: ${confidence}
待复盘: ${pending_count} 篇 · 待上传: ${upload_count} 篇
上次预测: $(fmt_date "$last_pred") · 上次复盘: $(fmt_date "$last_retro")
EOF

# 待复盘提醒
if (( pending_count > 0 )); then
  echo ""
  echo "⏰ 待复盘作品："
  jq -r '.pending_retros[]' "$STATE_FILE" 2>/dev/null | while read -r item; do
    echo "  · $item"
  done
fi

exit 0
