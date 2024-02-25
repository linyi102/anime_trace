enum WebDAVWebSite {
  common('WebDAV', '', ''),
  jianguoyun('坚果云', 'https://dav.jianguoyun.com/dav/', 'jianguoyun'),
  infiniCloud('InfiniCLOUD', 'https://toi.teracloud.jp/dav/', 'teracloud');

  final String title;
  final String url;
  final String urlKeyword;
  const WebDAVWebSite(this.title, this.url, this.urlKeyword);

  static WebDAVWebSite getWebDAVWebSiteByUrlKeyword(String url) {
    for (final website in WebDAVWebSite.values) {
      if (website == WebDAVWebSite.common) continue;

      if (url.contains(website.urlKeyword)) {
        return website;
      }
    }
    return WebDAVWebSite.common;
  }
}
