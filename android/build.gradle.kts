allprojects {
    repositories {
        // 官方源优先，保证 CI 可靠性；阿里云镜像作为国内加速回退
        google()
        mavenCentral()
        maven("https://maven.aliyun.com/repository/public")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
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

// 在受限构建环境中关闭 lint 任务（AGP 9 lint 工具在此环境初始化失败，且非打包必需）
gradle.taskGraph.whenReady {
    allTasks.forEach { task ->
        if (task.name.startsWith("lint")) {
            task.enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
