
import 'package:flutter/material.dart';
import 'package:animetrace/controllers/theme_controller.dart';
import 'package:animetrace/models/page_switch_animation.dart';
import 'package:animetrace/pages/settings/widgets/main_tab_layout_setting.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/utils/settings.dart';
import 'package:animetrace/utils/sp_profile.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:animetrace/widgets/setting_card.dart';
import 'package:get/get.dart';
import 'package:animetrace/utils/toast_util.dart';

class GeneralSettingPage extends StatefulWidget {
  const GeneralSettingPage({Key? key}) : super(key: key);

  @override
  State<GeneralSettingPage> createState() => _GeneralSettingPageState();
}

class _GeneralSettingPageState extends State<GeneralSettingPage> {
  String beforeCurYearTimeExample = ""; // 今年之前的年份
  String curYearTimeExample = ""; // 今年
  String todayTimeExample = ""; // 今天

  bool showModifyChecklistDialog =
      SPUtil.getBool("showModifyChecklistDialog", defaultValue: true);

  @override
  void initState() {
    super.initState();

    DateTime now = DateTime.now();
    beforeCurYearTimeExample = DateTime(2000).toString();
    // 今年要和今天或昨天区分出来，但也不能改到去年了
    DateTime tmpDT = now.add(const Duration(days: -2)); // 前天
    if (tmpDT.year != now.year) {
      // 如果前天在去年，则改为明天
      tmpDT = now.add(const Duration(days: 1));
    }
    curYearTimeExample = tmpDT.toString();
    todayTimeExample = now.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("常规设置"),
      ),
      body: CommonScaffoldBody(child: _buildBody(context)),
    );
  }

  ListView _buildBody(BuildContext context) {
    return ListView(
      children: [
        SettingCard(
          title: '偏好',
          children: [
            if (PlatformUtil.isMobile)
              ListTile(
                title: const Text("选择页面切换动画"),
                subtitle: Obx(() =>
                    Text(ThemeController.to.pageSwitchAnimation.value.title)),
                onTap: () {
                  _showDialogSelectPageSwitchAnimation(context);
                },
              ),
            ListTile(
              title: const Text('调整选项卡'),
              subtitle: const Text('启用或禁用选项卡'),
              onTap: () {
                _showDialogConfigureMainTab();
              },
            ),
            ListTile(
              title: const Text('重置移动清单对话框提示'),
              subtitle: const Text("完成最后一集时会提示移动清单"),
              onTap: () {
                SPUtil.remove("autoMoveToFinishedTag"); // 总是
                SPUtil.remove("showModifyChecklistDialog"); // 不再提示
                SPUtil.remove("selectedFinishedTag"); // 存放已完成动漫的清单
                ToastUtil.showText("重置成功");
              },
            ),
            if (PlatformUtil.isMobile)
              Obx(
                () => SwitchListTile(
                  title: const Text('隐藏底部栏文字'),
                  value: ThemeController.to.hideMobileBottomLabel.value,
                  onChanged: (value) {
                    ThemeController.to.hideMobileBottomLabel.value = value;
                    SettingsUtil.setValue(
                        SettingsEnum.hideMobileBottomLabel, value);
                  },
                ),
              ),
          ],
        ),
        SettingCard(
          title: '时间显示',
          children: [
            SwitchListTile(
              title: const Text("精确到时分"),
              subtitle: Text(TimeUtil.getHumanReadableDateTimeStr(
                  beforeCurYearTimeExample)),
              value: TimeUtil.showPreciseTime,
              onChanged: (bool value) {
                TimeUtil.turnShowPreciseTime();
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text("显示昨天/今天"),
              subtitle:
                  Text(TimeUtil.getHumanReadableDateTimeStr(todayTimeExample)),
              value: TimeUtil.showYesterdayAndToday,
              onChanged: (bool value) {
                TimeUtil.turnShowYesterdayAndToday();
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text("今年时间显示年份"),
              subtitle: Text(
                  TimeUtil.getHumanReadableDateTimeStr(curYearTimeExample)),
              value: TimeUtil.showCurYear,
              onChanged: (bool value) {
                TimeUtil.turnShowCurYear();
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showDialogConfigureMainTab() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('调整选项卡'),
        content: MainTabLayoutSettingPage(),
      ),
    );
  }

  Future<dynamic> _showDialogSelectPageSwitchAnimation(BuildContext context) {
    ThemeController themeController = Get.find();

    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            children: PageSwitchAnimation.values
                .map((e) => ListTile(
                      title: Text(e.title),
                      trailing: e == themeController.pageSwitchAnimation.value
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        themeController.pageSwitchAnimation.value = e;
                        SpProfile.savePageSwitchAnimationId(e.id);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          );
        });
  }
}
