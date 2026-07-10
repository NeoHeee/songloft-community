# Songloft 自定义主题包规范

Songloft 主题包使用声明式 JSON，不允许脚本、CSS、远程链接或可执行代码。建议文件扩展名使用 `.songloft-theme`，也可直接导入 `.json` 文件。

## 设计目标

- 同一份主题包可用于 Web、Android、Windows、Linux、macOS 和 iOS。
- 主题包同时提供浅色与深色配置，用户仍可独立选择“浅色 / 深色 / 跟随系统”。
- 主题包只负责视觉变量，不改变播放、插件、网络和数据逻辑。
- 导入前执行字段、颜色、圆角与大小校验。

## 限制

- 当前规范版本：`schemaVersion: 1`
- 单个主题包最大：128 KB
- 最多安装：32 个自定义主题包
- `id` 长度：3-64 个字符
- `id` 仅允许：小写字母、数字、点、下划线、短横线
- 颜色格式：`#RRGGBB` 或 `#AARRGGBB`
- 圆角范围：0-40
- `light` 与 `dark` 必须同时存在
- 自定义主题不能使用内置主题的 `id`

## 完整示例

```json
{
  "schemaVersion": 1,
  "id": "my-theme-pack",
  "name": "我的主题",
  "version": "1.0.0",
  "author": "作者名称",
  "description": "主题简介",
  "light": {
    "seed": "#7C5CFF",
    "background": "#F4F5FA",
    "surface": "#FFFFFF",
    "secondary": "#4C7DFF",
    "tertiary": "#B45CFF",
    "playerGradient": ["#7C5CFF", "#4C7DFF"],
    "cardRadius": 22,
    "controlRadius": 15,
    "navigationRadius": 16
  },
  "dark": {
    "seed": "#9C87FF",
    "background": "#0B0D12",
    "surface": "#151821",
    "secondary": "#6E9BFF",
    "tertiary": "#D18AFF",
    "playerGradient": ["#8B6CFF", "#426FE8"],
    "cardRadius": 22,
    "controlRadius": 15,
    "navigationRadius": 16
  }
}
```

## 字段说明

### 顶层字段

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `schemaVersion` | 是 | 当前固定为 `1` |
| `id` | 是 | 主题唯一标识；同一 `id` 再次导入会覆盖更新 |
| `name` | 是 | 主题显示名称，最多 48 个字符 |
| `version` | 是 | 主题版本号，最多 24 个字符 |
| `author` | 是 | 作者名称，最多 48 个字符 |
| `description` | 否 | 主题简介，最多 160 个字符 |
| `light` | 是 | 浅色主题配置 |
| `dark` | 是 | 深色主题配置 |

### 配色字段

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `seed` | 是 | Material 3 主种子色 |
| `background` | 是 | 页面背景色 |
| `surface` | 是 | 卡片、侧栏、弹窗等面板色 |
| `secondary` | 否 | 次强调色；省略时由 `seed` 自动生成 |
| `tertiary` | 否 | 第三强调色；省略时由 `seed` 自动生成 |
| `playerGradient` | 否 | 两个颜色组成的渐变；用于品牌标识和播放器视觉 |
| `cardRadius` | 否 | 卡片与弹窗圆角，默认 22 |
| `controlRadius` | 否 | 输入框与按钮圆角，默认 15 |
| `navigationRadius` | 否 | 底栏、侧栏选中块圆角，默认 16 |

## 制作步骤

1. 复制应用“设置 → 外观设置 → 主题包 → 制作规范”中的模板，或复制本目录示例。
2. 修改 `id`、名称、作者和配色。
3. 保存为 UTF-8 编码文本文件。
4. 将扩展名改为 `.songloft-theme`。
5. 在 Songloft 中点击“导入主题包”。
6. 导入成功后主题会立即启用；同一 `id` 再次导入会更新原主题。

## 安全规则

主题包不会解析或执行以下内容：

- JavaScript、Dart 或其他脚本
- CSS
- HTML
- 网络请求地址
- 本地文件路径
- 动态字体和可执行插件

后续规范版本可增加打包图片资源，但必须继续采用白名单字段、大小限制和路径校验。
