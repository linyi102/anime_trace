import 'package:animetrace/global.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ManjiPlatform exposes the configured platform capabilities', () {
    ManjiPlatform.configure(const _TestManjiPlatform());

    final featureFlag = $featureFlag;
    expect(featureFlag.enableCheckUpgrade, isTrue);
    expect(featureFlag.enablePickLocalImage, isTrue);
    expect(featureFlag.enablePickFile, isTrue);
    expect(featureFlag.enableSaveFile, isTrue);
    expect(featureFlag.enableCustomPageTransition, isTrue);
    expect(featureFlag.enablePaste, isTrue);
    expect(featureFlag.enableCopy, isTrue);
  });
}

class _TestManjiPlatform implements IManjiPlatform {
  const _TestManjiPlatform();

  @override
  IFeatureFlag get featureFlag => const _TestFeatureFlag();
}

class _TestFeatureFlag implements IFeatureFlag {
  const _TestFeatureFlag();

  @override
  bool get enableCheckUpgrade => true;

  @override
  bool get enableCopy => true;

  @override
  bool get enableCustomPageTransition => true;

  @override
  bool get enableFixCover => false;

  @override
  bool get enablePaste => true;

  @override
  bool get enablePickFile => true;

  @override
  bool get enablePickLocalImage => true;

  @override
  bool get enableSaveFile => true;
}
