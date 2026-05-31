import 'package:animetrace/controllers/host_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostController.parseHosts', () {
    test('parses multiple source hosts from one line', () {
      final controller = HostService();

      final hosts = controller.parseHosts('''
bangumi.one bgm.tv bangumi.tv
lain.bangumi.one lain.bgm.tv
''');

      expect(hosts, hasLength(3));
      expect(hosts[0].to, 'bangumi.one');
      expect(hosts[0].from, 'bgm.tv');
      expect(hosts[1].to, 'bangumi.one');
      expect(hosts[1].from, 'bangumi.tv');
      expect(hosts[2].to, 'lain.bangumi.one');
      expect(hosts[2].from, 'lain.bgm.tv');
    });

    test('ignores empty lines, comments, inline comments, and invalid lines',
        () {
      final controller = HostService();

      final hosts = controller.parseHosts('''
# full line comment

invalid-only-one-part
bangumi.one bgm.tv # inline comment
lain.bangumi.one lain.bgm.tv
''');

      expect(hosts, hasLength(2));
      expect(hosts[0].to, 'bangumi.one');
      expect(hosts[0].from, 'bgm.tv');
      expect(hosts[1].to, 'lain.bangumi.one');
      expect(hosts[1].from, 'lain.bgm.tv');
    });
  });

  group('HostController.hostMatches', () {
    test('matches exact hosts', () {
      final controller = HostService();

      expect(controller.hostMatches('bgm.tv', 'bgm.tv'), isTrue);
      expect(controller.hostMatches('lain.bgm.tv', 'bgm.tv'), isFalse);
      expect(controller.hostMatches('bangumi.tv', 'bgm.tv'), isFalse);
    });

    test('matches wildcard subdomain patterns', () {
      final controller = HostService();

      expect(controller.hostMatches('bgm.tv', '*.bgm.tv'), isFalse);
      expect(controller.hostMatches('lain.bgm.tv', '*.bgm.tv'), isTrue);
      expect(controller.hostMatches('img.lain.bgm.tv', '*.bgm.tv'), isTrue);
      expect(controller.hostMatches('bangumi.tv', '*.bgm.tv'), isFalse);
    });

    test('matches general wildcard patterns case-insensitively', () {
      final controller = HostService();

      expect(controller.hostMatches('img.bgm.tv', '*.bgm.*'), isTrue);
      expect(controller.hostMatches('IMG.BGM.TV', '*.bgm.*'), isTrue);
      expect(controller.hostMatches('bgm.tv', '*'), isTrue);
      expect(controller.hostMatches('bangumi.tv', 'bgm.*'), isFalse);
    });
  });
}
