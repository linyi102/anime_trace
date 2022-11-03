import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

Widget emptyDataHint(String msg, {String toastMsg = ""}) {
  return Stack(
    children: [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text("(°ー°〃)"),
            const SizedBox(height: 10),
            Text(msg),
            toastMsg.isEmpty
                ? Container()
                : IconButton(
                    onPressed: () => showToast(toastMsg),
                    iconSize: 15,
                    icon: const Icon(Icons.help_outline))
          ],
        ),
      ),
    ],
  );
}
