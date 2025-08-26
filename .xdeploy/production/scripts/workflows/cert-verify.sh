#!/bin/bash
# 证书验证脚本
# 验证证书是否成功部署到服务器

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
SERVER="$1"
CERT_DIR="$2"
BASE_DOMAIN="$3"
SSH_KEY="$4"

# 参数验证
if [ -z "$SERVER" ] || [ -z "$CERT_DIR" ] || [ -z "$BASE_DOMAIN" ]; then
  log_github_error "缺少必要参数"
  echo "用法: $0 <server> <cert_dir> <base_domain> [ssh_key]" >&2
  exit 1
fi

# 主要功能实现
log_github_group_start "证书验证"

log_cert_check "验证服务器 $SERVER 上的证书..."
log_info "证书目录: $CERT_DIR"
log_info "基础域名: $BASE_DOMAIN"

# 设置SSH连接
setup_ssh_connection "$SERVER" "$SSH_KEY"

# 检查证书文件是否存在
log_cert_check "检查证书文件是否存在..."
CERT_EXISTS=$(safe_ssh $SERVER "if [ -f $CERT_DIR/$BASE_DOMAIN/cert.pem ]; then echo 'true'; else echo 'false'; fi")

if [ "$CERT_EXISTS" == "true" ]; then
  log_success "证书文件验证成功"
  VERIFY_RESULT="success"
else
  log_github_warning "证书文件验证失败，可能部署不完整"
  VERIFY_RESULT="failure"
fi

# 检查证书过期时间
if [ "$CERT_EXISTS" == "true" ]; then
  log_cert_check "检查证书过期时间..."
  CERT_FILE="$CERT_DIR/$BASE_DOMAIN/cert.pem"
  
  # 创建临时目录
  TMP_DIR="/tmp/cert_verify"
  mkdir -p $TMP_DIR
  
  # 下载证书
  log_info "下载证书: $CERT_FILE"
  safe_scp $SERVER:$CERT_FILE $TMP_DIR/cert.pem
  
  if [ -f "$TMP_DIR/cert.pem" ]; then
    EXPIRY=$(safe_ssh $SERVER "openssl x509 -enddate -noout -in $CERT_FILE | cut -d= -f2")
    EXPIRY_DATE=$(date -d "$EXPIRY" "+%Y-%m-%d %H:%M:%S")
    NOW=$(date "+%Y-%m-%d %H:%M:%S")
    
    log_time "证书过期时间: $EXPIRY_DATE"
    log_time "当前时间: $NOW"
    
    # 计算剩余天数
    EXPIRY_SECONDS=$(date -d "$EXPIRY" +%s)
    NOW_SECONDS=$(date +%s)
    DIFF_DAYS=$(( ($EXPIRY_SECONDS - $NOW_SECONDS) / 86400 ))
    
    log_time "证书将在 $DIFF_DAYS 天后过期"
    
    # 清理临时目录
    rm -rf $TMP_DIR
  else
    log_warning "无法下载证书进行验证"
  fi
fi

log_github_group_end

# 输出摘要
print_separator
log_info "证书验证完成"
print_summary_item "服务器" "$SERVER"
print_summary_item "证书目录" "$CERT_DIR"
print_summary_item "基础域名" "$BASE_DOMAIN"
print_summary_item "验证结果" "$VERIFY_RESULT"
if [ -n "$DIFF_DAYS" ]; then
  print_summary_item "过期天数" "$DIFF_DAYS"
fi
print_separator

# 设置输出变量
set_github_output "cert_verified" "$VERIFY_RESULT"

if [ "$VERIFY_RESULT" == "success" ]; then
  exit 0
else
  exit 1
fi 