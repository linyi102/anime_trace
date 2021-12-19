import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  WidgetsFlutterBinding.ensureInitialized();
  await SPUtil.getInstance();
  await SqliteUtil.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: '漫迹', // 后台应用显示名称
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'NotoSans',
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
