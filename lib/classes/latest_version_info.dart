class LatestVersionInfo {
  String version;
  String desc;
  String downloadUrl;

  LatestVersionInfo(this.version, {this.desc = "", this.downloadUrl = ""});

  @override
  String toString() {
    return "[版本号：$version, 描述：$desc, 下载链接：$downloadUrl]";
  }
}
