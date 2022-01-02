import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/tags.dart';
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
  await SqliteUtil.getInstance();
  await SqliteUtil.addColumnCoverToAnime(); // 添加封面列
  tags = await SqliteUtil.getAllTags();

  runApp(const MyApp());
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
      if (SPUtil.getBool("auto_backup")) {
        String lastTimeBackup = SPUtil.getString("last_time_backup");
        // 不为空串表示之前备份过
        if (lastTimeBackup != "") {
          debugPrint("上次备份的时间：$lastTimeBackup");
          DateTime dateTime = DateTime.parse(lastTimeBackup);
          DateTime now = DateTime.now();
          // 距离上次备份超过1天，则进行备份
          // if (now.difference(dateTime).inSeconds >= 10) {
          if (now.difference(dateTime).inDays >= 1) {
            WebDavUtil.backupData(true);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: '漫迹', // 后台应用显示名称
        home: const MyHome(),
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // brightness: Brightness.dark,
          // fontFamily: 'hm',
          appBarTheme: const AppBarTheme(
            shadowColor: Colors.transparent,
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(
              color: Colors.black,
            ),
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
            },
          ),
          scaffoldBackgroundColor: Colors.white,
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
