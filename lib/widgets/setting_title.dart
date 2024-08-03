import 'package:flutter/material.dart';

class SettingTitle extends StatelessWidget {
  const SettingTitle({
    super.key,
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.titleStyle,
  });
  final String title;
  final TextStyle? titleStyle;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: titleStyle ??
            Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: trailing,
      iconColor: Theme.of(context).iconTheme.color,
    );
  }
}
