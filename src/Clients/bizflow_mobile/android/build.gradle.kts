plugins {
    // Đây là plugin cần thiết cho Firebase
    id("com.google.gms.google-services") version "4.4.4" apply false
    
    // Nếu project của bạn cần khai báo rõ version Android/Kotlin tại đây thì giữ nguyên,
    // còn không thì chỉ cần dòng google-services ở trên là đủ để fix lỗi Firebase.
}
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
