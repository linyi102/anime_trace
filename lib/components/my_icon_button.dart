import 'package:flutter/material.dart';

/// 用于代替IconButton
/// 缺点：不能代替PopupMenuButton，以及appbar自带的返回按钮也要重写
class MyIconButton extends StatelessWidget {
  const MyIconButton(
      {this.onPressed, required this.icon, this.tooltip, super.key});
  final void Function()? onPressed; // 不命名为onTap是为了方便直接把IconButton改为MyIconButton
  final Widget icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onPressed, icon: icon);

    // 悬浮操作栏高度不受限制，解决方法SizedBox指定高度
    // return SizedBox(
    //   height: 40,
    //   // AppBar-actions处为椭圆而不是圆形，解决方法：Column
    //   child: Column(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       InkWell(
    //         borderRadius: BorderRadius.circular(50),
    //         onTap: onPressed,
    //         child: Container(
    //           padding: const EdgeInsets.all(8),
    //           child: tooltip == null
    //               ? icon
    //               : Tooltip(message: tooltip, child: icon),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}
