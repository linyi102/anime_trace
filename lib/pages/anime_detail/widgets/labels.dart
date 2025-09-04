import 'package:flutter/material.dart';
import 'package:animetrace/pages/anime_detail/controllers/anime_controller.dart';
import 'package:animetrace/controllers/labels_controller.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/local_search/views/local_search_page.dart';
import 'package:animetrace/pages/settings/label/home.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/bottom_sheet.dart';
import 'package:get/get.dart';

class AnimeDetailLabels extends StatefulWidget {
  const AnimeDetailLabels({required this.animeController, super.key});
  final AnimeController animeController;

  @override
  State<AnimeDetailLabels> createState() => _AnimeDetailLabelsState();
}

class _AnimeDetailLabelsState extends State<AnimeDetailLabels> {
  final LabelsController labelsController = Get.find(); // 动漫详细页的标签

  Anime get _anime => widget.animeController.anime;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.animeController.isCollected
        ? Obx(() => Wrap(
              spacing: AppTheme.wrapSacing,
              runSpacing: AppTheme.wrapRunSpacing,
              children: _getLabelChips(),
            ))
        : Container();
  }

  // 构建标签chips，最后添加增加标签和管理删除chip
  _getLabelChips() {
    List<Widget> chips =
        // Get.find<LabelsController>()
        //     .labelsInAnimeDetail
        widget.animeController.labels
            .map((label) => GestureDetector(
                  onTap: () async {
                    AppLog.info("点按标签：$label");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DbAnimeSearchPage(label: label)),
                    ).then((value) {
                      widget.animeController.reloadAnime(_anime);
                    });
                  },
                  onLongPress: () {
                    AppLog.info("长按标签：$label");
                  },
                  child: Chip(
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                      label: Text(label.name)),
                ))
            .toList();

    chips.add(GestureDetector(
      child: const Chip(
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(fontSize: 12),
        label: Text("  +  "),
      ),
      onTap: () {
        AppLog.info("添加标签");
        // 弹出底部菜单，提供搜索和查询列表
        // Navigator.of(context).push(MaterialPageRoute(
        //     builder: (context) => LabelManagePage(
        //           enableSelectLabelForAnime: true,
        //           animeController: widget.animeController,
        //         )));
        showCommonModalBottomSheet(
          context: context,
          builder: (context) => LabelManagePage(
            enableSelectLabelForAnime: true,
            animeController: widget.animeController,
          ),
        );

        // 不适配主题，且搜索时显示空白
        // Get.bottomSheet(
        //   const LabelManagePage(enableSelectLabelForAnime: true),
        // );

        // 可以
        // showCommonBottomSheet(
        //     context: context,
        //     expanded: true,
        //     child: LabelManagePage(
        //       enableSelectLabelForAnime: true,
        //       animeController: widget.animeController,
        //     ));

        // 弹出软键盘时报错，尽管可以正常运行
        // showFlexibleBottomSheet(
        //     context: context,
        //     duration: const Duration(milliseconds: 200),
        //     builder: (
        //       BuildContext context,
        //       ScrollController scrollController,
        //       double bottomSheetOffset,
        //     ) =>
        //         const LabelManagePage(enableSelectLabelForAnime: true),
        //     );
      },
    ));

    return chips;
  }
}
