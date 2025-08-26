#!/bin/bash
# 辅助函数主入口文件
# 导入所有辅助函数模块，提供统一的入口点

# 获取当前脚本所在目录
UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")"

# 导入所有模块
source "$UTILS_DIR/colors.sh"
source "$UTILS_DIR/logging.sh"
source "$UTILS_DIR/domain.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/ssh.sh"
source "$UTILS_DIR/deploy.sh"

# 如果脚本被直接执行而不是被导入，则显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  print_title "辅助函数脚本"
  log_info "此脚本包含辅助函数，不应直接执行"
  log_info "请在其他脚本中使用 source 命令导入此脚本"
  
  echo "" >&2
  log_info "示例:"
  echo "  source \"\$(dirname \"\$0\")/utils/index.sh\"" >&2
  echo "" >&2
  
  log_info "可用函数列表:"
  echo "  - 日志函数: log_info, log_success, log_warning, log_error" >&2
  echo "  - GitHub Actions 函数: log_github_error, log_github_warning, log_github_group_start, log_github_group_end" >&2
  echo "  - 证书操作函数: log_cert_check, log_cert_generate, log_cert_deploy, log_cert_sync" >&2
  echo "  - 其他日志函数: log_server_operation, log_time, log_config" >&2
  echo "  - 格式化函数: print_separator, print_title, print_step, print_summary_item" >&2
  echo "  - 域名处理函数: extract_domain, extract_base_domain" >&2
  echo "  - 通用辅助函数: command_exists, check_var_not_empty, safe_ssh, safe_scp, set_github_output, get_timestamp" >&2
  echo "  - SSH 辅助函数: install_ssh_key, add_known_host, setup_ssh_connection" >&2
  
  exit 0
fi 