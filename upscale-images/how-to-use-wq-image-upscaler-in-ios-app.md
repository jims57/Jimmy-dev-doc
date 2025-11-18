# 如何在iOS应用中使用WQImageUpscaler.xcframework库

*作者：Jimmy Gan*

*最后更新：2025年11月18日*

本指南将详细介绍如何从零开始在iOS项目中集成和使用【沃奇】图片降噪增强XCFramework库（WQImageUpscaler.xcframework），该库基于AI模型提供强大的图像降噪功能。

## 目录

1. [库简介](#库简介)
2. [系统要求](#系统要求)
3. [获取XCFramework库](#获取xcframework库)
4. [项目集成步骤](#项目集成步骤)
5. [基础使用方法](#基础使用方法)
6. [高级功能](#高级功能)
7. [常见问题解答](#常见问题解答)
8. [最佳实践](#最佳实践)
9. [控制台日志说明](#控制台日志说明)

## 库简介

WQImageUpscaler是一个专为iOS开发的图像降噪XCFramework库，具有以下特点：

- **AI驱动**：基于深度学习模型
- **4倍放大**：支持图像4倍降噪增强
- **硬件加速**：自动GPU (Metal)加速，智能CPU回退
- **内存优化**：自动瓦片处理，防止大图像内存溢出
- **静态框架**：静态链接，减小应用体积，加快启动速度
- **中文支持**：完整的中文API文档和控制台日志
- **智能回退**：自动检测设备兼容性，GPU失败时自动切换CPU

## 系统要求

- **最低iOS版本**：iOS 15.0+
- **支持架构**：arm64（真机）
- **推荐内存**：至少2GB可用内存（处理大图像时）
- **存储空间**：约10MB（包含AI模型和TensorFlow Lite依赖）
- **硬件加速**：支持Metal的设备（可选，但推荐）

**注意**：本库仅支持真机运行，不支持模拟器。

## 获取XCFramework库

### 方式一：从构建输出获取

```bash
# XCFramework库文件位置
/path/to/ios_use_cpp_demo/my-info/build_ios_xcframework/build/WQImageUpscaler.xcframework

# TensorFlow Lite依赖库位置
/path/to/ios_use_cpp_demo/my-info/build_ios_xcframework/other-xcframeworks/TensorFlowLiteC.xcframework
/path/to/ios_use_cpp_demo/my-info/build_ios_xcframework/other-xcframeworks/TensorFlowLiteCMetal.xcframework
/path/to/ios_use_cpp_demo/my-info/build_ios_xcframework/other-xcframeworks/TensorFlowLiteCCoreML.xcframework

# AI模型文件
/path/to/ios_use_cpp_demo/my-info/build_ios_xcframework/model.tflite
```

### 方式二：自行构建

```bash
cd /path/to/ios_use_cpp_demo/my-info/build_ios_xcframework
./build_ios_xcframework_for_denoising_image.sh
```

构建成功后，所有文件会自动复制到iOS项目目录。

## 项目集成步骤

### 第1步：添加XCFramework到Xcode项目

1. 打开您的Xcode项目
2. 将以下4个XCFramework拖入项目导航器：
   - `WQImageUpscaler.xcframework`
   - `TensorFlowLiteC.xcframework`
   - `TensorFlowLiteCMetal.xcframework`
   - `TensorFlowLiteCCoreML.xcframework`

3. 在弹出的对话框中：
   - ✅ 勾选 "Copy items if needed"
   - ✅ 选择您的应用target
   - 点击 "Finish"

### 第2步：配置框架链接方式

1. 选择您的项目 → 选择应用target → 点击 "General" 标签
2. 滚动到 "Frameworks, Libraries, and Embedded Content" 部分
3. 找到刚添加的4个XCFramework
4. 将它们的嵌入方式设置为 **"Do Not Embed"**（静态框架不需要嵌入）

**重要提示**：静态框架使用"Do Not Embed"，动态框架才使用"Embed & Sign"。

### 第3步：添加AI模型文件

1. 将 `model.tflite` 文件拖入Xcode项目
2. 在弹出的对话框中：
   - ✅ 勾选 "Copy items if needed"
   - ✅ 勾选 "Add to targets"（选择您的应用target）
   - 点击 "Finish"

3. 验证模型文件已添加到 "Copy Bundle Resources"：
   - 选择项目 → Target → Build Phases
   - 展开 "Copy Bundle Resources"
   - 确认 `model.tflite` 在列表中

**关键步骤**：模型文件必须添加到"Copy Bundle Resources"，否则运行时会找不到模型。

### 第4步：同步项目

在Xcode中按 `Cmd+B` 构建项目，确保没有编译错误。

## 基础使用方法

### Swift实现（推荐）

```swift
import UIKit
import WQImageUpscaler

class ViewController: UIViewController {
    private var imageUpscaler: WQImageUpscaler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化图像增强器
        imageUpscaler = WQImageUpscaler()
        
        // 在后台线程初始化
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.imageUpscaler?.initialize()
                
                DispatchQueue.main.async {
                    print("图像增强器初始化成功")
                    // 可以开始处理图像
                }
            } catch {
                DispatchQueue.main.async {
                    print("初始化失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 图像降噪处理
    func upscaleImage(imagePath: String) {
        guard let upscaler = imageUpscaler else {
            print("图像增强器未初始化")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 处理图像
            let result = upscaler.upscaleImage(
                atPath: imagePath,
                saveAfterUpscaled: false,        // 是否保存到Documents
                smallerImageByPercentage: 0.75,  // 缩小75%（保留25%）
                resizeAfterUpscale: true         // 处理后恢复原始尺寸
            )
            
            DispatchQueue.main.async {
                if result.success {
                    // 处理成功
                    if let outputImage = result.outputImage {
                        self?.imageView.image = outputImage
                    }
                    
                    // 显示处理时间
                    let processingTime = result.processingTimeMs
                    print("处理完成，耗时: \(processingTime)ms")
                    
                    // 显示输出尺寸
                    if let sizeInfo = result.outputSizeInfo {
                        print("输出尺寸: \(sizeInfo)")
                    }
                } else {
                    // 处理失败
                    if let errorMsg = result.errorMessage {
                        print("处理失败: \(errorMsg)")
                    }
                }
            }
        }
    }
    
    deinit {
        // 清理资源
        imageUpscaler?.cleanup()
    }
}
```

### Objective-C实现

```objc
#import <WQImageUpscaler/WQImageUpscaler-Swift.h>

@interface ViewController ()
@property (nonatomic, strong) WQImageUpscaler *imageUpscaler;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化图像增强器
    self.imageUpscaler = [[WQImageUpscaler alloc] init];
    
    // 在后台线程初始化
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        [self.imageUpscaler initializeAndReturnError:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"初始化失败: %@", error.localizedDescription);
            } else {
                NSLog(@"图像增强器初始化成功");
            }
        });
    });
}

- (void)upscaleImageWithPath:(NSString *)imagePath {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WQUpscaleResult *result = [self.imageUpscaler upscaleImageAtPath:imagePath
                                                       saveAfterUpscaled:NO
                                                smallerImageByPercentage:0.75
                                                      resizeAfterUpscale:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result.success) {
                // 处理成功
                if (result.outputImage) {
                    self.imageView.image = result.outputImage;
                }
                NSLog(@"处理完成，耗时: %ldms", (long)result.processingTimeMs);
            } else {
                // 处理失败
                NSLog(@"处理失败: %@", result.errorMessage);
            }
        });
    });
}

- (void)dealloc {
    [self.imageUpscaler cleanup];
}

@end
```

## 高级功能

### 1. 不同的处理模式

```swift
// 标准4倍降噪（不缩小，不恢复尺寸）
let result = imageUpscaler.upscaleImage(
    atPath: imagePath,
    saveAfterUpscaled: false,
    smallerImageByPercentage: 0.0,
    resizeAfterUpscale: false
)

// 先缩小75%再处理（适合大图像，保留25%尺寸）
let result = imageUpscaler.upscaleImage(
    atPath: imagePath,
    saveAfterUpscaled: false,
    smallerImageByPercentage: 0.75,
    resizeAfterUpscale: false
)

// 处理后恢复到原始尺寸（推荐）
let result = imageUpscaler.upscaleImage(
    atPath: imagePath,
    saveAfterUpscaled: false,
    smallerImageByPercentage: 0.75,
    resizeAfterUpscale: true
)

// 保存处理结果到Documents目录
let result = imageUpscaler.upscaleImage(
    atPath: imagePath,
    saveAfterUpscaled: true,
    smallerImageByPercentage: 0.75,
    resizeAfterUpscale: true
)
```

**参数说明：**
- `imagePath`: 图像文件路径（完整路径）
- `saveAfterUpscaled`: 是否保存到Documents目录（开发测试用）
- `smallerImageByPercentage`: 缩小百分比（0.0=不缩小，0.75=缩小75%保留25%）
- `resizeAfterUpscale`: 是否恢复到原始尺寸（使用专业多步骤降采样算法）

### 2. 硬件加速（自动处理）

**重要更新**：XCFramework现在自动处理硬件加速，无需手动指定！

```swift
// XCFramework内部自动处理：
// 1. 首先尝试GPU (Metal)（如果设备支持）
// 2. 如果GPU失败，自动回退到CPU
// 3. 自动选择最佳线程数（4-8线程，基于CPU核心数）

// 您只需调用方法，XCFramework会自动选择最佳硬件加速方式
let result = imageUpscaler.upscaleImage(
    atPath: imagePath,
    saveAfterUpscaled: false,
    smallerImageByPercentage: 0.75,
    resizeAfterUpscale: true
)

// 检查当前使用的加速类型（可选）
let accelerationType = imageUpscaler.getCurrentAccelerationType()
print("当前加速类型: \(accelerationType)") // "GPU (Metal)" 或 "CPU"
```

**自动优化特性：**
- GPU (Metal) 优先（性能提升2-3倍）
- 自动CPU回退（保证100%兼容性）
- 自适应线程数（4-8线程，基于设备）
- 详细日志输出（便于调试）

### 3. 错误处理和日志

```swift
func upscaleImageWithErrorHandling(imagePath: String) {
    guard let upscaler = imageUpscaler else {
        handleError("图像增强器未初始化")
        return
    }
    
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        let result = upscaler.upscaleImage(
            atPath: imagePath,
            saveAfterUpscaled: false,
            smallerImageByPercentage: 0.75,
            resizeAfterUpscale: true
        )
        
        DispatchQueue.main.async {
            if result.success {
                self?.handleSuccessResult(result)
            } else {
                self?.handleError(result.errorMessage ?? "未知错误")
            }
        }
    }
}

func handleSuccessResult(_ result: WQUpscaleResult) {
    // 显示处理结果
    if let outputImage = result.outputImage {
        imageView.image = outputImage
    }
    
    // 显示性能信息
    let processingTime = result.processingTimeMs
    print("处理耗时: \(processingTime)ms")
    
    // 显示保存路径
    if let savedPath = result.savedFilePath {
        print("文件已保存: \(savedPath)")
    }
}

func handleError(_ message: String) {
    print("错误: \(message)")
    // 显示错误提示给用户
}
```

## 常见问题解答

### Q1: 为什么初始化失败？

**A:** 常见原因包括：
- 设备内存不足
- 模型文件未添加到项目
- 模型文件未包含在"Copy Bundle Resources"中
- TensorFlow Lite依赖缺失

**解决方案：**
```swift
// 1. 检查模型文件是否存在
if let modelPath = Bundle.main.path(forResource: "model", ofType: "tflite") {
    print("模型文件路径: \(modelPath)")
} else {
    print("错误: 模型文件未找到")
}

// 2. 检查内存状态
let memoryInfo = ProcessInfo.processInfo.physicalMemory
print("物理内存: \(memoryInfo / 1024 / 1024)MB")

// 3. 初始化时捕获错误
do {
    try imageUpscaler?.initialize()
} catch {
    print("初始化错误: \(error)")
}
```

### Q2: 处理大图像时出现内存不足？

**A:** 使用smallerImageByPercentage参数：
```swift
// 对于大图像，先缩小75%再处理，然后恢复到原始尺寸
let result = imageUpscaler.upscaleImage(
    atPath: imagePath,
    saveAfterUpscaled: false,
    smallerImageByPercentage: 0.75,
    resizeAfterUpscale: true
)

// 或者缩小更多（90%），保留10%
let result = imageUpscaler.upscaleImage(
    atPath: imagePath,
    saveAfterUpscaled: false,
    smallerImageByPercentage: 0.90,
    resizeAfterUpscale: true
)
```

### Q3: 如何提高处理速度？

**A:** 优化建议：
- XCFramework自动使用GPU (Metal)硬件加速（如果设备支持）
- 使用smallerImageByPercentage预先调整图像尺寸
- 在后台线程处理（使用DispatchQueue.global）
- 复用WQImageUpscaler实例（不要每次都创建新实例）
- 对于大图像，使用0.75或更高的缩小比例

### Q4: 支持哪些图像格式？

**A:** 支持iOS标准格式：
- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC (.heic) - iOS原生格式
- BMP (.bmp)
- TIFF (.tiff)

### Q5: 为什么只支持真机，不支持模拟器？

**A:** 技术原因：
- XCFramework仅包含arm64架构（真机）
- 不包含x86_64架构（模拟器）
- TensorFlow Lite Metal加速需要真实GPU
- 减小框架体积，优化真机性能

## 最佳实践

### 1. 单例模式管理

```swift
class ImageUpscalerManager {
    static let shared = ImageUpscalerManager()
    
    private var imageUpscaler: WQImageUpscaler?
    private(set) var isInitialized = false
    
    private init() {
        imageUpscaler = WQImageUpscaler()
        initializeAsync()
    }
    
    private func initializeAsync() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.imageUpscaler?.initialize()
                DispatchQueue.main.async {
                    self?.isInitialized = true
                    print("全局图像增强器初始化成功")
                }
            } catch {
                print("全局初始化失败: \(error)")
            }
        }
    }
    
    func upscaleImage(atPath path: String,
                     saveAfterUpscaled: Bool = false,
                     smallerImageByPercentage: Float = 0.75,
                     resizeAfterUpscale: Bool = true) -> WQUpscaleResult? {
        guard isInitialized, let upscaler = imageUpscaler else {
            print("图像增强器未就绪")
            return nil
        }
        
        return upscaler.upscaleImage(
            atPath: path,
            saveAfterUpscaled: saveAfterUpscaled,
            smallerImageByPercentage: smallerImageByPercentage,
            resizeAfterUpscale: resizeAfterUpscale
        )
    }
    
    func cleanup() {
        imageUpscaler?.cleanup()
    }
}
```

### 2. 内存优化

```swift
func processImageWithMemoryOptimization(imagePath: String) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        autoreleasepool {
            guard let result = self?.imageUpscaler?.upscaleImage(
                atPath: imagePath,
                saveAfterUpscaled: false,
                smallerImageByPercentage: 0.75,
                resizeAfterUpscale: true
            ) else { return }
            
            DispatchQueue.main.async {
                if result.success, let outputImage = result.outputImage {
                    // 创建副本用于显示
                    let displayImage = UIImage(cgImage: outputImage.cgImage!)
                    self?.imageView.image = displayImage
                }
            }
        }
    }
}
```

### 3. 用户体验优化

```swift
func upscaleImageWithProgress(imagePath: String) {
    // 显示加载指示器
    let loadingView = showLoadingIndicator(message: "正在处理图像，请稍候...")
    
    let startTime = Date()
    
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        let result = self?.imageUpscaler?.upscaleImage(
            atPath: imagePath,
            saveAfterUpscaled: false,
            smallerImageByPercentage: 0.75,
            resizeAfterUpscale: true
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        DispatchQueue.main.async {
            loadingView.dismiss()
            
            if let result = result, result.success {
                self?.imageView.image = result.outputImage
                self?.showToast("处理完成，耗时: \(Int(processingTime * 1000))ms")
            } else {
                self?.showToast("处理失败: \(result?.errorMessage ?? "未知错误")")
            }
        }
    }
}
```

### 4. 批量处理

```swift
func batchUpscaleImages(imagePaths: [String]) {
    let total = imagePaths.count
    var completed = 0
    
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        for imagePath in imagePaths {
            autoreleasepool {
                let result = self?.imageUpscaler?.upscaleImage(
                    atPath: imagePath,
                    saveAfterUpscaled: true,
                    smallerImageByPercentage: 0.75,
                    resizeAfterUpscale: true
                )
                
                completed += 1
                
                DispatchQueue.main.async {
                    // 更新进度
                    let progress = Float(completed) / Float(total)
                    self?.progressView.progress = progress
                    self?.statusLabel.text = "已完成: \(completed)/\(total)"
                }
                
                if let result = result, result.success {
                    print("完成: \(imagePath)")
                } else {
                    print("失败: \(imagePath) - \(result?.errorMessage ?? "未知错误")")
                }
            }
        }
        
        DispatchQueue.main.async {
            self?.showToast("批量处理完成！")
        }
    }
}
```

## 控制台日志说明

### 初始化日志

```
WQImageUpscaler: 开始初始化...
模型路径: /var/containers/Bundle/Application/.../iOSUseCppDemo1.app/model.tflite
使用线程数: 6 (设备CPU核心数: 6)
尝试初始化GPU (Metal)代理...
Created TensorFlow Lite delegate for Metal.
INFO: Created TensorFlow Lite delegate for Metal.
Initialized TensorFlow Lite runtime.
INFO: Initialized TensorFlow Lite runtime.
GPU (Metal)代理初始化成功
预期性能: ~800-1500ms per tile (比CPU快2-3倍)
初始化成功，使用GPU (Metal)加速
```

### 图像处理日志

```
输入图像尺寸: 240.0x240.0
预缩放到: 60.0x60.0 (25.0%)
处理图像: 60x60 pixels
释放处理内存...
恢复到原始尺寸: 240.0x240.0
处理完成，耗时: 127ms, 输出尺寸: 240x240
```

### 大图像瓦片处理日志

```
输入图像尺寸: 3000.0x2250.0
预缩放到: 750.0x562.5 (25.0%)
处理图像: 750x563 pixels
处理 7x5 重叠tiles (overlap=16px)
并行处理和混合tiles (推理 + 混合重叠)
Tile处理完成. 输出: 3000x2252 pixels
释放处理内存...
恢复到原始尺寸: 3000.0x2250.0
处理完成，耗时: 3171ms, 输出尺寸: 3000x2250
```

### 错误日志

```
错误: 在主bundle中未找到模型文件
GPU初始化异常: [错误描述]
GPU初始化失败，降级到CPU模式
CPU代理初始化成功
初始化成功，使用CPU
```

---

## 技术支持

如果您在使用过程中遇到问题，请检查：

1. **模型文件配置**：确保model.tflite已添加到"Copy Bundle Resources"
2. **框架链接方式**：确保所有XCFramework设置为"Do Not Embed"
3. **内存状态**：确保设备有足够的可用内存
4. **控制台日志**：查看Xcode控制台中的详细日志信息
5. **真机测试**：确保在真机上测试，不支持模拟器

**日志关键词：**
- `WQImageUpscaler`：库的主要日志
- `TensorFlow Lite`：TensorFlow Lite相关日志
- `GPU (Metal)`：GPU加速相关日志

通过遵循本指南，您应该能够成功在iOS应用中集成和使用WQImageUpscaler.xcframework库，为用户提供强大的AI图像降噪功能。

---

## 版本历史

### 版本 1.0.0 (2025年11月18日)

- ✅ 首个正式版本发布
- ✅ 支持iOS 15.0+，arm64架构
- ✅ 自动GPU (Metal)加速，智能CPU回退
- ✅ 完整的中文控制台日志
- ✅ 静态框架，简化集成流程
- ✅ AI模型，4倍图像增强
- ✅ 自动瓦片处理，支持大图像
- ✅ 多步骤降采样算法，高质量尺寸恢复
