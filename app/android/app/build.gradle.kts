plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.cristalins.assinatura"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.cristalins.assinatura"
        // Android 8.0 ou superior (Anexo).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavors: dev e hml instalam lado a lado com prod (applicationId com sufixo).
    // Rodar com: flutter run --flavor dev -t lib/main_dev.dart --dart-define=API_URL=http://10.0.2.2:3000
    flavorDimensions += "ambiente"
    productFlavors {
        create("dev") {
            dimension = "ambiente"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Cristalins Dev")
        }
        create("hml") {
            dimension = "ambiente"
            applicationIdSuffix = ".hml"
            resValue("string", "app_name", "Cristalins Hml")
        }
        create("prod") {
            dimension = "ambiente"
            resValue("string", "app_name", "Cristalins")
        }
    }

    buildTypes {
        release {
            // Assinatura de release fica para cr-8 (Play Store). Por ora, chaves de debug.
            signingConfig = signingConfigs.getByName("debug")
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
