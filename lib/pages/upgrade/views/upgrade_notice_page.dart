import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test_future/pages/changelog/view.dart';
import 'package:flutter_test_future/pages/upgrade/controllers/app_upgrade_controller.dart';
import 'package:flutter_test_future/pages/upgrade/views/upgrade_method_page.dart';
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';
import 'package:flutter_test_future/widgets/limit_width_center.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class UpgradeNoticePage extends StatefulWidget {
  const UpgradeNoticePage({super.key});

  @override
  State<UpgradeNoticePage> createState() => UpgradeNoticePageState();
}

class UpgradeNoticePageState extends State<UpgradeNoticePage> {
  final upgradeController = AppUpgradeController.to;
  final emojis = ['🤩', '🥰', '🥳', '🔥', '🎉', '🌟', '🌈'];
  late final emoji = emojis[Random().nextInt(emojis.length)];

  @override
  Widget build(BuildContext context) {
    upgradeController.latestRelease?.body = '''
1. 新增：按首播时间排列动漫
2. 新增：本地搜索完善过滤条件（清单、标签、星级、搜索源、首播时间、播放状态、地区、类别）
3. 新增：支持忽略推荐系列
4. 优化：更新封面提示直接展示预览图
5. 优化：网络图片加载失败时支持单击退出
6. 优化：自定义搜索源地址后，更新动漫时会自动获取最新链接
7. 修复：次元城无法搜索
''';
    upgradeController.latestRelease?.body = '''
### 新增
- 按首播时间排列动漫
- 本地搜索完善过滤条件（清单、标签、星级、搜索源、首播时间、播放状态、地区、类别）
- 支持忽略推荐系列

### 优化
- 优化：更新封面提示直接展示预览图
- 优化：网络图片加载失败时支持单击退出
- 优化：自定义搜索源地址后，更新动漫时会自动获取最新链接

### 修复
- 修复：次元城无法搜索
''';
    return GetBuilder(
      init: AppUpgradeController.to,
      builder: (_) => SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: AlignLimitedBox(
                    maxWidth: AppTheme.formMaxWidth,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNewVersionTitle(),
                        const SizedBox(height: 20),
                        _buildUpdateDesc(),
                      ],
                    ),
                  ),
                ),
              ),
              const CommonDivider(padding: EdgeInsets.symmetric(vertical: 10)),
              // TODO GitHub页面
              // 选择加速网站
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildNewVersionTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 36),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 0),
          child: Text(
            '发现新版本！',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Row(
          children: [
            Text(
              '${upgradeController.latestRelease?.tagName}',
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            _buildToChanglogPageButton(),
          ],
        ),
      ],
    );
  }

  MarkdownBody _buildUpdateDesc() {
    return MarkdownBody(
      data: upgradeController.latestRelease?.body ?? '',
      styleSheet: MarkdownStyleSheet(
        h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        p: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildToChanglogPageButton() {
    return TextButton(
        onPressed: () => RouteUtil.materialTo(context, const ChangelogPage()),
        child: Row(
          children: [
            Text(
              '全部更新日志',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              MingCuteIcons.mgc_arrow_right_line,
              color: Theme.of(context).primaryColor,
              size: 16,
            )
          ],
        ));
  }

  _buildActions() {
    const buttonMargin = EdgeInsets.symmetric(horizontal: 20);

    return AlignLimitedBox(
        maxWidth: AppTheme.formMaxWidth,
        alignment: Alignment.topCenter,
        child: Container(
          padding: buttonMargin,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        upgradeController.ignoreVersion();
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('忽略该版本'),
                      )),
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('下次提醒'),
                      )),
                  const SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: () => RouteUtil.materialTo(
                            context,
                            const UpgradeMethodPage(),
                            replace: true,
                          ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('下载'),
                      )),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ));
  }
}
