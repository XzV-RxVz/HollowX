plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.Hollow.Execution"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.Hollow.Execution"

        minSdk = flutter.minSdkVersion
        targetSdk = 37

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ===== TAMBAHKAN INI =====
        multiDexEnabled = true

        ndk {
            abiFilters += listOf(
                "armeabi-v7a",
                "arm64-v8a"
            )
        }
    }

    // ===== TAMBAHKAN BLOK INI =====
    dexOptions {
        javaMaxHeapSize = "4g"
        preDexLibraries = false
        maxProcessCount = 4
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))
    implementation("com.google.firebase:firebase-messaging")

    // ===== TAMBAHKAN INI =====
    implementation("androidx.multidex:multidex:2.0.1")

    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.5"
    )
}