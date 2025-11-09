import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/sqlite_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/values/sp_key.dart';
import 'package:animetrace/values/theme.dart';
import 'package:flutter/material.dart';

import 'package:animetrace/models/anime.dart';

/// 迁移比较页
/// 提交会直接更新动漫表
class MigrateComparePage extends StatefulWidget {
  const MigrateComparePage({
    super.key,
    required this.oldAnime,
    required this.newAnime,
  });

  final Anime oldAnime;
  final Anime newAnime;

  @override
  State<MigrateComparePage> createState() => _MigrateComparePageState();
}

class _MigrateComparePageState extends State<MigrateComparePage> {
  final config = Config.migrateConfig;
  Anime? get oldAnime => widget.oldAnime;
  late Anime? newAnime = widget.newAnime;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    if (widget.newAnime.isCollected()) {
      ToastUtil.showText('无法迁移到已收藏动漫');
      Navigator.pop(context);
      return;
    }

    ToastUtil.showLoading(
      msg: '获取信息中...',
      task: () async {
        newAnime = await ClimbAnimeUtil.climbAnimeInfoByUrl(widget.newAnime,
            showMessage: false);
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('迁移配置')),
      body: ListView(
        children: [
          _CompareTile(
            title: '封面',
            value: config.coverIsNew,
            onChanged: (value) => setState(() => config.coverIsNew = value),
            oldWidget: _buildCover(widget.oldAnime.animeCoverUrl),
            newWidget: _buildCover(widget.newAnime.animeCoverUrl),
          ),
          _CompareTile(
            title: '名字',
            value: config.nameIsNew,
            onChanged: (value) => setState(() => config.nameIsNew = value),
            oldWidget: Text(widget.oldAnime.animeName),
            newWidget: Text(widget.newAnime.animeName),
          ),
          _CompareTile(
            title: '别名',
            value: config.anotherNameIsNew,
            onChanged: (value) =>
                setState(() => config.anotherNameIsNew = value),
            oldWidget: Text(widget.oldAnime.nameAnother),
            newWidget: Text(widget.newAnime.nameAnother),
          ),
          _CompareTile(
            title: '地区',
            value: config.areaIsNew,
            onChanged: (value) => setState(() => config.areaIsNew = value),
            oldWidget: Text(widget.oldAnime.area),
            newWidget: Text(widget.newAnime.area),
          ),
          _CompareTile(
            title: '分类',
            value: config.categoryIsNew,
            onChanged: (value) => setState(() => config.categoryIsNew = value),
            oldWidget: Text(widget.oldAnime.category),
            newWidget: Text(widget.newAnime.category),
          ),
          _CompareTile(
            title: '首播时间',
            value: config.premiereTimeIsNew,
            onChanged: (value) =>
                setState(() => config.premiereTimeIsNew = value),
            oldWidget: Text(widget.oldAnime.premiereTime),
            newWidget: Text(widget.newAnime.premiereTime),
          ),
          _CompareTile(
            title: '播放状态',
            value: config.playStatusIsNew,
            onChanged: (value) =>
                setState(() => config.playStatusIsNew = value),
            oldWidget: Text(widget.oldAnime.playStatus),
            newWidget: Text(widget.newAnime.playStatus),
          ),
          _CompareTile(
            title: '链接',
            value: config.urlIsNew,
            onChanged: (value) => setState(() => config.urlIsNew = value),
            oldWidget: Text(widget.oldAnime.animeUrl),
            newWidget: Text(widget.newAnime.animeUrl),
          ),
          _CompareTile(
            title: '简介',
            value: config.descIsNew,
            onChanged: (value) => setState(() => config.descIsNew = value),
            oldWidget: Text(widget.oldAnime.animeDesc),
            newWidget: Text(widget.newAnime.animeDesc),
          ),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Config.setMigrateConfig(config);
          await AnimeDao.updateAnime(
            await SqliteUtil.getAnimeByAnimeId(oldAnime!.animeId),
            newAnime!,
            config: config,
          );
          ToastUtil.showText('迁移成功');

          // 更新到数据库后，再退出比较页和搜索页
          Navigator.pop(context);
          Navigator.pop(context);
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  Widget _buildCover(String url) {
    return Container(
      height: 280,
      width: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.imgRadius)),
      child: CommonImage(url),
    );
  }
}

class _CompareTile extends StatelessWidget {
  const _CompareTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.oldWidget,
    this.newWidget,
  }) : assert((oldWidget == null) == (newWidget == null));

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? oldWidget;
  final Widget? newWidget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title, style: TextTheme.of(context).titleMedium),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: GestureDetector(
                  onTap: () => onChanged(false),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio(
                        value: false,
                        groupValue: value,
                        onChanged: (value) {
                          if (value == null) return;
                          onChanged(value);
                        },
                      ),
                      if (oldWidget != null) oldWidget!,
                    ],
                  ),
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio(
                        value: true,
                        groupValue: value,
                        onChanged: (value) {
                          if (value == null) return;
                          onChanged(value);
                        },
                      ),
                      if (newWidget != null) newWidget!,
                    ],
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
