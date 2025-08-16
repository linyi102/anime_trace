import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/percent_bar.dart';
import 'package:animetrace/models/app_release.dart';
import 'package:animetrace/modules/load_status/status.dart';
import 'package:animetrace/utils/dio_util.dart';
import 'package:animetrace/utils/file_util.dart';
import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as d;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:version/version.dart';

class AppUpgradeController extends GetxController {
  static AppUpgradeController get to => Get.find();

  AppRelease? latestRelease;
  LoadStatus status = LoadStatus.none;

  late PackageInfo packageInfo;

  bool downloading = false;
  int count = 0;
  int total = 0;
  double get downloadPercent => total == 0 ? 0 : count / total;
  String get downloadPercnetStr => "${(downloadPercent * 100).toInt()}%";
  CancelToken? releaseCancelToken;

  String get curVersion => packageInfo.version;
  String get latestVersion {
    String tagName = latestRelease?.tagName ?? '';
    if (tagName.startsWith('v')) {
      tagName = tagName.substring(1);
    }
    return tagName;
  }

  String get ignoreVersionKey => "ignore$latestVersion";

  void Function()? closeProgressDialog;

  @override
  void onInit() async {
    if (Platform.isWindows) {
      Log.info("Windows exe path: ${Platform.resolvedExecutable}");
    }
    packageInfo = await PackageInfo.fromPlatform();
    if (!Platform.isOhos) getLatestVersion(autoCheck: true);
    super.onInit();
  }

  getLatestVersion({bool showToast = false, bool autoCheck = false}) async {
    if (downloading) {
      _showDownloadDialog();
      return;
    }

    if (status == LoadStatus.loading) return;
    status = LoadStatus.loading;
    update();

    if (showToast) ToastUtil.showText('正在检查···');
    var result = await DioUtil.get(
        'https://api.github.com/repos/linyi102/anime_trace/releases/latest');
    if (result.isSuccess) {
      d.Response response = result.data;
      latestRelease = AppRelease.fromJson(response.data);
      if (latestRelease == null) {
        status = LoadStatus.fail;
        Log.info('解析最新版本失败');
        return;
      }
      status = LoadStatus.success;
      Log.info('最新版本：${latestRelease?.tagName}');
      // if (!Global.isRelease) latestRelease?.tagName = "1.10.1-beta";

      if (Version.parse(latestVersion) > Version.parse(curVersion)) {
        // 检测到新版本
        if (autoCheck && SPUtil.getBool(ignoreVersionKey)) {
          // 自动检查时若忽略了该新版本，则不提示
          Log.info('忽略了新版本：$latestVersion');
        } else {
          _showDialogUpgrade(autoCheck);
        }
      } else {
        if (showToast) ToastUtil.showText('已是最新版本');
        // 如果是Android，若是最新版本，则删除上次下载的apk
        // Windows则不要删，因为是用户手动选择的目录
        if (autoCheck && Platform.isAndroid) {
          String? dir = await _getAndroidDownloadDir();
          Asset? asset = _getAndroidAsset(latestRelease?.assets ?? []);
          if (dir != null && asset != null) {
            String path = _getDownloadPath(dir, asset.name);
            var file = File(path);
            if (file.existsSync()) file.delete();
          }
        }
      }
    } else {
      status = LoadStatus.fail;
      Log.info('获取最新版本失败');
    }

    if (status == LoadStatus.fail && showToast) {
      ToastUtil.showText('检查更新失败！');
    }
    update();
  }

