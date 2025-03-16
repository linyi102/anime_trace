import 'package:flutter/material.dart';
import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/multi_platform.dart';
import 'package:animetrace/widgets/responsive.dart';

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
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Responsive(
        mobile: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildMultiPlatform(),
        ),
        desktop: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildMultiPlatform(),
        ));
  }

  MultiPlatform _buildMultiPlatform() {
    return MultiPlatform(
      mobile: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _zoomInCover(),
        onTapUp: (_) => _zoomOutCover(),
        onTapCancel: () => _zoomOutCover(),
        child: _buildItem(),
      ),
      desktop: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (_) => _zoomInCover(),
          onExit: (_) => _zoomOutCover(),
          child: _buildItem(),
        ),
      ),
    );
  }

  Widget _buildItem() {
    return SizedBox(
      width: widget.width,
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
      child: AnimatedScale(
        scale: hovering ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
        child: CommonImage(
          widget.coverUrl!,
          reduceMemCache: true,
        ),
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

  void _zoomOutCover() {
    setState(() {
      hovering = false;
    });
  }

  void _zoomInCover() {
    setState(() {
      hovering = true;
    });
  }
}
