import 'package:animetrace/animetrace.dart';

void main() {
  runManjiApp(platform: const _HarmonyManjiPlatform());
}

/// Host adaptation for HarmonyOS.
class _HarmonyManjiPlatform implements IManjiPlatform {
  const _HarmonyManjiPlatform();

  @override
  IFeatureFlag get featureFlag => const _HarmonyFeatureFlag();
}

/// HarmonyOS capabilities.
///
/// The current HarmonyOS host disables optional capabilities until their
/// corresponding platform integrations are available and verified.
class _HarmonyFeatureFlag implements IFeatureFlag {
  const _HarmonyFeatureFlag();

  @override
  bool get enableCheckUpgrade => false;

  @override
  bool get enableCopy => false;

  @override
  bool get enableCustomPageTransition => false;

  @override
  bool get enableFixCover => false;

  @override
  bool get enablePaste => false;

  @override
  bool get enablePickFile => false;

  @override
  bool get enablePickLocalImage => false;

  @override
  bool get enableSaveFile => false;
}
