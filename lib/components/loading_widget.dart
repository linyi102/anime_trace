import 'package:flutter/material.dart';

Widget loadingWidget(BuildContext context) {
  return const LoadingWidget(center: true);
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({this.height = 60, this.center = false, super.key});
  final double height;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: height,
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}
