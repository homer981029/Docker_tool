#!/bin/bash

# --- 強制以 sudo 執行 ---
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ 本腳本需以 sudo 執行。正在重新啟動..."
  exec sudo "$0" "$@"
fi

# --- 自動加執行權限 ---
REQUIRED_SCRIPTS=("install_docker.sh" "install_portainer.sh" "backup_volume.sh" "restore_volume.sh")
for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    chmod +x "$script"
  else
    echo "❌ 缺少必要腳本：$script"
    exit 1
  fi
done

show_menu() {
    echo "==============================="
    echo "🛠️ Docker 工具選單"
    echo "==============================="
    echo "1. 安裝 Docker"
    echo "2. 安裝 Portainer"
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
    sudo bash ./install_docker.sh
    pause
}

install_portainer() {
    sudo bash ./install_portainer.sh
    pause
}

backup_volume() {
    sudo bash ./backup_volume.sh
    pause
}

restore_volume() {
    sudo bash ./restore_volume.sh
    pause
}

uninstall_portainer() {
    echo "🧹 正在移除 Portainer..."
    docker rm -f portainer 2>/dev/null || echo "⚠️ 容器不存在"
    docker volume rm MYL_portainer_data 2>/dev/null || true
    rm -rf ./MYL/portainer
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

