import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/get_anime_grid_delegate.dart';
import 'package:flutter_test_future/components/operation_button.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/sources/pages/lapse_cover_fix/lapse_cover_controller.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

/// 展示网络封面失效的所有动漫
class LapseCoverAnimesPage extends StatefulWidget {
  const LapseCoverAnimesPage({Key? key}) : super(key: key);

  @override
  State<LapseCoverAnimesPage> createState() => _LapseCoverAnimesPageState();
}

class _LapseCoverAnimesPageState extends State<LapseCoverAnimesPage> {
  final lapseCoverController = Get.put(LapseCoverController());

  @override
  void initState() {
    super.initState();
    if (!lapseCoverController.loadOk) {
      detect();
    }
  }

  detect() async {
    Log.info("检测失效网络封面中");
    setState(() {
      lapseCoverController.loadOk = false;
    });

    List<Anime> animes = await AnimeDao.getAllAnimes();
    // 检测网络图片是否有效
    // 开启新线程来计算，否则会造成加载圈卡顿
    lapseCoverController.lapseCoverAnimes =
        await compute(getAllLapseCoverAnimes, animes);
    if (mounted) {
      lapseCoverController.loadOk = true;
      setState(() {});
    }
    Log.info("网络封面检测完毕");
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "失效封面 (${lapseCoverController.lapseCoverAnimes.length})",
        ),
      ),
      body: !lapseCoverController.loadOk
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("正在寻找失效封面")
              ],
            ))
          : lapseCoverController.lapseCoverAnimes.isEmpty
              ? _buildEmptyHint()
              : RefreshIndicator(
                  onRefresh: () async {
                    detect();
                  },
                  child: Column(
                    children: [
                      Expanded(child: _buildAnimeGridView()),
                      OperationButton(
                        text: "修复封面",
                        onTap: () => _handleFixCover(),
                      ),
                    ],
                  )),
    );
  }

  Center _buildEmptyHint() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        emptyDataHint(msg: "没有找到失效封面。"),
        const SizedBox(height: 20),
        TextButton(
            onPressed: () => detect(),
            child: const Text("再次检测", style: TextStyle(color: Colors.white)))
      ],
    ));
  }

  _buildAnimeGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
      gridDelegate: getAnimeGridDelegate(context),
      itemCount: lapseCoverController.lapseCoverAnimes.length,
      itemBuilder: (BuildContext context, int index) {
        Anime anime = lapseCoverController.lapseCoverAnimes[index];
        return AnimeGridCover(
          anime,
          showProgress: false,
          showReviewNumber: false,
          onPressed: () {
            // 恢复中，不允许进入详细页
            if (lapseCoverController.recovering) {
              ToastUtil.showText("正在恢复中，请稍后进入");
              return;
            }

            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) => AnimeDetailPage(anime)))
                .then((value) {
              // 可能内部迁移了动漫或修改了封面
              // 仍然build是该页面，而不是只build AnimeGridCover，必须要在AnimeGridCover里使用setState
              setState(() {
                // anime = value; 返回后封面没有变化，需要使用index，如下
                lapseCoverController.lapseCoverAnimes[index] = value;
              });
            });
          },
        );
      },
    );
  }

  _handleFixCover() async {
    // 如果在恢复时再次点击，则直接返回
    if (lapseCoverController.recovering) {
      // 必须放在点击事件内部，否则重绘时就会执行此处
      ToastUtil.showText("恢复中");
      return;
    }

    setState(() {
      lapseCoverController.recovering = true;
    });

    ToastUtil.showLoading(
      msg: "重新获取封面中",
      task: () async {
        int limit = 5, curCnt = 0;
        // 同时恢复。要恢复的图片很多时，显示加载圈时卡顿
        // 还有一种方法是每5个每5个去更新封面
        List<Future> futures = [];
        for (var anime in lapseCoverController.lapseCoverAnimes) {
          futures.add(
              ClimbAnimeUtil.climbAnimeInfoByUrl(anime, showMessage: false)
                  .then((value) {
            AnimeDao.updateAnimeCoverUrl(anime.animeId, anime.animeCoverUrl);
            if (mounted) {
              setState(() {
                anime = value;
              });
            }
          }));

          curCnt++;
          if (curCnt > limit) {
            // 超过限制，先等待上一组全部更新完毕后，再恢复下一组
            await Future.wait(futures);
            // 重置
            futures.clear();
            curCnt = 0;
          }
        }
        // 最后一组不足5个
        if (futures.isNotEmpty) {
          await Future.wait(futures);
          futures.clear();
          curCnt = 0;
        }
      },
      onTaskComplete: (taskValue) {
        // 提示恢复完毕，并关闭加载框
        ToastUtil.showText("封面恢复完毕");
        lapseCoverController.recovering =
            false; // 可以进入详情页或再次修复，因为是点击事件中用到，所以不需要重绘
      },
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

/// 自动拉取最新封面
/// 缺点：如果是GridView懒加载，那么后面的就不会自动拉取。而如果去掉懒加载，则会很卡
class AnimeItemWithAutoPullCover extends StatefulWidget {
  const AnimeItemWithAutoPullCover(
      {this.needPull = false, required this.anime, this.onChanged, super.key});
  final bool needPull; // 传入true则开始自动拉取最新封面
  final Anime anime;
  final void Function(Anime newAnime)? onChanged;

  @override
  State<AnimeItemWithAutoPullCover> createState() =>
      _AnimItemWitheAutoPullCoverState();
}

class _AnimItemWitheAutoPullCoverState
    extends State<AnimeItemWithAutoPullCover> {
  bool recovering = false;
  late Anime anime;

  @override
  void initState() {
    super.initState();
    anime = widget.anime;

    _pullCover();
  }

  void _pullCover() async {
    if (widget.needPull) {
      Anime newAnime = await ClimbAnimeUtil.climbAnimeInfoByUrl(widget.anime,
          showMessage: false);
      if (mounted) {
        setState(() {
          anime = newAnime;
          recovering = false;
        });
      }
      AnimeDao.updateAnimeCoverUrl(anime.animeId, anime.animeCoverUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimeGridCover(
      widget.anime,
      showProgress: false,
      showReviewNumber: false,
      showName: true,
      loading: recovering,
      onPressed: () {
        // 恢复中，不允许进入详细页
        if (recovering) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailPage(widget.anime),
          ),
        ).then((value) {
          // 可能内部迁移了动漫或修改了封面
          setState(() {
            anime = value;
          });
        });
      },
    );
  }
}
