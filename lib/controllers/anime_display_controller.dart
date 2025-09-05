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
  RxBool showGridAnimeName =
      SPUtil.getBool("showGridAnimeName", defaultValue: true)
          .obs; // 网格样式下显示动漫名(封面内或封面下)
  RxBool showNameInCover =
      SPUtil.getBool("showNameInCover", defaultValue: false)
          .obs; // 网格样式下动漫名字显示在封面内底部
  RxInt nameMaxLines = SPUtil.getInt("coverNameMaxLines", defaultValue: 2).obs;
  RxBool showGridAnimeProgress =
      SPUtil.getBool("showGridAnimeProgress", defaultValue: true)
          .obs; // 网格样式下显示进度
  RxBool showSeriesFlagInGridStyle =
      SPUtil.getBool("showSeriesFlagInGridStyle", defaultValue: true)
          .obs; // 网格样式下显示系列图标
  RxBool showReviewNumber =
      SPUtil.getBool("showReviewNumber", defaultValue: true).obs; // 显示第几次观看
  RxBool showAnimeCntAfterTag =
      SPUtil.getBool("showAnimeCntAfterTag", defaultValue: true)
          .obs; // 清单后面显示动漫数量

  // Getx运算也是响应式的
  bool get showNameBelowCover =>
      showGridAnimeName.value && !showNameInCover.value;

  RxBool showProgressBar =
      SPUtil.getBool("showProgressBarBelowGridCover", defaultValue: false).obs;

  turnShowProgressBar() {
    showProgressBar.value = !showProgressBar.value;
    SPUtil.setBool("showProgressBarBelowGridCover", showProgressBar.value);
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

  turnShowGridAnimeName() {
    showGridAnimeName.value = !showGridAnimeName.value;
    SPUtil.setBool("showGridAnimeName", showGridAnimeName.value);
  }

  turnShowSeriesFlagInGridStyle() {
    showSeriesFlagInGridStyle.value = !showSeriesFlagInGridStyle.value;
    SPUtil.setBool(
        "showSeriesFlagInGridStyle", showSeriesFlagInGridStyle.value);
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

  turnNameMaxLines() {
    if (nameMaxLines.value == 1) {
      nameMaxLines.value = 2;
    } else {
      nameMaxLines.value = 1;
    }
    SPUtil.setInt("coverNameMaxLines", nameMaxLines.value);
  }
}
