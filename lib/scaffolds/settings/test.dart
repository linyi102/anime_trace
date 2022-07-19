import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/count_controller.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

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
          Obx(
            () {
              int updateOkCnt = updateRecordController.updateOkCnt.value;
              int needUpdateCnt = updateRecordController.needUpdateCnt.value;
              return GestureDetector(
                onTap: () {
                  ClimbAnimeUtil.updateAllAnimesInfo();
                },
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: LinearPercentIndicator(
                    width: MediaQuery.of(context).size.width - 50,
                    animation: true,
                    lineHeight: 20.0,
                    animationDuration: 0,
                    // percent: 0.9,
                    percent:
                        needUpdateCnt > 0 ? (updateOkCnt / needUpdateCnt) : 0,
                    // percent: updateRecordController.updateOkCnt.value.toDouble() /
                    //     updateRecordController.needUpdateCnt.value,
                    center: Text("$updateOkCnt / $needUpdateCnt"),
                    // linearStrokeCap: LinearStrokeCap.roundAll,
                    progressColor: Colors.greenAccent,
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}
