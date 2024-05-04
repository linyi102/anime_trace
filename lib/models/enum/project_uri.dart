import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';

enum ProjectUri {
  qqGroup(
    'qq 群',
    'https://jq.qq.com/?_wv=1027&k=qOpUIx7x',
    isDownloadChannel: true,
  ),
  github(
    'GitHub',
    'https://github.com/linyi102/anime_trace',
    isDownloadChannel: true,
  ),
  gitee(
    'Gitee',
    'https://gitee.com/linyi517/anime_trace',
    isDownloadChannel: true,
  ),
  lanzou(
    '蓝奏云',
    'https://wwc.lanzouw.com/b01uyqcrg?password=eocv',
    isDownloadChannel: true,
  ),
  baiduyun(
    '百度云',
    'https://pan.baidu.com/s/1NHJAOnOP5HA1_AM_ZujBSQ?pwd=eocv',
    isDownloadChannel: true,
  ),
  aliyun(
    '阿里云',
    'https://www.alipan.com/s/PWKrRaDN8uj',
    isDownloadChannel: true,
  );

  final String label;
  final String uri;
  final bool isDownloadChannel;
  const ProjectUri(this.label, this.uri, {this.isDownloadChannel = false});
}

extension ProjectUriHelper on ProjectUri {
  launch(BuildContext context) {
    LaunchUrlUtil.launch(
      context: context,
      uriStr: uri,
      inApp: false,
    );
  }
}
