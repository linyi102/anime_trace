import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/routes/default_transitions.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../controllers/update_record_controller.dart';
import '../../utils/climb/climb_anime_util.dart';

dialogUpdateAllAnimeProgress(parentContext) {
  final UpdateRecordController updateRecordController = Get.find();

  showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text("动漫更新"),
          content: Obx(
            () {
              int updateOkCnt = updateRecordController.updateOkCnt.value;
              int needUpdateCnt = updateRecordController.needUpdateCnt.value;

              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: LinearPercentIndicator(
                  barRadius: const Radius.circular(15), // 圆角
                  animation: false,
                  lineHeight: 20.0,
                  animationDuration: 1000,
                  percent:
                  needUpdateCnt > 0 ? (updateOkCnt / needUpdateCnt) : 0,
                  center: Text("$updateOkCnt / $needUpdateCnt"),
                  progressColor: Colors.greenAccent,
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("关闭"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}
