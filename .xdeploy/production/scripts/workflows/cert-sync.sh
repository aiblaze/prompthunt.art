#!/bin/bash
# 证书同步脚本
# 从主节点下载证书，将证书同步到其他服务器，执行证书更新后处理

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
PRIMARY_SERVER="$1"
TARGET_SERVER="$2"
CERT_DIR="$3"
BASE_DOMAIN="$4"
DEPLOY_SCRIPTS_DIR="$5"
SSH_KEY="$6"
FORCE_SYNC="${7:-false}"

# 参数验证
if [ -z "$PRIMARY_SERVER" ] || [ -z "$TARGET_SERVER" ] || [ -z "$CERT_DIR" ] || [ -z "$BASE_DOMAIN" ] || [ -z "$DEPLOY_SCRIPTS_DIR" ] || [ -z "$SSH_KEY" ]; then
  log_github_error "缺少必要参数"
  echo "用法: $0 <primary_server> <target_server> <cert_dir> <base_domain> <deploy_scripts_dir> <ssh_key> [force_sync]" >&2
  echo "  force_sync: true|false (默认: false) - 是否强制同步，跳过证书比较" >&2
  exit 1
fi

# 主要功能实现
log_github_group_start "证书同步"

log_cert_sync "从主节点 $PRIMARY_SERVER 同步证书到 $TARGET_SERVER"
log_info "证书目录: $CERT_DIR"
log_info "基础域名: $BASE_DOMAIN"
log_info "部署脚本目录: $DEPLOY_SCRIPTS_DIR"
log_info "强制同步: $FORCE_SYNC"

# 设置SSH连接
setup_ssh_connection "$PRIMARY_SERVER" "$SSH_KEY"
setup_ssh_connection "$TARGET_SERVER" "$SSH_KEY"

# 检查主节点证书是否存在
log_cert_check "检查主节点证书是否存在..."
CERT_EXISTS=$(safe_ssh $PRIMARY_SERVER "if [ -d $CERT_DIR/$BASE_DOMAIN ]; then echo 'true'; else echo 'false'; fi")

if [ "$CERT_EXISTS" != "true" ]; then
  log_github_error "主节点 $PRIMARY_SERVER 没有有效证书，无法同步"
  log_github_group_end
  exit 1
fi

log_success "主节点 $PRIMARY_SERVER 存在有效证书"

# 检查是否强制同步
if [ "$FORCE_SYNC" = "true" ]; then
  log_info "启用强制同步模式，跳过证书比较"
  log_info "准备强制同步证书到 $TARGET_SERVER"
else
  # 比较主节点和目标服务器的证书是否一致
  log_cert_check "比较主节点和目标服务器的证书..."
  "${SCRIPT_DIR}/cert-compare.sh" "$PRIMARY_SERVER" "$TARGET_SERVER" "$CERT_DIR" "$BASE_DOMAIN" "$SSH_KEY"
  COMPARE_EXIT_CODE=$?
  CERT_COMPARISON_RESULT=$(get_github_output "cert_comparison_result")

  if [ $COMPARE_EXIT_CODE -eq 0 ] && [ "$CERT_COMPARISON_RESULT" = "identical" ]; then
    log_success "主节点和目标服务器的证书完全一致，跳过同步"
    
    # 设置输出变量
    set_github_output "cert_synced" "false"
    set_github_output "sync_skipped" "true"
    set_github_output "skip_reason" "certificates_identical"
    
    # 输出摘要
    print_separator
    log_info "证书同步跳过"
    print_summary_item "主节点" "$PRIMARY_SERVER"
    print_summary_item "目标服务器" "$TARGET_SERVER"
    print_summary_item "证书目录" "$CERT_DIR"
    print_summary_item "基础域名" "$BASE_DOMAIN"
    print_summary_item "跳过原因" "证书完全一致"
    print_separator
    
    log_github_group_end
    exit 0
  fi

  # 根据比较结果记录日志
  case "$CERT_COMPARISON_RESULT" in
    "different")
      log_info "证书不一致，开始同步"
      ;;
    "target_missing")
      log_info "目标服务器没有证书，开始同步"
      ;;
    "metadata_missing")
      log_warning "无法精确比较证书（metadata.json 缺失），继续同步以确保一致性"
      ;;
    "read_error"|"hash_error")
      log_warning "证书比较过程中出现错误，继续同步以确保一致性"
      ;;
    "primary_missing")
      log_github_error "主节点证书缺失，无法同步"
      log_github_group_end
      exit 1
      ;;
    *)
      log_warning "未知的证书比较结果：$CERT_COMPARISON_RESULT，继续同步"
      ;;
  esac

  log_info "准备同步证书到 $TARGET_SERVER"
