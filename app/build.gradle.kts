plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.compose")
}

android {
    namespace = "com.lightmind.webviewapp"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.lightmind.webviewapp"
        minSdk = 26
        targetSdk = 36
        versionCode = 2
        versionName = "1.1"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.webkit:webkit:1.11.0")
    implementation("io.github.kyant0:backdrop:2.0.0")

    // Compose Multiplatform 依赖（由 CMP 插件解析到对应的 AndroidX Compose 制品）
    implementation(compose.foundation)
    implementation(compose.material3)
    debugImplementation(compose.uiTooling)
}
