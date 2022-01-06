import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ImageUtil {
  static ImageUtil? _instance;
  ImageUtil._();
  static late String rootImageDirPath;

  static getInstance() async {
    if (Platform.isAndroid) {
      rootImageDirPath =
          ((await getExternalStorageDirectory())!.path + "/images");
    } else if (Platform.isWindows) {
      rootImageDirPath =
          ((await getApplicationSupportDirectory()).path + "/images");
      // rootImageDirPath =
      //     join((await getApplicationSupportDirectory()).path, "images");
    } else {
      throw ("未适配平台：${Platform.environment}");
    }
    return _instance ?? ImageUtil._();
  }
}
