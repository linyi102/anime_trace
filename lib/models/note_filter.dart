class NoteFilter {
  String animeNameKeyword;
  String noteContentKeyword;

  NoteFilter({this.animeNameKeyword = "", this.noteContentKeyword = ""});

  bool hasFilter() =>
      animeNameKeyword.isNotEmpty || noteContentKeyword.isNotEmpty;

  @override
  String toString() {
    return "NoteFilter[animeNameKeyword=$animeNameKeyword, noteContentKeyword=$noteContentKeyword]";
  }
}
