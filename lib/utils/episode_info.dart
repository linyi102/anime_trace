class EpisodeInfo {
  int number; // 第几集
  DateTime? dateTime; // 完成日期，若未完成，则是null

  EpisodeInfo(this.number);

  void setDateTimeNow() {
    dateTime = DateTime.now();
  }

  String getDate() {
    return "${dateTime!.year}/${dateTime!.month}/${dateTime!.day}";
  }
}
