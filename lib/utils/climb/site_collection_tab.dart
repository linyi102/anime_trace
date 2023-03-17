/// 网站收藏的标签页(想看、看过...)
class SiteCollectionTab {
  String title; // 标题，例如「想看」
  String word; // url尾部单词，例如「wish」

  SiteCollectionTab({
    required this.title,
    required this.word,
  });

  @override
  String toString() => 'SiteCollectionTab(title: $title, word: $word)';
}
