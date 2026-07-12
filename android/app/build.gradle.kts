import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 读取 key.properties（本地开发用，CI 中通过环境变量传入）
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val requireReleaseSigning =
    System.getenv("ANDROID_REQUIRE_RELEASE_SIGNING")?.equals("true", ignoreCase = true) == true

android {
    namespace = "com.neo.songloft.community"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 启用 core library desugaring，因为 minSdk 24 < 26，
        // 某些 Java 8+ API（如 java.time）需要 desugaring 支持
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            // 优先使用环境变量（CI），其次使用 key.properties（本地）
            val storeFilePath = System.getenv("ANDROID_KEYSTORE_PATH")
                ?: keystoreProperties.getProperty("storeFile")
            val storePass = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                ?: keystoreProperties.getProperty("storePassword")
            val releaseKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
                ?: keystoreProperties.getProperty("keyAlias")
            val releaseKeyPass = System.getenv("ANDROID_KEY_PASSWORD")
                ?: keystoreProperties.getProperty("keyPassword")

            val configuredValues = listOf(
                storeFilePath,
                storePass,
                releaseKeyAlias,
                releaseKeyPass,
            )
            val hasAnySigningValue = configuredValues.any { !it.isNullOrBlank() }
            val hasCompleteSigning = configuredValues.all { !it.isNullOrBlank() }

            if (hasAnySigningValue && !hasCompleteSigning) {
                throw GradleException(
                    "Android release signing is only partially configured. " +
                        "Provide the keystore path, store password, key alias and key password.",
                )
            }

            if (hasCompleteSigning) {
                storeFile = file(storeFilePath!!)
                storePassword = storePass
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPass
            }
        }
    }

    defaultConfig {
        applicationId = "com.neo.songloft.community"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // audio_session 依赖要求 API 24+，与 Flutter 默认值保持一致。
        // Android Automotive 建议 API 28+，但非强制
        @Suppress("PropertyName")
        val SONGLOFT_MIN_SDK = 24
        minSdk = SONGLOFT_MIN_SDK
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.getByName("release")
            signingConfig = when {
                releaseConfig.storeFile != null -> releaseConfig
                requireReleaseSigning -> throw GradleException(
                    "A fixed Android release signing key is required for this build.",
                )
                else -> signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // gomobile bind 生成的 Go 后端 .aar（本地模式使用）
    // 文件由 `make build-go-mobile-android` 生成到 libs/ 目录
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
}

flutter {
    source = "../.."
}
