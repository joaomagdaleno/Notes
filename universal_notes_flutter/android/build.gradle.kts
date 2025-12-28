buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
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
    project.extensions.extraProperties.set("flutter.compileSdkVersion", 35)
    project.extensions.extraProperties.set("flutter.minSdkVersion", 21)
    project.extensions.extraProperties.set("flutter.targetSdkVersion", 35)
    project.extensions.extraProperties.set("flutter.ndkVersion", "28.2.13676358")

    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                // Set compileSdk using reflection to avoid classpath issues
                val compileSdkMethod = android.javaClass.methods.find { it.name == "setCompileSdk" && it.parameterCount == 1 }
                compileSdkMethod?.invoke(android, 35)
                
                // Set namespace if null
                val getNamespace = android.javaClass.methods.find { it.name == "getNamespace" && it.parameterCount == 0 }
                val currentNamespace = getNamespace?.invoke(android)
                if (currentNamespace == null) {
                    val setNamespace = android.javaClass.methods.find { it.name == "setNamespace" && it.parameterCount == 1 }
                    setNamespace?.invoke(android, "com.fix.${project.name.replace(":", ".").replace("-", ".")}")
                }
            } catch (e: Exception) {
                // Ignore failures for non-Android or unusual structures
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
