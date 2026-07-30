plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quiz_apps"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.example.quiz_apps"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // নাল সেফটি সমস্যা সমাধানের জন্য সেফ কল ব্যবহার করা হয়েছে
        versionCode = flutter.flutterVersionCode?.toInt() ?: 1
        versionName = flutter.flutterVersionName ?: "1.0"

        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
