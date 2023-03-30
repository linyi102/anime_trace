import 'package:flutter/material.dart';

showCommonBottomSheet({
  required BuildContext context,
  required Widget child,
  Widget? title,
  bool centerTitle = false,
  bool expanded = false, // child为ListView时需要置为true。为true时高度为半屏，无法自适应
  List<Widget>? actions,
}) {
  // 自带的底部菜单
  showModalBottomSheet(
    // isScrollControlled为true，且builder为Scaffold时会全屏
    // isScrollControlled为false(默认)，且builder为column时为半屏(指定mainAxisSize: MainAxisSize.min则会自适应)，如果column外套SingleChildScrollView则会自适应高度
    // 或者用ListView(shrinkWrap: true, ...)代替SingleChildScrollView(child: Column(...))
    // isScrollControlled: true,
    context: context,
    // 左上和右上圆角
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
    ),
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          title != null
              ? AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  title: title,
                  centerTitle: centerTitle,
                  actions: actions,
                )
              : const SizedBox(height: 20),
          expanded ? Expanded(child: child) : child,
        ],
      );
    },
  );
}
