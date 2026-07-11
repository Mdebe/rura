import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")

    // Firebase
    id("com.google.gms.google-services")

    // Flutter
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.ruralmap"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.ruralmap"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {

        create("release") {

            if (keystorePropertiesFile.exists()) {

                storeFile = file(
                    keystoreProperties["storeFile"] as String
                )

                storePassword =
                    keystoreProperties["storePassword"] as String

                keyAlias =
                    keystoreProperties["keyAlias"] as String

                keyPassword =
                    keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {

        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }

        getByName("release") {

            signingConfig = signingConfigs.getByName("release")

            isDebuggable = false

            isMinifyEnabled = false

            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}