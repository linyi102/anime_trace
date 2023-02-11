import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:oktoast/oktoast.dart';

import '../../dao/anime_dao.dart';
import '../../models/anime.dart';
import '../network/sources/lapse_cover_fix/lapse_cover_animes_page.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Scaffold(
      appBar: AppBar(
        title: const Text("测试"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("测试图片失效"),
            onTap: () async {
              // 模拟器测试时不管有无使用compute，大多数图片都会捕捉到连接超时错误
              // head改成get也是
              List<Anime> animes = await AnimeDao.getAllAnimes();
              List<Anime> lapseCoverAnimes =
                  await compute(getAllLapseCoverAnimes, animes);

              // String url =
              //     "https://proxy-tf-all-ws.bilivideo.com/?url=https://lain.bgm.tv/pic/cover/l/d6/4f/332261_szZEK.jpg";
              // DioPackage.urlResponseOk(url).then((value) {
              //   if (value) {
              //     Log.info("有效");
              //   } else {
              //     Log.info("失效");
              //   }
              // });
            },
          ),
          ListTile(
            title: const Text("对话框中弹出消息"),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                        children: [
                          ListTile(
                            title: const Text("弹出消息"),
                            onTap: () {
                              // 背景页面上显示了
                              showToast("${DateTime.now()}");
                              // 没有显示
                              // showToast("${DateTime.now()}", context: context);
                            },
                          ),
                        ],
                      ));
            },
          ),
          ListTile(
            title: const Text("弹出消息"),
            onTap: () {
              // showToast("${DateTime.now()}");
              showToast("正在更新书架");
            },
          ),
          ListTile(
            title: const Text("加载对话框"),
            onTap: () async {
              BuildContext? loadingContext;
              showDialog(
                  context: context,
                  builder: (context) {
                    loadingContext = context;
                    return const LoadingDialog("获取详细信息中...");
                  });
              await Future.delayed(const Duration(seconds: 2));
              if (loadingContext != null) Navigator.pop(loadingContext!);
            },
          ),

          // 不管用
          ListTile(
            title: const Text("清除缓存"),
            subtitle: Text("${imageCache.currentSizeBytes / 1024 / 1024}MB"),
            onTap: () {
              // imageCache.clear();
            },
          )
        ],
      ),
    );
  }
}
