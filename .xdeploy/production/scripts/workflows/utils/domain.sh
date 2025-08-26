#!/bin/bash
# 域名处理函数模块
# 包含域名提取和验证的函数

# 导入日志函数
LOCAL_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${LOCAL_SCRIPT_DIR}/logging.sh"

#######################
# 域名处理函数
#######################

# 提取和验证域名
# 用法: extract_domain "域名参数"
# 返回: 成功时输出基础域名，失败时返回非零状态码
extract_domain() {
  local DOMAIN_ARG="$1"
  
  log_info "处理域名参数: $DOMAIN_ARG"
  
  # 提取所有域名（使用更兼容的方式，不依赖 grep -P）
  local ALL_DOMAINS=""
  local PARTS=$(echo "$DOMAIN_ARG" | tr ' ' '\n')
  local NEXT_IS_DOMAIN=false
  
  for part in $PARTS; do
    if [ "$NEXT_IS_DOMAIN" = true ]; then
      ALL_DOMAINS="$ALL_DOMAINS $part"
      NEXT_IS_DOMAIN=false
    elif [ "$part" = "-d" ]; then
      NEXT_IS_DOMAIN=true
    fi
  done
  
  # 去除前导空格
  ALL_DOMAINS=$(echo "$ALL_DOMAINS" | sed 's/^ *//')
  
  if [ -z "$ALL_DOMAINS" ]; then
    log_error "无法从域名参数中提取域名。请确保格式正确，例如: -d example.com -d *.example.com"
    return 1
  fi
  
  log_info "提取的所有域名: $ALL_DOMAINS"
  
  # 查找基础域名（不带通配符的域名）
  local BASE_DOMAIN=""
  for domain in $ALL_DOMAINS; do
    if [[ ! "$domain" == \** ]]; then
      BASE_DOMAIN="$domain"
      break
    fi
  done
  
  # 如果没有找到基础域名，尝试从通配符域名中提取
  if [ -z "$BASE_DOMAIN" ]; then
    for domain in $ALL_DOMAINS; do
      if [[ "$domain" == \** ]]; then
        BASE_DOMAIN="${domain#\*.}"
        break
      fi
    done
  fi
  
  # 如果仍然没有找到基础域名，使用第一个域名
  if [ -z "$BASE_DOMAIN" ]; then
    BASE_DOMAIN=$(echo "$ALL_DOMAINS" | awk '{print $1}')
  fi
  
  # 验证基础域名是否有效（使用更兼容的正则表达式语法）
  if ! echo "$BASE_DOMAIN" | grep -E '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$' > /dev/null; then
    log_error "提取的基础域名 '$BASE_DOMAIN' 格式无效"
    return 2
  fi
  
  log_success "基础域名: $BASE_DOMAIN"
  echo "$BASE_DOMAIN"
  return 0
}

# 提取域名函数（简化版，用于辅助函数）
extract_base_domain() {
  local domain_arg="$1"
  local base_domain=""
  
  # 提取第一个域名参数
  if [[ $domain_arg =~ -d[[:space:]]+([^[:space:]]+) ]]; then
    base_domain="${BASH_REMATCH[1]}"
    
    # 如果是通配符域名，去掉通配符
    if [[ $base_domain == \** ]]; then
      base_domain="${base_domain#\*.}"
    fi
    
    echo "$base_domain"
    return 0
  else
    echo "无法从参数中提取域名: $domain_arg"
    return 1
  fi
}

# 如果脚本被直接执行而不是被导入，则显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "此脚本包含域名处理函数，不应直接执行" >&2
  echo "请在其他脚本中使用 source 命令导入此脚本" >&2
  
  echo "" >&2
  echo "可用函数列表:" >&2
  echo "  - extract_domain: 提取和验证域名" >&2
  echo "  - extract_base_domain: 提取基础域名（简化版）" >&2
  exit 1
fi 