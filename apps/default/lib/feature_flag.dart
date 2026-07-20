import 'dart:io';

import 'package:animetrace/feature_flags.dart';

class DefaultFeatureFlag implements IFeatureFlag {
  const DefaultFeatureFlag();

  @override
  bool get enableFixCover => false;

  @override
  bool get enableCheckUpgrade => true;

  @override
  bool get enablePickFile => true;

  @override
  bool get enableSaveFile => true;

  @override
  bool get enablePickLocalImage => Platform.isWindows || Platform.isAndroid;

  @override
  bool get enableCustomPageTransition => Platform.isAndroid || Platform.isIOS;

  @override
  bool get enableCopy => true;

  @override
  bool get enablePaste => true;
}
