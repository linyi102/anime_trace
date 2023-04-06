import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

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
                    showToast(toastMsg);
                  },
                  iconSize: 15,
                  icon: const Icon(Icons.help_outline))
          ],
        ),
      ),
    ],
  );
}
