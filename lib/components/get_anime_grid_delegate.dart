import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../controllers/anime_display_controller.dart';

SliverGridDelegate getAnimeGridDelegate(BuildContext context) {
  final AnimeDisplayController _animeDisplayController = Get.find();
  bool enableResponsive =
      _animeDisplayController.enableResponsiveGridColumnCnt.value;
  int gridColumnCnt = _animeDisplayController.gridColumnCnt.value;

  // Size size = MediaQuery.of(context).size;
  if (enableResponsive) {
    // if (Responsive.isMobile(context)) {
    //   gridColumnCnt = 4;
    //   if (size.width < 500) gridColumnCnt = 3;
    // } else if (Responsive.isTablet(context)) {
    //   gridColumnCnt = 5;
    // } else if (Responsive.isDesktop(context)) {
    //   gridColumnCnt = 6;
    //   if (size.width > 1100) gridColumnCnt = 7;
    // }
    // 改用这个来指定item最大宽度，从而实现自适应
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 150,
      // 横轴距离
      crossAxisSpacing: 3,
      // 竖轴距离
      mainAxisSpacing: 6,
      // 每个网格的比例(如果不显示名字或名字显示在封面内部，则使用31/45，否则31/56)
      childAspectRatio:
          _animeDisplayController.showNameBelowCover ? 31 / 56 : 31 / 43,
    );
  } else {
    return SliverGridDelegateWithFixedCrossAxisCount(
      // 横轴数量
      crossAxisCount: gridColumnCnt,
      // 横轴距离
      crossAxisSpacing: 3,
      // 竖轴距离
      mainAxisSpacing: 6,
      // 每个网格的比例(如果不显示名字或名字显示在封面内部，则使用31/45，否则31/56)
      childAspectRatio:
          _animeDisplayController.showNameBelowCover ? 31 / 56 : 31 / 43,
    );
  }
}
