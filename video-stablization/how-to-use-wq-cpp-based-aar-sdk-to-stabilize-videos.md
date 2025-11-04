# 如何在Android应用中使用wqvideostabilizer-1.2.0.aar库

*作者：Jimmy Gan*

*最后更新：2025年11月4日*

本指南将详细介绍如何从零开始在Android项目中集成和使用【沃奇】视频稳定AAR库（wqvideostabilizer-1.2.0.aar），该库基于FFmpeg和OpenCV技术（如LK光流算法、 GFTT算法、 PFM算法等）提供强大的视频稳定功能。

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

wqvideostabilizer是一个专为Android开发的视频稳定AAR库，具有以下特点：

- **FFmpeg + OpenCV**：基于FFmpeg视频处理和OpenCV计算机视觉技术（如LK光流算法、GFTT特征检测、PFM算法等）
- **三种稳定模式**：轻度、中度、激进三种模式适应不同场景
- **实时进度反馈**：帧级别的处理进度回调
- **自包含设计**：包含所有依赖，无需额外配置
- **Java友好**：纯Java API，简化集成
- **中文支持**：完整的中文API文档和错误信息

## 系统要求

- **最低Android版本**：API 21 (Android 5.0)
- **推荐内存**：至少2GB可用内存
- **存储空间**：约20MB（包含FFmpeg库）
- **处理器**：支持arm64-v8a架构

## 获取AAR库

### 方式一：从构建输出获取
```bash
# AAR库文件位置
/Users/mac/Documents/GitHub/video-stabilization-by-opencv/my-info/build_aar_for_android/android-output/wqvideostabilizer-1.2.0.aar
```

### 方式二：自行构建
```bash
cd /Users/mac/Documents/GitHub/android_use_cpp/my-info/build_android_aar
./build_android_aar_for_video_stabilization.sh
```

## 项目集成步骤

### 第1步：复制AAR文件

将AAR文件复制到您的Android项目中：

```bash
# 创建libs目录（如果不存在）
mkdir -p /path/to/your/android/project/app/libs

# 复制AAR文件
cp wqvideostabilizer-1.2.0.aar /path/to/your/android/project/app/libs/
```

### 第2步：配置build.gradle.kts

在您的`app/build.gradle.kts`文件中添加以下依赖：

```kotlin
dependencies {
    // 视频稳定AAR库（自包含所有依赖）
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    
    // 其他现有依赖...
}
```

**重要提示：** AAR已包含所有必需的依赖（FFmpeg、vidstab、smart-exception），无需额外添加。

### 第3步：同步项目

点击Android Studio的"Sync Now"按钮，或运行：

```bash
./gradlew sync
```

## 权限配置

在`AndroidManifest.xml`中添加必要的权限：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="your.package.name">
    
    <!-- 读取外部存储权限（读取视频文件） -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    
    <!-- 写入外部存储权限（保存稳定后的视频） -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <application
        ...>
        ...
    </application>
</manifest>
```

## 基础使用方法

### Java实现（推荐）

```java
import cn.watchfun.videostabilizer.WQVideoStabilizer;
import cn.watchfun.videostabilizer.StabilizationMode;
import cn.watchfun.videostabilizer.ProgressCallback;
import cn.watchfun.videostabilizer.VideoInfo;

public class MainActivity extends AppCompatActivity {
    private WQVideoStabilizer videoStabilizer;
    private ExecutorService executorService;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // 初始化线程池
        executorService = Executors.newSingleThreadExecutor();
        
