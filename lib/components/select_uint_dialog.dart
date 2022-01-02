import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';

Future<int?> dialogSelectUint(context, String title,
    {int defaultValue = 0,
    int minValue = 0,
    int maxValue = 9223372036854775807}) async {
  var yearTextEditingController = TextEditingController();
  int tmpValue = defaultValue;
  return await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, state) {
          return AlertDialog(
              title: Text(title),
              content: Row(
                children: [
                  Expanded(
                    child: TextField(
                      // autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // 数字，只能是整数
                      ],
                      controller: yearTextEditingController
                        ..text = tmpValue.toString(),
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        // 最小值为minValue
                        if (tmpValue - 1 >= minValue) {
                          // 先测试，再减，否则还需要恢复，比如如下面的按钮
                          tmpValue--;
                          state(() {});
                        }
                      },
                      icon: const Icon(Icons.navigate_before)),
                  IconButton(
                      onPressed: () {
                        tmpValue++;
                        // 最大值为maxValue
                        if (tmpValue <= maxValue) {
                          state(() {});
                        } else {
                          tmpValue--; // 恢复
                        }
                      },
                      icon: const Icon(Icons.navigate_next)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, defaultValue); // 取消了则返回默认值
                    },
                    child: const Text("取消")),
                TextButton(
                    onPressed: () {
                      String content = yearTextEditingController.text;
                      if (content.isEmpty) {
                        showToast("不能为空！");
                        return;
                      }

                      Navigator.pop(context, int.parse(content));
                    },
                    child: const Text("确认")),
              ]);
        });
      });
}
