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
// Compatibility shim for legacy Flutter plugins that predate AGP 8, such as
// on_audio_query_android 1.1.0 (latest release, unmaintained): its Groovy
// build file declares no `namespace` (only the manifest `package`), no Java/
// Kotlin JVM target and compileSdk 33. AGP 8 refuses to configure a library
// without a namespace, and Kotlin 2.x fails on mismatched Java/Kotlin JVM
// targets. Only Android library subprojects without their own namespace are
// touched; well-formed plugins are left exactly as they declare themselves.
// Registered before `evaluationDependsOn(":app")` below and run in
// afterEvaluate (ahead of AGP's own hook), while the DSL is still mutable.
subprojects {
    val patchLegacyAndroidLibrary: Project.() -> Unit = {
        val android = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android != null && android.namespace == null) {
            val manifest = file("src/main/AndroidManifest.xml")
            val manifestPackage = manifest.takeIf { it.isFile }?.let {
                Regex("""package\s*=\s*"([^"]+)"""").find(it.readText())?.groupValues?.get(1)
            }
            android.namespace = manifestPackage ?: group.toString()

            val appCompileSdk = rootProject.project(":app").extensions
                .getByType(com.android.build.api.dsl.ApplicationExtension::class.java).compileSdk
            if (appCompileSdk != null && (android.compileSdk ?: 0) < appCompileSdk) {
                android.compileSdk = appCompileSdk
            }

            android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
    if (state.executed) patchLegacyAndroidLibrary() else afterEvaluate { patchLegacyAndroidLibrary() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
