# WQVideoStabilizer AAR 使用指南

> 作者：Jimmy Gan  
> 日期：2025-11-03  
> 版本：v1.0.0

## 目录

1. [简介](#1-简介)
2. [快速开始](#2-快速开始)
3. [详细集成步骤](#3-详细集成步骤)
4. [API使用说明](#4-api使用说明)
5. [完整示例代码](#5-完整示例代码)
6. [常见问题](#6-常见问题)
7. [最佳实践](#7-最佳实践)
8. [故障排查](#8-故障排查)

---

## 1. 简介

### 1.1 什么是 WQVideoStabilizer？

WQVideoStabilizer 是一个基于 FFmpeg 和 vid.stab 的高性能 Android AAR 库，专注于视频稳定处理。

### 1.2 核心特性

- ✅ **专业级稳定**：基于 vid.stab 库，提供两阶段稳定算法
- ✅ **高质量编码**：使用 libx264 编码器，支持 H.264/AVC 格式
- ✅ **多种模式**：提供激进、中等、轻度三种稳定模式
- ✅ **完整API**：基于 FFmpeg-Kit，提供完整的 Java API

### 1.3 技术架构

**底层技术栈：**
- FFmpeg 6.0 LTS
- vid.stab 1.1（视频稳定库）
- libx264（H.264编码器）
- FFmpeg-Kit（Android集成框架）

**稳定流程：**
1. **检测阶段**：使用 `vidstabdetect` 过滤器分析视频抖动
2. **转换阶段**：使用 `vidstabtransform` 过滤器应用稳定效果
3. **编码阶段**：使用 `libx264` 编码器输出稳定后的视频

---

## 2. 快速开始

### 2.1 前置要求

- **Android Studio**: Arctic Fox (2020.3.1) 或更高版本
- **Gradle**: 7.0 或更高版本
- **minSdkVersion**: 24 (Android 7.0)
- **targetSdkVersion**: 34
- **Java**: JDK 17
- **支持架构**: arm64-v8a

### 2.2 三分钟快速集成

#### 步骤 1：添加 AAR 依赖

将 `wqvideostabilizer-1.0.0.aar` 文件复制到项目的 `app/libs/` 目录

在 `app/build.gradle.kts` 中添加：

\`\`\`kotlin
dependencies {
    // WQVideoStabilizer AAR
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    
    // FFmpeg-Kit 依赖（必需）
    implementation("com.arthenica:smart-exception-java:0.2.1")
    
    // Media3 依赖（用于视频播放）
    implementation("androidx.media3:media3-exoplayer:1.2.0")
    implementation("androidx.media3:media3-ui:1.2.0")
}
\`\`\`

#### 步骤 2：添加权限

在 `AndroidManifest.xml` 中添加：

\`\`\`xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" 
    android:minSdkVersion="33" />
\`\`\`

#### 步骤 3：使用视频稳定器

\`\`\`java
import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.FFmpegSession;
import com.arthenica.ffmpegkit.ReturnCode;

// 1. 第一阶段：检测视频抖动
String detectCmd = String.format(
    "-i \"%s\" -vf vidstabdetect=shakiness=10:accuracy=15:result=\"%s\" -f null -",
    inputPath, transformFile
);
FFmpegSession detectSession = FFmpegKit.execute(detectCmd);

// 2. 第二阶段：应用稳定效果
String transformCmd = String.format(
    "-i \"%s\" -vf vidstabtransform=input=\"%s\":smoothing=50 -c:v libx264 -crf 18 \"%s\" -y",
    inputPath, transformFile, outputPath
);
FFmpegSession transformSession = FFmpegKit.execute(transformCmd);
\`\`\`

---

## 3. 详细集成步骤

完整的集成步骤请参考示例项目：
`/Users/mac/Documents/GitHub/android_use_cpp`

---

## 4. API 使用说明

### 4.1 FFmpeg-Kit 核心类

#### FFmpegKit
执行 FFmpeg 命令的主类。

#### FFmpegSession
表示一个 FFmpeg 执行会话。

#### ReturnCode
表示命令执行结果。

### 4.2 视频稳定参数

**检测参数：**
- `shakiness`: 抖动强度 (1-10)
- `accuracy`: 精度 (1-15)
- `stepsize`: 步长 (默认4)
- `mincontrast`: 最小对比度 (0.0-1.0)

**转换参数：**
- `smoothing`: 平滑度 (0-100)
- `interpol`: 插值方法（bilinear, bicubic, nearest）
- `optzoom`: 优化缩放 (0-2)
- `zoomspeed`: 缩放速度 (0.0-1.0)

**编码参数：**
- `-c:v libx264`: 使用 H.264 编码器
- `-crf 18`: 质量因子 (0-51)
- `-preset medium`: 编码速度预设

---

## 5. 完整示例代码

完整示例代码请参考：
`/Users/mac/Documents/GitHub/android_use_cpp/app/src/main/java/cn/watchfun/android_use_cpp_demo1/MainActivity.java`

---

## 6. 常见问题

### Q1: 支持哪些视频格式？
**A:** 支持所有 FFmpeg 支持的格式（MP4, AVI, MOV, MKV等）

### Q2: 处理速度如何？
**A:** 取决于视频分辨率和设备性能，通常为实时播放速度的0.5-2倍

### Q3: 是否支持实时预览？
**A:** 当前版本不支持，需要完整处理后才能播放

---

## 7. 最佳实践

1. **选择合适的模式**：根据视频抖动程度选择模式
2. **预览原始视频**：处理前先预览，评估是否需要稳定
3. **保存原始文件**：始终保留原始视频备份
4. **测试不同参数**：针对特定场景调整参数

---

## 8. 故障排查

### 8.1 常见错误

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| "No such filter: 'vidstabdetect'" | FFmpeg未包含vid.stab | 使用正确的AAR版本 |
| "Permission denied" | 缺少存储权限 | 检查并请求权限 |
| "Out of memory" | 视频过大 | 降低分辨率或分段处理 |

### 8.2 调试日志

\`\`\`bash
adb logcat -s FFmpegKit:V VideoStabilizer:V
\`\`\`

---

**文档结束**

如有疑问或建议，请联系：jimmy@watchfun.cn
