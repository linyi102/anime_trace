import 'package:flutter_test_future/utils/log.dart';

class VersionUtil {
  /// v1 > v2
  static bool greater(String v1, String v2) {
    return VersionUtil.compare(v1, v2) == 1;
  }

  /// v1 < v2
  static bool less(String v1, String v2) {
    return VersionUtil.compare(v1, v2) == -1;
  }

  /// v1 >= v2
  static bool greaterOrEqual(String v1, String v2) {
    return !less(v1, v2);
  }

  /// v1 <= v2
  static bool lessOrEqual(String v1, String v2) {
    return !greater(v1, v2);
  }

  /// v1 = v2
  static bool equal(String v1, String v2) {
    return VersionUtil.compare(v1, v2, log: false) == 0;
  }

  /// 检查是否是新版本
  /// v1 > v2：返回1
  /// v1 < v2、无法解析：返回-1
  /// v1 = v2：返回0
  static int compare(String v1, String v2, {bool log = true}) {
    if (log) Log.info('------------------\nv1=$v1，v2=$v2');

    var reg = RegExp('[0-9]+(\\.[0-9]+)+');
    v1 = reg.firstMatch(v1)?[0] ?? "";
    v2 = reg.firstMatch(v2)?[0] ?? "";
    if (v1.isEmpty || v2.isEmpty) {
      if (log) Log.info('没有解析到正确版本：v1=$v1，v2=$v2');
      return -1;
    }
    if (log) Log.info('1. 正则匹配版本：v1=$v1, v2=$v2');

    var list1 = v1.split(".");
    var list2 = v2.split(".");
    if (log) Log.info("2. 小数点分割成数组：list1=$list1, list2=$list2");
    int len1 = list1.length, len2 = list2.length;
    if (len1 > len2) {
      list2.addAll(List.generate(len1 - len2, (index) => '0'));
    } else if (len1 < len2) {
      list1.addAll(List.generate(len2 - len1, (index) => '0'));
    }
    if (log) Log.info("3. 尾部填充0使之长度相同：list1=$list1, list2=$list2");

    int len = list1.length;
    for (int i = 0; i < len; ++i) {
      int? n1 = int.tryParse(list1[i]), n2 = int.tryParse(list2[i]);
      if (n1 != null && n2 != null) {
        if (n1 > n2) {
          if (log) Log.info('比较结果：$v1 > $v2');
          return 1;
        } else if (n1 < n2) {
          if (log) Log.info('比较结果：$v1 < $v2 ($n1 < $n2)');
          return -1;
        }
      }
    }
    if (log) Log.info('比较结果：$v1 = $v2');
    return 0;
  }
}
