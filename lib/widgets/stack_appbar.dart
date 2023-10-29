import 'package:flutter/material.dart';

class StackAppBar extends StatelessWidget {
  const StackAppBar(
      {this.leading,
      this.title = '',
      this.titleSize = 20,
      this.foregroundColor = Colors.white,
      this.onTapLeading,
      super.key});

  final Widget? leading;
  final String title;
  final double titleSize;
  final Color foregroundColor;
  final void Function()? onTapLeading;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
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
            // IconButton(
            //     onPressed: () {},
            //     icon: const Icon(Icons.more_vert, color: Colors.white))
          ],
        ),
      ),
    );
  }
}
