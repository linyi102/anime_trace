import 'package:flutter/material.dart';
import 'package:animetrace/pages/main_screen/logic.dart';

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
