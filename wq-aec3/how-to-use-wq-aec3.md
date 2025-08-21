# wq-aec3-1.0.aar Android集成指南

## 概述

`wq-aec3-1.0.aar` 是一个基于NLMS(归一化最小均方)算法的Android音频回声消除库，专为TTS（文本转语音）场景优化，提供高性能的实时回声消除功能。

## 1. 项目依赖配置

### 1.1 添加AAR文件

将 `wq-aec3-1.0.aar` 文件放置到项目的 `app/libs/` 目录下。

### 1.2 配置build.gradle

在 `app/build.gradle` 文件中添加：

```gradle
dependencies {
    implementation files('libs/wq-aec3-1.0.aar')
}
```

## 2. 权限配置

在 `AndroidManifest.xml` 中添加必要权限：

```xml
<!-- 音频相关权限 -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 11+ 存储权限 -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" 
    android:minSdkVersion="30" />
```

## 3. 音频参数配置

### 3.1 核心音频参数

```java
// AEC3要求的标准配置
private static final int SAMPLE_RATE = 48000;  // 48kHz采样率（必须）
private static final int CHANNELS = 1;         // 单声道
private static final int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
private static final int AEC3_FRAME_SIZE = 480; // 10ms @ 48kHz
private static final int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, 
        AudioFormat.CHANNEL_IN_MONO, AUDIO_FORMAT);
```

### 3.2 延迟补偿配置

```java
private static final int AEC3_STREAM_DELAY = 5; // 初始延迟5ms，可调整范围5-300ms
private int currentStreamDelay = AEC3_STREAM_DELAY;
```

## 4. 核心类导入和初始化

### 4.1 导入必要的类

```java
import cn.watchfun.aec3.WqAecProcessor;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.media.AudioFormat;
import android.media.MediaRecorder;
import android.media.AudioAttributes;
import java.util.concurrent.ConcurrentLinkedQueue;
```

### 4.2 声明核心变量

```java
// AEC3处理器实例
private WqAecProcessor aec3Processor = null;

// 音频组件
private AudioTrack audioTrack;
private AudioRecord audioRecord;

// 同步缓冲区
private final ConcurrentLinkedQueue<short[]> ttsFrameBuffer = new ConcurrentLinkedQueue<>();
private volatile boolean enableAecSync = false;

// 清洁音频存储
private List<float[]> cleanAudioFrames = new ArrayList<>();
```

## 5. AEC3处理器初始化

### 5.1 基础初始化

```java
private void initializeAEC3Processor() {
    try {
        // 销毁现有处理器
        if (aec3Processor != null) {
            aec3Processor.destroy();
            aec3Processor = null;
        }
        
        // 创建新的AEC3处理器
        aec3Processor = new WqAecProcessor();
        boolean initResult = aec3Processor.initialize();
        
        if (initResult) {
            Log.i(TAG, "AEC3处理器初始化成功");
            
            // 启用时序同步
            aec3Processor.enableTimingSync(true);
            
            // 设置初始延迟
            aec3Processor.setStreamDelay(currentStreamDelay);
            
            // 配置ERLE优化参数
            configureErleParameters();
            
        } else {
            Log.e(TAG, "AEC3处理器初始化失败");
        }
    } catch (Exception e) {
        Log.e(TAG, "AEC3初始化异常", e);
    }
}
```

### 5.2 ERLE优化参数配置

```java
private void configureErleParameters() {
    // 基于官方优化参数的配置
    aec3Processor.setFilterLengthBlocks(25);
    aec3Processor.setFilterLeakageConverged(0.000005f);
    aec3Processor.setFilterLeakageDiverged(0.005f);
    aec3Processor.setDelayDownSamplingFactor(2);
    aec3Processor.setDelayNumFilters(16);
    aec3Processor.setDelayEstimateSmoothing(0.98f);
    
    // 官方AEC3参数优化
    aec3Processor.setInitialStateSeconds(2.5f);
    aec3Processor.setMaxDecFactorLF(4.0f);
    aec3Processor.setMaxIncFactor(3.5f);
    aec3Processor.setEnrThreshold(0.20f);
    aec3Processor.setConservativeInitialPhase(false);
}
```

