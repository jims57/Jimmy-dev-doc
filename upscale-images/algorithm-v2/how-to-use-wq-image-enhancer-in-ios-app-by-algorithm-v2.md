# 如何在iOS应用中使用WQImageEnhancer.xcframework库

*作者：Jimmy Gan*

*最后更新：2025年12月4日*

*当前版本：v1.3.0*

本指南介绍如何在iOS项目中集成【沃奇】WQImageEnhancer.xcframework图像降噪增强库。

## 库简介

WQImageEnhancer是专为iOS开发的图像降噪增强库：

- **高性能处理**：优化算法，3000x2250图像约230ms完成
- **原尺寸处理**：不对图像进行缩放，保持原始分辨率
- **多种降噪方法**：双边滤波、快速非局部均值、BM3D
- **边缘保持**：降噪同时保持边缘清晰
- **锐化增强**：可选Unsharp Mask锐化
- **单一动态框架**：仅需一个XCFramework，体积约6.7MB

## 系统要求

- **iOS版本**：iOS 13.0+
- **架构**：arm64（仅真机）
- **Xcode**：15.0+

## 项目集成

### 第1步：添加框架

将框架拖入Xcode项目：
- `WQImageEnhancer.xcframework`

### 第2步：配置嵌入方式

在 General → Frameworks, Libraries, and Embedded Content：
- `WQImageEnhancer.xcframework` → **Embed & Sign**（动态库）

## 基础使用

```objc
#import <WQImageEnhancer/WQImageEnhancer.h>

@interface ViewController ()
@property (nonatomic, strong) WQImageEnhancer *enhancer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.enhancer = [[WQImageEnhancer alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error = nil;
        BOOL success = [self.enhancer initializeAndReturnError:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSLog(@"图像增强器初始化成功");
            }
        });
    });
}

- (void)enhanceImage:(UIImage *)image {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        WQEnhanceResult *result = [self.enhancer enhanceImage:image
                                            saveAfterEnhanced:NO
                                                denoiseMethod:WQ_DENOISE_BILATERAL
                                            enableUnsharpMask:NO  // 默认关闭，淡海项目建议关闭以减少伪影
                                             progressCallback:^(float progress) {
            NSLog(@"进度: %.2f%%", progress);
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result.success) {
                self.imageView.image = result.outputImage;
                NSLog(@"处理完成，耗时: %.0fms", result.processingTimeMs);
            }
        });
    });
}

- (void)dealloc {
    [self.enhancer cleanup];
}

@end
```

## 降噪方法

| 方法 | 枚举值 | 速度 | 质量 |
|------|--------|------|------|
| 双边滤波 | WQ_DENOISE_BILATERAL | 最快 | 中等 |
| 快速非局部均值 | WQ_DENOISE_FAST_NL_MEANS | 较慢 | 高 |
| BM3D | WQ_DENOISE_BM3D | 最慢 | 最高 |

**推荐**：使用 `WQ_DENOISE_BILATERAL`，速度快且效果好。

## API参考

### 默认参数值常量

```objc
// 可直接使用这些常量，无需硬编码
extern const int WQ_DEFAULT_BILATERAL_D;              // 8
extern const double WQ_DEFAULT_BILATERAL_SIGMA_COLOR; // 50.0
extern const double WQ_DEFAULT_BILATERAL_SIGMA_SPACE; // 30.0
extern const int WQ_DEFAULT_BILATERAL_ITERATIONS;     // 2
extern const BOOL WQ_DEFAULT_ENABLE_UNSHARP_MASK;     // NO
extern const double WQ_DEFAULT_UNSHARP_SIGMA;         // 1.0
extern const double WQ_DEFAULT_UNSHARP_AMOUNT;        // 1.5
```

### WQImageEnhancer

