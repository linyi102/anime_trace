import 'package:flutter/material.dart';

class SingleSegmentButton extends StatefulWidget {
  const SingleSegmentButton({
    super.key,
    required this.titles,
    this.initialIdx = 0,
    this.onSelected,
    this.border,
    this.radius,
    this.margin,
  });

  final List<String> titles;
  final void Function(int index)? onSelected;
  final int initialIdx;

  final double? radius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? margin;

  @override
  State<SingleSegmentButton> createState() => _SingleSegmentButtonState();
}

class _SingleSegmentButtonState extends State<SingleSegmentButton> {
  late double radius;
  late int selectedIdx;

  @override
  void initState() {
    super.initState();
    radius = widget.radius ?? 99;
    selectedIdx = widget.initialIdx;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: widget.border ?? Border.all(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.titles.length; ++i) _buildItem(i)
        ],
      ),
    );
  }

  _buildItem(int index) {
    // 第一个只有左上角和左下角添加圆角，最后一个则是右上角和右下角
    var leftRadius = Radius.zero, rightRadius = Radius.zero;
    if (index == 0) {
      leftRadius = Radius.circular(radius);
    } else if (index == widget.titles.length - 1) {
      rightRadius = Radius.circular(radius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: leftRadius,
        bottomLeft: leftRadius,
        topRight: rightRadius,
        bottomRight: rightRadius,
      ),
      child: InkWell(
        borderRadius: BorderRadius.only(
          topLeft: leftRadius,
          bottomLeft: leftRadius,
          topRight: rightRadius,
          bottomRight: rightRadius,
        ),
        onTap: () {
          setState(() {
            selectedIdx = index;
          });
          widget.onSelected?.call(index);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              Container(
                  width: 1, height: 10, color: Theme.of(context).dividerColor),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
              color:
                  selectedIdx == index ? Theme.of(context).colorScheme.primary : null,
              child: Text(
                widget.titles[index],
                style: TextStyle(
                  color: selectedIdx == index ? Colors.white : null,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
