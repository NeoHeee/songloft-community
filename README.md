# Songloft Community

<p align="center">
  <strong>🎵 面向 Android 手机、Windows、Web 与 Android TV 深度优化的 Songloft 社区增强版客户端</strong>
</p>

<p align="center">
  <a href="https://github.com/NeoHeee/songloft-community/releases/latest"><img src="https://img.shields.io/github/v/release/NeoHeee/songloft-community?include_prereleases&label=release" alt="Release"></a>
  <a href="https://github.com/NeoHeee/songloft-community/actions"><img src="https://img.shields.io/github/actions/workflow/status/NeoHeee/songloft-community/ui-redesign-check.yml?branch=main&label=build" alt="Build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/NeoHeee/songloft-community" alt="License"></a>
  <a href="https://github.com/NeoHeee/songloft-community"><img src="https://img.shields.io/github/stars/NeoHeee/songloft-community" alt="Stars"></a>
  <img src="https://img.shields.io/badge/Flutter-3.41.5-02569B?logo=flutter" alt="Flutter">
</p>

<img width="1536" height="1024" alt="ae63b573-3fde-444e-9873-108dd3e17b1f" src="https://github.com/user-attachments/assets/3cff0c1d-06c0-4b8b-91d5-44fc2fe25f94" />

## 项目定位

