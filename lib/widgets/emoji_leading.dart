import 'package:flutter/material.dart';

class EmojiLeading extends StatelessWidget {
  const EmojiLeading({super.key, required this.emoji});
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: emoji == null
          ? Icon(Icons.tag, color: onSurface, size: 20)
          : Center(
              child: Text(emoji ?? '',
                  style: TextStyle(fontSize: 18, color: onSurface))),
    );
  }
}
