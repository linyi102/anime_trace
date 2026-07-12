/// 修改自 https://pub.dev/packages/dynamic_height_grid_view
///
/// 改动处：
/// - [DynamicHeightGridView] 添加 padding 属性
import 'package:flutter/material.dart';

/// GridView with dynamic height
///
/// Usage is almost same as [GridView.count]
class DynamicHeightGridView extends StatelessWidget {
  const DynamicHeightGridView({
    Key? key,
    required this.builder,
    required this.itemCount,
    required this.crossAxisCount,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.rowCrossAxisAlignment = CrossAxisAlignment.start,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  }) : super(key: key);
  final IndexedWidgetBuilder builder;
  final int itemCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final CrossAxisAlignment rowCrossAxisAlignment;

  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  int columnLength() {
    if (itemCount % crossAxisCount == 0) {
      return itemCount ~/ crossAxisCount;
    } else {
      return (itemCount ~/ crossAxisCount) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (ctx, columnIndex) {
        return _GridRow(
          columnIndex: columnIndex,
          builder: builder,
          itemCount: itemCount,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisAlignment: rowCrossAxisAlignment,
        );
      },
      itemCount: columnLength(),
    );
  }
}

/// Use this for [CustomScrollView]
class SliverDynamicHeightGridView extends StatelessWidget {
  const SliverDynamicHeightGridView({
    Key? key,
    required this.builder,
    required this.itemCount,
    required this.crossAxisCount,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.rowCrossAxisAlignment = CrossAxisAlignment.start,
    this.controller,
  }) : super(key: key);
  final IndexedWidgetBuilder builder;
  final int itemCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final ScrollController? controller;

  int columnLength() {
    if (itemCount % crossAxisCount == 0) {
      return itemCount ~/ crossAxisCount;
    } else {
      return (itemCount ~/ crossAxisCount) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, columnIndex) {
          return _GridRow(
            columnIndex: columnIndex,
            builder: builder,
            itemCount: itemCount,
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisAlignment: rowCrossAxisAlignment,
          );
        },
        childCount: columnLength(),
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    Key? key,
    required this.columnIndex,
    required this.builder,
    required this.itemCount,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.crossAxisAlignment,
  }) : super(key: key);
  final IndexedWidgetBuilder builder;
  final int itemCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final CrossAxisAlignment crossAxisAlignment;
  final int columnIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: (columnIndex == 0) ? 0 : mainAxisSpacing,
      ),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: List.generate(
          (crossAxisCount * 2) - 1,
          (rowIndex) {
            final rowNum = rowIndex + 1;
            if (rowNum % 2 == 0) {
              return SizedBox(width: crossAxisSpacing);
            }
            final rowItemIndex = ((rowNum + 1) ~/ 2) - 1;
            final itemIndex = (columnIndex * crossAxisCount) + rowItemIndex;
            if (itemIndex > itemCount - 1) {
              return const Expanded(child: SizedBox());
            }
            return Expanded(
              child: builder(context, itemIndex),
            );
          },
        ),
      ),
    );
  }
}
