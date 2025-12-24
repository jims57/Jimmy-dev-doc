#!/bin/bash

# Android MP3流播放器SDK部署脚本
# 用于将Android项目复制到备份目录并压缩

# Usage:
# ./deploy_mp3_streams_player_sdk.sh --sdkVersion v1.5.0

# 默认SDK版本
SDK_VERSION="v1.5.0"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --sdkVersion)
            SDK_VERSION="$2"
            shift 2
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 源目录和目标目录
SOURCE_DIR="/Users/mac/Documents/GitHub/android_use_cpp"
BACKUP_DIR="/Users/mac/jims57/工作备份"
FOLDER_NAME="mp3流播放器SDK(${SDK_VERSION})"
TARGET_DIR="$BACKUP_DIR/$FOLDER_NAME"

echo "开始部署Android MP3流播放器SDK..."
echo "SDK版本: $SDK_VERSION"

# 1. 如果目标目录已存在，强制删除
if [ -d "$TARGET_DIR" ]; then
    echo "删除已存在的目录: $TARGET_DIR"
    rm -rf "$TARGET_DIR"
fi

# 2. 如果zip文件已存在，删除
if [ -f "$BACKUP_DIR/${FOLDER_NAME}.zip" ]; then
    echo "删除已存在的zip文件: $BACKUP_DIR/${FOLDER_NAME}.zip"
    rm -f "$BACKUP_DIR/${FOLDER_NAME}.zip"
fi

# 3. 创建目标目录
echo "创建目标目录: $TARGET_DIR"
mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR/app"
mkdir -p "$TARGET_DIR/gradle"

# 4. 复制指定的文件和目录
echo "复制文件到: $TARGET_DIR"

# 复制app目录下的内容
cp -r "$SOURCE_DIR/app/libs" "$TARGET_DIR/app/"
cp -r "$SOURCE_DIR/app/src" "$TARGET_DIR/app/"
cp "$SOURCE_DIR/app/.gitignore" "$TARGET_DIR/app/"
cp "$SOURCE_DIR/app/build.gradle.kts" "$TARGET_DIR/app/"
cp "$SOURCE_DIR/app/build.gradle.kts.backup" "$TARGET_DIR/app/"
cp "$SOURCE_DIR/app/proguard-rules.pro" "$TARGET_DIR/app/"

# 复制根目录下的文件
cp "$SOURCE_DIR/.gitattributes" "$TARGET_DIR/"
cp "$SOURCE_DIR/.gitignore" "$TARGET_DIR/"
cp "$SOURCE_DIR/build.gradle.kts" "$TARGET_DIR/"
cp "$SOURCE_DIR/gradle.properties" "$TARGET_DIR/"
cp "$SOURCE_DIR/gradlew" "$TARGET_DIR/"
cp "$SOURCE_DIR/gradlew.bat" "$TARGET_DIR/"
cp "$SOURCE_DIR/local.properties" "$TARGET_DIR/"
cp "$SOURCE_DIR/QUICK_START.md" "$TARGET_DIR/"
cp "$SOURCE_DIR/settings.gradle.kts" "$TARGET_DIR/"

# 复制gradle目录
cp -r "$SOURCE_DIR/gradle" "$TARGET_DIR/"

echo "文件复制完成"

# 5. 压缩为zip文件
echo "压缩文件夹为zip..."
cd "$BACKUP_DIR"
zip -r "${FOLDER_NAME}.zip" "$FOLDER_NAME"

# 6. 删除原始复制的文件夹
echo "删除临时文件夹: $TARGET_DIR"
rm -rf "$TARGET_DIR"

echo "完成! zip文件位置: $BACKUP_DIR/${FOLDER_NAME}.zip"
