class AnimeGridCoverConfig {
  final bool showCover; // 封面
  final bool showName; // 名字
  final bool showProgressBar; // 进度条
  final bool showReviewNumber; // 回顾号
  final bool showProgress; // 进度
  final bool showSeries; // 系列

  const AnimeGridCoverConfig({
    this.showCover = false,
    this.showName = false,
    this.showProgress = false,
    this.showProgressBar = false,
    this.showReviewNumber = false,
    this.showSeries = false,
  });

  factory AnimeGridCoverConfig.allShow() => const AnimeGridCoverConfig(
        showCover: true,
        showName: true,
        showProgress: true,
        showProgressBar: true,
        showReviewNumber: true,
        showSeries: true,
      );

  factory AnimeGridCoverConfig.noneShow() => const AnimeGridCoverConfig(
        showCover: false,
        showName: false,
        showProgress: false,
        showProgressBar: false,
        showReviewNumber: false,
        showSeries: false,
      );

  factory AnimeGridCoverConfig.onlyShowCover() => const AnimeGridCoverConfig(
        showCover: true,
        showName: false,
        showProgress: false,
        showProgressBar: false,
        showReviewNumber: false,
        showSeries: false,
      );

  bool get isOnlyShowCover =>
      showCover &&
      !showName &&
      !showProgress &&
      showProgressBar &&
      !showReviewNumber &&
      !showSeries;

  AnimeGridCoverConfig copyWith({
    bool? showCover,
    bool? showName,
    bool? showProgress,
    bool? showProgressBar,
    bool? showReviewNumber,
    bool? showSeries,
  }) {
    return AnimeGridCoverConfig(
      showCover: showCover ?? this.showCover,
      showName: showName ?? this.showName,
      showProgress: showProgress ?? this.showProgress,
      showProgressBar: showProgressBar ?? this.showProgressBar,
      showReviewNumber: showReviewNumber ?? this.showReviewNumber,
      showSeries: showSeries ?? this.showSeries,
    );
  }
}
