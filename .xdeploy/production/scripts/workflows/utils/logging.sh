#!/bin/bash
# 日志和输出函数模块
# 包含各种日志输出和格式化函数

# 引入颜色定义
LOCAL_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${LOCAL_SCRIPT_DIR}/colors.sh"

#######################
# 基本日志函数
#######################

# 基本日志函数
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
  if [ "${DEBUG:-false}" = "true" ]; then
    echo -e "${BLUE}[DEBUG]${NC} $1" >&2
  fi
}

#######################
# GitHub Actions 特定输出
#######################

# GitHub Actions 特定输出
log_github_error() {
  echo "::error::$1"
  log_error "$1"
}

log_github_warning() {
  echo "::warning::$1"
  log_warning "$1"
}

log_github_group_start() {
  echo "::group::$1"
  print_title "$1"
}

log_github_group_end() {
  print_separator
  echo "::endgroup::"
}

#######################
# 证书操作相关输出
#######################

# 证书操作相关输出
log_cert_check() {
  echo -e "${EMOJI_CERT} ${CYAN}CERT CHECK:${NC} $1" >&2
}

log_cert_generate() {
  echo -e "${EMOJI_LOCK} ${PURPLE}CERT GENERATE:${NC} $1" >&2
}

log_cert_deploy() {
  echo -e "${EMOJI_DEPLOY} ${GREEN}CERT DEPLOY:${NC} $1" >&2
}

log_cert_sync() {
  echo -e "${EMOJI_SYNC} ${BLUE}CERT SYNC:${NC} $1" >&2
}

log_server_operation() {
  echo -e "${EMOJI_SERVER} ${YELLOW}SERVER:${NC} $1" >&2
}

log_time() {
  echo -e "${EMOJI_TIME} ${PURPLE}TIME:${NC} $1" >&2
}

log_config() {
  echo -e "${EMOJI_CONFIG} ${CYAN}CONFIG:${NC} $1" >&2
}

#######################
# 格式化输出函数
#######################

# 分隔线和标题
print_separator() {
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
}

print_title() {
  print_separator
  echo -e "${PURPLE}                      $1                      ${NC}" >&2
  print_separator
}

# 进度显示
print_step() {
  echo -e "${EMOJI_ROCKET} ${GREEN}STEP $1/${2}:${NC} $3" >&2
}

# 摘要输出
print_summary_item() {
  echo -e "   ${EMOJI_INFO} ${CYAN}$1:${NC} $2" >&2
}

# 如果脚本被直接执行而不是被导入，则显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "此脚本包含日志和输出函数，不应直接执行" >&2
  echo "请在其他脚本中使用 source 命令导入此脚本" >&2
  
  echo "" >&2
  echo "可用函数列表:" >&2
  echo "  - 基本日志函数: log_info, log_success, log_warning, log_error" >&2
  echo "  - GitHub Actions 函数: log_github_error, log_github_warning, log_github_group_start, log_github_group_end" >&2
  echo "  - 证书操作函数: log_cert_check, log_cert_generate, log_cert_deploy, log_cert_sync" >&2
  echo "  - 其他日志函数: log_server_operation, log_time, log_config" >&2
  echo "  - 格式化函数: print_separator, print_title, print_step, print_summary_item" >&2
  exit 1
fi

# 导出函数
export -f log_info
export -f log_warning
export -f log_error
export -f log_success
export -f log_debug
export -f log_github_error
export -f log_github_warning
export -f log_github_group_start
export -f log_github_group_end
export -f log_cert_check
export -f log_cert_generate
export -f log_cert_deploy
export -f log_cert_sync
export -f log_server_operation
export -f log_time
export -f log_config
export -f print_separator
export -f print_title
export -f print_step
export -f print_summary_item 