import 'dart:convert';

import 'package:animetrace/components/anime_custom_cover.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/sp_profile.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:get/get.dart';

class AnimeDisplayController extends GetxController {
  static AnimeDisplayController get to => Get.find();

  RxBool displayList = SPUtil.getBool("display_list").obs; // 列表或网格
  RxInt gridColumnCnt = SpProfile.getGridColumnCnt().obs; // 动漫网格列数
  RxBool enableResponsiveGridColumnCnt =
      SPUtil.getBool("enableResponsiveGridColumnCnt", defaultValue: true)
          .obs; // 开启响应式动漫网格列数
  RxBool showAnimeCntAfterTag =
      SPUtil.getBool("showAnimeCntAfterTag", defaultValue: true)
          .obs; // 清单后面显示动漫数量

  late Rx<AnimeCoverStyle> coverStyle = getCoverStyle().obs;

  turnShowAnimeCntAfterTag() {
    showAnimeCntAfterTag.value = !showAnimeCntAfterTag.value;
    SPUtil.setBool("showAnimeCntAfterTag", showAnimeCntAfterTag.value);
  }

  turnDisplayList() {
    displayList.value = !displayList.value;
    SPUtil.setBool("display_list", displayList.value);
  }

  turnEnableResponsiveGridColumnCnt() {
    enableResponsiveGridColumnCnt.value = !enableResponsiveGridColumnCnt.value;
    SPUtil.setBool(
        "enableResponsiveGridColumnCnt", enableResponsiveGridColumnCnt.value);
  }

  setGridColumnCnt(int cnt) {
    gridColumnCnt.value = cnt;
    SPUtil.setInt("gridColumnCnt", cnt);
  }

  void updateCoverStyle(AnimeCoverStyle style) {
    coverStyle.value = style;
    SPUtil.setString('coverStyle', jsonEncode(coverStyle.value.toJson()));
  }

  AnimeCoverStyle getCoverStyle() {
    try {
      final json = SPUtil.getString('coverStyle');
      if (json.isEmpty) return const AnimeCoverStyle();

      return AnimeCoverStyle.fromJson(jsonDecode(json));
    } catch (e, s) {
      AppLog.error('get cover style error', error: e, stackTrace: s);
      return const AnimeCoverStyle();
    }
  }
}
