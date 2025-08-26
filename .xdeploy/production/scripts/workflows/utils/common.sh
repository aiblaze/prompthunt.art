#!/bin/bash
# 通用辅助函数模块
# 包含各种通用的辅助函数

# 导入日志函数
LOCAL_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${LOCAL_SCRIPT_DIR}/logging.sh"

#######################
# 通用辅助函数
#######################

# 检查命令是否存在
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 检查变量是否为空
check_var_not_empty() {
  local var_name="$1"
  local var_value="$2"
  
  if [ -z "$var_value" ]; then
    log_github_error "变量 $var_name 为空"
    return 1
  fi
  
  return 0
}

# 安全地执行 SSH 命令
safe_ssh() {
  local server="$1"
  local command="$2"
  
  log_server_operation "在 $server 上执行: $command"
  ssh "$server" "$command"
  local status=$?
  
  if [ $status -ne 0 ]; then
    log_warning "SSH 命令执行失败，退出码: $status"
  fi
  
  return $status
}

# 安全地执行 SCP 命令
safe_scp() {
  # 获取所有参数
  local args=("$@")
  local last_arg="${args[-1]}"
  local source_args=("${args[@]:0:$((${#args[@]} - 1))}")
  
  log_server_operation "复制 ${source_args[*]} 到 $last_arg"
  scp "${args[@]}"
  local status=$?
  
  if [ $status -ne 0 ]; then
    log_warning "SCP 命令执行失败，退出码: $status"
  fi
  
  return $status
}

# 使用 tar + ssh 管道安全地传输目录
safe_tar_transfer() {
  local source_dir="$1"
  local server="$2"
  local dest_dir="$3"
  local operation_name="${4:-文件传输}"
  
  log_server_operation "$operation_name: $source_dir -> $server:$dest_dir"
  
  # 确保源目录存在且不为空
  if [ ! -d "$source_dir" ] || [ -z "$(ls -A "$source_dir" 2>/dev/null)" ]; then
    log_error "源目录 $source_dir 不存在或为空"
    return 1
  fi
  
  # 确保目标目录存在
  safe_ssh "$server" "mkdir -p '$dest_dir'"
  
  # 使用 tar + ssh 管道传输
  tar -czf - -C "$source_dir" . | ssh "$server" "cd '$dest_dir' && tar -xzf -"
  local status=$?
  
  if [ $status -ne 0 ]; then
    log_warning "$operation_name 失败，退出码: $status"
  fi
  
  return $status
}

# 设置 GitHub Actions 输出变量
set_github_output() {
  local name="$1"
  local value="$2"
  
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "$name=$value" >> "$GITHUB_OUTPUT"
  else
    log_warning "GITHUB_OUTPUT 环境变量未设置，无法设置输出变量"
  fi
}

# 获取当前时间戳
get_timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

# 获取 GitHub Actions 输出变量
get_github_output() {
  local name="$1"
  
  if [ -n "$GITHUB_OUTPUT" ] && [ -f "$GITHUB_OUTPUT" ]; then
    grep "^${name}=" "$GITHUB_OUTPUT" | tail -1 | cut -d'=' -f2-
  else
    log_warning "GITHUB_OUTPUT 环境变量未设置或文件不存在，无法获取输出变量"
    return 1
  fi
}

# 如果脚本被直接执行而不是被导入，则显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "此脚本包含通用辅助函数，不应直接执行" >&2
  echo "请在其他脚本中使用 source 命令导入此脚本" >&2
  
  echo "" >&2
  echo "可用函数列表:" >&2
  echo "  - command_exists: 检查命令是否存在" >&2
  echo "  - check_var_not_empty: 检查变量是否为空" >&2
  echo "  - safe_ssh: 安全地执行 SSH 命令" >&2
  echo "  - safe_scp: 安全地执行 SCP 命令" >&2
  echo "  - safe_tar_transfer: 使用 tar + ssh 管道安全地传输目录" >&2
  echo "  - set_github_output: 设置 GitHub Actions 输出变量" >&2
  echo "  - get_github_output: 获取 GitHub Actions 输出变量" >&2
  echo "  - get_timestamp: 获取当前时间戳" >&2
  exit 1
fi 