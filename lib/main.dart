import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'controllers/anime_display_controller.dart';
import 'controllers/update_record_controller.dart';
import 'my_app.dart';

void main() {
  beforeRunApp().then((value) => runApp(const GetMaterialApp(home: MyApp())));
}

Future<void> beforeRunApp() async {
  // 透明状态栏
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  // 确保初始化，否则Unhandled Exception: Null check operator used on a null value
  WidgetsFlutterBinding.ensureInitialized();
  // 获取SharedPreferences
  await SPUtil.getInstance();
  // 桌面应用的sqflite初始化
  sqfliteFfiInit();
  // 确保数据库表最新结构
  await SqliteUtil.ensureDBTable();
  // put常用的getController
  putGetController();
  // 设置Windows窗口
  handleWindowsManager();
  // 解决访问部分网络图片时报错CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate
  HttpOverrides.global = MyHttpOverrides();
}

void putGetController() {
  Get.put(UpdateRecordController()); // 放在ensureDBTable后，因为init中访问到了表
  Get.put(AnimeDisplayController());
}

void handleWindowsManager() async {
  // 只在Windows系统下开启窗口设置，否则Android端会白屏
  if (Platform.isWindows) {
    // Windows端窗口设置
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      title: "漫迹",
      size: Size(SpProfile.getWindowWidth(), SpProfile.getWindowHeight()),
      // 最小尺寸
      // minimumSize: const Size(900, 600),
      minimumSize: const Size(300, 300),
      fullScreen: false,
      // 需要居中，否则会偏右
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      // titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
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
