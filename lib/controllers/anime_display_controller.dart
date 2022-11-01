import 'package:get/get.dart';

import '../utils/sp_profile.dart';
import '../utils/sp_util.dart';

class AnimeDisplayController extends GetxController {
  RxBool displayList = SPUtil.getBool("display_list").obs; // 列表或网格
  RxInt gridColumnCnt = SpProfile.getGridColumnCnt().obs; // 网格列数
  RxBool showGridAnimeName = SPUtil.getBool("showGridAnimeName", defaultValue: true).obs; // 网格样式下显示动漫名(封面内或封面下)
  RxBool showNameInCover = SPUtil.getBool("showNameInCover", defaultValue: true).obs; // 网格样式下动漫名字显示在封面内底部
  RxBool showGridAnimeProgress = SPUtil.getBool("showGridAnimeProgress", defaultValue: true).obs; // 网格样式下显示进度
  RxBool showReviewNumber = SPUtil.getBool("showReviewNumber", defaultValue: true).obs; // 显示第几次观看
  RxBool showAnimeCntAfterTag = SPUtil.getBool("showAnimeCntAfterTag", defaultValue: true).obs; // 清单后面显示动漫数量

  // Getx运算也是响应是的
  bool get showNameBelowCover => showGridAnimeName.value && !showNameInCover.value;

  turnDisplayList() {
    displayList.value = !displayList.value;
    SPUtil.setBool("display_list", displayList.value);
  }

  setGridColumnCnt(int cnt) {
    gridColumnCnt.value = cnt;
    SPUtil.setInt("gridColumnCnt", cnt);
  }

  turnShowGridAnimeName() {
    showGridAnimeName.value = !showGridAnimeName.value;
    SPUtil.setBool("showGridAnimeName", showGridAnimeName.value);
  }

  turnShowGridAnimeProgress() {
    showGridAnimeProgress.value = !showGridAnimeProgress.value;
    SPUtil.setBool("showGridAnimeProgress", showGridAnimeProgress.value);
  }

  turnShowReviewNumber() {
    showReviewNumber.value = !showReviewNumber.value;
    SPUtil.setBool("showReviewNumber", showReviewNumber.value);
  }

  turnShowNameInCover() {
    showNameInCover.value = !showNameInCover.value;
    SPUtil.setBool("showNameInCover", showNameInCover.value);
  }

  turnShowAnimeCntAfterTag() {
    showAnimeCntAfterTag.value = !showAnimeCntAfterTag.value;
    SPUtil.setBool("showAnimeCntAfterTag", showAnimeCntAfterTag.value);
  }

}