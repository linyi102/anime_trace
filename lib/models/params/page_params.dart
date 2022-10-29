class PageParams {
  int pageIndex;
  int pageSize;

  PageParams(this.pageIndex, this.pageSize);

  int getOffsetWhenIndexStartZero() {
    // 如果下标为0，则偏移0个数据
    return pageIndex * pageSize;
  }

  int getOffsetWhenIndexStartOne() {
    return (pageIndex - 1) * pageSize;
  }

  @override
  String toString() {
    return "PageParams[pageIndex=$pageIndex,pageSize=$pageSize]";
  }
}
