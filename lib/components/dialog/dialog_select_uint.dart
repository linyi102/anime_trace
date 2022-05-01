import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';

Future<int?> dialogSelectUint(context, String title,
    {int initialValue = 0,
    int minValue = 0,
    int maxValue = 9223372036854775807}) async {
  var yearTextEditingController = TextEditingController();
  int tmpValue = initialValue;
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
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          helperText: "范围：[$minValue, $maxValue]"),
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
                      icon: const Icon(Icons.remove)),
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
                      icon: const Icon(Icons.add)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, initialValue); // 取消了则返回默认值
                    },
                    child: const Text("取消")),
                ElevatedButton(
                    onPressed: () {
                      String content = yearTextEditingController.text;
                      if (content.isEmpty) {
                        showToast("不能为空！");
                        return;
                      }
                      int number = int.parse(content);
                      if (number < minValue || number > maxValue) {
                        showToast("设置范围：[$minValue, $maxValue]");
                        return;
                      }
                      Navigator.pop(context, number);
                    },
                    child: const Text("确认")),
              ]);
        });
      });
}
