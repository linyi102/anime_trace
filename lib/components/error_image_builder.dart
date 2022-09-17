import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';

// 错误图片
// 提供可以点击
// 也可以不点击，比如点击封面需要进入封面详细页，然后修改
Widget Function(BuildContext, Object, StackTrace?)? errorImageBuilder(
    String path,
    {bool dialog = true,
    double fallbackHeight = 400.0,
    double fallbackWidth = 400.0}) {
  return (buildContext, object, stackTrace) {
    return MaterialButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {

        if (dialog) {
          showDialog(
              context: buildContext,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text("无法显示图片"),
                  content: ListTile(
                    title: Text("图片地址：$path"),
                    subtitle: const Text("点击复制地址"),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: path))
                          .then((value) => showToast("已复制图片相对路径：\n$path"));
                    },
                  ),
                );
              });
        }
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
