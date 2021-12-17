class HistorySql {
  String date;
  int animeId;
  String animeName;
  int episodeNumber;

  HistorySql(
      {required this.date,
      required this.animeId,
      required this.animeName,
      required this.episodeNumber});

  String getDate() {
    // 2022-09-04 00:00:00.000Z
    String res = date.split(' ')[0]; // 2022-09-04
    return res.replaceAll("-", "/"); // 2022/09/04
  }

  @override
  String toString() {
    return "$date, $animeName, $episodeNumber";
  }
}
