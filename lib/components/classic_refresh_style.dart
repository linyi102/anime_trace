import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MyClassicHeader extends StatelessWidget {
  const MyClassicHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // return const ClassicHeader(
    //   idleText: "上拉刷新",
    //   releaseText: "释放刷新",
    //   refreshingText: "加载数据中...",
    //   completeText: "加载成功",
    //   failedText: "加载失败！",
    // );
    return const MaterialClassicHeader();
  }
}

class MyClassicFooter extends StatelessWidget {
  const MyClassicFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClassicFooter(
      idleText: "上拉加载更多",
      canLoadingText: "释放加载更多",
      loadingText: "加载更多数据中...",
      noDataText: "已经到底了",
      failedText: "加载失败！点击重试！",
    );
  }
}
