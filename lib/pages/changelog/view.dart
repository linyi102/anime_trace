import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/pages/changelog/logic.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/widgets/common_outlined_button.dart';
import 'package:get/get.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  ChangelogLogic get logic => Get.put(ChangelogLogic());

  @override
  void dispose() {
    super.dispose();
    Get.delete<ChangelogLogic>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更新日志'),
      ),
      body: GetBuilder(
        init: logic,
        builder: (_) {
          if (logic.loading) return const LoadingWidget(center: true);

          return RefreshIndicator(
            onRefresh: () async {
              await logic.loadData();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: logic.releases.length,
              itemBuilder: (context, index) {
                final release = logic.releases[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonOutlinedButton(
                      onPressed: () {
                        LaunchUrlUtil.launch(
                            context: context,
                            uriStr: release.htmlUrl,
                            inApp: false);
                      },
                      text: release.tagName,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 10),
                    Text(release.body.trim()),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
