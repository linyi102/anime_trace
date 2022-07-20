import 'dart:io';

import 'sp_util.dart';

class SpProfile {
  static getGridColumnCnt() {
    return SPUtil.getInt("gridColumnCnt",
        defaultValue: Platform.isWindows ? 8 : 3);
  }
}