import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/logo.dart';

import 'package:flutter_test_future/components/update_hint.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_icons/simple_icons.dart';

class AboutVersion extends StatefulWidget {
  const AboutVersion({Key? key}) : super(key: key);

  @override
  _AboutVersionState createState() => _AboutVersionState();
}

class _AboutVersionState extends State<AboutVersion> {
  late PackageInfo packageInfo;
  bool loadOk = false;
  bool checkLatestVersion = false;

  @override
  void initState() {
    super.initState();
    Future(() {
      return PackageInfo.fromPlatform();
    }).then((value) {
      packageInfo = value;
      loadOk = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("关于版本"),
      ),
      body: Stack(
        children: [
          ListView(
            children: _showLVC(),
          ),
          // 改变checkLatestVersion后setState，并无法重新渲染该组件
          // UpdateHint(
          //   checkLatestVersion: checkLatestVersion, // 不先检查，知道点击检查更新后，进行检查
          //   forceShowUpdateDialog: true,
          // )
          // 改用以下方式
          checkLatestVersion
              ? const UpdateHint(
                  checkLatestVersion: true, forceShowUpdateDialog: true)
              : Container()
        ],
      ),
    );
  }

  _showLVC() {
    List<Widget> lvc = [];

    lvc.add(Column(
      children: [
        const Logo(),
        loadOk ? Text("当前版本: ${packageInfo.version}") : const Text(""),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () {
                  LaunchUrlUtil.launch(
                      context: context,
                      uriStr: "https://github.com/linyi102/anime_trace");
                },
                icon: Icon(
                  SimpleIcons.github,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                )),
            IconButton(
              onPressed: () {
                LaunchUrlUtil.launch(
                    context: context,
                    uriStr: "https://gitee.com/linyi517/anime_trace",
                    inApp: false);
              },
              icon: const Icon(
                SimpleIcons.gitee,
                color: Color.fromRGBO(187, 33, 36, 1),
              ),
            )
          ],
        ),
      ],
    ));
    lvc.add(ListTile(
        onTap: () {
          if (checkLatestVersion) {
            checkLatestVersion = false;
            setState(() {});
          }
          // 必须推迟，否则可能会合并setState
          // 然后再渲染有更新对话框的页面
          Future.delayed(const Duration(milliseconds: 200)).then((value) {
            ToastUtil.showText("正在获取最新版本");
            checkLatestVersion = true;
            setState(() {});
          });
        },
        title: const Text("检查更新")));
    lvc.add(ListTile(
        title: const Text("更新日志"),
        trailing: const Icon(Icons.open_in_new_outlined),
        onTap: () {
          LaunchUrlUtil.launch(
              context: context,
              uriStr: "https://www.yuque.com/linyi517/fzfxr0",
              inApp: false);
        }));
    lvc.add(ListTile(
        title: const Text("下载地址"),
        subtitle: const Text("密码：eocv"),
        trailing: const Icon(Icons.open_in_new_outlined),
        onTap: () {
          LaunchUrlUtil.launch(
              context: context,
              uriStr: "https://wwc.lanzouw.com/b01uyqcrg?password=eocv",
              inApp: false);
        }));
    lvc.add(ListTile(
        title: const Text("QQ 交流群"),
        subtitle: const Text("414226908"),
        trailing: const Icon(Icons.open_in_new_outlined),
        onTap: () {
          LaunchUrlUtil.launch(
              context: context,
              uriStr: "https://jq.qq.com/?_wv=1027&k=qOpUIx7x",
              inApp: false);
        }));
    return lvc;
  }
}
