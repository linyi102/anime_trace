import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:flutter/material.dart';

Future<void> showShareErrorLog({String content = ""}) async {
  ToastUtil.showDialog(
    builder: (close) => AlertDialog(
      title: const Text("发生错误"),
      content: Text("${content.isNotEmpty ? '$content,' : ''}是否将错误日志发送给开发者？"),
      actions: [
        TextButton(
          onPressed: () {
            close();
          },
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () {
            close();
            AppLog.share();
          },
          child: const Text("分享"),
        )
      ],
    ),
  );
}
