import 'package:flutter/material.dart';

/// 加载对话框
class LoadingDialog extends Dialog {
  const LoadingDialog(
    this.msg, {
    Key? key,
    this.simple = false,
    this.direction = Axis.vertical,
  }) : super(key: key);
  final bool simple;
  final String msg;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    var bg = Theme.of(context).dialogBackgroundColor;
    Color? fg;

    return Container(
      // 避免消息长度过长时紧挨屏幕边界
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      // 大小由消息长度决定
      padding:
          EdgeInsets.symmetric(horizontal: 30, vertical: msg.isEmpty ? 24 : 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Flex(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        direction: direction,
        children: [
          CircularProgressIndicator(
            color: fg,
            strokeWidth: 4,
          ),
          if (msg.isNotEmpty)
            SizedBox(
              height: direction == Axis.horizontal ? 0 : 12,
              width: direction == Axis.horizontal ? 20 : 0,
            ),
          // 若采用Expanded，可以避免横向布局时文字过长溢出，但会导致背景拉长
          if (msg.isNotEmpty)
            Text(msg, style: TextStyle(color: fg, fontSize: 14)),
        ],
      ),
    );
  }
}
