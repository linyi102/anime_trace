import 'package:animetrace/animetrace.dart';
import 'package:animetrace_harmony/feature_flag.dart';

void main() {
  runManjiApp(platform: const _HarmonyManjiPlatform());
}

class _HarmonyManjiPlatform implements IManjiPlatform {
  const _HarmonyManjiPlatform();

  @override
  IFeatureFlag get featureFlag => const HarmonyFeatureFlag();
}
