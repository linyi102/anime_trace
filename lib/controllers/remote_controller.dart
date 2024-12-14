import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:get/get.dart';

class RemoteController extends GetxController {
  static RemoteController get to => Get.find();

  bool isOnline = SPUtil.getBool("online");
  bool get isOffline => !isOnline;

  void setOnline(bool value) {
    SPUtil.setBool("online", value);
    isOnline = value;
    update();
  }
}
