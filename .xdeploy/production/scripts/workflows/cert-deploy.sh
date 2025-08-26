#!/bin/bash
# 证书部署脚本
# 将证书部署到服务器，备份现有证书，上传新证书，设置适当的权限

# 引入辅助函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

# 参数解析
SERVER="$1"
CERT_DIR="$2"
TMP_CERT_DIR="$3"
DEPLOY_SCRIPTS_DIR="$4"
SSH_KEY="$5"
BASE_DOMAIN="$6"  # 基础域名

# 参数验证
if [ -z "$SERVER" ] || [ -z "$CERT_DIR" ] || [ -z "$TMP_CERT_DIR" ] || [ -z "$DEPLOY_SCRIPTS_DIR" ] || [ -z "$BASE_DOMAIN" ]; then
  log_github_error "缺少必要参数"
  echo "用法: $0 <server> <cert_dir> <tmp_cert_dir> <deploy_scripts_dir> [ssh_key] <base_domain>" >&2
  exit 1
fi

# 主要功能实现
log_github_group_start "证书部署"

log_cert_deploy "开始部署证书到服务器: $SERVER"
log_info "证书目录: $CERT_DIR"
log_info "临时证书目录: $TMP_CERT_DIR"
log_info "部署脚本目录: $DEPLOY_SCRIPTS_DIR"
log_info "基础域名: $BASE_DOMAIN"

# 设置SSH连接
setup_ssh_connection "$SERVER" "$SSH_KEY"

# 再次检查证书是否存在
if [ ! -d "$TMP_CERT_DIR" ] || [ ! "$(ls -A $TMP_CERT_DIR)" ]; then
  log_github_error "证书目录为空，无法部署"
  log_github_group_end
  exit 1
fi

# 检查临时证书是否包含指定域名的证书
if [ ! -d "$TMP_CERT_DIR/$BASE_DOMAIN" ]; then
  log_github_error "临时证书目录中未找到 $BASE_DOMAIN 的证书"
  log_github_group_end
  exit 1
fi

# 创建证书目录
log_server_operation "创建证书目录..."
safe_ssh $SERVER "mkdir -p $CERT_DIR/$BASE_DOMAIN"

# 备份现有证书 - 只备份特定域名的证书
log_server_operation "备份现有证书..."
safe_ssh $SERVER "if [ -d $CERT_DIR/$BASE_DOMAIN ]; then 
  mkdir -p ${CERT_DIR}.bak/$BASE_DOMAIN && 
  cp -r $CERT_DIR/$BASE_DOMAIN/* ${CERT_DIR}.bak/$BASE_DOMAIN/ 2>/dev/null || true; 
fi"

# 上传证书文件
log_cert_deploy "上传证书文件..."

# 使用 tar 来传输文件，避免通配符问题
log_server_operation "传输证书文件..."
cd $TMP_CERT_DIR && tar -czf - $BASE_DOMAIN | ssh $SERVER "tar -xzf - -C $CERT_DIR"

# 检查上传是否成功
if [ $? -ne 0 ]; then
  log_github_warning "证书上传失败，尝试恢复备份"
  # 只恢复特定域名的证书
  safe_ssh $SERVER "if [ -d ${CERT_DIR}.bak/$BASE_DOMAIN ]; then 
    mkdir -p $CERT_DIR/$BASE_DOMAIN && 
    cp -r ${CERT_DIR}.bak/$BASE_DOMAIN/* $CERT_DIR/$BASE_DOMAIN/ 2>/dev/null || true; 
  fi"
  log_github_group_end
  exit 1
fi

# 确保适当的权限
log_server_operation "设置证书权限..."
# 只设置特定域名证书的权限
safe_ssh $SERVER "if [ -d $CERT_DIR/$BASE_DOMAIN ]; then chmod -R 600 $CERT_DIR/$BASE_DOMAIN/*; fi"

# 上传部署脚本
log_cert_deploy "上传部署脚本..."
safe_ssh $SERVER "mkdir -p /tmp/scripts"

# 列出所有需要上传的脚本
log_info "部署脚本列表："
find $DEPLOY_SCRIPTS_DIR -type f -name "*.sh" | sort

# 上传 scripts/deploy 目录下的所有脚本
for script in $(find $DEPLOY_SCRIPTS_DIR -type f -name "*.sh"); do
  script_name=$(basename "$script")
  log_server_operation "上传脚本: $script_name"
  
  # 尝试使用 scp 上传脚本
  safe_scp "$script" $SERVER:/tmp/scripts/ || {
    log_warning "scp 上传失败，尝试使用 cat 命令写入文件..."
    cat "$script" | ssh $SERVER "cat > /tmp/scripts/$script_name"
  }
done

# 确保脚本有执行权限
log_server_operation "设置脚本执行权限..."
safe_ssh $SERVER "chmod +x /tmp/scripts/*.sh"

# 执行证书更新后处理脚本
log_cert_deploy "执行证书更新后处理脚本..."
# 检查脚本是否存在
log_server_operation "检查脚本是否存在..."
safe_ssh $SERVER "ls -la /tmp/scripts/"
# 执行脚本
log_server_operation "执行 post-cert-renewal.sh 脚本..."
safe_ssh $SERVER "CERT_DIR=$CERT_DIR BASE_DOMAIN=$BASE_DOMAIN /tmp/scripts/post-cert-renewal.sh"

# 检查执行结果
SCRIPT_EXIT_CODE=$?
log_info "脚本执行结果: $SCRIPT_EXIT_CODE"
if [ $SCRIPT_EXIT_CODE -ne 0 ]; then
  log_github_warning "证书更新后处理脚本执行失败，退出码: $SCRIPT_EXIT_CODE"
fi

# 清理临时脚本
log_server_operation "清理临时脚本..."
safe_ssh $SERVER "rm -rf /tmp/scripts"

# 清理备份（如果部署成功）
log_server_operation "清理备份..."
# 只清理特定域名的备份
safe_ssh $SERVER "rm -rf ${CERT_DIR}.bak/$BASE_DOMAIN"

log_success "服务器 $SERVER 证书部署完成"
log_github_group_end

# 输出摘要
print_separator
log_info "证书部署完成"
print_summary_item "服务器" "$SERVER"
print_summary_item "证书目录" "$CERT_DIR"
print_summary_item "基础域名" "$BASE_DOMAIN"
print_summary_item "部署结果" "成功"
print_separator

exit 0 