#!/bin/bash
set -e

# 参数: $1 - 服务器列表，$2 - 公钥内容
SERVERS="$1"
PUBLIC_KEY="$2"

# 导入工具函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 创建 SSH 目录
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 分割服务器列表
IFS=',' read -ra SERVER_ARRAY <<< "$SERVERS"

# 部署到每个服务器
for server in "${SERVER_ARRAY[@]}"; do
  print_title "开始部署到服务器: $server"

  # 使用 grep 查找密码
  password=$(grep -E "^$server=" server_passwords.txt | cut -d= -f2)

  if [ -z "$password" ]; then
    log_error "未找到服务器 $server 的密码"
    log_error "请确保在 XDS_SERVERS_PWD Secret 中包含此服务器的密码"
    exit 1
  fi

  # 提取主机名
  if [[ "$server" == *"@"* ]]; then
    host=$(echo $server | cut -d@ -f2)
  else
    host="$server"
  fi

  # 添加服务器到已知主机
  add_known_host "$host"

  log_info "正在连接到 $server 并部署公钥..."

  # 使用 sshpass 部署公钥
  if sshpass -p "$password" ssh -o StrictHostKeyChecking=no $server "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"; then
    log_success "公钥已成功添加到 $server 的 authorized_keys 文件"
  else
    log_error "向 $server 添加公钥失败"
    exit 1
  fi

  # 验证部署
  log_info "正在验证公钥部署..."
  if sshpass -p "$password" ssh -o StrictHostKeyChecking=no $server "grep -q '$(echo $PUBLIC_KEY | cut -d' ' -f1,2)' ~/.ssh/authorized_keys"; then
    log_success "验证成功: 公钥已正确部署到 $server"
  else
    log_error "验证失败: 公钥未正确部署到 $server"
    exit 1
  fi
done

# 清理临时文件
rm server_passwords.txt

log_success "🎉 所有服务器的公钥部署已完成!" 