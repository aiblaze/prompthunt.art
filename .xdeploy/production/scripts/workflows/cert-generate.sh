#!/bin/bash
# 证书生成脚本
# 使用 X Certbot 生成 SSL 证书

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
DOMAIN_ARG="$1"
EMAIL="$2"
DNS_WAIT_TIME="${3:-60}"
FORCE_RENEWAL="${4:-false}"
TMP_CERT_DIR="$5"
ENV_TEMPLATE="$6"
ALIYUN_REGION="$7"
ALIYUN_ACCESS_KEY_ID="$8"
ALIYUN_ACCESS_KEY_SECRET="${9}"
OPERATION="${10:-generate}" # generate 或 renew

# 参数验证
if ! check_var_not_empty "TMP_CERT_DIR" "$TMP_CERT_DIR" ||
   ! check_var_not_empty "ENV_TEMPLATE" "$ENV_TEMPLATE" ||
   ! check_var_not_empty "DOMAIN_ARG" "$DOMAIN_ARG" ||
   ! check_var_not_empty "EMAIL" "$EMAIL" ||
   ! check_var_not_empty "ALIYUN_REGION" "$ALIYUN_REGION" ||
   ! check_var_not_empty "ALIYUN_ACCESS_KEY_ID" "$ALIYUN_ACCESS_KEY_ID" ||
   ! check_var_not_empty "ALIYUN_ACCESS_KEY_SECRET" "$ALIYUN_ACCESS_KEY_SECRET"; then
  log_github_error "缺少必要参数"
  log_info "用法: $0 <domain_arg> <email> [dns_wait_time] [force_renewal] <tmp_cert_dir> <env_template> [aliyun_region] [aliyun_access_key_id] [aliyun_access_key_secret] [operation]"
  exit 1
fi

# 主要功能实现
log_github_group_start "证书${OPERATION}操作"

log_cert_generate "执行证书${OPERATION}操作..."
log_info "域名参数: $DOMAIN_ARG"
log_info "邮箱地址: $EMAIL"
log_info "DNS 等待时间: $DNS_WAIT_TIME 秒"
log_info "强制续期: $FORCE_RENEWAL"
log_info "临时证书目录: $TMP_CERT_DIR"

# 确保临时证书目录存在
mkdir -p "$TMP_CERT_DIR"

# 生成 .env 文件
log_config "生成 .env 文件..."
ENV_FILE="${GITHUB_WORKSPACE:-$(pwd)}/xcertbot.env"

# 处理环境变量模板，替换私密变量
cat "$ENV_TEMPLATE" | \
sed "s|<XDS_CERTBOT_ALIYUN_REGION>|$ALIYUN_REGION|g" | \
sed "s|<XDS_CERTBOT_ALIYUN_ACCESS_KEY_ID>|$ALIYUN_ACCESS_KEY_ID|g" | \
sed "s|<XDS_CERTBOT_ALIYUN_ACCESS_KEY_SECRET>|$ALIYUN_ACCESS_KEY_SECRET|g" > "$ENV_FILE"

log_info "生成的 .env 文件内容（敏感信息已隐藏）："
cat "$ENV_FILE" | grep -v SECRET | grep -v KEY_ID

# 运行 Docker 容器生成证书
log_cert_generate "运行 Docker 容器${OPERATION}证书..."

# 统一日志目录配置
LOG_DIR="${GITHUB_WORKSPACE:-$(pwd)}/certbot_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/certbot_$(date +%Y%m%d%H%M%S).log"

# 安全构建 Docker 命令数组
DOCKER_CMD=(
  docker run --rm
  --env-file "${ENV_FILE}"
  -v "${TMP_CERT_DIR}:/etc/letsencrypt/certs/live"
  aiblaze/x.certbot:latest
)

# 根据操作类型追加参数
if [ "$OPERATION" = "renew" ]; then
  DOCKER_CMD+=(renew)
fi

# 执行命令并使用 tee 同时输出到控制台和文件
log_info "执行命令并记录日志到: $LOG_FILE"
log_info "Docker 命令: ${DOCKER_CMD[@]}"
log_info "确认当前目录: $(pwd)"
log_info "确认环境文件存在: $(ls -la ${ENV_FILE})"
log_info "确认临时证书目录: $(ls -la ${TMP_CERT_DIR})"

# 使用 tee 实现同时输出到控制台和文件
"${DOCKER_CMD[@]}" 2>&1 | tee "$LOG_FILE"

CERT_STATUS=${PIPESTATUS[0]}  # 获取 Docker 命令的退出状态
log_info "X Certbot 退出码: $CERT_STATUS"

# 检查证书是否实际生成
if [ -d "$TMP_CERT_DIR" ] && [ "$(ls -A $TMP_CERT_DIR)" ]; then
  log_success "证书${OPERATION}成功，证书目录不为空"
  set_github_output "cert_updated" "true"
  
  # 列出生成的证书
  log_info "生成的证书目录结构："
  find "$TMP_CERT_DIR" -type f -name "*.pem" | sort
else
  log_github_error "证书${OPERATION}失败，证书目录为空"
  set_github_output "cert_updated" "false"
  log_github_group_end
  exit 1
fi

log_github_group_end

# 输出摘要
print_separator
log_info "证书${OPERATION}操作完成"
print_summary_item "操作结果" "成功"
print_summary_item "证书目录" "$TMP_CERT_DIR"
print_summary_item "日志文件" "$LOG_FILE"
print_separator

exit 0 