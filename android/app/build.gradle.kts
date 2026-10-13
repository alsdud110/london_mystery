import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing for the store (PROD). The upload key and its passwords live
// outside the repository: android/key.properties (git-ignored) names them:
//   storeFile=<path to the .jks>   storePassword=…   keyAlias=…   keyPassword=…
// Without it a PROD release build stops; it is never signed with the debug key.
val uploadKeyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasUploadKey = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !uploadKeyProperties.getProperty(it).isNullOrBlank() }

android {
    namespace = "com.londonmystery.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.londonmystery.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(uploadKeyProperties.getProperty("storeFile"))
                storePassword = uploadKeyProperties.getProperty("storePassword")
                keyAlias = uploadKeyProperties.getProperty("keyAlias")
                keyPassword = uploadKeyProperties.getProperty("keyPassword")
            }
        }
    }

    // DEV and PROD are separate apps with separate Firebase projects: each
    // flavor's google-services.json sits in src/<flavor>/ (git-ignored).
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev" // com.londonmystery.app.dev → london-mystery-dev
            manifestPlaceholders["appLabel"] = "London Mystery DEV"
            // Internal builds only: a DEV release may use the debug key.
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prod") {
            dimension = "env" // com.londonmystery.app → london-mystery-prod
            manifestPlaceholders["appLabel"] = "London Mystery"
            if (hasUploadKey) signingConfig = signingConfigs.getByName("upload")
        }
    }

    buildTypes {
        release {
            // Signing comes from the flavor (DEV: debug key, PROD: upload key).
            signingConfig = null
        }
    }
}

// A checkout without the (git-ignored) Firebase config still builds: the game
// then runs guest-only, as the app finds no Firebase settings at start.
googleServices {
    missingGoogleServicesStrategy =
        com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy.WARN
}

// A PROD release without the upload key stops here instead of producing an
// unsigned or debug-signed build.
gradle.taskGraph.whenReady {
    val prodRelease = allTasks.any { it.project == project && it.name.contains("ProdRelease") }
    if (prodRelease && !hasUploadKey) {
        throw GradleException(
            "PROD release needs the upload key: create android/key.properties (see app/build.gradle.kts). " +
                "It is never signed with the debug key.",
        )
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
