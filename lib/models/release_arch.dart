import 'package:flutter_test_future/utils/installer.dart';

typedef InstallFunction = Future<bool> Function(String path);

class ReleaseArch {
  final String label;
  final bool Function(String url) match;
  final InstallFunction install;
  const ReleaseArch(this.label, {required this.match, required this.install});
}

class AndroidReleaseArch extends ReleaseArch {
  AndroidReleaseArch(
    super.label, {
    required super.match,
    super.install = installAndroidApk,
  });
}
