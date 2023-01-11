import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

/// 加载对话框
/// 来源：https://blog.csdn.net/johnWcheung/article/details/89634582
class LoadingDialog extends Dialog {
  const LoadingDialog(this.text, {Key? key}) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SizedBox(
          height: 110,
          width: 140,
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator()),
                const SizedBox(height: 20),
                Text(text, style: TextStyle(color: ThemeUtil.getFontColor()))
              ],
            ),
            decoration: ShapeDecoration(
                color:ThemeUtil.getCardColor(),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ),
      ),
    );
  }
}
