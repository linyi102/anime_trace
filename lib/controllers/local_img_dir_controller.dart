import 'package:animetrace/utils/image_util.dart';
import 'package:get/get.dart';

/// 太麻烦，暂不使用
class LocalImgDirController extends GetxController {
  RxString noteImgDir = ImageUtil.noteImageRootDirPath.obs;
  RxString coverDir = ImageUtil.coverImageRootDirPath.obs;

  changeNoteImgDir(String dir) {
    noteImgDir.value = dir;
    ImageUtil.setNoteImageRootDirPath(dir);
  }

  changeCoverDir(String dir) {
    coverDir.value = dir;
    ImageUtil.setCoverImageRootDirPath(dir);
  }

  getAbsoluteNoteImagePath(String relImgPath) {}
}
