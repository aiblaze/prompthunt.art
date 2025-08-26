#!/bin/bash
set -e

# 导入工具函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数: $1 - 服务器信息 (格式为 username@host=password,username@host=password)
SERVERS="$1"

# 验证输入
if check_var_not_empty "SERVERS" "$SERVERS"; then
  log_info "开始处理服务器列表..."
else
  log_error "未提供服务器列表"
  exit 1
fi

# 创建一个临时文件存放密码
> server_passwords.txt

# 处理每个服务器信息，提取用户名、主机和密码
IFS=',' read -ra SERVER_ARRAY <<< "$SERVERS"
CLEAN_SERVERS=""

for server_info in "${SERVER_ARRAY[@]}"; do
  # 从 username@host=password 格式解析信息
  server_address=$(echo $server_info | cut -d'=' -f1)
  password=$(echo $server_info | cut -d'=' -f2-)
  
  # 验证密码是否有效
  if [ -z "$password" ]; then
    log_error "服务器 $server_address 的密码格式无效"
    exit 1
  fi

  # 添加到清理后的服务器列表
  if [ -n "$CLEAN_SERVERS" ]; then
    CLEAN_SERVERS="${CLEAN_SERVERS},${server_address}"
  else
    CLEAN_SERVERS="${server_address}"
  fi

  # 将密码写入密码文件
  echo "${server_address}=${password}" >> server_passwords.txt
  log_info "处理服务器: ${server_address}"
done

# 输出处理后的服务器列表
echo "$CLEAN_SERVERS"

# 显示处理后的服务器列表（不包含密码）
log_success "处理后的服务器列表: $CLEAN_SERVERS" 