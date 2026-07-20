import 'dart:io';

import 'package:animetrace/animetrace.dart';

void main() {
  runManjiApp(platform: const _DefaultManjiPlatform());
}

/// Host adaptation for Flutter's standard Android, iOS, desktop
/// platforms.
class _DefaultManjiPlatform implements IManjiPlatform {
  const _DefaultManjiPlatform();

  @override
  IFeatureFlag get featureFlag => const _DefaultFeatureFlag();
}

/// Capabilities provided by the standard Flutter host.
class _DefaultFeatureFlag implements IFeatureFlag {
  const _DefaultFeatureFlag();

  @override
  bool get enableCheckUpgrade => true;

  @override
  bool get enableCopy => true;

  @override
  bool get enableCustomPageTransition => Platform.isAndroid || Platform.isIOS;

  @override
  bool get enableFixCover => false;

  @override
  bool get enablePaste => true;

  @override
  bool get enablePickFile => true;

  @override
  bool get enablePickLocalImage => Platform.isWindows || Platform.isAndroid;

  @override
  bool get enableSaveFile => true;
}
