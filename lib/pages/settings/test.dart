import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("测试"),
      ),
      body: ListView(
        children: [
          // 不管用
          ListTile(
            title: const Text("清除缓存"),
            subtitle: Text("${imageCache.currentSizeBytes / 1024 / 1024}MB"),
            onTap: () {
              imageCache.clear();
            },
          )
        ],
      ),
    );
  }
}
