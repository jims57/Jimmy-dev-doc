# 如何在Android应用中使用wq-image-upscaler-1.4.0.aar库

*作者：Jimmy Gan*

*最后更新：2025年11月11日*

本指南将详细介绍如何从零开始在Android项目中集成和使用【沃奇】图片降噪增强AAR库（wq-image-upscaler-1.4.0.aar），该库基于Real-ESRGAN AI模型提供强大的图像降噪功能。

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

wq-image-upscaler是一个专为Android开发的图像降噪AAR库，具有以下特点：

- **AI驱动**：基于Real-ESRGAN深度学习模型
- **4倍放大**：支持图像4倍降噪增强
- **硬件加速**：自动NNAPI硬件加速，智能CPU回退
- **内存优化**：自动瓦片处理，防止大图像内存溢出
- **Java友好**：提供阻塞方法，简化Java集成
- **中文支持**：完整的中文API文档和错误信息
- **智能回退**：自动检测设备兼容性，NNAPI失败时自动切换CPU

## 系统要求

- **最低Android版本**：API 24 (Android 7.0)
- **推荐内存**：至少2GB可用内存（处理大图像时）
- **存储空间**：约5MB（包含AI模型）
- **硬件加速**：支持NNAPI的设备（可选，但推荐）

## 获取AAR库

### 方式一：从构建输出获取
```bash
# AAR库文件位置
/path/to/android-use-litert/my-info/android_aar/aar-output/wq-image-upscaler-1.4.0.aar
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
cp wq-image-upscaler-1.4.0.aar /path/to/your/android/project/app/libs/
```

### 第2步：配置build.gradle.kts

在您的`app/build.gradle.kts`文件中添加以下依赖：

```kotlin
dependencies {
    // 只需添加AAR库依赖，所有TensorFlow Lite依赖已自动包含
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    
    // 其他现有依赖...
}
```

**重要提示：** wq-image-upscaler-1.4.0.aar已经内置了所有必需的依赖，包括：
- `org.tensorflow:tensorflow-lite:2.14.0`
- `org.tensorflow:tensorflow-lite-support:0.4.4`
- `org.tensorflow:tensorflow-lite-metadata:0.4.4`
- `org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3`

**无需手动添加这些依赖！**

### 第3步：同步项目

在Android Studio中点击"Sync Now"同步项目依赖。

## 权限配置

