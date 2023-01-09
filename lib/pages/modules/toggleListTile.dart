import 'package:flutter/material.dart';

import '../../utils/theme_util.dart';

class ToggleListTile extends StatelessWidget {
  const ToggleListTile(
      {this.title, this.subtitle, this.toggleOn = false, this.onTap, Key? key})
      : super(key: key);
  final Widget? title;
  final Widget? subtitle;
  final bool toggleOn;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: toggleOn
          ? Icon(Icons.toggle_on, color: ThemeUtil.getPrimaryIconColor())
          : const Icon(Icons.toggle_off),
      onTap: onTap,
    );
  }
}
