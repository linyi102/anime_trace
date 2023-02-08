import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_collection/search_db_anime.dart';
import 'package:flutter_test_future/pages/settings/label_manage_page.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';

class AnimeDetailLabels extends StatefulWidget {
  const AnimeDetailLabels({required this.animeController, super.key});
  final AnimeController animeController;

  @override
  State<AnimeDetailLabels> createState() => _AnimeDetailLabelsState();
}

class _AnimeDetailLabelsState extends State<AnimeDetailLabels> {
  final LabelsController labelsController = Get.find(); // 动漫详细页的标签

  Anime get _anime => widget.animeController.anime.value;

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  _loadLabels() async {
    Log.info("查询当前动漫(id=${_anime.animeId})的所有标签");
    // labelsController.labelsInAnimeDetail.value =
    //     await AnimeLabelDao.getLabelsByAnimeId(_anime.animeId);
    // labelsController.animeId = _anime.animeId;
    widget.animeController.acqLabels();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _getLabelChips(),
        ));
  }

  // 构建标签chips，最后添加增加标签和管理删除chip
  _getLabelChips() {
    List<Widget> chips =
        // Get.find<LabelsController>()
        //     .labelsInAnimeDetail
        widget.animeController.labels
            .map((label) => GestureDetector(
                  onTap: () async {
                    Log.info("点按标签：$label");
                    // 关闭当前详细页并打开本地动漫搜索页(因为如果不关闭当前详细页，则当前的animeController里的动漫会被后来打开的动漫所覆盖)
                    // 使用pushReplacement而非先pop再push，这样不就会显示关闭详细页的路由动画了
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SearchDbAnime(incomingLabelId: label.id)),
                        result: _anime);

                    // 进入某些动漫无法显示集信息，很奇怪，也不是ids的问题
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) =>
                    //           SearchDbAnime(incomingLabelId: label.id)),
                    // );
                  },
                  onLongPress: () {
                    Log.info("长按标签：$label");
                  },
                  child: Chip(
                    label: Text(label.name),
                    backgroundColor: ThemeUtil.getCardColor(),
                  ),
                ))
            .toList();

    chips.add(GestureDetector(
      onTap: () {
        Log.info("添加标签");
        // 弹出底部菜单，提供搜索和查询列表
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => LabelManagePage(
                  enableSelectLabelForAnime: true,
                  animeController: widget.animeController,
                )));

        // 不适配主题，且搜索时显示空白
        // Get.bottomSheet(
        //   const LabelManagePage(enableSelectLabelForAnime: true),
        // );

        // 弹出软键盘时报错，尽管可以正常运行
        // showFlexibleBottomSheet(
        //     duration: const Duration(milliseconds: 200),
        //     minHeight: 0,
        //     initHeight: 0.5,
        //     maxHeight: 1,
        //     context: context,
        //     builder: (
        //       BuildContext context,
        //       ScrollController scrollController,
        //       double bottomSheetOffset,
        //     ) =>
        //         const LabelManagePage(enableSelectLabelForAnime: true),
        //     isExpand: true);
      },
      child: Chip(
        label: const Text("  +  "),
        backgroundColor: ThemeUtil.getCardColor(),
      ),
    ));

    return chips;
  }
}
