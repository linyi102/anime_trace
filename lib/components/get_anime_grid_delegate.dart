import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../controllers/anime_display_controller.dart';

SliverGridDelegate getAnimeGridDelegate(BuildContext context) {
  final AnimeDisplayController _animeDisplayController = Get.find();
  bool enableResponsive =
      _animeDisplayController.enableResponsiveGridColumnCnt.value;
  int gridColumnCnt = _animeDisplayController.gridColumnCnt.value;

  double childAspectRatio;
  bool showProgressBar = _animeDisplayController.showProgressBar.value;
  // 宽高比，三种情况：名字(2行)在封面下面，名字(1行)在封面下面，名字在封面内底部。高不断缩小
  if (_animeDisplayController.showNameBelowCover) {
    if (_animeDisplayController.nameMaxLines.value == 2) {
      childAspectRatio = showProgressBar ? 31 / 56 : 31 / 53;
    } else {
      childAspectRatio = showProgressBar ? 31 / 53 : 31 / 50;
    }
  } else {
    childAspectRatio = showProgressBar ? 31 / 46 : 31 / 43;
  }

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
      // 每个网格的比例
      childAspectRatio: childAspectRatio,
    );
  } else {
    return SliverGridDelegateWithFixedCrossAxisCount(
      // 横轴数量
      crossAxisCount: gridColumnCnt,
      // 横轴距离
      crossAxisSpacing: 3,
      // 竖轴距离
      mainAxisSpacing: 6,
      // 每个网格的比例
      childAspectRatio: childAspectRatio,
    );
  }
}
