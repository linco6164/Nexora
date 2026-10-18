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

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileOptions {
                // pay_android 3.2.0 fixează încă jvmTarget Kotlin la 1.8.
                // Păstrăm Java la aceeași țintă doar pentru acest plugin;
                // aplicația și restul modulelor continuă să folosească JVM 17.
                val javaTarget =
                    if (project.name == "pay_android") {
                        JavaVersion.VERSION_1_8
                    } else {
                        JavaVersion.VERSION_17
                    }

                sourceCompatibility = javaTarget
                targetCompatibility = javaTarget
            }
        }
    }

    plugins.withId("org.jetbrains.kotlin.android") {
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
            compilerOptions {
                jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                )
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
