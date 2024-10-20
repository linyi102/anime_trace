extension StringExtension on String? {
  bool get isNull => this == null;

  bool get isBlank => !isNull && this!.trim().isEmpty;

  bool get isNullOrBlank => isNull || isBlank;
}
