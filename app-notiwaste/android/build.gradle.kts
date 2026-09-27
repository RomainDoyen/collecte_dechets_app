allprojects {
    repositories {
        google()
        mavenCentral()
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

fun Any.forceCompileSdk36() {
    val methods = javaClass.methods
    val setCompileSdk = methods.firstOrNull {
        it.name == "setCompileSdk" && it.parameterCount == 1
    }
    if (setCompileSdk != null) {
        setCompileSdk.invoke(this, 36)
        return
    }
    methods.firstOrNull {
        it.name == "setCompileSdkVersion" &&
            it.parameterCount == 1 &&
            it.parameterTypes[0] == Int::class.javaPrimitiveType
    }?.invoke(this, 36)
}

// AGP 9 verrouille compileSdk après l'évaluation. finalizeDsl est le dernier moment autorisé.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val androidComponents = extensions.findByName("androidComponents") ?: return@withPlugin
        val finalizeDsl = androidComponents.javaClass.methods.firstOrNull { method ->
            method.name == "finalizeDsl" &&
                method.parameterCount == 1 &&
                Action::class.java.isAssignableFrom(method.parameterTypes[0])
        } ?: return@withPlugin
        finalizeDsl.invoke(
            androidComponents,
            object : Action<Any> {
                override fun execute(dsl: Any) {
                    dsl.forceCompileSdk36()
                }
            },
        )
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
