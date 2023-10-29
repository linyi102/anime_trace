import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/platform.dart';

class MultiPlatform extends StatelessWidget {
  const MultiPlatform({required this.mobile, required this.desktop, super.key});
  final Widget mobile;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isMobile) return mobile;
    return desktop;
  }
}
