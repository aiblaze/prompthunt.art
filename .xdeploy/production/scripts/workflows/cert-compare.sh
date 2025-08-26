#!/bin/bash
# 证书比较脚本
# 比较主节点和目标服务器的证书是否一致，通过 metadata.json 文件进行比较

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
PRIMARY_SERVER="$1"
TARGET_SERVER="$2"
CERT_DIR="$3"
BASE_DOMAIN="$4"
SSH_KEY="$5"

# 参数验证
if [ -z "$PRIMARY_SERVER" ] || [ -z "$TARGET_SERVER" ] || [ -z "$CERT_DIR" ] || [ -z "$BASE_DOMAIN" ]; then
  log_github_error "缺少必要参数"
  echo "用法: $0 <primary_server> <target_server> <cert_dir> <base_domain> [ssh_key]" >&2
  exit 1
fi

# 主要功能实现
log_github_group_start "证书比较"

log_cert_check "开始比较主节点 $PRIMARY_SERVER 和目标服务器 $TARGET_SERVER 的证书"
log_info "证书目录: $CERT_DIR"
log_info "基础域名: $BASE_DOMAIN"

# 设置SSH连接
setup_ssh_connection "$PRIMARY_SERVER" "$SSH_KEY"
setup_ssh_connection "$TARGET_SERVER" "$SSH_KEY"

# 检查主节点证书是否存在
log_cert_check "检查主节点证书和 metadata.json 是否存在..."
PRIMARY_CERT_EXISTS=$(safe_ssh $PRIMARY_SERVER "if [ -d $CERT_DIR/$BASE_DOMAIN ]; then echo 'true'; else echo 'false'; fi")
PRIMARY_METADATA_EXISTS=$(safe_ssh $PRIMARY_SERVER "if [ -f $CERT_DIR/$BASE_DOMAIN/metadata.json ]; then echo 'true'; else echo 'false'; fi")

if [ "$PRIMARY_CERT_EXISTS" != "true" ]; then
  log_github_error "主节点 $PRIMARY_SERVER 没有证书目录"
  set_github_output "cert_comparison_result" "primary_missing"
  log_github_group_end
  exit 1
fi

if [ "$PRIMARY_METADATA_EXISTS" != "true" ]; then
  log_github_warning "主节点 $PRIMARY_SERVER 没有 metadata.json 文件，无法进行精确比较"
  set_github_output "cert_comparison_result" "metadata_missing"
  log_github_group_end
  exit 0
fi

# 检查目标服务器证书是否存在
log_cert_check "检查目标服务器证书和 metadata.json 是否存在..."
TARGET_CERT_EXISTS=$(safe_ssh $TARGET_SERVER "if [ -d $CERT_DIR/$BASE_DOMAIN ]; then echo 'true'; else echo 'false'; fi")
TARGET_METADATA_EXISTS=$(safe_ssh $TARGET_SERVER "if [ -f $CERT_DIR/$BASE_DOMAIN/metadata.json ]; then echo 'true'; else echo 'false'; fi")

if [ "$TARGET_CERT_EXISTS" != "true" ]; then
  log_info "目标服务器 $TARGET_SERVER 没有证书目录，需要同步"
  set_github_output "cert_comparison_result" "target_missing"
  log_github_group_end
  exit 0
fi

if [ "$TARGET_METADATA_EXISTS" != "true" ]; then
  log_github_warning "目标服务器 $TARGET_SERVER 没有 metadata.json 文件，无法进行精确比较"
  set_github_output "cert_comparison_result" "metadata_missing"
  log_github_group_end
  exit 0
fi

# 获取主节点的 metadata.json 内容
log_cert_check "获取主节点证书元数据..."
PRIMARY_METADATA=$(safe_ssh $PRIMARY_SERVER "cat $CERT_DIR/$BASE_DOMAIN/metadata.json 2>/dev/null")
PRIMARY_SSH_EXIT_CODE=$?

if [ $PRIMARY_SSH_EXIT_CODE -ne 0 ] || [ -z "$PRIMARY_METADATA" ]; then
  log_github_error "无法获取主节点的 metadata.json 文件内容"
  set_github_output "cert_comparison_result" "read_error"
  log_github_group_end
  exit 1
fi

# 获取目标服务器的 metadata.json 内容
log_cert_check "获取目标服务器证书元数据..."
TARGET_METADATA=$(safe_ssh $TARGET_SERVER "cat $CERT_DIR/$BASE_DOMAIN/metadata.json 2>/dev/null")
TARGET_SSH_EXIT_CODE=$?

if [ $TARGET_SSH_EXIT_CODE -ne 0 ] || [ -z "$TARGET_METADATA" ]; then
  log_github_error "无法获取目标服务器的 metadata.json 文件内容"
  set_github_output "cert_comparison_result" "read_error"
  log_github_group_end
  exit 1
