# 【沃奇】图像降噪SDK参数说明

## 默认参数值 (v1.3.0)

```java
// 是否启用锐化 (淡海项目建议关闭以减少伪影噪点)
boolean enableUnsharpMask = false; // 默认: false

// BILATERAL双边滤波参数
int bilateralD = 8;              // 范围: 5-15（经Jimmy测试对比，发现8最平均速度和效果。建议：8）
double bilateralSigmaColor = 50.0; // 范围: 10-150（建议：50）
double bilateralSigmaSpace = 30.0; // 范围: 10-150（建议：30，控制多远的像素参与计算）
int bilateralIterations = 2;     // 范围: 1-4 （建议：2。经测试，发现2和3，差别不大。而且2的时间更短）

// Unsharp Mask锐化参数 (仅当enableUnsharpMask=true时生效)
double unsharpSigma = 1.0;       // 范围: 0.5-3.0
double unsharpAmount = 1.5;      // 范围: 0.5-3.0

// 调试模式
boolean isDebug = false;         // 调试模式（如果你更多日志，可以设置为true）
```

---

## 1. BILATERAL 双边滤波参数

目标: 强降噪 + 保留纹理细节(避免磨皮效果) + 处理时间约1秒

### bilateralD (滤波直径)

| 值 | 效果 |
|-------|--------|
| **范围** | 5-15, 推荐: **8** |
| 5 | 最快，轻度降噪 |
| 8 | 平衡速度和效果(推荐) |
| 15 | 最慢，强力降噪 |

### bilateralSigmaColor (颜色sigma)

控制颜色相似度阈值 - 决定哪些像素会被混合。

| 值 | 效果 |
|-------|--------|
| **范围** | 10-150, 推荐: **50** |
| 10-30 | 保留纹理，轻度降噪 |
| 50-75 | 平衡降噪和纹理(推荐) |
| 100-150 | 强力降噪，可能磨皮 |

- **越小**: 只混合颜色非常相似的像素，保留更多纹理细节
- **越大**: 混合更多颜色差异的像素，降噪更强但可能磨皮

### bilateralSigmaSpace (空间sigma)

控制空间距离的影响范围 - 决定多远的像素会参与计算。

| 值 | 效果 |
|-------|--------|
| **范围** | 10-150, 推荐: **30** |
| 10-30 | 局部降噪，保留细节(推荐) |
| 50-75 | 平衡 |
| 100-150 | 全局平滑，可能丢失细节 |

- **越小**: 只考虑非常近的像素，局部降噪
- **越大**: 考虑更远的像素，全局降噪效果更平滑

### bilateralIterations (迭代次数)

多次轻度滤波比一次强滤波效果更好。

| 值 | 效果 |
|-------|--------|
| **范围** | 1-4, 推荐: **2** |
| 1 | 最快，单次滤波 |
| 2 | 平衡速度和效果(推荐) |
| 3-4 | 更强降噪，但可能过度平滑 |

---

## 2. Unsharp Mask 锐化参数

### unsharpSigma (高斯sigma)

控制模糊半径，影响锐化的"粗细"。

| 值 | 效果 |
|-------|--------|
| **范围** | 0.5-3.0, 推荐: **1.0** |
| 0.5-1.0 | 精细锐化，增强细节 |
| 1.0-2.0 | 中等锐化(推荐) |
| 2.0-3.0 | 粗糙锐化，增强轮廓 |

- **越小**: 锐化越精细(细节)
- **越大**: 锐化越粗糙(轮廓)

### unsharpAmount (锐化强度)

控制锐化效果的强度。

| 值 | 效果 |
|-------|--------|
| **范围** | 0.5-3.0, 推荐: **1.5** |
| 0.5-1.0 | 轻度锐化 |
| 1.0-2.0 | 中等锐化(推荐) |
| 2.0-3.0 | 强力锐化，可能有光晕 |

---

## 3. 调试模式 (isDebug)

当 `isDebug = true` 时:

1. **文件命名**: 文件名包含参数值
   - 示例: `enhanced_20251203_143109(UnsharpFalse-D8-Color50-Space30-it2-Sigma1.0-Amount1.5).jpg`
   - 如果enableUnsharpMask=true: `enhanced_20251203_143109(UnsharpTrue-D8-Color50-Space30-it2-Sigma1.0-Amount1.5).jpg`

2. **Logcat输出**: 详细参数日志:
   ```
   ============================================================
   [DEBUG] 图像增强参数详情:
   [DEBUG] 图像尺寸: 3000x2250
   [DEBUG] 降噪方法: BILATERAL
   [DEBUG] 启用锐化: true
   ------------------------------------------------------------
   [DEBUG] BILATERAL双边滤波参数:
   [DEBUG]   bilateralD = 9 (范围5-15)
   [DEBUG]   bilateralSigmaColor = 50.0 (范围10-150)
   [DEBUG]   bilateralSigmaSpace = 50.0 (范围10-150)
   [DEBUG]   bilateralIterations = 3 (范围1-4)
   ------------------------------------------------------------
   [DEBUG] Unsharp Mask锐化参数:
   [DEBUG]   unsharpSigma = 1.0 (范围0.5-3.0)
   [DEBUG]   unsharpAmount = 1.5 (范围0.5-3.0)
   ============================================================
   ```

---

## 4. 非局部均值降噪参数 (FAST_NL_MEANS / BM3D)

| 参数 | 范围 | 推荐值 | 说明 |
|-----------|-------|-------------|-------------|
| h | 3-25 | 20 | 亮度滤波强度 |
| hColor | 3-25 | 20 | 颜色滤波强度 |
| templateWindowSize | 3-11 (奇数) | 7 | 模板窗口大小 |
| searchWindowSize | 11-35 (奇数) | 21 | 搜索窗口大小 |

---

## 5. CLAHE参数 (对比度增强)

| 参数 | 范围 | 推荐值 | 说明 |
|-----------|-------|-------------|-------------|
| clipLimit | 1.0-10.0 | 2.0 | 对比度限制 |
| tileSize | 4-16 | 8 | 瓦片大小 |

---

## 快速参考

```java
// 在 MainActivity.java 的 enhanceImage() 方法中

// 是否启用锐化 (淡海项目建议关闭以减少伪影噪点)
boolean enableUnsharpMask = false; // 默认false

// BILATERAL 双边滤波参数
int bilateralD = 8;              // 5-15, 越大降噪越强但越慢
double bilateralSigmaColor = 50.0; // 10-150, 越小越保留纹理
double bilateralSigmaSpace = 30.0; // 10-150, 控制平滑范围
int bilateralIterations = 2;     // 1-4, 多次轻度滤波效果更好

// Unsharp Mask 锐化参数 (仅当enableUnsharpMask=true时生效)
double unsharpSigma = 1.0;       // 0.5-3.0, 越小锐化越精细
double unsharpAmount = 1.5;      // 0.5-3.0, 越大锐化越明显

// 调试模式
boolean isDebug = false;         // true = 文件名包含参数值
```