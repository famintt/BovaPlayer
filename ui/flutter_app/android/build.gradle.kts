allprojects {
    repositories {
        google()
        mavenCentral()
        // mpv-android 仓库
        maven { url = uri("https://jitpack.io") }
    }
}

// 全局依赖解析策略
subprojects {
    afterEvaluate {
        configurations.all {
            resolutionStrategy {
                force("org.checkerframework:checker-qual:3.42.0")
                force("com.google.guava:guava:32.1.3-android")
                force("com.google.code.findbugs:jsr305:3.0.2")
                
                // 处理依赖冲突时优先使用最新版本
                preferProjectModules()
                
                // 缓存动态版本1小时
                cacheDynamicVersionsFor(1, "hours")
                cacheChangingModulesFor(0, "seconds")
            }
        }
    }
}

// 统一所有 Android 子模块（含第三方 Flutter 插件）的 compileSdk。
// 背景：file_picker 8.3.7 等插件把 compileSdk 硬编码为 34，而
// flutter_plugin_android_lifecycle 要求依赖方 compileSdk >= 36，
// 否则 :file_picker:checkReleaseAarMetadata 会直接失败。
// 这里用反射设置，兼容 AGP 9 的新旧两套 DSL（setCompileSdk / compileSdkVersion）。
fun Project.forceAndroidCompileSdk(apiLevel: Int) {
    val androidExtension = extensions.findByName("android") ?: return
    val methods = androidExtension.javaClass.methods
    val setter = methods.firstOrNull { it.name == "setCompileSdk" && it.parameterTypes.size == 1 }
    if (setter != null) {
        setter.invoke(androidExtension, apiLevel)
        return
    }
    methods.firstOrNull { it.name == "compileSdkVersion" && it.parameterTypes.size == 1 }
        ?.invoke(androidExtension, apiLevel)
}

subprojects {
    plugins.withId("com.android.library") { forceAndroidCompileSdk(36) }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // 解决依赖冲突
    configurations.all {
        resolutionStrategy {
            force("org.checkerframework:checker-qual:3.42.0")
            force("com.google.guava:guava:32.1.3-android")
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
