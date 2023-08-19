import 'package:flutter/material.dart';

// class IconTextButton extends StatelessWidget {
//   const IconTextButton(
//       {super.key,
//       required this.icon,
//       required this.text,
//       this.onTap,
//       this.height = 80,
//       this.width = 80,
//       this.iconSize = 30});

//   final Widget icon;
//   final Widget text;
//   final void Function()? onTap;
//   final double height;
//   final double width;
//   final double iconSize;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(6),
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: SizedBox(
//             width: width,
//             height: height,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(height: iconSize, width: iconSize, child: icon),
//                 const SizedBox(height: 5),
//                 text
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
