import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/release_info.dart';
import 'package:flutter_test_future/utils/log.dart';

import 'release_checker.dart';

class GithubReleaseChecker extends ReleaseChecker {
  GithubReleaseChecker({
    required this.dio,
    required super.url,
  });
  final Dio dio;

  @override
  Future<ReleaseInfo?> fetchLatestRelease() async {
    try {
      final resp = await dio.get(url);
      return ReleaseInfo.fromGithub(resp.data);
    } catch (err, stack) {
      logger.error('获取GitHub最新版本失败：$err', stackTrace: stack);
      return null;
    }
  }
}
