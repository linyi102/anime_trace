import 'package:flutter/material.dart';

/// 配合showFlexibleBottomSheet的builder使用
/// 为底部面板添加顶部圆角效果
class RoundedSheet extends StatelessWidget {
  const RoundedSheet(
      {required this.body,
      this.title,
      this.centerTitle = false,
      this.radius,
      super.key});
  final Widget body;
  final Widget? title;
  final bool centerTitle;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius ?? 10),
                topRight: Radius.circular(radius ?? 10)),
          ),
        ),
        Column(
          children: [
            if (title != null)
              AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                title: title,
                centerTitle: centerTitle,
              ),
            Expanded(child: body)
          ],
        )
      ],
    );
  }
}
