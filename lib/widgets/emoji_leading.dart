import 'package:flutter/material.dart';
import 'package:animetrace/utils/extensions/color.dart';

class EmojiLeading extends StatelessWidget {
  const EmojiLeading({super.key, required this.emoji});
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).hintColor.withOpacityFactor(0.06),
      ),
      child: emoji == null
          ? Icon(
              Icons.tag,
              color: Theme.of(context).hintColor,
              size: 20,
            )
          : Center(
              child: Text(
              emoji ?? '',
              style: const TextStyle(fontSize: 18),
            )),
    );
  }
}
