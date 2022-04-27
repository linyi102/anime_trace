class Filter {
  String
      year; // 年份。用String而非int，这样默认值时字符串空，则不会过滤，否则用int时默认值不能为空，只能选一个数，追加到url中需要判断为默认值时，转为空字符串
  String season; // 季度
  String status; // 状态
  String label; // 标签
  String order; // 按什么排序
  bool asc; // true为正序
  String region; // 地区
  String category; // 类型

  Filter(
      {this.year = "",
      this.season = "",
      this.status = "",
      this.label = "",
      this.order = "",
      this.asc = true,
      this.region = "",
      this.category = ""});

  String getYearStr() {
    return year.isEmpty ? "全部" : year;
  }
}
