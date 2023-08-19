import 'package:flutter/material.dart';

class IconTextButton extends StatelessWidget {
  const IconTextButton({
    // 为icon指定图标
    this.iconData,
    this.iconColor,
    this.iconSize = 20,
    // icon自定义widget
    this.icon,
    required this.text,
    this.onTap,
    this.direction = Axis.vertical,
    this.padding = const EdgeInsets.all(8.0),
    this.margin = const EdgeInsets.all(4.0),
    this.radius = 6,
    Key? key,
  }) : super(key: key);

  final void Function()? onTap;
  final IconData? iconData;
  final double iconSize;
  final Color? iconColor;
  final Widget? icon;
  final Widget text;
  final Axis direction;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return _buildHorizontalView();
    }

    return _buildVerticalView();
  }

  _buildVerticalView() {
    return Container(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          child: Column(
            children: [
              _buildIcon(),
              const SizedBox(height: 5),
              text,
            ],
          ),
        ),
      ),
    );
  }

  _buildHorizontalView() {
    return Container(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 5),
              text,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return iconData == null
        ? icon ?? const SizedBox.shrink()
        : Icon(iconData, color: iconColor, size: iconSize);
  }
}
