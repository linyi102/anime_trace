import 'release_asset.dart';

class ReleaseInfo {
  final String version;
  final String releaseNotes;
  final List<ReleaseAsset> assets;
  static const String defaultVersion = '0.0.0';

  ReleaseInfo({
    this.version = defaultVersion,
    this.releaseNotes = '',
    this.assets = const [],
  });

  factory ReleaseInfo.fromGithub(Map<String, dynamic> json) {
    final assets = json['assets'];
    return ReleaseInfo(
      version: json['tag_name'] ?? ReleaseInfo.defaultVersion,
      releaseNotes: json['body'] ?? '',
      assets: assets is List
          ? assets
              .map((e) => ReleaseAsset(
                    url: e['browser_download_url'] ?? '',
                    size: e['size'] ?? 0,
                  ))
              .where((e) => e.url.isNotEmpty)
              .toList()
          : [],
    );
  }

  @override
  String toString() {
    return 'ReleaseInfo{version: $version, releaseNotes: $releaseNotes, assets: $assets}';
  }
}
