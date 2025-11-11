#!/bin/bash
set -e

echo "🐉 Kali Docker 安裝工具 (install_docker_kali.sh)"

# --- 必須 root / sudo 執行 ---
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ 本腳本需以 root / sudo 執行，正在以 sudo 重新啟動..."
  exec sudo "$0" "$@"
fi

# --- 偵測系統 ---
DIST_ID=""
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DIST_ID="${ID:-}"
fi

if [ "$DIST_ID" != "kali" ]; then
  echo "⚠️ 偵測到目前不是 Kali (ID=$DIST_ID)，本腳本主要針對 Kali。"
  read -p "仍要繼續安裝 Docker？(y/N): " cont
  cont=${cont:-N}
  if [[ ! "$cont" =~ ^[yY]$ ]]; then
    echo "已取消。"
    exit 1
  fi
fi

# --- 若已安裝，詢問是否重新安裝 ---
echo "🔍 檢查是否已安裝 Docker..."
if command -v docker &>/dev/null; then
  echo "✅ 偵測到 Docker: $(docker --version)"
  read -p "是否要重新安裝 Docker？[y/N]: " confirm
  confirm=${confirm:-N}
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "🧹 移除舊版 Docker 與相關套件..."
    apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io || true
    apt autoremove -y || true
    rm -rf /var/lib/docker /var/lib/containerd || true
  else
    echo "⏭️ 跳過 Docker 安裝。"
    exit 0
  fi
fi

echo "🛠 使用 Kali 套件庫安裝 Docker..."
apt update
apt install -y \
  docker.io \
  docker-compose-plugin \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# 啟用並啟動 Docker
systemctl enable docker || true
systemctl start docker || true

# 驗證 Docker 狀態
if systemctl is-active --quiet docker; then
  echo "✅ Docker 安裝並啟動成功！版本: $(docker --version)"
else
  echo "❌ Docker 安裝完成但未成功啟動，請檢查：systemctl status docker"
  exit 1
fi

# --- 加入 docker 群組 ---
TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  # 若無 SUDO_USER，就詢問要加誰
  read -p "請輸入要加入 docker 群組的使用者帳號（留空略過）: " INPUT_USER
  if [ -n "$INPUT_USER" ]; then
    TARGET_USER="$INPUT_USER"
  fi
fi

if [ -n "$TARGET_USER" ] && id "$TARGET_USER" &>/dev/null; then
  echo "👤 將使用者 $TARGET_USER 加入 docker 群組..."
  groupadd -f docker
  usermod -aG docker "$TARGET_USER"
  echo "🔁 請讓 $TARGET_USER 重新登入，或在該帳號執行：newgrp docker"
else
  echo "ℹ️ 未設定要加入 docker 群組的非 root 使用者，如有需要可手動執行：usermod -aG docker <username>"
fi

echo "🎉 Docker 安裝程序完成！"
