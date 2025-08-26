# 硅人语言艺术

🌈 硅人（AI）语言艺术（PROMPTHUNT）官网项目，基于 [Nuxt](https://nuxt.com/) 定制开发。

## 品牌色

<span style="background-color: #0048E6;color: #ffffff;padding: 2px;">星火蓝#0048E6</span>，延续克<span style="background-color: #002FA7; color: #ffffff; padding: 2px;">莱因蓝#002FA7</span>的深邃艺术基因，以更炽烈的数字光谱点燃AI未来。

在原色基础上提升明度（+15%），降低灰度，保留高饱和度，更适合数字屏幕显示。

## 本地开发

1. 获取代码

```bash
git clone https://github.com/aiblaze/prompthunt.art.git
```

2. 安装依赖

```bash
cd prompthunt.art
pnpm i
```

3. 运行开发服务器

```bash
pnpm dev
```

## 部署

基于 [x.deploy](https://github.com/aispin/x.deploy) 实现高效部署。

## 其他

### Package.json

解决 `nuxt-image` 组件无法正常显示图片的[问题](https://github.com/nuxt/image/issues/1372)

```
"pnpm": {
  "onlyBuiltDependencies": [
    "better-sqlite3",
    "esbuild",
    "sharp"
  ],
  "supportedArchitectures": {
    "os": [
      "current",
      "linux"
    ],
    "cpu": [
      "current",
      "x64"
    ]
  },
  "overrides": {
    "sharp": "0.33.5"
  }
}
```
