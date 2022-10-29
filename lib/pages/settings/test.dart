import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/count_controller.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:get/get.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CountController countController = Get.put(CountController());
    final UpdateRecordController updateRecordController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text("测试"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Obx(() => Text("${countController.count}")),
            onTap: () => countController.increment(),
          ),
          ListTile(
            title: const Text("更新所有动漫"),
            subtitle: Obx(
              () => Text(
                  "${updateRecordController.updateOkCnt.value} / ${updateRecordController.needUpdateCnt.value}"),
            ),
            onTap: () {
              ClimbAnimeUtil.updateAllAnimesInfo();
            },
          ),
        ],
      ),
    );
  }
}
