import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/tags.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:oktoast/oktoast.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  WidgetsFlutterBinding.ensureInitialized();
  await SPUtil.getInstance();
  await SqliteUtil.getInstance();
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
    debugPrint("initState: MyApp");
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
            WebDavUtil.backupData();
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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'hm',
        ),
        home: const MyHome(),
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
    // return const TestSQL();
  }
}
