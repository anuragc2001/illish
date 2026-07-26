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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAction = Action<Project> {
        val p = this
        p.plugins.withId("com.android.library") {
            p.extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                if (p.name == "geocoding_android" || p.name.contains("isar")) {
                    compileSdk = 36
                }
                if (namespace == null || namespace?.isEmpty() == true) {
                    if (p.name.contains("isar")) {
                        namespace = "dev.isar.${p.name.replace("-", ".")}"
                    }
                }
            }
        }
    }

    if (project.state.executed) {
        configureAction.execute(project)
    } else {
        project.afterEvaluate(configureAction)
    }
}