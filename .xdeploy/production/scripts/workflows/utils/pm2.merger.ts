#!/usr/bin/env node
/**
 * PM2 配置合并工具
 *
 * 用法:
 * npx tsx pm2.merger.ts <服务器配置路径> <本地配置路径> <输出路径> <应用目录> [部署环境]
 */

import fs from 'node:fs'
import process from 'node:process'

/**
 * 检查服务器配置是否已包含应用配置路径
 * @param serverConfigContent 服务器配置内容
 * @param appConfigPath 应用配置路径
 * @returns 是否已包含
 */
function hasAppConfig(serverConfigContent: string, appConfigPath: string): boolean {
  return serverConfigContent.includes(appConfigPath)
}

/**
 * 解析 PM2 配置文件中的 apps 数组
 * @param content 配置文件内容
 * @returns 解析结果对象 {arrayContentStart, arrayContentEnd, arrayContent} 或 null
 */
function parseAppsArray(content: string): { arrayContentStart: number, arrayContentEnd: number, arrayContent: string } | null {
  const appsIndex = content.indexOf('apps:')
  if (appsIndex === -1) {
    console.log('未找到 apps 部分')
    return null
  }

  const arrayStartIndex = content.indexOf('[', appsIndex)
  if (arrayStartIndex === -1) {
    console.log('未找到数组开始位置')
    return null
  }

  // 手动匹配括号
  let bracketCount = 1
  let arrayEndIndex = arrayStartIndex + 1

  while (bracketCount > 0 && arrayEndIndex < content.length) {
    if (content[arrayEndIndex] === '[') {
      bracketCount++
    }
    else if (content[arrayEndIndex] === ']') {
      bracketCount--
    }
    arrayEndIndex++
  }

  if (bracketCount !== 0) {
    console.log('未找到匹配的括号')
    return null
  }

  // 找到匹配的括号
  const arrayContentStart = arrayStartIndex + 1
  const arrayContentEnd = arrayEndIndex - 1
  const arrayContent = content.substring(arrayContentStart, arrayContentEnd).trim()

  return { arrayContentStart, arrayContentEnd, arrayContent }
}

/**
 * 合并 PM2 配置文件
 * @param serverConfigPath 服务器 PM2 主配置拷贝至本地的文件路径
 * @param appConfigPath 服务器端的应用 PM2 配置文件路径，如 /xdeploy/apps/app1/production/scripts/pm2.config.js
 * @param outputPath 输出配置文件路径
 */
function mergePM2Configs(
  serverConfigPath: string,
  appConfigPath: string,
  outputPath: string,
): void {
  try {
    // 初始化输出内容变量
    let outputContent: string

    // 如果服务器配置不存在，直接生成新配置
    if (!fs.existsSync(serverConfigPath)) {
      outputContent = generateDefaultConfig(appConfigPath)
      console.log('服务器配置不存在，创建新配置')
    }
    // 服务器配置存在，处理已有配置
    else {
      // 读取服务器配置内容
      const serverContent = fs.readFileSync(serverConfigPath, 'utf-8')

      // 如果配置已包含当前应用，保持原样
      if (hasAppConfig(serverContent, appConfigPath)) {
        outputContent = serverContent
        console.log(`服务器配置已包含应用 ${appConfigPath}，保持原配置`)
      }
      // 配置不包含当前应用，尝试添加
      else {
        // 解析服务器配置文件
        const parseResult = parseAppsArray(serverContent)

        // 如果解析成功，添加新应用配置
        if (parseResult) {
          const { arrayContentStart, arrayContentEnd, arrayContent } = parseResult

          // 构建新的数组内容
          let newArrayContent = arrayContent

          // 如果数组不为空，添加逗号
          if (newArrayContent && !newArrayContent.endsWith(',')) {
            newArrayContent += ','
          }

          // 添加新的 require 语句
          newArrayContent += `\n    require('${appConfigPath}')`

          // 替换回原文件
          outputContent
            = serverContent.substring(0, arrayContentStart)
              + newArrayContent
              + serverContent.substring(arrayContentEnd)

          console.log(`在服务器配置中添加应用 ${appConfigPath}`)
        }
        // 解析失败，使用默认配置
        else {
          outputContent = generateDefaultConfig(appConfigPath)
          console.log('无法解析服务器配置，使用默认配置')
        }
      }
    }

    // 写入输出文件
    fs.writeFileSync(outputPath, outputContent)
    console.log(`成功合并 PM2 配置到: ${outputPath}`)
  }
  catch (error) {
    console.error(`合并 PM2 配置失败: ${error instanceof Error ? error.message : String(error)}`)
    process.exit(1)
  }
}

/**
 * 生成默认配置内容
 * @param appConfigPath 应用配置路径
 * @returns 配置文件内容
 */
function generateDefaultConfig(appConfigPath: string): string {
  return `/**
 * PM2 多应用配置文件
 * 自动管理由 X.DEPLOY 部署的应用
 */
module.exports = {
  apps: [
    require('${appConfigPath}')
  ]
};`
}

// 主函数
function main(): void {
  // 获取命令行参数
  const args = process.argv.slice(2)

  if (args.length < 3) {
    console.error('使用方法: npx tsx pm2.merger.ts <服务器 PM2 主配置拷贝至本地的文件路径> <服务器端的应用 PM2 配置文件路径> <输出路径>')
    process.exit(1)
  }

  const [serverConfigPath, localConfigPath, outputPath] = args

  // 执行合并
  mergePM2Configs(serverConfigPath, localConfigPath, outputPath)
}

// 入口点
main()
