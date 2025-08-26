#!/bin/bash
# 证书更新后处理脚本
# 在证书更新后执行的操作，如重载 Nginx 等

set -e

# 脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 日志文件
LOG_FILE="/var/log/cert-renewal-post.log"

# 记录日志
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

log "证书更新后处理开始"

# 检查证书是否存在
CERT_DIR=${CERT_DIR:-"/etc/letsencrypt/certs/live"}
if [ ! -d "$CERT_DIR" ]; then
  log "错误: 证书目录 $CERT_DIR 不存在"
  exit 1
fi

# 列出更新的证书
log "已更新的证书目录: $CERT_DIR"
ls -la "$CERT_DIR" 2>/dev/null || echo "证书目录不存在"

# 重载 Nginx 配置
log "重载 Nginx 配置..."
if [ -f "$SCRIPT_DIR/nginx-reload.sh" ]; then
  bash "$SCRIPT_DIR/nginx-reload.sh"
  RELOAD_STATUS=$?
  
  if [ $RELOAD_STATUS -eq 0 ]; then
    log "Nginx 重载成功"
  else
    log "警告: Nginx 重载失败，退出码: $RELOAD_STATUS"
  fi
else
  log "警告: nginx-reload.sh 脚本不存在，尝试直接重载 Nginx"
  
  # 直接重载 Nginx
  if command -v nginx >/dev/null 2>&1 && sudo nginx -t >/dev/null 2>&1 && sudo systemctl reload nginx; then
    log "Nginx 直接重载成功"
  else
    log "警告: Nginx 直接重载失败或 Nginx 未安装，尝试重启 Docker 容器"
    
    # 定义 Docker Compose 命令函数
    run_docker_compose() {
      local compose_dir="$1"
      local cmd="$2"
      
      cd "$compose_dir"
      
      # 检查 docker-compose 命令是否存在
      if command -v docker-compose >/dev/null 2>&1; then
        log "使用 docker-compose 命令..."
        docker-compose $cmd
        return $?
      # 检查 docker compose 命令是否存在
      elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        log "使用 docker compose 命令(新格式)..."
        docker compose $cmd
        return $?
      else
        log "错误: 未找到 docker-compose 或 docker compose 命令"
        return 1
      fi
    }
    
    # 尝试重启使用证书的 Docker 容器
    DOCKER_COMPOSE_DIR="/docker"
    if [ -d "$DOCKER_COMPOSE_DIR" ]; then
      log "查找使用证书的 Docker Compose 服务..."
      
      # 查找包含证书目录的 docker-compose.yml 文件
      COMPOSE_FILES=$(find "$DOCKER_COMPOSE_DIR" -name "docker-compose.yml" -type f -exec grep -l "$CERT_DIR" {} \; 2>/dev/null)
      
      if [ -n "$COMPOSE_FILES" ]; then
        for compose_file in $COMPOSE_FILES; do
          compose_dir=$(dirname "$compose_file")
          log "重启 Docker Compose 服务: $compose_dir"
          
          if run_docker_compose "$compose_dir" "restart"; then
            log "Docker Compose 服务重启成功: $compose_dir"
          else
            log "警告: Docker Compose 服务重启失败: $compose_dir"
          fi
        done
      else
        log "未找到使用证书的 Docker Compose 服务"
      fi
    else
      log "$DOCKER_COMPOSE_DIR 目录不存在"
    fi
  fi
fi

# 其他可能的后处理操作
# ...

log "证书更新后处理完成"
exit 0
