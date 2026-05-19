#!/usr/bin/env bash
#
# novel-forge / score-immutability hook
#
# PreToolUse(Edit|Write) → 拦截对 创作设定.md 中 '## 立项评分' 段的编辑。
#
# 放行：首次写入评分 / 编辑评分以外的段 / 非创作设定.md 的文件
# 拦截：修改已存在的 ## 立项评分 到下一个 ## 之间的内容
#
# 绕过：NOVEL_BYPASS_IMMUTABILITY=1
#
# NOTE: chmod +x at install time

set -uo pipefail

if [[ "${NOVEL_BYPASS_IMMUTABILITY:-0}" == "1" ]]; then
  echo "[novel-forge] ⚠️  IMMUTABILITY BYPASS（评分段）" >&2
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
  */创作设定.md)
    :
    ;;
  *)
    exit 0
    ;;
esac

# Write 新文件 → 放行（首次创建创作设定.md）
if [[ "$tool_name" == "Write" && ! -f "$file_path" ]]; then
  exit 0
fi

# Write 覆盖已有文件 → 如果文件已有评分段，拦截
if [[ "$tool_name" == "Write" && -f "$file_path" ]]; then
  if grep -q '^## 立项评分' "$file_path" 2>/dev/null; then
    cat >&2 <<EOF

[novel-forge] 🚫 拦截：Write 会覆盖含立项评分的创作设定：
  $file_path

立项评分一旦写下不可更改（校准闭环原则）。
请用 Edit 修改评分以外的段落。
EOF
    exit 1
  fi
  exit 0
fi

# Edit 模式
if [[ "$tool_name" == "Edit" ]]; then
  old_string=$(printf '%s' "$input" | jq -r '.tool_input.old_string // empty' 2>/dev/null || echo "")
  if [[ -z "$old_string" ]]; then
    exit 0
  fi

  # 文件不存在或没有评分段 → 放行
  if [[ ! -f "$file_path" ]] || ! grep -q '^## 立项评分' "$file_path" 2>/dev/null; then
    exit 0
  fi

  score_section=$(awk '
    /^## / {
      if ($0 ~ /^## 立项评分/) {
        in_score=1; print; next
      } else if (in_score) {
        exit
      }
    }
    in_score { print }
  ' "$file_path" 2>/dev/null || echo "")

  if [[ -z "$score_section" ]]; then
    exit 0
  fi

  score_tmp=$(mktemp)
  printf '%s' "$score_section" > "$score_tmp"

  if grep -qF -- "$old_string" "$score_tmp" 2>/dev/null; then
    rm -f "$score_tmp"
    cat >&2 <<EOF

[novel-forge] 🚫 拦截：编辑触及创作设定的 '## 立项评分' 段：
  $file_path

立项评分一旦写下不可更改（校准闭环原则 #1）。
如需修正评分，在预测文件的 '## 复盘' 段记录差异原因。
纯格式修正 → NOVEL_BYPASS_IMMUTABILITY=1
EOF
    exit 1
  fi

  rm -f "$score_tmp"
  exit 0
fi

exit 0
