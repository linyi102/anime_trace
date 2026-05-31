import 'package:animetrace/controllers/setting_service.dart';
import 'package:get/get.dart';

class HostEntry {
  final String from;
  final String to;

  const HostEntry(this.from, this.to);
}

class HostService extends GetxService {
  static HostService get to => Get.find();

  String _content = '';

  String get content => _content;

  List<HostEntry> _hosts = [];

  @override
  void onInit() async {
    super.onInit();
    _content = await SettingService.to.getHosts();
    _hosts = parseHosts(_content);
  }

  /// 解析 host 转发
  ///
  /// 每行格式：
  /// - to from
  /// - to from1 from2
  List<HostEntry> parseHosts(String _content) {
    final result = <HostEntry>[];

    for (final rawLine in _content.split('\n')) {
      final line = rawLine.trim();

      // 忽略空行和注释
      if (line.isEmpty || line.startsWith('#')) continue;

      // 去除行尾注释
      final pureLine = line.split('#').first.trim();
      if (pureLine.isEmpty) continue;

      final parts = pureLine.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;

      final to = parts.first;
      for (final from in parts.skip(1)) {
        result.add(HostEntry(from, to));
      }
    }

    return result;
  }

  void updateHosts(String _content) {
    this._content = _content;
    _hosts = parseHosts(_content);
    SettingService.to.setHosts(_content);
  }

  String tryForwardUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return url;

    final host = uri.host.toLowerCase();
    for (final entry in _hosts) {
      if (hostMatches(host, entry.from)) {
        return uri.replace(host: entry.to).toString();
      }
    }

    return url;
  }

  bool hostMatches(String host, String pattern) {
    if (pattern.contains('*')) {
      final regex = RegExp(
        '^${pattern.split('*').map(RegExp.escape).join('.*')}\$',
        caseSensitive: false,
      );
      return regex.hasMatch(host);
    }

    return host == pattern;
  }
}
