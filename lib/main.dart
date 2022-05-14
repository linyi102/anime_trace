import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/components/update_hint.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/pages/tabs.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  WidgetsFlutterBinding
      .ensureInitialized(); // 确保初始化，否则Unhandled Exception: Null check operator used on a null value
  await SPUtil.getInstance();
  sqfliteFfiInit(); // 桌面应用的sqflite初始化
  await ensureLatestData(); // 必须要用await
  // runApp(const MyApp());
  runApp(const GetMaterialApp(
    home: MyApp(),
  ));
}

ensureLatestData() async {
  await ImageUtil.getInstance();
  await SqliteUtil.getInstance();
  // 先创建表，再添加列
  await SqliteUtil.createTableEpisodeNote();
  await SqliteUtil.createTableImage();

  await SqliteUtil.addColumnReviewNumberToHistoryAndNote(); // 添加回顾号列
  await SqliteUtil.addColumnInfoToAnime(); // 为动漫表添加列
  tags = await SqliteUtil.getAllTags();
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _autoBackup();
  }

  _autoBackup() async {
    // 之前登录过，因为关闭应用会导致连接关闭，所以下次重启应用时需要再次连接
    if (SPUtil.getBool("login")) {
      await WebDavUtil.initWebDav(
        SPUtil.getString("webdav_uri"),
        SPUtil.getString("webdav_user"),
        SPUtil.getString("webdav_password"),
      );
      if (!SPUtil.getBool("online") && SPUtil.getBool("auto_backup_webdav")) {
        debugPrint("WebDav 自动备份失败，请检查网络状态");
        showToast("WebDav 自动备份失败，请检查网络状态");
      }
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

  _onBackPressed() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("确定退出程序吗?"),
              actions: <Widget>[
                TextButton(
                  child: const Text("暂不"),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: const Text("确定"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());

    return WillPopScope(
      onWillPop: () async {
        return _onBackPressed();
      },
      child: Obx(() => OKToast(
            // textStyle: const TextStyle(fontFamily: "yuan"),
            position: ToastPosition.center,
            dismissOtherOnShow: true, // 正在显示第一个时，如果弹出第二个，则会先关闭第一个
            child: MaterialApp(
              title: '漫迹', // 后台应用显示名称
              home: const MyHome(),
              theme: ThemeData(
                primarySwatch: Colors.blue,
                brightness: themeController.isDarkMode.value
                    ? Brightness.dark
                    : Brightness.light,
                // fontFamily: "yuan",
                appBarTheme: AppBarTheme(
                  shadowColor: Colors.transparent,
                  centerTitle: false,
                  elevation: 0,
                  foregroundColor: ThemeUtil.getFontColor(),
                  backgroundColor: themeController.isDarkMode.value
                      ? const Color.fromRGBO(48, 48, 48, 1)
                      : Colors.white,
                  iconTheme: IconThemeData(
                    color: ThemeUtil.getIconButton(),
                  ),
                ),
                iconTheme: IconThemeData(
                  color: ThemeUtil.getIconButton(),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  suffixIconColor: ThemeUtil.getIconButton(),
                ),
                listTileTheme: ListTileThemeData(
                    iconColor: themeController.isDarkMode.value
                        ? Colors.white70
                        // : Colors.black54,
                        : Colors.blue,
                    textColor: ThemeUtil.getFontColor()),
                radioTheme: RadioThemeData(
                    fillColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.blue;
                  }
                })),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                    selectedItemColor: Colors.blue),
                textButtonTheme: TextButtonThemeData(
                    style: ButtonStyle(
                        textStyle: MaterialStateProperty.all(
                            const TextStyle(color: Colors.black)))),
                tabBarTheme: TabBarTheme(
                  unselectedLabelColor: themeController.isDarkMode.value
                      ? Colors.white70
                      : Colors.black54,
                  labelColor: Colors.blue, // 选中的tab字体颜色
                ),
                scrollbarTheme: ScrollbarThemeData(
                  showTrackOnHover: true,
                  thickness: MaterialStateProperty.all(5),
                  interactive: true,
                  radius: const Radius.circular(10),
                  // thumbColor: MaterialStateProperty.all(Colors.blueGrey),
                ),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                  },
                ),
              ),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate, //指定本地化的字符串和一些其他的值
                GlobalWidgetsLocalizations
                    .delegate, //定义 widget 默认的文本方向，从左到右或从右到左。GlobalCupertinoLocalizations.delegate,//对应的 Cupertino 风格（Cupertino 风格组件即 iOS 风格组件）
              ],
              supportedLocales: const [
                Locale('zh', 'CH'),
                Locale('en', 'US'),
              ],
            ),
          )),
    );
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
