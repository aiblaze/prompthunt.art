# Builder stage 1 - Build the application
FROM node:24-alpine AS builder

# Install pnpm and build dependencies
RUN corepack enable && corepack prepare pnpm@10.5.2 --activate

# Install build dependencies for native modules
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy the essential files
COPY .npmrc package.json pnpm-lock.yaml ./

# Install dependencies with rebuild for native modules
RUN pnpm install --frozen-lockfile --rebuild

# Copy the entire project
COPY . ./

# Set environment variables for build
ENV NUXT_TELEMETRY_DISABLED=1

# Build the application
RUN pnpm build

# Build stage 2 - the production image, copy all the files and run next
FROM node:24-alpine

WORKDIR /app

# 安装健康检查所需的工具
RUN apk add --no-cache curl wget busybox-extras

# Copy only the built application from the previous stage
COPY --from=builder /app/.output ./

# 将健康检查脚本复制到容器内并设置执行权限
COPY .xdeploy/production/scripts/docker/healthcheck.sh /app/scripts/healthcheck.sh
RUN chmod +x /app/scripts/healthcheck.sh

# Default port (can be overridden by APP_PORT_DOCKER)
ARG PORT=3013
ENV PORT=${PORT}

# 设置健康检查
HEALTHCHECK --interval=30s --timeout=15s --start-period=20s --retries=5 \
  CMD ["/app/scripts/healthcheck.sh"]

# Expose the port
EXPOSE ${PORT}

# Start the application
CMD ["node", "server/index.mjs"]
