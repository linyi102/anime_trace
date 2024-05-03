import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/upgrade/controllers/app_upgrade_controller.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';
import 'package:flutter_test_future/widgets/limit_width_center.dart';
import 'package:get/get.dart';

class UpgradeMethodPage extends StatefulWidget {
  const UpgradeMethodPage({super.key});

  @override
  State<UpgradeMethodPage> createState() => _UpgradeMethodPageState();
}

class _UpgradeMethodPageState extends State<UpgradeMethodPage> {
  final upgradeController = AppUpgradeController.to;
  final urls = ['github.com', 'kgithub.com', 'download.nuaa.cf', 'git.xfj0.cn'];
  late String selectedUrl = urls.first;

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
                        _buildDownloadMethods(context),
                        _buildOtherMethods(context),
                      ],
                    ),
                  ),
                ),
              ),
              const CommonDivider(padding: EdgeInsets.symmetric(vertical: 10)),
              _buildDownloadButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildBackButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_outlined),
          splashRadius: 18),
    );
  }

  AlignLimitedBox _buildDownloadButton(BuildContext context) {
    return AlignLimitedBox(
      maxWidth: AppTheme.formMaxWidth,
      alignment: Alignment.topCenter,
      child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          height: 36,
          width: MediaQuery.of(context).size.width,
          child: ElevatedButton(onPressed: () {}, child: const Text('下载'))),
    );
  }

  Column _buildDownloadMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Row(
            children: [
              Text('选择下载源', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        for (var index = 0; index < urls.length; index++)
          RadioListTile(
            title: Text(index == 0 ? 'GitHub' : '镜像 $index'),
            subtitle: Text(urls[index]),
            dense: true,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            // secondary: SizedBox(
            //   height: 30,
            //   child: OutlinedButton(
            //       onPressed: () {}, child: const Text('下载')),
            // ),
            groupValue: selectedUrl,
            value: urls[index],
            onChanged: (String? value) {
              setState(() {
                selectedUrl = urls[index];
              });
            },
          ),

        // ListTile(
        //   title: const Text('GitHub'),
        //   subtitle: const Text('github.com'),
        //   trailing: SizedBox(
        //     height: 30,
        //     child: OutlinedButton(
        //         onPressed: () {}, child: const Text('下载')),
        //   ),
        // ),
        // for (var index = 0; index < urls.length; index++)
        //   ListTile(
        //     title: Text('镜像 ${index + 1}'),
        //     subtitle: Text(urls[index]),
        //     trailing: SizedBox(
        //       height: 30,
        //       child: OutlinedButton(
        //           onPressed: () {}, child: const Text('下载')),
        //     ),
        //   ),
      ],
    );
  }

  Column _buildOtherMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Text('或访问网站下载', style: Theme.of(context).textTheme.titleLarge),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...['GitHub', 'Gitee', '蓝奏云', '百度网盘'].map((e) => Container(
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextButton(onPressed: () {}, child: Text(e)),
                  ))
            ],
          ),
        )
      ],
    );
  }
}
