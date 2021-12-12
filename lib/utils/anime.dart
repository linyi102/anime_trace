import 'package:flutter_test_future/utils/episode.dart';

class Anime {
  String name;
  List<Episode> episodes = [Episode(0)]; // 第0集。使得episodes[1]表示第1集
  int curEpisodeCnt = 0;

  Anime(this.name);

  void addEpisode() {
    episodes.add(Episode(++curEpisodeCnt));
  }

  void setEpisodeDateTimeNow(int number) {
    episodes[number].setDateTimeNow();
  }

  /*
  anime_name
  第1集：√ 2021/12/8
  第2集：×
  第3集：×
   */
  @override
  String toString() {
    StringBuffer ret = StringBuffer();
    ret.writeln(name);
    for (int i = 1; i < episodes.length; ++i) {
      ret.write("第$i集：");
      ret.writeln(
          episodes[i].dateTime != null ? "√ ${episodes[i].getDate()}" : "×");
    }
    return ret.toString();
  }
}
