import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/enum/project_uri.dart';
import 'package:flutter_test_future/pages/upgrade/controllers/app_upgrade_controller.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';
import 'package:flutter_test_future/widgets/limit_width_center.dart';
import 'package:get/get.dart';

class UpgradeMethodPage extends StatefulWidget {
  const UpgradeMethodPage({this.showBackLeading = false, super.key});
  final bool showBackLeading;

  @override
  State<UpgradeMethodPage> createState() => _UpgradeMethodPageState();
}

class _UpgradeMethodPageState extends State<UpgradeMethodPage> {
  final upgradeController = AppUpgradeController.to;
  final urls = ['github.com', 'kgithub.com', 'download.nuaa.cf', 'git.xfj0.cn'];
  late String selectedUrl = urls.first;
  late bool supportDirectDownload = Platform.isAndroid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GetBuilder(
        init: upgradeController,
        builder: (_) => Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: AlignLimitedBox(
                    maxWidth: AppTheme.formMaxWidth,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBackButton(context),
                        // _buildDownloadType(),
                        _buildDownloadMethods(context),
                        _buildOtherMethods(context),
                      ],
                    ),
                  ),
                ),
              ),
              const CommonDivider(padding: EdgeInsets.symmetric(vertical: 10)),
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    if (!widget.showBackLeading) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_outlined),
          splashRadius: 18),
    );
  }

  // ignore: unused_element
  Column _buildDownloadType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('选择下载类型'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<int>(
            multiSelectionEnabled: false,
            emptySelectionAllowed: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('便捷版')),
              ButtonSegment(value: 1, label: Text('安装版')),
            ],
            selected: const {0},
            onSelectionChanged: (p0) {},
            // style: const ButtonStyle(
            //     visualDensity: VisualDensity.compact,
            //     textStyle: MaterialStatePropertyAll(TextStyle(fontSize: 14))),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadMethods(BuildContext context) {
    if (!supportDirectDownload) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTitle('选择下载源'),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              '当前不支持直接下载',
              style: TextStyle(color: Theme.of(context).hintColor),
            )),
        const SizedBox(height: 20),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('选择下载源'),
        for (var index = 0; index < urls.length; index++)
          RadioListTile(
            title: Text(index == 0 ? 'GitHub' : '镜像 $index'),
            subtitle: Text(urls[index]),
            dense: true,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            groupValue: selectedUrl,
            value: urls[index],
            onChanged: (String? value) {
              setState(() {
                selectedUrl = urls[index];
              });
            },
          ),
      ],
    );
  }

  Column _buildOtherMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(supportDirectDownload ? '或访问网站下载' : '访问网站下载'),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...ProjectUri.values
                  .where((e) => e.isDownloadChannel)
                  .map((e) => Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton(
                            onPressed: () => e.launch(context),
                            child: Text(e.label)),
                      ))
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return AlignLimitedBox(
      maxWidth: AppTheme.formMaxWidth,
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (supportDirectDownload) ...[
              SizedBox(
                  height: 36,
                  child: ElevatedButton(
                      onPressed: () {}, child: const Text('下载'))),
              const SizedBox(height: 10),
            ],
            SizedBox(
                height: 36,
                width: MediaQuery.of(context).size.width,
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'))),
          ],
        ),
      ),
    );
  }

  _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