fi

# 使用 grep/sed 提取指纹
log_cert_check "提取证书指纹..."
PRIMARY_FINGERPRINT=$(echo "$PRIMARY_METADATA" | grep -o '"fingerprint"[ 	]*:[ 	]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
TARGET_FINGERPRINT=$(echo "$TARGET_METADATA" | grep -o '"fingerprint"[ 	]*:[ 	]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')

# 添加调试信息
log_cert_check "指纹提取结果："
log_info "主节点指纹长度: ${#PRIMARY_FINGERPRINT} 字符"
log_info "目标服务器指纹长度: ${#TARGET_FINGERPRINT} 字符"
if [ ${#PRIMARY_FINGERPRINT} -lt 100 ]; then
  log_info "主节点指纹: '$PRIMARY_FINGERPRINT'"
fi
if [ ${#TARGET_FINGERPRINT} -lt 100 ]; then
  log_info "目标服务器指纹: '$TARGET_FINGERPRINT'"
fi

# 指纹提取失败，则进行证书文件内容比较
if [ -z "$PRIMARY_FINGERPRINT" ] || [ -z "$TARGET_FINGERPRINT" ]; then
  log_github_warning "无法从 metadata.json 中提取证书指纹，将进行证书文件内容比较"
  
  # 备选方案：直接比较证书文件的哈希值
  log_cert_check "使用证书文件哈希值进行比较..."
  
  PRIMARY_CERT_HASH=$(safe_ssh $PRIMARY_SERVER "if [ -f $CERT_DIR/$BASE_DOMAIN/cert.pem ]; then sha256sum $CERT_DIR/$BASE_DOMAIN/cert.pem | cut -d' ' -f1; else echo 'missing'; fi")
  TARGET_CERT_HASH=$(safe_ssh $TARGET_SERVER "if [ -f $CERT_DIR/$BASE_DOMAIN/cert.pem ]; then sha256sum $CERT_DIR/$BASE_DOMAIN/cert.pem | cut -d' ' -f1; else echo 'missing'; fi")
  
  if [ "$PRIMARY_CERT_HASH" = "missing" ] || [ "$TARGET_CERT_HASH" = "missing" ]; then
    log_github_error "无法计算证书文件哈希值"
    set_github_output "cert_comparison_result" "hash_error"
    log_github_group_end
    exit 1
  fi
  
  if [ "$PRIMARY_CERT_HASH" = "$TARGET_CERT_HASH" ]; then
    log_success "证书哈希值一致，证书相同"
    set_github_output "cert_comparison_result" "identical"
    log_github_group_end
    exit 0
  else
    log_info "证书哈希值不同，需要同步"
    set_github_output "cert_comparison_result" "different"
    log_github_group_end
    exit 0
  fi
fi

# 指纹提取成功，则进行证书指纹比较
if [ "$PRIMARY_FINGERPRINT" = "$TARGET_FINGERPRINT" ]; then
  log_success "证书指纹一致，证书相同"
  
  # 额外检查证书的有效期，确保两边的证书信息完全一致
  PRIMARY_RENEWED_AT=$(echo "$PRIMARY_METADATA" | grep -o '"renewed_at"[ 	]*:[ 	]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
  TARGET_RENEWED_AT=$(echo "$TARGET_METADATA" | grep -o '"renewed_at"[ 	]*:[ 	]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
  
  if [ -n "$PRIMARY_RENEWED_AT" ] && [ -n "$TARGET_RENEWED_AT" ]; then
    if [ "$PRIMARY_RENEWED_AT" = "$TARGET_RENEWED_AT" ]; then
      log_success "证书续期时间也一致"
    else
      log_info "证书续期时间不同："
      log_info "  主节点: $PRIMARY_RENEWED_AT"
      log_info "  目标服务器: $TARGET_RENEWED_AT"
    fi
  fi
  
  set_github_output "cert_comparison_result" "identical"
else
  log_info "证书指纹不同，需要同步"
  log_info "证书差异详情："
  log_info "  主节点: $PRIMARY_FINGERPRINT"
  log_info "  目标服务器: $TARGET_FINGERPRINT"
  set_github_output "cert_comparison_result" "different"
fi

log_github_group_end

# 输出摘要
print_separator
log_info "证书比较完成"
print_summary_item "主节点" "$PRIMARY_SERVER"
print_summary_item "目标服务器" "$TARGET_SERVER"
print_summary_item "证书目录" "$CERT_DIR"
print_summary_item "基础域名" "$BASE_DOMAIN"
print_summary_item "比较结果" "$([ "$PRIMARY_FINGERPRINT" = "$TARGET_FINGERPRINT" ] && echo "证书一致" || echo "证书不同")"
print_separator

exit 0 