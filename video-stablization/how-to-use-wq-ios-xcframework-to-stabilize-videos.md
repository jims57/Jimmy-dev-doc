# 如何在iOS应用中使用WQVideoStabilizer.xcframework库

*作者：Jimmy Gan*

*最后更新：2025年11月21日*

本指南将详细介绍如何从零开始在iOS项目中集成和使用【沃奇】视频稳定XCFramework库（WQVideoStabilizer.xcframework），该库基于先进的视频处理技术提供强大的视频稳定功能。

## 目录

1. [库简介](#库简介)
2. [系统要求](#系统要求)
3. [获取XCFramework库](#获取xcframework库)
4. [项目集成步骤](#项目集成步骤)
5. [权限配置](#权限配置)
6. [基础使用方法](#基础使用方法)
7. [API参考](#api参考)
8. [常见问题解答](#常见问题解答)
9. [最佳实践](#最佳实践)
10. [技术细节](#技术细节)

## 库简介

WQVideoStabilizer是一个专为iOS开发的视频稳定XCFramework库，具有以下特点：

- **先进算法**：基于业界领先的视频处理和稳定算法
- **动态框架**：使用动态库架构，支持代码共享和扩展
- **多架构支持**：支持arm64和arm64e架构（iPhone真机）
- **Objective-C/Swift兼容**：可在Objective-C和Swift项目中使用
- **完整依赖**：包含所有FFmpeg依赖框架
- **生产就绪**：经过测试的稳定API

## 系统要求

- **最低iOS版本**：iOS 13.0
- **支持架构**：arm64, arm64e（iPhone真机）
- **Xcode版本**：Xcode 12.0或更高
- **开发语言**：Objective-C或Swift
- **推荐内存**：至少2GB可用内存
- **存储空间**：约150MB（包含所有FFmpeg框架）

## 获取XCFramework库

### 方式一：从构建输出获取

```bash
# XCFramework库文件位置
/Users/mac/Documents/GitHub/ios_use_cpp_demo/my-info/build_ios_xcframework/xcframework-output/WQVideoStabilizer.xcframework

# FFmpeg依赖框架位置
/Users/mac/Documents/GitHub/ffmpeg-kit/prebuilt/bundle-apple-xcframework-ios/
```

### 方式二：自行构建

```bash
cd /Users/mac/Documents/GitHub/ios_use_cpp_demo/my-info/build_ios_xcframework
./build_ios_xcframework_for_video_stabilization.sh
```

构建完成后，所有XCFramework会自动复制到iOS项目目录。

## 项目集成步骤

### 第1步：复制XCFramework文件

将所有XCFramework文件复制到您的iOS项目中：

```bash
# 复制到您的iOS项目目录
cp -R WQVideoStabilizer.xcframework /path/to/your/ios/project/
cp -R ffmpegkit.xcframework /path/to/your/ios/project/
cp -R libavcodec.xcframework /path/to/your/ios/project/
cp -R libavdevice.xcframework /path/to/your/ios/project/
cp -R libavfilter.xcframework /path/to/your/ios/project/
cp -R libavformat.xcframework /path/to/your/ios/project/
cp -R libavutil.xcframework /path/to/your/ios/project/
cp -R libswresample.xcframework /path/to/your/ios/project/
cp -R libswscale.xcframework /path/to/your/ios/project/
```

**重要：** 必须复制所有9个XCFramework文件，WQVideoStabilizer依赖所有FFmpeg框架。

### 第2步：在Xcode中添加XCFramework

1. 在Xcode中打开您的项目
2. 选择项目文件（.xcodeproj）
3. 选择您的Target
4. 点击"General"标签页
5. 滚动到"Frameworks, Libraries, and Embedded Content"部分
6. 点击"+"按钮
7. 点击"Add Other..." -> "Add Files..."
8. 选择所有9个XCFramework文件

### 第3步：配置为"Embed & Sign"（关键步骤）

**非常重要：** 由于这些是动态框架，必须设置为"Embed & Sign"。

在"Frameworks, Libraries, and Embedded Content"中，将所有XCFramework的嵌入方式设置为**"Embed & Sign"**：

- ✅ WQVideoStabilizer.xcframework -> **Embed & Sign**
- ✅ ffmpegkit.xcframework -> **Embed & Sign**
- ✅ libavcodec.xcframework -> **Embed & Sign**
- ✅ libavdevice.xcframework -> **Embed & Sign**
- ✅ libavfilter.xcframework -> **Embed & Sign**
- ✅ libavformat.xcframework -> **Embed & Sign**
- ✅ libavutil.xcframework -> **Embed & Sign**
- ✅ libswresample.xcframework -> **Embed & Sign**
- ✅ libswscale.xcframework -> **Embed & Sign**

**为什么必须是Embed & Sign？**
- 这些是动态库（.dylib），不是静态库（.a）
- 动态库必须嵌入到app bundle中才能运行
- 如果只设置为"Do Not Embed"，应用在真机上会崩溃并显示：`dyld: Library not loaded`

### 第4步：验证配置

构建项目（Command+B），确保没有错误。如果出现链接错误，请检查：

1. 所有9个XCFramework都已添加
2. 所有框架都设置为"Embed & Sign"
3. 框架路径正确
4. Build Settings中的"Framework Search Paths"包含框架目录

## 权限配置

在`Info.plist`中添加必要的权限说明：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>我们需要访问您的照片库来选择需要稳定的视频</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>我们需要保存稳定后的视频到您的照片库</string>

<key>NSCameraUsageDescription</key>
<string>我们需要访问相机来录制视频</string>
```

**或者在Xcode中配置：**

1. 选择项目 -> Target -> Info
2. 添加以下条目：
   - Privacy - Photo Library Usage Description
   - Privacy - Photo Library Additions Usage Description
   - Privacy - Camera Usage Description

## 基础使用方法

### Objective-C实现

```objc
#import <WQVideoStabilizer/WQVideoStabilizer.h>
#import <WQVideoStabilizer/ios_file_wrapper.h>

@interface ViewController ()
@property (nonatomic, strong) WQVideoStabilizerImpl *videoStabilizer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化视频稳定器
    self.videoStabilizer = [[WQVideoStabilizerImpl alloc] init];
}

- (void)stabilizeVideo {
    NSString *inputPath = [[NSBundle mainBundle] pathForResource:@"shaky_video" ofType:@"mp4"];
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"stabilized.mp4"];
    
    // 在后台线程执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        BOOL success = [self.videoStabilizer stabilizeVideo:inputPath
                                                 outputPath:outputPath
                                                      error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSLog(@"视频稳定成功: %@", outputPath);
                [self showAlert:@"成功" message:@"视频稳定完成"];
            } else {
                NSLog(@"视频稳定失败: %@", error.localizedDescription);
                [self showAlert:@"失败" message:error.localizedDescription];
            }
        });
    });
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
```

### Swift实现

```swift
import UIKit
import WQVideoStabilizer

class ViewController: UIViewController {
    
    private let videoStabilizer = WQVideoStabilizerImpl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func stabilizeVideo() {
        guard let inputPath = Bundle.main.path(forResource: "shaky_video", ofType: "mp4") else {
            print("找不到输入视频")
            return
        }
        
        let outputPath = NSTemporaryDirectory() + "stabilized.mp4"
        
        // 在后台线程执行
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let success = try self.videoStabilizer.stabilizeVideo(inputPath,
                                                                      outputPath: outputPath)
                
                DispatchQueue.main.async {
                    if success {
                        print("视频稳定成功: \(outputPath)")
                        self.showAlert(title: "成功", message: "视频稳定完成")
                    } else {
                        self.showAlert(title: "失败", message: "视频稳定失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("视频稳定出错: \(error.localizedDescription)")
                    self.showAlert(title: "错误", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
```

### 带进度显示的完整示例

```objc
@interface ViewController ()
@property (nonatomic, strong) WQVideoStabilizerImpl *videoStabilizer;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化UI
    [self setupUI];
    
    // 初始化视频稳定器
    self.videoStabilizer = [[WQVideoStabilizerImpl alloc] init];
}

- (void)setupUI {
    // 进度条
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(20, 200, self.view.bounds.size.width - 40, 20);
    [self.view addSubview:self.progressView];
    
    // 状态标签
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 230, self.view.bounds.size.width - 40, 30)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];
    
    // 开始按钮
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [startButton setTitle:@"开始稳定视频" forState:UIControlStateNormal];
    startButton.frame = CGRectMake(20, 270, self.view.bounds.size.width - 40, 44);
    [startButton addTarget:self action:@selector(startStabilization) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
}

- (void)startStabilization {
    NSString *inputPath = [[NSBundle mainBundle] pathForResource:@"shaky_video" ofType:@"mp4"];
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"stabilized.mp4"];
    
    // 重置UI
    self.progressView.progress = 0.0;
    self.statusLabel.text = @"准备中...";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        
        // 获取视频信息
        int totalFrames = [WQVideoStabilizerImpl getTotalFrames:inputPath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusLabel.text = [NSString stringWithFormat:@"视频总帧数: %d", totalFrames];
        });
        
        // 执行稳定
        BOOL success = [self.videoStabilizer stabilizeVideo:inputPath
                                                 outputPath:outputPath
                                                      error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                self.progressView.progress = 1.0;
                self.statusLabel.text = @"稳定完成";
                [self showAlert:@"成功" message:@"视频已保存"];
            } else {
                self.statusLabel.text = @"稳定失败";
                [self showAlert:@"失败" message:error.localizedDescription];
            }
        });
    });
}

@end
```

## API参考

### WQVideoStabilizerImpl类

#### 初始化

```objc
// Objective-C
WQVideoStabilizerImpl *stabilizer = [[WQVideoStabilizerImpl alloc] init];

// Swift
let stabilizer = WQVideoStabilizerImpl()
```

#### 稳定视频

```objc
// Objective-C
- (BOOL)stabilizeVideo:(NSString *)inputPath
            outputPath:(NSString *)outputPath
                 error:(NSError **)error;

// Swift
func stabilizeVideo(_ inputPath: String, outputPath: String) throws -> Bool
```

**参数：**
- `inputPath`: 输入视频文件的完整路径
- `outputPath`: 输出稳定后视频的完整路径
- `error`: 错误信息（如果失败）

**返回值：**
- 成功返回`YES`/`true`
- 失败返回`NO`/`false`，并通过error参数返回错误信息

#### 获取视频总帧数

```objc
// Objective-C
+ (int)getTotalFrames:(NSString *)videoPath;

// Swift
class func getTotalFrames(_ videoPath: String) -> Int32
```

**参数：**
- `videoPath`: 视频文件路径

**返回值：**
- 视频总帧数

### ios_file_wrapper辅助函数

```objc
// 创建临时文件路径
NSString *createTempFilePath(NSString *extension);

// 示例
NSString *tempPath = createTempFilePath(@"mp4");
```

## 常见问题解答

### Q1: 为什么必须设置为"Embed & Sign"？

**A:** 因为这些是动态库（.dylib），不是静态库（.a）。动态库必须嵌入到app bundle中才能在运行时加载。如果不嵌入，应用会在启动时崩溃并显示：

```
dyld: Library not loaded: @rpath/WQVideoStabilizer.framework/WQVideoStabilizer
Reason: image not found
```

### Q2: 为什么需要所有9个XCFramework？

**A:** WQVideoStabilizer依赖FFmpeg的所有组件：

- **ffmpegkit**: FFmpeg主框架
- **libavcodec**: 编解码器
- **libavformat**: 格式处理
- **libavfilter**: 视频滤镜处理
- **libavutil**: 工具函数
- **libavdevice**: 设备支持
- **libswscale**: 图像缩放
- **libswresample**: 音频重采样

缺少任何一个都会导致链接错误。

### Q3: 支持哪些视频格式？

**A:**
- **输入格式**: MP4, MOV, AVI, MKV等FFmpeg支持的格式
- **输出格式**: MP4 (H.264编码)
- **音频**: AAC编码

### Q4: 处理大视频时如何避免内存问题？

**A:**
1. 在后台线程处理，避免阻塞主线程
2. 处理前检查可用内存
3. 考虑先压缩视频分辨率
4. 监控内存使用情况

### Q5: 为什么在模拟器上无法使用？

**A:** 这些XCFramework只包含真机架构（arm64, arm64e），不包含模拟器架构（x86_64, arm64-simulator）。必须在真机上测试。

### Q6: 如何处理iOS沙盒限制？

**A:** iOS沙盒会限制文件访问。建议：

1. 使用应用的临时目录：`NSTemporaryDirectory()`
2. 使用Documents目录：`NSSearchPathForDirectoriesInDomains()`
3. 使用Photos框架保存到相册

```objc
// 使用临时目录
NSString *tempDir = NSTemporaryDirectory();
NSString *outputPath = [tempDir stringByAppendingPathComponent:@"stabilized.mp4"];

// 使用Documents目录
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentsDir = [paths firstObject];
NSString *outputPath = [documentsDir stringByAppendingPathComponent:@"stabilized.mp4"];
```

## 最佳实践

### 1. 后台线程处理

```objc
// 始终在后台线程处理视频
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self.videoStabilizer stabilizeVideo:input outputPath:output error:&error];
    
    // 完成后回到主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新UI
    });
});
```

### 2. 错误处理

```objc
NSError *error = nil;
BOOL success = [self.videoStabilizer stabilizeVideo:input
                                         outputPath:output
                                              error:&error];

