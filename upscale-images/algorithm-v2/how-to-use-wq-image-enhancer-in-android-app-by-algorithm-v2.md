# 如何在Android应用中使用wq-image-enhancer-1.3.0.aar库

*作者：Jimmy Gan*

*最后更新：2025年12月3日*

*当前版本：v1.3.0*

本指南将详细介绍如何从零开始在Android项目中集成和使用【沃奇】图片降噪增强AAR库（wq-image-enhancer-1.3.0.aar），该库提供高性能的图像降噪和增强功能。

## 目录

1. [库简介](#库简介)
2. [系统要求](#系统要求)
3. [获取AAR库](#获取aar库)
4. [项目集成步骤](#项目集成步骤)
5. [权限配置](#权限配置)
6. [基础使用方法](#基础使用方法)
7. [API参考](#api参考)
8. [参数微调指南](#参数微调指南)
9. [常见问题解答](#常见问题解答)

## 库简介

wq-image-enhancer是一个专为Android开发的图像降噪增强AAR库，具有以下特点：

- **高性能**：处理3000x2250图像耗时小于1秒
- **多种降噪算法**：支持BILATERAL（快速）、FAST_NL_MEANS（高质量）、BM3D（最高质量）
- **可选锐化**：支持Unsharp Mask锐化增强
- **Java友好**：提供阻塞方法，简化Java集成
- **进度回调**：实时进度更新，平滑的用户体验
- **内置依赖**：AAR已包含所有必需库，无需额外配置
- **内存中处理**：直接处理Bitmap，避免文件I/O开销

## 系统要求

- **最低Android版本**：API 24 (Android 7.0)
- **推荐内存**：至少1GB可用内存
- **存储空间**：约60MB（包含native库）

## 获取AAR库

### 方式一：从构建输出获取
```bash
# AAR库文件位置
/path/to/android_use_cpp/my-info/build_android_aar_based_on_opencv/aar-output/wq-image-enhancer-1.3.0.aar
```

### 方式二：自行构建
```bash
cd /path/to/android_use_cpp/my-info/build_android_aar_based_on_opencv
./build_android_aar_based_on_opencv.sh
# 或者指定版本号:
./build_android_aar_based_on_opencv.sh --sdkVersion 1.3.0
```

## 项目集成步骤

### 第1步：复制AAR文件

将AAR文件复制到您的Android项目中：

```bash
# 创建libs目录（如果不存在）
mkdir -p /path/to/your/android/project/app/libs

# 复制AAR文件
cp wq-image-enhancer-1.3.0.aar /path/to/your/android/project/app/libs/
```

### 第2步：配置build.gradle.kts

在您的`app/build.gradle.kts`文件中添加以下依赖：

```kotlin
dependencies {
    // 图像增强AAR（已内置所有依赖）
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    
    // Kotlin Coroutines（AAR需要）
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

**重要提示：** wq-image-enhancer-1.3.0.aar已经内置了所有必需的native库，无需手动添加其他依赖！

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

### Java实现（推荐）

```java
import watchfun.enhance.ImageEnhancer;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {
    private ImageEnhancer imageEnhancer;
    private ExecutorService executorService;
    private Bitmap currentBitmap;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // 初始化图像增强器
        imageEnhancer = new ImageEnhancer(this);
        executorService = Executors.newSingleThreadExecutor();
        
        // 在后台线程中初始化
        executorService.execute(() -> {
            boolean success = imageEnhancer.initializeBlocking();
            runOnUiThread(() -> {
                if (success) {
                    Log.d("ImageEnhancer", "初始化成功");
                } else {
                    Log.e("ImageEnhancer", "初始化失败");
                }
            });
        });
    }
    
    // 图像增强处理
    private void enhanceImage() {
        if (currentBitmap == null) return;
        
        executorService.execute(() -> {
            // 使用阻塞方法处理图像
            ImageEnhancer.EnhanceResult result = imageEnhancer.enhanceBitmapBlocking(
                currentBitmap,                              // 输入Bitmap
                true,                                       // 是否保存到Documents
                ImageEnhancer.DenoiseMethod.BILATERAL,      // 降噪方法
                false,                                      // 启用锐化(默认false,淡海项目建议关闭)
                (Float progress) -> {                       // 进度回调
                    runOnUiThread(() -> {
                        progressText.setText(String.format("处理中(%.0f%%)", progress));
                    });
                    return null;
                }
            );
            
            runOnUiThread(() -> {
                if (result.getSuccess() && result.getOutputBitmap() != null) {
                    // 获取处理后的Bitmap用于显示或进一步处理
                    Bitmap enhancedBitmap = result.getOutputBitmap();
                    imageView.setImageBitmap(enhancedBitmap);
                    
                    // 如果保存了文件，可以获取路径
                    if (result.getOutputPath() != null) {
                        Log.d("ImageEnhancer", "已保存到: " + result.getOutputPath());
                    }
                } else {
                    Toast.makeText(this, "处理失败: " + result.getErrorMessage(), 
                                 Toast.LENGTH_LONG).show();
                }
            });
        });
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (imageEnhancer != null) {
            imageEnhancer.cleanup();
        }
        if (executorService != null) {
            executorService.shutdown();
        }
    }
}
```

## API参考

### ImageEnhancer类

#### 初始化方法

```java
// 创建实例
ImageEnhancer imageEnhancer = new ImageEnhancer(context);

// 阻塞初始化（在后台线程调用）
boolean success = imageEnhancer.initializeBlocking();
```

#### 图像增强方法

```java
// 从Bitmap处理（推荐，速度更快）
ImageEnhancer.EnhanceResult result = imageEnhancer.enhanceBitmapBlocking(
    inputBitmap,           // Bitmap: 输入图像
    saveAfterEnhanced,     // boolean: 是否保存到Documents目录
    denoiseMethod,         // DenoiseMethod: 降噪方法
    enableUnsharpMask,     // boolean: 是否启用锐化(默认false)
    bilateralD,            // int: 双边滤波直径(默认8)
    bilateralSigmaColor,   // double: 颜色sigma(默认50)
    bilateralSigmaSpace,   // double: 空间sigma(默认30)
    bilateralIterations,   // int: 迭代次数(默认2)
    unsharpSigma,          // double: 锐化sigma(默认1.0)
    unsharpAmount,         // double: 锐化强度(默认1.5)
    isDebug,               // boolean: 调试模式(默认false)
    progressCallback       // Function1<Float, Unit>: 进度回调(0-100)
);

// 从文件路径处理
ImageEnhancer.EnhanceResult result = imageEnhancer.enhanceImageBlocking(
    imagePath,             // String: 图像文件路径
    saveAfterEnhanced,     // boolean: 是否保存到Documents目录
    denoiseMethod,         // DenoiseMethod: 降噪方法
    enableUnsharpMask,     // boolean: 是否启用锐化
    progressCallback       // Function1<Float, Unit>: 进度回调(0-100)
);
```

#### 降噪方法枚举

```java
ImageEnhancer.DenoiseMethod.BILATERAL      // 双边滤波 - 最快，边缘保持
ImageEnhancer.DenoiseMethod.FAST_NL_MEANS  // 快速非局部均值 - 较慢，高质量（默认）
ImageEnhancer.DenoiseMethod.BM3D           // BM3D - 最慢，最高质量
```

#### 结果类

```java
ImageEnhancer.EnhanceResult result = ...;

result.getSuccess()        // boolean: 处理是否成功
result.getOutputBitmap()   // Bitmap: 处理后的图像（内存中，可直接用于显示或进一步处理）
result.getOutputPath()     // String: 保存的文件路径（如果saveAfterEnhanced=true）
result.getErrorMessage()   // String: 错误信息（如果失败）
result.getProcessingTimeMs() // long: 处理耗时（毫秒）
```

#### 资源清理

```java
// 使用完毕后清理资源
imageEnhancer.cleanup();
```

## 参数微调指南

详细的参数说明和微调建议请参考: [fine-tune-parameter.md](../fine-tune/fine-tune-parameter.md)

### 默认参数值 (v1.3.0)

```java
// 是否启用锐化 (淡海项目建议关闭以减少伪影噪点)
boolean enableUnsharpMask = false; // 默认: false

// BILATERAL双边滤波参数
int bilateralD = 8;              // 范围: 5-15, 推荐: 8
double bilateralSigmaColor = 50.0; // 范围: 10-150, 推荐: 50
double bilateralSigmaSpace = 30.0; // 范围: 10-150, 推荐: 30
int bilateralIterations = 2;     // 范围: 1-4, 推荐: 2

// Unsharp Mask锐化参数 (仅当enableUnsharpMask=true时生效)
double unsharpSigma = 1.0;       // 范围: 0.5-3.0
double unsharpAmount = 1.5;      // 范围: 0.5-3.0

// 调试模式
boolean isDebug = false;         // true时文件名包含参数值
```

### 调试模式文件命名

当 `isDebug = true` 时，保存的文件名包含参数值:
- 示例: `enhanced_20251203_143109(UnsharpFalse-D8-Color50-Space30-it2-Sigma1.0-Amount1.5).jpg`

## 常见问题解答

### Q1: 如何获取处理后的图像用于进一步处理？

**A:** 使用`result.getOutputBitmap()`获取内存中的Bitmap：

```java
ImageEnhancer.EnhanceResult result = imageEnhancer.enhanceBitmapBlocking(...);
if (result.getSuccess()) {
    Bitmap enhancedBitmap = result.getOutputBitmap();
    // 可以直接用于显示、保存或进一步处理
    imageView.setImageBitmap(enhancedBitmap);
}
```

### Q2: 各降噪方法的区别？

**A:** 
- **BILATERAL**：速度最快，适合实时预览，边缘保持效果好
- **FAST_NL_MEANS**：平衡速度和质量，推荐用于一般场景
- **BM3D**：质量最高，但处理时间较长，适合对质量要求高的场景

### Q3: 处理大图像时如何优化？

**A:** 
- 使用BILATERAL方法获得最快速度
- 在后台线程处理，避免阻塞UI
- 复用ImageEnhancer实例

### Q4: 支持哪些图像格式？

**A:** 支持Android标准Bitmap格式，包括：
- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- BMP (.bmp)

---

## 版本历史

### 版本 1.3.0 (2025年12月3日)

- 优化默认参数值（经Jimmy测试对比，适合淡海项目）
  - enableUnsharpMask默认为false（减少伪影噪点）
  - bilateralD默认为8（平衡速度和效果）
  - bilateralSigmaSpace默认为30（局部降噪保留细节）
  - bilateralIterations默认为2（速度更快）
- 调试模式文件名新增锐化状态标识（UnsharpTrue/UnsharpFalse）
- 构建脚本支持--sdkVersion参数

### 版本 1.0.0 (2025年11月27日)

- 初始版本发布
- 支持三种降噪方法：BILATERAL、FAST_NL_MEANS、BM3D
- 支持Unsharp Mask锐化
- 支持直接Bitmap处理，避免文件I/O开销
- 内置所有依赖，简化集成
- 支持进度回调
- 支持保存到Documents目录

