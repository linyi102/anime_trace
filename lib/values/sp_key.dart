import 'package:flutter_test_future/utils/sp_util.dart';

/// 收藏页开启下拉还原最新备份
const pullDownRestoreLatestBackupInChecklistPage =
    "pullDownRestoreLatestBackupInChecklistPage";

/// 上次dav备份文件路径
const latestDavBackupFilePath = "latestDavBackupFilePath";

/// 用户选择的目录搜索源下标
const selectedDirectorySourceIdx = "selectedDirectorySourceIdx";

/// 用户选择的周表搜索源下标
const selectedWeeklyTableSourceIdx = "selectedWeeklyTableSourceIdx";

/// 用户选择的导入数据搜索源下标
const selectedImportCollTableSourceIdx = "selectedImportCollTableSourceIdx";

/// banner本地图片
const bannerFileImagePath = "bannerFileImagePath";

/// banner网络图片
const bannerNetworkImageUrl = "bannerNetworkImageUrl";

/// banner类型下标
const bannerSelectedImageTypeIdx = "bannerSelectedImageTypeIdx";

class SPKey {
  // 显示推荐系列
  static get showRecommendedSeries => "showRecommendedSeries";

  // 系列详情页中显示推荐动漫
  static get showRecommendedAnimesInSeriesPage =>
      "showRecommendedAnimesInSeriesPage";

  // bangumi搜索类型
  static get selectedBangumiSearchCategoryKey =>
      "selectedBangumiSearchCategoryKey";

  // 开启热键恢复最新备份文件
  static get enableRestoreLatestHotkey => "enableRestoreLatestHotkey";

  /// 手机底部导航栏隐藏文字
  static get hideMobileBottomBarLabel => "hideMobileBottomLabel";
}

class Config {
  static String get selectedBangumiSearchCategoryKey =>
      SPUtil.getString(SPKey.selectedBangumiSearchCategoryKey,
          defaultValue: 'all');

  static void setSelectedBangumiSearchCategoryKey(String value) {
    SPUtil.setString(SPKey.selectedBangumiSearchCategoryKey, value);
  }

  static bool get enableRestoreLatestHotkey =>
      SPUtil.getBool(SPKey.enableRestoreLatestHotkey);

  static void toggleEnableRestoreLatestHotkey(bool value) {
    SPUtil.setBool(SPKey.enableRestoreLatestHotkey, value);
  }
}
