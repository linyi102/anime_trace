import 'package:flutter/material.dart';

class SettingTitle extends StatelessWidget {
  const SettingTitle({
    super.key,
    required this.title,
    this.trailing,
  });
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Theme.of(context).textTheme.titleLarge
    var titleStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

    return ListTile(
      title: Text(title, style: titleStyle),
      trailing: trailing,
    );
  }
}
