import 'package:animetrace/animetrace.dart';
import 'package:animetrace_default/feature_flag.dart';

void main() {
  runManjiApp(platform: const _DefaultManjiPlatform());
}

class _DefaultManjiPlatform implements IManjiPlatform {
  const _DefaultManjiPlatform();

  @override
  IFeatureFlag get featureFlag => const DefaultFeatureFlag();
}
