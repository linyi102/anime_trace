import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/utils/log.dart';
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
    Log.build(runtimeType);

    return Scaffold(
      appBar: AppBar(
        title: const Text("测试"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("返回上一级"),
            onTap: () {
              // Get.back();
              Navigator.pop(context);
            },
          ),
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
