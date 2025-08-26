# Builder stage 1 - Build the application
FROM node:24-alpine AS builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@10.5.2 --activate

WORKDIR /app

# Copy the essential files
COPY .npmrc package.json pnpm-lock.yaml ./

# Install dependencies with rebuild for native modules
RUN pnpm install --frozen-lockfile

# Copy the entire project
COPY . ./

# Set environment variables for build
ENV NODE_ENV=production
ENV NUXT_TELEMETRY_DISABLED=1
# 设置内存限制
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Build the application
RUN pnpm build

# Build stage 2 - the production image, copy all the files and run next
FROM node:24-alpine

WORKDIR /app

# 安装健康检查所需的工具
RUN apk add --no-cache curl wget busybox-extras

# Copy only the built application from the previous stage
COPY --from=builder /app/.output ./

# 创建脚本目录并复制健康检查脚本
COPY scripts/docker/healthcheck.sh /app/scripts/healthcheck.sh
RUN chmod +x /app/scripts/healthcheck.sh

# Default port (can be overridden by APP_PORT_DOCKER)
ARG PORT=3013
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=${PORT}

# 设置健康检查
HEALTHCHECK --interval=30s --timeout=15s --start-period=20s --retries=5 \
  CMD ["/app/scripts/healthcheck.sh"]

# Expose the port
EXPOSE ${PORT}

# Start the application
CMD ["node", "server/index.mjs"]