## 6. AudioTrack配置（播放端）

### 6.1 AudioTrack初始化

```java
private void initializeAudioTrack() {
    int trackBufferSize = AudioTrack.getMinBufferSize(SAMPLE_RATE, 
            AudioFormat.CHANNEL_OUT_MONO, AUDIO_FORMAT);
    
    audioTrack = new AudioTrack.Builder()
            .setAudioAttributes(new AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build())
            .setAudioFormat(new AudioFormat.Builder()
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .setEncoding(AUDIO_FORMAT)
                    .build())
            .setBufferSizeInBytes(trackBufferSize * 2)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
            .build();
}
```

### 6.2 TTS音频播放与缓冲

```java
private void playTTSAudio(List<byte[]> pcmChunks) {
    audioTrack.play();
    audioTrack.setVolume(1.0f);
    
    for (byte[] chunkData : pcmChunks) {
        // 播放音频数据
        audioTrack.write(chunkData, 0, chunkData.length);
        
        // 同时缓冲TTS参考信号用于AEC
        if (enableAecSync && aec3Processor != null) {
            bufferTTSFrames(chunkData);
        }
    }
}

private void bufferTTSFrames(byte[] chunkData) {
    float[] floatData = byteArrayToFloatArray(chunkData);
    
    int offset = 0;
    while (offset + AEC3_FRAME_SIZE <= floatData.length) {
        float[] frame = new float[AEC3_FRAME_SIZE];
        System.arraycopy(floatData, offset, frame, 0, AEC3_FRAME_SIZE);
        
        // 转换为short数组并缓冲
        short[] shortFrame = new short[AEC3_FRAME_SIZE];
        for (int j = 0; j < AEC3_FRAME_SIZE; j++) {
            shortFrame[j] = (short) (frame[j] * Short.MAX_VALUE);
        }
        
        ttsFrameBuffer.offer(shortFrame);
        offset += AEC3_FRAME_SIZE;
    }
}
```

## 7. AudioRecord配置（录音端）

### 7.1 AudioRecord初始化

```java
private void initializeAudioRecord() {
    // 尝试多种音频源以确保兼容性
    int[] audioSources = {
        MediaRecorder.AudioSource.MIC,
        MediaRecorder.AudioSource.VOICE_COMMUNICATION,
        MediaRecorder.AudioSource.VOICE_RECOGNITION
    };
    
    for (int source : audioSources) {
        try {
            audioRecord = new AudioRecord(source, SAMPLE_RATE, 
                    AudioFormat.CHANNEL_IN_MONO, AUDIO_FORMAT, BUFFER_SIZE * 2);
            
            if (audioRecord.getState() == AudioRecord.STATE_INITIALIZED) {
                Log.i(TAG, "AudioRecord初始化成功，音频源: " + source);
                break;
            }
        } catch (Exception e) {
            Log.w(TAG, "音频源" + source + "初始化失败", e);
        }
    }
}
```

### 7.2 实时AEC处理

