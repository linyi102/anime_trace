import 'dart:io';

import 'package:flutter/material.dart';

class MultiPlatform extends StatelessWidget {
  const MultiPlatform({required this.mobile, required this.desktop, super.key});
  final Widget mobile;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) return mobile;
    return desktop;
  }
}
