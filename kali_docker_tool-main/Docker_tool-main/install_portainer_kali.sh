#!/bin/bash
set -e

# =============================
# Kali Portainer 安裝/啟動工具
# =============================

# --- 強制以 root / sudo 執行 ---
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ 本腳本需以 root / sudo 執行，正在以 sudo 重新啟動..."
  exec sudo "$0" "$@"
fi

PORTAINER_DIR=./MYL/portainer
PORTAINER_NAME=portainer

echo "🔍 檢查 Docker 是否可用..."
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ 尚未安裝 Docker，請先在選單中執行「安裝 Docker」。"
  exit 1
fi

echo "🔍 檢查是否已安裝 Portainer..."

# 建立資料夾
if [ ! -d "$PORTAINER_DIR" ]; then
  echo "📁 建立資料夾 $PORTAINER_DIR ..."
  mkdir -p "$PORTAINER_DIR"
else
  echo "📂 資料夾已存在：$PORTAINER_DIR"
fi

# 進入 Portainer 目錄
cd "$PORTAINER_DIR"

# 建立 docker-compose.yml（使用 CE 版 + 最新建議語法）
if [ ! -f "docker-compose.yml" ]; then
  echo "📝 建立 docker-compose.yml 檔案..."
  cat <<EOF > docker-compose.yml
version: '3.8'

services:
  ${PORTAINER_NAME}:
    image: portainer/portainer-ce:latest
    container_name: ${PORTAINER_NAME}
    restart: always
    ports:
      - "9000:9000"
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
EOF
else
  echo "📄 docker-compose.yml 已存在，略過建立"
fi

# 檢查 docker compose 指令
if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  COMPOSE_CMD="docker compose"
fi

# 檢查容器是否已存在
if docker ps -a --format '{{.Names}}' | grep -qw "$PORTAINER_NAME"; then
  echo "✅ Portainer 容器已存在"
  # 啟動（如果尚未運行）
  if docker ps --format '{{.Names}}' | grep -qw "$PORTAINER_NAME"; then
    echo "🔄 Portainer 已在執行中"
  else
    echo "▶️ 啟動已存在的 Portainer 容器..."
    $COMPOSE_CMD up -d
  fi
else
  echo "🚀 使用 $COMPOSE_CMD 啟動 Portainer ..."
  $COMPOSE_CMD up -d
fi

# 檢查啟動是否成功
if docker ps --format '{{.Names}}' | grep -qw "$PORTAINER_NAME"; then
  echo "✅ Portainer 已成功啟動！"
  echo "🌐 請開啟瀏覽器並前往: http://localhost:9000"
else
  echo "❌ Portainer 啟動失敗，請使用以下指令檢查："
  echo "   cd $PORTAINER_DIR && $COMPOSE_CMD logs"
fi

cd - > /dev/null  # 回到原本目錄
