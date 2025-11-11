#!/bin/bash
set -e

echo "📦 Docker Volume 備份工具 (backup_volume_kali.sh)"

# --- 必須 root / sudo（主要為了避免權限問題） ---
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ 建議以 root / sudo 執行，正在以 sudo 重新啟動..."
  exec sudo "$0" "$@"
fi

# --- 檢查 Docker ---
if ! command -v docker &>/dev/null; then
  echo "❌ 未找到 docker 指令，請先安裝 Docker。"
  exit 1
fi

echo "🔍 正在查詢 Docker volumes..."

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
SELECTED_VOLUME=${VOLUME_MAP[$SELECTED_INDEX]:-}

if [ -z "$SELECTED_VOLUME" ]; then
  echo "❌ 無效的選項，請輸入有效的數字編號。"
  exit 1
fi

# 建立備份資料夾
BACKUP_DIR="./Backup_volumes"
mkdir -p "$BACKUP_DIR" || { echo "❌ 無法建立備份資料夾。"; exit 1; }

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="${SELECTED_VOLUME}_backup_${TIMESTAMP}.tar.gz"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILENAME"

echo "📤 正在備份 volume: $SELECTED_VOLUME → $BACKUP_FILE"

if docker run --rm \
  -v "${SELECTED_VOLUME}":/volume \
  -v "${BACKUP_DIR}":/backup \
  busybox sh -c "cd /volume && tar czf /backup/${BACKUP_FILENAME} ."
then
  if [ -f "$BACKUP_FILE" ]; then
    FILESIZE=$(du -BG "$BACKUP_FILE" | cut -f1)
    echo "✅ 備份成功！檔案：${BACKUP_FILENAME}，大小：${FILESIZE}B"
  else
    echo "❌ 備份失敗，找不到備份檔案。"
    exit 1
  fi
else
  echo "❌ 備份失敗！正在清理暫存檔案..."
  [ -f "$BACKUP_FILE" ] && rm -f "$BACKUP_FILE"
  exit 1
fi
