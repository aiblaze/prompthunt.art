#!/bin/bash
set -e

# 导入工具函数
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/utils/index.sh"

log_info "生成新的 SSH 密钥对..."
# 生成新的 SSH 密钥对
ssh-keygen -t ed25519 -C "github-actions-deploy" -f github-actions-deploy -N ""

log_info "密钥生成完成，显示公钥指纹："
# 显示公钥指纹用于验证
ssh-keygen -lf github-actions-deploy.pub

log_success "SSH 密钥对已成功生成" 