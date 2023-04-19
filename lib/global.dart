import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/controllers/anime_display_controller.dart';
import 'package:flutter_test_future/controllers/backup_service.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

class Global {
  // 私有构造器，避免外部错误使用(也就是创建Global对象)
  Global._();

  /// 是否 release
  static bool get isRelease => const bool.fromEnvironment("dart.vm.product");

  /// 修改了笔记图片根路径
  static bool modifiedImgRootPath = false;

  /// 展开/收缩目录过滤器
  static bool expandDirectoryFilter = true;

  static Future<void> init() async {
    // 透明状态栏
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    }
    // 确保初始化，否则会提示Unhandled Exception: Null check operator used on a null value
    WidgetsFlutterBinding.ensureInitialized();
    // 获取SharedPreferences
    await SPUtil.getInstance();
    // 桌面应用的sqflite初始化
    sqfliteFfiInit();
    // 确保数据库表最新结构
    await SqliteUtil.ensureDBTable();
    // put常用的getController
    await _putGetController();
    // 设置Windows窗口
    _handleWindowsManager();
    // 解决访问部分网络图片时报错CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate
    HttpOverrides.global = MyHttpOverrides();
  }

  static _putGetController() async {
    Get.lazyPut(
        () => UpdateRecordController()); // 放在ensureDBTable后，因为init中访问到了表
    Get.lazyPut(() => AnimeDisplayController());
    Get.lazyPut(() => LabelsController());
    Get.lazyPut(() => BackupService());

    final checklistController = ChecklistController();
    Get.put(checklistController);
    await checklistController.init();
  }

  static void _handleWindowsManager() async {
    // 只在Windows系统下开启窗口设置，否则Android端会白屏
    if (Platform.isWindows) {
      // Windows端窗口设置
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = WindowOptions(
        title: "漫迹",
        size: Size(SpProfile.getWindowWidth(), SpProfile.getWindowHeight()),
        // 最小尺寸
        // minimumSize: const Size(900, 600),
        minimumSize: const Size(400, 400),
        fullScreen: false,
        // 需要居中，否则会偏右
        center: true,
        // 透明会导致新版Win11的标题栏看不到最小化、最大化和关闭按钮
        // backgroundColor: Colors.transparent,
        skipTaskbar: false,
        // 隐藏标题栏
        // titleBarStyle: TitleBarStyle.hidden,
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
