import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/controllers/anime_display_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/log.dart';

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
    tabController = TabController(length: tabStr.length, vsync: this);
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
      body: TabBarView(controller: tabController, children: [
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
    list.add(ListTile(
      title: displayList ? const Text("列表样式") : const Text("网格样式"),
      subtitle: const Text("单击切换列表样式/网格样式"),
      onTap: () {
        animeDisplayController.turnDisplayList();
      },
    ));

    // 如果显示网格，则添加更多修改选项
    if (!displayList) {
      list.add(ListTile(
        title: const Text("动漫列数自适应"),
        trailing: showToggleButton(
            animeDisplayController.enableResponsiveGridColumnCnt.value),
        onTap: () {
          animeDisplayController.turnEnableResponsiveGridColumnCnt();
        },
      ));

      list.add(ListTile(
        title: const Text("修改动漫列数"),
        subtitle: Text("${animeDisplayController.gridColumnCnt}"),
        enabled: !animeDisplayController.enableResponsiveGridColumnCnt.value,
        onTap: () {
          dialogSelectUint(context, "选择列数",
                  initialValue: animeDisplayController.gridColumnCnt.value,
                  minValue: 1,
                  maxValue: 10)
              .then((value) {
            if (value == null) {
              Log.info("未选择，直接返回");
              return;
            }
            animeDisplayController.setGridColumnCnt(value);
          });
        },
      ));

      list.add(ListTile(
        title: const Text("显示动漫名称"),
        trailing:
            showToggleButton(animeDisplayController.showGridAnimeName.value),
        onTap: () {
          animeDisplayController.turnShowGridAnimeName();
        },
      ));

      list.add(ListTile(
        title: const Text("动漫名称显示在内部"),
        trailing:
            showToggleButton(animeDisplayController.showNameInCover.value),
        enabled: animeDisplayController.showGridAnimeName.value, // 确保先开启显示动漫名称
        onTap: () {
          animeDisplayController.turnShowNameInCover();
        },
      ));

      list.add(ListTile(
        title: const Text("动漫名称只显示一行(默认两行)"),
        trailing:
            showToggleButton(animeDisplayController.nameMaxLines.value == 1),
        onTap: () {
          animeDisplayController.turnNameMaxLines();
        },
      ));

      list.add(ListTile(
        title: const Text("显示动漫进度"),
        trailing: showToggleButton(
            animeDisplayController.showGridAnimeProgress.value),
        onTap: () {
          animeDisplayController.turnShowGridAnimeProgress();
        },
      ));
    }

    // 其他公共选项
    list.add(ListTile(
      title: const Text("显示动漫第几次观看"),
      trailing: showToggleButton(animeDisplayController.showReviewNumber.value),
      onTap: () {
        animeDisplayController.turnShowReviewNumber();
      },
    ));

    list.add(ListTile(
      title: const Text("显示动漫数量"),
      trailing:
          showToggleButton(animeDisplayController.showAnimeCntAfterTag.value),
      onTap: () => animeDisplayController.turnShowAnimeCntAfterTag(),
    ));

    list.add(ListTile(
      title: const Text("封面显示原图"),
      trailing: showToggleButton(animeDisplayController.showOriCover.value),
      onTap: () => animeDisplayController.turnShowOriCover(),
    ));

    return list;
  }

  showToggleButton(bool on) {
    return on
        ? Icon(Icons.toggle_on, color: Theme.of(context).primaryColor)
        : const Icon(Icons.toggle_off_outlined);
  }
}
