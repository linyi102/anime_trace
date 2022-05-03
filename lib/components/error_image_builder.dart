import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';

Widget Function(BuildContext, Object, StackTrace?)? errorImageBuilder(
    String path,
    {double fallbackHeight = 400.0,
    double fallbackWidth = 400.0}) {
  return (buildContext, object, stackTrace) {
    return MaterialButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: path))
            .then((value) => showToast("已复制图片相对路径：\n$path"));
      },
      // child: const Text(
      //   "未找到图片",
      //   style: TextStyle(color: Colors.black),
      // ),
      child: Placeholder(
        fallbackHeight: fallbackHeight,
        fallbackWidth: fallbackWidth,
      ),
    );
  };
}
