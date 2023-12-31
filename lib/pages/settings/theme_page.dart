import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/pages/main_screen/logic.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:flutter_test_future/widgets/setting_card.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("外观设置")),
      body: CommonScaffoldBody(
          child: ListView(
        children: [
          SettingCard(
            title: '选项卡',
            children: [
              ListTile(
                title: const Text('调整选项卡'),
                subtitle: const Text('启用或禁用选项卡'),
                onTap: () {
                  _showDialogConfigureMainTab();
                },
              ),
            ],
          ),
          SettingCard(
            title: '配色',
            children: [
              ListTile(
                title: const Text('选择主题色'),
                trailing: Obx(() => _buildColorIndicator()),
                onTap: _showColorPicker,
              ),
              ListTile(
                title: const Text('重置'),
                onTap: () {
                  themeController.resetCustomPrimaryColor();
                },
              ),
            ],
          ),
          SettingCard(
            title: '夜间模式',
            children: [
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
            ],
          ),
          SettingCard(
            title: '夜间主题',
            children: [
              Obx(() => _buildColorAtlasList()),
            ],
          ),
        ],
      )),
    );
  }

  Future<void> _showColorPicker() async {
    final Color newColor = await showColorPickerDialog(
      context,
      _getCurPrimaryColor(),
      title: Text('ColorPicker', style: Theme.of(context).textTheme.titleLarge),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 0,
      wheelDiameter: 165,
      enableOpacity: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: <ColorPickerType, bool>{
        ColorPickerType.wheel: true,
      },
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
      ),
      actionButtons: const ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: false,
      ),
      constraints:
          const BoxConstraints(minHeight: 480, minWidth: 320, maxWidth: 320),
    );
    themeController.changeCustomPrimaryColor(newColor);
  }

  ColorIndicator _buildColorIndicator() {
    return ColorIndicator(
        width: 32,
        height: 32,
        borderRadius: 12,
        color: _getCurPrimaryColor(),
        elevation: 1,
        onSelectFocus: false);
  }

  _getCurPrimaryColor() {
    return themeController.customPrimaryColor.value ??
        Theme.of(context).primaryColor;
  }

  _showDialogConfigureMainTab() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('调整选项卡'),
        content: MainTabLayoutSettingPage(),
      ),
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

class MainTabLayoutSettingPage extends StatefulWidget {
  const MainTabLayoutSettingPage({super.key});

  @override
  State<MainTabLayoutSettingPage> createState() =>
      _MainTabLayoutSettingPageState();
}

class _MainTabLayoutSettingPageState extends State<MainTabLayoutSettingPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: MainScreenLogic.to.allTabs
            .map((tab) => ListTile(
                  iconColor: Theme.of(context).iconTheme.color,
                  leading: tab.icon,
                  title: _buildTitle(tab, context),
                  dense: true,
                  trailing: tab.canHide ? _buildTurnShowIcon(tab) : null,
                ))
            .toList(),
      ),
    );
  }

  IconButton _buildTurnShowIcon(MainTab tab) {
    return IconButton(
      icon: Icon(tab.show ? Icons.remove : Icons.add_circle_outline),
      onPressed: () async {
        bool? show = tab.turnShow?.call();
        if (show == null) return;

        tab.show = show;
        MainScreenLogic.to.loadTabs();
        setState(() {});
      },
    );
  }

  Text _buildTitle(MainTab tab, BuildContext context) {
    return Text(
      tab.name,
      style: tab.show
          ? null
          : TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Theme.of(context).hintColor,
            ),
    );
  }
}
