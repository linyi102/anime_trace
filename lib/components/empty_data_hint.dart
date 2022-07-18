import 'package:flutter/material.dart';

Widget emptyDataHint(String msg) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.hourglass_empty, size: 30),
        const SizedBox(height: 10),
        Text(msg)
      ],
    ),
  );
}
