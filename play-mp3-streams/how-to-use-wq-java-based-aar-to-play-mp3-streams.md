# WQMp3StreamPlayer AAR 使用指南

> 作者：Jimmy Gan  
> 日期：2025-12-24  
> 版本：v1.5.0

## 目录

1. [简介](#1-简介)
2. [快速开始](#2-快速开始)
3. [详细集成步骤](#3-详细集成步骤)
4. [API使用说明](#4-api使用说明)
5. [完整示例代码](#5-完整示例代码)
6. [常见问题](#6-常见问题)
7. [最佳实践](#7-最佳实践)
8. [故障排查](#8-故障排查)

---

## 1. 简介

### 1.1 什么是 WQMp3StreamPlayer？

WQMp3StreamPlayer 是一个轻量级高性能的 Android AAR 库，专注于播放 MP3 音频流。**本库不处理网络连接或 WebSocket 通信**，而是由应用层负责数据接收，AAR 只负责播放，这使得它更加灵活和通用。

### 1.2 核心特性

-  **简单纯粹**：只负责 MP3 流播放，不涉及网络层
-  **灵活通用**：适用于任何数据源（WebSocket、HTTP、本地文件等）
-  **头部处理**：可选的12字节头部自动移除功能
-  **状态监听**：完善的回调机制，实时获取播放状态
-  **资源高效**：自动管理音频缓冲和播放资源
-  **线程安全**：内部处理了线程切换
-  **音量控制**：支持静音和恢复音量功能 (v1.3.0)
-  **自动完成检测**：自动识别空流完成信号，5秒超时 (v1.3.0)
-  **多轮播放**：支持同一WebSocket连接多轮播放，自动状态管理 (v1.3.0)
-  **头部信息提取**：feedDataWithHeader()方法可返回startTimeId和messageId (v1.5.0)

### 1.3 什么时候需要移除头部？

如果您的服务器在每个音频数据包前添加了 12 字节头部（8字节 startTimeId + 4字节 messageId），则需要配置头部信息。如果没有头部，则不需要配置。

**服务器端代码示例（Python）：**
```python
# 如果发送了头部
header_bytes = struct.pack('>QI', start_time_id, message_id)  # 12字节
audio_bytes_with_headers = header_bytes + audio_bytes
websocket.send(audio_bytes_with_headers)

# 如果没有头部（直接发送音频）
websocket.send(audio_bytes)
```

---

## 2. 快速开始

### 2.1 前置要求

- **Android Studio**: Arctic Fox (2020.3.1) 或更高版本
- **Gradle**: 7.0 或更高版本
- **minSdkVersion**: 24 (Android 7.0)
- **targetSdkVersion**: 34
- **Java**: JDK 17

### 2.2 三分钟快速集成

#### 步骤 1：添加 AAR 依赖

**方式一：使用 Maven 本地仓库（推荐）- Media3依赖自动包含**

1. 将整个 `libs-maven` 文件夹复制到项目的 `app/` 目录
2. 在项目根目录的 `settings.gradle.kts` 中添加：

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("${rootProject.projectDir.absolutePath}/app/libs-maven")
        }
    }
}
```

3. 在 `app/build.gradle.kts` 中添加：

```kotlin
dependencies {
    // WQMp3StreamPlayer - Media3依赖会自动包含
    implementation("cn.watchfun:wqmp3streamplayer:1.0.0")
    
    // 如果使用WebSocket，需要添加OkHttp
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
```

**方式二：使用 AAR 文件 - 需要手动添加Media3依赖**

将 `wqmp3streamplayer.aar` 文件复制到项目的 `app/libs/` 目录，然后在 `app/build.gradle` 中添加：

```gradle
dependencies {
    implementation files('libs/wqmp3streamplayer.aar')
    
    // 必需的Media3依赖
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-datasource:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    
    // 如果使用WebSocket，需要添加OkHttp
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
}
```

#### 步骤 2：添加权限

在 `AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### 步骤 3：使用播放器

```java
import java.util.concurrent.atomic.AtomicBoolean;
import cn.watchfun.mp3streamplayer.WQMp3StreamPlayer;
import cn.watchfun.mp3streamplayer.PlayerCallback;
import cn.watchfun.mp3streamplayer.PlayerState;
import cn.watchfun.mp3streamplayer.StreamConfig;

// 1. 创建播放器
WQMp3StreamPlayer player = new WQMp3StreamPlayer(context);
final AtomicBoolean isPlaying = new AtomicBoolean(false);

// 2. 设置回调
player.setCallback(new PlayerCallback() {
    @Override
    public void onStateChanged(PlayerState state) {
        // 处理状态变化
        if (state == PlayerState.STOPPED || state == PlayerState.ENDED || state == PlayerState.ERROR) {
            isPlaying.set(false);
        }
    }
    
    @Override
    public void onError(String errorMessage, Throwable throwable) {
        Log.e(TAG, "播放错误: " + errorMessage, throwable);
        isPlaying.set(false);
    }
    
    @Override
    public void onPlaybackCompleted() {
        Log.d(TAG, "播放完成");
        isPlaying.set(false);
    }
});

// 3. 初始化播放器
// 如果数据有12字节头部，配置头部信息
StreamConfig config = new StreamConfig.Builder()
        .setStartTimeId(System.currentTimeMillis())
        .setMessageId(1)
        .build();
player.initialize(config);

// 如果数据没有头部，使用默认配置
// player.initialize(null);

// 4. 启动播放器
player.start();
isPlaying.set(true);

// 5. 在接收到WebSocket数据时，喂给播放器
webSocket = okHttpClient.newWebSocket(request, new WebSocketListener() {
    @Override
    public void onMessage(WebSocket webSocket, ByteString bytes) {
        if (player != null) {
            player.feedData(bytes.toByteArray());
        }
    }
    
    @Override
    public void onClosed(WebSocket webSocket, int code, String reason) {
        // 通知播放器数据传输完成
        if (player != null) {
            player.notifyDataComplete();
        }
    }
});

// 6. 停止播放
if (player != null) {
    player.stop();
}
isPlaying.set(false);

// 7. 释放资源（在onDestroy中）
if (player != null) {
    player.release();
    player = null;
}
```

---

## 3. 详细集成步骤

### 3.1 添加 AAR 到项目

#### 方式一：使用 Maven 本地仓库（推荐）

**优点**：Media3依赖自动包含，无需手动添加

```
YourProject/
├── app/
│   ├── libs-maven/  ← 复制整个文件夹到这里
│   │   └── cn/
│   │       └── watchfun/
│   │           └── wqmp3streamplayer/
│   │               ├── 1.0.0/
│   │               └── maven-metadata.xml
│   ├── build.gradle.kts
│   └── src/
├── settings.gradle.kts  ← 在这里配置
```

在项目根目录的 `settings.gradle.kts` 中：

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("${rootProject.projectDir.absolutePath}/app/libs-maven")
        }
    }
}
```

在 `app/build.gradle.kts` 中：

```kotlin
android {
    compileSdk = 34
    
    defaultConfig {
        minSdk = 24
        targetSdk = 34
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    // WQMp3StreamPlayer - Media3依赖自动包含
    implementation("cn.watchfun:wqmp3streamplayer:1.0.0")
    
    // OkHttp - WebSocket 通信（如需要）
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
```

#### 方式二：使用 AAR 文件

**优点**：简单直接  
**缺点**：需要手动添加Media3依赖

```
YourProject/
├── app/
│   ├── libs/
│   │   └── wqmp3streamplayer.aar  ← 放在这里
│   ├── build.gradle
│   └── src/
```

在 `app/build.gradle` 中：

```gradle
android {
    compileSdk 34
    
    defaultConfig {
        minSdk 24
        targetSdk 34
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    // AAR 库
    implementation files('libs/wqmp3streamplayer.aar')
    
    // Media3 库 - 必需依赖（手动添加）
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-datasource:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    
    // OkHttp - WebSocket 通信（应用层使用，如需要）
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
}
```

### 3.2 同步项目

点击 Android Studio 工具栏的 "Sync Now" 或运行：

```bash
./gradlew clean build
```

---

## 4. API 使用说明

### 4.1 WQMp3StreamPlayer 类

这是主要的 API 类，负责 MP3 流播放控制。

#### 4.1.1 构造函数

```java
public WQMp3StreamPlayer(@NonNull Context context)
```

**示例：**
```java
WQMp3StreamPlayer player = new WQMp3StreamPlayer(this);
```

#### 4.1.2 核心方法

| 方法 | 说明 | 参数 |
|------|------|------|
| `setCallback(PlayerCallback)` | 设置状态回调 | 回调接口 |
| `initialize(StreamConfig)` | 初始化配置 | 流配置（可null） |
| `initialize(StreamConfig, float)` | 初始化配置（带超时） | 流配置、超时秒数 (v1.3.0) |
| `start()` | 开始播放 | 无 |
| `feedData(byte[])` | 喂入音频数据 | 音频数据字节数组 |
| `feedDataWithHeader(byte[])` | 喂入音频数据并返回头部信息 | 音频数据字节数组 (v1.5.0) |
| `notifyDataComplete()` | 通知数据传输完成 | 无 |
| `stop()` | 停止播放 | 无 |
| `pause()` | 暂停播放 | 无 |
| `resume()` | 恢复播放 | 无 |
| `setVolume(float)` | 设置音量 | 音量值 0.0-1.0 (v1.3.0) |
| `getVolume()` | 获取当前音量 | 无 (v1.3.0) |
| `mute()` | 静音 | 无 (v1.3.0) |
| `restoreVolume(float)` | 恢复音量 | 之前的音量值 (v1.3.0) |
| `getCurrentState()` | 获取当前状态 | 无 |
| `isPlaying()` | 是否正在播放 | 无 |
| `release()` | 释放所有资源 | 无 |

#### 4.1.3 方法详解

##### initialize(StreamConfig) / initialize(StreamConfig, float)

初始化播放器配置。如果音频数据包含12字节头部，需要配置 `startTimeId` 和 `messageId`。

**v1.3.0 新增：** 支持设置超时参数，如果在指定时间内没有新数据，将自动标记完成。

```java
// 有头部的情况
StreamConfig config = new StreamConfig.Builder()
        .setStartTimeId(123456L)  // 8字节
        .setMessageId(789)        // 4字节
        .build();
player.initialize(config);

// 无头部的情况（推荐 - AAR会自动检测）
player.initialize(null, 5.0f);  // 5秒超时

// 使用默认超时（5秒）
player.initialize(null);
```

##### start()

启动播放器，创建内部播放引擎并开始缓冲。

```java
player.start();
```

##### feedData(byte[]) / feedDataWithHeader(byte[])

这是最重要的方法，用于将接收到的音频数据喂给播放器。

**v1.3.0 新增：** 自动检测空流完成信号（0字节或12字节头部空流）。

**v1.5.0 新增：** `feedDataWithHeader()` 方法可以返回从MP3数据中提取的 `startTimeId` 和 `messageId`。

```java
// 在WebSocket回调中接收MP3数据
@Override
public void onMessage(WebSocket webSocket, ByteString bytes) {
    byte[] data = bytes.toByteArray();
    Log.d(TAG, "接收到MP3数据: " + data.length + " 字节");
    
    // 将数据传递给播放器并获取头部信息（使用AAR）
    if (player != null) {
        WQMp3StreamPlayer.HeaderInfo headerInfo = player.feedDataWithHeader(data);
        if (headerInfo.hasHeader) {
            // 从MP3数据中提取的startTimeId和messageId
            Log.d(TAG, "从MP3数据提取 - startTimeId: " + headerInfo.startTimeId + ", messageId: " + headerInfo.messageId);
        }
    }
    
    // 或者使用简单方式（不获取头部信息）：
    // if (player != null) {
    //     player.feedData(data);
    // }
}
```

**HeaderInfo 类 (v1.5.0)：**
```java
public static class HeaderInfo {
    public final long startTimeId;   // 8字节开始时间ID
    public final int messageId;      // 4字节消息ID
    public final boolean hasHeader;  // 是否包含头部
}
```

**头部处理逻辑：**
- 如果配置了 `startTimeId` 和 `messageId`，AAR 会自动移除每个数据包前的 12 字节
- 如果没有配置，AAR 直接播放原始数据

**自动完成检测 (v1.3.0)：**
- 检测0字节空流：自动触发完成
- 检测12字节头部空流：自动触发完成
- 无需手动调用 `notifyDataComplete()`

##### notifyDataComplete()

通知播放器所有数据已传输完成，播放器会在播放完缓冲数据后触发 `onPlaybackCompleted()` 回调。

**v1.3.0 注意：** 大多数情况下不需要手动调用此方法，AAR会自动检测空流完成信号。

```java
// 当WebSocket收到结束信号或连接关闭时（可选）
player.notifyDataComplete();
```

##### stop()

停止播放并清理资源，但不释放播放器实例。

```java
player.stop();
```

##### setVolume(float) / getVolume() (v1.3.0)

控制播放音量。

```java
// 设置音量（0.0 = 静音，1.0 = 最大音量）
player.setVolume(0.5f);  // 50%音量

// 获取当前音量
float currentVolume = player.getVolume();
```

##### mute() / restoreVolume(float) (v1.3.0)

静音和恢复音量的便捷方法。

```java
// 保存当前音量并静音
float previousVolume = player.getVolume();
player.mute();  // 设置音量为0

// 恢复之前的音量
player.restoreVolume(previousVolume);
```

##### release()

释放所有资源，**必须**在 Activity/Fragment 销毁时调用。

```java
@Override
protected void onDestroy() {
    super.onDestroy();
    if (player != null) {
        player.release();
        player = null;
    }
}
```

### 4.2 StreamConfig 类

流配置类，用于配置头部移除功能。

#### 4.2.1 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `startTimeId` | Long | null | 开始时间ID（8字节，可选） |
| `messageId` | Integer | null | 消息ID（4字节，可选） |

#### 4.2.2 使用示例

**场景 1：服务器发送的数据包含头部**

```java
// 服务器端在每个音频包前添加了12字节头部
StreamConfig config = new StreamConfig.Builder()
        .setStartTimeId(System.currentTimeMillis())  // 与服务器一致
        .setMessageId(1001)                          // 与服务器一致
        .build();
player.initialize(config);
```

**场景 2：服务器发送的数据不包含头部**

```java
// 直接播放原始MP3数据
player.initialize(null);
```

### 4.3 PlayerCallback 接口

用于接收播放器状态和事件的回调接口。

#### 4.3.1 回调方法

```java
public interface PlayerCallback {
    void onStateChanged(@NonNull PlayerState state);
    void onError(@NonNull String errorMessage, @Nullable Throwable throwable);
    void onPlaybackCompleted();
}
```

#### 4.3.2 实现示例

```java
player.setCallback(new PlayerCallback() {
    @Override
    public void onStateChanged(PlayerState state) {
        Log.d(TAG, "状态变化: " + state);
        switch (state) {
            case IDLE:
                updateUI("空闲");
                break;
            case BUFFERING:
                showProgressBar(true);
                updateUI("缓冲中...");
                break;
            case PLAYING:
                showProgressBar(false);
                updateUI("播放中");
                break;
            case STOPPED:
                updateUI("已停止");
                break;
            case ENDED:
                updateUI("播放完成");
                break;
            case ERROR:
                updateUI("错误");
                break;
        }
    }
    
    @Override
    public void onError(String errorMessage, Throwable throwable) {
        Log.e(TAG, "错误: " + errorMessage, throwable);
        Toast.makeText(this, "播放错误: " + errorMessage, Toast.LENGTH_LONG).show();
    }
    
    @Override
    public void onPlaybackCompleted() {
        Log.d(TAG, "播放完成");
        Toast.makeText(this, "播放完成", Toast.LENGTH_SHORT).show();
        // 可以播放下一个或重置UI
    }
});
```

### 4.4 PlayerState 枚举

播放器状态枚举值。

| 状态 | 说明 | 何时触发 |
|------|------|----------|
| `IDLE` | 空闲状态 | 初始状态、释放后 |
| `BUFFERING` | 缓冲中 | 开始播放但数据不足 |
| `PLAYING` | 播放中 | 正在播放音频 |
| `STOPPED` | 已停止 | 调用 stop() 后 |
| `ENDED` | 已结束 | 播放完成 |
| `ERROR` | 错误状态 | 发生错误 |

---

## 5. 完整示例代码

### 5.1 Activity 完整实现

```java
package com.example.ttsplayer;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import org.json.JSONObject;

import cn.watchfun.mp3streamplayer.PlayerCallback;
import cn.watchfun.mp3streamplayer.PlayerState;
import cn.watchfun.mp3streamplayer.StreamConfig;
import cn.watchfun.mp3streamplayer.WQMp3StreamPlayer;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import okio.ByteString;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";
    
    // WebSocket配置（应用层处理）
    private static final String WS_URL = "ws://minimax-dev.watchfun.cn/tts";
    private static final String API_KEY = "your-api-key-here";
    
    // UI 组件
    private TextView tvStatus;
    private EditText etText;
    private Button btnConnect;
    private Button btnPlay;
    private Button btnStop;
    
    // WebSocket（应用层管理）
    private OkHttpClient okHttpClient;
    private WebSocket webSocket;
    private boolean isConnected = false;
    
    // 播放器（AAR提供）
    private WQMp3StreamPlayer player;
    private Handler mainHandler;
    
    // 消息头信息（如果需要）
    private long startTimeId = System.currentTimeMillis();
    private int messageId = 1;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        mainHandler = new Handler(Looper.getMainLooper());
        
        initViews();
        initWebSocket();
        initPlayer();
        setupListeners();
    }
    
    private void initViews() {
        tvStatus = findViewById(R.id.tvStatus);
        etText = findViewById(R.id.etText);
        btnConnect = findViewById(R.id.btnConnect);
        btnPlay = findViewById(R.id.btnPlay);
        btnStop = findViewById(R.id.btnStop);
        
        etText.setText("世界是一幅由无限多样的丝线编织而成的织锦。");
    }
    
    /**
     * 初始化WebSocket（应用层负责）
     */
    private void initWebSocket() {
        okHttpClient = new OkHttpClient.Builder()
                .retryOnConnectionFailure(true)
                .build();
    }
    
    /**
     * 初始化播放器（使用AAR）
     */
    private void initPlayer() {
        player = new WQMp3StreamPlayer(this);
        
        player.setCallback(new PlayerCallback() {
            @Override
            public void onStateChanged(PlayerState state) {
                updateStatus("播放器: " + state);
            }
            
            @Override
            public void onError(String errorMessage, Throwable throwable) {
                Toast.makeText(MainActivity.this, errorMessage, Toast.LENGTH_LONG).show();
            }
            
            @Override
            public void onPlaybackCompleted() {
                Toast.makeText(MainActivity.this, "播放完成", Toast.LENGTH_SHORT).show();
            }
        });
    }
    
    private void setupListeners() {
        btnConnect.setOnClickListener(v -> {
            if (isConnected) {
                disconnectWebSocket();
            } else {
                connectWebSocket();
            }
        });
        
        btnPlay.setOnClickListener(v -> startPlayback());
        btnStop.setOnClickListener(v -> stopPlayback());
    }
    
    /**
     * 连接WebSocket（应用层实现）
     */
    private void connectWebSocket() {
        Request request = new Request.Builder()
                .url(WS_URL)
                .addHeader("x-api-key", API_KEY)
                .build();
        
        webSocket = okHttpClient.newWebSocket(request, new WebSocketListener() {
            @Override
            public void onOpen(WebSocket webSocket, Response response) {
                isConnected = true;
                mainHandler.post(() -> {
                    btnConnect.setText("断开");
                    btnPlay.setEnabled(true);
                });
            }
            
            @Override
            public void onMessage(WebSocket webSocket, ByteString bytes) {
                // 关键：将接收到的数据传递给播放器
                if (player != null) {
                    player.feedData(bytes.toByteArray());
                }
            }
            
            @Override
            public void onClosed(WebSocket webSocket, int code, String reason) {
                isConnected = false;
                // 通知播放器数据传输完成
                if (player != null) {
                    player.notifyDataComplete();
                }
            }
            
            @Override
            public void onFailure(WebSocket webSocket, Throwable t, Response response) {
                isConnected = false;
                mainHandler.post(() -> {
                    Toast.makeText(MainActivity.this, "连接失败", Toast.LENGTH_SHORT).show();
                });
            }
        });
    }
    
    private void disconnectWebSocket() {
        if (webSocket != null) {
            webSocket.close(1000, "用户断开");
            webSocket = null;
        }
        isConnected = false;
    }
    
    /**
     * 开始播放
     */
    private void startPlayback() {
        String text = etText.getText().toString().trim();
        if (text.isEmpty()) {
            Toast.makeText(this, "请输入文本", Toast.LENGTH_SHORT).show();
            return;
        }
        
        // 配置播放器
        // 如果服务器发送的数据有12字节头部
        StreamConfig config = new StreamConfig.Builder()
                .setStartTimeId(startTimeId)
                .setMessageId(messageId)
                .build();
        player.initialize(config);
        
        // 如果服务器发送的数据没有头部，使用：
        // player.initialize(null);
        
        // 启动播放器
        player.start();
        
        // 发送TTS请求
        sendTTSRequest(text);
    }
    
    private void sendTTSRequest(String text) {
        try {
            JSONObject request = new JSONObject();
            request.put("text", text);
            request.put("model", "speech-02-turbo");
            request.put("speakerId", "0029532abc4672af1243539d5cac6f4d");
            request.put("outputSampleRate", 16000);
            request.put("audioFormat", "mp3");
            request.put("speed", 1.0);
            
            // MP3 chunk时长设置，值越小响应越快，默认0.25秒
            request.put("chunkDuration", 0.25);
            
            // 如果需要头部信息
            request.put("startTimeId", startTimeId);
            request.put("messageId", messageId);
            
            webSocket.send(request.toString());
        } catch (Exception e) {
            Log.e(TAG, "发送请求失败", e);
        }
    }
    
    private void stopPlayback() {
        if (player != null) {
            player.stop();
        }
    }
    
    private void updateStatus(String status) {
        tvStatus.setText(status);
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        
        if (player != null) {
            player.release();
        }
        
        if (isConnected) {
            disconnectWebSocket();
        }
        
        if (okHttpClient != null) {
            okHttpClient.dispatcher().executorService().shutdown();
        }
    }
}
```

### 5.2 布局文件

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">
    
    <TextView
        android:id="@+id/tvStatus"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="状态: 就绪"
        android:textSize="16sp"
        android:padding="12dp"
        android:background="#E3F2FD"
        android:layout_marginBottom="16dp"/>
    
    <EditText
        android:id="@+id/etText"
        android:layout_width="match_parent"
        android:layout_height="120dp"
        android:gravity="top|start"
        android:hint="输入要播放的文本..."
        android:inputType="textMultiLine"
        android:padding="12dp"
        android:layout_marginBottom="16dp"/>
    
    <Button
        android:id="@+id/btnConnect"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="连接WebSocket"
        android:layout_marginBottom="8dp"/>
    
    <Button
        android:id="@+id/btnPlay"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="播放"
        android:enabled="false"
        android:layout_marginBottom="8dp"/>
    
    <Button
        android:id="@+id/btnStop"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="停止"
        android:enabled="false"/>
    
</LinearLayout>
```

---

## 6. 常见问题

### Q1: 播放有杂音或卡顿？

**A:** 检查是否正确配置了头部信息。如果服务器发送的数据包含12字节头部，必须配置 `startTimeId` 和 `messageId`：

```java
StreamConfig config = new StreamConfig.Builder()
        .setStartTimeId(startTimeId)
        .setMessageId(messageId)
        .build();
player.initialize(config);
```

### Q2: 如何判断服务器是否发送了头部？

**A:** 检查服务器端代码。如果看到类似这样的代码，说明有头部：

```python
# Python示例
header_bytes = struct.pack('>QI', start_time_id, message_id)
audio_bytes_with_headers = header_bytes + audio_bytes
```

或查看网络抓包，如果每个数据包前12字节不是MP3数据，则是头部。

### Q3: 为什么需要移除头部？

**A:** MP3 解码器只能识别标准的 MP3 数据格式。如果数据包前有额外的头部信息，解码器会将其误认为是音频数据，导致杂音、卡顿或播放失败。

### Q4: startTimeId 和 messageId 的值从哪里来？

**A:** 这些值通常由应用层生成，并在发送TTS请求时一起发送给服务器：

```java
long startTimeId = System.currentTimeMillis();
int messageId = 1001;

// 发送给服务器
JSONObject request = new JSONObject();
request.put("startTimeId", startTimeId);
request.put("messageId", messageId);
request.put("text", "要播放的文本");
webSocket.send(request.toString());

// 配置播放器（使用相同的值）
StreamConfig config = new StreamConfig.Builder()
        .setStartTimeId(startTimeId)
        .setMessageId(messageId)
        .build();
```

### Q5: 可以播放其他格式的音频吗（如PCM）？

**A:** 当前版本专注于 MP3 格式。如需支持 PCM，请联系技术支持。

### Q6: 如何实现播放列表？

**A:** 在 `onPlaybackCompleted()` 回调中播放下一个：

```java
private List<String> playlist = new ArrayList<>();
private int currentIndex = 0;

@Override
public void onPlaybackCompleted() {
    currentIndex++;
    if (currentIndex < playlist.size()) {
        playNext();
    }
}
```

### Q7: WebSocket 连接失败怎么办？

**A:** WebSocket 连接由应用层负责，请检查：
1. URL 是否正确（ws:// 或 wss://）
2. API Key 是否有效
3. 网络权限是否已添加
4. 网络连接是否正常

### Q8: 播放器占用内存大吗？

**A:** AAR 使用高效的流式播放技术，内存占用很小（通常 < 5MB）。记得在不使用时调用 `release()` 释放资源。

---

## 7. 最佳实践

### 7.1 资源管理

```java
//  正确做法
@Override
protected void onDestroy() {
    super.onDestroy();
    if (player != null) {
        player.release();
        player = null;
    }
}

//  错误做法 - 忘记释放
@Override
protected void onDestroy() {
    super.onDestroy();
    // 没有调用 release()，会导致内存泄漏
}
```

### 7.2 线程安全

```java
//  正确 - feedData() 可以在任何线程调用
webSocketThread.execute(() -> {
    player.feedData(audioData);  // 线程安全
});

//  也正确 - 在主线程调用
mainHandler.post(() -> {
    player.feedData(audioData);
});
```


### 7.3 错误处理

```java
player.setCallback(new PlayerCallback() {
    @Override
    public void onError(String errorMessage, Throwable throwable) {
        Log.e(TAG, "播放错误: " + errorMessage, throwable);
        
        // 显示用户友好的错误信息
        runOnUiThread(() -> {
            Toast.makeText(context, "播放失败，请重试", Toast.LENGTH_LONG).show();
        });
        
        // 上报错误到监控系统
        reportError(errorMessage, throwable);
    }
});
```

### 7.4 配置管理

```java
//  推荐 - 集中管理配置
public class AudioConfig {
    public static final String WS_URL = BuildConfig.WS_URL;
    public static final String API_KEY = BuildConfig.API_KEY;
    
    public static StreamConfig createWithHeaders(long startTimeId, int messageId) {
        return new StreamConfig.Builder()
                .setStartTimeId(startTimeId)
                .setMessageId(messageId)
                .build();
    }
    
    public static StreamConfig createWithoutHeaders() {
        return new StreamConfig.Builder().build();
    }
}
```

---

## 8. 故障排查

### 8.1 调试日志

AAR 内部使用 Android Log，过滤标签查看日志：

```bash
adb logcat -s WQMp3StreamPlayer:V WebSocketDataSource:V
```

**正常流程日志：**
```
D/WQMp3StreamPlayer: 初始化ExoPlayer
D/WQMp3StreamPlayer: 配置包含头部信息 - startTimeId: 1698765432, messageId: 1001
D/WQMp3StreamPlayer: 开始播放
D/WQMp3StreamPlayer: 播放器已启动
V/WQMp3StreamPlayer: 移除头部后数据大小: 4096 字节 (原始: 4108 字节)
D/WQMp3StreamPlayer: 状态更新: PLAYING
```

### 8.2 常见错误

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| "DataSource未打开，忽略数据" | 未调用 start() | 先调用 start() 再 feedData() |
| "头部验证失败" | 配置的ID与实际不符 | 检查 startTimeId 和 messageId 是否一致 |
| "播放错误: Source error" | 音频格式错误 | 检查是否正确移除了头部 |

### 8.3 性能优化

1. **及时释放**：不使用时立即调用 `release()`
2. **复用实例**：避免频繁创建销毁播放器
3. **控制缓冲**：如果网速慢，考虑预缓冲

---

**文档结束**

如有疑问或建议，请联系：jimmy@watchfun.cn
