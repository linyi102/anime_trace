import 'package:flutter/material.dart';

class OperationButton extends StatelessWidget {
  const OperationButton(
      {required this.text,
      this.onTap,
      this.active = true,
      this.horizontal = 30,
      this.height = 65,
      this.fontSize,
      super.key});
  final void Function()? onTap;
  final String text;
  final bool active;
  final double horizontal;
  final double height;
  final double? fontSize;

  get borderRadius => BorderRadius.circular(50);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AspectRatio(
        aspectRatio: 6,
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: horizontal, vertical: 10),
            child: Material(
              borderRadius: borderRadius,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor.withOpacity(0.2),
              child: InkWell(
                  borderRadius: borderRadius,
                  onTap: onTap,
                  child: Center(
                      child: Text(text,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: active
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          )))),
            )),
      ),
    );
  }
}
