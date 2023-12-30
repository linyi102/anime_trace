class AnimeEpisodeInfo {
  int totalCnt; // 总集数
  int startNumber; // 起始集
  bool calNumberFromOne; // 是否从1开始计算

  AnimeEpisodeInfo({
    this.totalCnt = 0,
    this.startNumber = 1,
    this.calNumberFromOne = false,
  });
}