Songloft Community 是基于 [Songloft](https://github.com/songloft-org/songloft) 服务端与官方 Flutter 客户端持续改造的 **非官方社区增强版本**。

本项目保留原有服务端接口、认证方式、播放器能力和 JavaScript 插件协议，重点重做了跨端 UI、手机端交互、导航状态、网络恢复、歌单管理、主题系统、TV 遥控器体验以及 Android 正式发布流程。

它不是简单换肤，而是一套围绕真实日常使用场景持续收口的客户端分支：

- 手机端优先解决操作连续性、返回逻辑、列表效率和播放器手势；
- Windows 与 Web 保持完整构建验证；
- Android TV / Google TV 补齐遥控器焦点、队列、搜索和辅助登录；
- 正式 Android 包使用固定签名，可持续覆盖升级。

> 本仓库由社区独立维护，并非 Songloft 官方发行版。原项目及相关版权归原作者和贡献者所有。

## 获取正式版本

当前正式版本：**Songloft Community v1.0.0-community.2**

- [前往 Releases 下载](https://github.com/NeoHeee/songloft-community/releases/latest)
- Android 手机优先下载 `arm64-v8a` APK
- 三架构压缩包同时包含 ARM64、ARMv7 与 x86_64 APK
- Release 附带 `SHA256SUMS.txt` 和安装说明

正式 Android APK 使用长期固定证书签名。安装过正式固定签名版后，后续版本可以直接覆盖升级；此前使用临时调试签名的安装包，需要先卸载一次。

## 相比上游的重点改进

| 方向 | Songloft Community 的改进 |
|---|---|
| 响应式 UI | 使用 Material 3 统一首页、歌曲库、歌单、播放器、设置与插件页面；手机、桌面和 TV 使用针对性的导航与内容布局 |
| 标签页现场保留 | 首页、歌曲库、歌单、插件和设置采用独立导航栈，切换栏目时保留滚动位置、搜索、筛选、排序、视图模式和已打开页面 |
| 手机歌曲库 | 顶部区域随滚动收缩，搜索和筛选吸顶；播放全部保留为主操作，排序、添加歌曲、电台、隐藏歌曲和清理集中到操作面板 |
| 手机交互闭环 | 多选连续滑动勾选、删除短时撤销、统一骨架屏、下拉刷新、错误重试、至少 48px 触控区域和触觉反馈 |
| 播放器连续性 | 迷你播放器滑动切歌、长按打开队列；全屏封面上滑打开队列、双击收藏、长按歌曲菜单；设置和插件页面保留紧凑播放器 |
| 返回逻辑 | 键盘、弹层、队列和页面内部模式优先关闭；详情页返回所属页面；非首页一级栏目统一返回首页；首页二次返回退出 |
| 网络与服务器 | 多服务器配置、登录页局域网自动搜索、Android 16 局域网访问兼容、私有 CA 支持、地址自动规范化、断线自动重连与全局重试提示 |
| 插件体验 | 首页快捷入口可配置，插件图标与卡片样式统一，动态插件标签保活，手机端超出导航容量的入口自动收进“更多” |
| 主题系统 | 支持本地主题包、浅色/深色双配色、在线主题目录、安装前预览、更新识别、安全来源限制与 SHA-256 校验 |
| TV 端 | 遥控器焦点布局、播放器和队列快捷操作、歌曲库搜索、设置页导航、多服务器选择以及手机扫码辅助输入登录 |
| 发布工程 | Android 三架构构建、固定 JKS 签名、证书指纹校验、APK SHA-256、Windows/Web/Android 全平台 CI 验证 |

## 手机端体验

### 独立导航栈与页面现场

主界面基于 `StatefulShellRoute.indexedStack`：

- 歌曲库滚动到很后面，切到歌单再回来，仍停留在原位置；
- 搜索关键词、类型筛选、排序方式和歌单视图模式不会因切换标签而丢失；
- 歌单详情、设置子页面和插件 WebView 可以恢复上次页面栈；
- 再次点击当前栏目入口，可返回该栏目的根页面。

### 统一返回规则

Android 手机端按以下优先级处理系统返回键：

1. 键盘已打开时先收起键盘；
2. 弹窗、底部面板、播放队列或插件网页历史优先关闭或后退；
3. 多选、排序等页面内部模式优先退出，不离开页面；
4. 歌单详情和设置子页面返回所属父页面；
5. 歌曲库、歌单、设置和插件一级页面统一返回首页；
6. 首页在两秒内再次按返回键才退出应用。

首次启动后直接进入设置、歌曲库或歌单，也不会再因为没有历史栈而直接退出到桌面。

### 歌曲库与批量操作

- 统一滚动容器与浮动 AppBar；
- 介绍区自然收起，搜索、筛选与播放全部保持可用；
- 搜索、类型筛选、排序、分页加载和下拉刷新；
- 多选状态保留封面并显示明确选中标记；
- 支持连续滑动勾选、全选、批量加入歌单和批量删除；
- 单曲与批量删除均提供短时间撤销；
- 加载、空状态、错误和重试反馈统一。

### 播放器与队列

- 迷你播放器左右滑动切歌；
- 长按迷你播放器打开播放队列；
- 播放失败时直接显示重试入口；
- 全屏播放器封面上滑打开队列；
- 双击封面收藏或取消收藏当前歌曲；
- 长按封面打开当前歌曲操作菜单；
- 队列自动定位当前歌曲，支持排序、移除、清空和删除撤销；
- 系统开启“减少动画”后，路由与播放器动画会自动简化。

## 网络连接与服务器发现

### 多服务器管理

客户端支持保存和切换多个 Songloft 服务端，并记住对应登录信息。服务器地址会自动清理常见误填内容，例如末尾重复填写的 `/api/v1`。

### 局域网自动搜索

原生客户端可在登录页自动搜索当前局域网中的 Songloft 服务：

- 自动识别当前私有 IPv4 网段；
- 默认扫描 Songloft 标准端口 `58091`；
- 同时复用已保存服务器中的自定义端口；
- 通过 `/api/v1/health` 验证目标；
- 显示扫描进度、发现数量和响应延迟；
- 支持随时停止，并可一键将结果填入服务器列表。

Web 端受浏览器安全限制，不执行局域网扫描，仍可手动输入服务器地址。

### 断线恢复

- 对连接失败、超时、网关错误和证书错误进行统一分类；
- 断线后按退避间隔自动探测服务端；
- 全局显示“无法连接”“正在重新连接”和“连接已恢复”；
- 提供“立即重试”入口；
- 恢复后自动刷新歌曲库和歌单数据；
- 正常的 401、404 等 HTTP 响应不会被误判为服务器断线。

## 插件与主题

### JavaScript 插件

继续兼容上游 JavaScript 插件协议和插件 WebView：

- 首页插件快捷入口可显示或隐藏；
- 隐藏快捷入口不会停用或卸载插件；
- 可选择将插件放入主导航；
- 手机端导航超过五项时，其余入口自动进入“更多”；
- 已访问插件页面保持自己的 WebView 与页面状态。

### 自定义主题包

支持导入 `.songloft-theme` 或 JSON 主题文件：

- 浅色与深色配色共同打包；
- 可配置主色、背景、面板、辅助色、播放器渐变和圆角；
- 支持导入前预览、覆盖更新、导出和删除；
- 自定义主题保存在本地，重启后继续生效。

在线主题目录支持搜索、安装状态识别和更新检测。远程目录不可用时会回退到安装包内置安全快照。

主题包采用声明式 JSON，不执行 JavaScript、CSS、HTML 或其他代码。在线主题仅允许受信任的 HTTPS 来源，并在安装前校验 SHA-256 与主题身份信息。

完整规范见：[主题包制作与安全规则](docs/theme-packs.md)。

## Android TV / Google TV

TV 端围绕“仅使用遥控器完成核心操作”持续优化：

- TV 专用首页、大屏导航和焦点样式；
- 歌单卡片、歌曲列表和设置分类支持方向键与确认键；
- 播放器支持媒体键、上一首、下一首和音量键；
- 播放队列自动定位当前歌曲，并提供遥控器操作菜单；
- 歌曲库搜索可调用系统键盘并恢复焦点；
- 多服务器选择、手动输入地址和已保存账号回填；
- 手机扫码或输入配对码，替代遥控器输入服务器、用户名和密码。

TV 主流程已经可用，少数复杂设置和第三方插件页面仍会继续优化。

## 无障碍与系统适配

- 跟随系统字号缩放，并为极端字号提供安全边界；
- 手机端主要触控区域不小于 48×48 逻辑像素；
- 支持系统“减少动画”偏好；
- 列表选择状态、队列拖动和连接状态提供读屏语义；
- Android 手机启用边到边显示，并适配状态栏和导航栏明暗主题；
- 封面缓存统一处理 URL、磁盘尺寸与内存解码，减少重复下载和列表闪烁。

## 平台状态

| 平台 | 状态 | 说明 |
|---|---|---|
| Android 手机 | ✅ 重点支持 | 推荐使用固定签名的 ARM64 APK |
| Windows x64 | ✅ 持续构建验证 | 支持普通客户端和内置 Go 后端 Bundle 模式 |
| Web | ✅ 持续构建验证 | 支持 standalone 与 embedded 模式 |
| Android TV / Google TV | 🟢 主流程可用 | 已完成遥控器浏览、播放、搜索、队列和辅助登录 |
| Linux | 🟡 继承上游能力 | 社区版尚未完成完整实机回归 |
| macOS / iOS | 🟡 继承上游能力 | 社区版尚未完成完整实机回归 |

## 使用方式

### 连接现有 Songloft 服务端

Android、TV 和普通桌面客户端需要连接 Songloft 后端。首次启动时可自动搜索局域网服务器，也可以手动填写服务器地址、用户名和密码。

常见默认地址：

```text
http://localhost:58091
```

服务端项目：[songloft-org/songloft](https://github.com/songloft-org/songloft)

### Windows Bundle 本地模式

Windows 可将 Go 后端与 Flutter 客户端打包在一起，启动后由客户端自动拉起本地服务，无需单独部署服务器：

```bash
flutter build windows --release --dart-define=HAS_BACKEND=true
```

Web 不支持 Bundle 本地模式。

## 开发与构建

### 环境

- Flutter 3.41.5
- Dart 3.x
- Riverpod
- GoRouter
- Dio
- just_audio / audio_service
- SharedPreferences / FlutterSecureStorage

### 快速开始

```bash
git clone https://github.com/NeoHeee/songloft-community.git
cd songloft-community
flutter pub get
flutter run
```

### Android

```bash
flutter build apk --release --split-per-abi
```

生成目录：

```text
build/app/outputs/flutter-apk/
```

架构说明：

- `app-arm64-v8a-release.apk`：大多数新款 Android 手机和电视设备；
- `app-armeabi-v7a-release.apk`：较老的 32 位 ARM 设备；
- `app-x86_64-release.apk`：Android 模拟器或 x86_64 设备。

### Windows

```bash
flutter build windows --release
```

### Web

```bash
flutter build web --release --base-href /
```

## 自动化验证与正式签名

主分支变更会运行完整 CI：

- Dart 格式检查；
- 主题、网络恢复、导航、封面缓存、歌曲库和播放器专项测试；
- `flutter analyze`；
- Android 三架构 Release APK；
- Flutter Web Release；
- Windows x64 Bundle。

正式 Android 工作流会额外执行：

- 从 GitHub Actions Secrets 恢复固定 JKS；
- 校验 Keystore、别名和密码；
- 对三个 APK 执行证书 SHA-256 验证；
- 生成 APK SHA-256、证书报告和构建产物。

## 项目结构

```text
lib/
├── config/                 # 品牌与应用配置
├── core/
│   ├── audio/              # 音频服务与系统媒体控制
│   ├── backend/            # 内置后端与运行模式
│   ├── env/                # TV 与平台环境检测
│   ├── navigation/         # 手机返回策略
│   ├── network/            # API、多服务器、发现与重连
│   ├── router/             # StatefulShellRoute 路由
│   ├── storage/            # 本地状态与安全存储
│   └── theme/              # 主题、主题包与在线目录
├── features/
│   ├── auth/               # 登录、服务器选择与局域网发现
│   ├── home/               # 首页、插件入口与 TV 首页
│   ├── jsplugin/           # JavaScript 插件系统
│   ├── library/            # 歌曲库与批量操作
│   ├── player/             # 播放器、歌词、队列与手势
│   ├── playlist/           # 歌单管理
│   └── settings/           # 设置、主题与数据管理
└── shared/                 # 通用布局、组件、模型与工具
```

## 后续方向

- 继续完善 TV 端复杂设置页和第三方插件焦点；
- 增加更多社区主题及主题签名机制；
- 优化手机、平板和桌面端细节一致性；
- 持续跟进上游 Songloft 接口和插件能力；
- 完善 Windows、Web 与 Android 的统一正式发布流程。

## 上游项目

- Songloft 服务端：[songloft-org/songloft](https://github.com/songloft-org/songloft)
- Songloft 官方客户端：[songloft-org/songloft-player](https://github.com/songloft-org/songloft-player)

感谢原项目作者和所有开源贡献者。Songloft Community 的界面重构、移动端优化和社区扩展均建立在他们的工作基础上。

## 许可证

本项目沿用 [Apache-2.0 License](LICENSE)。

Windows / Linux 音频后端涉及的第三方组件及 LGPL 合规说明请参见 [NOTICE](NOTICE)。