在`AndroidManifest.xml`中添加必要权限（仅在需要保存图像时）：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- 存储权限（可选 - 仅在需要保存处理结果时添加） -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
        android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    
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
import watchfun.image.ImageUpscaler;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {
    private ImageUpscaler imageUpscaler;
    private ExecutorService executorService;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // 初始化图像增强器
        imageUpscaler = new ImageUpscaler(this);
        executorService = Executors.newSingleThreadExecutor();
        
        // 在后台线程中初始化
        executorService.execute(() -> {
            boolean success = imageUpscaler.initializeBlocking();
            runOnUiThread(() -> {
                if (success) {
                    Log.d("ImageUpscaler", "初始化成功");
                    // 可以开始处理图像
                } else {
                    Log.e("ImageUpscaler", "初始化失败");
                }
            });
        });
    }
    
    // 图像降噪处理
    private void upscaleImage(String imagePath) {
        executorService.execute(() -> {
            // 使用阻塞方法处理图像 - 无需协程！
            // AAR会自动处理硬件加速（NNAPI -> CPU回退）
            ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
                imagePath,                    // 图像路径
                true,                        // 是否保存处理结果
                0.75f,                       // 缩小参数（0.75表示缩小75%，保留25%）
                true                         // 是否在处理后恢复到原始尺寸
            );
            
            // 在主线程更新UI
            runOnUiThread(() -> {
                if (result.getSuccess()) {
                    // 处理成功
                    if (result.getOutputBitmap() != null) {
                        imageView.setImageBitmap(result.getOutputBitmap());
                    }
                    
                    // 显示处理时间
                    long processingTime = result.getInferenceTime();
                    Toast.makeText(this, "处理完成，耗时: " + processingTime + "ms", 
                                 Toast.LENGTH_SHORT).show();
                    
                    // 如果保存了文件
                    if (result.getSavedPath() != null) {
                        Log.d("ImageUpscaler", "图像已保存到: " + result.getSavedPath());
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
        if (imageUpscaler != null) {
            imageUpscaler.cleanup();
        }
        if (executorService != null) {
            executorService.shutdown();
        }
    }
}
```

### Kotlin实现（使用协程）

```kotlin
import watchfun.image.ImageUpscaler
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {
    private lateinit var imageUpscaler: ImageUpscaler
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // 初始化图像增强器
        imageUpscaler = ImageUpscaler(this)
        
        // 在协程中初始化
        scope.launch {
            val success = withContext(Dispatchers.IO) {
                imageUpscaler.initialize()
            }
            
            if (success) {
                Log.d("ImageUpscaler", "初始化成功")
            } else {
                Log.e("ImageUpscaler", "初始化失败")
            }
        }
    }
    
    // 图像降噪处理
    private fun upscaleImage(imagePath: String) {
        scope.launch {
            val result = withContext(Dispatchers.IO) {
                imageUpscaler.upscaleImage(
                    imagePath = imagePath,
                    saveAfterUpscaled = true,
                    smallerImageByPercentage = 0.75f,
                    resizeAfterUpscale = true,
                    delegate = ImageUpscaler.Delegate.NNAPI
                )
            }
            
            // 在主线程更新UI
            if (result.success) {
                result.outputBitmap?.let { bitmap ->
                    imageView.setImageBitmap(bitmap)
                }
                
                Toast.makeText(this@MainActivity, 
                    "处理完成，耗时: ${result.inferenceTime}ms", 
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
        imageUpscaler.cleanup()
        scope.cancel()
    }
}
```

## 高级功能

### 1. 不同的处理模式

```java
// 标准4倍降噪（不缩小，不恢复尺寸）
ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
    imagePath, false, 0.0f, false
);

// 先缩小75%再处理（适合大图像，保留25%尺寸）
ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
    imagePath, false, 0.75f, false
);

// 处理后恢复到原始尺寸（推荐）
ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
    imagePath, false, 0.75f, true
);

// 保存处理结果到文档目录
ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
    imagePath, true, 0.75f, true
);
```

**参数说明：**
- `imagePath`: 图像文件路径
- `saveAfterUpscaled`: 是否保存到Documents目录（开发测试用，生产环境建议使用后删除）
- `smallerImageByPercentage`: 缩小百分比（0.0=不缩小，0.75=缩小75%保留25%）
- `resizeAfterUpscale`: 是否恢复到原始尺寸（使用专业多步骤降采样算法）

### 2. 硬件加速（自动处理）

** 重要更新：** AAR现在自动处理硬件加速，无需手动指定代理类型！

```java
// AAR内部自动处理：
// 1. 首先尝试NNAPI（如果设备支持）
// 2. 如果NNAPI失败或输出质量差，自动回退到CPU
// 3. 对于已知问题设备（如ZTE），直接使用CPU

// 您只需调用方法，AAR会自动选择最佳硬件加速方式
ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
    imagePath, false, 0.75f, true
);

// 检查可用的硬件加速选项（可选）
List<ImageUpscaler.Delegate> availableDelegates = imageUpscaler.getAvailableDelegates();
```

**自动回退策略：**
- 已知问题设备检测（ZTE等）
- NNAPI质量测试（检测输出是否有效）
- 自动CPU回退（保证100%兼容性）
- 详细日志输出（便于调试）

### 3. 错误处理和日志

```java
private void upscaleImageWithErrorHandling(String imagePath) {
    executorService.execute(() -> {
        try {
            ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
                imagePath, false, 0.75f, true
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
            Log.e("ImageUpscaler", "处理异常", e);
            runOnUiThread(() -> {
                handleErrorResult("处理异常: " + e.getMessage());
            });
        }
    });
}

private void handleSuccessResult(ImageUpscaler.UpscaleResult result) {
    // 显示处理结果
    if (result.getOutputBitmap() != null) {
        imageView.setImageBitmap(result.getOutputBitmap());
    }
    
    // 显示性能信息
    long processingTime = result.getInferenceTime();
    Log.d("ImageUpscaler", "处理耗时: " + processingTime + "ms");
    
    // 显示保存路径
    if (result.getSavedPath() != null) {
        Log.d("ImageUpscaler", "文件已保存: " + result.getSavedPath());
    }
}

private void handleErrorResult(String errorMessage) {
    Log.e("ImageUpscaler", "处理失败: " + errorMessage);
    Toast.makeText(this, "图像处理失败: " + errorMessage, Toast.LENGTH_LONG).show();
}
```

## 常见问题解答

### Q1: 为什么初始化失败？
**A:** 常见原因包括：
- 设备内存不足
- TensorFlow Lite依赖缺失
- 模型文件损坏
- 权限不足

**解决方案：**
```java
// 检查内存状态
ActivityManager activityManager = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
ActivityManager.MemoryInfo memoryInfo = new ActivityManager.MemoryInfo();
activityManager.getMemoryInfo(memoryInfo);
Log.d("Memory", "可用内存: " + memoryInfo.availMem / (1024 * 1024) + "MB");

// AAR会自动处理硬件加速和回退，无需手动指定
boolean success = imageUpscaler.initializeBlocking();
```

### Q2: 处理大图像时出现内存不足？
**A:** 使用smallerImageByPercentage参数：
```java
// 对于大图像，先缩小75%再处理，然后恢复到原始尺寸
ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
    imagePath, false, 0.75f, true
);

