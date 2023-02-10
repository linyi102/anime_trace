import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      alignment: Alignment.center,
      child: Image.asset('assets/images/logo.png'),
    );
  }
}
