import 'package:flutter/cupertino.dart';

enum ResponsiveWidthSource {
  mediaQuery,
  constraints,
}

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final ResponsiveWidthSource responsiveWidthSource;

  const Responsive({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.responsiveWidthSource = ResponsiveWidthSource.mediaQuery,
  }) : super(key: key);

  static get _mobileMaxWidth => 600;
  static get _tabletMaxWidth => 850;

  // 获取平台，用于显示或隐藏某些组件
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= _mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      600 <= MediaQuery.of(context).size.width &&
      MediaQuery.of(context).size.width <= _tabletMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > _tabletMaxWidth;

  // 根据不同的平台，为组件传入不同的比例
  @override
  Widget build(BuildContext context) {
    switch (responsiveWidthSource) {
      case ResponsiveWidthSource.mediaQuery:
        return _buildByMediaQuery(context);
      case ResponsiveWidthSource.constraints:
        return _buildByConstraints();
      default:
        return _buildByMediaQuery(context);
    }
  }

  _buildByConstraints() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width > _tabletMaxWidth) {
          return desktop;
        } else if (width > _mobileMaxWidth) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }

  _buildByMediaQuery(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    if (_size.width > _tabletMaxWidth) {
      return desktop;
    } else if (_size.width > _mobileMaxWidth) {
      return tablet ?? desktop;
    } else {
      return mobile;
    }
  }
}
