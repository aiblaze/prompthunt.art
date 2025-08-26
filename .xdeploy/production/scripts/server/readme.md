# 服务器部署脚本

此目录包含需要在服务器上执行的部署脚本。这些脚本会在 GitHub Actions 工作流中被上传到服务器并执行。

## 脚本列表

1. **post-cert-renewal.sh** - 证书更新后处理脚本，在证书更新后执行的操作，如重载 Nginx 等
2. **nginx-reload.sh** - Nginx 重载/重启脚本，用于重载或重启 Nginx 服务

## 添加新脚本

如果需要添加新的部署脚本，请将脚本放在此目录中，并确保脚本具有执行权限：

```bash
chmod +x scripts/server/your-script.sh
```

工作流会自动上传此目录中的所有 `.sh` 脚本到服务器的 `//xdeploy/apps/prompthunt/production/scripts` 目录，并赋予执行权限。

## 脚本依赖

如果脚本之间有依赖关系，请确保它们能够在同一目录中正确引用彼此。例如，`post-cert-renewal.sh` 会调用同目录下的 `nginx-reload.sh`。
