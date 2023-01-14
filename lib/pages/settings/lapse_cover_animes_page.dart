import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_cover_detail.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../components/anime_grid_cover.dart';
import '../../components/get_anime_grid_delegate.dart';
import '../../components/empty_data_hint.dart';
import '../../components/loading_dialog.dart';
import '../../controllers/anime_controller.dart';
import '../../utils/sqlite_util.dart';

/// 展示网络封面失效的所有动漫
class LapseCoverAnimesPage extends StatefulWidget {
  const LapseCoverAnimesPage({Key? key}) : super(key: key);

  @override
  State<LapseCoverAnimesPage> createState() => _LapseCoverAnimesPageState();
}

class _LapseCoverAnimesPageState extends State<LapseCoverAnimesPage> {
  List<Anime> lapseCoverAnimes = [];
  bool loadOk = false;
  bool recovering = false;

  @override
  void initState() {
    super.initState();
    initData();
  }

  initData() async {
    List<Anime> animes = await AnimeDao.getAllAnimes();
    // 检测网络图片是否有效
    // 开启新线程来计算，否则会造成加载圈卡顿
    lapseCoverAnimes = await compute(getAllLapseCoverAnimes, animes);
    loadOk = true;
    if (mounted) {
      setState(() {});
    }
    Log.info("网络封面检测完毕");
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("失效网络封面", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          // 只有当全部检测完毕后，才能刷新
          if (loadOk)
            IconButton(
              onPressed: () {
                setState(() {
                  recovering = true;
                });

                BuildContext? loadingContext;
                showDialog(
                    context: context, // 页面context
                    builder: (context) {
                      // 对话框context
                      loadingContext = context; // 将对话框context赋值给变量，用于任务完成后完毕
                      return const LoadingDialog("重新获取封面中...");
                    });
                List<Future> futures = [];
                for (var anime in lapseCoverAnimes) {
                  futures.add(
                      ClimbAnimeUtil.climbAnimeInfoByUrl(anime).then((value) {
                    setState(() {
                      anime = value;
                    });
                    SqliteUtil.updateAnimeCoverUrl(
                        anime.animeId, anime.animeCoverUrl);
                  }));
                }
                Future.wait(futures).then((value) async {
                  await Future.delayed(
                      const Duration(milliseconds: 200)); // 避免任务很快结束，没有关闭加载框
                  if (loadingContext != null) Navigator.pop(loadingContext!);
                  showToast("封面恢复完毕");
                  setState(() {
                    recovering = false;
                  });
                });
              },
              icon: const Icon(Icons.auto_fix_high),
              tooltip: "恢复失效封面",
            ),
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                          title: Text("提示"),
                          content: Text("因为会缓存封面，所以查询结果中有些动漫仍可以看到封面"),
                        ));
              },
              icon: const Icon(Icons.info_outlined)),
        ],
      ),
      body: !loadOk
          ? const Center(
              child: RefreshProgressIndicator(),
            )
          : lapseCoverAnimes.isEmpty
              ? Center(child: emptyDataHint("没有找到失效的网络封面"))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
                  gridDelegate: getAnimeGridDelegate(context),
                  itemCount: lapseCoverAnimes.length,
                  itemBuilder: (BuildContext context, int index) {
                    Anime anime = lapseCoverAnimes[index];
                    return MaterialButton(
                        padding: const EdgeInsets.all(0),
                        child: AnimeGridCover(anime,
                            showProgress: false, showReviewNumber: false),
                        onPressed: () {
                          // 恢复中，不允许进入封面详细页
                          if (recovering) return;

                          // 恢复备份后，如果之前没有进入过动漫详细页，则没有put过，所以不能使用Get.find
                          final AnimeController animeController =
                              Get.put(AnimeController());
                          animeController.setAnime(anime);
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (context) => AnimeCoverDetail()))
                              .then((value) {
                            // 将这里的anime传入了animeController，在封面详细页修改封面后返回，需要重新刷新状态
                            setState(() {});
                          });
                        });
                  },
                ),
    );
  }
}

Future<List<Anime>> getAllLapseCoverAnimes(List<Anime> animes) async {
  List<Anime> lapseCoverAnimes = [];
  List<Future> futures = [];
  for (var anime in animes) {
    if (anime.animeCoverUrl.startsWith("http")) {
      // 添加到future中，并使用then
      // 如果在for里使用await，只能等返回结果后，才会执行下一次循环
      futures
          .add(DioPackage.urlResponseOk(anime.animeCoverUrl).then((responseOk) {
        if (!responseOk) {
          Log.info("添加失效封面动漫：${anime.animeName}");
          lapseCoverAnimes.add(anime);
        }
      }));
    }
  }
  // 等待所有future结果
  await Future.wait(futures);
  return lapseCoverAnimes;
}
