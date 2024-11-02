class ReleaseAsset {
  final String url;
  final int size;

  const ReleaseAsset({
    required this.url,
    required this.size,
  });

  @override
  String toString() => 'ReleaseAsset(url: $url, size: $size)';
}
