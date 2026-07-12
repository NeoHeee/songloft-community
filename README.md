# Songloft Community Edition

<p align="center">
  <strong>🎵 一个更适合手机、桌面与电视使用的 Songloft 社区魔改版客户端</strong>
</p>

<p align="center">
  <a href="https://github.com/NeoHeee/songloft-player/actions"><img src="https://img.shields.io/github/actions/workflow/status/NeoHeee/songloft-player/ui-redesign-check.yml?branch=main&label=build" alt="Build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/NeoHeee/songloft-player" alt="License"></a>
  <a href="https://github.com/NeoHeee/songloft-player"><img src="https://img.shields.io/github/stars/NeoHeee/songloft-player" alt="Stars"></a>
  <img src="https://img.shields.io/badge/Flutter-3.41.5-02569B?logo=flutter" alt="Flutter">
</p>


<img width="1536" height="1024" alt="ae63b573-3fde-444e-9873-108dd3e17b1f" src="https://github.com/user-attachments/assets/3cff0c1d-06c0-4b8b-91d5-44fc2fe25f94" />


## 项目介绍

本项目是在开源音乐服务器项目 [Songloft](https://github.com/songloft-org/songloft) 及其 Flutter 客户端基础上持续改造的 **社区魔改版播放器**。

在保留原有服务端接口、认证方式、播放器能力和 JavaScript 插件协议的前提下，本版本重点重做了界面体系、移动端操作逻辑、歌单管理、插件入口和主题系统，使其更适合日常在 Android 手机、Windows 桌面、Web 与 Android TV 上使用。

> 本仓库为社区维护版本，并非 Songloft 官方发行版。原始项目及相关版权归原作者和贡献者所有。

## 版本亮点

### 全新响应式界面

- 使用 Material 3 重新统一首页、歌曲库、歌单、播放器、设置和插件页面
- 手机、平板、桌面和 TV 使用不同的导航与内容布局
- 手机端采用底部导航，桌面端采用侧边栏，TV 端提供大屏焦点布局
- 首页欢迎语、数据卡片和快捷入口针对窄屏重新排版
- 浅色、深色及跟随系统模式均支持完整配色

### 更符合 Android 习惯的返回逻辑

- 二级页面返回上一级
- 歌曲库、歌单、设置和插件等一级页面返回首页
- 设置分类详情先返回设置列表
- 播放队列展开时优先关闭队列
- 插件网页优先返回网页历史
- 首页需要在两秒内连续按两次返回键才会退出应用

### 更实用的歌单管理

- 搜索歌单和歌单内歌曲
- 多选、隐藏和恢复歌单
- 批量删除歌曲
- 歌单永久排序
- 卡片和列表两种展示方式
- 编辑、删除及响应式详情页

### 插件体验重做

- 首页展示插件快捷入口
- 可自行控制哪些插件在首页显示或隐藏
- 隐藏快捷入口不会停用或卸载插件
- 插件图标、卡片和状态样式统一
- 手机底部导航最多保留五个入口，多余插件统一进入“更多”
- 保留原有 JS 插件协议和插件 WebView 能力

### 自定义主题包

- 内置 Songloft 经典、深海蓝、森林绿、暮色玫瑰等主题
- 支持导入 `.songloft-theme` 或 JSON 主题文件
- 支持导入前预览、覆盖更新、导出和删除
- 支持浅色与深色两套配色共同打包
- 可设置主色、背景、面板、辅助色、播放器渐变及圆角参数
- 自定义主题设置保存在本地，重启后继续生效

### 在线主题目录

客户端可直接访问本仓库维护的在线主题目录：

- 搜索主题、作者、标签和简介
- 自动识别未安装、已安装和可更新状态
- 仅允许受信任的 HTTPS 来源
- 下载后校验 SHA-256 和主题身份信息
- 远程目录不可用时自动回退到安装包内置安全快照
- 安装前仍需用户确认，不执行 JavaScript、CSS、HTML 或其他代码

在线目录文件位于：

```text
assets/theme_catalog/catalog.json
assets/theme_catalog/themes/
```

主题制作规范参见 [docs/theme-packs.md](docs/theme-packs.md)。

## 核心能力

- 本地音乐库管理与在线播放
- 后台播放、播放队列、歌词和进度控制
- 歌曲搜索、筛选和信息编辑
- 歌单创建、整理和批量管理
- JWT 登录与多服务器配置
- JavaScript 插件扩展
- DLNA 投放
- 浅色、深色、自定义及在线主题
- Android、Windows、Web 与 TV 响应式适配
- 支持标准远程服务模式与 Bundle 本地模式

## 平台状态

| 平台 | 当前状态 | 说明 |
|------|----------|------|
| Android 手机 | ✅ 重点适配 | ARM64 设备推荐使用 `arm64-v8a` APK |
| Windows x64 | ✅ 已验证构建 | 支持便携版及内置 Go 后端模式 |
| Web | ✅ 已验证构建 | 支持 standalone 与 embedded 模式 |
| Android TV | 🟡 基础可用 | 已有 TV 首页、遥控器焦点和大屏播放器，部分设置与插件页面仍在持续优化 |
| Linux | 🟡 继承上游能力 | 社区版尚未完成完整实机回归 |
| macOS / iOS | 🟡 继承上游能力 | 社区版尚未完成完整实机回归 |

## 使用方式

### 连接 Songloft 服务端

标准客户端需要连接 Songloft 后端服务。首次启动时填写服务端地址、用户名和密码即可。

默认服务地址：

```text
http://localhost:58091
```

默认账号：

```text
admin / admin
```

服务端项目： [songloft-org/songloft](https://github.com/songloft-org/songloft)

### Bundle 本地模式

桌面端可将 Go 后端与 Flutter 客户端一起打包，启动后由客户端自动拉起本地服务，不需要额外部署服务器。

```bash
flutter build windows --release --dart-define=HAS_BACKEND=true
```

Web 不支持 Bundle 模式。

## 开发环境

- Flutter 3.41.5
- Dart 3.x
- Riverpod
- GoRouter
- Dio
- just_audio / audio_service
- SharedPreferences / FlutterSecureStorage

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/NeoHeee/songloft-player.git
cd songloft-player

# 安装依赖
flutter pub get

# 运行
flutter run
```

### Android 构建

```bash
flutter build apk --release --split-per-abi
```

生成文件位于：

```text
build/app/outputs/flutter-apk/
```

常见版本：

- `app-arm64-v8a-release.apk`：大多数新款 Android 手机和电视盒子
- `app-armeabi-v7a-release.apk`：较老的 32 位 ARM 设备
- `app-x86_64-release.apk`：Android 模拟器

### Windows 构建

```bash
flutter build windows --release
```

### Web 构建

```bash
flutter build web --release --base-href /
```

## 项目结构

```text
lib/
├── config/                 # 应用配置
├── core/
│   ├── audio/              # 音频播放
│   ├── backend/            # 内置后端与运行模式
│   ├── env/                # TV 等环境检测
│   ├── network/            # 网络与服务器连接
│   ├── router/             # GoRouter 路由
│   ├── storage/            # 本地存储
│   └── theme/              # 主题、主题包和在线目录
├── features/
│   ├── auth/               # 登录与认证
│   ├── home/               # 首页与 TV 首页
│   ├── jsplugin/           # 插件系统
│   ├── library/            # 歌曲库
│   ├── player/             # 播放器、歌词和队列
│   ├── playlist/           # 歌单管理
│   └── settings/           # 设置与主题管理
└── shared/                 # 通用布局、模型和组件
```

## 主题包安全规则

主题包采用声明式 JSON，不具备代码执行能力：

- 单个主题包最大 128 KB
- 最多安装 32 个自定义主题
- 颜色仅接受 `#RRGGBB` 或 `#AARRGGBB`
- 圆角参数限制在 0–40
- 在线主题必须来自受信任仓库
- 下载文件必须通过 SHA-256 校验
- 在线主题不能覆盖内置主题 ID

完整规范见 [docs/theme-packs.md](docs/theme-packs.md)。

## 当前改造方向

- 继续完善 Android TV 全页面遥控器焦点
- 优化手机、平板和桌面端视觉细节
- 增加更多社区主题与主题签名机制
- 完善正式 Release 自动发布流程
- 持续跟进上游 Songloft 接口和插件能力

## 上游项目

- Songloft 服务端：[songloft-org/songloft](https://github.com/songloft-org/songloft)
- Songloft 官方客户端：[songloft-org/songloft-player](https://github.com/songloft-org/songloft-player)

感谢原项目作者及所有开源贡献者。本仓库的界面重构与社区扩展建立在他们的工作基础上。

## 许可证

本项目沿用 [Apache-2.0 License](LICENSE)。

Windows / Linux 音频后端涉及的第三方组件及 LGPL 合规说明请参见 [NOTICE](NOTICE)。
