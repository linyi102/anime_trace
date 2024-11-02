import 'package:flutter_test_future/models/release_info.dart';

abstract class ReleaseChecker {
  final String url;

  ReleaseChecker({required this.url});

  Future<ReleaseInfo?> fetchLatestRelease();
}
