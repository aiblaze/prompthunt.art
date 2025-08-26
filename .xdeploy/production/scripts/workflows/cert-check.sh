#!/bin/bash
# 证书检查脚本
# 检查服务器上是否存在证书，验证证书的有效期，确定是否需要生成新证书或续期

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
SERVER="$1"
BASE_DOMAIN="$2"
CERT_DIR="$3"
TMP_CERT_DIR="$4"
SSH_KEY="$5"

# 参数验证
if [ -z "$SERVER" ] || [ -z "$BASE_DOMAIN" ] || [ -z "$CERT_DIR" ] || [ -z "$TMP_CERT_DIR" ]; then
  log_github_error "缺少必要参数"
  echo "用法: $0 <server> <base_domain> <cert_dir> <tmp_cert_dir> [ssh_key]" >&2
  exit 1
fi

# 主要功能实现
log_github_group_start "证书检查"

log_cert_check "检查服务器 $SERVER 上的证书..."
log_info "基础域名: $BASE_DOMAIN"
log_info "证书目录: $CERT_DIR"
log_info "临时证书目录: $TMP_CERT_DIR"

# 设置SSH连接
setup_ssh_connection "$SERVER" "$SSH_KEY"

# 检查证书是否存在
CERT_EXISTS="false"
CERT_PATH=""

# 检查基础域名证书
log_cert_check "检查基础域名证书..."
if safe_ssh $SERVER "[ -f $CERT_DIR/$BASE_DOMAIN/cert.pem ]"; then
  CERT_EXISTS="true"
  CERT_PATH="$CERT_DIR/$BASE_DOMAIN/cert.pem"
  log_success "找到基础域名证书: $CERT_PATH"
# 尝试查找任何可能的证书目录
else
  log_info "没有找到基础域名证书..."
fi

log_info "证书存在: $CERT_EXISTS"

if [ "$CERT_EXISTS" == "true" ]; then
  # 创建临时目录
  CERT_FILENAME=$(basename "$CERT_PATH")
  CERT_DIRNAME=$(basename "$(dirname "$CERT_PATH")")
  mkdir -p $TMP_CERT_DIR/$CERT_DIRNAME

  # 下载证书以检查过期时间
  log_info "下载证书: $CERT_PATH"
  safe_scp $SERVER:$CERT_PATH $TMP_CERT_DIR/$CERT_DIRNAME/$CERT_FILENAME

  # 检查证书过期时间
  CERT_FILE="$TMP_CERT_DIR/$CERT_DIRNAME/$CERT_FILENAME"
  if [ ! -f "$CERT_FILE" ]; then
    log_github_error "无法下载证书文件"
    set_github_output "cert_status" "missing"
  else
    EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
    EXPIRY_SECONDS=$(date -d "$EXPIRY" +%s)
    NOW_SECONDS=$(date +%s)
    DIFF_DAYS=$(( ($EXPIRY_SECONDS - $NOW_SECONDS) / 86400 ))

    log_time "证书将在 $DIFF_DAYS 天后过期"

    if [ $DIFF_DAYS -gt 30 ]; then
      log_success "证书仍然有效，剩余 $DIFF_DAYS 天，无需续期"
      set_github_output "cert_status" "valid"
    else
      log_warning "证书将在 $DIFF_DAYS 天后过期，需要续期"
      set_github_output "cert_status" "expiring"
    fi
  fi
else
  log_warning "证书不存在，需要生成新证书"
  set_github_output "cert_status" "missing"
fi

log_github_group_end

# 输出摘要
print_separator
log_info "证书检查完成"
print_summary_item "证书状态" "${CERT_STATUS:-未知}"
if [ -n "$DIFF_DAYS" ]; then
  print_summary_item "过期天数" "$DIFF_DAYS"
fi
print_separator

exit 0 