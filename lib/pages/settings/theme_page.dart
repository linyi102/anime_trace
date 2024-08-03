import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/pages/main_screen/logic.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:flutter_test_future/widgets/setting_card.dart';

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
            title: '主题配色',
            trailing: TextButton(
                onPressed: () {
                  themeController.resetCustomPrimaryColor();
                },
                child: const Text('重置')),
            children: [
              ListTile(
                title: const Text('选择主题色'),
                trailing: _buildColorIndicator(),
                onTap: _showColorPicker,
              ),
            ],
          ),
          _buildThemeMode(),
          _buildDarkTheme(),
        ],
      )),
    );
  }

  SettingCard _buildThemeMode() {
    return SettingCard(
      title: '主题模式',
      useCard: false,
      children: [
        _buildRadioGrid(
          children: [
            for (int i = 0; i < AppTheme.darkModes.length; ++i)
              _buildThemeModeItem(context, i)
          ],
        )
      ],
    );
  }

  Widget _buildThemeModeItem(BuildContext context, int themeModeIndex) {
    final selected = ThemeController.to.themeModeIdx.value == themeModeIndex;
    final fg = selected ? Theme.of(context).primaryColor : null;

    return _buildRadioItem(
      icon: Icon(AppTheme.darkModeIcons[themeModeIndex], color: fg),
      label: AppTheme.darkModes[themeModeIndex],
      selected: ThemeController.to.themeModeIdx.value == themeModeIndex,
      onTap: () {
        setState(() {
          ThemeController.to.themeModeIdx.value = themeModeIndex;
        });
        ThemeController.to.setThemeMode(themeModeIndex);
      },
    );
  }

  Future<void> _showColorPicker() async {
    final Color newColor = await showColorPickerDialog(
      context,
      _getCurPrimaryColor(),
      title: Text('主题色', style: Theme.of(context).textTheme.titleLarge),
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
        okButton: false,
        closeButton: false,
        dialogActionButtons: true,
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
        borderRadius: 99,
        color: _getCurPrimaryColor(),
        elevation: 1,
        onSelectFocus: false);
  }

  Color _getCurPrimaryColor() {
    return themeController.customPrimaryColor.value ??
        Theme.of(context).primaryColor;
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

  Widget _buildDarkTheme() {
    return SettingCard(title: '夜间主题', useCard: false, children: [
      _buildRadioGrid(
        children: [
          for (int i = 0; i < AppTheme.darkColors.length; ++i)
            _buildColorAtlasItem(AppTheme.darkColors[i], dark: true)
        ],
      ),
    ]);
  }

  Widget _buildColorAtlasItem(ThemeColor themeColor, {bool dark = false}) {
    final selectedThemeColor = dark
        ? ThemeController.to.darkThemeColor.value
        : ThemeController.to.lightThemeColor.value;

    return _buildRadioItem(
      icon: Icon(Icons.circle, color: themeColor.representativeColor),
      label: themeColor.name,
      selected: selectedThemeColor == themeColor,
      onTap: () {
        ThemeController.to.changeTheme(themeColor.key, dark: dark);
      },
    );
  }

  Widget _buildRadioGrid({required List<Widget> children}) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 5),
      child: GridView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          mainAxisExtent: 100,
          maxCrossAxisExtent: MediaQuery.of(context).size.width / 3,
        ),
        children: children,
      ),
    );
  }

  Widget _buildRadioItem({
    Widget? icon,
    String? label,
    void Function()? onTap,
    bool selected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected
              ? Theme.of(context).primaryColor
              : Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) icon,
              const SizedBox(height: 5),
              Text(
                label ?? '',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? Theme.of(context).primaryColor : null),
              ),
            ],
          ),
        ),
      ),
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
