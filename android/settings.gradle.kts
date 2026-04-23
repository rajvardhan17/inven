pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            properties.getProperty("flutter.sdk")
                ?: error("flutter.sdk not set")
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // ✅ ONLY declare versions (apply false)
    id("com.android.application") version "8.6.0" apply false
    id("com.android.library") version "8.6.0" apply false

    id("com.google.gms.google-services") version "4.4.2" apply false

    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

include(":app")