        // 初始化视频稳定器
        initializeStabilizer();
    }
    
    private void initializeStabilizer() {
        try {
            // 创建稳定器实例
            videoStabilizer = new WQVideoStabilizer();
            
            // 设置进度回调
            videoStabilizer.setProgressCallback(new ProgressCallback() {
                @Override
                public void onProgress(int stage, int currentFrame, int totalFrames, 
                                      float percentage, String message) {
                    runOnUiThread(() -> {
                        // 更新UI显示进度
                        // message 格式: "[2/4] 分析视频抖动... 23/234 帧 (9.8%)"
                        statusText.setText(message);
                        progressBar.setProgress((int) percentage);
                        
                        Log.d("VideoStabilizer", String.format(
                            "阶段 %d: %d/%d 帧, %.1f%%, %s",
                            stage, currentFrame, totalFrames, percentage, message
                        ));
                    });
                }
            });
            
            Log.i("VideoStabilizer", "视频稳定器初始化成功");
            
        } catch (Exception e) {
            Log.e("VideoStabilizer", "初始化失败", e);
        }
    }
    
    // 稳定视频（在后台线程执行）
    private void stabilizeVideo() {
        String inputPath = "/sdcard/DCIM/input_video.mp4";
        String outputPath = "/sdcard/DCIM/stabilized_video.mp4";
        
        executorService.execute(() -> {
            try {
                // 方式一：使用预设模式
                boolean success = videoStabilizer.stabilizeVideo(
                    inputPath,
                    outputPath,
                    StabilizationMode.AGGRESSIVE  // 激进模式
                );
                
                if (success) {
                    runOnUiThread(() -> {
                        Toast.makeText(this, "视频稳定成功！", Toast.LENGTH_LONG).show();
                    });
                } else {
                    String error = videoStabilizer.getLastError();
                    runOnUiThread(() -> {
                        Toast.makeText(this, "稳定失败: " + error, Toast.LENGTH_LONG).show();
                    });
                }
                
            } catch (Exception e) {
                Log.e("VideoStabilizer", "稳定过程出错", e);
                runOnUiThread(() -> {
                    Toast.makeText(this, "错误: " + e.getMessage(), Toast.LENGTH_LONG).show();
                });
            }
        });
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (executorService != null) {
            executorService.shutdown();
        }
        if (videoStabilizer != null) {
            videoStabilizer.destroy();
        }
    }
}
```

### 完整示例：带UI更新的视频稳定

```java
public class VideoStabilizerActivity extends AppCompatActivity {
    private WQVideoStabilizer videoStabilizer;
    private ExecutorService executorService;
    
    // UI组件
    private Button btnStabilize;
    private ProgressBar progressBar;
    private TextView tvStatus;
    private TextView tvLog;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_stabilizer);
        
        // 初始化UI
        btnStabilize = findViewById(R.id.btnStabilize);
        progressBar = findViewById(R.id.progressBar);
        tvStatus = findViewById(R.id.tvStatus);
        tvLog = findViewById(R.id.tvLog);
        
        // 初始化
        executorService = Executors.newSingleThreadExecutor();
        initializeStabilizer();
        
        // 设置按钮点击事件
        btnStabilize.setOnClickListener(v -> startStabilization());
    }
    
    private void initializeStabilizer() {
        videoStabilizer = new WQVideoStabilizer();
        videoStabilizer.setProgressCallback(new ProgressCallback() {
            @Override
            public void onProgress(int stage, int currentFrame, int totalFrames, 
                                  float percentage, String message) {
                runOnUiThread(() -> {
                    tvStatus.setText(message);
                    progressBar.setIndeterminate(false);
                    progressBar.setProgress((int) percentage);
                    appendLog(message);
                });
            }
        });
    }
    
    private void startStabilization() {
        // 禁用按钮
        btnStabilize.setEnabled(false);
        progressBar.setVisibility(View.VISIBLE);
        progressBar.setIndeterminate(true);
        
        String inputPath = "/sdcard/DCIM/shaky_video.mp4";
        String outputPath = "/sdcard/DCIM/stabilized_" + System.currentTimeMillis() + ".mp4";
        
        executorService.execute(() -> {
            try {
                appendLog("开始视频稳定处理...");
                
                // 获取视频信息
                VideoInfo videoInfo = videoStabilizer.getVideoInfo(inputPath);
                if (videoInfo.valid) {
                    appendLog(String.format("视频信息: %dx%d, %.1f fps, %d 帧",
                        videoInfo.width, videoInfo.height, videoInfo.fps, videoInfo.totalFrames));
                }
                
                // 执行稳定
                boolean success = videoStabilizer.stabilizeVideo(
                    inputPath,
                    outputPath,
                    StabilizationMode.MODERATE  // 中度模式
                );
                
                runOnUiThread(() -> {
                    btnStabilize.setEnabled(true);
                    progressBar.setVisibility(View.GONE);
                    
                    if (success) {
                        tvStatus.setText("稳定完成");
                        appendLog("视频已保存到: " + outputPath);
                        Toast.makeText(this, "稳定成功！", Toast.LENGTH_LONG).show();
                    } else {
                        tvStatus.setText(" 稳定失败");
                        String error = videoStabilizer.getLastError();
                        appendLog(" 错误: " + error);
                        Toast.makeText(this, "失败: " + error, Toast.LENGTH_LONG).show();
                    }
                });
                
            } catch (Exception e) {
                Log.e("VideoStabilizer", "稳定出错", e);
                runOnUiThread(() -> {
                    btnStabilize.setEnabled(true);
                    progressBar.setVisibility(View.GONE);
                    tvStatus.setText(" 出错");
                    appendLog(" 异常: " + e.getMessage());
                });
            }
        });
    }
    
    private void appendLog(String message) {
        runOnUiThread(() -> {
            tvLog.append(message + "\n");
            Log.i("VideoStabilizer", message);
        });
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (executorService != null) {
            executorService.shutdown();
        }
        if (videoStabilizer != null) {
            videoStabilizer.destroy();
        }
    }
}
```

## 高级功能

### 1. 自定义稳定参数

```java
// 使用自定义参数进行稳定
int shakiness = 10;   // 抖动程度 (1-10，越高越激进)
int accuracy = 15;    // 准确度 (1-15，越高越准确)
int smoothing = 50;   // 平滑度 (0-100，越高越平滑)

