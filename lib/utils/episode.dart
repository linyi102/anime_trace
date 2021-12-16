class Episode {
  final int _number; // 第几集
  String? dateTime; // 完成日期，若未完成，则是null

  Episode(this._number, {this.dateTime});

  // void setDateTimeNow() {
  //   dateTime = DateTime.now();
  // }

  void cancelDateTime() {
    dateTime = null;
  }

  int get number => _number;

  bool isChecked() {
    return dateTime == null ? false : true;
  }

  String getDate() {
    // if (dateTime == null) return "";
    // return "${dateTime!.year}/${dateTime!.month}/${dateTime!.day}";
    if (dateTime == null) return "";
    return dateTime!.split(' ')[0];
  }
}
