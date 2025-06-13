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

allprojects { 
   repositories { 
      google() 
      maven { 
         url = uri("https://phonepe.mycloudrepo.io/public/repositories/phonepe-intentsdk-android")
      } 
   } 
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}