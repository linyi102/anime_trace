import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final bool useUnselectedItemColor;
  final bool useSelectedItemColor;

  const SvgAssetIcon({
    super.key,
    required this.assetPath,
    this.size = 24,
    this.color,
    this.useUnselectedItemColor = false,
    this.useSelectedItemColor = false,
  });

  @override
  Widget build(BuildContext context) {
    var destColor = color ??
        Theme.of(context).iconTheme.color ??
        Theme.of(context).colorScheme.primary;

    if (useUnselectedItemColor) {
      destColor =
          Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ??
              destColor;
    }

    if (useSelectedItemColor) {
      destColor =
          Theme.of(context).bottomNavigationBarTheme.selectedItemColor ??
              destColor;
    }

    return SvgPicture.asset(
      assetPath,
      height: size,
      width: size,
      // 夜间模式若不指定colorFilter，则看不清图标，因此color默认是iconTheme中的color
      colorFilter: ColorFilter.mode(destColor, BlendMode.srcIn),
    );
  }
}
