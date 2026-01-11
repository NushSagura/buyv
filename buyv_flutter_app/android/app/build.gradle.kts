plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.buyv.flutter_app"
    compileSdk = 36
    buildToolsVersion = "35.0.0"
    // NDK version removed - let AGP auto-select compatible version
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
        applicationId = "com.buyv.flutter_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // ═══════════════════════════════════════════════════════════
            // 🚀 OPTIMISATIONS MAXIMALES POUR PRODUCTION
            // ═══════════════════════════════════════════════════════════
            
            // Active ProGuard/R8 pour réduction de taille et obfuscation
            isMinifyEnabled = true
            
            // Réduit la taille des ressources (images, layouts)
            isShrinkResources = true
            
            // Fichiers de règles ProGuard
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Désactive les logs en production
            buildConfigField("boolean", "DEBUG_MODE", "false")
        }
        
        debug {
            // Active les logs en debug
            buildConfigField("boolean", "DEBUG_MODE", "true")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Material Components for Stripe
    implementation("com.google.android.material:material:1.11.0")
    
    // Import the Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging-ktx")
    
    // Firebase Analytics (optionnel mais recommandé)
    implementation("com.google.firebase:firebase-analytics-ktx")
}

flutter {
    source = "../.."
}

tasks.configureEach {
    if (name == "compileFlutterBuildDebug") {
        doNotTrackState("Task uses Task.project at execution time")
    }
}