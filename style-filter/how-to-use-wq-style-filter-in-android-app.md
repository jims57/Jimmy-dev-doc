# 如何在Android应用中使用wq-style-filter-1.0.0.aar库

*作者：Jimmy Gan*

*最后更新：2025年10月14日*

本指南将详细介绍如何从零开始在Android项目中集成和使用【沃奇】风格滤镜AAR库（wq-style-filter-1.0.0.aar），该库基于3D LUT色彩查找表技术提供强大的图像风格转换功能。

## 目录

1. [库简介](#库简介)
2. [系统要求](#系统要求)
3. [获取AAR库](#获取aar库)
4. [项目集成步骤](#项目集成步骤)
5. [权限配置](#权限配置)
6. [基础使用方法](#基础使用方法)
7. [高级功能](#高级功能)
8. [常见问题解答](#常见问题解答)
9. [最佳实践](#最佳实践)

## 库简介

wq-style-filter是一个专为Android开发的图像风格滤镜AAR库，具有以下特点：

- **3D LUT技术**：基于专业的3D色彩查找表算法
- **多种滤镜**：支持富士、哈苏、理光等多种专业相机风格
- **三线性插值**：平滑的颜色过渡，无色块现象
- **多线程优化**：利用所有CPU核心并行处理，性能卓越
- **Java友好**：提供阻塞方法，简化Java集成
- **中文支持**：完整的中文API文档和错误信息

## 系统要求

- **最低Android版本**：API 24 (Android 7.0)
- **推荐内存**：至少1GB可用内存
- **存储空间**：约50KB（包含LUT文件）
- **处理器**：支持多核处理器（可选，但推荐）

## 获取AAR库

### 方式一：从构建输出获取
```bash
# AAR库文件位置
/path/to/android-use-litert/my-info/android_aar/style_filter_aar/build/outputs/aar/wq-style-filter-1.0.0.aar
```

### 方式二：自行构建
```bash
cd /path/to/android-use-litert/my-info/android_aar
./build_android_aar.sh
```

## 项目集成步骤

### 第1步：复制AAR文件

将AAR文件复制到您的Android项目中：

```bash
# 创建libs目录（如果不存在）
mkdir -p /path/to/your/android/project/app/libs

# 复制AAR文件
cp wq-style-filter-1.0.0.aar /path/to/your/android/project/app/libs/
```

### 第2步：配置build.gradle.kts

在您的`app/build.gradle.kts`文件中添加以下依赖：

```kotlin
dependencies {
    // StyleFilter AAR库（Kotlin编写）
    implementation(files("libs/wq-style-filter-1.0.0.aar"))
    
    // Kotlin标准库（AAR兼容性必需）
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    
    // 协程库（AAR内部使用）
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // 其他现有依赖...
}
```

**重要提示：** 即使您的项目是纯Java项目，也需要添加Kotlin标准库和协程库，因为AAR是用Kotlin编写的。

### 第3步：准备LUT滤镜文件

将LUT滤镜文件复制到项目的assets目录：

```bash
# 创建assets目录结构
mkdir -p /path/to/your/android/project/app/src/main/assets/lut/formated-luts

# 复制LUT文件（.cube格式）
cp /path/to/lut/files/*.cube /path/to/your/android/project/app/src/main/assets/lut/formated-luts/
```

常见的LUT滤镜包括：
- `Fuji-XT4.cube` - 富士相机风格
- `Hasselblad-1.cube` - 哈苏相机风格
- `Ricoh-GR3.cube` - 理光相机风格
- 等等...

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

## 基础使用方法

### Java实现（推荐 - 使用阻塞方法）

```java
import cn.watchfun.StyleFilter;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {
    private StyleFilter styleFilter;
    private ExecutorService executorService;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // 初始化风格滤镜
        styleFilter = new StyleFilter(this);
        executorService = Executors.newSingleThreadExecutor();
    }
    
    // 应用风格滤镜
    private void applyFilter(String imagePath, String filterName) {
        executorService.execute(() -> {
            // 构建LUT文件路径
            String cubePath = "lut/formated-luts/" + filterName + ".cube";
            
            // 使用阻塞方法处理图像 - 无需协程！
            StyleFilter.FilterResult result = styleFilter.applyStyleFilterBlocking(
                cubePath,           // LUT滤镜路径
                imagePath,          // 输入图像路径
                null                // 输出文件夹（null=不自动保存）
            );
            
            // 在主线程更新UI
            runOnUiThread(() -> {
                if (result.getSuccess()) {
                    // 处理成功
                    if (result.getOutputBitmap() != null) {
                        imageView.setImageBitmap(result.getOutputBitmap());
                    }
                    
                    // 显示处理时间
                    long processingTime = result.getProcessingTime();
                    Toast.makeText(this, "处理完成，耗时: " + processingTime + "ms", 
                                 Toast.LENGTH_SHORT).show();
                    
                    // 如果保存了文件
                    if (result.getSavedPath() != null) {
                        Log.d("StyleFilter", "图像已保存到: " + result.getSavedPath());
                    }
                } else {
                    // 处理失败
                    String errorMsg = result.getErrorMessage();
                    Toast.makeText(this, "处理失败: " + errorMsg, Toast.LENGTH_LONG).show();
                }
            });
        });
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        // 清理资源
        if (executorService != null) {
            executorService.shutdown();
        }
    }
}
```

### Kotlin实现（使用协程）

```kotlin
import cn.watchfun.StyleFilter
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {
    private lateinit var styleFilter: StyleFilter
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // 初始化风格滤镜
        styleFilter = StyleFilter(this)
    }
    
    // 应用风格滤镜
    private fun applyFilter(imagePath: String, filterName: String) {
        scope.launch {
            val cubePath = "lut/formated-luts/$filterName.cube"
            
            val result = withContext(Dispatchers.IO) {
                styleFilter.applyStyleFilter(
                    cubePath = cubePath,
                    targetImagePath = imagePath,
                    outputFolder = null
                )
            }
            
            // 在主线程更新UI
            if (result.success) {
                result.outputBitmap?.let { bitmap ->
                    imageView.setImageBitmap(bitmap)
                }
                
                Toast.makeText(this@MainActivity, 
                    "处理完成，耗时: ${result.processingTime}ms", 
                    Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this@MainActivity, 
                    "处理失败: ${result.errorMessage}", 
                    Toast.LENGTH_LONG).show()
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
```

## 高级功能

### 1. 不同的保存选项

```java
// 不保存，只返回Bitmap
StyleFilter.FilterResult result = styleFilter.applyStyleFilterBlocking(
    cubePath, imagePath, null
);

// 保存到默认Documents文件夹
StyleFilter.FilterResult result = styleFilter.applyStyleFilterBlocking(
    cubePath, imagePath, ""
);

// 保存到自定义文件夹
StyleFilter.FilterResult result = styleFilter.applyStyleFilterBlocking(
    cubePath, imagePath, "/sdcard/MyApp/Filtered"
);
```

### 2. 支持多种图像输入格式

```java
// 文件路径
String imagePath = "/sdcard/Pictures/photo.jpg";

// Content URI
String imagePath = "content://media/external/images/media/123";

// Assets文件
String imagePath = "sample_image.jpg";  // 从assets/sample_image.jpg加载
```

### 3. 批量处理多张图像

```java
private void batchProcessImages(List<String> imagePaths, String filterName) {
    executorService.execute(() -> {
        String cubePath = "lut/formated-luts/" + filterName + ".cube";
        int total = imagePaths.size();
        int completed = 0;
        
        for (String imagePath : imagePaths) {
            try {
                StyleFilter.FilterResult result = styleFilter.applyStyleFilterBlocking(
                    cubePath, imagePath, "/sdcard/FilteredImages"
                );
                
                completed++;
                final int progress = completed;
                
                runOnUiThread(() -> {
                    // 更新进度
                    progressBar.setProgress((progress * 100) / total);
                    statusText.setText("已完成: " + progress + "/" + total);
                });
                
                if (result.getSuccess()) {
                    Log.d("BatchProcess", "完成: " + imagePath);
                } else {
                    Log.e("BatchProcess", "失败: " + imagePath + " - " + result.getErrorMessage());
                }
                
            } catch (Exception e) {
                Log.e("BatchProcess", "异常: " + imagePath, e);
            }
        }
        
        runOnUiThread(() -> {
            Toast.makeText(this, "批量处理完成！", Toast.LENGTH_SHORT).show();
        });
    });
}
```

### 4. 错误处理和日志

```java
private void applyFilterWithErrorHandling(String imagePath, String filterName) {
    executorService.execute(() -> {
        try {
            String cubePath = "lut/formated-luts/" + filterName + ".cube";
            
            StyleFilter.FilterResult result = styleFilter.applyStyleFilterBlocking(
                cubePath, imagePath, null
            );
            
            runOnUiThread(() -> {
                if (result.getSuccess()) {
                    // 成功处理
                    handleSuccessResult(result);
                } else {
                    // 处理失败
                    handleErrorResult(result.getErrorMessage());
                }
            });
            
        } catch (Exception e) {
            Log.e("StyleFilter", "处理异常", e);
            runOnUiThread(() -> {
                handleErrorResult("处理异常: " + e.getMessage());
            });
        }
    });
}

private void handleSuccessResult(StyleFilter.FilterResult result) {
    // 显示处理结果
    if (result.getOutputBitmap() != null) {
        imageView.setImageBitmap(result.getOutputBitmap());
    }
    
    // 显示性能信息
    long processingTime = result.getProcessingTime();
    Log.d("StyleFilter", "处理耗时: " + processingTime + "ms");
    
    // 显示保存路径
    if (result.getSavedPath() != null) {
        Log.d("StyleFilter", "文件已保存: " + result.getSavedPath());
    }
}

private void handleErrorResult(String errorMessage) {
    Log.e("StyleFilter", "处理失败: " + errorMessage);
    Toast.makeText(this, "图像处理失败: " + errorMessage, Toast.LENGTH_LONG).show();
}
```

### 5. 从Assets加载LUT滤镜列表

```java
private List<String> loadAvailableFilters() {
    List<String> filterNames = new ArrayList<>();
    try {
        AssetManager assetManager = getAssets();
        String[] files = assetManager.list("lut/formated-luts");
        
        if (files != null) {
            for (String file : files) {
                if (file.endsWith(".cube")) {
                    // 移除.cube扩展名
                    filterNames.add(file.replace(".cube", ""));
                }
            }
            // 排序
            Collections.sort(filterNames);
        }
    } catch (IOException e) {
        Log.e("StyleFilter", "加载滤镜列表失败", e);
    }
    return filterNames;
}
```

## 常见问题解答

### Q1: 为什么纯Java项目也需要添加Kotlin依赖？
**A:** wq-style-filter AAR库是用Kotlin编写的，因此需要Kotlin标准库和协程库才能运行。但您不需要在自己的代码中使用Kotlin，AAR提供了Java友好的阻塞方法`applyStyleFilterBlocking()`。

### Q2: 支持哪些LUT文件格式？
**A:** 目前仅支持`.cube`格式的3D LUT文件。这是业界标准格式，大多数专业调色软件都支持导出。

### Q3: 如何获取更多LUT滤镜？
**A:** 您可以：
- 从专业调色软件（如DaVinci Resolve、Adobe Premiere）导出
- 从网上下载免费或付费的LUT包
- 使用Photoshop等工具自己创建

### Q4: 处理速度如何？
**A:** 处理速度取决于：
- 图像分辨率（典型的1080p图像约50-200ms）
- 设备CPU性能
- LUT文件大小（通常为33x33x33或64x64x64）

库已经过优化，使用多线程并行处理，充分利用所有CPU核心。

### Q5: 如何处理权限请求？
**A:** 动态权限请求示例：
```java
private void requestStoragePermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        // Android 13+
        ActivityCompat.requestPermissions(this,
            new String[]{Manifest.permission.READ_MEDIA_IMAGES}, 100);
    } else {
        // Android 12及以下
        ActivityCompat.requestPermissions(this,
            new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE}, 100);
    }
}
```

### Q6: 支持哪些图像格式？
**A:** 支持Android标准格式：
- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- BMP (.bmp)

## 最佳实践

### 1. 内存优化
```java
// 处理完成后及时回收大图像
private void processImageWithMemoryOptimization(String imagePath, String filterName) {
    executorService.execute(() -> {
        StyleFilter.FilterResult result = null;
        try {
            String cubePath = "lut/formated-luts/" + filterName + ".cube";
            result = styleFilter.applyStyleFilterBlocking(cubePath, imagePath, null);
            
            runOnUiThread(() -> {
                if (result.getSuccess() && result.getOutputBitmap() != null) {
                    // 创建副本用于显示
                    Bitmap displayBitmap = result.getOutputBitmap().copy(
                        result.getOutputBitmap().getConfig(), false);
                    imageView.setImageBitmap(displayBitmap);
                    
                    // 及时回收原始大图像
                    if (!result.getOutputBitmap().isRecycled()) {
                        result.getOutputBitmap().recycle();
                    }
                }
            });
        } catch (Exception e) {
            Log.e("StyleFilter", "处理异常", e);
        } finally {
            // 强制垃圾回收
            System.gc();
        }
    });
}
```

### 2. 用户体验优化
```java
// 显示处理进度
private void applyFilterWithProgress(String imagePath, String filterName) {
    // 显示进度对话框
    ProgressDialog progressDialog = new ProgressDialog(this);
    progressDialog.setMessage("正在应用滤镜，请稍候...");
    progressDialog.setCancelable(false);
    progressDialog.show();
    
    executorService.execute(() -> {
        long startTime = System.currentTimeMillis();
        String cubePath = "lut/formated-luts/" + filterName + ".cube";
        
        StyleFilter.FilterResult result = styleFilter.applyStyleFilterBlocking(
            cubePath, imagePath, null
        );
        
        long processingTime = System.currentTimeMillis() - startTime;
        
        runOnUiThread(() -> {
            progressDialog.dismiss();
            
            if (result.getSuccess()) {
                imageView.setImageBitmap(result.getOutputBitmap());
                Toast.makeText(this, "处理完成，耗时: " + processingTime + "ms", 
                             Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "处理失败: " + result.getErrorMessage(), 
                             Toast.LENGTH_LONG).show();
            }
        });
    });
}
```

### 3. 滤镜预览功能
```java
// 生成滤镜缩略图预览
private void generateFilterPreviews(String sampleImagePath) {
    executorService.execute(() -> {
        List<String> filters = loadAvailableFilters();
        
        for (String filterName : filters) {
            String cubePath = "lut/formated-luts/" + filterName + ".cube";
            
            StyleFilter.FilterResult result = styleFilter.applyStyleFilterBlocking(
                cubePath, sampleImagePath, null
            );
            
            if (result.getSuccess()) {
                runOnUiThread(() -> {
                    // 添加到预览网格
                    addFilterPreview(filterName, result.getOutputBitmap());
                });
            }
        }
    });
}
```

### 4. 临时文件管理
```java
// 如果AAR需要文件路径而您只有Bitmap
private String saveBitmapToTempFile(Bitmap bitmap) throws IOException {
    File tempFile = new File(getCacheDir(), "temp_input_" + System.currentTimeMillis() + ".png");
    FileOutputStream fos = new FileOutputStream(tempFile);
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);
    fos.close();
    return tempFile.getAbsolutePath();
}

// 使用后清理
private void cleanupTempFile(String filePath) {
    File file = new File(filePath);
    if (file.exists()) {
        file.delete();
    }
}
```

---

## 技术支持

如果您在使用过程中遇到问题，请检查：

1. **依赖配置**：确保Kotlin标准库和协程库已正确添加
2. **LUT文件**：确保.cube文件已正确放置在assets/lut/formated-luts/目录
3. **权限设置**：确保必要的存储权限已授予（如需保存）
4. **日志输出**：查看LogCat中的详细错误信息

**日志标签：**
- `StyleFilter`：库的主要日志
- `StyleFilterHelper`：内部处理日志

## 完整示例项目

参考项目：`/path/to/android_use_cpp`

该项目展示了：
- 完整的Java集成示例
- 图像选择和滤镜选择UI
- 处理进度显示
- 结果保存功能
- 错误处理

通过遵循本指南，您应该能够成功在Android应用中集成和使用wq-style-filter-1.0.0.aar库，为用户提供专业的图像风格转换功能。