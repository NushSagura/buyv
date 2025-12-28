plugins {
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.0" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Force all subprojects to use compileSdk 36
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(36)
            }
        }
    }
}
subprojects {
    val subProject = this
    val applyNamespace = {
        val android = subProject.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && (android.namespace == null || android.namespace == "")) {
            // Try to find AndroidManifest.xml in standard locations
            val possibleManifestPaths = listOf(
                subProject.file("src/main/AndroidManifest.xml"),
                subProject.file("src/androidMain/AndroidManifest.xml"),
                subProject.file("AndroidManifest.xml")
            )
            
            var manifestFile: java.io.File? = null
            for (path in possibleManifestPaths) {
                if (path.exists()) {
                    manifestFile = path
                    break
                }
            }
            
            if (manifestFile != null && manifestFile.exists()) {
                try {
                    val manifest = groovy.xml.XmlParser().parse(manifestFile)
                    val packageName = manifest.attribute("package")?.toString()
                    if (packageName != null && packageName.isNotEmpty()) {
                        android.namespace = packageName
                    }
                } catch (e: Exception) {
                    // If parsing fails, try to read package from manifest as text
                    try {
                        val manifestContent = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestContent)
                        packageMatch?.groupValues?.get(1)?.let { packageName ->
                            if (packageName.isNotEmpty()) {
                                android.namespace = packageName
                            }
                        }
                    } catch (e2: Exception) {
                        // If all else fails and it's cached_video_player, use the correct namespace
                        if (subProject.name == "cached_video_player") {
                            android.namespace = "com.lazyarts.vikram.cached_video_player"
                        }
                    }
                }
            } else {
                // Special handling for cached_video_player if manifest not found
                if (subProject.name == "cached_video_player") {
                    android.namespace = "com.lazyarts.vikram.cached_video_player"
                }
            }
        }
    }

    if (subProject.state.executed) {
        applyNamespace()
    } else {
        subProject.afterEvaluate {
            applyNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
        options.isWarnings = false
        options.isFailOnError = false
    }
}