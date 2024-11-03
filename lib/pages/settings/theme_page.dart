import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:flutter_test_future/widgets/responsive.dart';
import 'package:flutter_test_future/widgets/setting_card.dart';
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
            children: [
              ListTile(
                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('选择主题色'),
                    SizedBox(width: 8),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: themeController.resetCustomPrimaryColor,
                      child: const Text('重置'),
                    ),
                    _buildColorIndicator(),
                  ],
                ),
                onTap: _showColorPicker,
              ),
              if (!Responsive.isMobile(context)) ...[
                ListTile(
                  title: const Text('主题模式'),
                  trailing: _buildThemeSelector(),
                ),
                ListTile(
                  title: const Text('夜间主题'),
                  trailing: _buildColorSelector(),
                ),
              ]
            ],
          ),
          if (Responsive.isMobile(context)) ...[
            _buildThemeMode(),
            _buildDarkTheme(),
          ]
        ],
      )),
    );
  }

  Widget _buildColorSelector() {
    return Obx(() => SegmentedButton<ThemeColor>(
          segments: [
            for (final themeColor in AppTheme.darkColors)
              ButtonSegment(
                icon: Icon(Icons.circle, color: themeColor.representativeColor),
                value: themeColor,
                label: Text(themeColor.name),
              ),
          ],
          // showSelectedIcon: false,
          emptySelectionAllowed: true,
          selected: {ThemeController.to.darkThemeColor.value},
          onSelectionChanged: (value) {
            if (value.isEmpty) return;
            final themeColor = value.first;
            ThemeController.to.changeTheme(themeColor.key, dark: true);
          },
        ));
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

  Widget _buildDarkTheme() {
    return SettingCard(
      title: '夜间主题',
      useCard: false,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, left: 16),
          child: _buildColorSelector(),
        ),
      ],
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

  Widget _buildColorIndicator() {
    return Obx(() => ColorIndicator(
        width: 24,
        height: 24,
        borderRadius: 99,
        color: _getCurPrimaryColor(),
        elevation: 1,
        onSelectFocus: false));
  }

  Color _getCurPrimaryColor() {
    return themeController.customPrimaryColor.value ??
        Theme.of(context).primaryColor;
  }
}
