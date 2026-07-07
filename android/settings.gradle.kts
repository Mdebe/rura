import java.util.Properties
import java.io.File
import java.io.FileInputStream

pluginManagement {
    val flutterSdkPath = run {
        val properties = Properties()
        val localPropertiesFile = File("local.properties")
        if (localPropertiesFile.exists()) {
            FileInputStream(localPropertiesFile).use { stream ->
                properties.load(stream)
            }
        }
        val path = properties.getProperty("flutter.sdk")
        requireNotNull(path) { "flutter.sdk not set in local.properties" }
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
    id("com.android.application") version "8.6.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")