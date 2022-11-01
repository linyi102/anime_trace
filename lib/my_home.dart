import 'package:flutter/cupertino.dart';
import 'package:flutter_test_future/pages/home_tabs.dart';
import 'package:flutter_test_future/pages/main_screen.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import 'components/update_hint.dart';
import 'controllers/update_record_controller.dart';

class MyHome extends StatelessWidget {
  MyHome({
    Key? key,
  }) : super(key: key);

  final UpdateRecordController updateRecordController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      int updateOkCnt = updateRecordController.updateOkCnt.value;
      int needUpdateCnt = updateRecordController.needUpdateCnt.value;
      // 最初需要更新的数量为0，所以需要避免刚进入App就提示该信息
      if (needUpdateCnt > 0 && updateOkCnt == needUpdateCnt) {
        showToast("动漫更新完毕！");
      }

      return Stack(
        children: const [
          MainScreen(),
          // HomeTabs(),
          UpdateHint(checkLatestVersion: true)],
      );
    });
  }
}

