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
        ProxyType.direct => '直连',
        ProxyType.http => 'HTTP',
        ProxyType.socks5 => 'Socks5',
        ProxyType.socks4 => 'Socks4',
      };
}