// 或者缩小更多（90%），保留10%
ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
    imagePath, false, 0.90f, true
);
```

### Q3: 如何提高处理速度？
**A:** 优化建议：
- AAR自动使用NNAPI硬件加速（如果设备支持）
- 使用smallerImageByPercentage预先调整图像尺寸
- 在后台线程处理
- 复用ImageUpscaler实例
- 对于大图像，使用0.75或更高的缩小比例

### Q4: 支持哪些图像格式？
**A:** 支持Android标准格式：
- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- BMP (.bmp)

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
            new String[]{Manifest.permission.READ_EXTERNAL_STORAGE}, 100);
    }
}
```

## 最佳实践

### 1. 生命周期管理
```java
public class ImageUpscalerManager {
    private static ImageUpscalerManager instance;
    private ImageUpscaler imageUpscaler;
    private boolean isInitialized = false;
    
    public static synchronized ImageUpscalerManager getInstance(Context context) {
        if (instance == null) {
            instance = new ImageUpscalerManager(context.getApplicationContext());
        }
        return instance;
    }
    
    private ImageUpscalerManager(Context context) {
        imageUpscaler = new ImageUpscaler(context);
        initializeAsync();
    }
    
    private void initializeAsync() {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.execute(() -> {
            isInitialized = imageUpscaler.initializeBlocking();
            Log.d("ImageUpscaler", "全局初始化: " + isInitialized);
        });
        executor.shutdown();
    }
    
    public boolean isReady() {
        return isInitialized;
    }
    
    public ImageUpscaler getUpscaler() {
        return imageUpscaler;
    }
    
    public void cleanup() {
        if (imageUpscaler != null) {
            imageUpscaler.cleanup();
        }
    }
}
```

### 2. 内存优化
```java
// 处理完成后及时回收大图像
private void processImageWithMemoryOptimization(String imagePath) {
    executorService.execute(() -> {
        ImageUpscaler.UpscaleResult result = null;
        try {
            result = imageUpscaler.upscaleImageBlocking(imagePath, false, 0.75f, true);
            
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
            Log.e("ImageUpscaler", "处理异常", e);
        } finally {
            // 强制垃圾回收
            System.gc();
        }
    });
}
```

### 3. 用户体验优化
```java
// 显示处理进度
private void upscaleImageWithProgress(String imagePath) {
    // 显示进度对话框
    ProgressDialog progressDialog = new ProgressDialog(this);
    progressDialog.setMessage("正在处理图像，请稍候...");
    progressDialog.setCancelable(false);
    progressDialog.show();
    
    executorService.execute(() -> {
        long startTime = System.currentTimeMillis();
        
        ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
            imagePath, false, 0.75f, true
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

### 4. 批量处理
```java
// 批量处理多张图像
private void batchUpscaleImages(List<String> imagePaths) {
    executorService.execute(() -> {
        int total = imagePaths.size();
        int completed = 0;
        
        for (String imagePath : imagePaths) {
            try {
                ImageUpscaler.UpscaleResult result = imageUpscaler.upscaleImageBlocking(
                    imagePath, true, 0.75f, true
                );
                
                completed++;
                final int progress = completed;
                
                runOnUiThread(() -> {
                    // 更新进度
                    progressBar.setProgress((progress * 100) / total);
                    statusText.setText("已完成: " + progress + "/" + total);
                });
                
                if (result.getSuccess()) {
                    Log.d("BatchUpscale", "完成: " + imagePath);
                } else {
                    Log.e("BatchUpscale", "失败: " + imagePath + " - " + result.getErrorMessage());
                }
                
            } catch (Exception e) {
                Log.e("BatchUpscale", "异常: " + imagePath, e);
            }
        }
        
        runOnUiThread(() -> {
            Toast.makeText(this, "批量处理完成！", Toast.LENGTH_SHORT).show();
        });
    });
}
```

---

## 技术支持

如果您在使用过程中遇到问题，请检查：

1. **依赖配置**：确保所有TensorFlow Lite依赖已正确添加
2. **权限设置**：确保必要的存储权限已授予
3. **内存状态**：确保设备有足够的可用内存
4. **日志输出**：查看LogCat中的详细错误信息

**日志标签：**
- `ImageUpscaler`：库的主要日志
- `TensorFlowLite`：TensorFlow Lite相关日志

通过遵循本指南，您应该能够成功在Android应用中集成和使用wq-image-upscaler-1.4.0.aar库，为用户提供强大的AI图像降噪功能。
---

## 版本历史

### 版本 1.4.0 (2025年11月11日)

- 加入安全验证，保证此SDK只能在特定package中使用

