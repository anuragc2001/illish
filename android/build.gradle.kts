allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://phonepe.mycloudrepo.io/public/repositories/phonepe-intentsdk-android")
        }
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
                compileSdk = 36
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