boolean success = videoStabilizer.stabilizeVideo(
    inputPath,
    outputPath,
    shakiness,
    accuracy,
    smoothing
);
```

### 2. 视频格式转换

```java
// 将AVI转换为MP4
String aviPath = "/sdcard/DCIM/video.avi";
String mp4Path = "/sdcard/DCIM/video.mp4";

boolean success = videoStabilizer.convertToMp4(aviPath, mp4Path);
if (success) {
    Log.i("VideoStabilizer", "转换成功");
}
```

### 3. 创建对比视频

```java
// 创建原始和稳定后的并排对比视频
String originalPath = "/sdcard/DCIM/original.mp4";
String stabilizedPath = "/sdcard/DCIM/stabilized.mp4";
String comparisonPath = "/sdcard/DCIM/comparison.mkv";

boolean success = videoStabilizer.createComparisonVideo(
    originalPath,
    stabilizedPath,
    comparisonPath
);
```

### 4. 取消正在进行的操作

```java
// 在另一个线程中取消操作
videoStabilizer.cancel();
```

### 5. 三种稳定模式详解

```java
// 轻度模式 - 适合轻微抖动
StabilizationMode.LIGHT
// 参数: shakiness=3, accuracy=8, smoothing=20
// 特点: 处理速度快，保留更多原始画面细节

// 中度模式 - 适合一般抖动
StabilizationMode.MODERATE
// 参数: shakiness=5, accuracy=10, smoothing=30
// 特点: 平衡速度和效果，适合大多数场景

// 激进模式 - 适合严重抖动
StabilizationMode.AGGRESSIVE
// 参数: shakiness=10, accuracy=15, smoothing=50
// 特点: 最强稳定效果，处理时间较长
```

### 6. 完整的进度监控示例

```java
videoStabilizer.setProgressCallback(new ProgressCallback() {
    @Override
    public void onProgress(int stage, int currentFrame, int totalFrames, 
                          float percentage, String message) {
        // stage: 当前处理阶段
        //   1 = 转换为MP4
        //   2 = 分析视频抖动
        //   3 = 应用稳定效果
        //   4 = 创建对比视频
        
        // currentFrame: 当前处理的帧号
        // totalFrames: 视频总帧数
        // percentage: 总体进度 (0-100)
        // message: 可读的进度消息
        
        runOnUiThread(() -> {
            // 更新进度条
            progressBar.setProgress((int) percentage);
            
            // 更新状态文本
            statusText.setText(message);
            
            // 详细日志
            if (totalFrames > 0) {
                Log.d("Progress", String.format(
                    "阶段 %d: 帧 %d/%d (%.1f%%)",
                    stage, currentFrame, totalFrames, percentage
                ));
            }
        });
    }
});
```

## 常见问题解答

### Q1: 为什么需要在后台线程执行？

**A:** 视频稳定是CPU密集型操作，可能需要几分钟时间。在主线程执行会导致ANR（应用无响应）。

```java
// 正确 - 使用后台线程
executorService.execute(() -> {
    videoStabilizer.stabilizeVideo(input, output, mode);
});

