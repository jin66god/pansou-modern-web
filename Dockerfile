# ============================================================
# PanSou Modern Web —— 纯前端镜像
# ------------------------------------------------------------
# 两阶段构建：
#   1) node 阶段把 Vue 前端编译成静态文件
#   2) nginx 阶段只提供静态文件 + 反向代理到已部署好的 PanSou 后端
#
# 本镜像 **不包含** PanSou 后端二进制。后端请使用上游
# ghcr.io/fish2018/pansou-web（一体化镜像）或你自己编译的
# pansou 服务，然后用 PANSOU_BACKEND_URL 指过来。
# ============================================================

# ---------- 阶段 1：编译前端 ----------
FROM node:20-alpine AS build

WORKDIR /app

# 先只拷贝依赖清单，最大化利用 Docker 层缓存
COPY package.json package-lock.json ./

# --include=dev 必须有：tailwindcss / typescript / postcss 都在 devDependencies
# 有些环境把 NODE_ENV 设成 production，会顺手跳过 devDependencies 导致构建失败
ENV NODE_ENV=development
RUN npm ci --include=dev --no-audit --no-fund

# 拷贝源码并构建
COPY . .
RUN npm run build && test -f dist/index.html

# ---------- 阶段 2：运行 ----------
FROM nginx:1.27-alpine

# curl 供 HEALTHCHECK 使用；tzdata 保证日志时间是本地时区
RUN apk add --no-cache curl tzdata \
 && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && echo "Asia/Shanghai" > /etc/timezone \
 && rm -rf /var/cache/apk/*

# 默认后端地址：host.docker.internal 指向宿主机（compose 里用 extra_hosts 映射）
# 如果你的后端是同一 compose 网络里的容器，改成 http://pansou:80 即可
ENV TZ=Asia/Shanghai \
    PANSOU_BACKEND_URL=http://host.docker.internal:8890 \
    PANSOU_PROXY_READ_TIMEOUT=180s \
    PANSOU_CLIENT_MAX_BODY_SIZE=8m

# 前端静态文件
COPY --from=build /app/dist /usr/share/nginx/html

# nginx 官方镜像会自动把 /etc/nginx/templates/*.template 用 envsubst
# 渲染到 /etc/nginx/conf.d/，变量只在容器启动时求值，改 .env 重启即可生效
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
RUN rm -f /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
