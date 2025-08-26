#!/bin/bash
# 证书摘要脚本
# 生成证书操作的摘要信息

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
OPERATION_TYPE="$1"
DOMAIN_ARG="$2"
BASE_DOMAIN="$3"
SERVERS="$4"
APP_DIR="$5"
CERT_DIR="$6"

# 参数验证
if [ -z "$OPERATION_TYPE" ] || [ -z "$DOMAIN_ARG" ] || [ -z "$BASE_DOMAIN" ] || [ -z "$SERVERS" ] || [ -z "$APP_DIR" ] || [ -z "$CERT_DIR" ]; then
  log_github_error "缺少必要参数"
  echo "用法: $0 <operation_type> <domain_arg> <base_domain> <servers> <app_dir> <cert_dir>" >&2
  exit 1
fi

# 主要功能实现
log_github_group_start "证书操作摘要"

log_info "✅ SSL 证书操作完成！"
log_info "📋 操作详情："

case "$OPERATION_TYPE" in
  "force_renewal")
    log_info "   - 操作类型：强制重新生成证书"
    ;;
  "missing")
    log_info "   - 操作类型：生成新证书（证书不存在）"
    ;;
  "expiring")
    log_info "   - 操作类型：续期证书（证书即将过期）"
    ;;
  "valid")
    # 获取服务器列表
    IFS=',' read -ra SERVER_ARRAY <<< "$SERVERS"
    if [ ${#SERVER_ARRAY[@]} -gt 1 ]; then
      log_info "   - 操作类型：跳过生成操作（证书仍然有效），同步证书到其他服务器"
    else
      log_info "   - 操作类型：跳过操作（证书仍然有效）"
    fi
    ;;
  *)
    log_info "   - 操作类型：$OPERATION_TYPE"
    ;;
esac

log_info "   - 域名参数：$DOMAIN_ARG"
log_info "   - 基础域名：$BASE_DOMAIN"
log_info "   - 部署服务器：$SERVERS"
log_info "   - 应用目录：$APP_DIR"
log_info "   - 证书目录：$CERT_DIR"
log_info "   - 操作时间：$(date)"

log_github_group_end

# 输出摘要
print_separator
log_success "证书操作摘要"
print_summary_item "操作类型" "$OPERATION_TYPE"
print_summary_item "域名参数" "$DOMAIN_ARG"
print_summary_item "基础域名" "$BASE_DOMAIN"
print_summary_item "部署服务器" "$SERVERS"
print_summary_item "应用目录" "$APP_DIR"
print_summary_item "证书目录" "$CERT_DIR"
print_summary_item "操作时间" "$(date)"
print_separator

exit 0 