```java
private void startAECRecording() {
    enableAecSync = true;
    cleanAudioFrames.clear();
    
    new Thread(() -> {
        audioRecord.startRecording();
        byte[] buffer = new byte[BUFFER_SIZE];
        
        while (isRecording) {
            int bytesRead = audioRecord.read(buffer, 0, buffer.length);
            
            if (bytesRead > 0) {
                processAudioWithAEC(buffer, bytesRead);
            }
        }
        
        audioRecord.stop();
    }).start();
}

private void processAudioWithAEC(byte[] buffer, int bytesRead) {
    float[] micData = byteArrayToFloatArray(buffer, bytesRead);
    
    int offset = 0;
    while (offset + AEC3_FRAME_SIZE <= micData.length) {
        // 提取麦克风帧
        float[] micFrame = new float[AEC3_FRAME_SIZE];
        System.arraycopy(micData, offset, micFrame, 0, AEC3_FRAME_SIZE);
        
        // 转换为short数组
        short[] micShortFrame = new short[AEC3_FRAME_SIZE];
        for (int j = 0; j < AEC3_FRAME_SIZE; j++) {
            micShortFrame[j] = (short) (micFrame[j] * Short.MAX_VALUE);
        }
        
        // 获取对应的TTS参考帧
        short[] ttsFrame = ttsFrameBuffer.poll();
        
        if (ttsFrame != null) {
            // 先处理TTS参考信号
            aec3Processor.processTtsAudio(ttsFrame);
        }
        
        // 处理麦克风信号并获取清洁输出
        short[] cleanOutput = aec3Processor.processMicrophoneAudio(micShortFrame);
        
        if (cleanOutput != null) {
            // 转换回float并保存
            float[] cleanFrame = new float[AEC3_FRAME_SIZE];
            for (int j = 0; j < AEC3_FRAME_SIZE; j++) {
                cleanFrame[j] = cleanOutput[j] / (float) Short.MAX_VALUE;
            }
            cleanAudioFrames.add(cleanFrame);
            
            // 获取性能指标
            WqAecProcessor.EnhancedAecMetrics metrics = aec3Processor.getEnhancedMetrics();
            if (metrics != null) {
                float erle = (float) metrics.echoReturnLossEnhancement;
                int delay = metrics.delayMs;
                Log.d(TAG, String.format("ERLE: %.1fdB, 延迟: %dms", erle, delay));
            }
        }
        
        offset += AEC3_FRAME_SIZE;
    }
}
```

## 8. 性能监控和优化

### 8.1 ERLE性能监控

```java
private void monitorERLEPerformance() {
    WqAecProcessor.EnhancedAecMetrics metrics = aec3Processor.getEnhancedMetrics();
    if (metrics != null) {
        float erle = (float) metrics.echoReturnLossEnhancement;
        int delay = metrics.delayMs;
        String quality = metrics.getErleQuality();
        boolean synced = metrics.isFrameSynchronized();
        
        Log.i(TAG, String.format("ERLE: %.1fdB (%s), 延迟: %dms, 同步: %s", 
                erle, quality, delay, synced ? "是" : "否"));
        
        // ERLE性能评估
        if (erle > 15.0f) {
            Log.i(TAG, "🎉 AEC3性能卓越");
        } else if (erle > 10.0f) {
            Log.i(TAG, "🎯 AEC3性能良好");
        } else if (erle > 5.0f) {
            Log.w(TAG, "⚠️ AEC3性能一般，需要优化");
        } else {
            Log.e(TAG, "❌ AEC3性能差，急需优化");
        }
    }
}
```

### 8.2 自动延迟优化

```java
private void autoOptimizeDelay() {
    if (aec3Processor != null) {
        boolean result = aec3Processor.autoOptimizeDelay();
        if (result) {
            WqAecProcessor.EnhancedAecMetrics metrics = aec3Processor.getEnhancedMetrics();
            if (metrics != null) {
                currentStreamDelay = metrics.optimalDelayMs;
                Log.i(TAG, "自动优化完成，最优延迟: " + currentStreamDelay + "ms");
            }
        }
    }
}
```

## 9. 清洁音频获取

### 9.1 从处理器缓冲区获取清洁音频

```java
private void getCleanAudioFromProcessor() {
    if (aec3Processor != null) {
        try {
            // 获取WAV格式清洁音频（44.1kHz）
            byte[] cleanWavData = aec3Processor.getCleanAudioAsWAV(44100);
            if (cleanWavData != null && cleanWavData.length > 0) {
                saveCleanAudioToFile(cleanWavData, "wav");
            }
            
            // 获取PCM格式清洁音频（16kHz）
            byte[] cleanPcmData = aec3Processor.getCleanAudioAsPCM(16000);
            if (cleanPcmData != null && cleanPcmData.length > 0) {
                saveCleanAudioToFile(cleanPcmData, "pcm");
            }
            
        } catch (Exception e) {
            Log.e(TAG, "获取清洁音频失败", e);
        }
    }
}
```

