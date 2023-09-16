import 'package:flutter/material.dart';

class SettingTitle extends StatelessWidget {
  const SettingTitle({
    super.key,
    required this.title,
    this.subtitle = '',
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Theme.of(context).textTheme.titleLarge
    var titleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

    return ListTile(
      title: Text(title, style: titleStyle),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: trailing,
    );
  }
}
