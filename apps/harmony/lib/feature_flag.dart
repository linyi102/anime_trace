import 'package:animetrace/feature_flags.dart';

class HarmonyFeatureFlag implements IFeatureFlag {
  const HarmonyFeatureFlag();

  @override
  bool get enableFixCover => false;

  @override
  bool get enableCheckUpgrade => false;

  @override
  bool get enablePickLocalImage => false;

  /// 鸿蒙 file_picker 包选择文件未进行适配，暂时隐藏
  /// UnimplementedError: The current platform "ohos" is not supported by this plugin.
  @override
  bool get enablePickFile => false;

  @override
  bool get enableSaveFile => false;

  /// PageTransitionsTheme 需要手动传入 TargetPlatform，为保证代码统一鸿蒙平台暂时禁用
  @override
  bool get enableCustomPageTransition => false;

  /// 鸿蒙平台需要权限，暂时禁用
  @override
  bool get enableCopy => false;

  /// 鸿蒙平台需要权限，暂时禁用
  @override
  bool get enablePaste => false;
}
