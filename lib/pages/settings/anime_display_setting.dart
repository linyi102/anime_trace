import 'package:animetrace/pages/settings/anime_cover_custom_page.dart';
import 'package:animetrace/routes/get_route.dart';
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
                  children: _buildListTiles(context, animeDisplayController)),
            ))
      ]),
    );
  }

  _buildListTiles(
      BuildContext context, AnimeDisplayController animeDisplayController) {
    bool displayList = animeDisplayController.displayList.value;
    List<Widget> list = [];

    list.add(SwitchListTile(
      title: const Text("显示清单数量"),
      value: animeDisplayController.showAnimeCntAfterTag.value,
      onChanged: (bool value) =>
          animeDisplayController.turnShowAnimeCntAfterTag(),
    ));

    list.add(ListTile(
      title: displayList ? const Text("列表样式") : const Text("网格样式"),
      subtitle: const Text("点击切换列表/网格样式"),
      onTap: () {
        animeDisplayController.turnDisplayList();
      },
    ));

    // 如果显示网格，则添加更多修改选项
    if (!displayList) {
      list.add(SwitchListTile(
        title: const Text("列数自适应"),
        value: animeDisplayController.enableResponsiveGridColumnCnt.value,
        onChanged: (bool value) {
          animeDisplayController.turnEnableResponsiveGridColumnCnt();
        },
      ));

      list.add(ListTile(
        title: const Text("修改列数"),
        subtitle: Text("${animeDisplayController.gridColumnCnt}"),
        enabled: !animeDisplayController.enableResponsiveGridColumnCnt.value,
        onTap: () {
          dialogSelectUint(context, "选择列数",
                  initialValue: animeDisplayController.gridColumnCnt.value,
                  minValue: 1,
                  maxValue: 10)
              .then((value) {
            if (value == null) {
              AppLog.info("未选择，直接返回");
              return;
            }
            animeDisplayController.setGridColumnCnt(value);
          });
        },
      ));

      list.add(ListTile(
        title: const Text("封面样式"),
        onTap: () {
          RouteUtil.materialTo(context, const AnimeCoverCustomPage());
        },
      ));

      list.add(SwitchListTile(
        title: const Text("显示动漫名称"),
        value: animeDisplayController.showGridAnimeName.value,
        onChanged: (bool value) {
          animeDisplayController.turnShowGridAnimeName();
        },
      ));

      list.add(SwitchListTile(
        title: const Text("动漫名称显示在封面内部"),
        value: animeDisplayController.showNameInCover.value,
        // 开启显示动漫名称后才能修改是否显示在内部
        onChanged: animeDisplayController.showGridAnimeName.value
            ? (bool value) {
                animeDisplayController.turnShowNameInCover();
              }
            : null,
      ));

      list.add(SwitchListTile(
        title: const Text("动漫名称只显示一行(默认两行)"),
        value: animeDisplayController.nameMaxLines.value == 1,
        onChanged: (bool value) {
          animeDisplayController.turnNameMaxLines();
        },
      ));

      list.add(SwitchListTile(
        title: const Text("封面右上角显示是否已加入系列"),
        value: animeDisplayController.showSeriesFlagInGridStyle.value,
        onChanged: (bool value) {
          animeDisplayController.turnShowSeriesFlagInGridStyle();
        },
      ));

      list.add(SwitchListTile(
        title: const Text("封面左上角显示进度"),
        value: animeDisplayController.showGridAnimeProgress.value,
        onChanged: (bool value) {
          animeDisplayController.turnShowGridAnimeProgress();
        },
      ));

      list.add(SwitchListTile(
        title: const Text("封面底部显示进度条"),
        value: animeDisplayController.showProgressBar.value,
        onChanged: (bool value) => animeDisplayController.turnShowProgressBar(),
      ));
    }

    // 其他公共选项
    // list.add(SwitchListTile(
    //   title: const Text("显示第几次观看"),
    //   value: animeDisplayController.showReviewNumber.value,
    //   onChanged: (bool value) {
    //     animeDisplayController.turnShowReviewNumber();
    //   },
    // ));
    return list;
  }
}
