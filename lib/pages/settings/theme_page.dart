import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:flutter_test_future/widgets/setting_title.dart';
import 'package:get/get.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  int themeModeIdx = ThemeController.to.themeModeIdx.value;
  ThemeController get themeController => ThemeController.to;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("外观设置")),
      body: CommonScaffoldBody(
          child: ListView(
        children: [
          const SettingTitle(title: '夜间模式'),
          // _buildTileSelectDarkMode(context),
          for (int i = 0; i < AppTheme.darkModes.length; ++i)
            RadioListTile(
              title: Text(AppTheme.darkModes[i]),
              controlAffinity: ListTileControlAffinity.trailing,
              value: i,
              groupValue: themeModeIdx,
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  themeModeIdx = value;
                });

                ThemeController.to.setThemeMode(i);
              },
            ),
          const CommonDivider(),
          const SettingTitle(title: '夜间主题'),

          Obx(() => _buildColorAtlasList()),
        ],
      )),
    );
  }

  _buildColorAtlasList() {
    List<Widget> list = [];
    // list.add(const ListTile(dense: true, title: Text("白天模式")));
    // list.addAll(AppTheme.lightColors.map((e) => _buildColorAtlasItem(e)));
    // list.add(const ListTile(dense: true, title: Text("夜间模式")));
    list.addAll(
        AppTheme.darkColors.map((e) => _buildColorAtlasItem(e, dark: true)));

    return Column(
      children: list,
    );
  }

  _buildColorAtlasItem(ThemeColor themeColor, {bool dark = false}) {
    var curThemeColor = dark
        ? ThemeController.to.darkThemeColor.value
        : ThemeController.to.lightThemeColor.value;

    return RadioListTile(
      title: Text(themeColor.name),
      controlAffinity: ListTileControlAffinity.trailing,
      value: themeColor,
      groupValue: curThemeColor,
      onChanged: (value) {
        if (value == null) return;
        ThemeController.to.changeTheme(value.key, dark: dark);
      },
    );
  }
}
