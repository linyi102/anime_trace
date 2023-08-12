import 'package:flutter/material.dart';

class IconTextButton extends StatelessWidget {
  const IconTextButton(
      {super.key,
      required this.icon,
      required this.text,
      this.onTap,
      this.height = 80,
      this.width = 80,
      this.iconSize = 30});

  final Widget icon;
  final Widget text;
  final void Function()? onTap;
  final double height;
  final double width;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: width,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: iconSize, width: iconSize, child: icon),
                const SizedBox(height: 5),
                text
              ],
            ),
          ),
        ),
      ),
    );
  }
}
