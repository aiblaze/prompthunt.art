/**
 * PM2 应用配置 - prompthunt
 */

// 使用自定义环境变量加载器
const { loadEnvFiles } = require('./env-loader')

// 加载环境变量文件
const envFiles = [
  '/xdeploy/apps/prompthunt/production/.env',
  '/xdeploy/apps/prompthunt/production/.env.local',
]

const loadedEnv = loadEnvFiles(envFiles)

module.exports = {
  name: 'prompthunt',
  script: '/xdeploy/apps/prompthunt/production/server/index.mjs',
  instances: 1,
  exec_mode: 'fork',
  watch: false,
  env: {
    // 从 .env 文件加载的所有环境变量
    ...loadedEnv,
  },
  log_date_format: 'YYYY-MM-DD HH:mm:ss',
  error_file: '/xdeploy/apps/prompthunt/production/logs/err.log',
  out_file: '/xdeploy/apps/prompthunt/production/logs/out.log',
  merge_logs: true,
  max_memory_restart: '1G',
}
