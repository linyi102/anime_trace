class NoteFilter {
  int? animeId;
  String animeNameKeyword;
  String noteContentKeyword;

  NoteFilter(
      {this.animeNameKeyword = "", this.noteContentKeyword = "", this.animeId});

  bool hasFilter() =>
      animeNameKeyword.isNotEmpty || noteContentKeyword.isNotEmpty;

  String get valueKeyStr => toString();

  @override
  String toString() =>
      'NoteFilter(animeId: $animeId, animeNameKeyword: $animeNameKeyword, noteContentKeyword: $noteContentKeyword)';
}
