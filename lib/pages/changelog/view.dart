import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/pages/changelog/logic.dart';
import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

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
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        icon: const Icon(MingCuteIcons.mgc_tag_line, size: 16),
                        onPressed: () {
                          LaunchUrlUtil.launch(
                              context: context,
                              uriStr: release.htmlUrl,
                              inApp: false);
                        },
                        label: Text(release.tagName),
                        style: const ButtonStyle(
                          visualDensity: VisualDensity(vertical: -2),
                          padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    MarkdownBody(data: release.body),
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
