#!/usr/bin/env bash
# backup-file.sh — macOS/Linux 文档双份备份
# 改任何主文件前必须先调用本脚本
#
# Usage:
#   bash backup-file.sh --file-path <文件绝对路径>
#   bash backup-file.sh -f <文件绝对路径>
#
# 输出：
#   1. <同级目录>/bak/_<原文件名>        — 即时备份（覆盖最近一次）
#   2. <同级目录>/bak/yyyyMM/<安全目录名>/<名>-yyyyMMdd-HHmmss.ext — 历史归档
#      安全目录名：原文件名中的 "." 换为 "_"（如 SKILL.md → SKILL_md），避免与技能入口冲突

set -euo pipefail

FILE_PATH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file-path|-f) FILE_PATH="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: backup-file.sh --file-path <absolute-path>"; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$FILE_PATH" ]]; then
  echo "Error: --file-path is required" >&2
  echo "Usage: backup-file.sh --file-path <absolute-path>" >&2
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "Error: File not found: $FILE_PATH" >&2
  exit 1
fi

DIR=$(dirname "$FILE_PATH")
FILENAME=$(basename "$FILE_PATH")
if [[ "$FILENAME" == *.* ]]; then
  STEM="${FILENAME%.*}"
  EXT=".${FILENAME##*.}"
else
  STEM="$FILENAME"
  EXT=""
fi

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
MONTH=$(date +"%Y%m")

ARCHIVE_SEGMENT="${FILENAME//./_}"

BAK_DIR="$DIR/bak"
HIST_DIR="$BAK_DIR/$MONTH/$ARCHIVE_SEGMENT"

# Step 1: 即时备份（直接覆盖，保留最近一次）
mkdir -p "$BAK_DIR"
cp "$FILE_PATH" "$BAK_DIR/_$FILENAME"

# Step 2: 历史归档（追加，不覆盖旧时间戳）
mkdir -p "$HIST_DIR"
cp "$FILE_PATH" "$HIST_DIR/${STEM}-${TIMESTAMP}${EXT}"

echo "✓ 备份完成: $FILE_PATH"
echo "  即时备份: $BAK_DIR/_$FILENAME"
echo "  历史归档: $HIST_DIR/${STEM}-${TIMESTAMP}${EXT}"
