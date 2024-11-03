class ReviewInfo {
  final int number;
  final int checked;
  final int total;
  final String minDate;
  final String maxDate;
  ReviewInfo({
    required this.number,
    required this.checked,
    required this.total,
    required this.minDate,
    required this.maxDate,
  });

  factory ReviewInfo.empty({required int number, required int total}) =>
      ReviewInfo(
          number: number, checked: 0, total: total, minDate: '', maxDate: '');
}
