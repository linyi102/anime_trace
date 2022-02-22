import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
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
  runApp(const MyApp());
}

ensureLatestData() async {
  await ImageUtil.getInstance();
  await SqliteUtil.getInstance();
  await SqliteUtil.addColumnCoverToAnime(); // 添加封面列
  await SqliteUtil.addColumnReviewNumberToHistoryAndNote(); // 添加回顾号列
  await SqliteUtil.createTableEpisodeNote();
  await SqliteUtil.createTableImage();
  await SqliteUtil.addColumnCoverSourceToAnime(); // 添加搜索源列
  tags = await SqliteUtil.getAllTags();
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    return WillPopScope(
      onWillPop: () async {
        return _onBackPressed();
      },
      child: OKToast(
        textStyle: const TextStyle(fontFamily: "yuan"),
        child: MaterialApp(
          title: '漫迹', // 后台应用显示名称
          home: const MyHome(),
          theme: ThemeData(
            primarySwatch: Colors.blue,
            // brightness: Brightness.dark,
            fontFamily: "yuan",
            appBarTheme: const AppBarTheme(
              shadowColor: Colors.transparent,
              elevation: 0,
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(
                color: Colors.black,
              ),
              // titleTextStyle: TextStyle(
              //   color: Colors.black,
              //   fontWeight: FontWeight.bold,
              // ),
              // 会影响字体大小，应该和TextStyle有关
            ),
            scrollbarTheme: ScrollbarThemeData(
              showTrackOnHover: true,
              thickness: MaterialStateProperty.all(7),
              interactive: true,
              radius: const Radius.circular(10),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
              },
            ),
            // 无效，不知道为什么
            // buttonTheme: const ButtonThemeData(
            //   hoverColor: Colors.transparent, // 悬停时的颜色
            //   highlightColor: Colors.transparent, // 长按时的颜色
            //   splashColor: Colors.transparent, // 点击时的颜色
            // ),
            // scaffoldBackgroundColor: Colors.white,
            scaffoldBackgroundColor: const Color.fromRGBO(250, 250, 250, 1),
            // scaffoldBackgroundColor: const Color.fromRGBO(247, 247, 247, 1),
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
      ),
    );
  }
}

class MyHome extends StatelessWidget {
  const MyHome({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Tabs();
  }
}
