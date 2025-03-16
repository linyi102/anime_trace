extension ListSortHelper<T> on List<T> {
  List<T> sorted([int Function(T a, T b)? compare]) {
    final copied = [...this]..sort(compare);
    return copied;
  }
}
