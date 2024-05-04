import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/logo.dart';
import 'package:flutter_test_future/models/enum/project_uri.dart';
import 'package:flutter_test_future/pages/upgrade/controllers/app_upgrade_controller.dart';
import 'package:flutter_test_future/models/enum/load_status.dart';
import 'package:flutter_test_future/pages/changelog/view.dart';
import 'package:flutter_test_future/values/assets.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:flutter_test_future/widgets/svg_asset_icon.dart';
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
                  onTap: () => appUpgradeLogic.getLatestVersion(context,
                      showToast: true),
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
                title: const Text("蓝奏云下载"),
                subtitle: const Text("密码：eocv"),
                trailing: const Icon(EvaIcons.externalLink),
                onTap: () => ProjectUri.lanzou.launch(context)),
            ListTile(
                title: const Text("QQ 交流群"),
                subtitle: const Text("414226908"),
                trailing: const Icon(EvaIcons.externalLink),
                onTap: () => ProjectUri.qqGroup.launch(context)),
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
          onPressed: () => ProjectUri.github.launch(context),
          icon: SvgAssetIcon(
            assetPath: Assets.iconsGithub,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        IconButton(
          splashRadius: 20,
          onPressed: () => ProjectUri.gitee.launch(context),
          icon: const SvgAssetIcon(
            assetPath: Assets.iconsGitee,
            color: Color.fromRGBO(187, 33, 36, 1),
          ),
        )
      ],
    );
  }
}
