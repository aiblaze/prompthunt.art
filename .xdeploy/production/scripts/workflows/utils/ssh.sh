#!/bin/bash
# SSH 辅助函数
# 提供 SSH 密钥管理和操作的通用函数

# 引入日志函数（如果尚未引入）
UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")"
if ! command -v log_info &> /dev/null; then
  source "$UTILS_DIR/logging.sh"
fi

# 安装 SSH 密钥（如果提供且不存在）
# 参数:
#   $1: SSH 密钥内容
#   $2: (可选) SSH 密钥文件路径，默认为 ~/.ssh/id_rsa
install_ssh_key() {
  local SSH_KEY="$1"
  local KEY_PATH="${2:-$HOME/.ssh/id_rsa}"
  local KEY_DIR="$(dirname "$KEY_PATH")"
  
  if [ -z "$SSH_KEY" ]; then
    log_info "未提供 SSH 密钥，跳过安装"
    return 0
  fi
  
  if [ ! -f "$KEY_PATH" ] || [ ! -s "$KEY_PATH" ]; then
    log_info "安装 SSH 密钥到 $KEY_PATH..."
    # 创建目录并设置权限
    mkdir -p "$KEY_DIR" 2>/dev/null || {
      log_github_error "无法创建目录 $KEY_DIR"
      return 1
    }
    
    # 写入密钥文件
    echo "$SSH_KEY" > "$KEY_PATH" 2>/dev/null || {
      log_github_error "无法写入 SSH 密钥到 $KEY_PATH"
      return 1
    }
    
    # 设置权限
    chmod 600 "$KEY_PATH" 2>/dev/null || {
      log_github_warning "无法设置 SSH 密钥权限，这可能导致连接问题"
    }
    
    log_success "SSH 密钥安装完成"
  else
    log_info "SSH 密钥已存在于 $KEY_PATH，跳过安装"
  fi
  
  return 0
}

# 添加服务器到已知主机
# 参数:
#   $1: 服务器地址（格式：user@host 或 host）
add_known_host() {
  local SERVER="$1"
  local HOST
  
  # 提取主机名
  if [[ "$SERVER" == *"@"* ]]; then
    HOST=$(echo "$SERVER" | cut -d@ -f2)
  else
    HOST="$SERVER"
  fi
  
  log_info "添加服务器 $HOST 到已知主机..."
  mkdir -p ~/.ssh
  # 重定向ssh-keyscan的输出到/dev/null，只保留错误信息
  ssh-keyscan -H "$HOST" >> ~/.ssh/known_hosts 2>/dev/null || {
    log_warning "无法获取服务器 $HOST 的密钥指纹"
    return 1
  }
  
  return 0
}

# 设置 SSH 连接（安装密钥并添加到已知主机）
# 参数:
#   $1: 服务器地址（格式：user@host）
#   $2: SSH 密钥内容
setup_ssh_connection() {
  local SERVER="$1"
  local SSH_KEY="$2"
  local RESULT=0
  
  # 安装 SSH 密钥
  install_ssh_key "$SSH_KEY" || {
    log_github_error "SSH 密钥安装失败"
    RESULT=1
  }
  
  # 添加服务器到已知主机
  add_known_host "$SERVER" || {
    log_github_warning "添加服务器到已知主机失败，但将继续尝试连接"
  }
  
  return $RESULT
}

# 如果脚本被直接执行而不是被导入，则显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  log_info "此脚本包含 SSH 辅助函数，不应直接执行"
  log_info "请在其他脚本中使用 source 命令导入此脚本"
  
  echo "" >&2
  log_info "可用函数列表:"
  echo "  - install_ssh_key: 安装 SSH 密钥（如果提供且不存在）" >&2
  echo "  - add_known_host: 添加服务器到已知主机" >&2
  echo "  - setup_ssh_connection: 设置 SSH 连接（安装密钥并添加到已知主机）" >&2
  
  exit 0
fi 