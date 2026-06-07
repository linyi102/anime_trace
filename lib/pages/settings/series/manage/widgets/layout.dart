import 'package:flutter/material.dart';
import 'package:animetrace/components/common_tab_bar.dart';
import 'package:animetrace/pages/settings/series/manage/logic.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/widgets/common_tab_bar_view.dart';

import '../style.dart';

class SeriesManageLayoutSettingPage extends StatefulWidget {
  const SeriesManageLayoutSettingPage({super.key, required this.logic});
  final SeriesManageLogic logic;

  @override
  State<SeriesManageLayoutSettingPage> createState() =>
      _SeriesManageLayoutStateSettingPage();
}

class _SeriesManageLayoutStateSettingPage
    extends State<SeriesManageLayoutSettingPage>
    with SingleTickerProviderStateMixin {
  SeriesManageLogic get logic => widget.logic;

  final List<String> tabs = ['排序', '界面'];
  late final TabController tabController;
  double coverHeight = SeriesStyle.getItemCoverHeight();

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: tabs.length,
      vsync: this,
      animationDuration: PlatformUtil.tabControllerAnimationDuration,
    );
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
          tabs: tabs.map((e) => Tab(text: e)).toList()),
      body: CommonTabBarView(controller: tabController, children: [
        _buildSortPage(),
        _buildLayoutPage(),
      ]),
    );
  }

  Widget _buildSortPage() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        for (var cond in SeriesListSortCond.values) _buildSortTile(cond),
      ],
    );
  }

  Widget _buildLayoutPage() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        ListTile(
          onTap: () {
            if (SeriesStyle.useList) {
              SeriesStyle.enableGrid();
            } else {
              SeriesStyle.enableList();
            }
            setState(() {});
            logic.update();
          },
          title: Text("${SeriesStyle.useList ? '列表' : '网格'}样式"),
          subtitle: const Text('点击切换列表/网格样式'),
        ),
        if (SeriesStyle.useGrid)
          SwitchListTile(
            title: const Text('仅显示 1 张封面'),
            value: SeriesStyle.useSingleCover,
            onChanged: (value) {
              SeriesStyle.toggleUseSingleCover();
              setState(() {});
              logic.update();
            },
          ),
        if (SeriesStyle.useGrid) _buildSetCoverHeightTile(),
      ],
    );
  }

  _buildSetCoverHeightTile() {
    return ListTile(
        title: const Text("封面高度"),
        trailing: SizedBox(
          width: 200,
          child: Stack(
            children: [
              SizedBox(
                width: 190,
                child: Slider(
                  min: 40,
                  max: 300,
                  divisions: 260,
                  value: coverHeight,
                  onChangeStart: (value) {
                    setState(() {});
                    logic.update();
                  },
                  onChanged: (value) {
                    AppLog.info("拖动中，value=$value");
                    coverHeight = value;
                    setState(() {});
                  },
                  onChangeEnd: (value) {
                    AppLog.info("拖动结束，value=$value");
                    SeriesStyle.setItemCoverHeight(value);
                    setState(() {});
                    logic.update();
                  },
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text("${coverHeight.toInt()}", textScaleFactor: 0.8),
              )
            ],
          ),
        ));
  }

  ListTile _buildSortTile(SeriesListSortCond cond) {
    bool selected = SeriesStyle.sortRule.cond == cond;
    return ListTile(
      title: Text(cond.title),
      selected: selected,
      leading: selected
          ? Icon(SeriesStyle.sortRule.desc
              ? Icons.arrow_downward
              : Icons.arrow_upward)
          : const SizedBox(),
      onTap: () {
        // 如果还没选中，则选择该排序，并重置为升序
        if (SeriesStyle.sortRule.cond != cond) {
          SeriesStyle.setSortCond(cond);
        } else {
          // 如果已选中，再次点击时进行升降序
          SeriesStyle.toggleSortDesc();
        }
        logic.sort();
        setState(() {});
      },
    );
  }
}