fi

# 创建临时目录用于存储证书 - 使用更安全的路径
SYNC_TMP_DIR="${HOME:-/tmp}/cert_sync_$$"
log_info "创建临时目录: $SYNC_TMP_DIR"
mkdir -p "$SYNC_TMP_DIR/$BASE_DOMAIN"
chmod 755 "$SYNC_TMP_DIR"
chmod 755 "$SYNC_TMP_DIR/$BASE_DOMAIN"

# 临时调整主节点证书文件和目录权限以便读取
log_info "临时调整主节点证书文件权限..."
safe_ssh $PRIMARY_SERVER "chmod 755 $CERT_DIR/$BASE_DOMAIN && chmod 644 $CERT_DIR/$BASE_DOMAIN/*"

# 从主节点下载证书 - 只下载特定域名的证书
log_cert_sync "从主节点下载证书..."

if command_exists rsync; then
  log_info "使用 rsync 下载证书..."
  if ! rsync -avz -e ssh $PRIMARY_SERVER:$CERT_DIR/$BASE_DOMAIN/ $SYNC_TMP_DIR/$BASE_DOMAIN/; then
    log_warning "使用 rsync 下载失败，尝试使用 scp..."
    safe_ssh $PRIMARY_SERVER "cd $CERT_DIR && tar -czf /tmp/certs.tar.gz $BASE_DOMAIN"
    safe_scp $PRIMARY_SERVER:/tmp/certs.tar.gz $SYNC_TMP_DIR/
    cd $SYNC_TMP_DIR && tar -xzf certs.tar.gz
    rm -f $SYNC_TMP_DIR/certs.tar.gz
    safe_ssh $PRIMARY_SERVER "rm -f /tmp/certs.tar.gz"
  fi
else
  log_info "rsync 不可用，使用 tar+scp 下载证书..."
  safe_ssh $PRIMARY_SERVER "cd $CERT_DIR && tar -czf /tmp/certs.tar.gz $BASE_DOMAIN"
  safe_scp $PRIMARY_SERVER:/tmp/certs.tar.gz $SYNC_TMP_DIR/
  cd $SYNC_TMP_DIR && tar -xzf certs.tar.gz
  rm -f $SYNC_TMP_DIR/certs.tar.gz
  safe_ssh "$PRIMARY_SERVER" "rm -f /tmp/certs.tar.gz"
fi

# 恢复主节点证书文件和目录权限
log_info "恢复主节点证书文件权限..."
safe_ssh $PRIMARY_SERVER "chmod 700 $CERT_DIR/$BASE_DOMAIN && chmod 600 $CERT_DIR/$BASE_DOMAIN/*"

# 检查证书是否下载成功
if [ ! -d "$SYNC_TMP_DIR/$BASE_DOMAIN" ] || [ ! "$(ls -A $SYNC_TMP_DIR/$BASE_DOMAIN)" ]; then
  log_github_error "从主节点下载证书失败，证书目录为空"
  log_github_group_end
  exit 1
fi

log_success "从主节点下载证书成功"

# 创建目标服务器上的证书目录
log_server_operation "创建目标服务器上的证书目录..."
safe_ssh $TARGET_SERVER "mkdir -p $CERT_DIR/$BASE_DOMAIN"

