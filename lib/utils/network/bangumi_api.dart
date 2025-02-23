import 'dart:io';

import 'package:animetrace/controllers/app_upgrade_controller.dart';

class BangumiApi {
  static Map<String, dynamic> headers = {
    'user-agent':
        'linyi102/anime_trace/${AppUpgradeController.to.curVersion} (${Platform.operatingSystem}) (https://github.com/linyi102/anime_trace)',
    'Cookie': 'chii_searchDateLine=1729417788',
  };

  static String baseUrl = 'https://api.bgm.tv';

  /// 每日放送
  static String calendar = '$baseUrl/calendar';

  /// 条目
  static String subject(String subjectId) => '$baseUrl/v0/subjects/$subjectId';

  /// 章节
  static String episodes = '$baseUrl/v0/episodes';

  /// 角色
  static String characters(String subjectId) =>
      '$baseUrl/v0/subjects/$subjectId/characters';

  /// 人物
  static String persons(String subjectId) =>
      '$baseUrl/v0/subjects/$subjectId/persons';
}
