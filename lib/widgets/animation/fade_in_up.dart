import 'package:flutter/material.dart';

class FadeInUp extends StatefulWidget {
  const FadeInUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.ease,
    this.animate = true,
  });
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool animate;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> offsetDy;
  late Animation<double> opacity;
  late bool display;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: widget.duration);
    offsetDy = Tween<double>(begin: 20, end: 0)
        .animate(CurvedAnimation(parent: controller, curve: widget.curve));
    opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: controller, curve: widget.curve));
    display = widget.animate;

    controller.addStatusListener((status) {
      switch (status) {
        case AnimationStatus.forward:
          if (mounted) {
            setState(() {
              display = true;
            });
          }
          break;
        case AnimationStatus.dismissed:
          if (mounted) {
            setState(() {
              display = false;
            });
          }
          break;
        default:
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.animate ? controller.forward() : controller.reverse();
    if (!display) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: offsetDy,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, offsetDy.value),
        child: Opacity(
          opacity: opacity.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
