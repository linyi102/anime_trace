class UserCollection {
  String title; // 标题，例如「想看」
  String word; // url尾部单词，例如「wish」

  UserCollection({
    required this.title,
    required this.word,
  });

  @override
  String toString() => 'UserCollection(title: $title, word: $word)';
}
