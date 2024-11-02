import 'package:flutter/material.dart';

Future<bool> unimplementedInstall(String path) async {
  throw Exception('unimplemented install');
}

Future<bool> installAndroidApk(String path) async {
  debugPrint('install android apk: $path');
  return true;
}

Future<bool> installWindowsExe(String path) async {
  debugPrint('install windows exe: $path');
  return true;
}

Future<bool> installWindowsZip(String path) async {
  debugPrint('install windows zip: $path');
  return true;
}
