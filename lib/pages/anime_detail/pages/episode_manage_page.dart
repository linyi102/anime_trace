import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/dao/episode_desc_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/bangumi/episode.dart';
import 'package:animetrace/models/episode.dart';
import 'package:animetrace/modules/load_status/page.dart';
import 'package:animetrace/pages/anime_detail/controllers/anime_controller.dart';
import 'package:animetrace/pages/bangumi/bind_subject/view.dart';
import 'package:animetrace/repositories/bangumi_repository.dart';
import 'package:animetrace/routes/get_route.dart';
import 'package:animetrace/utils/common_util.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/widgets/button/action_button.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/dialog/dialog_select_uint.dart';
import 'package:animetrace/models/anime_episode_info.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/values/assets.gen.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class EpisodeManagePage extends StatefulWidget {
  const EpisodeManagePage({super.key, required this.animeController});
  final AnimeController animeController;

  @override
  State<EpisodeManagePage> createState() => _EpisodeManagePageState();
}

class _EpisodeManagePageState extends State<EpisodeManagePage> {
  int episodeCntMinValue = 0, episodeCntMaxValue = 1 << 16;
  int episodeStartNumberMinValue = 0, episodeStartNumberMaxValue = 1 << 16;

  late int totalCnt = widget.animeController.anime.animeEpisodeCnt;
  late int startNumber = widget.animeController.anime.episodeStartNumber;
  late bool calEpisodeNumberFromOne =
      widget.animeController.anime.calEpisodeNumberFromOne;

  bool loadOk = false;

  /// 动漫所有集数
  List<Episode> episodes = [];

  /// 起始范围，最小为 1，和起始集无关
  late RangeValues curRange;
  int get rangeStart => curRange.start.round();
  int get rangeEnd => curRange.end.round();

  /// 数据库中记录的标题信息，只在生成 [episodes] 时用到
  List<EpisodeDesc> descs = [];

  /// 用户输入的标题数组
  List<String> inputTitles = [];

  List<_EpisodeTitleDiff> diffs = [];

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void load() async {
    descs = await EpisodeDescDao.queryAll(widget.animeController.anime.animeId);
    loadEpisodes();

    if (mounted) {
      setState(() => loadOk = true);
    }
  }

  void loadEpisodes() {
    episodes = List.generate(totalCnt, (index) {
      final number = index + 1;
      final desc = descs.firstWhereOrNull((e) => e.number == number);
      return Episode(number, 1,
          startNumber: calEpisodeNumberFromOne ? 1 : startNumber, desc: desc);
    });
    curRange = RangeValues(1, totalCnt == 0 ? 1 : totalCnt.toDouble());
    buildDiffs();

    setState(() {});
  }

  void buildDiffs() {
    diffs.clear();

    for (int i = 0; i < rangeEnd - rangeStart + 1; i++) {
      if (episodes.length <= rangeStart - 1 + i) {
        break;
      }

      final ep = episodes[rangeStart - 1 + i];
      final input = inputTitles.length > i ? inputTitles[i] : null;
      final oldTitle = ep.caption;
      var newTitle = input ?? '';

      if (newTitle.isEmpty || newTitle == oldTitle) {
        diffs.add(_EpisodeTitleDiff(
          episode: ep,
          newTitle: '',
          action: _DiffAction.same,
          isSamePrefix: false,
        ));
        continue;
      }

      if (newTitle == '-') {
        diffs.add(_EpisodeTitleDiff(
          episode: ep,
          newTitle: '',
          action: _DiffAction.delete,
          isSamePrefix: false,
        ));
        continue;
      }

      final prefix = '第 ${ep.numberWithStartNumber} 集 ';
      final isSamePrefix = newTitle.startsWith(prefix);

      if (isSamePrefix) {
        newTitle = newTitle.replaceFirst(prefix, '');
      }
      diffs.add(_EpisodeTitleDiff(
        episode: ep,
        newTitle: newTitle,
        action: _DiffAction.update,
        isSamePrefix: isSamePrefix,
      ));
    }

    setState(() {});
  }

