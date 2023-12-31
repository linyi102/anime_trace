import 'package:flutter/material.dart';

class SettingCard extends StatelessWidget {
  const SettingCard({required this.title, this.children = const [], super.key});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingTitle(title: title),
        Card(child: Column(children: children))
      ],
    );
  }
}

class _SettingTitle extends StatelessWidget {
  const _SettingTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
      ),
    );
  }
}
