import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

class OperationButton extends StatelessWidget {
  const OperationButton(
      {required this.text, this.onTap, this.active = true, super.key});
  final void Function()? onTap;
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    var borderRadius = BorderRadius.circular(50);

    return SizedBox(
      height: 60,
      child: AspectRatio(
        aspectRatio: 6,
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? ThemeUtil.getPrimaryColor()
                  : ThemeUtil.getInActiveButtonBgColor(),
              borderRadius: borderRadius,
            ),
            child: InkWell(
                borderRadius: borderRadius,
                onTap: onTap,
                child: Center(
                    child: Text(
                  text,
                  style: TextStyle(
                      color: active
                          ? Colors.white
                          : ThemeUtil.getInActiveButtonFgColor()),
                )))),
      ),
    );
  }
}
