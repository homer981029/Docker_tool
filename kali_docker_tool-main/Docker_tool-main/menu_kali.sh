#!/bin/bash

# =============================
# Kali Docker 工具選單 (menu_kali.sh)
# =============================

# --- 強制以 root / sudo 執行 ---
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ 本腳本需以 root / sudo 執行，正在以 sudo 重新啟動..."
  exec sudo "$0" "$@"
fi

# --- 確認必備腳本存在並加執行權限 ---
REQUIRED_SCRIPTS=("install_docker_kali.sh" "install_portainer_kali.sh" "backup_volume_kali.sh" "restore_volume_kali.sh")
for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    chmod +x "$script"
  else
    echo "❌ 缺少必要腳本：$script"
    echo "請確認所有 Kali 版腳本放在同一資料夾。"
    exit 1
  fi
done

# --- 簡單偵測系統類型 ---
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DIST_ID="${ID:-}"
else
  DIST_ID=""
fi

if [ "$DIST_ID" != "kali" ]; then
  echo "⚠️ 偵測到目前不是 Kali (ID=$DIST_ID)，本工具主要針對 Kali 調整。"
  read -p "仍然要繼續執行選單？(y/N): " cont
  cont=${cont:-N}
  if [[ ! "$cont" =~ ^[yY]$ ]]; then
    echo "已取消。"
    exit 1
  fi
fi

show_menu() {
  echo "==============================="
  echo "🛠️ Kali Docker 工具選單"
  echo "==============================="
  echo "1. 安裝 Docker"
  echo "2. 安裝 / 啟動 Portainer"
  echo "3. 備份 Volume"
  echo "4. 還原 Volume"
  echo "5. 移除 Portainer"
  echo "6. 離開"
  echo "==============================="
}

pause() {
  read -p "⏸️ 按 Enter 繼續..."
}

install_docker() {
  bash ./install_docker_kali.sh
  pause
}

install_portainer() {
  bash ./install_portainer_kali.sh
  pause
}

backup_volume() {
  bash ./backup_volume_kali.sh
  pause
}

restore_volume() {
  bash ./restore_volume_kali.sh
  pause
}

uninstall_portainer() {
  echo "🧹 正在移除 Portainer..."

  # 停掉並移除容器
  docker rm -f portainer 2>/dev/null || echo "⚠️ Portainer 容器不存在"

  # 移除資料夾（使用 bind 的情況）
  if [ -d "./MYL/portainer" ]; then
    rm -rf ./MYL/portainer
    echo "🗑️ 已刪除 ./MYL/portainer 目錄"
  fi

  # 如果曾使用命名 volume，可在此一併移除（保留為安全，不強制失敗）
  docker volume rm MYL_portainer_data 2>/dev/null || true

  echo "✅ Portainer 移除完成"
  pause
}

# --- 主選單迴圈 ---
while true; do
  clear
  show_menu
  read -p "請選擇操作項目 [1-6]: " choice
  case $choice in
    1) install_docker ;;
    2) install_portainer ;;
    3) backup_volume ;;
    4) restore_volume ;;
    5) uninstall_portainer ;;
    6) echo "👋 再見！"; exit 0 ;;
    *) echo "❌ 無效選項"; pause ;;
  esac
done
