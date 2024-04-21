export HOME=/c/Users/11580

# 获取版本
androidVersion=$(grep -m1 'version:' pubspec.yaml | awk '{print $2}')
androidVersion="v$androidVersion"
echo "Android版本：$androidVersion"
windowsVerison=$(grep -oP '#define VERSION_AS_STRING "\K[^"]+' windows/runner/Runner.rc)
windowsVerison="v$windowsVerison"
echo "Windows版本：$windowsVerison"

# 输出目录
packRootDir="$HOME/Desktop/漫迹发布 ${androidVersion}"
mkdir "$packRootDir"

# Android
apkOriPath="build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
apkOutputPath="$packRootDir/manji-$androidVersion-android.apk"

cp "$apkOriPath" "$apkOutputPath"

# Windows
windowsOriDir="build/windows/runner/Release"
windowsOutputDir="$packRootDir/漫迹 $windowsVerison for Windows"
windowsOutputZipPath="$packRootDir/manji-$windowsVerison-windows.zip"

cp -r "$windowsOriDir" "$packRootDir"
mv "$packRootDir/Release" "$windowsOutputDir"
7z a -tzip "$windowsOutputZipPath" "$windowsOutputDir"
