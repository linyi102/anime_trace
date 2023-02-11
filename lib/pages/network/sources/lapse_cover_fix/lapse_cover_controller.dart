import 'package:flutter_test_future/models/anime.dart';
import 'package:get/get.dart';

class LapseCoverController extends GetxController {
  // 放到控制器空，当再查找失效封面时就退出，之后再进入时避免再次检测
  List<Anime> lapseCoverAnimes = []; // 失效封面的动漫
  bool loadOk = false; // 所有封面是否检测完毕
  bool recovering = false; // 恢复封面中

}
