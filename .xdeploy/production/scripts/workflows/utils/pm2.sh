#!/bin/bash
# PM2 配置管理辅助函数

# 引入必要的模块
LOCAL_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${LOCAL_SCRIPT_DIR}/logging.sh"
source "${LOCAL_SCRIPT_DIR}/ssh.sh"
source "${LOCAL_SCRIPT_DIR}/common.sh"

# 获取服务器上的 PM2 配置文件
get_server_pm2_config() {
  local server="$1"
  local config_path="$2"
  local temp_dir="${3:-/tmp}"
  local local_path="${temp_dir}/server_pm2_config.js"

  log_server_operation "获取服务器 PM2 配置..."
  if safe_ssh "$server" "test -f $config_path"; then
    safe_scp "$server:$config_path" "$local_path"
    echo "$local_path"
  else
    log_warning "服务器上不存在 PM2 配置文件: $config_path"
    echo "$local_path"
  fi
}

# 合并两个 PM2 配置文件
merge_pm2_configs() {
  # PM2 主配置文件在 Github 构建服务器上的地址
  local server_config="$1"
  # 应用 PM2 配置文件在 用户服务器上的地址
  local app_config="$2"
  # 合并后的 PM2 配置文件在 Github 构建服务器上的地址
  local output_file="$3"
  
  log_info "合并 PM2 配置文件..."
  
  # 使用 TypeScript 脚本合并配置
  local script_dir="${LOCAL_SCRIPT_DIR}"
  local merger_script="${script_dir}/pm2.merger.ts"
  
  if [ ! -f "$merger_script" ]; then
    log_error "合并脚本不存在: $merger_script"
    return 1
  fi
  
  # 使用 npx tsx 执行 TypeScript 脚本，并传递必要参数
  # 注意：$app_config 是服务器端路径，不需要 realpath 处理
  npx tsx "$merger_script" "$(realpath "$server_config")" "$app_config" "$(realpath "$output_file")"
  return $?
}

# 部署 PM2 配置到服务器
deploy_pm2_config() {
  local server="$1"
  local pm2_config="$2"
  local server_path="$3"
  
  log_server_operation "部署 PM2 配置到服务器..."
  
  # 确保目标目录存在
  safe_ssh "$server" "mkdir -p $(dirname "$server_path")"
  
  # 上传配置文件
  safe_scp "$pm2_config" "$server:$server_path"
  
  # 验证上传
  if safe_ssh "$server" "test -f $server_path"; then
    log_success "PM2 配置已成功部署到: $server_path"
    return 0
  else
    log_error "PM2 配置部署失败"
    return 1
  fi
}

# 主要 PM2 配置管理函数
manage_pm2_config() {
  local server="$1"
  local server_config_path="${2:-/xdeploy/pm2/ecosystem.config.js}"
  local app_config_path="$3"
  
  log_info "管理 PM2 配置..."
  
  # 创建临时工作目录
  local temp_dir=$(mktemp -d)
  
  # 获取服务器配置
  local server_config=$(get_server_pm2_config "$server" "$server_config_path" "$temp_dir")
  
  # 合并配置
  local merged_config="${temp_dir}/merged_ecosystem.config.js"
  merge_pm2_configs "$server_config" "$app_config_path" "$merged_config"
  
  # 部署配置
  deploy_pm2_config "$server" "$merged_config" "$server_config_path"
  local deploy_result=$?
  
  # 清理临时目录
  rm -rf "$temp_dir"
  
  return $deploy_result
}

# 使用 PM2 重载应用
reload_pm2_app() {
  local server="$1"
  local app_name="$2"
  local config_path="${3:-/xdeploy/pm2/ecosystem.config.js}"
  
  log_server_operation "重载 PM2 应用..."
  
  # 检查 PM2 是否可用
  if ! safe_ssh "$server" "command -v pm2 &>/dev/null"; then
    log_error "服务器上未安装 PM2"
    return 1
  fi

  # 先尝试根据应用名称重启应用
  if [ -n "$app_name" ]; then
    log_server_operation "尝试重启应用: $app_name"
    if safe_ssh "$server" "pm2 restart $app_name 2>/dev/null"; then
      log_success "应用 $app_name 重启成功"
      # 保存 PM2 配置以便重启后自动恢复
      safe_ssh "$server" "pm2 save"
      return 0
    else
      log_warning "无法重启应用 $app_name，尝试使用配置文件"
    fi
  fi

  # 如果根据应用名称重启失败，尝试使用配置文件重载或启动
  if safe_ssh "$server" "test -f $config_path"; then
    log_server_operation "使用配置文件: $config_path"
    safe_ssh "$server" "pm2 reload $config_path || pm2 start $config_path"
  else
    log_error "未找到 PM2 主配置文件"
    return 1
  fi
  
  # 保存 PM2 配置以便重启后自动恢复
  safe_ssh "$server" "pm2 save"
  
  return 0
}

# 如果脚本被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  log_info "PM2 配置管理工具"
  log_info "此脚本应当被其他脚本导入使用，而不是直接执行"
  exit 1
fi 