#!/bin/bash
# 颜色和 Emoji 定义模块
# 包含控制台输出的颜色代码和 Emoji 符号定义

#######################
# 颜色定义
#######################

# 颜色定义
NC="\033[0m"       # No Color
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"

#######################
# Emoji 符号
#######################

# Emoji 符号
EMOJI_SUCCESS="✅"
EMOJI_ERROR="❌"
EMOJI_WARNING="⚠️"
EMOJI_INFO="ℹ️"
EMOJI_ROCKET="🚀"
EMOJI_LOCK="🔒"
EMOJI_GLOBE="🌐"
EMOJI_SERVER="🖥️"
EMOJI_CERT="📜"
EMOJI_SYNC="🔄"
EMOJI_TIME="⏱️"
EMOJI_DEPLOY="📦"
EMOJI_CONFIG="⚙️"

# 如果脚本被直接执行而不是被导入，则显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "此脚本包含颜色和 Emoji 定义，不应直接执行" >&2
  echo "请在其他脚本中使用 source 命令导入此脚本" >&2
  exit 1
fi 