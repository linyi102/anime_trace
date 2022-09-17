import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../controllers/update_record_controller.dart';

/**
 * 全局更新动漫
 * 作用：弹出对话框，显示动漫更新进度
 * 使用：动漫页、网络-更新页的下拉操作和右上角刷新按钮
 */
dialogUpdateAllAnimeProgress(parentContext) {
  final UpdateRecordController updateRecordController = Get.find();

  showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text("动漫更新"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Obx(
                  () {
                    int updateOkCnt = updateRecordController.updateOkCnt.value;
                    int needUpdateCnt =
                        updateRecordController.needUpdateCnt.value;
                    // 更新完毕后自动退出对话框
                    if (updateOkCnt == needUpdateCnt) {
                      showToast("动漫更新完毕！");
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                      child: LinearPercentIndicator(
                        barRadius: const Radius.circular(15),
                        // 圆角
                        animation: false,
                        lineHeight: 20.0,
                        animationDuration: 1000,
                        percent: needUpdateCnt > 0
                            ? (updateOkCnt / needUpdateCnt)
                            : 0,
                        center: Text(
                          "$updateOkCnt / $needUpdateCnt",
                          style: const TextStyle(color: Colors.black54)),
                        progressColor: Colors.greenAccent,
                        // linearGradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                      ),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: const Text(
                    "提示：更新时会跳过已完结动漫",
                    style: TextStyle(color: Colors.grey),
                    textScaleFactor: 0.8,
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("结束后提醒我"), // 不要写关闭，否则用户可能会因为点击这个而暂停更新，一直在等待更新界面
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}
