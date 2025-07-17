#!/bin/bash

set -e

# 檢查系統是否為 Ubuntu
if ! grep -qi ubuntu /etc/os-release; then
    echo "❌ 此腳本僅適用於 Ubuntu 系統"
    exit 1
fi

echo "🔍 檢查是否已安裝 Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker 已安裝，版本: $(docker --version)"
    read -p "是否要重新安裝 Docker？[y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "🧹 移除舊版 Docker..."
        sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io
        sudo apt autoremove -y
        sudo rm -rf /var/lib/docker /var/lib/containerd
    else
        echo "⏭️ 跳過 Docker 安裝"
        exit 0
    fi
fi

echo "🛠 開始安裝 Docker Engine..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

# 驗證 Docker 是否成功啟動
if systemctl is-active --quiet docker; then
    echo "✅ Docker 安裝並啟動成功！版本: $(docker --version)"
else
    echo "❌ Docker 安裝完成但未能成功啟動，請檢查 systemctl status docker"
    exit 1
fi

# 加入 docker 群組
sudo usermod -aG docker "$USER"
echo "👤 已將使用者 $USER 加入 docker 群組。"
echo "🔁 請重新登入或執行 'newgrp docker' 以立即生效。"
