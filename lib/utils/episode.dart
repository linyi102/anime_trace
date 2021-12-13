class Episode {
  final int _number; // 第几集
  DateTime? _dateTime; // 完成日期，若未完成，则是null

  Episode(this._number);

  void setDateTimeNow() {
    _dateTime = DateTime.now();
  }

  void cancelDateTime() {
    _dateTime = null;
  }

  int get number => _number;
  DateTime? get dateTime => _dateTime;

  String getDate() {
    if (_dateTime == null) return "";
    return "${_dateTime!.year}/${_dateTime!.month}/${_dateTime!.day}";
  }
}
