import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/count_controller.dart';
import 'package:get/get.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CountController countController = Get.put(CountController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("测试"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Obx(() => Text("${countController.count}")),
            onTap: () => countController.increment(),
          )
        ],
      ),
    );
  }
}
