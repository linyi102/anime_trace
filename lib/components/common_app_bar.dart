import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const CommonAppBar({this.caption, this.title, super.key});

  final String? caption; // 如果指定了caption，则文字显示
  final Widget? title; // 否则显示指定的title

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: caption != null
          ? Text(caption!, style: const TextStyle(fontWeight: FontWeight.w600))
          : title,
    );
  }
}
