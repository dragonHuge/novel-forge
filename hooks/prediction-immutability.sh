#!/usr/bin/env bash
#
# novel-forge / prediction-immutability hook
#
# PreToolUse(Edit|Write) → 拦截对 predictions/*.md 中 '## 预测' 段的编辑。
#
# 放行：新建预测文件 / 编辑 header / 追加到 ## 复盘 段 / predictions/ 外的文件
# 拦截：修改 ## 预测 到下一个 ## 之间的任何内容
#
# 绕过：NOVEL_BYPASS_IMMUTABILITY=1（单次，日志可见）
#
# NOTE: chmod +x at install time

set -uo pipefail

if [[ "${NOVEL_BYPASS_IMMUTABILITY:-0}" == "1" ]]; then
  echo "[novel-forge] ⚠️  IMMUTABILITY BYPASS（NOVEL_BYPASS_IMMUTABILITY=1）" >&2
  echo "[novel-forge] ⚠️  仅用于纯格式修正，语义变更禁止绕过。" >&2
  exit 0
fi

input=$(cat)
if [[ -z "$input" ]]; then
  exit 0
fi

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

if [[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]]; then
  exit 0
fi

if [[ -z "$file_path" ]]; then
  exit 0
fi

case "$file_path" in
  */predictions/*.md|predictions/*.md)
    :
    ;;
  *)
    exit 0
    ;;
esac

if [[ "$tool_name" == "Write" && ! -f "$file_path" ]]; then
  exit 0
fi

if [[ "$tool_name" == "Edit" ]]; then
  old_string=$(printf '%s' "$input" | jq -r '.tool_input.old_string // empty' 2>/dev/null || echo "")
  if [[ -z "$old_string" ]]; then
    exit 0
  fi

  prediction_section=$(awk '
    /^## / {
      if ($0 ~ /^## 预测/) {
        in_pred=1; print; next
      } else if (in_pred) {
        exit
      }
    }
    in_pred { print }
  ' "$file_path" 2>/dev/null || echo "")

  if [[ -z "$prediction_section" ]]; then
    exit 0
  fi

  pred_tmp=$(mktemp)
  printf '%s' "$prediction_section" > "$pred_tmp"

  if grep -qF -- "$old_string" "$pred_tmp" 2>/dev/null; then
    rm -f "$pred_tmp"
    cat >&2 <<EOF

[novel-forge] 🚫 拦截：编辑触及 predictions/ 文件的 '## 预测' 段：
  $file_path

校准闭环原则 #1：预测一旦写下不可更改。
只有 '## 复盘' 段允许追加内容。

替代方案：
  • 重做预测 → 创建新文件：${file_path%.md}_redo.md（原文件必须保留）
  • 发现事实错误 → 在 '## 复盘' 段记录："修正：原概率 X% 应为 Y%"
  • 纯格式修正 → NOVEL_BYPASS_IMMUTABILITY=1（单次绕过，git 可追溯）
EOF
    exit 1
  fi

  rm -f "$pred_tmp"
  exit 0
fi

if [[ "$tool_name" == "Write" && -f "$file_path" ]]; then
  cat >&2 <<EOF

[novel-forge] 🚫 拦截：Write 会覆盖已有预测文件：
  $file_path

请用 Edit 追加到 '## 复盘' 段，或创建 '_redo.md' 新文件。
原始预测文件必须原样保留。
EOF
  exit 1
fi

exit 0
