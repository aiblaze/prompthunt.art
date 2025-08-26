#!/bin/bash
# 应用部署脚本
# 将应用部署到指定服务器，包括设置目录、部署镜像和配置文件等

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
SERVER="$1"
APP_NAME="$2"
APP_DIR="$3"
APP_PORT="$4"
APP_PORT_DOCKER="$5"
IMAGE_NAME="$6"
IMAGE_TAG="$7"
REGISTRY_URL="$8"
REGISTRY_NAMESPACE="$9"
REGISTRY_USERNAME="${10}"
REGISTRY_PASSWORD="${11}"
COMPOSE_FILE="${12}"
CHECK_ONLY="${13}"

# 参数验证
if [ -z "$SERVER" ] || [ -z "$APP_NAME" ] || [ -z "$APP_DIR" ] || \
   [ -z "$APP_PORT" ] || [ -z "$APP_PORT_DOCKER" ] || [ -z "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ] || \
   [ -z "$REGISTRY_URL" ] || [ -z "$REGISTRY_NAMESPACE" ] || \
   [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_PASSWORD" ] || [ -z "$COMPOSE_FILE" ]; then
  log_github_error "缺少必要参数"
  echo "用法: $0 <server> <app_name> <app_dir> <port> <docker_port> <image_name> <tag> <registry_url> <namespace> <username> <password> <compose_file> [env_vars]" >&2
  exit 1
fi

# 主要功能实现
log_github_group_start "应用部署"

if [ "$CHECK_ONLY" = "true" ]; then
  log_info "仅执行健康检查"
  # 健康检查
  check_app_health "$SERVER" "$APP_NAME" "$APP_PORT_DOCKER" "30" "6" "/"
  HEALTH_CHECK_RESULT=$?

  if [ $HEALTH_CHECK_RESULT -eq 0 ]; then
    log_success "应用运行正常"
  else
    log_warning "应用可能未正常运行，请检查日志"
    safe_ssh "$SERVER" "docker logs $APP_NAME --tail 50"
  fi

  log_github_group_end
  exit $HEALTH_CHECK_RESULT
fi

log_info "开始部署应用到服务器: $SERVER"
log_info "应用名称: $APP_NAME"
log_info "应用目录: $APP_DIR"
log_info "应用端口: $APP_PORT"
log_info "Docker 端口: $APP_PORT_DOCKER"
log_info "镜像名称: $IMAGE_NAME"
log_info "镜像标签: $IMAGE_TAG"

# 构建完整的镜像 URL
IMAGE_URL="$REGISTRY_URL/$REGISTRY_NAMESPACE/$IMAGE_NAME:$IMAGE_TAG"
log_info "镜像 URL: $IMAGE_URL"

# 设置目录结构
setup_app_directories "$SERVER" "$APP_DIR"

# 登录到容器仓库
login_container_registry "$SERVER" "$REGISTRY_URL" "$REGISTRY_USERNAME" "$REGISTRY_PASSWORD"

# 拉取应用镜像
pull_app_image "$SERVER" "$IMAGE_URL"

# 上传 docker-compose.yml
log_server_operation "上传 docker-compose.yml..."
safe_scp "$COMPOSE_FILE" "$SERVER:$APP_DIR/docker-compose.yml"

# 处理运行时环境变量
ENV_RUN_TEMPLATE="${SCRIPT_DIR}/../../configs/env.run"
create_env_file "$SERVER" "$APP_DIR" "$ENV_RUN_TEMPLATE"

# 启动应用服务
start_app_service "$SERVER" "$APP_DIR" "$APP_PORT"

# 健康检查
check_app_health "$SERVER" "$APP_NAME" "$APP_PORT_DOCKER" "30" "6" "/"
HEALTH_CHECK_RESULT=$?

if [ $HEALTH_CHECK_RESULT -eq 0 ]; then
  log_success "应用部署成功"
else
  log_warning "应用可能未正常启动，请检查日志"
  safe_ssh "$SERVER" "docker logs $APP_NAME --tail 50"
fi

log_github_group_end

# 输出摘要
print_separator
log_info "部署完成"
print_summary_item "服务器" "$SERVER"
print_summary_item "应用名称" "$APP_NAME"
print_summary_item "应用目录" "$APP_DIR"
print_summary_item "应用端口" "$APP_PORT"
print_summary_item "镜像名称" "$IMAGE_NAME"
print_summary_item "镜像标签" "$IMAGE_TAG"
print_summary_item "部署状态" "$([ $HEALTH_CHECK_RESULT -eq 0 ] && echo "成功" || echo "警告")"
print_separator

exit $HEALTH_CHECK_RESULT 