  _showDialogUpgrade(bool autoCheck) {
    if (latestRelease == null && Get.context == null) return;

    String content = latestRelease!.body;

    ToastUtil.showDialog(
      clickClose: false,
      builder: (close) {
        var scrollController = ScrollController();

        return AlertDialog(
          title: Text('发现新版本 ${latestRelease!.tagName}'),
          content: Scrollbar(
              controller: scrollController,
              child: SingleChildScrollView(
                  controller: scrollController, child: Text(content))),
          actions: [
            // 自动检查时，提供忽略操作
            if (autoCheck)
              TextButton(
                onPressed: () {
                  SPUtil.setBool(ignoreVersionKey, true);
                  close();
                },
                child: const Text("忽略"),
              ),
            TextButton(onPressed: () => close(), child: const Text('取消')),
            TextButton(
                onPressed: () {
                  close();
                  _onSelectDownloadWay();
                },
                child: const Text('下载')),
          ],
        );
      },
    );
  }

  Future<String?> _getAndroidDownloadDir() async {
    return (await getExternalCacheDirectories())?.first.path;
  }

  _onSelectDownloadWay() async {
    if (PlatformUtil.isDesktop || Platform.isIOS) {
      LaunchUrlUtil.launch(
          context: Get.context!, uriStr: latestRelease!.htmlUrl);
      return;
    }
  }

  String _getDownloadPath(String dir, String name) {
    // 路径：/storage/emulated/0/Android/data/com.example.flutter_test_future/cache/manji-v1.8.1-android.apk
    return p.join(dir, name);
  }

  Asset? _getAndroidAsset(List<Asset> assets) {
    for (var asset in latestRelease!.assets) {
      if (Platform.isAndroid && asset.name.endsWith("-arm64-v8a.apk")) {
        return asset;
      }
    }
    return null;
  }

  _showDownloadDialog() {
    ToastUtil.showDialog(
        clickClose: false,
        builder: (close) {
          closeProgressDialog = close;
          return AlertDialog(
            title: const Text('下载进度'),
            content: const AppDownloadProgressBar(),
            actions: [
              TextButton(
                  onPressed: () {
                    close();
                    releaseCancelToken?.cancel();
                    releaseCancelToken = null;
                    downloading = false;
                    _onSelectDownloadWay();
                  },
                  child: const Text('重新选择')),
              TextButton(
                  onPressed: () {
                    close();
                    releaseCancelToken?.cancel();
                    releaseCancelToken = null;
                    downloading = false;
                  },
                  child: const Text('取消下载')),
              TextButton(onPressed: () => close(), child: const Text('后台下载')),
            ],
          );
        });
  }

  void _download({
    required String urlPath,
    required String savePath,
    void Function()? onComplete,
    void Function(String msg)? onFail,
  }) async {
    count = 0;
    downloading = true;

    var cancelToken = CancelToken();
    releaseCancelToken = cancelToken;
    var result = await DioUtil.download(
      urlPath: urlPath,
      savePath: savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (count, total) {
        this.count = count;
        this.total = total;
        // Log.info('下载进度：$count/$total');
        update();
        if (count == total) {
          downloading = false;
          onComplete?.call();
        }
      },
    );
    downloading = false;

    if (!result.isSuccess) {
      // 如果是用户取消的下载，那么就不进行重试，也不提示下载失败
      // releaseCancelToken会在下载前赋值为CancelToken()，在用户取消下载后赋值为null，因此可以通过releaseCancelToken是否为null来判断用户是否取消了下载
      // 更推荐的方式是根据DioError类型为cancel来判断，但是这里不好做
      if (releaseCancelToken == null) {
        return;
      }

      // 超时dio会提示：DioError [DioErrorType.other]: HttpException: 信号灯超时时间已到
      onFail?.call(result.msg);
    }
  }
}

class AppDownloadProgressBar extends StatelessWidget {
  const AppDownloadProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppUpgradeController>(
      init: AppUpgradeController.to,
      initState: (_) {},
      builder: (controller) {
        const textStyle = TextStyle(fontSize: 14);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: PercentBar(percent: controller.downloadPercent),
            ),
            Text(
              "${FileUtil.getReadableFileSize(controller.count)}/${FileUtil.getReadableFileSize(controller.total)}",
              style: textStyle,
            ),
          ],
        );
      },
    );
  }
}
