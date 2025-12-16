# 如何在Android应用中使用WQStyleFilter AAR库

*作者：Jimmy Gan*

*最后更新：2025年12月16日*

*版本：v1.7.0（对应iOS版本：v1.2.2）*

本指南详细介绍如何在Android项目中集成和使用【沃奇】风格滤镜AAR库，该库基于3D LUT色彩查找表技术提供强大的图像风格转换功能。

**本版本包含两个AAR文件：**
- `wq-ffmpeg-kit-1.0.0.aar` (33MB) - 独立FFmpeg引擎，支持libmp3lame编码器
- `wq-ffmpeg-style-filter-1.7.0.aar` (16KB) - 风格滤镜SDK

## 为什么使用独立的FFmpeg-Kit AAR？

在团队项目中，您可能已经使用了Maven仓库的FFmpeg-Kit依赖：

```kotlin
// 原有依赖（可能导致冲突）
implementation("com.mrljdx:ffmpeg-kit-full:6.1.4")
```

**使用独立AAR的原因：**

1. **避免依赖冲突**：如果项目中已有其他FFmpeg相关依赖，Maven版本可能导致类冲突或版本不兼容
2. **统一版本管理**：确保风格滤镜SDK和音频转换使用相同的FFmpeg版本
3. **离线可用**：无需网络即可构建项目
4. **团队项目兼容**：支持团队项目中的音频转换需求（如Opus/MP3转PCM）

**迁移方法：**

```kotlin
// 移除原有Maven依赖
// implementation("com.mrljdx:ffmpeg-kit-full:6.1.4")  // 删除此行

// 使用独立AAR
implementation(files("libs/wq-ffmpeg-kit-1.0.0.aar"))
implementation(files("libs/wq-ffmpeg-style-filter-1.7.0.aar"))
```

**音频转换示例（团队项目需求）：**

```java
// Opus/MP3 转 PCM
String command = String.format(Locale.US, 
    "-y -i \"%s\" -f s16le -ar %d -ac 1 \"%s\"",
    inputPath, sampleRate, outputPath);
FFmpegKit.execute(command);

// 或使用WQFFmpegKit工具类
WQFFmpegKit.AudioConversionResult result = 
    WQFFmpegKit.convertToPcm(inputPath, outputPath, 16000);
```

## 目录

