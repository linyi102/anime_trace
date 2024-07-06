class PageParams {
  int pageIndex;
  int pageSize;
  late int baseIndex;

  PageParams({required this.pageIndex, required this.pageSize}) {
    baseIndex = pageIndex;
  }

  int getFixedPageIndex({int firstPageIndex = 0}) {
    if (baseIndex == 0) {
      return firstPageIndex == 0 ? pageIndex : pageIndex + 1;
    } else {
      return firstPageIndex == 0 ? pageIndex - 1 : pageIndex;
    }
  }

  int getOffset() {
    // 如果下标为0，则偏移0个数据
    if (baseIndex == 0) {
      return pageIndex * pageSize;
    } else {
      return (pageIndex - 1) * pageSize;
    }
  }

  // 已查询的数量
  int getQueriedSize() {
    // 如果下标从0开始，那么最开始的查询数量是pageSize
    if (baseIndex == 0) {
      return (pageIndex + 1) * pageSize;
    } else {
      return pageIndex * pageSize;
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
