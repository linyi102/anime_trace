abstract interface class IFeatureFlag {
  /// 修复封面
  bool get enableFixCover;

  /// 检测更新
  bool get enableCheckUpgrade;

  /// 选择本地图片
  bool get enablePickLocalImage;

  /// 选择文件
  ///
  /// 鸿蒙file_picker包选择文件未进行适配，暂时隐藏
  /// UnimplementedError: The current platform "ohos" is not supported by this plugin.
  bool get enablePickFile;

  /// 保存文件
  bool get enableSaveFile;

  /// 路由动画
  ///
  /// PageTransitionsTheme 需要手动传入 TargetPlatform，为保证代码统一鸿蒙平台暂时禁用
  bool get enableCustomPageTransition;

  /// 从剪切板粘贴
  ///
  /// 鸿蒙平台需要权限，暂时禁用
  bool get enablePaste;

  /// 复制到剪切板
  ///
  /// 鸿蒙平台需要权限，暂时禁用
  bool get enableCopy;
}

abstract interface class IManjiPlatform {
  IFeatureFlag get featureFlag;
}

class ManjiPlatform {
  ManjiPlatform._();

  static late IManjiPlatform _instance;

  static IManjiPlatform get instance => _instance;

  static void configure(IManjiPlatform platform) {
    _instance = platform;
  }
}
