import 'dart:io';

import 'package:animetrace/controllers/setting_service.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:get/get.dart';

class ProxyService extends GetxService {
  static ProxyService get to => Get.find();

  ProxyType _type = SettingService.to.getProxyType();

  ProxyType get type => _type;

  String _proxy = SettingService.to.getProxy();

  String get proxy => _proxy;

  bool _proxyInitialized = false;

  @override
  void onInit() {
    super.onInit();
    loadProxy();
  }

  void loadProxy({ProxyType? type, String? proxy}) async {
    if (type != null) {
      _type = type;
      SettingService.to.setProxyType(type);
    }
    if (proxy != null) {
      _proxy = proxy;
      SettingService.to.setProxy(proxy);
    }

    final fullProxy = switch (_type) {
      ProxyType.direct => _type.value,
      _ => '${_type.value} $_proxy'
    };

    if (!_proxyInitialized) {
      SocksProxy.initProxy(
        proxy: fullProxy,
        onCreate: (client) {
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
            // 次元城图链域名
            final allowedHosts = ['img.idti.cn', 'img.cycimg.me'];
            return allowedHosts.contains(host);
          };
        },
      );
      _proxyInitialized = true;
    } else {
      SocksProxy.setProxy(fullProxy);
    }
  }
}

enum ProxyType {
  direct('DIRECT'),
  http('PROXY'),
  socks5('SOCKS5'),
  socks4('SOCKS4'),
  ;

  final String value;
  const ProxyType(this.value);

  static ProxyType? fromValue(String value) {
    final index = values.indexWhere((e) => e.value == value);
    return index >= 0 ? values[index] : null;
  }
}

extension ProxyTypeExt on ProxyType {
  String get label => switch (this) {
        ProxyType.direct => '不代理',
        ProxyType.http => 'HTTP',
        ProxyType.socks5 => 'Socks5',
        ProxyType.socks4 => 'Socks4',
      };
}