  void submit() async {
    if (totalCnt < episodeCntMinValue || totalCnt > episodeCntMaxValue) {
      ToastUtil.showText("集数设置范围：[$episodeCntMinValue, $episodeCntMaxValue]");
      return;
    }

    if (startNumber < episodeStartNumberMinValue ||
        startNumber > episodeStartNumberMaxValue) {
      ToastUtil.showText(
          "起始集设置范围：[$episodeStartNumberMinValue, $episodeStartNumberMaxValue]");
      return;
    }

    final form = AnimeEpisodeInfo(
      totalCnt: totalCnt,
      startNumber: startNumber,
      calNumberFromOne: calEpisodeNumberFromOne,
    );

    await AnimeDao.updateEpisodeInfoByAnimeId(
        widget.animeController.anime.animeId, form);

    // 修改数据
    widget.animeController.anime.animeEpisodeCnt = form.totalCnt;
    widget.animeController.anime.episodeStartNumber = form.startNumber;
    widget.animeController.anime.calEpisodeNumberFromOne =
        form.calNumberFromOne;

    for (final diff in diffs) {
      final ep = diff.episode;
      final desc = ep.desc ??
          EpisodeDesc(
            id: 0,
            animeId: widget.animeController.anime.animeId,
            number: ep.number,
            title: diff.newTitle,
            hideDefault: !diff.isSamePrefix,
          );

      switch (diff.action) {
        case _DiffAction.same:
          break;
        case _DiffAction.delete:
          if (!desc.notInsert) {
            desc
              ..title = ''
              ..hideDefault = false;
            await EpisodeDescDao.update(desc);
          }
          break;
        case _DiffAction.update:
          if (desc.notInsert) {
            await EpisodeDescDao.insert(desc);
          } else {
            desc
              ..title = diff.newTitle
              ..hideDefault = !diff.isSamePrefix;
            await EpisodeDescDao.update(desc);
          }
          break;
      }
    }

    // 重绘
    widget.animeController.updateAnimeInfo(); // 重绘信息行中显示的集数
    widget.animeController.loadEpisode(); // 重绘集信息

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('集数管理')),
      resizeToAvoidBottomInset: false,
      body: !loadOk
          ? const LoadingPage()
          : Stack(
              children: [
                _buildMainView(context),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    width: 300,
                    child: ActionButton(
                      onTap: submit,
                      child: const Text('保存'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMainView(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('总集数'),
                      const SizedBox(width: 30),
                      Expanded(
                        child: NumberControlInputField(
                          minValue: episodeCntMinValue,
                          maxValue: episodeCntMaxValue,
                          initialValue: totalCnt,
                          showRangeHintText: false,
                          onChanged: (number) {
                            totalCnt = number.toInt();
                            loadEpisodes();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('起始集'),
                      const SizedBox(width: 30),
                      Expanded(
                        child: NumberControlInputField(
                          minValue: episodeStartNumberMinValue,
                          maxValue: episodeStartNumberMaxValue,
                          initialValue: startNumber,
                          showRangeHintText: false,
                          onChanged: (number) {
                            startNumber = number.toInt();
                            loadEpisodes();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('从第 1 集计数'),
                      value: calEpisodeNumberFromOne,
                      onChanged: (value) {
                        calEpisodeNumberFromOne = value;
                        loadEpisodes();
                      }),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      '预览',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            final lines =
                                diffs.map((d) => d.latestTitle).toList();
                            CommonUtil.copyContent(lines.join('\n'));
                          },
                          icon: const Icon(Icons.paste),
                          tooltip: '导出',
                        ),
                        IconButton(
                          onPressed: () async {
                            final r = await showDialog(
                              context: context,
                              builder: (context) => _EpisodeTitlesInputDialog(
                                anime: widget.animeController.anime,
                                initialValue: inputTitles.join('\n'),
                                epStartNumber:
                                    calEpisodeNumberFromOne ? 1 : null,
                              ),
                            );
                            if (r is String) {
                              inputTitles = r
                                  .split('\n')
                                  // 清除回车 CR 键
                                  .map((e) => e.trim())
                                  .toList();
                              buildDiffs();
                            }
                          },
                          icon: const Icon(Icons.document_scanner_outlined),
                          tooltip: '导入',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (totalCnt > 1)
            SliverToBoxAdapter(
              child: SliderTheme(
                data: const SliderThemeData(
                  showValueIndicator: ShowValueIndicator.always,
                ),
                child: RangeSlider(
                  // 最小值始终为 1，只对展示范围的 label 根据起始集调整
                  min: 1,
                  max: totalCnt.toDouble(),
                  values: curRange,
                  divisions: totalCnt - 1,
                  labels: calEpisodeNumberFromOne
                      ? RangeLabels('$rangeStart', '$rangeEnd')
                      : RangeLabels('${rangeStart + startNumber - 1}',
                          '${rangeEnd + startNumber - 1}'),
                  onChanged: (v) {
                    curRange = v;
                    buildDiffs();
                  },
                ),
              ),
            ),
          if (totalCnt > 0)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 64),
              sliver: SuperSliverList.builder(
                itemCount: diffs.length,
                itemBuilder: (_, index) {
                  final d = diffs[index];
                  final oldTitle = d.oldTitleWithoutPrefix;

                  return switch (d.action) {
                    _DiffAction.same => ListTile(title: Text(d.oldTitle)),
                    _DiffAction.delete => ListTile(
                        title: Text.rich(TextSpan(children: [
                          TextSpan(text: d.prefix),
                          if (oldTitle.isNotEmpty) ...[
                            TextSpan(
                              text: oldTitle,
                              style: const TextStyle(
                                  decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ])),
                      ),
                    _DiffAction.update => d.isSamePrefix
                        ? ListTile(
                            title: Text.rich(TextSpan(children: [
                              TextSpan(text: d.prefix),
                              if (oldTitle.isNotEmpty) ...[
                                TextSpan(
                                  text: oldTitle,
                                  style: const TextStyle(
                                      decoration: TextDecoration.lineThrough),
                                ),
                              ],
                              TextSpan(
                                text: d.newTitle,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                              ),
                            ])),
                          )
                        : ListTile(
                            title: Text.rich(TextSpan(children: [
                              TextSpan(
                                text: '${d.oldTitle}\n',
                                style: const TextStyle(
                                    decoration: TextDecoration.lineThrough),
                              ),
                              TextSpan(
                                text: d.newTitle,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                              ),
                            ])),
                          ),
                  };
                },
              ),
            )
        ],
      ),
    );
  }
}

class _EpisodeTitlesInputDialog extends StatefulWidget {
  const _EpisodeTitlesInputDialog({
    required this.anime,
    this.initialValue = '',
    this.epStartNumber,
  });

  final Anime anime;
  final String initialValue;

  /// 用于生成第 n 集前缀
  /// - null 时根据 bangumi 的 sort 生成
  /// - 不为 null 时根据 `epStartNumber + index` 计算 n
  final int? epStartNumber;

  @override
  State<_EpisodeTitlesInputDialog> createState() =>
      __EpisodeTitlesInputDialogState();
}

class __EpisodeTitlesInputDialogState extends State<_EpisodeTitlesInputDialog> {
  final inputCtr = TextEditingController();
  final bgmRepo = const BangumiRepository();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    inputCtr.text = widget.initialValue;
  }

  @override
  void dispose() {
    inputCtr.dispose();
    super.dispose();
  }

  void getBgmEpisodes() async {
    if (isLoading) return;

    Future<String> getSubjectId() async {
      if (widget.anime.bgmSubjectId.isNotEmpty) {
        return widget.anime.bgmSubjectId;
      }

      final dbSubjectId = await AnimeDao.getBgmSubjectId(widget.anime.animeId);
      if (dbSubjectId.isNotEmpty) return dbSubjectId;

      final bgmAnime = await RouteUtil.materialTo<Anime>(
          context, BindBgmSubjectView(widget.anime.animeName));
      if (bgmAnime == null) return '';

      final subjectId = bgmAnime.bgmSubjectId;
      await AnimeDao.setBgmSubjectId(widget.anime.animeId, subjectId);
      return subjectId;
    }

    final subjectId = await getSubjectId();
    if (subjectId.isEmpty) return;

    setState(() {
      isLoading = true;
    });
    try {
      final eps = await bgmRepo.fetchEpisodes(subjectId);
      final destTypeValues = [
        BgmEpisodeType.main.value,
        BgmEpisodeType.sp.value
      ];
      inputCtr.text = eps
          .where((ep) => destTypeValues.contains(ep.type))
          .toList()
          .asMap()
          .entries
          .map((entry) {
        final index = entry.key;
        final ep = entry.value;
        final epName =
            ep.nameCn?.isNotEmpty == true ? ep.nameCn! : (ep.name ?? '');

        return ep.sort == null
            ? ''
            : ep.type == BgmEpisodeType.main.value
                ? widget.epStartNumber == null
                    ? '第 ${ep.sort} 集 $epName'
                    : '第 ${widget.epStartNumber! + index} 集 $epName'
                : 'SP${ep.sort} $epName';
      }).join('\n');
    } catch (e) {
      AppLog.error('获取bangumi集列表失败：$e');
    } finally {
      isLoading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('导入')),
          IconButton(
            onPressed: getBgmEpisodes,
            tooltip: '从 Bangumi 中导入',
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Assets.images.website.bangumi.image(width: 24),
            ),
          )
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const LinearProgressIndicator(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            TextField(
              controller: inputCtr,
              minLines: 4,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText:
                    '每行一集，示例：\n第 1 集 标题 1 \n第 2 集 标题 2\n\n提示：\n1. 空行表示跳过\n2. - 表示删除标题',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, inputCtr.text),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

enum _DiffAction { same, delete, update }

class _EpisodeTitleDiff {
  final Episode episode;

  String get oldTitle => episode.caption;

  String get oldTitleWithoutPrefix => episode.desc?.title ?? '';

  final String newTitle;

  final _DiffAction action;

  final bool isSamePrefix;

  _EpisodeTitleDiff({
    required this.episode,
    required this.newTitle,
    required this.action,
    required this.isSamePrefix,
  });

  String get latestTitle => switch (action) {
        _DiffAction.same => oldTitle,
        _DiffAction.update => isSamePrefix ? '$prefix$newTitle' : newTitle,
        _DiffAction.delete => prefix,
      }
          .trim();

  String get prefix => '第 ${episode.numberWithStartNumber} 集 ';
}
