buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    // Inject properties to satisfy plugin requirements
    project.extensions.extraProperties.set("flutter.compileSdkVersion", 36)
    project.extensions.extraProperties.set("flutter.minSdkVersion", 21)
    project.extensions.extraProperties.set("flutter.targetSdkVersion", 36)
    project.extensions.extraProperties.set("flutter.ndkVersion", "28.2.13676358")

    configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")
            force("androidx.core:core:1.15.0")
            force("androidx.core:core-ktx:1.15.0")
            force("androidx.activity:activity:1.9.3")
            force("androidx.activity:activity-ktx:1.9.3")
            force("androidx.lifecycle:lifecycle-common:2.8.7")
            force("androidx.lifecycle:lifecycle-runtime:2.8.7")
            force("androidx.lifecycle:lifecycle-viewmodel:2.8.7")
        }
    }

    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                // Force compileSdk 36 for all android subprojects
                val setCompileSdk = android.javaClass.methods.find { it.name == "setCompileSdk" && it.parameterCount == 1 }
                setCompileSdk?.invoke(android, 36)

                // Ensure a namespace exists (required by AGP 8+)
                val getNamespace = android.javaClass.methods.find { it.name == "getNamespace" && it.parameterCount == 0 }
                if (getNamespace?.invoke(android) == null) {
                    val setNamespace = android.javaClass.methods.find { it.name == "setNamespace" && it.parameterCount == 1 }
                    setNamespace?.invoke(android, "com.universalnotes.${project.name.replace(":", ".").replace("-", ".")}")
                }
            } catch (e: Exception) {
                // Ignore if reflection fails
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
