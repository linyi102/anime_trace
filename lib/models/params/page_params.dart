class PageParams {
  int pageIndex;
  int pageSize;
  late int baseIndex;

  PageParams({required this.pageIndex, required this.pageSize}) {
    baseIndex = pageIndex;
  }

  int getOffset() {
    if (baseIndex == 0) {
      // 如果下标为0，则偏移0个数据
      return pageIndex * pageSize;
    } else {
      return (pageIndex - 1) * pageSize;
    }
  }

  void resetPageIndex() {
    pageIndex = baseIndex;
  }

  @override
  String toString() {
    return "PageParams[pageIndex=$pageIndex,pageSize=$pageSize]";
  }
}
