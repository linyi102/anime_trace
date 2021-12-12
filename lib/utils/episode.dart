class Episode {
  int number; // 第几集
  DateTime? dateTime; // 完成日期，若未完成，则是null

  Episode(this.number);

  void setDateTimeNow() {
    dateTime = DateTime.now();
  }

  String getDate() {
    if (dateTime == null) return "";
    return "${dateTime!.year}/${dateTime!.month}/${dateTime!.day}";
  }
}
