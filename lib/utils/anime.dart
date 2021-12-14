import 'package:flutter_test_future/utils/episode.dart';

class Anime {
  String name;
  String tag;
  List<Episode> episodes = [];
  int endEpisode = 0;
  int lastCheckedEpisode = 0;

  Anime(this.name, {required this.tag});

  void setEndEpisode(int newEndEpisode) {
    // 如果新设置的最后一集<原最后一集，则删除后面多余的集数
    if (newEndEpisode < endEpisode) {
      for (int i = 0; i < endEpisode - newEndEpisode; ++i) {
        episodes.removeLast();
      }
    } else {
      // 每次更改最后一集时，是在原来集数+1的基础上开始
      for (int i = endEpisode + 1; i <= newEndEpisode; ++i) {
        episodes.add(Episode(i)); // 添加第i集
      }
    }
    endEpisode = newEndEpisode;
  }

  // 设置第number集的时间
  void setEpisodeDateTimeNow(int number) {
    // 更新最后观看的第几集(注意先设置，然后number--)
    if (number > lastCheckedEpisode) lastCheckedEpisode = number;

    number--; // number--后才是数组对应的索引
    episodes[number].setDateTimeNow();
  }

  void modifyName(String newName) {
    name = newName;
  }

  void cancelEpisodeDateTime(int number) {
    number--; // number--后才是数组对应的索引
    episodes[number].cancelDateTime();
  }

  String getEpisodeDate(int number) {
    number--;
    return episodes[number].getDate().toString();
  }

  String getPace() {
    return "$lastCheckedEpisode/${episodes.length}";
  }

  void setTag(String newTag) {
    tag = newTag;
  }

  String getTag() {
    return tag;
  }

  bool isChecked(int number) {
    number--;
    return episodes[number].isChecked();
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
    for (int i = 0; i < episodes.length; ++i) {
      ret.write("第${i + 1}集：");
      ret.writeln(
          episodes[i].dateTime != null ? "√ ${episodes[i].getDate()}" : "×");
    }
    return ret.toString();
  }
}
