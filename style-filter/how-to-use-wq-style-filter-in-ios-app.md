# 如何在iOS应用中使用WQStyleFilterFramework.xcframework库

*作者：Jimmy Gan*

*最后更新：2025年10月15日*

本指南将详细介绍如何从零开始在iOS项目中集成和使用【沃奇】风格滤镜XCFramework库（WQStyleFilterFramework.xcframework），该库基于3D LUT色彩查找表技术提供强大的图像风格转换功能。

## 目录

1. [库简介](#库简介)
2. [系统要求](#系统要求)
3. [获取XCFramework库](#获取xcframework库)
4. [项目集成步骤](#项目集成步骤)
5. [资源文件配置](#资源文件配置)
6. [基础使用方法](#基础使用方法)
7. [高级功能](#高级功能)
8. [常见问题解答](#常见问题解答)
9. [最佳实践](#最佳实践)

## 库简介

WQStyleFilterFramework是一个专为iOS开发的图像风格滤镜XCFramework库，具有以下特点：

- **3D LUT技术**：基于专业的3D色彩查找表算法
- **多种滤镜**：支持富士、哈苏、理光等多种专业相机风格
- **三线性插值**：平滑的颜色过渡，无色块现象
- **多线程优化**：利用GCD并行处理，性能卓越
- **静态库**：无需Embed & Sign，集成简单
- **中文支持**：完整的中文API文档和注释
- **Objective-C/Swift双支持**：原生iOS开发体验

## 系统要求

- **最低iOS版本**：iOS 12.0+
- **支持架构**：arm64 (真机)
- **推荐内存**：至少1GB可用内存
- **存储空间**：约50KB（包含LUT文件）
- **开发工具**：Xcode 14.0+

## 获取XCFramework库

### 方式一：从构建输出获取
```bash
# XCFramework文件位置
/path/to/ios_use_cpp_demo/my-info/WQStyleFilterFramework.xcframework
```

### 方式二：自行构建
```bash
cd /path/to/ios_use_cpp_demo/my-info
./build_xcframwork_based_on_objc.sh
```

构建完成后，XCFramework将自动复制到iOS项目目录。

## 项目集成步骤

### 第1步：添加XCFramework到项目

#### 方法A：通过Xcode界面添加

1. 在Xcode中打开您的iOS项目
2. 选择项目导航器中的项目文件
3. 选择您的Target
4. 点击"General"标签页
5. 滚动到"Frameworks, Libraries, and Embedded Content"部分
6. 点击"+"按钮
7. 点击"Add Other..." → "Add Files..."
8. 选择`WQStyleFilterFramework.xcframework`文件
9. **重要**：确保"Embed"设置为"Do Not Embed"（因为这是静态库）

#### 方法B：手动复制文件

```bash
# 复制XCFramework到项目目录
cp -R WQStyleFilterFramework.xcframework /path/to/your/ios/project/

# 然后在Xcode中添加引用（参考方法A的步骤5-9）
```

### 第2步：验证集成

在Xcode中检查：
1. Target → General → "Frameworks, Libraries, and Embedded Content"
2. 确认`WQStyleFilterFramework.xcframework`已列出
3. 确认"Embed"列显示为空（不是"Embed & Sign"）

### 第3步：准备LUT滤镜文件

将LUT滤镜文件添加到项目的资源中：

1. 在Xcode项目导航器中，右键点击项目
2. 选择"Add Files to [项目名]..."
3. 选择包含.cube文件的文件夹（例如：`formated-luts`文件夹）
4. **重要**：勾选"Copy items if needed"
5. **重要**：勾选"Create folder references"（保持文件夹结构）
6. 点击"Add"

常见的LUT滤镜包括：
- `Fuji-XT4.cube` - 富士相机风格
- `Hasselblad-1.cube` - 哈苏相机风格  
- `Ricoh-GR3.cube` - 理光相机风格
- 等等...

### 第4步：添加示例图像（可选）

如果需要示例图像用于测试：

1. 将测试图像（.jpg, .png等）添加到项目
2. 确保勾选"Copy items if needed"
3. 确保图像已添加到Target的"Build Phases" → "Copy Bundle Resources"

## 资源文件配置

### iOS Bundle资源路径说明

**重要概念**：iOS会将所有资源文件扁平化到Bundle根目录，无论源文件夹结构如何。

```
源文件夹结构：
assets/
  ├── lut/
  │   └── formated-luts/
  │       ├── Fuji-XT4.cube
  │       └── Arapaho.cube
  └── images/
      └── sample.jpg

iOS Bundle中的实际路径：
MainBundle/
  ├── Fuji-XT4.cube      ← 扁平化
  ├── Arapaho.cube       ← 扁平化
  └── sample.jpg         ← 扁平化
```

### 正确的资源加载方式

```objc
// ✅ 正确 - 直接使用文件名
NSString *cubePath = [[NSBundle mainBundle] pathForResource:@"Fuji-XT4" ofType:@"cube"];

// ✅ 正确 - 加载图像
NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"jpg"];

// ❌ 错误 - 不要使用目录路径（Android风格）
NSString *cubePath = @"assets/lut/formated-luts/Fuji-XT4.cube";  // 这在iOS中不工作
```

## 基础使用方法

### Objective-C实现（推荐）

```objc
#import <WQStyleFilterFramework/WQStyleFilterFramework.h>

@interface ViewController ()
@property (nonatomic, strong) WQStyleFilter *styleFilter;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化风格滤镜
    self.styleFilter = [[WQStyleFilter alloc] init];
    self.processingQueue = dispatch_queue_create("cn.watchfun.stylefilter", DISPATCH_QUEUE_SERIAL);
}

// 应用风格滤镜
- (void)applyFilter:(UIImage *)image filterName:(NSString *)filterName {
    // 获取LUT文件的完整路径
    NSString *cubePath = [[NSBundle mainBundle] pathForResource:filterName ofType:@"cube"];
    
    if (!cubePath) {
        NSLog(@"找不到LUT文件: %@.cube", filterName);
        return;
    }
    
    // 在后台线程处理
    dispatch_async(self.processingQueue, ^{
        // 将UIImage保存到临时文件（框架要求文件路径）
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"temp_input_%f.png", 
                              [[NSDate date] timeIntervalSince1970]]];
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:tempPath atomically:YES];
        
        // 应用风格滤镜
        NSError *error = nil;
        WQFilterResult *result = [self.styleFilter applyStyleFilterWithCubePath:cubePath
                                                                 targetImagePath:tempPath
                                                                    outputFolder:nil
                                                                           error:&error];
        
        // 清理临时文件
        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
        
        // 在主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result.success && result.outputImage) {
                // 处理成功
                self.imageView.image = result.outputImage;
                NSLog(@"处理完成，耗时: %ldms", (long)result.processingTime);
                
                // 如果保存了文件
                if (result.savedPath) {
                    NSLog(@"图像已保存到: %@", result.savedPath);
                }
            } else {
                // 处理失败
                NSLog(@"处理失败: %@", result.errorMessage);
            }
        });
    });
}

@end
```

### Swift实现

```swift
import UIKit
import WQStyleFilterFramework

class ViewController: UIViewController {
    private var styleFilter: WQStyleFilter!
    private let processingQueue = DispatchQueue(label: "cn.watchfun.stylefilter")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化风格滤镜
        styleFilter = WQStyleFilter()
    }
    
    // 应用风格滤镜
    func applyFilter(image: UIImage, filterName: String) {
        // 获取LUT文件路径
        guard let cubePath = Bundle.main.path(forResource: filterName, ofType: "cube") else {
            print("找不到LUT文件: \(filterName).cube")
            return
        }
        
        // 在后台线程处理
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 将UIImage保存到临时文件
            let tempPath = NSTemporaryDirectory() + "temp_input_\(Date().timeIntervalSince1970).png"
            if let imageData = image.pngData() {
                try? imageData.write(to: URL(fileURLWithPath: tempPath))
            }
            
            // 应用风格滤镜
            let result = self.styleFilter.applyStyleFilter(withCubePath: cubePath,
                                                           targetImagePath: tempPath,
                                                           outputFolder: nil,
                                                           error: nil)
            
            // 清理临时文件
            try? FileManager.default.removeItem(atPath: tempPath)
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                if result.success, let outputImage = result.outputImage {
                    // 处理成功
                    self.imageView.image = outputImage
                    print("处理完成，耗时: \(result.processingTime)ms")
                    
                    if let savedPath = result.savedPath {
                        print("图像已保存到: \(savedPath)")
                    }
                } else {
                    // 处理失败
                    print("处理失败: \(result.errorMessage ?? "未知错误")")
                }
            }
        }
    }
}
```

## 高级功能

### 1. 不同的保存选项

```objc
// 不保存，只返回UIImage
WQFilterResult *result = [self.styleFilter applyStyleFilterWithCubePath:cubePath
                                                         targetImagePath:imagePath
                                                            outputFolder:nil
                                                                   error:nil];

// 保存到默认Documents文件夹
WQFilterResult *result = [self.styleFilter applyStyleFilterWithCubePath:cubePath
                                                         targetImagePath:imagePath
                                                            outputFolder:@""
                                                                   error:nil];

// 保存到自定义文件夹
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *customFolder = [[paths firstObject] stringByAppendingPathComponent:@"FilteredImages"];
WQFilterResult *result = [self.styleFilter applyStyleFilterWithCubePath:cubePath
                                                         targetImagePath:imagePath
                                                            outputFolder:customFolder
                                                                   error:nil];
```

### 2. 异步处理（使用回调）

```objc
// 异步方法 - 自动在主线程回调
[self.styleFilter applyStyleFilterAsyncWithCubePath:cubePath
                                    targetImagePath:imagePath
                                       outputFolder:nil
                                         completion:^(WQFilterResult *result, NSError *error) {
    // 已经在主线程
    if (result.success) {
        self.imageView.image = result.outputImage;
        NSLog(@"处理完成，耗时: %ldms", (long)result.processingTime);
    } else {
        NSLog(@"处理失败: %@", result.errorMessage);
    }
}];
```

### 3. 从Bundle加载LUT滤镜列表

```objc
- (NSArray<NSString *> *)loadAvailableFilters {
    NSMutableArray *filterNames = [NSMutableArray array];
    
    // 获取Bundle资源路径
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:&error];
    
    if (error) {
        NSLog(@"加载滤镜列表失败: %@", error);
        return filterNames;
    }
    
    for (NSString *file in files) {
        if ([file hasSuffix:@".cube"]) {
            // 移除.cube扩展名
            NSString *filterName = [file stringByReplacingOccurrencesOfString:@".cube" withString:@""];
            [filterNames addObject:filterName];
        }
    }
    
    // 排序
    [filterNames sortUsingSelector:@selector(compare:)];
    
    NSLog(@"已加载 %lu 个LUT滤镜", (unsigned long)filterNames.count);
    return filterNames;
}
```

### 4. 批量处理多张图像

```objc
- (void)batchProcessImages:(NSArray<UIImage *> *)images filterName:(NSString *)filterName {
    NSString *cubePath = [[NSBundle mainBundle] pathForResource:filterName ofType:@"cube"];
    
    if (!cubePath) {
        NSLog(@"找不到LUT文件");
        return;
    }
    
    dispatch_async(self.processingQueue, ^{
        NSInteger total = images.count;
        NSInteger completed = 0;
        
        for (UIImage *image in images) {
            @autoreleasepool {
                // 保存到临时文件
                NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                                     [NSString stringWithFormat:@"temp_%ld.png", (long)completed]];
                [UIImagePNGRepresentation(image) writeToFile:tempPath atomically:YES];
                
                // 处理图像
                NSString *outputFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                                             NSUserDomainMask, YES) firstObject];
                WQFilterResult *result = [self.styleFilter applyStyleFilterWithCubePath:cubePath
                                                                         targetImagePath:tempPath
                                                                            outputFolder:outputFolder
                                                                                   error:nil];
                
                // 清理临时文件
                [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
                
                completed++;
                
                // 更新进度
                dispatch_async(dispatch_get_main_queue(), ^{
                    float progress = (float)completed / (float)total;
                    self.progressView.progress = progress;
                    self.statusLabel.text = [NSString stringWithFormat:@"已完成: %ld/%ld", 
                                           (long)completed, (long)total];
                });
                
                if (result.success) {
                    NSLog(@"✅ 完成第%ld张图像", (long)completed);
                } else {
                    NSLog(@"❌ 第%ld张图像失败: %@", (long)completed, result.errorMessage);
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"批量处理完成！");
        });
    });
}
```

## 常见问题解答

### Q1: 为什么XCFramework要设置为"Do Not Embed"？
**A:** WQStyleFilterFramework是静态库（Static Library），静态库的代码会在编译时链接到您的应用中，不需要在运行时动态加载。只有动态库（Dynamic Library）才需要"Embed & Sign"。

### Q2: 如何处理不同的图像来源？
**A:** 框架需要文件路径，因此需要先将图像保存到临时文件：

```objc
// 从UIImage
NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.png"];
[UIImagePNGRepresentation(image) writeToFile:tempPath atomically:YES];

// 从PHAsset（相册）
PHImageManager *manager = [PHImageManager defaultManager];
[manager requestImageDataForAsset:asset 
                          options:nil 
                    resultHandler:^(NSData *imageData, NSString *dataUTI, 
                                   UIImageOrientation orientation, NSDictionary *info) {
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.jpg"];
    [imageData writeToFile:tempPath atomically:YES];
    // 然后使用tempPath
}];
```

### Q3: 支持哪些LUT文件格式？
**A:** 目前仅支持`.cube`格式的3D LUT文件。这是业界标准格式，大多数专业调色软件都支持导出。

### Q4: 处理速度如何？
**A:** 处理速度取决于：
- 图像分辨率（典型的1080p图像约100-500ms）
- 设备性能（iPhone 12及以上更快）
- LUT文件大小（通常为33x33x33或64x64x64）

库已经过优化，使用GCD并行处理和Accelerate框架加速。

### Q5: 支持哪些图像格式？
**A:** 支持iOS标准格式：
- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC (.heic) - iOS 11+
- 其他UIImage支持的格式

## 最佳实践

### 1. 内存管理

```objc
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // 清理缓存的图像
    self.imageView.image = nil;
    
    // 清理临时文件
    NSString *tempDir = NSTemporaryDirectory();
    NSArray *tempFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tempDir error:nil];
    for (NSString *file in tempFiles) {
        if ([file hasPrefix:@"temp_"]) {
            NSString *filePath = [tempDir stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}
```

### 2. 错误处理

```objc
- (void)applyFilterWithErrorHandling:(UIImage *)image filterName:(NSString *)filterName {
    NSString *cubePath = [[NSBundle mainBundle] pathForResource:filterName ofType:@"cube"];
    
    if (!cubePath) {
        [self showAlert:@"找不到滤镜文件"];
        return;
    }
    
    dispatch_async(self.processingQueue, ^{
        @try {
            NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"temp_%f.png", 
                                  [[NSDate date] timeIntervalSince1970]]];
            [UIImagePNGRepresentation(image) writeToFile:tempPath atomically:YES];
            
            NSError *error = nil;
            WQFilterResult *result = [self.styleFilter applyStyleFilterWithCubePath:cubePath
                                                                     targetImagePath:tempPath
                                                                        outputFolder:nil
                                                                               error:&error];
            
            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result.success) {
                    self.imageView.image = result.outputImage;
                } else {
                    [self showAlert:result.errorMessage];
                }
            });
        } @catch (NSException *exception) {
            NSLog(@"处理异常: %@", exception);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlert:@"处理失败，请重试"];
            });
        }
    });
}
```

### 3. 性能优化

```objc
// 使用@autoreleasepool减少内存峰值
- (void)processMultipleImages:(NSArray<UIImage *> *)images {
    dispatch_async(self.processingQueue, ^{
        for (UIImage *image in images) {
            @autoreleasepool {
                [self processImage:image];
            }
        }
    });
}
```

---

## 技术支持

如果您在使用过程中遇到问题，请检查：

1. **框架集成**：确保XCFramework已正确添加并设置为"Do Not Embed"
2. **LUT文件**：确保.cube文件已正确添加到Bundle Resources
3. **资源路径**：使用`[[NSBundle mainBundle] pathForResource:ofType:]`而不是硬编码路径
4. **日志输出**：查看Xcode控制台中的详细错误信息

**日志标签：**
- `WQStyleFilter`：库的主要日志
- `WQStyleFilterHelper`：内部处理日志

## 完整示例项目

参考项目：`/path/to/ios_use_cpp_demo/iOSUseCppDemo1`

该项目展示了：
- 完整的Objective-C集成示例
- 图像选择和滤镜选择UI
- 处理进度显示
- 结果保存功能
- 错误处理

通过遵循本指南，您应该能够成功在iOS应用中集成和使用WQStyleFilterFramework.xcframework库，为用户提供专业的图像风格转换功能。