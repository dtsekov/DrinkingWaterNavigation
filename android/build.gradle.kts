allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
buildscript {
    repositories {
        google() // Google's Maven repository
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.1.1")
        classpath("com.google.gms:google-services:4.3.10")
    }
}
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
