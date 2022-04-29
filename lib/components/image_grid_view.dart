import 'package:flutter/material.dart';

showImageGridView(
    int itemCount, Widget Function(BuildContext, int) itemBuilder) {
  if (itemCount == 0) return Container();
  return GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      shrinkWrap: true, // ListView嵌套GridView
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: itemCount == 2 ? 2 : 3, // 横轴数量
        crossAxisSpacing: 5, // 横轴距离
        mainAxisSpacing: 5, // 竖轴距离
        childAspectRatio: 1, // 网格比例。31/43为封面比例
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder);
}
