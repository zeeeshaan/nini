pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
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
    id("com.android.application") version "9.1.0" apply false
    // Supply a compiler newer than AGP's default; don't apply legacy KGP.
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

// rive_native 0.1.11 still applies legacy KGP. Use our Android build adapter
// while keeping the package's original source files and native runtime.
findProject(":rive_native")?.let { rive ->
    val packageInfo = rive.projectDir.parentFile.resolve("pubspec.yaml").readText()
    if (Regex("(?m)^version:\\s*0\\.1\\.11\\s*$").containsMatchIn(packageInfo)) {
        rive.buildFileName = file("gradle/rive_native.gradle").relativeTo(rive.projectDir).path
    }
}

// These releases already support built-in Kotlin. Flutter's source scanner
// incorrectly flags their conditional fallback for older Android builds.
mapOf(
    "emoji_picker_flutter" to "4.5.4",
    "photo_manager" to "3.12.0",
    "flutter_image_compress_common" to "1.1.1"
)
    .forEach { (name, version) ->
        findProject(":$name")?.let { plugin ->
            val packageInfo = plugin.projectDir.parentFile.resolve("pubspec.yaml").readText()
            if (Regex("(?m)^version:\\s*${Regex.escape(version)}\\s*$").containsMatchIn(packageInfo)) {
                plugin.buildFileName = file("gradle/built_in_kotlin_plugin.gradle")
                    .relativeTo(plugin.projectDir).path
            }
        }
    }
