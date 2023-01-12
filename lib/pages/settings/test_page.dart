import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    File dbFile = File(SqliteUtil.dbPath);
    final LabelsController labelsController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text("测试"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("加载对话框"),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    const String text = "获取详细信息中...";
                    return const LoadingDialog(text);
                    // return SimpleDialog(
                    //   children: [
                    //     Center(
                    //         child: Column(
                    //       children: const [
                    //         SizedBox(child: CircularProgressIndicator()),
                    //         SizedBox(height: 10),
                    //         Text(text)
                    //       ],
                    //     ))
                    //   ],
                    // );
                  });
            },
          ),
          ListTile(
            title: const Text("设置字体"),
            subtitle: Obx(() => Text(themeController.fontFamilyFallback[0])),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (dialogContext) {
                    var textEditingController = TextEditingController()
                      ..text = themeController.fontFamilyFallback[0];
                    return AlertDialog(
                      title: const Text("设置字体"),
                      content: TextField(
                        controller: textEditingController,
                        autofocus: true,
                        maxLength: 30,
                        decoration: InputDecoration(
                          helperText: "指定一种字体",
                          suffixIcon: IconButton(
                              // 清空按钮
                              onPressed: () {
                                textEditingController
                                    .clear(); // 控制器.clear函数来清空输入的内容
                              },
                              icon: const Icon(Icons.close)),
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text("取消"),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        ElevatedButton(
                          child: const Text("确认"),
                          onPressed: () {
                            String input = textEditingController.text;
                            // 去除单双引号
                            input = input.replaceAll("'", "");
                            input = input.replaceAll("\"", "");
                            themeController.changeFontFamily(input);
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    );
                  });
            },
          ),
          // 不管用
          ListTile(
            title: const Text("清除缓存"),
            subtitle: Text("${imageCache.currentSizeBytes / 1024 / 1024}MB"),
            onTap: () {
              // imageCache.clear();
            },
          )
        ],
      ),
    );
  }
}
