import 'dart:async';
import 'dart:math';

import 'package:animetrace/utils/sp_profile.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_dialog.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:window_manager/window_manager.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  int seconds = 3;
  Timer? timer;
  double percent = 0.2;

  @override
  void initState() {
    1.seconds.delay(() {
      percent = 0.5;
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLog.debug('build test page');
    return Scaffold(
      appBar: AppBar(title: const Text("测试")),
      body: CommonScaffoldBody(child: _buildBody(context)),
    );
  }

  ListView _buildBody(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('保存当前窗口大小'),
          onTap: () async {
            SpProfile.setWindowSize(await windowManager.getSize());
          },
        ),
        ListTile(
          title: const Text('loading mask'),
          onTap: () {
            ToastUtil.showLoading(
              task: () async {
                AppLog.info('do task');
                await 3.delay();
              },
              onTaskComplete: () {
                AppLog.info('task complete');
              },
            );
          },
        ),
        const LoadingWidget(),
        LottieBuilder.asset(
          Assets.lotties.playing,
          width: 24,
          height: 24,
        ),
        const SizedBox(height: 10),
        LinearPercentIndicator(
          lineHeight: 12,
          animation: true,
          animateFromLastPercent: true,
          percent: percent,
          progressColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).disabledColor,
          barRadius: const Radius.circular(24),
        ),
        ListTile(
          title: const Text('无限滚动重复展示'),
          onTap: () {
            var arr = [
              'Apple',
              'Banana',
              'Cherry',
              'Lemon',
              'Orange',
              'Peach',
              'Pear',
              'Watermelon'
            ];
            Get.to(
              () => Scaffold(
                appBar: AppBar(),
                body: ListView.builder(
                  itemBuilder: (context, index) {
                    AppLog.info('build $index');
                    var realIndex = index % arr.length;
                    return ListTile(
                      title: Text(arr[realIndex]),
                      subtitle: Text('index=$index, realIndex=$realIndex'),
                    );
                  },
                ),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("测试下拉刷新"),
          onTap: () {
            var refreshController = RefreshController();
            int pageSize = 5;
            var list = List.generate(pageSize, (index) => index);

            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setState) => Scaffold(
                    appBar: AppBar(),
                    body: SmartRefresher(
                      controller: refreshController,
                      enablePullDown: true,
                      enablePullUp: true,
                      onRefresh: () async {
                        await Future.delayed(const Duration(seconds: 1));
                        list = List.generate(pageSize, (index) => index);
                        refreshController.refreshCompleted();
                        setState(() {});
                      },
                      onLoading: () async {
                        AppLog.info("加载更多");
                        list.addAll(List.generate(
                            pageSize, (index) => list.length + index));
                        await Future.delayed(const Duration(seconds: 1));
                        refreshController.loadComplete();
                        setState(() {});
                      },
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          AppLog.info("build $index");
                          return ListTile(
                            title: Text("$index"),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ));
          },
        ),
        ListTile(
          title: const Text("定时器"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                  onPressed: () {
                    // 保证关闭之前开启的定时器
                    timer?.cancel();

                    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                      AppLog.info("timer=${timer.tick}");
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
            build: (context, value) => Text(
                TimeUtil.getReadableDuration(Duration(seconds: value.toInt()))),
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
            //     AppLog.info("有效");
            //   } else {
            //     AppLog.info("失效");
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
                  TextButton(onPressed: () => cancel(), child: const Text("关闭"))
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
                  return const LoadingDialog("获取信息中...");
                });
            await Future.delayed(const Duration(seconds: 2));
            if (loadingContext != null) Navigator.pop(loadingContext!);
          },
        ),
        ListTile(
          title: const Text("加载框2"),
          onTap: () async {
            BotToast.showCustomLoading(
              toastBuilder: (void Function() cancelFunc) {
                // 方式1
                Future.delayed(const Duration(seconds: 1), () {
                  cancelFunc.call();
                });

                return const LoadingDialog("获取信息中...");
              },
              clickClose: true,
              onClose: () {
                AppLog.info("close");
              },
            );

            // 方式2，缺点是没有关闭渐变动画
            // Future.delayed(const Duration(seconds: 1), () {
            //   BotToast.closeAllLoading();
            // });
          },
        ),
        ListTile(
          title: const Text("加载框3"),
          onTap: () async {
            ToastUtil.showLoading(
                msg: "获取信息中...",
                task: () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                });
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
    );
  }
}
