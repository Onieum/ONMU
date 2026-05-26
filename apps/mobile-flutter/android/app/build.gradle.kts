plugins {
    id("com.android.application")
    // Flutter Gradle Plugin은 Android/Kotlin Gradle plugin 뒤에 적용해야 합니다.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.onieum.onmu_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 추후 고유한 Application ID를 지정합니다. 참고: https://developer.android.com/studio/build/application-id.html
        applicationId = "io.onieum.onmu_mobile"
        // 아래 값은 앱 요구사항에 맞게 수정할 수 있습니다.
        // 자세한 내용은 https://flutter.dev/to/review-gradle-config 를 참고합니다.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 추후 release build용 signing config를 추가합니다.
            // 지금은 `flutter run --release`가 동작하도록 debug key로 signing합니다.
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
