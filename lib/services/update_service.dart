import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/enum/github_mirror.dart';
import 'package:flutter_test_future/models/enum/load_status.dart';
import 'package:flutter_test_future/models/release_arch.dart';
import 'package:flutter_test_future/models/release_asset.dart';
import 'package:flutter_test_future/models/release_info.dart';
import 'package:flutter_test_future/pages/app_update/update_page.dart';
import 'package:flutter_test_future/pages/changelog/view.dart';
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/release_checker/release_checker.dart';
import 'package:flutter_test_future/utils/version.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:version/version.dart';
import 'package:path/path.dart' as p;

class AppUpdateService extends GetxService {
  static AppUpdateService get to => Get.find();

  ReleaseInfo? releaseInfo;
  ReleaseChecker checker;
  String curVersion = '0.0.0';
  final checkStatus = ValueNotifier(LoadStatus.none);
  final downloadStatus = ValueNotifier(DownloadStatus.initial);
  final downloadPercent = ValueNotifier(0.0);
  String downloadFilePath = '';

  AppUpdateService({required this.checker});

  Future<ReleaseInfo?> _getLatestRelease(ReleaseChecker checker) async {
    curVersion = (await PackageInfo.fromPlatform()).version;
    final release = await checker.fetchLatestRelease();
    if (release == null) return null;

    bool hasNew = false;
    try {
      hasNew = Version.parse(formatVersion(release.version)) >
          Version.parse(formatVersion(curVersion));
    } catch (err, stack) {
      logger.error('版本比较错误：$err', stackTrace: stack);
      return null;
    }
    if (hasNew) {
      logger.info('发现新版本：${release.version}');
      return release;
    }
    return null;
  }

  Future<void> checkLatestRelease({
    required BuildContext context,
  }) async {
    logger.info('检查最新版本');
    checkStatus.value = LoadStatus.loading;
    releaseInfo = await _getLatestRelease(checker);
    checkStatus.value = LoadStatus.success;

    if (context.mounted && releaseInfo != null) {
      RouteUtil.materialTo(context, AppUpdateView(service: this));
    }
  }

  Future<void> download({
    required ReleaseArch arch,
    required GithubMirror mirror,
  }) async {
    ReleaseAsset? asset =
        releaseInfo?.assets.where((asset) => arch.match(asset.url)).firstOrNull;
    if (asset == null) {
      logger.error('没有找到 ${arch.label} 相关的 asset');
      return;
    }
    logger.info('下载链接：${asset.url}');
    final url = mirror.speedUrl(asset.url);
    logger.info('加速链接：$url');
    final fileName = url.split('/').lastOrNull ?? '';
    if (fileName.isEmpty) {
      logger.error('从链接提取文件名失败: $url');
      return;
    }

    final downloadDir = Directory(p.join(
      (await getApplicationSupportDirectory()).path,
      'temp_download',
    ));
    if (await downloadDir.exists()) {
      await downloadDir.delete(recursive: true);
    }
    await downloadDir.create(recursive: true);
    final filePath = p.join(downloadDir.path, fileName);
    logger.info('最新版本下载到本地路径: $filePath');
    downloadPercent.value = 0;
    downloadStatus.value = DownloadStatus.downloading;
    await _mockDownload(
      url,
      filePath,
      onProgress: (count, total) {
        downloadPercent.value = total == 0 ? 0 : (count / total).clamp(0, 1);
        if (count == total && count > 0) {
          downloadStatus.value = DownloadStatus.success;
        }
      },
    );
    downloadFilePath = filePath;
  }

  Future<bool> _mockDownload(
    String url,
    String savePath, {
    void Function(int count, int total)? onProgress,
  }) async {
    int speed = 13, count = 0, total = 100;
    while (count < total) {
      count = (count + speed).clamp(0, total);
      onProgress?.call(count, total);
      await Future.delayed(const Duration(milliseconds: 600));
    }
    return true;
  }

  void stopDownload() {
    downloadStatus.value = DownloadStatus.initial;
  }

  Future<void> install(ReleaseArch arch) async {
    if (!await File(downloadFilePath).exists()) {
      logger.error('下载文件不存在：$downloadFilePath');
      return;
    }
    logger.info('安装下载文件：$downloadFilePath');
    arch.install(downloadFilePath);
  }

  void ignore(BuildContext context) {
    Navigator.of(context).pop();
  }

  void reSelect() {
    downloadStatus.value = DownloadStatus.initial;
  }

  void toChanglog(BuildContext context) {
    RouteUtil.materialTo(context, const ChangelogPage());
  }
}

enum DownloadStatus {
  initial,
  downloading,
  success,
  error,
  ;
}
