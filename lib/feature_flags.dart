abstract interface class IFeatureFlag {
  /// 修复封面
  bool get enableFixCover;

  /// 检测更新
  bool get enableCheckUpgrade;

  /// 选择本地图片
  bool get enablePickLocalImage;

  /// 选择文件
  bool get enablePickFile;

  /// 保存文件
  bool get enableSaveFile;

  /// 路由动画
  bool get enableCustomPageTransition;

  /// 从剪切板粘贴
  ///
  bool get enablePaste;

  /// 复制到剪切板
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
