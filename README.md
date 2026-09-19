# PanSou Modern Web

PanSou 网盘搜索的现代化前端工作台。**纯前端项目** —— 镜像里只有静态页面和 Nginx，
通过 `PANSOU_BACKEND_URL` 连接你已经部署好的 [fish2018/pansou](https://github.com/fish2018/pansou) 后端。

> 如果你已经有后端在跑（上游一体化镜像 `ghcr.io/fish2018/pansou-web` 或自编译的 pansou），
> 只需要部署本项目的前端容器，见「三、只部署前端」。

## 特性

### 搜索
- 关键词搜索；数据来源可切「全部 / Telegram / 插件」
- 并发数、强制刷新、响应内容（全部 / 合并链接 / 原始消息）
- 内容过滤：包含任一关键词（OR）、排除任一关键词（AND）
- 插件扩展参数：JSON 编辑器

### 结果
- 按网盘类型分组（夸克、百度、阿里、UC、115、123、迅雷、天翼、移动、PikPak、光鸭、磁力、电驴）
- 每条结果含来源、时间、提取码，支持复制链接与新标签页打开
- 原始消息视图：频道/插件、标题、正文、标签与一条消息内的全部链接
- 批量导出为 JSON / TXT，可勾选字段与网盘类型

### 筛选（左侧面板）
- 数据来源筛选（Telegram / 插件），带各来源条数
- 网盘类型筛选：按结果数量排序、显示每类条数、支持「全选 / 仅此」，
  类型多时可搜索网盘名
- 已选条件以胶囊展示，可单个移除或一键清除
- 窄屏自动折叠为卡片

### 账号与插件管理
- **配置中心**：勾选参与搜索的 TG 频道 / 插件 / 网盘类型，
  一键导出后端 `ENABLED_PLUGINS`、`CHANNELS` 环境变量
- **账号管理**：QQ 频道、微博、观影、盘链 四个插件账号页
  （扫码登录、状态、测试搜索），由后端插件决定是否可用

### 其它
- 链接检测：批量识别网盘链接并检查有效性，支持单次代理
- API 文档页：内置接口说明
- 管理员 JWT 登录（后端 `AUTH_ENABLED=true` 时启用）
- 响应式布局、减少动画模式、键盘焦点

## 架构

```text
浏览器
  │
  ▼
────────────────────────────┐
│ pansou-modern-web 容器      │  ← 本项目（Nginx + 静态文件）
│  /               前端页面   │
│  /api/*          ─        │
│  /qqpd/*          │        │
│  /weibo/*         ├─ 反代 ───► PanSou 后端（你已部署）
│  /gying/*         │        │      /api/search  /api/health
│  /panlian/*      ─┘        │      /qqpd/:hash  /weibo/:hash  …
│  /healthz        自身探针   │
└────────────────────────────┘
```

前端不做跨域请求：所有后端调用都走同源路径，由容器内 Nginx 转发。

## 目录结构

```text
.
├── src/                       Vue 3 前端源码
│   ├── components/            页面与组件
│   │   ├── SearchFilter.vue         左侧筛选面板
│   │   ├── SearchConfigModern.vue   配置中心
│   │   ├── ResultTabs.vue           结果分组视图
│   │   ├── QQPDManager.vue          QQ 频道账号页
│   │   ├── WeiboManager.vue         微博账号页
│   │   ├── GyingManager.vue         观影账号页
│   │   └── PanlianManager.vue       盘链账号页
│   ├── api/                   接口封装（含插件账号接口）
│   ── utils/diskTypes.ts     网盘类型元数据
├── nginx.conf.template        反代配置模板（容器启动时渲染）
├── Dockerfile                 两阶段构建：Node 构建 + Nginx 运行
├── docker-compose.yml         纯前端部署编排
├── .env.example               环境变量说明
└── .github/workflows/build.yml  CI：校验 + 构建多架构镜像推 GHCR
```

## 一、快速开始（用现成镜像）

```bash
mkdir -p ~/pansou-modern-web && cd ~/pansou-modern-web
curl -fsSL https://raw.githubusercontent.com/jin66god/pansou-modern-web/master/docker-compose.yml -o docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/jin66god/pansou-modern-web/master/.env.example -o .env
chmod 600 .env
vi .env          # 改 PANSOU_BACKEND_URL 为你的后端地址
docker compose config --quiet
docker compose pull
docker compose up -d --no-build
docker compose ps
curl -fsS http://127.0.0.1:13080/healthz && echo "  前端正常"
```

访问 `http://127.0.0.1:13080`。

## 二、从源码构建

```bash
git clone https://github.com/jin66god/pansou-modern-web.git
cd pansou-modern-web
cp .env.example .env && chmod 600 .env
vi .env
docker compose build        # 本地构建镜像，不用等 CI
docker compose up -d
```

## 三、只部署前端（后端已存在，推荐）

这是本项目最主要的用法，覆盖三种后端位置：

**情况 A：后端跑在宿主机上（最常见）**

```dotenv
PANSOU_BACKEND_URL=http://host.docker.internal:8890
```

`docker-compose.yml` 已通过 `extra_hosts: host.docker.internal:host-gateway` 保证
Linux 上也能解析。后端监听 `127.0.0.1:8890` 即可，不需要对公网开放。

**情况 B：后端是同一台机器上另一个容器**

把两个服务放进同一网络，然后直接把地址写成容器名：

```dotenv
PANSOU_BACKEND_URL=http://pansou-web:80
```

**情况 C：后端在另一台机器**

```dotenv
PANSOU_BACKEND_URL=http://10.0.0.12:8890
```

> 地址不要带结尾斜杠，也不要带 `/api` 后缀。

部署后验证：

```bash
docker compose exec pansou-frontend curl -fsS http://host.docker.internal:8890/api/health
curl -fsS http://127.0.0.1:13080/api/health
```

两条都返回 `{"status":"ok",...}` 说明链路通了。

## 四、用 OpenResty / Nginx 反代并上 HTTPS

前端容器只监听 `127.0.0.1:13080`，公网访问请加一层反代。示例：

```nginx
server {
    listen 80;
    server_name pansou.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name pansou.example.com;

    ssl_certificate     /etc/letsencrypt/live/pansou.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pansou.example.com/privkey.pem;

    # 搜索可能跑 20~60 秒，超时给足，否则反代会先断
    proxy_read_timeout   300s;
    proxy_send_timeout   300s;
    client_max_body_size 8m;

    location / {
        proxy_pass http://127.0.0.1:13080;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

注意两点：

1. **只反代 `/` 就够了**。`/api`、`/qqpd`、`/weibo`、`/gying`、`/panlian`
   都由前端容器的 Nginx 内部转发给后端，外层不需要再配一遍，否则容易出现
   双重前缀（`/api/api/...`）。
2. 外层反代的 `proxy_read_timeout` 要大于等于容器里的 `PANSOU_PROXY_READ_TIMEOUT`，
   否则长搜索会被外层提前截断。

## 五、环境变量

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PANSOU_BACKEND_URL` | `http://host.docker.internal:8890` | **必改**。后端 PanSou 地址，不带结尾斜杠、不带 `/api` |
| `PANSOU_FRONTEND_IMAGE` | `ghcr.io/jin66god/pansou-modern-web:latest` | 前端镜像，生产建议固定 tag |
| `PANSOU_FRONTEND_PORT` | `13080` | 宿主映射端口 |
| `PANSOU_FRONTEND_BIND` | `127.0.0.1` | 宿主监听地址，`0.0.0.0` 会直接暴露公网 |
| `PANSOU_CONTAINER_NAME` | `pansou-modern-web` | 容器名 |
| `PANSOU_PROXY_READ_TIMEOUT` | `180s` | 反代读超时，搜索是长请求 |
| `PANSOU_CLIENT_MAX_BODY_SIZE` | `8m` | 请求体上限（批量链接检测） |
| `TZ` | `Asia/Shanghai` | 时区 |

改完 `.env` 后 `docker compose up -d` 生效（Nginx 模板在容器启动时重新渲染）。

## 六、CI 与镜像

`.github/workflows/build.yml` 一个工作流干两件事：

1. `assets`：`npm ci --include=dev` + `npm run build` + 校验 `dist/index.html`，
   然后把 `dist` 作为 artifact 上传（先失败先报，坏代码不进镜像）
2. `publish`：取回 `dist`，用 `Dockerfile.prebuilt` 构建
   `linux/amd64` + `linux/arm64` 双架构镜像并推到 GHCR

**为什么镜像阶段不跑 node**：`Dockerfile` 是「node 构建 + nginx 运行」两阶段，
直接拿它做多架构构建时，`linux/arm64` 会在 QEMU 模拟下执行 `npm ci` + `vite build`，
实测会卡住几十分钟甚至一直不结束。所以 CI 里改成「在 amd64 上编译一次产物，
再用 `Dockerfile.prebuilt` 打包两种架构」，构建时间降到 2 分钟左右。

两个 Dockerfile 的分工：

| 文件 | 用途 | 是否跑 node |
| --- | --- | --- |
| `Dockerfile` | 本地 `docker compose build`、单架构 | 是 |
| `Dockerfile.prebuilt` | CI 多架构打包，需要已存在的 `dist/` | 否 |

镜像标签：

| 触发 | 标签 |
| --- | --- |
| push 到 `master` | `latest`、`master`、`sha-<短哈希>` |
| push tag `v1.2.3` | `1.2.3`、`1.2`、`latest`、`sha-<短哈希>` |
| Pull Request | 只构建不推送，并起容器做 `/healthz` 冒烟测试 |

拉取镜像（该包当前是 **public**，不需要登录）：

```bash
docker pull ghcr.io/jin66god/pansou-modern-web:latest
```

如果哪天包被改成私有，先登录再拉：

```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u <你的GitHub用户名> --password-stdin
docker pull ghcr.io/jin66god/pansou-modern-web:latest
```

改可见性：GitHub 仓库 → Packages → 该包 → Package settings → Change visibility。

**生产环境不要用 `latest`**，改用具体 tag，避免 `docker compose pull` 时被悄悄升级：

```dotenv
PANSOU_FRONTEND_IMAGE=ghcr.io/jin66god/pansou-modern-web:sha-1a2b3c4
```

## 七、本地开发

```bash
npm ci --include=dev
npm run dev          # http://localhost:3000（vite.config.js 里 server.host 为 localhost）
```

开发服务器把 `/api`、`/qqpd`、`/weibo`、`/gying`、`/panlian`
代理到 `VITE_API_BASE_URL`（默认 `http://localhost:8888`）：

```bash
VITE_API_BASE_URL=http://127.0.0.1:8890 npm run dev
```

生产构建与本地预览：

```bash
npm run build
npm run preview
```

> 若构建报 `Cannot find module 'tailwindcss'`：说明 devDependencies 没装上。
> 常见原因是 `~/.npmrc` 里有 `omit=dev` 或环境变量 `NODE_ENV=production`。
> 用 `NODE_ENV=development npm install --include=dev` 修复。

## 八、配置中心的边界（重要）

前端**不能**在线修改后端的插件/频道配置，原因是上游后端的 HTTP 接口只有：

```text
POST /api/auth/login      POST /api/auth/verify    POST /api/auth/logout
GET|POST /api/search      POST /api/check/links    GET /api/health
```

没有任何写配置的接口。所以「配置中心」的定位是：

- 勾选的频道 / 插件 / 网盘类型保存在**本机浏览器**，搜索时作为
  `channels`、`plugins`、`cloud_types` 参数发给后端 —— 改完立刻对后续搜索生效；
- 需要改**服务端**启用列表时，用页面上的「导出环境变量」拿到
  `ENABLED_PLUGINS=...` / `CHANNELS=...`，填进后端容器的 `.env` 后重启后端。

QQ 频道、微博、观影、盘链 这四个账号页则**是**真正的服务端操作：
它们调用后端插件注册的 `/qqpd/:hash`、`/weibo/:hash`、`/gying/:hash`、`/panlian/:hash`
接口完成扫码登录与账号管理。如果导航栏看不到「账号」入口，说明后端这些插件没启用 ——
把插件名加进后端 `ENABLED_PLUGINS` 并重启即可。

## 九、故障排查

### 页面打不开 / 502

```bash
docker compose ps
docker compose logs --tail=100 pansou-frontend
docker compose exec pansou-frontend curl -fsS http://127.0.0.1/healthz   # 前端自身
docker compose exec pansou-frontend curl -fsS $PANSOU_BACKEND_URL/api/health  # 到后端
```

`/healthz` 通、`/api/health` 不通 = 后端地址配错了，或后端没在跑。

### `host.docker.internal` 解析不了

```bash
docker compose exec pansou-frontend getent hosts host.docker.internal
```

没输出就说明 `extra_hosts` 没生效（老版本 Docker）。改成写死宿主机内网 IP：

```dotenv
PANSOU_BACKEND_URL=http://172.17.0.1:8890
```

### API 返回 401

后端启用了 `AUTH_ENABLED=true`。点页面右上角「管理员登录」，用后端
`AUTH_USERS` 里配置的账号。登录态存在浏览器 localStorage，
后端 `AUTH_TOKEN_EXPIRY` 到期后需重新登录。

### 搜索很慢或中途断开

搜索要并发抓取 TG 和几十个插件。调大超时：

```dotenv
PANSOU_PROXY_READ_TIMEOUT=300s
```

外层反代的 `proxy_read_timeout` 也要一起调大。

### 搜索结果很少

1. 打开「配置」页确认频道/插件没被误过滤；
2. 确认后端 `CHANNELS`、`ENABLED_PLUGINS` 里没有写错的名字；
3. 后端机器要能访问 Telegram 和插件站点，必要时在后端配 `PROXY`；
4. 勾选「强制刷新」跳过缓存再搜一次。

### 筛选点了没反应

筛选是纯前端过滤已拿到的结果。如果某个网盘类型下面本来就没数据，
筛选面板里不会出现该类型（面板只列**实际有结果**的网盘）。点「清除」可恢复全部。

### 页面上能搜但账号页 404

对应插件未在后端启用，或后端版本较旧没有注册该 Web 路由。
看后端启动日志里有没有 `[QQPD] Web路由已注册` / `[Weibo] Web路由已注册`。

## 十、安全建议

- 前端容器默认只绑 `127.0.0.1`，不要改成 `0.0.0.0` 直接暴露；
- `.env` 用 `chmod 600`，不要提交到 Git；
- 不要把管理员账号密码写进前端源码或聊天记录；
- 后端的 `/api/search` 无鉴权时任何人可调用，建议开启 `AUTH_ENABLED`；
- 生产环境固定镜像 tag，并定期 `docker compose pull` 更新。

## License

本前端采用 MIT License。上游 [PanSou](https://github.com/fish2018/pansou)
及其第三方插件的许可证以各自仓库为准。