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
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            try {
                // Enforce Java 17 for compileOptions
                val compileOptions = android!!.javaClass.getMethod("getCompileOptions").invoke(android)
                compileOptions!!.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
                compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)

                // Enforce Java 17 for kotlinOptions
                val kotlinOptions = android.javaClass.getMethod("getKotlinOptions").invoke(android)
                kotlinOptions!!.javaClass.getMethod("setJvmTarget", String::class.java).invoke(kotlinOptions, "17")

                // Definitive Namespace Fix: Inject namespace if missing
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val currentNamespace = getNamespace.invoke(android)
                    if (currentNamespace == null) {
                        val namespace = "com.universal_notes.${project.name.replace("-", "_").replace(".", "_")}"
                        setNamespace.invoke(android, namespace)
                    }
                } catch (e: Exception) {
                    // Fallback for newer AGP where namespace might be a property or different
                    try {
                        val extension = android as? com.android.build.api.variant.AndroidComponentsExtension<*, *, *>
                        // If it's the newer API, we might need a different approach, 
                        // but for plugins failing with "Namespace not specified", it's usually the legacy extension.
                    } catch (ignore: Exception) {}
                }
            } catch (e: Exception) {
                // Ignore errors related to reflection or missing methods
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
