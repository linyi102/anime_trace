import 'package:flutter/material.dart';

enum ButtonLoaderStyle {
  custom, // 自定义，loader生效
  circularCenter, // 加载圈居中
  circularTrailing, // 加载圈放置尾部
}

class ActionButton extends StatefulWidget {
  const ActionButton({
    Key? key,
    required this.onTap,
    required this.child,
    this.loaderStyle = ButtonLoaderStyle.circularCenter,
    this.borderRadius,
    this.loader,
    this.height,
  }) : super(key: key);
  final Future<void> Function()? onTap;
  final Widget? child;
  final Widget? loader;
  final double? height;
  final BorderRadius? borderRadius;
  final ButtonLoaderStyle loaderStyle;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 45,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ElevatedButton(
            style: ButtonStyle(
                shape: widget.borderRadius != null
                    ? MaterialStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: widget.borderRadius!))
                    : null),
            onPressed: () async {
              if (loading) return;

              loading = true;
              if (mounted) setState(() {});
              try {
                await widget.onTap?.call();
              } catch (e) {
                rethrow;
              } finally {
                loading = false;
                if (mounted) setState(() {});
              }
            },
            child: _buildChild(),
          ),
          if (loading &&
              widget.loaderStyle == ButtonLoaderStyle.circularTrailing)
            Align(
              alignment: Alignment.centerRight,
              child: _buildCircularIndicator(),
            )
        ],
      ),
    );
  }

  _buildChild() {
    if (!loading) return widget.child;

    switch (widget.loaderStyle) {
      case ButtonLoaderStyle.custom:
        return widget.loader;
      case ButtonLoaderStyle.circularCenter:
        return _buildCircularIndicator();
      default:
        return widget.child;
    }
  }

  LayoutBuilder _buildCircularIndicator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxHeight - 20;
        if (size <= 0) return const SizedBox.shrink();

        return Container(
          height: size,
          width: size,
          margin: const EdgeInsets.only(right: 10),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        );
      },
    );
  }
}

Widget circularTextButtonLoader(String title) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          )),
      const SizedBox(width: 10),
      Text(title),
    ],
  );
}
