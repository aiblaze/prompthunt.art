#!/bin/bash
# Nginx 重载/重启脚本
# 用法: ./nginx-reload.sh [--restart] [--no-check]
#   --restart: 完全重启 Nginx 而不是平滑重载
#   --no-check: 跳过配置语法检查

set -e

# 默认参数
CHECK_CONFIG=true
RESTART_MODE=false

# 解析参数
for arg in "$@"; do
  case $arg in
    --restart)
      RESTART_MODE=true
      shift
      ;;
    --no-check)
      CHECK_CONFIG=false
      shift
      ;;
    *)
      # 未知参数
      echo "未知参数: $arg"
      echo "用法: $0 [--restart] [--no-check]"
      exit 1
      ;;
  esac
done

# 确定操作模式
if [ "$RESTART_MODE" = true ]; then
  OPERATION="restart"
else
  OPERATION="reload"
fi

echo "Nginx 操作模式: ${OPERATION}"

# 检查 Nginx 是否安装
if ! command -v nginx >/dev/null 2>&1; then
  echo "Nginx 未安装或不在 PATH 中"
  exit 0
fi

# 检查 Nginx 配置语法
if [ "$CHECK_CONFIG" = true ]; then
  echo "检查 Nginx 配置语法..."
  if ! sudo nginx -t; then
    echo "配置检查失败！操作中止"
    exit 1
  fi
  echo "配置语法检查通过"
fi

# 检查 Nginx 服务是否正在运行
if ! systemctl is-active --quiet nginx; then
  echo "Nginx 服务未运行，尝试启动..."
  sudo systemctl start nginx
  if [ $? -ne 0 ]; then
    echo "Nginx 启动失败"
    exit 1
  fi
  echo "Nginx 启动成功"
  exit 0
fi

# 执行重载/重启操作
echo "${OPERATION}ing Nginx 服务..."
if sudo systemctl $OPERATION nginx; then
  echo "Nginx ${OPERATION} 成功"
else
  echo "Nginx ${OPERATION} 失败"
  exit 1
fi

# 检查 Nginx 状态
echo "检查 Nginx 状态..."
sudo systemctl status nginx | grep Active

echo "Nginx ${OPERATION} 操作完成"
exit 0
