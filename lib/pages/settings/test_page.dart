import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';
import 'package:flutter_test_future/utils/log.dart';

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
            title: const Text("返回上一级"),
            onTap: () {
              // Get.back();
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("加载对话框"),
            onTap: () async {
              BuildContext? loadingContext;
              showDialog(
                  context: context,
                  builder: (context) {
                    loadingContext = context;
                    return const LoadingDialog("获取详细信息中...");
                  });
              await Future.delayed(const Duration(seconds: 2));
              if (loadingContext != null) Navigator.pop(loadingContext!);
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
