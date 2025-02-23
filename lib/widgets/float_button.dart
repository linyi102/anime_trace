import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/extensions/color.dart';

class FloatButton extends StatelessWidget {
  const FloatButton({this.icon, this.onTap, this.active = false, Key? key})
      : super(key: key);
  final IconData? icon;
  final void Function()? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withOpacityFactor(0.4)
              : Colors.black.withOpacityFactor(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
