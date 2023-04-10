import 'package:flutter/material.dart';

class ClearButton extends StatelessWidget {
  const ClearButton({this.onTapClear, super.key});
  final void Function()? onTapClear;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 15,
        width: 15,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onTapClear,
            child: const Icon(Icons.close, size: 18)));
  }
}
