#!/bin/bash

set -e

echo "📦 正在查詢 Docker volumes..."

# 取得目前所有 volume 名稱
mapfile -t VOLUMES < <(docker volume ls -q)

if [ ${#VOLUMES[@]} -eq 0 ]; then
  echo "❌ 沒有可用的 Docker volumes。"
  exit 1
fi

echo
echo "以下是目前的 volumes:"
INDEX=1
declare -A VOLUME_MAP

for VOL in "${VOLUMES[@]}"; do
  CONTAINERS=$(docker ps -a --filter volume="$VOL" --format "{{.Names}}" | paste -sd "," -)
  [ -z "$CONTAINERS" ] && CONTAINERS="未使用"
  echo "$INDEX. $VOL : $CONTAINERS"
  VOLUME_MAP[$INDEX]=$VOL
  ((INDEX++))
done

echo
read -p "📝 請輸入要備份的 volume 編號: " SELECTED_INDEX
SELECTED_VOLUME=${VOLUME_MAP[$SELECTED_INDEX]}

if [ -z "$SELECTED_VOLUME" ]; then
  echo "❌ 無效的選項。請輸入有效的數字編號。"
  exit 1
fi
# 建立備份資料夾
BACKUP_DIR="./Backup_volumes"
mkdir -p "$BACKUP_DIR" || { echo "❌ 無法建立備份資料夾。"; exit 1; }

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="${SELECTED_VOLUME}_backup_${TIMESTAMP}.tar.gz"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILENAME"

echo "📤 正在備份 volume: $SELECTED_VOLUME..."
if docker run --rm -v "${SELECTED_VOLUME}":/volume -v "${BACKUP_DIR}":/backup busybox \
  sh -c "tar czf /backup/${BACKUP_FILENAME} -C /volume ."; then

  if [ -f "$BACKUP_FILE" ]; then
    FILESIZE=$(du -BG "$BACKUP_FILE" | cut -f1)
    echo "✅ 備份成功！名稱：${BACKUP_FILENAME}，大小為 ${FILESIZE}B"
  else
    echo "❌ 備份失敗，找不到備份檔案。"
    exit 1
  fi

else
  echo "❌ 備份失敗！正在清理暫存檔案..."
  [ -f "$BACKUP_FILE" ] && rm -f "$BACKUP_FILE"
  exit 1
fi

