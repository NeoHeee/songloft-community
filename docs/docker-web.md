# Songloft Community Web Docker 部署

Songloft Community Web 镜像将 Flutter Web 编译为 **embedded 模式**，并由 Nginx 同时提供静态页面和 `/api/` 反向代理。

浏览器始终访问同一个来源：

```text
浏览器 → http(s)://Web地址/
浏览器 → http(s)://Web地址/api/v1/...
                         ↓ Nginx 代理
              SONGLOFT_API_URL/api/v1/...
```

因此不需要在浏览器里扫描服务器，也不需要为 Web 与 API 单独处理 CORS。通过 HTTPS 发布时，浏览器也不会出现“HTTPS 页面请求 HTTP API”的混合内容问题。

## 一、直接使用已发布镜像

镜像地址：

```text
ghcr.io/neoheee/songloft-community-web:latest
```

支持：

- `linux/amd64`：威联通 TS-464C2、普通 Intel/AMD NAS 与服务器；
- `linux/arm64`：ARM64 NAS、树莓派和 ARM 服务器。

### Docker Compose

仓库根目录已提供：

```text
docker-compose.web.yml
```

先创建 `.env`：

```env
SONGLOFT_WEB_PORT=58092
SONGLOFT_API_URL=http://10.10.10.100:58091
```

其中：

- `SONGLOFT_WEB_PORT`：Web 播放器对外端口；
- `SONGLOFT_API_URL`：现有 Songloft 后端地址；
- 后端地址不要追加 `/api/v1`；
- 建议不要保留末尾 `/`。

启动：

```bash
docker compose -f docker-compose.web.yml up -d
```

查看状态：

```bash
docker compose -f docker-compose.web.yml ps
```

浏览器访问：

```text
http://NAS_IP:58092
```

更新镜像：

```bash
docker compose -f docker-compose.web.yml pull
docker compose -f docker-compose.web.yml up -d
```

停止并删除容器：

```bash
docker compose -f docker-compose.web.yml down
```

## 二、威联通 Container Station

进入：

```text
Container Station → 应用程序 → 创建
```

粘贴以下 YAML，并把后端 IP 改为实际地址：

```yaml
services:
  songloft-community-web:
    image: ghcr.io/neoheee/songloft-community-web:latest
    container_name: songloft-community-web
    restart: unless-stopped
    ports:
      - "58092:80"
    environment:
      SONGLOFT_API_URL: "http://10.10.10.100:58091"
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

创建完成后访问：

```text
http://威联通IP:58092
```

### 后端在同一台 NAS 上

如果 Songloft 后端通过 NAS 主机端口 `58091` 暴露，可使用：

```yaml
SONGLOFT_API_URL: "http://host.docker.internal:58091"
```

Compose 中应保留：

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### 后端使用 macvlan 独立 IP

直接填写后端的局域网地址，例如：

```yaml
SONGLOFT_API_URL: "http://10.10.10.201:58091"
```

### 后端与 Web 在同一个 Docker 网络

可以使用后端服务名，例如：

```yaml
SONGLOFT_API_URL: "http://songloft:58091"
```

并让两个服务加入同一个 Docker 网络。

## 三、HTTPS 与公网访问

建议只把 Web 容器交给 Lucky、Nginx Proxy Manager、Caddy 或其他反向代理：

```text
https://music.example.com → http://NAS_IP:58092
```

浏览器访问 `/api/v1/...` 时，Web 容器会再转发给内部 Songloft 后端。因此：

- 公网通常只需要暴露 Web 入口；
- 后端端口可以继续仅在局域网使用；
- Web 页面和 API 对浏览器保持同域；
- 登录、封面、音频流和插件 API 不需要额外配置 CORS。

反向代理应允许较长连接和音频流传输。容器内 Nginx 已关闭 API 响应缓冲，并保留 Range 请求头。

## 四、首次发布 GHCR 镜像

仓库工作流：

```text
.github/workflows/docker-web.yml
```

在 PR 中会：

1. 使用 Flutter 3.41.5 构建 embedded 模式 Web；
2. 构建 `linux/amd64` 测试镜像；
3. 启动容器执行 `/healthz`、首页和 `nginx -t` 冒烟测试。

合并到 `main` 后会发布：

```text
ghcr.io/neoheee/songloft-community-web:latest
ghcr.io/neoheee/songloft-community-web:1.0.0-community.2
ghcr.io/neoheee/songloft-community-web:sha-xxxxxxx
```

首次生成包后，若 GHCR 页面显示为 Private，需要在 GitHub 包设置中把可见性改为 Public。保持私有时，也可以先在 NAS 登录：

```bash
docker login ghcr.io
```

用户名填写 GitHub 用户名，密码使用具备 `read:packages` 权限的 Personal Access Token。

## 五、从源码构建运行镜像

Docker 运行镜像只负责包装已经生成的 `build/web`。本地需要先完成 Flutter Web 构建：

```bash
flutter pub get
printf "var _deployMode = 'embedded';\n" > web/deploy-mode.js
flutter build web --release --base-href / \
  --dart-define=DEPLOY_MODE=embedded \
  --dart-define=FRONTEND_VERSION=dev
```

再构建容器镜像：

```bash
docker build \
  -f docker/web/Dockerfile \
  -t songloft-community-web:local \
  .
```

运行：

```bash
docker run -d \
  --name songloft-community-web \
  --restart unless-stopped \
  -p 58092:80 \
  -e SONGLOFT_API_URL=http://10.10.10.100:58091 \
  songloft-community-web:local
```

## 六、健康检查与排错

健康检查：

```text
http://NAS_IP:58092/healthz
```

正常返回：

```text
ok
```

查看日志：

```bash
docker logs songloft-community-web
```

启动日志中应包含：

```text
[songloft-web] proxying /api/ to http://...
```

### 页面能打开，但登录失败

检查：

1. `SONGLOFT_API_URL` 是否能从 Web 容器内部访问；
2. 地址是否错误追加了 `/api/v1`；
3. 后端端口是否开放；
4. macvlan 网络是否允许 NAS 主机或其他容器访问；
5. 后端为 HTTPS 时，域名、证书和端口是否正确。

测试代理：

```text
http://NAS_IP:58092/api/v1/health
```

### 刷新子页面出现 404

镜像内已配置 Flutter SPA 回退。若外层反向代理仍然拦截路径，应确保所有非静态路径继续转发给 Web 容器，而不是由外层代理自己查找文件。

### 更新后仍看到旧页面

先强制刷新浏览器，或清理该站点的缓存与 Service Worker。镜像对 `index.html`、`flutter_service_worker.js` 和 `version.json` 已设置禁止缓存。
