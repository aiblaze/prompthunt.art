#!/bin/bash
set -e

# 导入工具函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数: $1 - 服务器列表
SERVERS="$1"

# 验证输入
if ! check_var_not_empty "SERVERS" "$SERVERS"; then
  log_error "未提供服务器列表"
  exit 1
fi

# 设置正确的权限
mkdir -p ~/.ssh
cp github-actions-deploy ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

print_title "使用新密钥测试 SSH 连接"

# 分割服务器列表
IFS=',' read -ra SERVER_ARRAY <<< "$SERVERS"

# 测试连接到每个服务器
for server in "${SERVER_ARRAY[@]}"; do
  log_info "正在测试连接到 $server..."
  
  # 添加到已知主机
  add_known_host "$server"
  
  if safe_ssh "$server" "echo '连接成功!'"; then
    log_success "使用新密钥成功连接到 $server"
  else
    log_error "使用新密钥连接到 $server 失败"
    exit 1
  fi
done

log_success "所有服务器连接测试成功完成" 