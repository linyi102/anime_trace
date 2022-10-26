import 'package:get/get.dart';

import '../utils/sp_profile.dart';
import '../utils/sp_util.dart';

class AnimeDisplayController extends GetxController {
  RxBool displayList = SPUtil.getBool("display_list").obs; // 列表或网格
  RxInt gridColumnCnt = SpProfile.getGridColumnCnt().obs; // 网格列数
  RxBool hideGridAnimeName = SPUtil.getBool("hideGridAnimeName").obs; // 隐藏动漫名
  RxBool hideGridAnimeProgress = SPUtil.getBool("hideGridAnimeProgress").obs; // 隐藏进度
  RxBool hideReviewNumber = SPUtil.getBool("hideReviewNumber").obs; // 隐藏第几次观看

  turnDisplayList() {
    displayList.value = !displayList.value;
    SPUtil.setBool("display_list", displayList.value);
  }

  setGridColumnCnt(int cnt) {
    gridColumnCnt.value = cnt;
    SPUtil.setInt("gridColumnCnt", cnt);
  }

  turnHideGridAnimeName() {
    hideGridAnimeName.value = !hideGridAnimeName.value;
    SPUtil.setBool("hideGridAnimeName", hideGridAnimeName.value);
  }

  turnHideGridAnimeProgress() {
    hideGridAnimeProgress.value = !hideGridAnimeProgress.value;
    SPUtil.setBool("hideGridAnimeProgress", hideGridAnimeProgress.value);
  }

  turnHideReviewNumber() {
    hideReviewNumber.value = !hideReviewNumber.value;
    SPUtil.setBool("hideReviewNumber", hideReviewNumber.value);
  }

}