import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "ly.courto.user"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "30.0.15729638"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }


    defaultConfig {
        applicationId = "ly.courto.user"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true

        manifestPlaceholders["mapsApiKey"] = keystoreProperties["mapsApiKey"] as? String ?: ""

            ndk {
        abiFilters += listOf("arm64-v8a", "armeabi-v7a")
    }
    }


    // The NUMO/PaySky SDK ships prebuilt card.io + OpenCV .so files. Their
    // x86_64 builds have 4KB-aligned LOAD segments, which fails Google Play's
    // 16KB memory page size requirement. arm64-v8a is clean (64KB aligned), so
    // the fix is to drop the x86 ABIs entirely.
    //
    // --target-platform only controls the Flutter engine libs, not the .so
    // files bundled inside dependency AARs, which is why the CLI flag alone
    // left x86_64 in the bundle. Removing this block puts the error back.
    packaging {
        jniLibs {
            excludes += listOf("lib/x86_64/**", "lib/x86/**")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }


        buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    

}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_11
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.github.payskyCompany:NUMO-PayButton-SDK-android:1.0.12")
}


flutter {
    source = "../.."
}

