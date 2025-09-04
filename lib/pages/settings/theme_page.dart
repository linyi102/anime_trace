import 'package:animetrace/widgets/connected_button_groups.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
            children: [
              ListTile(
                title: const Text('选择主题色'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: themeController.resetPrimaryColor,
                      child: const Text('重置'),
                    ),
                    _buildColorIndicator(),
                  ],
                ),
                onTap: _showColorPicker,
              ),
              ListTile(
                title: const Text('选择配色方案'),
                trailing: Obx(() => Text(
                      themeController.dynamicSchemeVariant.value.displayName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('选择配色方案'),
                      children: DynamicSchemeVariant.values
                          .map(
                            (e) => RadioListTile<DynamicSchemeVariant>(
                              title: Text(e.displayName),
                              value: e,
                              groupValue:
                                  themeController.dynamicSchemeVariant.value,
                              onChanged: (value) {
                                if (value != null) {
                                  themeController
                                      .setDynamicSchemeVariant(value);
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ],
          ),
          _buildThemeMode(),
        ],
      )),
    );
  }

  Widget _buildThemeSelector() {
    return Obx(() => ConnectedButtonGroups<int>(
          items: [
            for (int i = 0; i < AppTheme.darkModes.length; i++)
              ConnectedButtonItem(
                icon: Icon(AppTheme.darkModeIcons[i]),
                label: AppTheme.darkModes[i],
                value: i,
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: _buildThemeSelector(),
        ),
      ],
    );
  }

  Future<void> _showColorPicker() async {
    final Color newColor = await showColorPickerDialog(
      context,
      themeController.primaryColor.value,
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
    themeController.changePrimaryColor(newColor);
  }

  Widget _buildColorIndicator() {
    return Obx(() => ColorIndicator(
        width: 24,
        height: 24,
        borderRadius: 99,
        color: themeController.primaryColor.value,
        elevation: 1,
        onSelectFocus: false));
  }
}
