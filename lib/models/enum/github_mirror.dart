typedef SpeedUrl = String Function(String url);

enum GithubMirror {
  github('github.com', GithubSpeedType.origin),
  ghh233('gh.h233.eu.org', GithubSpeedType.addPrefix),
  ghproxy('mirror.ghproxy.com', GithubSpeedType.addPrefix),
  moeyy('github.moeyy.xyz', GithubSpeedType.addPrefix),
  ixnic('download.ixnic.net', GithubSpeedType.replaceHost);

  final String host;
  final GithubSpeedType speedType;
  const GithubMirror(this.host, this.speedType);

  String speedUrl(String url) {
    switch (speedType) {
      case GithubSpeedType.origin:
        return url;
      case GithubSpeedType.addPrefix:
        return _addPrefix(url, host);
      case GithubSpeedType.replaceHost:
        return _replaceHost(url, host);
    }
  }
}

enum GithubSpeedType {
  origin,
  addPrefix,
  replaceHost;
}

String _replaceHost(String url, String host) {
  return url.replaceFirst('github.com', host);
}

String _addPrefix(String url, String host) {
  return 'https://$host/$url';
}
