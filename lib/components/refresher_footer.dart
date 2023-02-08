import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefresherFooter extends StatelessWidget {
  const RefresherFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFooter(
      builder: (BuildContext context, LoadStatus? mode) {
        Widget body;
        if (mode == LoadStatus.idle) {
          body = const Text("上拉加载更多");
        } else if (mode == LoadStatus.loading) {
          body = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 10,
                width: 10,
                child: const CircularProgressIndicator(strokeWidth: 2),
                margin: const EdgeInsets.only(right: 10),
              ),
              const Text("加载更多中..."),
            ],
          );
        } else if (mode == LoadStatus.failed) {
          body = const Text("加载失败！点击重试！");
        } else if (mode == LoadStatus.canLoading) {
          body = const Text("释放加载更多");
        } else {
          body = const Text("已经到底了");
        }
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: Center(child: body),
        );
      },
    );
  }
}