```objc
// 初始化
- (BOOL)initializeAndReturnError:(NSError **)error;

// 基础方法 - 使用默认参数
- (WQEnhanceResult *)enhanceImage:(UIImage *)inputImage
                saveAfterEnhanced:(BOOL)saveAfterEnhanced
                    denoiseMethod:(WQDenoiseMethod)denoiseMethod
                enableUnsharpMask:(BOOL)enableUnsharpMask
                 progressCallback:(void(^)(float progress))progressCallback;

// 完整方法 - 支持自定义参数和调试模式
// isDebug参数说明:
//   - YES: 调试模式，文件名包含参数信息，如: enhanced_20251203_143109(UnsharpFalse-D8-Color50-Space30-it2-Sigma1.0-Amount1.5).jpg
//          同时在控制台输出详细参数日志
//   - NO: 正常文件名，如: enhanced_20251203_143109.jpg
- (WQEnhanceResult *)enhanceImage:(UIImage *)inputImage
                saveAfterEnhanced:(BOOL)saveAfterEnhanced
                    denoiseMethod:(WQDenoiseMethod)denoiseMethod
                enableUnsharpMask:(BOOL)enableUnsharpMask
                      bilateralD:(int)bilateralD
              bilateralSigmaColor:(double)bilateralSigmaColor
              bilateralSigmaSpace:(double)bilateralSigmaSpace
             bilateralIterations:(int)bilateralIterations
                     unsharpSigma:(double)unsharpSigma
                    unsharpAmount:(double)unsharpAmount
                          isDebug:(BOOL)isDebug
                 progressCallback:(void(^)(float progress))progressCallback;

// 处理文件路径
- (WQEnhanceResult *)enhanceImageAtPath:(NSString *)imagePath
                      saveAfterEnhanced:(BOOL)saveAfterEnhanced
                          denoiseMethod:(WQDenoiseMethod)denoiseMethod
                      enableUnsharpMask:(BOOL)enableUnsharpMask
                       progressCallback:(void(^)(float progress))progressCallback;

// 清理资源
- (void)cleanup;
```

### WQEnhanceResult

```objc
@property BOOL success;                    // 是否成功
@property UIImage *outputImage;            // 输出图像
@property NSString *outputPath;            // 输出路径（如果保存）
@property NSString *errorMessage;          // 错误信息
@property NSTimeInterval processingTimeMs; // 处理耗时(ms)
@property NSString *outputSizeInfo;        // 输出尺寸信息
```

## 性能参考

| 图像尺寸 | 双边滤波耗时 |
|----------|-------------|
| 240x240 | ~19ms |
| 1000x1000 | ~80ms |
| 3000x2250 | ~230ms |

注意：图像不会被缩放，始终以原始分辨率进行处理。

## 参数微调指南

详细的参数说明和微调建议请参考: [fine-tune-parameter.md](../fine-tune/fine-tune-parameter.md)

### 默认参数值 (v1.3.0)

```objc
// 提醒：建议不要修改这些参数，因为这些参数是经Jimmy反复测试和优化的
// 如果修改了，可能会导致降噪效果变差

// 是否启用锐化 (淡海项目建议关闭以减少伪影噪点)
BOOL enableUnsharpMask = WQ_DEFAULT_ENABLE_UNSHARP_MASK; // 默认: NO

// BILATERAL双边滤波参数
int bilateralD = WQ_DEFAULT_BILATERAL_D;                    // 范围: 5-15, 默认: 8
double bilateralSigmaColor = WQ_DEFAULT_BILATERAL_SIGMA_COLOR; // 范围: 10-150, 默认: 50
double bilateralSigmaSpace = WQ_DEFAULT_BILATERAL_SIGMA_SPACE; // 范围: 10-150, 默认: 30
int bilateralIterations = WQ_DEFAULT_BILATERAL_ITERATIONS;  // 范围: 1-4, 默认: 2

// Unsharp Mask锐化参数 (仅当enableUnsharpMask=YES时生效)
double unsharpSigma = WQ_DEFAULT_UNSHARP_SIGMA;             // 范围: 0.5-3.0, 默认: 1.0
double unsharpAmount = WQ_DEFAULT_UNSHARP_AMOUNT;           // 范围: 0.5-3.0, 默认: 1.5

// 调试模式开关
// isDebug参数说明:
//   - YES: 调试模式，文件名包含参数信息，如: enhanced_20251203_143109(UnsharpFalse-D8-Color50-Space30-it2-Sigma1.0-Amount1.5).jpg
//          同时在控制台输出详细参数日志
//   - NO: 正常文件名，如: enhanced_20251203_143109.jpg
BOOL isDebug = NO; // 默认: NO
```

## 版本历史

### v1.3.0 (2025-12-04)
- 优化默认参数值（经Jimmy测试对比，适合淡海项目）
  - enableUnsharpMask默认为NO（减少伪影噪点）
  - bilateralD默认为8（平衡速度和效果）
  - bilateralSigmaSpace默认为30（局部降噪保留细节）
  - bilateralIterations默认为2（速度更快）
- 添加默认参数值常量(WQ_DEFAULT_XXX)，App可直接使用
- 添加完整方法支持自定义参数和isDebug调试模式
- 添加参数微调指南参考
- 添加build脚本--sdkVersion参数支持

### v1.1.1 (2025-11-28)
- 支持iOS 13.0+（之前为iOS 15.0+）
- 修复nullability警告

### v1.1.0 (2025-11-28)
- 改为单一动态XCFramework，体积仅6.7MB
- 无需单独添加依赖库
- 简化集成流程

### v1.0.0 (2025-11-28)
- 全新高性能图像处理引擎
- 支持多种降噪算法
- C/C++风格API
- 仅支持arm64真机
