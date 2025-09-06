import 'package:animetrace/components/anime_custom_cover.dart';
import 'package:animetrace/widgets/picker/single_select_dialog.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/common_tab_bar.dart';
import 'package:animetrace/components/dialog/dialog_select_uint.dart';
import 'package:animetrace/controllers/anime_display_controller.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/widgets/common_tab_bar_view.dart';
import 'package:get/get.dart';
import 'package:animetrace/utils/log.dart';

class AnimesDisplaySetting extends StatefulWidget {
  final bool showAppBar;
  final Widget sortPage;

  const AnimesDisplaySetting(
      {Key? key, this.showAppBar = true, required this.sortPage})
      : super(key: key);

  @override
  State<AnimesDisplaySetting> createState() => _AnimesDisplaySettingState();
}

class _AnimesDisplaySettingState extends State<AnimesDisplaySetting>
    with SingleTickerProviderStateMixin {
  final AnimeDisplayController animeDisplayController = Get.find();

  final List<String> tabStr = ["排序", "界面"];

  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
        length: tabStr.length,
        vsync: this,
        animationDuration: PlatformUtil.tabControllerAnimationDuration);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBottomTabBar(
          tabController: tabController,
          tabs: tabStr.map((e) => Tab(text: e)).toList()),
      body: CommonTabBarView(controller: tabController, children: [
        widget.sortPage,
        Obx(() => SingleChildScrollView(
              child: Column(
                children:
                    _buildListTiles(context, animeDisplayController).toList(),
              ),
            ))
      ]),
    );
  }

  Iterable<Widget> _buildListTiles(
      BuildContext context, AnimeDisplayController displayController) sync* {
    bool displayList = displayController.displayList.value;
    final style = displayController.coverStyle.value;

    yield SwitchListTile(
      title: const Text("显示清单数量"),
      value: displayController.showAnimeCntAfterTag.value,
      onChanged: (bool value) => displayController.turnShowAnimeCntAfterTag(),
    );

    yield ListTile(
      title: displayList ? const Text("列表样式") : const Text("网格样式"),
      subtitle: const Text("点击切换列表/网格样式"),
      onTap: () {
        displayController.turnDisplayList();
      },
    );

    // 如果显示网格，则添加更多修改选项
    if (!displayList) {
      yield SwitchListTile(
        title: const Text("列数自适应"),
        value: displayController.enableResponsiveGridColumnCnt.value,
        onChanged: (bool value) {
          displayController.turnEnableResponsiveGridColumnCnt();
        },
      );

      yield ListTile(
        title: const Text("修改列数"),
        subtitle: Text("${displayController.gridColumnCnt}"),
        enabled: !displayController.enableResponsiveGridColumnCnt.value,
        onTap: () {
          dialogSelectUint(context, "选择列数",
                  initialValue: displayController.gridColumnCnt.value,
                  minValue: 1,
                  maxValue: 10)
              .then((value) {
            if (value == null) {
              AppLog.info("未选择，直接返回");
              return;
            }
            displayController.setGridColumnCnt(value);
          });
        },
      );

      yield ListTile(
        title: const Text('名字位置'),
        subtitle: Text(style.namePlacement.label),
        onTap: () async {
          final r = await SingleSelectDialog(
            title: const Text('选择位置'),
            value: style.namePlacement,
            options: const [
              Placement.bottomInCover,
              Placement.bottomOutCover,
              Placement.none
            ],
            labelBuilder: (placement) => Text(placement.label),
          ).show(context);
          if (r != null) {
            displayController
                .updateCoverStyle(style.copyWith(namePlacement: r));
          }
        },
      );
      yield ListTile(
        title: const Text('进度条'),
        subtitle: Text(style.progressLinearPlacement.label),
        onTap: () async {
          final r = await SingleSelectDialog(
            title: const Text('选择位置'),
            value: style.progressLinearPlacement,
            options: const [
              Placement.bottomInCover,
              Placement.bottomOutCover,
              Placement.none
            ],
            labelBuilder: (placement) => Text(placement.label),
          ).show(context);
          if (r != null) {
            displayController
                .updateCoverStyle(style.copyWith(progressLinearPlacement: r));
          }
        },
      );
      yield ListTile(
        title: const Text('进度'),
        subtitle: Text(style.progressNumberPlacement.label),
        onTap: () async {
          final r = await SingleSelectDialog(
            title: const Text('选择位置'),
            value: style.progressNumberPlacement,
            options: const [
              Placement.topLeft,
              Placement.topRight,
              Placement.none
            ],
            labelBuilder: (placement) => Text(placement.label),
          ).show(context);
          if (r != null) {
            displayController
                .updateCoverStyle(style.copyWith(progressNumberPlacement: r));
          }
        },
      );
      yield ListTile(
        title: const Text('系列'),
        subtitle: Text(style.seriesPlacement.label),
        onTap: () async {
          final r = await SingleSelectDialog(
            title: const Text('选择位置'),
            value: style.seriesPlacement,
            options: const [
              Placement.topLeft,
              Placement.topRight,
              Placement.none
            ],
            labelBuilder: (placement) => Text(placement.label),
          ).show(context);
          if (r != null) {
            displayController
                .updateCoverStyle(style.copyWith(seriesPlacement: r));
          }
        },
      );
      yield ListTile(
        title: const Text('名字行数'),
        subtitle: Text(style.maxNameLines.toString()),
        onTap: () async {
          final r = await SingleSelectDialog(
            title: const Text('选择行数'),
            value: style.maxNameLines,
            options: const [1, 2, 3],
            labelBuilder: (line) => Text(line.toString()),
          ).show(context);
          if (r != null) {
            displayController.updateCoverStyle(style.copyWith(maxNameLines: r));
          }
        },
      );
    }

    // 其他公共选项
    // yield SwitchListTile(
    //   title: const Text("显示第几次观看"),
    //   value: animeDisplayController.showReviewNumber.value,
    //   onChanged: (bool value) {
    //     animeDisplayController.turnShowReviewNumber();
    //   },
    // );
  }
}
