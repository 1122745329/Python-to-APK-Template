#!/usr/bin/env bash
# 一键打包 debug / release APK
# 用法: ./pack_apk.sh [debug|release]
set -e

TYPE="${1:-debug}"
echo ">>> 开始打包 $TYPE APK ..."

if [ "$TYPE" = "release" ]; then
  ./gradlew assembleRelease
  OUT="app/build/outputs/apk/release/app-release.apk"
else
  ./gradlew assembleDebug
  OUT="app/build/outputs/apk/debug/app-debug.apk"
fi

if [ -f "$OUT" ]; then
  cp "$OUT" "./TouchMapper-$TYPE.apk"
  echo ">>> 成功: ./TouchMapper-$TYPE.apk"
  ls -lh "./TouchMapper-$TYPE.apk"
else
  echo ">>> 未找到产物，请检查 gradle 输出"
  exit 1
fi
