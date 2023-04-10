import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  int themeModeIdx = ThemeController.to.themeModeIdx.value;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("主题样式")),
      body: ListView(
        children: [
          _buildTileSelectDarkMode(context),
          Obx(() => _buildColorAtlasList()),
        ],
      ),
    );
  }

  ListTile _buildTileSelectDarkMode(BuildContext context) {
    return ListTile(
      title: const Text("深色模式"),
      subtitle: Text(AppTheme.darkModes[themeModeIdx]),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text("深色模式"),
            children: [
              for (int i = 0; i < AppTheme.darkModes.length; ++i)
                RadioListTile(
                  title: Text(AppTheme.darkModes[i]),
                  value: i,
                  groupValue: themeModeIdx,
                  onChanged: (value) {
                    if (value == null) return;

                    Navigator.pop(context);
                    setState(() {
                      themeModeIdx = value as int;
                    });

                    ThemeController.to.setThemeMode(i);
                  },
                )
            ],
          ),
        );
      },
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

    return ListTile(
      trailing: curThemeColor == themeColor ? const Icon(Icons.check) : null,
      leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: themeColor.representativeColor,
            // border: Border.all(width: 2, color: Colors.red.shade200),
          )),
      title: Text(themeColor.name),
      onTap: () {
        ThemeController.to.changeTheme(themeColor.key, dark: dark);
      },
    );
  }
}
