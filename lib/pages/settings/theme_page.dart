import 'package:flutter/material.dart';
import 'package:animetrace/controllers/theme_controller.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:animetrace/widgets/setting_card.dart';
import 'package:get/get.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  ThemeController get themeController => ThemeController.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("外观设置")),
      body: CommonScaffoldBody(
          child: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingCard(
            title: '主题',
            children: [_buildThemeSelector()],
          ),
        ],
      )),
    );
  }

  Widget _buildThemeSelector() {
    return Obx(() => SegmentedButton<int>(
          segments: [
            for (int i = 0; i < AppTheme.darkModes.length; i++)
              ButtonSegment(
                icon: Icon(AppTheme.darkModeIcons[i]),
                value: i,
                label: Text(AppTheme.darkModes[i]),
              ),
          ],
          // showSelectedIcon: false,
          emptySelectionAllowed: true,
          selected: {ThemeController.to.themeModeIdx.value},
          onSelectionChanged: (value) {
            if (value.isEmpty) return;
            final selectedIndex = value.first;
            ThemeController.to.setThemeMode(selectedIndex);
          },
        ));
  }

  SettingCard _buildThemeMode() {
    return SettingCard(
      title: '主题模式',
      useCard: false,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, left: 16),
          child: _buildThemeSelector(),
        ),
      ],
    );
  }
}
