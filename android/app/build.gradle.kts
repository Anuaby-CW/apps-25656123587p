import java.io.File

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningKeys = listOf(
    "TALAGA_RELEASE_STORE_FILE",
    "TALAGA_RELEASE_STORE_PASSWORD",
    "TALAGA_RELEASE_KEY_ALIAS",
    "TALAGA_RELEASE_KEY_PASSWORD",
)
val releaseSigningValues = releaseSigningKeys.associateWith { name ->
    providers.gradleProperty(name)
        .orElse(providers.environmentVariable(name))
        .orNull
}
val missingReleaseSigningKeys = releaseSigningValues
    .filterValues { it.isNullOrBlank() }
    .keys
val releaseBuildRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true)
}

if (releaseBuildRequested && missingReleaseSigningKeys.isNotEmpty()) {
    throw GradleException(
        "Release signing is incomplete. Configure: " +
            missingReleaseSigningKeys.sorted().joinToString(", "),
    )
}

android {
    namespace = "com.talagacoffee.pos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.talagacoffee.pos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val releaseSigningConfig = if (missingReleaseSigningKeys.isEmpty()) {
        val configuredKeystoreFile = File(
            requireNotNull(releaseSigningValues["TALAGA_RELEASE_STORE_FILE"]),
        )
        if (!configuredKeystoreFile.isAbsolute) {
            throw GradleException(
                "TALAGA_RELEASE_STORE_FILE must be an absolute path outside the repository.",
            )
        }
        val keystoreFile = configuredKeystoreFile.canonicalFile
        val repositoryRoot = rootDir.parentFile.canonicalFile
        if (keystoreFile.toPath().startsWith(repositoryRoot.toPath())) {
            throw GradleException(
                "TALAGA_RELEASE_STORE_FILE must be outside the repository.",
            )
        }
        if (releaseBuildRequested && !keystoreFile.isFile) {
            throw GradleException(
                "TALAGA_RELEASE_STORE_FILE does not point to an existing file.",
            )
        }

        signingConfigs.create("release") {
            storeFile = keystoreFile
            storePassword =
                releaseSigningValues["TALAGA_RELEASE_STORE_PASSWORD"]
            keyAlias = releaseSigningValues["TALAGA_RELEASE_KEY_ALIAS"]
            keyPassword = releaseSigningValues["TALAGA_RELEASE_KEY_PASSWORD"]
        }
    } else {
        null
    }

    buildTypes {
        release {
            releaseSigningConfig?.let { signingConfig = it }
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
