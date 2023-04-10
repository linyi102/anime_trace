import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

Widget emptyDataHint({String msg = "没有数据。", String toastMsg = ""}) {
  return Stack(
    children: [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(msg),
            if (toastMsg.isNotEmpty)
              IconButton(
                  onPressed: () {
                    ToastUtil.showText(toastMsg);
                  },
                  iconSize: 15,
                  icon: const Icon(Icons.help_outline))
          ],
        ),
      ),
    ],
  );
}