if (!success) {
    NSLog(@"稳定失败: %@", error.localizedDescription);
    NSLog(@"错误代码: %ld", (long)error.code);
    NSLog(@"错误域: %@", error.domain);
    
    // 向用户显示友好的错误消息
    [self showErrorAlert:error];
}
```

### 3. 内存管理

```objc
- (void)dealloc {
    // 清理资源
    self.videoStabilizer = nil;
}
```

### 4. 文件路径管理

```objc
- (NSString *)generateOutputPath {
    NSString *tempDir = NSTemporaryDirectory();
    NSString *timestamp = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    NSString *filename = [NSString stringWithFormat:@"stabilized_%@.mp4", timestamp];
    return [tempDir stringByAppendingPathComponent:filename];
}
```

### 5. 权限检查

```objc
#import <Photos/Photos.h>

- (void)checkPhotoLibraryPermission {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                // 已授权
            }
        }];
    } else if (status == PHAuthorizationStatusAuthorized) {
        // 已授权
    } else {
        // 未授权，显示提示
        [self showPermissionAlert];
    }
}
```

## 技术细节

### 动态库架构

所有XCFramework都是动态库：

```bash
# 验证库类型
file WQVideoStabilizer.xcframework/ios-arm64/WQVideoStabilizer.framework/WQVideoStabilizer
# 输出: Mach-O 64-bit dynamically linked shared library arm64
```

### 框架依赖关系

```
WQVideoStabilizer.xcframework
├── ffmpegkit.xcframework
├── libavformat.xcframework
│   ├── libavcodec.xcframework
│   └── libavutil.xcframework
├── libavfilter.xcframework (视频稳定滤镜)
│   ├── libavcodec.xcframework
│   └── libavutil.xcframework
├── libswscale.xcframework
├── libswresample.xcframework
└── libavdevice.xcframework
```

### 运行时加载

动态库在运行时通过`@rpath`加载：

```
install_name: @rpath/WQVideoStabilizer.framework/WQVideoStabilizer
```

Xcode会自动设置正确的rpath：

```
@executable_path/Frameworks
```

### 构建配置

如果需要手动配置Build Settings：

- **Framework Search Paths**: `$(PROJECT_DIR)`
- **Runpath Search Paths**: `@executable_path/Frameworks`
- **Enable Bitcode**: `NO` (FFmpeg不支持Bitcode)

## 技术支持

如有问题或建议，请联系：

- **作者**: Jimmy Gan
- **邮箱**: jimmy@watchfun.cn

---

**版本历史:**

- **v1.0.0** (2025-11-21)
  - 初始iOS版本发布
  - 基于先进的视频稳定算法
  - 动态XCFramework架构
  - 支持arm64/arm64e架构
  - 完整的Objective-C/Swift API
