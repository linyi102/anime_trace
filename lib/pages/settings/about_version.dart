import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/logo.dart';
import 'package:flutter_test_future/controllers/app_upgrade_controller.dart';
import 'package:flutter_test_future/models/enum/load_status.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:get/get.dart';
import 'package:simple_icons/simple_icons.dart';

class AboutVersion extends StatefulWidget {
  const AboutVersion({Key? key}) : super(key: key);

  @override
  _AboutVersionState createState() => _AboutVersionState();
}

class _AboutVersionState extends State<AboutVersion> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("关于版本"),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Column(
                children: [
                  const Logo(),
                  Text("当前版本: ${AppUpgradeController.to.curVersion}"),
                  _buildWebsiteIconsRow(context),
                ],
              ),
              GetBuilder<AppUpgradeController>(
                init: AppUpgradeController.to,
                initState: (_) {},
                builder: (appUpgradeLogic) {
                  return ListTile(
                    onTap: () =>
                        appUpgradeLogic.getLatestVersion(showToast: true),
                    title: const Text("检查更新"),
                    trailing: appUpgradeLogic.status == LoadStatus.loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 3))
                        : null,
                  );
                },
              ),
              ListTile(
                  title: const Text("更新日志"),
                  trailing: const Icon(Icons.open_in_new_outlined),
                  onTap: () {
                    LaunchUrlUtil.launch(
                        context: context,
                        uriStr: "https://www.yuque.com/linyi517/fzfxr0",
                        inApp: false);
                  }),
              ListTile(
                  title: const Text("下载地址"),
                  subtitle: const Text("密码：eocv"),
                  trailing: const Icon(Icons.open_in_new_outlined),
                  onTap: () {
                    LaunchUrlUtil.launch(
                        context: context,
                        uriStr:
                            "https://wwc.lanzouw.com/b01uyqcrg?password=eocv",
                        inApp: false);
                  }),
              ListTile(
                  title: const Text("QQ 交流群"),
                  subtitle: const Text("414226908"),
                  trailing: const Icon(Icons.open_in_new_outlined),
                  onTap: () {
                    LaunchUrlUtil.launch(
                        context: context,
                        uriStr: "https://jq.qq.com/?_wv=1027&k=qOpUIx7x",
                        inApp: false);
                  }),
            ],
          ),
        ],
      ),
    );
  }

  Row _buildWebsiteIconsRow(BuildContext context) {
    return Row(
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
    );
  }
}
