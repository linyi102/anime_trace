import 'package:flutter_test_future/utils/image_util.dart';

import '../utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class ImageDao {
  static var database = SqliteUtil.database;

  /// 编辑好笔记后，退出时更新图片的顺序
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

  /// 获取所有图片
  static Future<List<String>> getAllImages() async {
    Log.info('sql: getAllImages');

    List<String> images = [];
    List<Map> rows =
        await database.rawQuery('select image_local_path from image');
    for (var row in rows) {
      String relativePath = row['image_local_path'];
      String path = ImageUtil.getAbsoluteNoteImagePath(relativePath);
      images.add(path);
    }

    return images;
  }

  /// 获取某个动漫的所有图片
  static Future<List<String>> getImages(int animeId) async {
    Log.info('sql: getImages(animeId=$animeId)');

    List<String> images = [];
    List<Map> rows = await database.rawQuery('''
      select image_local_path
      from image left join episode_note on episode_note.note_id = image.note_id
      where anime_id = $animeId;
      ''');
    for (var row in rows) {
      String relativePath = row['image_local_path'];
      String path = ImageUtil.getAbsoluteNoteImagePath(relativePath);
      images.add(path);
    }

    return images;
  }
}
