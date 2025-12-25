# 如何在Android应用中使用水印功能

*作者：Jimmy Gan*

*最后更新：2025年12月25日*

*版本：v1.8.0*

本指南介绍如何在Android项目中使用WQStyleFilter AAR库的水印功能。

**本版本包含两个AAR文件：**
- `wq-ffmpeg-kit-1.0.0.aar` (33MB) - 基础库
- `wq-ffmpeg-style-filter-1.8.0.aar` (20KB) - 功能SDK（包含水印和风格滤镜）

> 如需了解更多关于AAR集成、为什么使用独立AAR、风格滤镜功能等详细信息，请参考：[how-to-use-wq-style-filter-in-android-app-v2.md](../style-filter/ffmpeg-based/how-to-use-wq-style-filter-in-android-app-v2.md)

## 快速开始

### 1. 添加AAR依赖

```kotlin
// app/build.gradle.kts
dependencies {
    implementation(files("libs/wq-ffmpeg-kit-1.0.0.aar"))
    implementation(files("libs/wq-ffmpeg-style-filter-1.8.0.aar"))
    implementation("com.arthenica:smart-exception-java:0.2.1")
}
```

### 2. 准备水印图片

将水印PNG图片放入assets目录：

```
app/src/main/assets/
└── watermark-png/
    └── 水印图片.png
```

### 3. 添加水印（最简化API）

```java
import cn.watchfun.stylefilter.WQStyleFilter;

// 初始化
WQStyleFilter styleFilter = new WQStyleFilter(context);
ExecutorService executorService = Executors.newSingleThreadExecutor();

// 在后台线程添加水印
executorService.execute(() -> {
    // 最简化API - 输入图像和水印都从assets加载
    WQStyleFilter.WatermarkResult result = styleFilter.addWatermarkFromAssets(
            "your-image.jpg",           // 输入图像在assets中的路径
            "watermark-png/水印图片.png"  // 水印图像在assets中的路径
    );
    
    // 处理结果
    runOnUiThread(() -> {
        if (result.getSuccess()) {
            imageView.setImageBitmap(result.getOutputBitmap());
        } else {
            Toast.makeText(context, "水印添加失败: " + result.getErrorMessage(), Toast.LENGTH_SHORT).show();
        }
    });
});
```

## 水印API参考

### WatermarkPosition 枚举

| 位置 | 说明 |
|------|------|
| `TOP_LEFT` | 左上角 |
| `TOP_RIGHT` | 右上角 |
| `BOTTOM_LEFT` | 左下角 |
| `BOTTOM_RIGHT` | 右下角 |
| `CENTER` | 居中 |
| `BOTTOM_CENTER` | 底部居中（默认） |

### WatermarkResult 类

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `getSuccess()` | 处理是否成功 | `boolean` |
| `getOutputBitmap()` | 获取处理后的Bitmap | `Bitmap` |
| `getErrorMessage()` | 获取错误信息 | `String` |
| `getProcessingTime()` | 获取处理耗时(ms) | `long` |

### 水印方法

#### 1. 最简化API（推荐）

```java
// 使用默认位置（底部居中）和边距（100像素）
WatermarkResult addWatermarkFromAssets(String inputAssetPath, String watermarkAssetPath)

// 自定义位置和边距
WatermarkResult addWatermarkFromAssets(
    String inputAssetPath,      // 输入图像在assets中的路径
    String watermarkAssetPath,  // 水印图像在assets中的路径
    WatermarkPosition position, // 水印位置
    int margin,                 // 水印距离底边的距离（像素）
    boolean isDebug             // 是否打印调试日志
)
```

#### 2. 文件路径API

```java
// 使用绝对文件路径
WatermarkResult addWatermarkBlocking(
    String inputImagePath,      // 输入图像的绝对路径
    String watermarkImagePath,  // 水印图像的绝对路径
    String outputPath,          // 输出路径（可为null）
    WatermarkPosition position, // 水印位置
    int margin,                 // 水印距离底边的距离（像素）
    boolean isDebug             // 是否打印调试日志
)
```

#### 3. 带缩放的水印

```java
// 可以缩放水印大小
WatermarkResult addWatermarkWithScaleBlocking(
    String inputImagePath,
    String watermarkImagePath,
    String outputPath,
    WatermarkPosition position,
    int margin,
    float watermarkScale,  // 缩放比例：0.5=50%, 2.0=200%
    boolean isDebug
)
```

## 完整示例

```java
public class WatermarkActivity extends AppCompatActivity {
    private WQStyleFilter styleFilter;
    private ExecutorService executorService;
    private ImageView imageView;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_watermark);
        
        styleFilter = new WQStyleFilter(this);
        executorService = Executors.newSingleThreadExecutor();
        imageView = findViewById(R.id.imageView);
    }
    
    // 添加水印按钮点击事件
    private void addWatermark() {
        executorService.execute(() -> {
            // 使用简化API添加水印
            WQStyleFilter.WatermarkResult result = styleFilter.addWatermarkFromAssets(
                    "sample-image.jpg",
                    "watermark-png/水印图片.png",
                    WQStyleFilter.WatermarkPosition.BOTTOM_CENTER,
                    100,    // 距离底边100像素
                    false   // 不打印调试日志
            );
            
            runOnUiThread(() -> {
                if (result.getSuccess()) {
                    // 显示结果
                    imageView.setImageBitmap(result.getOutputBitmap());
                    
                    // 可选：保存到Documents文件夹
                    String savedPath = styleFilter.saveBitmapToDocuments(
                            result.getOutputBitmap(), 
                            "watermark"
                    );
                    if (savedPath != null) {
                        Toast.makeText(this, "已保存: " + savedPath, Toast.LENGTH_LONG).show();
                    }
                } else {
                    Toast.makeText(this, "失败: " + result.getErrorMessage(), Toast.LENGTH_SHORT).show();
                }
            });
        });
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (executorService != null) {
            executorService.shutdown();
        }
    }
}
```

## 注意事项

1. **后台线程**：水印处理是耗时操作，必须在后台线程执行
2. **水印格式**：推荐使用PNG格式水印，支持透明背景
3. **内存管理**：处理完成后，AAR会自动清理临时文件
4. **权限**：如需保存到Documents文件夹，需要存储权限

## 技术支持

**日志标签：** `WQStyleFilter`

如遇问题，请在LogCat中查看WQStyleFilter标签的日志输出。