import 'dart:io';

import 'package:flutter_test_future/controllers/app_upgrade_controller.dart';

class BangumiApi {
  static Map<String, dynamic> headers = {
    'user-agent':
        'linyi102/anime_trace/${AppUpgradeController.to.curVersion} (${Platform.operatingSystem}) (https://github.com/linyi102/anime_trace)',
    'Cookie': 'chii_searchDateLine=1729417788',
  };

  static String baseUrl = 'https://api.bgm.tv';

  static String calendar = '$baseUrl/calendar';
  static String subjectCharacters(String subjectId) =>
      '$baseUrl/v0/subjects/$subjectId/characters';
  static String subjectPersons(String subjectId) =>
      '$baseUrl/v0/subjects/$subjectId/persons';
}
