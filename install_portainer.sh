#!/bin/bash

set -e

PORTAINER_DIR=./MYL/portainer
PORTAINER_NAME=portainer

echo "🔍 檢查是否已安裝 Portainer..."

# 建立資料夾
if [ ! -d "$PORTAINER_DIR" ]; then
    echo "📁 建立資料夾 $PORTAINER_DIR ..."
    mkdir -p "$PORTAINER_DIR"
else
    echo "📂 資料夾已存在：$PORTAINER_DIR"
fi

# 建立 docker-compose.yml
cd "$PORTAINER_DIR"

if [ ! -f "docker-compose.yml" ]; then
    echo "📝 建立 docker-compose.yml 檔案..."
    cat <<EOF > docker-compose.yml
version: '3'

services:
  $PORTAINER_NAME:
    image: portainer/portainer-ce
    container_name: $PORTAINER_NAME
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

# 檢查容器是否已存在
if docker ps -a --format '{{.Names}}' | grep -qw "$PORTAINER_NAME"; then
    echo "✅ Portainer 容器已存在"
    # 啟動（如果尚未運行）
    if docker ps --format '{{.Names}}' | grep -qw "$PORTAINER_NAME"; then
        echo "🔄 Portainer 已在執行中"
    else
        echo "▶️ 啟動 Portainer 容器..."
        docker compose up -d
    fi
else
    echo "🚀 使用 docker compose 啟動 Portainer ..."
    docker compose up -d
fi

# 檢查啟動是否成功
if docker ps --format '{{.Names}}' | grep -qw "$PORTAINER_NAME"; then
    echo "✅ Portainer 已成功啟動！"
    echo "🌐 請開啟瀏覽器並前往: http://localhost:9000"
else
    echo "❌ Portainer 啟動失敗，請檢查 docker compose 日誌"
fi

cd - > /dev/null  # 回到原本目錄
