class SortMode<T> {
  final String label;
  final int storeIndex;
  final List<T> Function(List<T> list, bool isReverse) sort;

  SortMode({
    required this.label,
    required this.storeIndex,
    required this.sort,
  });
}
