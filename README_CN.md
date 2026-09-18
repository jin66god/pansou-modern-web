# 🔍 PanSou Web - 网盘搜索前端

[![Build Status](https://github.com/fish2018/pansou-web/workflows/Build%20and%20Deploy/badge.svg)](https://github.com/fish2018/pansou-web/actions)
[![Vue 3](https://img.shields.io/badge/Vue-3.5.19-42b883?logo=vue.js)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.9.2-3178c6?logo=typescript)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4.0-38bdf8?logo=tailwind-css)](https://tailwindcss.com/)

一个现代化的网盘资源聚合搜索前端应用，支持多数据源、智能筛选和响应式设计。

---

## ✨ 特性

### 🎯 核心功能
- **多源搜索**: 整合 Telegram、QQ 频道、微博等多个数据源
- **智能筛选**: 实时筛选 13+ 种网盘类型
- **实时统计**: 动态显示搜索结果和筛选状态
- **响应式设计**: 完美适配桌面端和移动端

### 🎨 界面特点
- **现代化 UI**: 卡片式设计，清晰的视觉层次
- **流畅动画**: 微动效和过渡动画提升体验
- **暗色主题**: 护眼的配色方案（待开发）
- **无障碍**: 符合 WCAG 标准的可访问性设计

### ⚡ 性能优化
- **按需加载**: 组件懒加载减少首屏时间
- **前端缓存**: 智能缓存搜索结果
- **虚拟滚动**: 处理大数据集（待开发）

---

## 📦 技术栈

```
前端框架: Vue 3.5 + TypeScript 5.9
构建工具: Vite 5.4
样式方案: Tailwind CSS 3.4
HTTP 客户端: Axios 1.11
CI/CD: GitHub Actions
```

---

## 🚀 快速开始

### 环境要求
- Node.js >= 18.x
- npm >= 9.x

### 安装依赖
```bash
npm install
```

### 开发模式
```bash
npm run dev
```

访问 http://localhost:5173

### 生产构建
```bash
npm run build
```

构建产物位于 `dist/` 目录

---

## 📂 项目结构

```
pansou-web-upstream/
├── .github/
│   └── workflows/
│       └── build.yml          # GitHub Actions 构建配置
├── src/
│   ├── components/
│   │   ├── SearchFilter.vue   # ⭐ 筛选侧边栏（新）
│   │   ├── SearchForm.vue     # 搜索表单
│   │   ├── ResultTabs.vue     # 结果标签页
│   │   ├── SearchStats.vue    # 搜索统计
│   │   ├── SearchConfig.vue   # 配置管理
│   │   ├── AccountCenter.vue  # 账号中心
│   │   ├── QQPDManager.vue    # QQ 频道管理
│   │   ├── WeiboManager.vue   # 微博管理
│   │   ├── GyingManager.vue   # 观影管理
│   │   └── PanlianManager.vue # 盘链管理
│   ├── utils/
│   │   ├── diskTypes.ts       # 网盘类型定义
│   │   └── linkDetection.ts   # 链接检测工具
│   ├── api/                   # API 接口
│   ├── types/                 # TypeScript 类型定义
│   ├── App.vue                # ⭐ 主应用（已重构）
│   └── main.ts                # 入口文件
├── CHANGELOG.md               # 变更日志
├── PROJECT_REPORT.md          # 项目报告
├── PUSH_GUIDE.md              # 推送指南
├── push-to-github.sh          # 推送脚本
└── package.json               # 依赖配置
```

---

## 🎯 核心组件说明

### SearchFilter.vue （新增）
智能筛选侧边栏组件

**功能**:
- 数据源筛选（全部/Telegram/插件）
- 网盘类型筛选（支持 13 种）
- 实时结果统计
- 全选/多选/单选

**技术亮点**:
```vue
- 响应式设计（Grid 布局）
- 粘性定位（Sticky）
- 选中状态动画
- 移动端自适应
```

### App.vue（已重构）
主应用容器，新增筛选逻辑

**新增功能**:
```javascript
- 原始结果存储（rawSearchResults）
- 筛选状态管理（activeFilters）
- 前端筛选算法（applyFrontendFilters）
- 左右分栏布局（280px + flex）
```

---

## 🛠️ 开发指南

### 添加新的网盘类型

编辑 `src/utils/diskTypes.ts`:
```typescript
export const diskTypeNames: Record<string, string> = {
  'baidu': '百度网盘',
  'quark': '夸克网盘',
  // 添加新类型
  'newdisk': '新网盘'
};
```

### 添加新的筛选条件

修改 `src/components/SearchFilter.vue`:
```vue
<script setup lang="ts">
// 添加新的筛选状态
const newFilter = ref<string[]>([]);

// 在筛选逻辑中使用
const emitFilterChange = () => {
  emit('filter-change', {
    sources: selectedSources.value,
    diskTypes: selectedDiskTypes.value,
    newFilter: newFilter.value  // 新增
  });
};
</script>
```

---

## 📊 待完成功能

### 优先级 P0（紧急）
- [ ] 配置界面美化重构
- [ ] 管理员权限修复
- [ ] 筛选状态持久化

### 优先级 P1（重要）
- [ ] QQ 频道界面优化
- [ ] 微博管理界面优化
- [ ] 添加暗色主题

### 优先级 P2（建议）
- [ ] 虚拟滚动支持
- [ ] 搜索历史记录
- [ ] 热门搜索词推荐

详见 [PROJECT_REPORT.md](./PROJECT_REPORT.md)

---

## 🔗 相关链接

- **在线演示**: https://pansou.example.com （待部署）
- **后端仓库**: https://github.com/fish2018/pansou
- **问题反馈**: https://github.com/fish2018/pansou-web/issues
- **更新日志**: [CHANGELOG.md](./CHANGELOG.md)

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

---

## 📄 开源协议

本项目采用 MIT 协议开源，详见 [LICENSE](./LICENSE) 文件。

---

## 💬 联系方式

- **作者**: fish2018
- **邮箱**: your-email@example.com
- **GitHub**: https://github.com/fish2018

---

**⭐ 如果这个项目对你有帮助，请给个 Star！**
