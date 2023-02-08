import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

Widget loadingWidget(BuildContext context) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: MediaQuery.of(context).size.height,
    key: UniqueKey(),
    color: ThemeUtil.getScaffoldBackgroundColor(),
    // child: const Center(child: Text("加载数据中...")),
  );
}
