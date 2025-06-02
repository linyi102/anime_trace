import 'package:animetrace/components/anime_list_cover.dart';
import 'package:animetrace/components/website_logo.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/models/data_state.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/pages/network/sources/pages/migrate/migrate_controller.dart';
import 'package:animetrace/utils/global_data.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/widgets/button/action_button.dart';
import 'package:animetrace/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MigratePage extends StatefulWidget {
  const MigratePage({super.key, required this.website});
  // 源搜索源
  final ClimbWebsite website;

  @override
  State<MigratePage> createState() => _MigratePageState();
}

class _MigratePageState extends State<MigratePage> {
  late final controller =
      Get.put(MigrateController(sourceWebsite: widget.website));

  @override
  void dispose() {
    Get.delete<MigrateController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _onWillPop(context);
      },
      child: GetBuilder(
        init: controller,
        builder: (controller) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _onWillPop(context),
            ),
            title:
                Text('迁移${widget.website.name} (${controller.animes.length})'),
          ),
          body: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 64),
                itemCount: controller.animes.length,
                itemBuilder: (context, index) {
                  final anime = controller.animes[index];
                  final state = controller.states[anime.animeId];
                  return ListTile(
                    leading: AnimeListCover(anime),
                    title: Text(anime.animeName),
                    subtitle: Text(anime.getAnimeSource()),
                    trailing: state?.when(
                      data: (message) => Text(message),
                      error: (_, __, message) => Text(message ?? '迁移失败'),
                      loading: (_) => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    onTap: () => _tryToDetailPage(index),
                  );
                },
              ),
              if (controller.animes.isNotEmpty) _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        width: 300,
        child: ActionButton(
          loaderStyle: ButtonLoaderStyle.none,
          onTap: () => controller.onTapPrimary(context),
          child: ProgressBuilder(
            controller: controller.progressController,
            builder: (context, count, total, percent) {
              if (controller.destWebsite == null) return const Text('选择搜索源');
              if (controller.migrating) return Text('迁移进度：$count / $total');
              return const Text('开始迁移');
            },
          ),
        ),
      ),
    );
  }

  void _tryToDetailPage(int index) {
    final anime = controller.animes[index];
    if (controller.states[anime.animeId]?.isLoading == true) {
      ToastUtil.showText("正在迁移中，请稍后进入");
      return;
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AnimeDetailPage(anime)))
        .then((value) {
      setState(() {
        controller.animes[index] = value;
      });
    });
  }

  void _onWillPop(BuildContext context) {
    if (controller.migrating) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('确认返回'),
            content: const Text('迁移未完成，是否确定返回？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    } else {
      Get.back();
    }
  }
}

class MigrateFormView extends StatelessWidget {
  const MigrateFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MigrateController>();
    return GetBuilder(
      init: controller,
      builder: (controller) => AlertDialog(
        title: const Text('迁移选项'),
        contentPadding: const EdgeInsets.all(10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: const Text('迁移到'),
                subtitle: Text(controller.destWebsite?.name ?? '未选择'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      children: climbWebsites
                          .where((e) =>
                              !e.discard && e != controller.sourceWebsite)
                          .map((e) {
                        return ListTile(
                          title: Text(e.name),
                          leading: WebSiteLogo(url: e.iconUrl, size: 25),
                          trailing: e.name == controller.destWebsite?.name
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            controller.updateDestWebsite(e);
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
                trailing: controller.destWebsite != null
                    ? WebSiteLogo(
                        url: controller.destWebsite!.iconUrl,
                        size: 25,
                      )
                    : null),
            ListTile(
              title: const Text('间隔时间(秒)'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('每次搜索动漫的间隔，避免请求频繁'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: controller.spacingSeconds.toDouble(),
                        min: 3,
                        max: 10,
                        onChanged: (value) =>
                            controller.updateSpacingDuration(value.round()),
                      ),
                      Text('${controller.spacingSeconds} 秒')
                    ],
                  )
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('精确匹配'),
              subtitle: Text(controller.precise
                  ? '精确匹配时，只有当动漫名完全匹配时才进行迁移'
                  : '非精确匹配时，会选择搜索的第一个动漫进行迁移'),
              value: controller.precise,
              onChanged: controller.updatePrecise,
            ),
            SwitchListTile(
              title: const Text('只迁移连载动漫'),
              subtitle: Text(
                  controller.skipFinishedAnime ? '已完结的动漫不会被迁移' : '所有动漫都会被迁移'),
              value: controller.skipFinishedAnime,
              onChanged: controller.updateOnlyMirgratePlaying,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.destWebsite == null) {
                ToastUtil.showText("请先选择搜索源");
                return;
              }

              Navigator.pop(context);
              controller.startMigrate();
            },
            child: const Text('开始迁移'),
          ),
        ],
      ),
    );
  }
}
