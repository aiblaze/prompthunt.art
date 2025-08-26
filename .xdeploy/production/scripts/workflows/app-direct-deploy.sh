#!/bin/bash
# 应用直接部署脚本（无需 Docker）
# 将应用直接部署到指定服务器，包括设置目录、上传构建产物和配置文件等

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"
source "${SCRIPT_DIR}/utils/pm2.sh"

# 参数解析
SERVER="$1"
APP_NAME="$2"
APP_DEPLOY_DIR="$3"
APP_DEPLOY_ENV="${4:-production}"
APP_PORT="$5"
BUILD_DIR="$6"
CLEAN_BEFORE_DEPLOY="$7"
RUN_INSTALL_AFTER_DEPLOY="$8"
PACKAGE_MANAGER="${9:-pnpm}"
PM2_CONFIG_PATH="${10:-/xdeploy/pm2/ecosystem.config.js}"

# 参数验证
if [ -z "$SERVER" ] || [ -z "$APP_NAME" ] || [ -z "$APP_DEPLOY_DIR" ] || [ -z "$APP_PORT" ] || [ -z "$BUILD_DIR" ]; then
  log_github_error "缺少必要参数"
  echo "用法: $0 <server> <app_name> <app_deploy_dir> <app_deploy_env> <port> <build_dir> [clean_before_deploy] [run_install_after_deploy] [package_manager] [pm2_config_path]" >&2
  exit 1
fi

# 主要功能实现
log_github_group_start "应用直接部署"

log_info "开始部署应用到服务器: $SERVER"
log_info "应用名称: $APP_NAME"
log_info "应用目录: $APP_DEPLOY_DIR"
log_info "应用部署环境: $APP_DEPLOY_ENV"
log_info "应用端口: $APP_PORT"
log_info "构建目录: $BUILD_DIR"
log_info "清理目标目录: $CLEAN_BEFORE_DEPLOY"
log_info "部署后运行安装: $RUN_INSTALL_AFTER_DEPLOY"
log_info "包管理器: $PACKAGE_MANAGER"
log_info "PM2 主配置路径: $PM2_CONFIG_PATH"

# 确保目标目录存在
log_server_operation "创建应用目录结构..."
safe_ssh "$SERVER" "mkdir -p $APP_DEPLOY_DIR/logs"
safe_ssh "$SERVER" "mkdir -p $APP_DEPLOY_DIR/scripts"

# 如果需要清理目标目录
if [ "$CLEAN_BEFORE_DEPLOY" = "true" ]; then
  log_server_operation "清理目标目录..."
  safe_ssh "$SERVER" "rm -rf $APP_DEPLOY_DIR/*"
  safe_ssh "$SERVER" "mkdir -p $APP_DEPLOY_DIR/logs"
  safe_ssh "$SERVER" "mkdir -p $APP_DEPLOY_DIR/scripts"
fi

# 上传构建产物
if ! safe_tar_transfer "$BUILD_DIR" "$SERVER" "$APP_DEPLOY_DIR" "上传构建产物"; then
  log_error "构建产物上传失败"
  log_error "请确保构建步骤成功完成并生成了构建产物"
  exit 1
fi
log_success "构建产物上传完成"

# 上传脚本文件（`scripts/server`）至服务器 `//xdeploy/apps/prompthunt/production/scripts`
SERVER_SCRIPTS_DIR="${SCRIPT_DIR}/../server"
if [ -d "$SERVER_SCRIPTS_DIR" ] && [ "$(ls -A "$SERVER_SCRIPTS_DIR" 2>/dev/null)" ]; then
  if ! safe_tar_transfer "$SERVER_SCRIPTS_DIR" "$SERVER" "$APP_DEPLOY_DIR/scripts" "上传脚本文件"; then
    log_error "脚本文件上传失败"
    exit 1
  fi
  log_success "脚本文件上传完成"
else
  log_warning "服务器脚本目录 $SERVER_SCRIPTS_DIR 为空或不存在，跳过上传"
fi