# 备份目标服务器上的现有证书 - 只备份特定域名的证书
log_server_operation "备份目标服务器上的现有证书..."
safe_ssh $TARGET_SERVER "if [ -d $CERT_DIR/$BASE_DOMAIN ]; then 
  mkdir -p ${CERT_DIR}.bak/$BASE_DOMAIN && 
  cp -r $CERT_DIR/$BASE_DOMAIN/* ${CERT_DIR}.bak/$BASE_DOMAIN/ 2>/dev/null || true; 
fi"

# 上传证书到目标服务器 - 只上传特定域名的证书
log_cert_sync "上传证书到目标服务器..."
if command_exists rsync; then
  log_info "使用 rsync 上传证书..."
  if ! rsync -avz -e ssh $SYNC_TMP_DIR/$BASE_DOMAIN/ $TARGET_SERVER:$CERT_DIR/$BASE_DOMAIN/; then
    log_warning "使用 rsync 上传失败，尝试使用 tar+scp..."
    cd $SYNC_TMP_DIR && tar -czf /tmp/certs.tar.gz $BASE_DOMAIN
    safe_scp /tmp/certs.tar.gz $TARGET_SERVER:/tmp/
    safe_ssh $TARGET_SERVER "cd $CERT_DIR && tar -xzf /tmp/certs.tar.gz && rm -f /tmp/certs.tar.gz"
    rm -f /tmp/certs.tar.gz
  fi
else
  log_info "rsync 不可用，使用 tar+scp 上传证书..."
  cd $SYNC_TMP_DIR && tar -czf /tmp/certs.tar.gz $BASE_DOMAIN
  safe_scp /tmp/certs.tar.gz $TARGET_SERVER:/tmp/
  safe_ssh $TARGET_SERVER "cd $CERT_DIR && tar -xzf /tmp/certs.tar.gz && rm -f /tmp/certs.tar.gz"
  rm -f /tmp/certs.tar.gz
fi

# 检查上传是否成功
CERT_SYNCED=$(safe_ssh $TARGET_SERVER "if [ -d $CERT_DIR/$BASE_DOMAIN ]; then echo 'true'; else echo 'false'; fi")

if [ "$CERT_SYNCED" != "true" ]; then
  log_github_error "证书同步失败，目标服务器上没有证书"
  log_github_group_end
  exit 1
fi

log_success "证书同步成功"

# 设置证书权限 - 只设置特定域名证书的权限
log_server_operation "设置证书权限..."
safe_ssh $TARGET_SERVER "chmod -R 600 $CERT_DIR/$BASE_DOMAIN/*"

# 上传部署脚本
log_cert_sync "上传部署脚本..."
safe_ssh $TARGET_SERVER "mkdir -p /tmp/scripts"

# 上传 scripts/deploy 目录下的所有脚本
for script in $(find $DEPLOY_SCRIPTS_DIR -type f -name "*.sh"); do
  script_name=$(basename "$script")
  log_server_operation "上传脚本: $script_name"
  safe_scp "$script" $TARGET_SERVER:/tmp/scripts/
done

# 确保脚本有执行权限
log_server_operation "设置脚本执行权限..."
safe_ssh $TARGET_SERVER "chmod +x /tmp/scripts/*.sh"

# 执行证书更新后处理脚本
log_cert_sync "执行证书更新后处理脚本..."
safe_ssh $TARGET_SERVER "CERT_DIR=$CERT_DIR BASE_DOMAIN=$BASE_DOMAIN /tmp/scripts/post-cert-renewal.sh"

# 检查执行结果
SCRIPT_EXIT_CODE=$?
log_info "脚本执行结果: $SCRIPT_EXIT_CODE"
if [ $SCRIPT_EXIT_CODE -ne 0 ]; then
  log_github_warning "证书更新后处理脚本执行失败，退出码: $SCRIPT_EXIT_CODE"
fi

# 清理临时脚本
log_server_operation "清理临时脚本..."
safe_ssh $TARGET_SERVER "rm -rf /tmp/scripts"

# 清理临时目录
log_info "清理临时目录..."
rm -rf "$SYNC_TMP_DIR"

# 清理备份（如果同步成功）
log_server_operation "清理备份..."
safe_ssh $TARGET_SERVER "rm -rf ${CERT_DIR}.bak/$BASE_DOMAIN"

log_success "证书同步完成"
log_github_group_end

# 输出摘要
print_separator
log_info "证书同步完成"
print_summary_item "主节点" "$PRIMARY_SERVER"
print_summary_item "目标服务器" "$TARGET_SERVER"
print_summary_item "证书目录" "$CERT_DIR"
print_summary_item "基础域名" "$BASE_DOMAIN"
print_summary_item "强制同步" "$FORCE_SYNC"
print_summary_item "同步结果" "成功"
print_separator

# 设置输出变量
set_github_output "cert_synced" "true"
set_github_output "sync_skipped" "false"

exit 0 