import 'package:animetrace/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/controllers/app_upgrade_controller.dart';
import 'package:animetrace/modules/load_status/status.dart';
import 'package:animetrace/pages/changelog/view.dart';
import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:animetrace/widgets/rotated_logo.dart';
import 'package:animetrace/widgets/svg_asset_icon.dart';
import 'package:get/get.dart';

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
      body: CommonScaffoldBody(child: _buildBody(context)),
    );
  }

  Stack _buildBody(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: RotatedLogo(size: 72),
                ),
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
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.4))
                      : null,
                );
              },
            ),
            ListTile(
                title: const Text("更新日志"),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChangelogPage()));
                }),
            ListTile(
                title: const Text("下载地址"),
                subtitle: const Text("密码：eocv"),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () {
                  LaunchUrlUtil.launch(
                      context: context,
                      uriStr: "https://wwc.lanzouw.com/b01uyqcrg?password=eocv",
                      inApp: false);
                }),
            ListTile(title: const Text("导出日志"), onTap: logger.shareLogs),
            ListTile(
                title: const Text("QQ 交流群"),
                subtitle: const Text("414226908"),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () {
                  LaunchUrlUtil.launch(
                      context: context,
                      uriStr: "https://jq.qq.com/?_wv=1027&k=qOpUIx7x",
                      inApp: false);
                }),
          ],
        ),
      ],
    );
  }

  Row _buildWebsiteIconsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          splashRadius: 20,
          onPressed: () {
            LaunchUrlUtil.launch(
                context: context,
                uriStr: "https://github.com/linyi102/anime_trace");
          },
          icon: SvgAssetIcon(
            assetPath: Assets.icons.github,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        IconButton(
          splashRadius: 20,
          onPressed: () {
            LaunchUrlUtil.launch(
                context: context,
                uriStr: "https://gitee.com/linyi517/anime_trace",
                inApp: false);
          },
          icon: SvgAssetIcon(
            assetPath: Assets.icons.gitee,
            color: const Color.fromRGBO(187, 33, 36, 1),
          ),
        )
      ],
    );
  }
}
