# OpenCV Image Enhancement Parameters

Reference: https://www.projectpro.io/recipes/remove-noise-from-images-opencv

## Default Parameter Values

```java
int bilateralD = 9;              // Range: 5-15
double bilateralSigmaColor = 50.0; // Range: 10-150
double bilateralSigmaSpace = 50.0; // Range: 10-150
int bilateralIterations = 3;     // Range: 1-4
double unsharpSigma = 1.0;       // Range: 0.5-3.0
double unsharpAmount = 1.5;      // Range: 0.5-3.0
boolean isDebug = false;         // Debug mode
```

---

## 1. BILATERAL Filter Parameters

Goal: Strong denoising + preserve texture details (avoid skin-smoothing) + ~1s processing time

### bilateralD (Filter Diameter)

| Value | Effect |
|-------|--------|
| **Range** | 5-15, Recommended: **9** |
| 5 | Fastest, light denoising |
| 9 | Balanced speed and effect (recommended) |
| 15 | Slowest, strong denoising |
| -1 | Auto-calculate based on sigmaSpace |

### bilateralSigmaColor (Color Sigma)

Controls color similarity threshold - determines which pixels get blended.

| Value | Effect |
|-------|--------|
| **Range** | 10-150, Recommended: **50** |
| 10-30 | Preserve texture, light denoising |
| 50-75 | Balanced denoising and texture (recommended) |
| 100-150 | Strong denoising, may cause skin-smoothing |

- **Smaller**: Only blend very similar colors, preserve more texture
- **Larger**: Blend more color differences, stronger denoising but may cause buffing

### bilateralSigmaSpace (Space Sigma)

Controls spatial distance influence - determines how far pixels participate in calculation.

| Value | Effect |
|-------|--------|
| **Range** | 10-150, Recommended: **50** |
| 10-30 | Local denoising, preserve details |
| 50-75 | Balanced (recommended) |
| 100-150 | Global smoothing, may lose details |

- **Smaller**: Only consider nearby pixels, local denoising
- **Larger**: Consider farther pixels, smoother global effect

### bilateralIterations (Iterations)

Multiple light passes are better than one heavy pass.

| Value | Effect |
|-------|--------|
| **Range** | 1-4, Recommended: **3** |
| 1 | Fastest, single pass |
| 2-3 | Balanced (recommended) |
| 4 | Strongest denoising, may over-smooth |

---

## 2. Unsharp Mask Parameters (Sharpening)

### unsharpSigma (Gaussian Sigma)

Controls blur radius, affects sharpening "coarseness".

| Value | Effect |
|-------|--------|
| **Range** | 0.5-3.0, Recommended: **1.0** |
| 0.5-1.0 | Fine sharpening, enhance details |
| 1.0-2.0 | Medium sharpening (recommended) |
| 2.0-3.0 | Coarse sharpening, enhance contours |

- **Smaller**: Finer sharpening (details)
- **Larger**: Coarser sharpening (contours)

### unsharpAmount (Sharpening Strength)

Controls the intensity of sharpening effect.

| Value | Effect |
|-------|--------|
| **Range** | 0.5-3.0, Recommended: **1.5** |
| 0.5-1.0 | Light sharpening |
| 1.0-2.0 | Medium sharpening (recommended) |
| 2.0-3.0 | Strong sharpening, may have halo |

---

## 3. Debug Mode (isDebug)

When `isDebug = true`:

1. **File naming**: Includes parameter values in filename
   - Example: `enhanced_20251203_143109(D9-Color50-Space50-it3-Sigma1-Amount1.5).jpg`

2. **Logcat output**: Detailed parameter logs with format:
   ```
   ============================================================
   [DEBUG] Image Enhancement Parameters:
   [DEBUG] Image size: 3000x2250
   [DEBUG] Denoise method: BILATERAL
   [DEBUG] Enable sharpening: true
   ------------------------------------------------------------
   [DEBUG] BILATERAL Parameters:
   [DEBUG]   bilateralD = 9 (range 5-15)
   [DEBUG]   bilateralSigmaColor = 50.0 (range 10-150)
   [DEBUG]   bilateralSigmaSpace = 50.0 (range 10-150)
   [DEBUG]   bilateralIterations = 3 (range 1-4)
   ------------------------------------------------------------
   [DEBUG] Unsharp Mask Parameters:
   [DEBUG]   unsharpSigma = 1.0 (range 0.5-3.0)
   [DEBUG]   unsharpAmount = 1.5 (range 0.5-3.0)
   ============================================================
   ```

---

## 4. Non-Local Means Parameters (FAST_NL_MEANS / BM3D)

| Parameter | Range | Recommended | Description |
|-----------|-------|-------------|-------------|
| h | 3-25 | 20 | Luminance filter strength |
| hColor | 3-25 | 20 | Color filter strength |
| templateWindowSize | 3-11 (odd) | 7 | Template window size |
| searchWindowSize | 11-35 (odd) | 21 | Search window size |

---

## 5. CLAHE Parameters (Contrast Enhancement)

| Parameter | Range | Recommended | Description |
|-----------|-------|-------------|-------------|
| clipLimit | 1.0-10.0 | 2.0 | Contrast limit |
| tileSize | 4-16 | 8 | Tile size |

---

## Quick Reference

```java
// In MainActivity.java - enhanceImage() method

// BILATERAL parameters
int bilateralD = 9;              // 5-15, larger = stronger but slower
double bilateralSigmaColor = 50.0; // 10-150, smaller = preserve texture
double bilateralSigmaSpace = 50.0; // 10-150, controls smoothing range
int bilateralIterations = 3;     // 1-4, multiple light passes better

// Unsharp Mask parameters
double unsharpSigma = 1.0;       // 0.5-3.0, smaller = finer sharpening
double unsharpAmount = 1.5;      // 0.5-3.0, larger = more obvious

// Debug mode
boolean isDebug = false;         // true = include params in filename
```