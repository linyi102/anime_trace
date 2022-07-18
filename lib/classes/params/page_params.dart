class PageParams {
  int pageIndex;
  int pageSize;

  PageParams(this.pageIndex, this.pageSize);

  int getOffsetWhenIndexStartZero() {
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
