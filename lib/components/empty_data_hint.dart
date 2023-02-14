import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

List<String> emoticons = [
  "|･ω･｀)",
  "ヽ(*。>Д<)o゜",
  "(๑°⌓°๑)",
  "o(╥﹏╥)o",
  "o(TωT)o",
  "(๑╹っ╹๑)",
  "╰(￣▽￣)╭",
  "φ(*￣0￣)",
  "(_　_)。゜zｚＺ",
  "(～﹃～)~zZ",
  "(￣o￣) . z Z",
  "ԅ(¯﹃¯ԅ)",
  "ヾ(•ω•`)o",
  "_(:з)∠)_",
];

Widget emptyDataHint({String msg = "什么都没有~", String toastMsg = ""}) {
  String emoticon = emoticons[Random().nextInt(emoticons.length)];

  return Stack(
    children: [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(emoticon, style: const TextStyle(fontSize: 24)),
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
