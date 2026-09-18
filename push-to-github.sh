#!/bin/bash

# PanSou 前端代码推送脚本

echo "🚀 PanSou 前端优化 - GitHub 推送脚本"
echo "========================================"
echo ""

# 检查是否在正确的目录
if [ ! -f "package.json" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 显示当前状态
echo "📊 当前提交状态:"
git log -1 --oneline
echo ""

# 询问推送方式
echo "请选择推送方式:"
echo "1) 使用 GitHub Personal Access Token"
echo "2) 使用 SSH 密钥"
echo "3) 查看变更内容后决定"
echo ""
read -p "请输入选项 (1-3): " choice

case $choice in
    1)
        echo ""
        read -p "请输入您的 GitHub Personal Access Token: " token
        if [ -z "$token" ]; then
            echo "❌ Token 不能为空"
            exit 1
        fi
        
        # 设置远程 URL
        git remote set-url origin https://$token@github.com/fish2018/pansou-web.git
        
        echo ""
        echo "🔄 正在推送到 GitHub..."
        if git push origin main; then
            echo "✅ 推送成功!"
            echo "📱 查看构建状态: https://github.com/fish2018/pansou-web/actions"
        else
            echo "❌ 推送失败，请检查 Token 权限"
            exit 1
        fi
        ;;
        
    2)
        # 使用 SSH
        git remote set-url origin git@github.com:fish2018/pansou-web.git
        
        echo ""
        echo "🔄 正在推送到 GitHub..."
        if git push origin main; then
            echo "✅ 推送成功!"
            echo "📱 查看构建状态: https://github.com/fish2018/pansou-web/actions"
        else
            echo "❌ 推送失败，请检查 SSH 密钥配置"
            exit 1
        fi
        ;;
        
    3)
        echo ""
        echo "📄 本次变更内容:"
        echo "================"
        git diff HEAD~1 --stat
        echo ""
        echo "详细变更:"
        git show --stat
        echo ""
        echo "重新运行此脚本选择推送方式"
        ;;
        
    *)
        echo "❌ 无效的选项"
        exit 1
        ;;
esac

echo ""
echo "✨ 完成!"
