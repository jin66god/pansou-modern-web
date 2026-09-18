# 🚀 如何推送代码到 GitHub

## 快速推送

### 方法 1：使用推送脚本（推荐）

```bash
cd /root/hermes-tasks/pansou-web-upstream
./push-to-github.sh
```

按提示操作即可。

### 方法 2：手动推送

#### 使用 Personal Access Token

```bash
cd /root/hermes-tasks/pansou-web-upstream

# 1. 创建 GitHub Personal Access Token
# 访问: https://github.com/settings/tokens
# 权限: repo (全部)

# 2. 配置远程仓库
git remote set-url origin https://YOUR_TOKEN@github.com/fish2018/pansou-web.git

# 3. 推送
git push origin main
```

#### 使用 SSH 密钥

```bash
cd /root/hermes-tasks/pansou-web-upstream

# 1. 确保已配置 SSH 密钥
# 查看: cat ~/.ssh/id_rsa.pub
# 添加到 GitHub: https://github.com/settings/keys

# 2. 配置远程仓库
git remote set-url origin git@github.com:fish2018/pansou-web.git

# 3. 推送
git push origin main
```

## 📋 推送前检查清单

- [x] 所有文件已提交 (`git status` 显示干净)
- [x] 提交信息清晰
- [x] CHANGELOG.md 已更新
- [x] GitHub Actions 配置已添加
- [ ] 有推送权限（Token 或 SSH）

## 🔍 推送后验证

1. **访问仓库**: https://github.com/fish2018/pansou-web
2. **查看提交**: 确认最新提交出现
3. **查看 Actions**: https://github.com/fish2018/pansou-web/actions
4. **检查构建状态**: 等待绿色勾号 ✅

## 📦 GitHub Actions 自动构建

推送后会自动触发构建流程：

```yaml
步骤:
1. ✅ Checkout 代码
2. ✅ 安装 Node.js 18
3. ✅ 安装依赖 (npm ci)
4. ✅ 构建项目 (npm run build)
5. ✅ 上传构建产物
```

### 查看构建结果

- **成功**: 绿色勾号，dist 文件夹已生成
- **失败**: 红色叉号，查看日志修复错误

## 🐛 常见问题

### Q1: Permission denied (403)

**原因**: 没有推送权限  
**解决**: 使用正确的 Token 或 SSH 密钥

```bash
# 检查当前配置
git remote -v

# 重新配置
git remote set-url origin https://YOUR_TOKEN@github.com/fish2018/pansou-web.git
```

### Q2: Authentication failed

**原因**: Token 过期或权限不足  
**解决**: 重新生成 Token，确保勾选 `repo` 权限

### Q3: GitHub Actions 构建失败

**原因**: 依赖问题或代码错误  
**解决**: 
1. 查看 Actions 日志
2. 本地运行 `npm ci && npm run build` 测试
3. 修复后重新推送

### Q4: 无法找到 tailwindcss

**原因**: 本地依赖未安装  
**解决**: GitHub Actions 会自动安装，本地可以：

```bash
rm -rf node_modules package-lock.json
npm install
```

## 📞 需要帮助？

如果推送遇到问题：

1. 检查网络连接
2. 验证 GitHub 账户权限
3. 查看错误信息
4. 联系仓库管理员

---

**提示**: 推送成功后，可以在 GitHub 上创建 Pull Request 进行代码审查。
