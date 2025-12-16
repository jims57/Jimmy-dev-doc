# 如何在iOS应用中使用WQStyleFilterFramework

*作者：Jimmy Gan*

*最后更新：2025年12月16日*

*版本：v1.2.2（对应Android版：v1.5.0）*


本指南详细介绍如何在iOS项目中集成和使用【沃奇】风格滤镜XCFramework，该库基于3D LUT色彩查找表技术提供强大的图像风格转换功能。

## 目录

1. [库简介](#库简介)
2. [系统要求](#系统要求)
3. [项目集成步骤](#项目集成步骤)
4. [API参考](#api参考)
5. [基础使用方法](#基础使用方法)
6. [完整示例代码](#完整示例代码)

## 库简介

WQStyleFilterFramework是一个专为iOS开发的图像风格滤镜XCFramework，具有以下特点：

- **3D LUT技术**：基于专业的3D色彩查找表算法
- **多种滤镜**：支持富士、哈苏、理光等多种专业相机风格
- **高性能**：典型处理时间100-200ms
- **单一框架**：所有依赖已静态链接，只需添加一个XCFramework
- **LUT预加载**：支持预加载所有LUT文件，加速后续滤镜应用
- **自定义LUT路径**：支持自动复制LUT文件到Documents目录，方便使用自定义绝对路径
- **丰富的辅助方法**：内置图像加载、保存、临时文件管理等功能

## 系统要求

- **最低iOS版本**：iOS 13.0
- **架构**：arm64 (真机)
- **XCFramework大小**：约14MB

## 项目集成步骤

### 第1步：复制XCFramework

将XCFramework复制到您的iOS项目目录：

```bash
cp -R WQStyleFilterFramework.xcframework /path/to/your/ios/project/
```

### 第2步：在Xcode中添加Framework

1. 打开Xcode项目
2. 选择项目Target -> General -> Frameworks, Libraries, and Embedded Content
3. 点击 "+" 按钮
4. 选择 "Add Other..." -> "Add Files..."
5. 选择 `WQStyleFilterFramework.xcframework`
6. 确保设置为 **Embed & Sign**

### 第3步：准备LUT滤镜文件

将LUT滤镜文件(.cube格式)添加到项目的Bundle Resources：

1. 将.cube文件拖入Xcode项目
2. 确保在"Copy Bundle Resources"中包含这些文件

### 第4步：导入Framework

在需要使用的文件中导入：

```objc
#import <WQStyleFilterFramework/WQStyleFilterFramework.h>
```

## API参考

### WQStyleFilter类

#### 核心方法

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `applyStyleFilterFastWithCubePath:inputImagePath:outputPath:isDebug:error:` | 应用风格滤镜到图像 | `WQFilterResult` |
| `preloadAllLutFilesFromFolder:isDebug:` | 预加载所有LUT文件到内存（支持绝对路径或相对路径） | `NSInteger` (加载数量) |
| `getLutFilterNamesFromFolder:` | 获取所有可用滤镜名称列表（支持绝对路径或相对路径） | `NSArray<NSString *>` |
| `isAllLutsLoaded` | 检查是否已预加载所有LUT | `BOOL` |
| `getLoadedLutCount` | 获取已加载的LUT数量 | `NSInteger` |

#### 初始化方法

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `initWithLutBundle:subpath:isDebug:` | 使用指定的NSBundle初始化，并自动预加载所有LUT文件（v1.2.2新增，推荐） | `WQStyleFilter` |
| `initWithLutFolder:isDebug:` | 使用指定的LUT文件夹路径初始化，并自动预加载所有LUT文件 | `WQStyleFilter` |

#### LUT文件管理方法

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `setupCustomLutFolderWithDebug:` | 设置自定义LUT文件夹，自动复制bundle中的.cube文件到Documents/luts | `NSString` (文件夹路径) |
| `defaultLutFolderPath` | 获取默认LUT文件夹路径（Documents/luts） | `NSString` |

#### 辅助方法

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `copyAssetImageToCache:` | 复制Bundle图像到临时目录 | `NSString` (临时文件路径) |
| `saveBitmapToDocuments:filterName:` | 保存UIImage到Documents文件夹 | `NSString` (保存路径) |
| `saveFilteredImageToDocuments:filterName:` | 保存滤镜处理后的图像到Documents文件夹（PNG格式） | `NSString` (保存路径) |
| `deleteTempFile:` | 删除临时文件 | `void` |

### WQFilterResult类

| 属性 | 说明 | 类型 |
|------|------|--------|
| `success` | 处理是否成功 | `BOOL` |
| `outputImage` | 获取处理后的UIImage | `UIImage` |
| `errorMessage` | 获取错误信息 | `NSString` |
| `processingTime` | 获取处理耗时(ms) | `NSInteger` |

## 基础使用方法

### 1. 初始化

```objc
#import <WQStyleFilterFramework/WQStyleFilterFramework.h>

@interface ViewController ()
@property (nonatomic, strong) WQStyleFilter *styleFilter;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 方式1: 使用NSBundle初始化（v1.2.2新增，推荐）
    // 直接从mainBundle加载LUT文件，subpath为nil表示从bundle根目录加载
    self.styleFilter = [[WQStyleFilter alloc] initWithLutBundle:[NSBundle mainBundle] subpath:nil isDebug:YES];
    
    // 方式2: 使用自定义Bundle和子路径
    // NSBundle *customBundle = [NSBundle bundleWithPath:@"path/to/custom.bundle"];
    // self.styleFilter = [[WQStyleFilter alloc] initWithLutBundle:customBundle subpath:@"lut/formated-luts" isDebug:YES];
    
    // 方式3: 使用setupCustomLutFolderWithDebug复制LUT到Documents目录
    // NSString *lutFolderPath = [WQStyleFilter setupCustomLutFolderWithDebug:YES];
    // self.styleFilter = [[WQStyleFilter alloc] initWithLutFolder:lutFolderPath isDebug:YES];
    
    self.processingQueue = dispatch_queue_create("cn.watchfun.stylefilter", DISPATCH_QUEUE_SERIAL);
}
```

**initWithLutBundle参数说明（v1.2.2新增）：**
- **bundle**: 包含LUT文件的NSBundle对象，传入nil时使用mainBundle
- **subpath**: bundle内LUT文件所在的子路径，传入nil或空字符串时从bundle根目录加载

### 2. 获取滤镜列表

```objc
// 从Bundle中获取滤镜列表
NSArray<NSString *> *filterNames = [self.styleFilter getLutFilterNamesFromFolder:@""];
```

**路径参数说明（v1.2.1新增）：**
- **绝对路径**（以`/`开头）：直接使用该路径，例如 `@"/var/mobile/Containers/Data/Application/.../luts"`
- **相对路径**：从mainBundle获取，例如 `@"lut/formated-luts"` 或 `@""`

### 3. 应用滤镜

```objc
- (void)applyFilterWithName:(NSString *)filterName toImage:(UIImage *)image {
    dispatch_async(self.processingQueue, ^{
        // 获取LUT文件路径
        NSString *cubePath = [[NSBundle mainBundle] pathForResource:filterName ofType:@"cube"];
        
        // 保存图像到临时文件
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp_input.jpg"];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.95);
        [imageData writeToFile:tempPath atomically:YES];
        
        // 应用滤镜
        NSError *error = nil;
        WQFilterResult *result = [self.styleFilter applyStyleFilterFastWithCubePath:cubePath
                                                                     inputImagePath:tempPath
                                                                         outputPath:nil
                                                                            isDebug:YES
                                                                              error:&error];
        
        // 清理临时文件
        [self.styleFilter deleteTempFile:tempPath];
        
        // 更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result.success && result.outputImage) {
                self.imageView.image = result.outputImage;
                NSLog(@"处理完成，耗时: %ldms", (long)result.processingTime);
            } else {
                NSLog(@"滤镜失败: %@", result.errorMessage);
            }
        });
    });
}
```

### 4. 保存处理结果

```objc
// 方式1: 使用saveFilteredImageToDocuments保存（推荐，v1.2.2新增）
NSString *savedPath = [self.styleFilter saveFilteredImageToDocuments:outputImage filterName:filterName];
if (savedPath) {
    NSLog(@"已保存到: %@", savedPath);
}

// 方式2: 使用saveBitmapToDocuments保存
NSString *savedPath = [self.styleFilter saveBitmapToDocuments:outputImage filterName:filterName];
```

## 完整示例代码

以下是一个完整的ViewController示例：

```objc
#import "ViewController.h"
#import <WQStyleFilterFramework/WQStyleFilterFramework.h>

@interface ViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIImageView *imageViewOriginal;
@property (nonatomic, strong) UIImageView *imageViewFiltered;
@property (nonatomic, strong) UIPickerView *filterPicker;
@property (nonatomic, strong) UIButton *buttonApplyFilter;
@property (nonatomic, strong) UILabel *labelProcessingTime;

@property (nonatomic, strong) NSMutableArray<NSString *> *filterNames;
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, strong) WQStyleFilter *styleFilter;
@property (nonatomic, strong) dispatch_queue_t processingQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 使用NSBundle初始化（v1.2.2新增，推荐）
    self.styleFilter = [[WQStyleFilter alloc] initWithLutBundle:[NSBundle mainBundle] subpath:nil isDebug:YES];
    self.processingQueue = dispatch_queue_create("cn.watchfun.stylefilter", DISPATCH_QUEUE_SERIAL);
    self.filterNames = [NSMutableArray array];
    
    [self setupUI];
    [self loadLUTFilters];
}

- (void)loadLUTFilters {
    // 从Bundle获取滤镜列表
    NSArray *names = [self.styleFilter getLutFilterNamesFromFolder:@""];
    [self.filterNames addObjectsFromArray:names];
    [self.filterPicker reloadAllComponents];
}

- (void)applyStyleFilter {
    if (!self.selectedImage) return;
    
    NSInteger selectedRow = [self.filterPicker selectedRowInComponent:0];
    NSString *filterName = self.filterNames[selectedRow];
    // 使用mainBundle获取LUT文件路径
    NSString *cubePath = [[NSBundle mainBundle] pathForResource:filterName ofType:@"cube"];
    
    dispatch_async(self.processingQueue, ^{
        // 保存到临时文件
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.jpg"];
        [UIImageJPEGRepresentation(self.selectedImage, 0.95) writeToFile:tempPath atomically:YES];
        
        // 应用滤镜
        NSError *error = nil;
        WQFilterResult *result = [self.styleFilter applyStyleFilterFastWithCubePath:cubePath
                                                                     inputImagePath:tempPath
                                                                         outputPath:nil
                                                                            isDebug:YES
                                                                              error:&error];
        
        [self.styleFilter deleteTempFile:tempPath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result.success && result.outputImage) {
                self.imageViewFiltered.image = result.outputImage;
                self.labelProcessingTime.text = [NSString stringWithFormat:@"处理时间: %ldms", (long)result.processingTime];
            }
        });
    });
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.filterNames.count;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.filterNames[row];
}

@end
```

---

## 技术支持

如果您在使用过程中遇到问题，请检查：

1. **XCFramework**：确保WQStyleFilterFramework.xcframework已正确添加并设置为"Embed & Sign"
2. **LUT文件**：确保.cube文件已添加到Bundle Resources
3. **日志输出**：查看Xcode控制台中的"WQStyleFilter"日志获取详细信息

**日志标签：** `WQStyleFilter`