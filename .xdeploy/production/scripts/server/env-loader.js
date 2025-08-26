/**
 * 环境变量加载器
 * 用于 PM2 配置文件中动态加载环境变量
 */

const fs = require('node:fs')

/**
 * 解析 .env 文件内容
 * @param {string} content - .env文件内容
 * @returns {object} - 解析后的环境变量对象
 */
function parseEnvFile(content) {
  const env = {}
  const lines = content.split('\n')

  for (const line of lines) {
    const trimmedLine = line.trim()

    // 跳过空行和注释行
    if (!trimmedLine || trimmedLine.startsWith('#')) {
      continue
    }

    // 查找等号位置
    const equalIndex = trimmedLine.indexOf('=')
    if (equalIndex === -1) {
      continue
    }

    const key = trimmedLine.substring(0, equalIndex).trim()
    let value = trimmedLine.substring(equalIndex + 1).trim()

    // 移除引号
    if ((value.startsWith('"') && value.endsWith('"'))
      || (value.startsWith('\'') && value.endsWith('\''))) {
      value = value.slice(1, -1)
    }

    env[key] = value
  }

  return env
}

/**
 * 加载环境变量文件
 * @param {string} envPath - .env文件路径
 * @returns {object} - 环境变量对象
 */
function loadEnvFile(envPath) {
  try {
    if (!fs.existsSync(envPath)) {
      console.warn(`环境变量文件不存在: ${envPath}`)
      return {}
    }

    const content = fs.readFileSync(envPath, 'utf8')
    return parseEnvFile(content)
  }
  catch (error) {
    console.error(`加载环境变量文件失败: ${envPath}`, error)
    return {}
  }
}

/**
 * 加载多个环境变量文件
 * @param {string[]} envPaths - .env文件路径数组
 * @returns {object} - 合并后的环境变量对象
 */
function loadEnvFiles(envPaths) {
  let combinedEnv = {}

  for (const envPath of envPaths) {
    const env = loadEnvFile(envPath)
    combinedEnv = { ...combinedEnv, ...env }
  }

  return combinedEnv
}

module.exports = {
  parseEnvFile,
  loadEnvFile,
  loadEnvFiles,
}
