import 'package:flutter/material.dart';

class FloatingCard extends StatefulWidget {
  const FloatingCard({super.key, this.child});
  final Widget? child;

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
              width: MediaQuery.of(context).size.width - 100,
              // height: 200,
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
