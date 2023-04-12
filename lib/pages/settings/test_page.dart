import 'dart:async';
import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:timer_count_down/timer_count_down.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  int seconds = 3;
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Scaffold(
      appBar: AppBar(title: const Text("测试")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("定时器"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                    onPressed: () {
                      // 保证关闭之前开启的定时器
                      timer?.cancel();

                      timer =
                          Timer.periodic(const Duration(seconds: 1), (timer) {
                        Log.info("timer=${timer.tick}");
                      });
                    },
                    child: const Text("开启")),
                TextButton(
                    onPressed: () {
                      timer?.cancel();
                    },
                    child: const Text("关闭"))
              ],
            ),
          ),
          ListTile(
            title: const Text("倒计时"),
            subtitle: Countdown(
              seconds: seconds,
              build: (context, value) => Text(TimeUtil.getReadableDuration(
                  Duration(seconds: value.toInt()))),
            ),
            onTap: () {
              setState(() {
                seconds = Random().nextInt(10);
              });
            },
          ),

          ListTile(
            title: const Text("测试图片失效"),
            onTap: () async {
              // 模拟器测试时不管有无使用compute，大多数图片都会捕捉到连接超时错误
              // head改成get也是
              // List<Anime> animes = await AnimeDao.getAllAnimes();
              // List<Anime> lapseCoverAnimes =
              //     await compute(getAllLapseCoverAnimes, animes);

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
            title: const Text("不使用context来显示对话框"),
            onTap: () {
              ToastUtil.showDialog(
                builder: (cancel) => AlertDialog(
                  title: const Text("还原失败"),
                  actions: [
                    TextButton(
                        onPressed: () => cancel(), child: const Text("关闭"))
                  ],
                ),
              );
              // BotToast.showCustomLoading(
              //   animationDuration: const Duration(milliseconds: 200),
              //   animationReverseDuration: const Duration(milliseconds: 200),
              //   clickClose: true,
              //   toastBuilder: (cancelFunc) => AlertDialog(
              //     title: const Text("还原失败"),
              //     actions: [
              //       TextButton(
              //           onPressed: () => cancelFunc(), child: const Text("关闭"))
              //     ],
              //   ),
              // );
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
                              ToastUtil.showText("${DateTime.now()}");
                            },
                          ),
                        ],
                      ));
            },
          ),
          ListTile(
            title: const Text("弹出消息"),
            onTap: () {
              // ToastUtil.showText("${DateTime.now()}");
              ToastUtil.showText("正在更新书架");
            },
          ),
          ListTile(
            title: const Text("加载框1"),
            onTap: () async {
              BuildContext? loadingContext;
              showDialog(
                  context: context,
                  builder: (context) {
                    loadingContext = context;
                    return const LoadingDialog("正在获取详细信息");
                  });
              await Future.delayed(const Duration(seconds: 2));
              if (loadingContext != null) Navigator.pop(loadingContext!);
            },
          ),
          ListTile(
            title: const Text("加载框1"),
            onTap: () async {
              BotToast.showCustomLoading(
                toastBuilder: (void Function() cancelFunc) {
                  // 方式1
                  Future.delayed(const Duration(seconds: 1), () {
                    cancelFunc.call();
                  });

                  return const LoadingDialog("正在获取详细信息");
                },
                clickClose: true,
                onClose: () {
                  Log.info("close");
                },
              );

              // 方式2，缺点是没有关闭渐变动画
              // Future.delayed(const Duration(seconds: 1), () {
              //   BotToast.closeAllLoading();
              // });
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