### 9.2 清洁音频文件保存

```java
private void saveCleanAudioToFile(byte[] audioData, String format) {
    try {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault());
        String timestamp = sdf.format(new Date());
        String filename = "clean_audio_" + timestamp + "." + format;
        
        File documentsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOCUMENTS);
        if (!documentsDir.exists()) {
            documentsDir.mkdirs();
        }
        File audioFile = new File(documentsDir, filename);
        
        try (FileOutputStream fos = new FileOutputStream(audioFile)) {
            fos.write(audioData);
            fos.flush();
        }
        
        Log.i(TAG, "清洁音频已保存: " + audioFile.getAbsolutePath());
        
    } catch (Exception e) {
        Log.e(TAG, "保存清洁音频失败", e);
    }
}
```

## 10. 资源清理

### 10.1 停止录音和清理

```java
private void stopRecordingAndCleanup() {
    // 停止录音
    isRecording = false;
    enableAecSync = false;
    
    // 清理缓冲区
    ttsFrameBuffer.clear();
    
    // 获取清洁音频
    getCleanAudioFromProcessor();
    
    // 释放资源
    if (audioRecord != null) {
        audioRecord.stop();
        audioRecord.release();
        audioRecord = null;
    }
    
    if (audioTrack != null) {
        audioTrack.stop();
        audioTrack.release();
        audioTrack = null;
    }
    
    // 清理处理器缓冲区
    if (aec3Processor != null) {
        aec3Processor.clearCleanAudioBuffer();
    }
}
```

### 10.2 销毁AEC3处理器

```java
@Override
protected void onDestroy() {
    super.onDestroy();
    
    stopRecordingAndCleanup();
    
    // 销毁AEC3处理器
    if (aec3Processor != null) {
        aec3Processor.destroy();
        aec3Processor = null;
    }
    
    Log.i(TAG, "所有资源已释放");
}
```

## 11. 工具方法

### 11.1 音频数据转换

```java
private float[] byteArrayToFloatArray(byte[] bytes) {
    return byteArrayToFloatArray(bytes, bytes.length);
}

private float[] byteArrayToFloatArray(byte[] bytes, int length) {
    float[] floats = new float[length / 2];
    ByteBuffer byteBuffer = ByteBuffer.wrap(bytes, 0, length)
            .order(ByteOrder.LITTLE_ENDIAN);
    
    for (int i = 0; i < floats.length; i++) {
        short sample = byteBuffer.getShort(i * 2);
        floats[i] = sample / 32768.0f; // 归一化到[-1.0, 1.0]
    }
    
    return floats;
}
```

## 12. 注意事项

### 12.1 必须遵循的要求

1. **采样率**: 必须使用48kHz，这是AEC3的硬性要求
2. **帧大小**: 必须使用480样本（10ms @ 48kHz）
3. **处理顺序**: 先处理TTS参考信号，再处理麦克风信号
4. **同步性**: TTS播放和麦克风录音必须帧级同步

### 12.2 性能优化建议

1. **延迟调优**: 根据设备特性调整streamDelay（通常5-200ms）
2. **ERLE目标**: 追求ERLE > 15dB的卓越性能
3. **内存管理**: 及时清理音频缓冲区避免内存泄漏
4. **线程安全**: 使用适当的同步机制保护共享资源

### 12.3 常见问题解决

1. **ERLE过低**: 检查延迟设置、TTS音量、麦克风增益
2. **音频断断续续**: 增加缓冲区大小、优化线程优先级
3. **初始化失败**: 检查权限、音频设备占用情况
4. **设备兼容性**: 尝试不同的AudioSource类型

---

**版本**: wq-aec3-1.0.aar  
**更新时间**: 2025-01-31  
**支持的Android版本**: API 21+  
**推荐测试设备**: 中高端Android设备以获得最佳性能
