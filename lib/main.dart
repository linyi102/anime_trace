import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/components/update_hint.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/pages/tabs.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'controllers/update_record_controller.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  WidgetsFlutterBinding
      .ensureInitialized(); // 确保初始化，否则Unhandled Exception: Null check operator used on a null value
  await SPUtil.getInstance();
  sqfliteFfiInit(); // 桌面应用的sqflite初始化
  await SqliteUtil.ensureDBTable(); // 必须要用await
  // put放在了ensureDBTable执行，因为既要保证在ensureDBTable里获取到，又要保证controller里的init能在表创建后访问。但这又会导致恢复备份时再次put吧...
  Get.put(
      UpdateRecordController()); // 确保被find前put。放在ensureDBTable后，因为init中访问到了表

  if (Platform.isWindows) {
    // Windows端窗口设置
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      title: "漫迹",
      // size: Size(1280, 720),
      size: Size(SpProfile.getWindowWidth(), SpProfile.getWindowHeight()),
      // 最小尺寸
      minimumSize: const Size(900, 600),
      fullScreen: false,
      // 不居中则会偏右
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

  runApp(const GetMaterialApp(
    home: MyApp(),
  ));

  // Win端好像不能放大缩小了
  // doWhenWindowReady(() {
  //   const initialSize = Size(1200, 720);
  //   appWindow.minSize = initialSize;
  //   appWindow.size = initialSize;
  //   appWindow.alignment = Alignment.center;
  //   appWindow.title = "漫迹";
  //   appWindow.show();
  // });
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WindowListener {
  // StatefulWidget才有initState和dispose
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
    _autoBackup();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    // Add this line to override the default close handler
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  void onWindowResize() async {}

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      // 关闭窗口前等待记录窗口大小完毕
      await SpProfile.setWindowSize(await windowManager.getSize());
      // 退出
      Navigator.of(context).pop();
      await windowManager.destroy();
    }
  }

  @override
  void onWindowMaximize() async {
    debugPrint("全屏");
  }

  _autoBackup() async {
    // 之前登录过，因为关闭应用会导致连接关闭，所以下次重启应用时需要再次连接
    if (SPUtil.getBool("login")) {
      await WebDavUtil.initWebDav(
        SPUtil.getString("webdav_uri"),
        SPUtil.getString("webdav_user"),
        SPUtil.getString("webdav_password"),
      );
    }
    // 如果都设置了自动备份，则只需要压缩一次
    if (SPUtil.getBool("auto_backup_local") &&
        SPUtil.getBool("auto_backup_webdav")) {
      debugPrint("准备本地和WebDav自动备份");
      BackupUtil.backup(
        localBackupDirPath:
            SPUtil.getString("backup_local_dir", defaultValue: "unset"),
        remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
        showToastFlag: false,
        automatic: true,
      );
    } else if (SPUtil.getBool("auto_backup_local")) {
      debugPrint("准备本地自动备份");
      BackupUtil.backup(
        localBackupDirPath:
            SPUtil.getString("backup_local_dir", defaultValue: "unset"),
        showToastFlag: false,
        automatic: true,
      );
    } else if (SPUtil.getBool("auto_backup_webdav")) {
      debugPrint("准备WebDav自动备份");
      BackupUtil.backup(
        remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
        showToastFlag: false,
        automatic: true,
      );
      // String lastTimeBackup = SPUtil.getString("last_time_backup");
      // // 不为空串表示之前备份过
      // if (lastTimeBackup != "") {
      //   debugPrint("上次备份的时间：$lastTimeBackup");
      //   DateTime dateTime = DateTime.parse(lastTimeBackup);
      //   DateTime now = DateTime.now();
      //   // 距离上次备份超过1天，则进行备份
      //   // if (now.difference(dateTime).inSeconds >= 10) {
      //   if (now.difference(dateTime).inDays >= 1) {
      //     // WebDavUtil.backupData(true);
      //   }
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());

    return Obx(() => OKToast(
          position: ToastPosition.top,
          dismissOtherOnShow: true,
          // 正在显示第一个时，如果弹出第二个，则会先关闭第一个
          radius: 20,
          textPadding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          // backgroundColor: Colors.blue,
          // textStyle: const TextStyle(
          //     color: Colors.white,
          //     fontSize: 15,
          //     fontWeight: FontWeight.w600,
          //     decoration: TextDecoration.none),

          backgroundColor:
              themeController.isDarkMode.value ? Colors.white : Colors.black,
          textStyle: TextStyle(
              color: themeController.isDarkMode.value
                  ? Colors.black
                  : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none),
          child: MaterialApp(
            title: '漫迹',
            // 后台应用显示名称
            home: const MyHome(),
            scrollBehavior: MyCustomScrollBehavior(),
            // 自定义滚动行为
            theme: ThemeData(
              primaryColor: ThemeUtil.getThemePrimaryColor(),
              brightness: themeController.isDarkMode.value
                  ? Brightness.dark
                  : Brightness.light,
              // fontFamily: "yuan",
              appBarTheme: AppBarTheme(
                shadowColor: Colors.transparent,
                centerTitle: false,
                elevation: 0,
                foregroundColor: ThemeUtil.getFontColor(),
                backgroundColor: ThemeUtil.getAppBarBackgroundColor(),
                iconTheme: IconThemeData(
                  color: ThemeUtil.getIconButtonColor(),
                ),
              ),
              iconTheme: IconThemeData(
                color: ThemeUtil.getIconButtonColor(),
              ),
              scaffoldBackgroundColor: ThemeUtil.getScaffoldBackgroundColor(),
              inputDecorationTheme: InputDecorationTheme(
                suffixIconColor: ThemeUtil.getIconButtonColor(),
              ),
              listTileTheme: ListTileThemeData(
                iconColor: themeController.isDarkMode.value
                    ? Colors.white70
                    : Colors.black54,
                // 会影响副标题颜色
                // textColor: ThemeUtil.getFontColor(),
              ),
              radioTheme: RadioThemeData(
                  fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return ThemeUtil.getThemePrimaryColor();
                }
                return null;
              })),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  selectedItemColor: ThemeUtil.getThemePrimaryColor()),
              textButtonTheme: TextButtonThemeData(
                  style: ButtonStyle(
                      textStyle: MaterialStateProperty.all(
                          const TextStyle(color: Colors.black)))),
              tabBarTheme: TabBarTheme(
                unselectedLabelColor: themeController.isDarkMode.value
                    ? Colors.white70
                    : Colors.black54,
                labelColor: ThemeUtil.getThemePrimaryColor(), // 选中的tab字体颜色
              ),
              // 滚动条主题
              scrollbarTheme: ScrollbarThemeData(
                trackVisibility: MaterialStateProperty.all(true),
                thickness: MaterialStateProperty.all(5),
                interactive: true,
                radius: const Radius.circular(10),
                thumbColor: MaterialStateProperty.all(
                  themeController.isDarkMode.value
                      ? const Color.fromRGBO(80, 80, 80, 1.0)
                      : const Color.fromRGBO(160, 160, 160, 1.0),
                ),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              //指定本地化的字符串和一些其他的值
              GlobalWidgetsLocalizations.delegate,
              //定义 widget 默认的文本方向，从左到右或从右到左。
              GlobalCupertinoLocalizations.delegate,
              //对应的 Cupertino 风格（Cupertino 风格组件即 iOS 风格组件）
            ],
            supportedLocales: const [
              Locale('zh', 'CH'),
              Locale('en', 'US'),
            ],
          ),
        ));
  }
}

class MyHome extends StatelessWidget {
  const MyHome({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [Tabs(), UpdateHint(checkLatestVersion: true)],
    );
  }
}

// Enable scrolling with mouse dragging
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