1. [库简介](#库简介)
2. [系统要求](#系统要求)
3. [项目集成步骤](#项目集成步骤)
4. [权限配置](#权限配置)
5. [API参考](#api参考)
6. [基础使用方法](#基础使用方法)
7. [完整示例代码](#完整示例代码)

## 库简介

WQStyleFilter是一个专为Android开发的图像风格滤镜AAR库，具有以下特点：

- **3D LUT技术**：基于专业的3D色彩查找表算法
- **多种滤镜**：支持富士、哈苏、理光等多种专业相机风格
- **多线程优化**：利用所有CPU核心并行处理，性能卓越（典型处理时间800-1500ms）
- **Java友好**：纯Java API，无需Kotlin协程
- **自动LUT预加载**：构造函数自动预加载所有LUT文件到缓存
- **FFmpeg预初始化**：构造函数自动预热FFmpeg引擎，消除首次调用延迟
- **音频转换支持**：通过WQFFmpegKit工具类支持MP3/PCM音频转换
- **丰富的辅助方法**：内置图像加载、保存、临时文件管理等功能

## 系统要求

- **最低Android版本**：API 26 (Android 8.0)
- **推荐内存**：至少1GB可用内存
- **AAR大小**：wq-ffmpeg-kit-1.0.0.aar (33MB) + wq-ffmpeg-style-filter-1.7.0.aar (16KB)
- **处理器**：支持ARM64-v8a和ARMeabi-v7a架构

## 项目集成步骤

### 第1步：复制AAR文件

将两个AAR文件复制到您的Android项目的`app/libs`目录：

```bash
# 创建libs目录（如果不存在）
mkdir -p /path/to/your/android/project/app/libs

# 复制AAR文件
cp wq-ffmpeg-kit-1.0.0.aar /path/to/your/android/project/app/libs/
cp wq-ffmpeg-style-filter-1.7.0.aar /path/to/your/android/project/app/libs/
```

### 第2步：配置build.gradle.kts

在您的`app/build.gradle.kts`文件中添加以下配置：

```kotlin
dependencies {
    // FFmpeg-Kit AAR (替代 com.mrljdx:ffmpeg-kit-full:6.1.4)
    implementation(files("libs/wq-ffmpeg-kit-1.0.0.aar"))
    
    // WQStyleFilter AAR库
    implementation(files("libs/wq-ffmpeg-style-filter-1.7.0.aar"))
    
    // smart-exception依赖（ffmpeg-kit需要）
    implementation("com.arthenica:smart-exception-java:0.2.1")
    
    // 其他现有依赖...
}
```

### 第3步：准备LUT滤镜文件

将LUT滤镜文件复制到项目的assets目录：

```bash
# 创建assets目录结构
mkdir -p /path/to/your/android/project/app/src/main/assets/lut/formated-luts

# 复制LUT文件（.cube格式）
cp /path/to/lut/files/*.cube /path/to/your/android/project/app/src/main/assets/lut/formated-luts/
```

### 第4步：同步项目

在Android Studio中点击"Sync Now"同步项目依赖。

## 权限配置

在`AndroidManifest.xml`中添加必要权限（仅在需要保存图像时）：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    
    <!-- 存储权限（可选 - 仅在需要保存处理结果时添加） -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"
        tools:ignore="ScopedStorage" />
    
    <!-- Android 13+存储权限 -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    
    <application>
        <!-- 您的应用配置 -->
    </application>
</manifest>
```

## API参考

### WQStyleFilter类

```java
import cn.watchfun.stylefilter.WQStyleFilter;
```

#### 构造函数

```java
// 使用默认LUT路径 "lut/formated-luts"
WQStyleFilter(Context context)

// 自定义LUT路径（满足团队项目不同目录需求）
WQStyleFilter(Context context, String lutAssetFolder, boolean isDebug)
```

**参数说明：**
- `context`: Android上下文
- `lutAssetFolder`: LUT文件在assets中的文件夹路径，如 `"lut/formated-luts"` 或 `"your/custom/lut/path"`
- `isDebug`: 是否打印调试日志

#### 核心方法

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `applyStyleFilterFast(String lutAssetPath, String inputImagePath, String outputPath, boolean isDebug)` | 应用风格滤镜到图像 | `FilterResult` |
| `getLutFilterNames(String lutAssetFolder)` | 获取所有可用滤镜名称列表 | `List<String>` |
| `isAllLutsLoaded()` | 检查是否已预加载所有LUT（构造函数自动加载） | `boolean` |
| `getLoadedLutCount()` | 获取已加载的LUT数量 | `int` |

### WQFFmpegKit类（音频转换工具）

```java
import com.arthenica.ffmpegkit.WQFFmpegKit;
```

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `convertToPcm(String inputPath, String outputPath, int sampleRate)` | MP3/Opus转PCM | `AudioConversionResult` |
| `convertPcmToMp3(String inputPath, String outputPath, int sampleRate)` | PCM转MP3（使用libmp3lame） | `AudioConversionResult` |
| `copyAssetToFile(Context context, String assetPath, File destFile)` | 从assets复制文件 | `boolean` |
| `getDocumentsDir()` | 获取公共Documents目录 | `File` |
| `preInitialize()` | 预初始化FFmpeg引擎 | `void` |

#### 辅助方法

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `loadBitmapFromAssets(String assetPath)` | 从assets加载图像为Bitmap | `Bitmap` |
| `copyAssetImageToCache(String assetPath)` | 复制assets图像到缓存目录 | `String` (临时文件路径) |
| `saveBitmapToDocuments(Bitmap bitmap, String filterName)` | 保存Bitmap到Documents文件夹 | `String` (保存路径) |
| `deleteTempFile(String filePath)` | 删除临时文件 | `boolean` |

### FilterResult类

```java
WQStyleFilter.FilterResult
```

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `getSuccess()` | 处理是否成功 | `boolean` |
| `getOutputBitmap()` | 获取处理后的Bitmap | `Bitmap` |
| `getErrorMessage()` | 获取错误信息 | `String` |
| `getProcessingTime()` | 获取处理耗时(ms) | `long` |

## 基础使用方法

### 1. 初始化

```java
import cn.watchfun.stylefilter.WQStyleFilter;

public class MainActivity extends AppCompatActivity {
    private WQStyleFilter styleFilter;
    private ExecutorService executorService;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 方式1: 使用默认LUT路径 "lut/formated-luts"
        styleFilter = new WQStyleFilter(this);
        
        // 方式2: 自定义LUT路径（满足团队项目不同目录需求）
        // styleFilter = new WQStyleFilter(this, "your/custom/lut/path", false);
        
        executorService = Executors.newSingleThreadExecutor();
    }
}
```

### 2. 获取滤镜列表

```java
// 使用AAR提供的方法获取滤镜列表（返回构造函数中缓存的列表）
List<String> filterNames = styleFilter.getLutFilterNames();
```

### 3. 应用滤镜

注意：LUT文件在构造函数中自动预加载，无需手动调用preloadAllLutFiles。

```java
private void applyFilter(String assetImageName, String filterName) {
    executorService.execute(() -> {
        // 复制图像到缓存
        String tempFilePath = styleFilter.copyAssetImageToCache(assetImageName);
        if (tempFilePath == null) {
            runOnUiThread(() -> Toast.makeText(this, "复制图像失败", Toast.LENGTH_SHORT).show());
            return;
        }
        
        // 构建LUT路径
        String cubePath = "lut/formated-luts/" + filterName + ".cube";
        
        // 应用滤镜
        WQStyleFilter.FilterResult result = styleFilter.applyStyleFilterFast(
                cubePath,
                tempFilePath,
                null,   // 不自动保存
                true    // 打印调试日志
        );
        
        // 清理临时文件
        styleFilter.deleteTempFile(tempFilePath);
        
        // 更新UI
        runOnUiThread(() -> {
            if (result != null && result.getSuccess() && result.getOutputBitmap() != null) {
                imageView.setImageBitmap(result.getOutputBitmap());
                Toast.makeText(this, "处理完成，耗时: " + result.getProcessingTime() + "ms", 
                        Toast.LENGTH_SHORT).show();
            } else {
                String errorMsg = result != null ? result.getErrorMessage() : "未知错误";
                Toast.makeText(this, "滤镜失败: " + errorMsg, Toast.LENGTH_LONG).show();
            }
        });
    });
}
```

### 5. 保存处理结果

```java
// 使用AAR提供的方法保存图像到Documents文件夹
String savedPath = styleFilter.saveBitmapToDocuments(bitmap, filterName);
if (savedPath != null) {
    Toast.makeText(this, "已保存到: " + savedPath, Toast.LENGTH_LONG).show();
}
```

### 6. 清理资源

```java
@Override
protected void onDestroy() {
    super.onDestroy();
    if (executorService != null && !executorService.isShutdown()) {
        executorService.shutdown();
    }
}
```

## 完整示例代码

以下是一个完整的MainActivity示例，展示了所有主要功能：

```java
package cn.watchfun.android_use_cpp_demo1;

import android.Manifest;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
import androidx.core.content.ContextCompat;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import cn.watchfun.stylefilter.WQStyleFilter;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    
    // 示例图像列表（来自assets目录）
    private static final String[] SAMPLE_IMAGES = {
        "image1.jpg",
        "image2.jpg",
        "image3.png",
    };

    // UI组件
    private ImageView imageViewOriginal;
    private ImageView imageViewFiltered;
    private TextView labelProcessingTime;
    private Spinner spinnerFilters;
    private Button buttonLoadAllLuts;
    private Button buttonApplyFilter;
    private ProgressBar progressBar;
    private SwitchCompat switchSaveToFile;

    // 数据变量
    private Bitmap selectedBitmap;
    private String selectedImageName;
    private List<String> filterNames = new ArrayList<>();
    private WQStyleFilter styleFilter;
    private ExecutorService executorService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // 初始化WQStyleFilter AAR
        styleFilter = new WQStyleFilter(this);
        executorService = Executors.newSingleThreadExecutor();

        // 初始化UI组件
        initializeViews();
        loadLUTFilters();
    }

    private void initializeViews() {
        imageViewOriginal = findViewById(R.id.imageViewOriginal);
        imageViewFiltered = findViewById(R.id.imageViewFiltered);
        labelProcessingTime = findViewById(R.id.labelProcessingTime);
        spinnerFilters = findViewById(R.id.spinnerFilters);
        buttonLoadAllLuts = findViewById(R.id.buttonLoadAllLuts);
        buttonApplyFilter = findViewById(R.id.buttonApplyFilter);
        progressBar = findViewById(R.id.progressBar);
        switchSaveToFile = findViewById(R.id.switchSaveToFile);

        buttonLoadAllLuts.setOnClickListener(v -> loadAllLutFiles());
        buttonApplyFilter.setOnClickListener(v -> applyStyleFilter());
    }

    /**
     * 加载LUT滤镜列表
     */
    private void loadLUTFilters() {
        // 使用AAR提供的方法获取滤镜列表
        filterNames = styleFilter.getLutFilterNames("lut/formated-luts");
        
        if (!filterNames.isEmpty()) {
            ArrayAdapter<String> adapter = new ArrayAdapter<>(this,
                    android.R.layout.simple_spinner_item, filterNames);
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            spinnerFilters.setAdapter(adapter);
            
            Log.d(TAG, "已加载 " + filterNames.size() + " 个LUT滤镜");
        }
    }
    
    /**
     * 预加载所有LUT文件到内存
     */
    private void loadAllLutFiles() {
        buttonLoadAllLuts.setEnabled(false);
        progressBar.setVisibility(View.VISIBLE);

        executorService.execute(() -> {
            int loadedCount = styleFilter.preloadAllLutFiles("lut/formated-luts", true);
            
            runOnUiThread(() -> {
                progressBar.setVisibility(View.GONE);
                buttonLoadAllLuts.setEnabled(true);
                Toast.makeText(this, "已加载 " + loadedCount + " 个LUT文件", Toast.LENGTH_SHORT).show();
            });
        });
    }

    /**
     * 应用风格滤镜
     */
    private void applyStyleFilter() {
        if (selectedBitmap == null || selectedImageName == null) {
            Toast.makeText(this, "请先选择图像", Toast.LENGTH_SHORT).show();
            return;
        }

        int selectedPosition = spinnerFilters.getSelectedItemPosition();
        String filterName = filterNames.get(selectedPosition);
        String cubePath = "lut/formated-luts/" + filterName + ".cube";

        progressBar.setVisibility(View.VISIBLE);
        buttonApplyFilter.setEnabled(false);

        executorService.execute(() -> {
            long startTime = System.currentTimeMillis();
            
            // 使用AAR方法复制图像到缓存
            String tempFilePath = styleFilter.copyAssetImageToCache(selectedImageName);
            if (tempFilePath == null) {
                runOnUiThread(() -> {
                    progressBar.setVisibility(View.GONE);
                    buttonApplyFilter.setEnabled(true);
                    Toast.makeText(this, "复制图像失败", Toast.LENGTH_SHORT).show();
                });
                return;
            }
            
            // 使用AAR应用风格滤镜
            WQStyleFilter.FilterResult result = styleFilter.applyStyleFilterFast(
                    cubePath,
                    tempFilePath,
                    null,
                    true
            );

            // 清理临时文件
            styleFilter.deleteTempFile(tempFilePath);

            long processingTime = System.currentTimeMillis() - startTime;

            runOnUiThread(() -> {
                progressBar.setVisibility(View.GONE);
                buttonApplyFilter.setEnabled(true);

                if (result != null && result.getSuccess() && result.getOutputBitmap() != null) {
                    imageViewFiltered.setImageBitmap(result.getOutputBitmap());
                    imageViewFiltered.setVisibility(View.VISIBLE);
                    
                    labelProcessingTime.setText("处理耗时: " + processingTime + "ms");
                    labelProcessingTime.setVisibility(View.VISIBLE);
                    
                    // 如果开关打开，保存到Documents文件夹
                    if (switchSaveToFile.isChecked()) {
                        String savedPath = styleFilter.saveBitmapToDocuments(result.getOutputBitmap(), filterName);
                        if (savedPath != null) {
                            Toast.makeText(this, "已保存: " + new File(savedPath).getName(), Toast.LENGTH_LONG).show();
                        }
                    }
                } else {
                    String errorMsg = result != null ? result.getErrorMessage() : "未知错误";
                    Toast.makeText(this, "滤镜失败: " + errorMsg, Toast.LENGTH_LONG).show();
                }
            });
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (executorService != null && !executorService.isShutdown()) {
            executorService.shutdown();
        }
    }
}
```

---

## 技术支持

如果您在使用过程中遇到问题，请检查：

1. **AAR文件**：确保wq-style-filter-1.5.0.aar已正确放置在app/libs/目录
2. **LUT文件**：确保.cube文件已正确放置在assets/lut/formated-luts/目录
3. **权限设置**：确保必要的存储权限已授予（如需保存）
4. **日志输出**：查看LogCat中的"WQStyleFilter"标签获取详细信息

**日志标签：** `WQStyleFilter`