import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/classes/filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter/material.dart';

class ClimbAnimeUtil {
  // 根据动漫网址中的关键字来判断来源
  static ClimbWebstie? getClimbWebsiteByAnimeUrl(String animeUrl) {
    for (var climbWebsite in climbWebsites) {
      // 存在animeUrl以https://www.agemys.cc/和https://www.agemys.com/开头的，因此都需要解释为age动漫源
      // 因此采用contain keyword，而不是startWith baseUrl
      // if (animeUrl.startsWith(climbWebsite.baseUrl)) {
      //   return climbWebsite;
      // }
      if (animeUrl.contains(climbWebsite.keyword)) {
        return climbWebsite;
      }
    }
  }

  // 根据过滤查询目录动漫
  static Future<List<Anime>> climbDirectory(Filter filter) async {
    Climb climb = ClimbYhdm();
    List<Anime> directory = await climb.climbDirectory(filter);
    return directory;
  }

  // 多搜索源。根据关键字搜索动漫
  static Future<List<Anime>> climbAnimesByKeywordAndWebSite(
      String keyword, ClimbWebstie climbWebStie) async {
    List<Anime> climbAnimes = [];
    climbAnimes = await climbWebStie.climb.climbAnimesByKeyword(keyword);
    return climbAnimes;
  }

  // 进入该动漫网址，获取详细信息
  static Future<Anime> climbAnimeInfoByUrl(Anime anime) async {
    if (anime.animeUrl.isEmpty) {
      debugPrint("无来源，无法更新，返回旧动漫对象");
      return anime;
    }
    Climb? climb = getClimbWebsiteByAnimeUrl(anime.animeUrl)?.climb;
    if (climb != null) anime = await climb.climbAnimeInfo(anime);
    return anime;
  }
}
