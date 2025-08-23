import 'package:flutter/material.dart';

class CommonTitleTabBar extends StatelessWidget {
  const CommonTitleTabBar({required this.tabs, this.tabController, super.key});
  final List<Widget> tabs;
  final TabController? tabController;
  double get radius => 99;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: tabs,
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
      indicator: MaterialIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
      splashBorderRadius: BorderRadius.circular(6),
      unselectedLabelColor: Theme.of(context).hintColor,
      labelStyle: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class CommonBottomTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  final List<Widget> tabs;
  final TabController? tabController;
  final bool isScrollable;
  final Color? bgColor;
  double get radius => 99;

  const CommonBottomTabBar(
      {required this.tabs,
      this.tabController,
      this.isScrollable = false,
      this.bgColor,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 5, end: 5),
      alignment: Alignment.centerLeft,
      color: bgColor,
      child: TabBar(
        tabs: tabs,
        controller: tabController,
        // 居中，而不是靠左下
        padding: const EdgeInsets.all(2),
        // 清单可以滑动，避免拥挤
        isScrollable: isScrollable,
        tabAlignment: isScrollable ? TabAlignment.start : null,
        labelPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
        indicator: MaterialIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
        splashBorderRadius: BorderRadius.circular(6),
        unselectedLabelColor: Theme.of(context).hintColor,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MaterialIndicator extends Decoration {
  final Color color;
  final double height;

  const MaterialIndicator({
    this.color = Colors.black,
    this.height = 4,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _IndicatorPainter(color: color, height: height);
  }
}

class _IndicatorPainter extends BoxPainter {
  final Color color;
  final double height;

  _IndicatorPainter({
    VoidCallback? onChanged,
    required this.color,
    required this.height,
  }) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = Size(configuration.size?.width ?? 0, height);
    final myOffset = Offset(
      offset.dx,
      offset.dy + (configuration.size?.height ?? 0) - height,
    );
    final rect = myOffset & size;

    final paint = Paint()..color = color;
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
  }
}
