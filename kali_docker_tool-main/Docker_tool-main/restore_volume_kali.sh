#!/bin/bash
set -e

echo "📦 Docker Volume 還原工具 (restore_volume_kali.sh)"

# --- 必須 root / sudo ---
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ 建議以 root / sudo 執行，正在以 sudo 重新啟動..."
  exec sudo "$0" "$@"
fi

# --- 檢查 Docker ---
if ! command -v docker &>/dev/null; then
  echo "❌ 未找到 docker 指令，請先安裝 Docker。"
  exit 1
fi

BACKUP_DIR="./Backup_volumes"

# 確認備份資料夾存在
if [ ! -d "$BACKUP_DIR" ]; then
  echo "❌ 找不到備份資料夾: $BACKUP_DIR"
  exit 1
fi

# 列出所有備份檔
mapfile -t FILES < <(find "$BACKUP_DIR" -maxdepth 1 -name "*.tar.gz" | sort)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "❌ 沒有可還原的備份檔。"
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
SELECTED_FILE=${FILE_MAP[$SELECTED_INDEX]:-}

if [ -z "$SELECTED_FILE" ]; then
  echo "❌ 無效的選項。"
  exit 1
fi

VOLUME_NAME=$(basename "$SELECTED_FILE" | sed -E 's/_backup_.*\.tar\.gz//')

if [ -z "$VOLUME_NAME" ]; then
  echo "❌ 無法從檔名解析 volume 名稱。"
  exit 1
fi

echo "📦 正在還原到 volume: $VOLUME_NAME"

# 如果 volume 不存在就建立
if ! docker volume ls -q | grep -qw "$VOLUME_NAME"; then
  echo "🔧 Volume 不存在，建立新 volume：$VOLUME_NAME"
  docker volume create "$VOLUME_NAME" >/dev/null
fi

# 將備份內容解壓進 volume
if docker run --rm \
  -v "$VOLUME_NAME":/volume \
  -v "$(dirname "$SELECTED_FILE")":/backup \
  busybox sh -c "cd /volume && tar xzf /backup/$(basename "$SELECTED_FILE")"
then
  echo "✅ 還原成功！Volume：$VOLUME_NAME"
else
  echo "❌ 還原失敗（解壓縮或 docker run 發生錯誤）"
  exit 1
fi
