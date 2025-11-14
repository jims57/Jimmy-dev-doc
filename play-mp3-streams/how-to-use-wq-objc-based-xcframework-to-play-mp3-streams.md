# WQMp3StreamPlayer XCFramework 使用指南 (iOS)

> 作者：Jimmy Gan  
> 日期：2025-11-14  
> 版本：v1.0.0

## 目录

1. [简介](#1-简介)
2. [快速开始](#2-快速开始)
3. [API使用说明](#3-api使用说明)
4. [完整示例](#4-完整示例)
5. [常见问题](#5-常见问题)

---

## 1. 简介

### 1.1 什么是 WQMp3StreamPlayer？

WQMp3StreamPlayer 是一个轻量级高性能的 iOS XCFramework 库，专注于播放 MP3 音频流。本库不处理网络连接或 WebSocket 通信，而是由应用层负责数据接收，XCFramework 只负责播放。

### 1.2 核心特性

- 简单纯粹：只负责 MP3 流播放，不涉及网络层
- 自动检测：自动检测MP3流是否包含12字节头部
- 灵活通用：适用于任何数据源（WebSocket、HTTP、本地文件等）
- 状态监听：完善的回调机制
- 静态库：无需嵌入，只需链接

### 1.3 自动头部检测（v2.0新特性）

XCFramework 会自动检测MP3流是否包含12字节头部（8字节 startTimeId + 4字节 messageId），应用层无需配置。

---

## 2. 快速开始

### 2.1 添加 XCFramework

1. 将 `WQMp3StreamPlayerFramework.xcframework` 复制到项目目录
2. Xcode -> Target -> General -> Frameworks, Libraries, and Embedded Content
3. 点击 + 号，选择 Add Files，选择 XCFramework
4. 设置为 Do Not Embed（静态库）

### 2.2 基本使用

```objc
#import <WQMp3StreamPlayerFramework/WQMp3StreamPlayerFramework.h>

// 1. 创建播放器
self.player = [[WQMp3StreamPlayer alloc] init];
self.player.callback = self;

// 2. 初始化（自动检测头部）
[self.player initializeWithConfig:nil timeout:15.0];

// 3. 启动
[self.player start];

// 4. 喂数据（在WebSocket回调中）
[self.player feedData:audioData];

// 5. 停止
[self.player stopImmediatelyAndReset];
```

---

## 3. API使用说明

### 3.1 核心方法

| 方法 | 说明 |
|------|------|
| `initializeWithConfig:timeout:` | 初始化（传nil自动检测头部） |
| `start` | 开始播放 |
| `feedData:` | 喂入音频数据 |
| `stopImmediatelyAndReset` | 立即停止并重置 |
| `notifyDataComplete` | 通知数据传输完成 |

### 3.2 回调协议

```objc
@protocol WQPlayerCallback <NSObject>
- (void)onStateChanged:(WQPlayerState)state;
- (void)onError:(NSString *)errorMessage error:(NSError *)error;
- (void)onPlaybackCompleted;
@end
```

### 3.3 播放器状态

| 状态 | 说明 |
|------|------|
| `WQPlayerStateIdle` | 空闲 |
| `WQPlayerStateBuffering` | 缓冲中 |
| `WQPlayerStatePlaying` | 播放中 |
| `WQPlayerStateStopped` | 已停止 |
| `WQPlayerStateEnded` | 已结束 |
| `WQPlayerStateError` | 错误 |

---

## 4. 完整示例

### 4.1 ViewController.h

```objc
#import <UIKit/UIKit.h>
#import <WQMp3StreamPlayerFramework/WQMp3StreamPlayerFramework.h>

@interface ViewController : UIViewController <WQPlayerCallback, NSURLSessionWebSocketDelegate>
@end
```

### 4.2 ViewController.m 关键代码

```objc
#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) WQMp3StreamPlayer *player;
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isPlaying;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化播放器
    self.player = [[WQMp3StreamPlayer alloc] init];
    self.player.callback = self;
}

// 连接WebSocket
- (void)connectWebSocket {
    NSURL *url = [NSURL URLWithString:@"ws://your-server.com/tts"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    self.webSocketTask = [session webSocketTaskWithRequest:request];
    [self.webSocketTask resume];
    [self receiveMessage];
    
    self.isConnected = YES;
}

// 接收WebSocket消息
- (void)receiveMessage {
    [self.webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage *message, NSError *error) {
        if (message.type == NSURLSessionWebSocketMessageTypeData) {
            // 喂数据给播放器（自动处理头部）
            [self.player feedData:message.data];
        }
        [self receiveMessage]; // 继续接收
    }];
}

// 开始播放
- (void)startPlayback {
    // 初始化（自动检测头部）
    [self.player initializeWithConfig:nil timeout:15.0];
    [self.player start];
    
    self.isPlaying = YES;
    
    // 发送TTS请求
    NSDictionary *request = @{
        @"model": @"speech-02-turbo",
        @"text": @"你好世界",
        @"audioFormat": @"mp3"
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:request options:0 error:nil];
    NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithData:jsonData];
    [self.webSocketTask sendMessage:message completionHandler:nil];
}

// 停止播放
- (void)stopPlayback {
    [self.player stopImmediatelyAndReset];
    self.isPlaying = NO;
}

#pragma mark - WQPlayerCallback

- (void)onStateChanged:(WQPlayerState)state {
    NSLog(@"状态: %ld", (long)state);
}

- (void)onError:(NSString *)errorMessage error:(NSError *)error {
    NSLog(@"错误: %@", errorMessage);
}

- (void)onPlaybackCompleted {
    NSLog(@"播放完成");
    self.isPlaying = NO;
}

@end
```

---

## 5. 常见问题

### Q1: 如何判断是否需要配置头部？

A: 不需要判断！v2.0版本会自动检测。推荐使用：
```objc
[self.player initializeWithConfig:nil timeout:15.0];
```

### Q2: 自动检测原理是什么？

A: XCFramework检查第一个数据块：
- 如果以MP3同步字节（0xFF）或ID3标签开头 -> 无头部
- 如果跳过12字节后是MP3数据 -> 有头部，自动移除

### Q3: 可以手动配置头部吗？

A: 可以，如果你确定有头部：
```objc
WQStreamConfig *config = [[WQStreamConfig alloc] initWithStartTimeId:123456 messageId:1];
[self.player initializeWithConfig:config timeout:15.0];
```

### Q4: 播放有杂音怎么办？

A: 使用v2.0自动检测功能即可解决。如果仍有问题，检查：
1. 网络数据是否完整
2. 服务器返回的是否是标准MP3格式

### Q5: 如何实现连续播放？

A: 在 `onPlaybackCompleted` 回调中开始下一个：
```objc
- (void)onPlaybackCompleted {
    [self playNext];
}
```

### Q6: 内存占用如何？

A: 使用流式播放技术，内存占用很小（通常 < 5MB）。

### Q7: 支持哪些iOS版本？

A: iOS 13.0 及以上版本。

---

## 6. 最佳实践

### 6.1 推荐用法

```objc
// 使用自动检测（推荐）
[self.player initializeWithConfig:nil timeout:15.0];
```

### 6.2 错误处理

```objc
- (void)onError:(NSString *)errorMessage error:(NSError *)error {
    NSLog(@"播放错误: %@", errorMessage);
    // 显示错误提示
    // 上报错误日志
}
```

### 6.3 资源管理

```objc
- (void)dealloc {
    [self.player stopImmediatelyAndReset];
}
```

---

## 7. 技术支持

如有疑问，请联系：jimmy@watchfun.cn

---

**文档结束**
