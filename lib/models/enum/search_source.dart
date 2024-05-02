import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/utils/global_data.dart';

enum AnimeSource {
  yinghua('樱花动漫', 1),
  age('AGE动漫', 2),
  ciyuan('次元城动漫', 3),
  douban('豆瓣', 4),
  qu('趣动漫', 5),
  quqi('曲奇动漫', 6),
  bangumi('Bangumi', 7),
  omofun('Omofun', 8),
  aimi('艾米动漫', 9);

  final String label;
  final int value;
  const AnimeSource(this.label, this.value);

  static ClimbWebsite? getWebsite(AnimeSource source) {
    switch (source) {
      case AnimeSource.yinghua:
        return yhdmClimbWebsite;
      case AnimeSource.age:
        return ageClimbWebsite;
      case AnimeSource.ciyuan:
        return cycClimbWebsite;
      case AnimeSource.douban:
        return doubanClimbWebsite;
      case AnimeSource.qu:
        return quClimbWebsite;
      case AnimeSource.quqi:
        return quqiClimbWebsite;
      case AnimeSource.bangumi:
        return bangumiClimbWebsite;
      case AnimeSource.omofun:
        return omofunClimbWebsite;
      case AnimeSource.aimi:
        return aimiWebsite;
      default:
        return null;
    }
  }
}
