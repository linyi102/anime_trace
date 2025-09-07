import 'package:flutter/material.dart';
import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/values/values.dart';

class CommonCover extends StatefulWidget {
  const CommonCover({
    super.key,
    this.onTap,
    this.width = 100,
    this.coverUrl,
    this.title,
    this.subtitle,
    this.bottomRightText,
  });

  final GestureTapCallback? onTap;
  final double? width;
  final String? coverUrl;
  final String? title;
  final String? subtitle;
  final String? bottomRightText;

  @override
  State<CommonCover> createState() => _CommonCoverState();
}

class _CommonCoverState extends State<CommonCover> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.imgRadius),
        onTap: widget.onTap,
        child: _buildItem(),
      ),
    );
  }

  Widget _buildItem() {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.coverUrl != null) _buildImage(),
                if (widget.bottomRightText != null) _buildBottomShadow(),
                if (widget.bottomRightText != null) _buildBottomRightText()
              ],
            ),
          ),
          const SizedBox(height: 5),
          if (widget.title != null)
            Text(
              widget.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          if (widget.subtitle != null)
            Text(
              widget.subtitle ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
        ],
      ),
    );
  }

  ClipRRect _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.imgRadius),
      child: CommonImage(
        widget.coverUrl!,
        reduceMemCache: true,
      ),
    );
  }

  Container _buildBottomRightText() {
    return Container(
      // 使用Align替换Positioned，可以保证在Stack下自适应父元素宽度
      alignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
        child: Text(
          widget.bottomRightText ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(blurRadius: 3, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildBottomShadow() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.imgRadius)),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.6),
                  ])),
        ),
      ],
    );
  }
}
