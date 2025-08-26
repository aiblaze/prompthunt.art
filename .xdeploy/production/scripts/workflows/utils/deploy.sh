#!/bin/bash
# 部署相关的辅助函数

# 引入必要的模块
LOCAL_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${LOCAL_SCRIPT_DIR}/logging.sh"
source "${LOCAL_SCRIPT_DIR}/ssh.sh"

# 设置应用目录结构
setup_app_directories() {
  local server="$1"
  local app_dir="$2"

  log_server_operation "创建应用目录结构..."
  safe_ssh "$server" "mkdir -p $app_dir"
}

# 登录到容器仓库
login_container_registry() {
  local server="$1"
  local registry_url="$2"
  local username="$3"
  local password="$4"

  log_server_operation "登录到容器仓库..."
  safe_ssh "$server" "echo '$password' | docker login $registry_url \
    --username $username \
    --password-stdin"
}

# 拉取应用镜像
pull_app_image() {
  local server="$1"
  local image_url="$2"

  log_server_operation "拉取应用镜像..."
  safe_ssh "$server" "docker pull $image_url"
}

# 创建环境配置文件
create_env_file() {
  local server="$1"
  local app_dir="$2"
  local env_file="$3"

  log_server_operation "处理运行时环境变量..."
  if [ -f "$env_file" ]; then
    # 创建临时工作目录
    TEMP_DIR=$(mktemp -d)
    ENV_RUN_FILE="${TEMP_DIR}/.env"

    # 复制模板
    cp "$env_file" "$ENV_RUN_FILE"

    # 上传到服务器
    safe_scp "$ENV_RUN_FILE" "$server:$app_dir/.env"

    # 清理
    rm -rf "$TEMP_DIR"
  else
    log_warning "运行时环境变量模板不存在，跳过运行时环境变量配置"
  fi
}

# 启动应用服务
start_app_service() {
  local server="$1"
  local app_dir="$2"
  local port="${3:-80}"  # 默认端口 80

  log_server_operation "启动应用服务..."
  safe_ssh "$server" "cd $app_dir && \
    # 1. 安全清理当前项目
    echo 'Cleaning up  project...'
    if command -v docker-compose &> /dev/null; then
      docker-compose down || true
      docker-compose down --remove-orphans || true
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
      docker compose down || true
      docker compose down --remove-orphans || true
    fi

    # 2. 检查端口占用
    echo 'Checking port availability...'
    if netstat -tlnp | grep :$port; then
      echo 'Warning: Port $port is in use'
      netstat -tlnp | grep :$port
    fi

    # 3. 拉取最新镜像并启动服务
    if command -v docker-compose &> /dev/null; then
      echo '使用 docker-compose 命令...'
      docker-compose pull && docker-compose up -d
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
      echo '使用 docker compose 命令（新格式）...'
      docker compose pull && docker compose up -d
    else
      echo '错误: 未找到 docker-compose 命令'
      exit 1
    fi"
}

# 检查应用健康状态
check_app_health() {
  local server="$1"
  local app_name="$2"
  local port="$3"
  local timeout="${4:-30}"
  local max_attempts="${5:-6}"
  local health_check_path="${6:-/}"
  local attempt=1

  log_server_operation "检查应用健康状态..."

  # 等待容器启动
  sleep 5

  # 循环检查健康状态，最多尝试 max_attempts 次
  while [ $attempt -le $max_attempts ]; do
    log_info "健康检查尝试 $attempt/$max_attempts..."

    # 方法1：利用 Docker 内置的健康检查（优先）
    if safe_ssh "$server" "docker inspect --format='{{.State.Health.Status}}' $app_name 2>/dev/null | grep -q 'healthy'"; then
      log_success "应用健康检查通过（Docker 健康检查）"
      return 0

    # 方法2：通过容器内部检查 HTTP 状态码
    elif safe_ssh "$server" "docker exec $app_name curl -s --max-time 10 -o /dev/null -w '%{http_code}' http://localhost:$port$health_check_path | grep -q '^2[0-9][0-9]$'"; then
      log_success "应用运行正常（通过容器内部检查）"
      return 0

    # 方法3：通过Docker网络访问检查 HTTP 状态码
    elif safe_ssh "$server" "curl -s --max-time 10 -o /dev/null -w '%{http_code}' http://$app_name:$port$health_check_path | grep -q '^2[0-9][0-9]$'"; then
      log_success "应用运行正常（通过Docker网络检查）"
      return 0

    # 方法4：通过主机网络访问检查（如果端口映射到主机）
    elif safe_ssh "$server" "curl -s --max-time 10 -o /dev/null -w '%{http_code}' http://localhost:$port$health_check_path | grep -q '^2[0-9][0-9]$'"; then
      log_success "应用运行正常（通过主机网络检查）"
      return 0
    fi

    # 如果容器不在运行状态，直接失败
    if ! safe_ssh "$server" "docker ps | grep -q \"$app_name\""; then
      log_error "容器未运行，健康检查失败"
      return 1
    fi

    # 等待一段时间后重试
    sleep $(( timeout / max_attempts ))
    attempt=$((attempt + 1))
  done

  # 所有尝试都失败，但容器仍在运行
  if safe_ssh "$server" "docker ps | grep -q \"$app_name\""; then
    log_warning "容器正在运行，但健康检查未通过"
    return 1
  else
    log_error "容器未运行，健康检查失败"
    return 1
  fi
}
