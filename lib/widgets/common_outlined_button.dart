import 'package:flutter/material.dart';

class CommonOutlinedButton extends StatelessWidget {
  const CommonOutlinedButton({
    super.key,
    this.onTap,
    required this.text,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
  });

  final void Function()? onTap;
  final String text;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).primaryColor;
    if (onTap == null) color = Theme.of(context).disabledColor;

    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, color: color),
        ),
      ),
    );
  }
}
