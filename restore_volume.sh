#!/bin/bash

set -e

BACKUP_DIR="./Backup_volumes"

# 確認備份資料夾存在
if [ ! -d "$BACKUP_DIR" ]; then
  echo "❌ 找不到備份資料夾: $BACKUP_DIR"
  exit 1
fi

# 列出所有備份檔
mapfile -t FILES < <(find "$BACKUP_DIR" -maxdepth 1 -name "*.tar.gz" | sort)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "❌ 沒有備份檔可還原。"
  exit 1
fi

echo "🗃️ 以下是可還原的備份檔："
INDEX=1
declare -A FILE_MAP

for FILE in "${FILES[@]}"; do
  SIZE=$(du -BG "$FILE" | cut -f1)
  FILENAME=$(basename "$FILE")
  echo "$INDEX. $FILENAME : 大小 ${SIZE}B"
  FILE_MAP[$INDEX]=$FILE
  ((INDEX++))
done

echo
read -p "📝 請輸入要還原的備份編號: " SELECTED_INDEX
SELECTED_FILE=${FILE_MAP[$SELECTED_INDEX]}

if [ -z "$SELECTED_FILE" ]; then
  echo "❌ 無效的選項。"
  exit 1
fi

VOLUME_NAME=$(basename "$SELECTED_FILE" | sed -E 's/_backup_.*\.tar\.gz//')

echo "📦 正在還原 volume: $VOLUME_NAME"

# 嘗試建立新的 volume
if docker volume create "$VOLUME_NAME" >/dev/null; then
  if docker run --rm -v "$VOLUME_NAME":/volume -v "$(dirname "$SELECTED_FILE")":/backup busybox \
    sh -c "cd /volume && tar xzf /backup/$(basename "$SELECTED_FILE")"; then
    echo "✅ 還原成功！"
  else
    echo "❌ 還原失敗（解壓縮失敗）"
    exit 1
  fi
else
  echo "❌ 還原失敗（volume 建立失敗）"
  exit 1
fi
