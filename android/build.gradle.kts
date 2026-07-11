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

// file_picker hardcodes compileSdk 34; flutter_plugin_android_lifecycle AAR
// requires consumers to compile against API 36+. Override after each module configures.
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        try {
            // AGP 8+ property: compileSdk = 36
            val setCompileSdk =
                android.javaClass.methods.firstOrNull { method ->
                    method.name == "setCompileSdk" &&
                        method.parameterCount == 1 &&
                        (method.parameterTypes[0] == Int::class.javaPrimitiveType ||
                            method.parameterTypes[0] == Integer::class.java)
                }
            if (setCompileSdk != null) {
                setCompileSdk.invoke(android, 36)
                return@afterEvaluate
            }

            // Older AGP: compileSdkVersion(36)
            val setCompileSdkVersion =
                android.javaClass.methods.firstOrNull { method ->
                    method.name == "setCompileSdkVersion" && method.parameterCount == 1
                }
            if (setCompileSdkVersion != null) {
                setCompileSdkVersion.invoke(android, 36)
                return@afterEvaluate
            }

            // Groovy-style method: compileSdkVersion(36)
            val compileSdkVersion =
                android.javaClass.methods.firstOrNull { method ->
                    method.name == "compileSdkVersion" &&
                        method.parameterCount == 1 &&
                        method.parameterTypes[0] == Int::class.javaPrimitiveType
                }
            compileSdkVersion?.invoke(android, 36)
        } catch (_: Throwable) {
            // Ignore modules with unexpected Android extension types.
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
