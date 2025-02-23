import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_list_cover.dart';
import 'package:animetrace/components/empty_data_hint.dart';
import 'package:animetrace/components/percent_bar.dart';
import 'package:animetrace/models/data_state.dart';
import 'package:animetrace/widgets/progress.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/pages/network/sources/pages/lapse_cover_fix/lapse_cover_controller.dart';
import 'package:animetrace/widgets/button/action_button.dart';
import 'package:get/get.dart';
import 'package:animetrace/utils/toast_util.dart';

/// 展示网络封面失效的所有动漫
class LapseCoverAnimesPage extends StatefulWidget {
  const LapseCoverAnimesPage({Key? key}) : super(key: key);

  @override
  State<LapseCoverAnimesPage> createState() => _LapseCoverAnimesPageState();
}

class _LapseCoverAnimesPageState extends State<LapseCoverAnimesPage> {
  final controller = Get.put(LapseCoverController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: controller,
      builder: (_) => Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            !controller.hasDetected
                ? const SizedBox()
                : !controller.loadOk
                    ? _buildDetecting()
                    : controller.coverAnimes.isEmpty
                        ? _buildEmptyHint()
                        : RefreshIndicator(
                            onRefresh: controller.detectAnimes,
                            child: _buildAnimeListView(),
                          ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: 300,
                child: _buildBottomButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        "失效封面" +
            (controller.loadOk
                ? ' ${controller.coverAnimes.length}'
                : ''),
      ),
    );
  }

  Widget _buildBottomButton() {
    if (!controller.hasDetected) {
      return ActionButton(
        loaderStyle: ButtonLoaderStyle.none,
        onTap: controller.detectAnimes,
        child: const Text('开始检测'),
      );
    }

    if (!controller.loadOk) return const SizedBox();

    return ActionButton(
      loaderStyle: ButtonLoaderStyle.none,
      onTap: controller.fixCovers,
      child: ProgressBuilder(
        controller: controller.fixProgressController,
        builder: (context, count, total, percent) {
          String text = '修复封面';
          if (controller.fixing) text = '修复进度：$count / $total';
          return Text(text);
        },
      ),
    );
  }

  Center _buildDetecting() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ProgressBuilder(
          controller: controller.detectProgressController,
          builder: (context, count, total, percent) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('检测到 ${controller.coverAnimes.length} 个失效封面',
                  style: Theme.of(context).textTheme.titleMedium),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: PercentBar(percent: percent)),
              ),
              Text(
                '$count / $total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        )
      ],
    ));
  }

  Center _buildEmptyHint() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        emptyDataHint(msg: "没有找到失效封面。"),
        const SizedBox(height: 20),
        TextButton(
            onPressed: () => controller.detectAnimes(),
            child: const Text("再次检测", style: TextStyle(color: Colors.white)))
      ],
    ));
  }

  Widget _buildAnimeListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: controller.coverAnimes.length,
      itemBuilder: (context, index) {
        final anime = controller.coverAnimes[index];
        final state = controller.states[anime.animeId];
        return ListTile(
          leading: AnimeListCover(anime),
          title: Text(anime.animeName),
          subtitle: Text(anime.getAnimeSource()),
          trailing: state?.when(
            data: (message) => Text(message),
            error: (_, __, ___) => const SizedBox(),
            loading: (_) => const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          onTap: () {
            _tryToDetailPage(index);
          },
        );
      },
    );
  }

  _tryToDetailPage(int index) {
    final anime = controller.coverAnimes[index];
    // 恢复中，不允许进入详细页
    if (controller.states[anime.animeId]?.isLoading == true) {
      ToastUtil.showText("正在恢复中，请稍后进入");
      return;
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AnimeDetailPage(anime)))
        .then((value) {
      // 可能内部迁移了动漫或修改了封面
      // 仍然build是该页面，而不是只build AnimeGridCover，必须要在AnimeGridCover里使用setState
      setState(() {
        // anime = value; 返回后封面没有变化，需要使用index，如下
        controller.coverAnimes[index] = value;
      });
    });
  }
}
