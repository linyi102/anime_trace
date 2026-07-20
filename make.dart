import 'dart:io';

const _defaultAppDir = 'apps/default';
const _harmonyAppDir = 'apps/harmony';
const _defaultFlutterVersion = '3.35.7';
const _harmonyFlutterVersion = 'custom_3.35.8';

bool _verbose = false;

/// 打包脚本
/// 环境变量：fvm, 7z, iscc
///
/// 每个构建通过 `fvm spawn <Flutter版本>` 执行：
/// 默认版为 3.35.7，鸿蒙版为 custom_3.35.8。
void main(List<String> arguments) async {
  _verbose = arguments.contains('-v') || arguments.contains('--verbose');

  stdout.writeln('Select the platform to build:');
  stdout.writeln('[1]: Android');
  stdout.writeln('[2]: Windows');
  stdout.writeln('[3]: Harmony');
  stdout.writeln('[4]: All');
  stdout.write('Please choose (for example "12", or "q" to quit): ');

  final choice = stdin.readLineSync()?.trim();
  if (choice == 'q') return;
  final targets = _parseTargets(choice ?? '');
  if (targets == null) {
    stderr.writeln('Invalid choice');
    exitCode = 64;
    return;
  }

  final buildDir = 'dist/manji_${_timestamp()}';
  await _prepareBuildDir(buildDir);
  for (final target in targets) {
    switch (target) {
      case _BuildTarget.android:
        await _buildAndroid(buildDir);
      case _BuildTarget.windows:
        await _buildWindows(buildDir);
      case _BuildTarget.harmony:
        await _buildHarmony(buildDir);
    }
  }
  stdout.writeln('\nBuild success: $buildDir');
}

enum _BuildTarget { android, windows, harmony }

List<_BuildTarget>? _parseTargets(String choice) {
  if (choice == '4') return _BuildTarget.values;
  if (choice.isEmpty || choice.contains('4')) return null;

  final targets = <_BuildTarget>[];
  for (final character in choice.split('')) {
    final target = switch (character) {
      '1' => _BuildTarget.android,
      '2' => _BuildTarget.windows,
      '3' => _BuildTarget.harmony,
      _ => null,
    };
    if (target == null) return null;
    if (!targets.contains(target)) targets.add(target);
  }
  return targets;
}

Future<void> _buildAndroid(String buildDir) async {
  stdout.writeln('Building Android...');
  await _runFlutter(
    _defaultAppDir,
    _defaultFlutterVersion,
    ['pub', 'get'],
  );
  await _runFlutter(
    _defaultAppDir,
    _defaultFlutterVersion,
    ['build', 'apk', '--split-per-abi'],
  );

  final version = _versionFor(_defaultAppDir);
  final qqDir = Directory('$buildDir/qq')..createSync(recursive: true);
  final sourceDir = Directory('$_defaultAppDir/build/app/outputs/flutter-apk');
  final apkNames = {
    'app-armeabi-v7a-release.apk': 'manji-$version-android.apk',
    'app-arm64-v8a-release.apk': 'manji-$version-arm64-v8a.apk',
    'app-x86_64-release.apk': 'manji-$version-x86_64.apk',
  };
  for (final entry in apkNames.entries) {
    final source = File('${sourceDir.path}/${entry.key}');
    await source.copy('$buildDir/${entry.value}');
    await source
        .copy('${qqDir.path}/${entry.value.replaceFirst('.apk', '.APK')}');
  }
}

Future<void> _buildWindows(String buildDir) async {
  stdout.writeln('Building Windows...');
  await _runFlutter(
    _defaultAppDir,
    _defaultFlutterVersion,
    ['pub', 'get'],
  );
  await _runFlutter(
    _defaultAppDir,
    _defaultFlutterVersion,
    ['build', 'windows'],
  );

  final version = _windowsVersion();
  final outputName = '漫迹 $version for Windows';
  final outputDir = Directory('$buildDir/$outputName')
    ..createSync(recursive: true);
  await _copyDirectory(
    Directory('$_defaultAppDir/build/windows/x64/runner/Release'),
    outputDir,
  );
  await _runCommand(
      '7z', ['a', '-tzip', 'manji-$version-windows.zip', outputName],
      workingDirectory: buildDir);
  await _runCommand(
    'iscc',
    [
      'setup.iss',
      '/Qp',
      '/DMyAppVersion=$version',
      '/DOutputDir=${Directory(buildDir).absolute.path}',
    ],
    workingDirectory: _defaultAppDir,
  );
}

Future<void> _buildHarmony(String buildDir) async {
  stdout.writeln('Building Harmony...');
  await _runFlutter(
    _harmonyAppDir,
    _harmonyFlutterVersion,
    ['pub', 'get'],
  );
  await _runFlutter(
    _harmonyAppDir,
    _harmonyFlutterVersion,
    ['build', 'hap'],
  );

  final hapFile =
      File('$_harmonyAppDir/build/ohos/hap/entry-default-signed.hap');
  if (!await hapFile.exists()) {
    throw StateError('Harmony build completed but no .hap artifact was found.');
  }
  final version = _versionFor(_harmonyAppDir);
  await hapFile.copy('$buildDir/manji-$version-harmony.hap');
}

Future<void> _runFlutter(
  String appDir,
  String flutterVersion,
  List<String> arguments,
) {
  return _runCommand(
      'fvm', ['spawn', flutterVersion, ...arguments, if (_verbose) '--verbose'],
      workingDirectory: appDir);
}

Future<void> _runCommand(
  String command,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  stdout.writeln(workingDirectory ?? Directory.current.path);
  stdout.writeln('> $command ${arguments.join(' ')}');
  final process = await Process.start(
    command,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  final code = await process.exitCode;
  if (code != 0) {
    throw ProcessException(command, arguments, 'Exit code $code', code);
  }
}

Future<void> _prepareBuildDir(String path) async {
  final dir = Directory(path)..createSync(recursive: true);
  final result =
      await Process.run('git', ['log', '-3', '--pretty=format:%h %s']);
  await File('${dir.path}/commit.txt').writeAsString(result.stdout as String);
}

String _versionFor(String appDir) {
  final content = File('$appDir/pubspec.yaml').readAsStringSync();
  return 'v${RegExp(r'version: ([0-9]+(?:\.[0-9]+)*)').firstMatch(content)?.group(1) ?? 'unknown'}';
}

String _windowsVersion() {
  final content =
      File('$_defaultAppDir/windows/runner/Runner.rc').readAsStringSync();
  return 'v${RegExp(r'#define VERSION_AS_STRING "([^"]+)"').firstMatch(content)?.group(1) ?? 'unknown'}';
}

String _timestamp() {
  final now = DateTime.now();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}_${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}';
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  for (final entity in source.listSync(recursive: true)) {
    final relativePath = entity.path.substring(source.path.length + 1);
    final targetPath = '${destination.path}/$relativePath';
    if (entity is Directory) {
      Directory(targetPath).createSync(recursive: true);
    } else if (entity is File) {
      await entity.copy(targetPath);
    }
  }
}
