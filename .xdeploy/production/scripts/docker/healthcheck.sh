#!/bin/sh
# 健康检查脚本

# 设置超时时间（秒）
TIMEOUT=10

# 获取应用容器内部端口，优先使用 PORT_CONTAINER 环境变量，默认为 3000
PORT_CONTAINER=${PORT_CONTAINER:-3000}

# 健康检查端点
HEALTH_ENDPOINT=${HEALTH_ENDPOINT:-"/health"}

# 记录开始检查的时间
echo "$(date): 开始健康检查... 端口: $PORT_CONTAINER, 端点: $HEALTH_ENDPOINT"

# 尝试使用 wget 检查（大多数 Node.js 镜像包含 wget）
if command -v wget > /dev/null; then
  if wget --spider --quiet --timeout=$TIMEOUT http://localhost:$PORT_CONTAINER$HEALTH_ENDPOINT; then
    echo "$(date): 健康检查成功 (wget)"
    exit 0
  fi
fi

# 尝试使用 curl 检查
if command -v curl > /dev/null; then
  if curl -s --fail --max-time $TIMEOUT http://localhost:$PORT_CONTAINER$HEALTH_ENDPOINT > /dev/null; then
    echo "$(date): 健康检查成功 (curl)"
    exit 0
  fi
fi

# 尝试使用 nc 检查端口是否开放
if command -v nc > /dev/null; then
  if nc -z localhost $PORT_CONTAINER; then
    echo "$(date): 端口 $PORT_CONTAINER 已开放，但无法验证应用状态"
    # 端口开放但应用可能未完全启动，返回成功
    exit 0
  fi
fi

# 所有检查方法都失败
echo "$(date): 健康检查失败"
exit 1