//  错误 - 在主线程执行
videoStabilizer.stabilizeVideo(input, output, mode);  // 会导致ANR
```

### Q2: 如何选择合适的稳定模式？

**A:** 根据视频抖动程度选择：

- **轻度模式**：手持拍摄，轻微抖动
- **中度模式**：边走边拍，一般抖动（推荐）
- **激进模式**：跑步拍摄，严重抖动

### Q3: 处理大视频时内存不足怎么办？

**A:** 
1. 确保设备有足够可用内存（至少2GB）
2. 关闭其他应用释放内存
3. 考虑先压缩视频分辨率
4. 建议使用轻度模式处理大视频文件
5. 处理前调用 `System.gc()` 释放内存

### Q4: 支持哪些视频格式？

**A:** 
- **输入格式**：MP4, AVI, MOV, MKV等常见格式
- **输出格式**：MP4 (H.264编码)
- **音频**：AAC编码，128kbps

### Q5: 如何处理权限请求？

**A:**
```java
private void checkPermissions() {
    String[] permissions = {
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE
    };
    
    List<String> needed = new ArrayList<>();
    for (String permission : permissions) {
        if (ContextCompat.checkSelfPermission(this, permission)
                != PackageManager.PERMISSION_GRANTED) {
            needed.add(permission);
        }
    }
    
    if (!needed.isEmpty()) {
        ActivityCompat.requestPermissions(this,
            needed.toArray(new String[0]),
            PERMISSION_REQUEST_CODE);
    }
}
```

### Q6: AAR包含哪些依赖？

**A:** AAR是自包含的，包括：
- FFmpeg库（带vidstab支持）
- smart-exception-common
- smart-exception-java
- 所有必需的native库

无需额外添加任何依赖！

## 最佳实践

### 1. 资源管理

```java
@Override
protected void onDestroy() {
    super.onDestroy();
    
    // 关闭线程池
    if (executorService != null) {
        executorService.shutdown();
        try {
            if (!executorService.awaitTermination(5, TimeUnit.SECONDS)) {
                executorService.shutdownNow();
            }
        } catch (InterruptedException e) {
            executorService.shutdownNow();
        }
    }
    
    // 释放稳定器资源
    if (videoStabilizer != null) {
        videoStabilizer.destroy();
        videoStabilizer = null;
    }
}
```

### 2. 错误处理

```java
try {
    boolean success = videoStabilizer.stabilizeVideo(input, output, mode);
    
    if (!success) {
        // 获取详细错误信息
        String error = videoStabilizer.getLastError();
        Log.e("VideoStabilizer", "稳定失败: " + error);
        
        // 向用户显示友好的错误消息
        runOnUiThread(() -> {
            Toast.makeText(this, "处理失败，请重试", Toast.LENGTH_LONG).show();
        });
    }
    
} catch (Exception e) {
    Log.e("VideoStabilizer", "异常", e);
    // 处理异常...
}
```

### 3. 进度显示优化

```java
private long lastUpdateTime = 0;
private static final long UPDATE_INTERVAL = 100; // 100ms更新一次

videoStabilizer.setProgressCallback(new ProgressCallback() {
    @Override
    public void onProgress(int stage, int currentFrame, int totalFrames, 
                          float percentage, String message) {
        long currentTime = System.currentTimeMillis();
        
        // 限制UI更新频率，避免过度刷新
        if (currentTime - lastUpdateTime >= UPDATE_INTERVAL) {
            lastUpdateTime = currentTime;
            
            runOnUiThread(() -> {
                progressBar.setProgress((int) percentage);
                statusText.setText(message);
            });
        }
    }
});
```

### 4. 文件路径处理

```java
// 使用应用私有目录，避免权限问题
File outputDir = new File(getFilesDir(), "stabilized_videos");
if (!outputDir.exists()) {
    outputDir.mkdirs();
}

String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
    .format(new Date());
File outputFile = new File(outputDir, "stabilized_" + timestamp + ".mp4");

String outputPath = outputFile.getAbsolutePath();
```

### 5. 性能优化建议

```java
// 1. 使用单线程池，避免多个视频同时处理
ExecutorService executorService = Executors.newSingleThreadExecutor();

// 2. 处理前检查文件大小
File inputFile = new File(inputPath);
long fileSizeMB = inputFile.length() / (1024 * 1024);
if (fileSizeMB > 500) {
    // 警告用户大文件可能需要较长时间
    Toast.makeText(this, "文件较大，处理可能需要几分钟", Toast.LENGTH_LONG).show();
}

