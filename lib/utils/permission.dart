import 'package:flutter_test_future/utils/log.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  /// 外部存储管理权限
  static Future<bool> requestManageExternalStorage(
      {bool onlyCheck = false}) async {
    var status = await Permission.manageExternalStorage.status;
    if (status == PermissionStatus.restricted) {
      // Android10没有manageExternalStorage，因此对应的权限状态为restricted，所以应判断storage的权限状态
      return _checkPermissionAndRequest(Permission.storage);
    } else {
      // Android11
      return _checkPermissionAndRequest(Permission.manageExternalStorage);
    }
  }

  static Future<bool> _checkPermissionAndRequest(Permission permission,
      {bool onlyCheck = false}) async {
    var status = await permission.status;
    if (status != PermissionStatus.granted) {
      if (onlyCheck) return false;

      // 未授权则发起一次申请
      status = await permission.request();
      if (status != PermissionStatus.granted) {
        Log.info("授权${permission.toString()}失败");
        return false;
      }
    }
    Log.info("授权${permission.toString()}成功");
    return true;
  }
}
