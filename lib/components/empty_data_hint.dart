import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

Widget emptyDataHint(String msg, {String toastMsg = ""}) {
  return Stack(
    children: [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Icon(Fontelico.emo_sleep, size: 80),
            // const Icon(Icons.hourglass_empty, size: 80),
            const SizedBox(height: 10),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
            toastMsg.isEmpty
                ? Container()
                : IconButton(
                    onPressed: () {
                      showToast(toastMsg);
                    },
                    icon: const Icon(Icons.help_outline_rounded))
          ],
        ),
      ),
    ],
  );
}
