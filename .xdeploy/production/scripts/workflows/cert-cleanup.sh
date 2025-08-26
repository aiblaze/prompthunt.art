#!/bin/bash
# 清理脚本
# 清理敏感文件和临时文件

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
ENV_FILE="$1"
LOG_DIR="$2"
TMP_CERT_DIR="${3:-/tmp/certs/live}"

# 主要功能实现
log_github_group_start "清理敏感文件"

# 清理环境变量文件
if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
  log_info "清理环境变量文件: $ENV_FILE"
  rm -f "$ENV_FILE"
fi

# 清理日志目录
if [ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ]; then
  log_info "清理日志目录: $LOG_DIR"
  rm -rf "$LOG_DIR"
fi

# 清理临时证书目录
if [ -n "$TMP_CERT_DIR" ] && [ -d "$TMP_CERT_DIR" ]; then
  log_info "清理临时证书目录: $TMP_CERT_DIR"
  rm -rf "$TMP_CERT_DIR"
fi

# 清理临时目录
log_info "清理其他临时目录..."
rm -rf /tmp/cert_sync /tmp/cert_verify 2>/dev/null || true

log_success "清理完成"
log_github_group_end

exit 0