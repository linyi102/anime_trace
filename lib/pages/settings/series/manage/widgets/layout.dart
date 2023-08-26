import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/settings/series/manage/logic.dart';
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
              subtitle: const Text('切换列表/网格样式'),
            ),
            const SettingTitle(title: '排序'),
            for (var cond in SeriesListSortCond.values) _buildSortTile(cond)
          ],
        ),
      ),
    );
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
