pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // 1. مرايا فلاتر الخاصة للشرق الأوسط والمناطق المحجوبة
        maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") }

        // 2. مرايا الأندرويد و Maven العامة
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }

        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        // 1. مستودع محرك فلاتر الرئيسي والمظلي (ضروري جداً لحل حزمة io.flutter)
        maven { url = uri("https://download.flutter.io") }
        maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") }

        // 2. مرايا التبعات العامة
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }

        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

gradle.beforeProject {
    buildscript.configurations.matching { it.name == "classpath" }.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                useVersion("8.11.1")
            }
        }
    }
}

include(":app")