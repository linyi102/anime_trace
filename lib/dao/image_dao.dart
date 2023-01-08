import '../utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class ImageDao {
  static var database = SqliteUtil.database;

  // 编辑好笔记后，退出时更新图片的顺序
  static updateImageOrderIdxById(int imageId, int newOrderIdx) {
    Log.info(
        "updateImageOrderIdxById(imageId=$imageId, newOrderIdx=$newOrderIdx)");
    // 只有调用await updateImageOrderIdxById，才有延时效果，而直接调用updateImageOrderIdxById，才有延时效果，而没有
    // await Future.delayed(const Duration(seconds: 2));
    // 更新不用await等待
    database.rawUpdate('''
    update image
    set order_idx = $newOrderIdx
    where image_id = $imageId
    ''');
  }
}
