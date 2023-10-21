import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/settings/series/manage/logic.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../../../widgets/setting_title.dart';
import '../style.dart';

class SeriesManageLayoutSettingPage extends StatefulWidget {
  const SeriesManageLayoutSettingPage({super.key, required this.logic});
  final SeriesManageLogic logic;

  @override
  State<SeriesManageLayoutSettingPage> createState() =>
      _SeriesManageLayoutStateSettingPage();
}

class _SeriesManageLayoutStateSettingPage
    extends State<SeriesManageLayoutSettingPage> {
  SeriesManageLogic get logic => widget.logic;

  double coverHeight = SeriesStyle.getItemCoverHeight();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SettingTitle(title: '显示'),
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
            const SettingTitle(title: '排序'),
            for (var cond in SeriesListSortCond.values) _buildSortTile(cond)
          ],
        ),
      ),
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
                    Log.info("拖动中，value=$value");
                    coverHeight = value;
                    setState(() {});
                  },
                  onChangeEnd: (value) {
                    Log.info("拖动结束，value=$value");
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
              ? MingCuteIcons.mgc_arrow_down_line
              : MingCuteIcons.mgc_arrow_up_line)
          : const SizedBox(),
      onTap: () {
        // 如果还没选中，则选择该排序，并重置为升序
        if (SeriesStyle.sortRule.cond != cond) {
          SeriesStyle.setSortCond(cond);
          SeriesStyle.resetSortDesc();
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