// 3. 提供取消功能
Button btnCancel = findViewById(R.id.btnCancel);
btnCancel.setOnClickListener(v -> {
    videoStabilizer.cancel();
    Toast.makeText(this, "已取消处理", Toast.LENGTH_SHORT).show();
});
```

## API参考

### WQVideoStabilizer类

#### 构造函数
```java
public WQVideoStabilizer()
```
创建视频稳定器实例。

#### 方法

##### setProgressCallback
```java
public void setProgressCallback(ProgressCallback callback)
```
设置进度回调以接收状态更新。

**参数:**
- `callback`: 进度回调接口

##### getVideoInfo
```java
public VideoInfo getVideoInfo(String videoPath)
```
获取视频信息（帧数、时长、尺寸、帧率）。

**参数:**
- `videoPath`: 输入视频文件路径

**返回:** 包含视频元数据的VideoInfo对象

##### convertToMp4
```java
public boolean convertToMp4(String inputPath, String outputPath)
```
将视频转换为MP4格式（如果尚未是MP4）。

**参数:**
- `inputPath`: 输入视频文件路径
- `outputPath`: 输出MP4文件路径

**返回:** 成功返回true，否则返回false

##### stabilizeVideo (预设模式)
```java
public boolean stabilizeVideo(String inputPath, String outputPath, StabilizationMode mode)
```
使用FFmpeg vidstab滤镜稳定视频。

**参数:**
- `inputPath`: 输入视频文件路径
- `outputPath`: 输出稳定后视频文件路径
- `mode`: 稳定模式 (LIGHT, MODERATE, AGGRESSIVE)

**返回:** 成功返回true，否则返回false

##### stabilizeVideo (自定义参数)
```java
public boolean stabilizeVideo(String inputPath, String outputPath, 
                             int shakiness, int accuracy, int smoothing)
```
使用自定义参数稳定视频。

**参数:**
- `inputPath`: 输入视频文件路径
- `outputPath`: 输出稳定后视频文件路径
- `shakiness`: 抖动程度参数 (1-10，越高越激进)
- `accuracy`: 准确度参数 (1-15，越高越准确)
- `smoothing`: 平滑度参数 (0-100，越高越平滑)

**返回:** 成功返回true，否则返回false

##### createComparisonVideo
```java
public boolean createComparisonVideo(String originalPath, String stabilizedPath, String outputPath)
```
创建对比视频（原始和稳定后并排）。

**参数:**
- `originalPath`: 原始视频文件路径
- `stabilizedPath`: 稳定后视频文件路径
- `outputPath`: 输出对比视频文件路径

**返回:** 成功返回true，否则返回false

##### cancel
```java
public void cancel()
```
取消当前操作。

##### getLastError
```java
public String getLastError()
```
获取最后的错误消息。

**返回:** 错误消息字符串

##### destroy
```java
public void destroy()
```
释放资源。当不再使用稳定器时调用此方法。

### ProgressCallback接口

```java
public interface ProgressCallback {
    void onProgress(int stage, int currentFrame, int totalFrames, 
                   float percentage, String message);
}
```

**参数:**
- `stage`: 当前处理阶段 (1-4)
- `currentFrame`: 当前正在处理的帧号
- `totalFrames`: 视频总帧数
- `percentage`: 总体进度百分比 (0-100)
- `message`: 可读的进度消息

### StabilizationMode枚举

```java
public enum StabilizationMode {
    LIGHT,       // 轻度: shakiness=3, accuracy=8, smoothing=20
    MODERATE,    // 中度: shakiness=5, accuracy=10, smoothing=30
    AGGRESSIVE;  // 激进: shakiness=10, accuracy=15, smoothing=50
}
```

### VideoInfo类

```java
public class VideoInfo {
    public final int totalFrames;    // 总帧数
    public final long durationMs;    // 时长（毫秒）
    public final int width;          // 宽度
    public final int height;         // 高度
    public final double fps;         // 帧率
    public final boolean valid;      // 是否有效
}
```

## 技术支持

如有问题或建议，请联系：

- **作者**: Jimmy Gan
- **邮箱**: jimmy@watchfun.cn
---

**版本历史:**

- **v1.2.0** (2025-11-04)
  - 添加详细的帧级进度反馈
  - 包含所有依赖，真正自包含
  - 完整的中文API文档
  - 优化性能和内存使用

- **v1.0.0** (2025-11-01)
  - 初始版本发布
  - 基础视频稳定功能
  - 三种预设模式
