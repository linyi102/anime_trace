import 'package:animetrace/controllers/setting_service.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:get/get.dart';

/// 动漫类型控制器
///
/// 存储/获取类型字符串列表，支持自定义
class CategoryController extends GetxController {
  static CategoryController get to => Get.find();

  List<String> categories = [];

  // TODO 未知是否有必要内置？如何过滤非自定义类别
  List<String> readonlyCategories = const ['未知'];

  @override
  void onInit() async {
    super.onInit();
    load();
  }

  void load() async {
    categories = await SettingService.to.getAnimeCategories() ??
        [...readonlyCategories, 'TV', 'WEB', '剧场版', 'OVA', 'OAD'];
    update();
  }

  bool isReadonly(String category) {
    return readonlyCategories.contains(category);
  }

  bool addCategory(String category) {
    category = category.trim();
    if (category.isEmpty) return false;

    if (categories.contains(category)) {
      ToastUtil.showText('已存在');
      return false;
    }

    categories.add(category);

    update();
    _save();
    return true;
  }

  bool updateCategory(int index, String category) {
    assert(0 <= index && index < categories.length);
    category = category.trim();
    if (category.isEmpty) return false;

    final oldCategory = categories[index];
    if (oldCategory == category) return true;

    for (int i = 0; i < categories.length; i++) {
      if (i == index) continue;

      if (categories[i] == category) {
        ToastUtil.showText('已存在');
        return false;
      }
    }

    categories[index] = category;

    update();
    _save();
    AnimeDao.batchUpdateCategory(oldCategory, category);

    return true;
  }

  void removeCategory(String category) {
    categories.remove(category);

    update();
    _save();
  }

  void updateOrder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final category = categories.removeAt(oldIndex);
    categories.insert(newIndex, category);

    update();
    _save();
  }

  Future<bool> _save() {
    return SettingService.to.setAnimeCategories(categories);
  }
}
