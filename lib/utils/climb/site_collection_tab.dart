/// 网站收藏的标签页(想看、看过...)
class SiteCollectionTab<T> {
  /// 标题
  String title;

  /// 标签标识
  T identity;

  SiteCollectionTab({
    required this.title,
    required this.identity,
  });

  @override
  String toString() => 'SiteCollectionTab(title: $title, identity: $identity)';
}
