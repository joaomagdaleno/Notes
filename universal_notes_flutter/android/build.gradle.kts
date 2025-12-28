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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
