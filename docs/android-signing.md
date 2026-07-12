# Android 固定签名

Songloft Community 的正式 Android APK 使用长期固定签名，包名保持：

```text
com.neo.songloft.community
```

正式签名证书 SHA-256：

```text
CA:A0:0F:91:D7:3B:12:AD:E2:5E:8A:43:20:18:1E:B5:20:A6:65:49:FD:08:9A:56:E4:69:4A:19:13:E9:68:F1
```

## GitHub Actions Secrets

仓库需要配置以下四个 Actions Secret：

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

其中 `ANDROID_KEYSTORE_BASE64` 是 JKS 文件的单行 Base64 内容。不要将 JKS、密码或 Base64 内容提交到 Git 仓库。

## 构建流程

`.github/workflows/android-signed-release.yml` 会在 `main` 的 Android、Dart、资源或版本文件变化时运行，也可以手动触发。工作流将：

1. 从 GitHub Secrets 恢复临时 JKS；
2. 强制 Gradle 使用 Release 签名，禁止回退到调试证书；
3. 构建 ARM64、ARMv7 和 x86_64 APK；
4. 使用 `apksigner` 校验证书 SHA-256；
5. 输出 APK、`SHA256SUMS.txt` 和 `SIGNING-CERTIFICATE.txt`。

正式产物名称：

```text
Songloft-Community-Android-fixed-signed
```

## 密钥保管

长期签名密钥丢失后，无法再为已安装用户提供覆盖升级。至少保存两份加密离线备份，并将备份密码与文件分开保存。
