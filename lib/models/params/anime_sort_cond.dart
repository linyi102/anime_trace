class AnimeSortCond {
  static List<SortCondItem> sortConds = [
    SortCondItem(showName: "名字", columnName: "anime_name"),
    SortCondItem(showName: "首播时间", columnName: "premiere_time"),
    SortCondItem(showName: "收藏时间", columnName: "anime_id"),
    SortCondItem(showName: "最后修改清单时间", columnName: "last_mode_tag_time"),
    SortCondItem(showName: "第1集观看时间", columnName: "first_episode_watch_time"),
    SortCondItem(showName: "最近观看时间", columnName: "recent_watch_time"),
  ]; // 给出所有排序条件
  bool desc; // 是否倒序
  int specSortColumnIdx; // 指定按照哪个列排序

  AnimeSortCond({required this.specSortColumnIdx, this.desc = true});
}

class SortCondItem {
  String showName; // 展示给用户的名字
  String columnName; // 数据库列名

  SortCondItem({required this.showName, required this.columnName});
}
