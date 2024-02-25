import 'dart:io';

import 'package:app_installer/app_installer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/percent_bar.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/models/app_release.dart';
import 'package:flutter_test_future/models/enum/load_status.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/file_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
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
    getLatestVersion(autoCheck: true);
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
    if (PlatformUtil.isDesktop) {
      LaunchUrlUtil.launch(
          context: Get.context!, uriStr: latestRelease!.htmlUrl);
      return;
    }

    // 选择下载方式
    ToastUtil.showDialog(
      builder: (close) => SimpleDialog(
        title: const Text('下载方式'),
        children: [
          ListTile(
            title: const Text('线路1：github'),
            onTap: () {
              close();
              _prepareDownload();
            },
          ),
          ListTile(
            title: const Text('线路2：kgithub'),
            onTap: () {
              close();
              _prepareDownload(
                speedUrl: (url) =>
                    url.replaceFirst('github.com', 'kgithub.com'),
              );
            },
          ),
          ListTile(
            title: const Text('线路3：download.nuaa.cf'),
            onTap: () {
              close();
              _prepareDownload(
                speedUrl: (url) =>
                    url.replaceFirst('github.com', 'download.nuaa.cf'),
              );
            },
          ),
          ListTile(
            title: const Text('线路4：git.xfj0.cn'),
            onTap: () {
              close();
              _prepareDownload(
                speedUrl: (url) => "https://git.xfj0.cn/$url",
              );
            },
          ),
          ListTile(
            title: const Text('前往 GitHub 手动下载'),
            onTap: () {
              close();
              LaunchUrlUtil.launch(
                  context: Get.context!,
                  uriStr: latestRelease!.htmlUrl,
                  inApp: false);
            },
          ),
          ListTile(
            title: const Text('前往 Gitee 手动下载'),
            onTap: () {
              close();
              LaunchUrlUtil.launch(
                  context: Get.context!,
                  uriStr: "https://gitee.com/linyi517/anime_trace",
                  inApp: false);
            },
          ),
        ],
      ),
    );
  }

  _prepareDownload({String Function(String url)? speedUrl}) async {
    String? downloadDir;
    if (Platform.isWindows) {
      // Windows指定下载目录
      downloadDir = await selectDirectory();
    } else {
      // Android默认下载到缓存目录
      // 注：下载到getTemporaryDirectory对应的路径时，无法安装
      downloadDir = await _getAndroidDownloadDir();
    }

    if (downloadDir == null) {
      ToastUtil.showText('获取下载位置失败，请重试或手动下载');
      return;
    }

    Asset? destAsset;
    if (Platform.isAndroid) {
      destAsset = _getAndroidAsset(latestRelease!.assets);
    } else if (Platform.isWindows) {
      destAsset = _getWindowsAsset(latestRelease!.assets);
    }

    if (destAsset == null) {
      _showDialogWhenDownloadFail('没有找到下载链接');
      return;
    }

    total = destAsset.size;
    String savePath = _getDownloadPath(downloadDir, destAsset.name);
    String url = destAsset.browserDownloadUrl;
    if (speedUrl != null) {
      url = speedUrl(url);
    }

    // 若之前下载过，且大小一致
    //  - 对于Andorid，提示直接安装，还是重新下载
    //  - 对于Windows，提示退出进行手动安装
    // 否则直接下载
    var file = File(savePath);
    if (file.existsSync() && file.statSync().size == total) {
      ToastUtil.showDialog(
        clickClose: false,
        builder: (close) => AlertDialog(
          title: const Text('提示'),
          content: Text(
              '检测到已下载最新版本，${Platform.isAndroid ? "是否立即安装？" : "是否退出应用，然后手动安装？"} '),
          actions: [
            TextButton(
                onPressed: () {
                  close();
                  _onDownload(url, savePath);
                },
                child: const Text('重新下载')),
            TextButton(
                onPressed: () {
                  close();
                  if (Platform.isAndroid) {
                    AppInstaller.installApk(savePath);
                  } else {
                    Global.exitApp();
                  }
                },
                child: Text(Platform.isAndroid ? '安装' : '退出'))
          ],
        ),
      );
    } else {
      _onDownload(url, savePath);
    }
  }

  _onDownload(String url, String savePath) {
    // 显示进度下载框
    _showDownloadDialog();

    Log.info('下载链接：$url');
    // 开始下载
    _download(
      urlPath: url,
      savePath: savePath,
      onComplete: () async {
        if (Platform.isAndroid) {
          // 关闭下载进度框
          closeProgressDialog?.call();

          // Android自动安装
          AppInstaller.installApk(savePath);

          // 提示下载完毕
          ToastUtil.showDialog(
            clickClose: false,
            builder: (close) => AlertDialog(
              title: const Text('下载成功'),
              content: const Text('下载成功后会自动安装，如果没有反应，请点击安装按钮'),
              actions: [
                TextButton(onPressed: () => close(), child: const Text('稍后')),
                TextButton(
                    onPressed: () {
                      close();
                      AppInstaller.installApk(savePath);
                    },
                    child: const Text('安装')),
              ],
            ),
          );
        } else {
          // 关闭下载进度框
          closeProgressDialog?.call();
          // 其他平台提示退出应用，进行手动安装
          ToastUtil.showDialog(
            clickClose: false,
            builder: (close) => AlertDialog(
              title: const Text('下载完毕'),
              content: const Text('是否退出应用，进行手动安装？'),
              actions: [
                TextButton(onPressed: () => close(), child: const Text('稍后')),
                TextButton(
                    onPressed: () {
                      close();
                      Global.exitApp();
                    },
                    child: const Text('退出')),
              ],
            ),
          );
        }
      },
      onFail: (failMsg) {
        closeProgressDialog?.call();

        _showDialogWhenDownloadFail(failMsg);
      },
    );
  }

  String _getDownloadPath(String dir, String name) {
    // 路径：/storage/emulated/0/Android/data/com.example.flutter_test_future/cache/manji-v1.8.1-android.apk
    return p.join(dir, name);
  }

  Asset? _getAndroidAsset(List<Asset> assets) {
    for (var asset in latestRelease!.assets) {
      if (Platform.isAndroid && asset.name.endsWith("-android.apk")) {
        return asset;
      }
    }
    return null;
  }

  Asset? _getWindowsAsset(List<Asset> assets) {
    for (var asset in latestRelease!.assets) {
      if (Platform.isWindows && asset.name.endsWith("-windows.zip")) {
        return asset;
      }
    }
    return null;
  }

  _showDialogWhenDownloadFail(String failMsg) {
    ToastUtil.showDialog(
      clickClose: false,
      builder: (close) => AlertDialog(
        title: const Text('下载失败'),
        content: Text('原因：$failMsg'),
        actions: [
          TextButton(
            onPressed: () => close(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              close();
              _onSelectDownloadWay();
            },
            child: const Text('重新选择'),
          )
        ],
      ),
    );
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
