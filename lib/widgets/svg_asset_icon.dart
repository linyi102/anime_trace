import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;

  const SvgAssetIcon({
    super.key,
    required this.assetPath,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      height: size,
      width: size,
      // 夜间模式若不指定colorFilter，则看不清图标，因此color默认是iconTheme中的color
      colorFilter: ColorFilter.mode(
          color ??
              Theme.of(context).iconTheme.color ??
              Theme.of(context).primaryColor,
          BlendMode.srcIn),
    );
  }
}
