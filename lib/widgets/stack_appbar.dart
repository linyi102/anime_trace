import 'package:flutter/material.dart';

class StackAppBar extends StatelessWidget {
  const StackAppBar(
      {this.leading,
      this.title = '',
      this.titleSize = 20,
      this.foregroundColor = Colors.white,
      this.onTapLeading,
      this.actions,
      super.key});

  final Widget? leading;
  final String title;
  final double titleSize;
  final Color foregroundColor;
  final void Function()? onTapLeading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ]),
      ),
      child: Row(
        children: [
          const SizedBox(width: 5),
          leading ??
              IconButton(
                onPressed: onTapLeading ?? () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                color: foregroundColor,
              ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                  color: foregroundColor,
                  fontSize: titleSize,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          ...?actions
        ],
      ),
    );
  }
}
