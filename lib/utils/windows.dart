import 'dart:io';

class WindowsUtil {
  static Future<bool> locateFile(String path) async {
    try {
      final result = await Process.run('cmd', ['/c', 'explorer', '/select,', path]);
      final isSuccess = result.exitCode == 0;
      return isSuccess;
    } catch (e) {
      return false;
    }
  }
}
