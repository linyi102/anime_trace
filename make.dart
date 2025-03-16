// ignore_for_file: avoid_print

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shell_executor/shell_executor.dart';

bool flutterBuildVerbose = false;
const flutterVersion = '3.27.0';

/// 打包脚本
/// 环境变量：fvm, 7z, iscc
void main(List<String> arguments) async {
  parseArguments(arguments);

  print('Select the platform to build:');
  print('[1]: Android');
  print('[2]: Windows');
  print('[3]: All');
  stdout.write('Please choose one (or "q" to quit): ');

  String choice = stdin.readLineSync()!.trim();
  String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  String buildDir = 'dist/manji_$timestamp';

  switch (choice) {
    case '1':
      print('Building Android...');
      await prepareBuildDir(buildDir);
      await buildAndroid(buildDir);
      break;
    case '2':
      print('Building Windows...');
      await prepareBuildDir(buildDir);
      await buildWindows(buildDir);
      break;
    case '3':
      print('Building All...');
      await prepareBuildDir(buildDir);
      await buildAll(buildDir);
      break;
    case 'q':
      exit(0);
    default:
      print('Invalid choice');
      exit(-1);
  }
  print('\nBuild success: $buildDir');
}

void parseArguments(List<String> arguments) {
  if (arguments.contains('-v') || arguments.contains('--verbose')) {
    flutterBuildVerbose = true;
  }
}

Future<void> buildAndroid(String buildDir) async {
  await runFlutter([
    'build',
    'apk',
    '--split-per-abi',
    if (flutterBuildVerbose) '--verbose',
  ]);

  String androidVersion = getVersionFromPubspec();
  Directory('$buildDir/qq').createSync(recursive: true);

  void copyApk(String fileName, String destFileName) {
    File('build/app/outputs/flutter-apk/$fileName.apk')
      ..copySync('$buildDir/$destFileName.apk')
      ..copySync('$buildDir/qq/$destFileName.APK');
  }

  copyApk('app-armeabi-v7a-release', 'manji-$androidVersion-android');
  copyApk('app-arm64-v8a-release', 'manji-$androidVersion-arm64-v8a');
  copyApk('app-x86_64-release', 'manji-$androidVersion-x86_64');
}

Future<void> buildWindows(String buildDir) async {
  await runFlutter([
    'build',
    'windows',
    if (flutterBuildVerbose) '--verbose',
  ]);

  String windowsVersion = getVersionFromRunner();
  String windowsOutputDirName = '漫迹 $windowsVersion for Windows';
  String windowsOutputDirPath = '$buildDir/$windowsOutputDirName';
  Directory(windowsOutputDirPath).createSync(recursive: true);
  copyDirectory(Directory('build/windows/x64/runner/Release'),
      Directory(windowsOutputDirPath));
  await runCommand(
    '7z',
    [
      'a',
      '-tzip',
      'manji-$windowsVersion-windows.zip',
      windowsOutputDirName,
    ],
    workingDirectory: buildDir,
  );
  await runCommand('iscc', [
    'setup.iss',
    '/Qp',
    '/DMyAppVersion=$windowsVersion',
    '/DOutputDir=$buildDir'
  ]);
}

Future<void> buildAll(String buildDir) async {
  await buildAndroid(buildDir);
  await buildWindows(buildDir);
}

Future<void> runFlutter(List<String> arguments) {
  return runCommand('fvm', ['spawn', flutterVersion, ...arguments]);
}

Future<void> runCommand(
  String command,
  List<String> args, {
  String? workingDirectory,
}) async {
  await $(command, args, workingDirectory: workingDirectory);
}

String getVersionFromPubspec() {
  String content = File('pubspec.yaml').readAsStringSync();
  RegExp versionRegex = RegExp(r'version:\s*(\S+)');
  String version = versionRegex.firstMatch(content)?.group(1) ?? 'unknown';
  return 'v$version';
}

String getVersionFromRunner() {
  String content = File('windows/runner/Runner.rc').readAsStringSync();
  RegExp versionRegex = RegExp(r'#define VERSION_AS_STRING "([^"]+)"');
  String version = versionRegex.firstMatch(content)?.group(1) ?? 'unknown';
  return 'v$version';
}

void copyDirectory(Directory source, Directory destination) {
  for (var entity in source.listSync(recursive: true)) {
    if (entity is Directory) {
      Directory(
              '${destination.path}/${entity.path.substring(source.path.length)}')
          .createSync(recursive: true);
    } else if (entity is File) {
      entity.copySync(
          '${destination.path}/${entity.path.substring(source.path.length)}');
    }
  }
}

Future<void> prepareBuildDir(String dir) async {
  Directory(dir).createSync(recursive: true);
  await generateCommitLog(dir);
}

Future<void> generateCommitLog(String dir) async {
  ProcessResult result = await $('git', ['log', '-3', '--pretty=format:%h %s']);
  File('$dir/commit.txt').writeAsStringSync(result.stdout);
  print('');
}