# 处理运行时环境变量
ENV_RUN_TEMPLATE="${SCRIPT_DIR}/../../configs/env.run"
create_env_file "$SERVER" "$APP_DEPLOY_DIR" "$ENV_RUN_TEMPLATE"

# 上传 package.json 和锁文件
if [ -f "package.json" ]; then
  log_server_operation "上传 package.json..."
  safe_scp "package.json" "$SERVER:$APP_DEPLOY_DIR/"
fi

for lockfile in package-lock.json yarn.lock pnpm-lock.yaml bun.lockb; do
  if [ -f "$lockfile" ]; then
    log_server_operation "上传 $lockfile..."
    safe_scp "$lockfile" "$SERVER:$APP_DEPLOY_DIR/"
  fi
done

# 如果需要在服务器上运行依赖安装
if [ "$RUN_INSTALL_AFTER_DEPLOY" = "true" ]; then
  log_server_operation "服务器上安装依赖..."
  case "$PACKAGE_MANAGER" in
    npm)
      safe_ssh "$SERVER" "cd $APP_DEPLOY_DIR && npm install --production"
      ;;
    yarn)
      safe_ssh "$SERVER" "cd $APP_DEPLOY_DIR && yarn install --production"
      ;;
    pnpm)
      safe_ssh "$SERVER" "cd $APP_DEPLOY_DIR && pnpm install --prod"
      ;;
    bun)
      safe_ssh "$SERVER" "cd $APP_DEPLOY_DIR && bun install --production"
      ;;
    *)
      log_warning "未知的包管理器: $PACKAGE_MANAGER, 使用 npm 代替"
      safe_ssh "$SERVER" "cd $APP_DEPLOY_DIR && npm install --production"
      ;;
  esac
fi

# 管理 PM2 配置
log_server_operation "管理 PM2 配置..."
APP_PM2_CONFIG_PATH="${APP_DEPLOY_DIR}/scripts/pm2.config.js"
manage_pm2_config "$SERVER" "$PM2_CONFIG_PATH" "$APP_PM2_CONFIG_PATH"

# 启动或重启应用
log_server_operation "启动或重启应用..."
reload_pm2_app "$SERVER" "$APP_NAME" "$PM2_CONFIG_PATH"

# 等待应用启动
log_server_operation "等待应用启动..."
sleep 5

# 检查应用是否运行
log_server_operation "检查应用状态..."
safe_ssh "$SERVER" "pm2 show $APP_NAME"

# 健康检查
log_info "进行健康检查..."
# HTTP 状态码检查
if safe_ssh "$SERVER" "curl -s --max-time 10 -o /dev/null -w '%{http_code}' http://localhost:$APP_PORT/ | grep -q '200'"; then
  log_success "应用运行正常，HTTP状态码: 200"
  HEALTH_CHECK_RESULT=0
elif safe_ssh "$SERVER" "curl -s --max-time 10 -o /dev/null -w '%{http_code}' http://localhost:$APP_PORT/ | grep -qE '2[0-9][0-9]'"; then
  log_success "应用运行正常，HTTP状态码: 2xx"
  HEALTH_CHECK_RESULT=0
else
  log_warning "应用可能未正常运行，请检查日志"
  log_info "尝试检查应用进程状态..."
  safe_ssh "$SERVER" "pm2 logs $APP_NAME --lines 20"
  HEALTH_CHECK_RESULT=1
fi

log_github_group_end

# 输出摘要
print_separator
log_info "部署完成"
print_summary_item "服务器" "$SERVER"
print_summary_item "应用名称" "$APP_NAME"
print_summary_item "应用目录" "$APP_DEPLOY_DIR"
print_summary_item "应用部署环境" "$APP_DEPLOY_ENV"
print_summary_item "应用端口" "$APP_PORT"
print_summary_item "构建目录" "$BUILD_DIR"
print_summary_item "PM2 主配置路径" "$PM2_CONFIG_PATH"
print_summary_item "应用 PM2 配置路径" "$APP_PM2_CONFIG_PATH"
print_summary_item "部署状态" "$([ $HEALTH_CHECK_RESULT -eq 0 ] && echo "成功" || echo "警告")"
print_separator

exit $HEALTH_CHECK_RESULT 