import 'dart:io';
import 'dart:ui';

import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:expand_widget/expand_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_cover_detail.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_rate_list_page.dart';
import 'package:flutter_test_future/components/anime_rating_bar.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/settings/label_manage_page.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../components/dialog/dialog_select_play_status.dart';
import '../../dao/note_dao.dart';
import '../../components/toggle_list_tile.dart';
import '../modules/search_db_anime.dart';
import 'anime_properties_page.dart';

class AnimeDetailPlus extends StatefulWidget {
  Anime anime;

  AnimeDetailPlus(
    this.anime, {
    Key? key,
  }) : super(key: key);

  @override
  _AnimeDetailPlusState createState() => _AnimeDetailPlusState();
}

class _AnimeDetailPlusState extends State<AnimeDetailPlus>
    with SingleTickerProviderStateMixin {
  bool _loadEpisodeOk = false;
  late Anime _anime;
  List<Episode> _episodes = []; // 集
  List<Note> _notes = []; // 集对应的笔记
  int rateNoteCount = 0; // 评价数量
  final AnimeController animeController =
      Get.put(AnimeController()); // 动漫详细页的动漫
  final LabelsController labelsController = Get.find(); // 动漫详细页的标签

  // 输入框
  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  FocusNode animeNameFocusNode = FocusNode(); // 动漫名字输入框焦点

  // 多选
  Map<int, bool> mapSelected = {};
  bool multiSelected = false;
  Color multiSelectedColor = ThemeUtil.getPrimaryColor().withOpacity(0.25);
  late int lastMultiSelectedIndex; // 记住最后一次多选的集下标

  bool hideNoteInAnimeDetail =
      SPUtil.getBool("hideNoteInAnimeDetail", defaultValue: false);

  // 选择显示的集范围
  int currentStartEpisodeNumber = 1;
  final int episodeRangeSize = 50;

  // 界面
  double sigma = SpProfile.getCoverBgSigmaInAnimeDetailPage();
  double coverBgHeightRatio = SpProfile.getCoverBgHeightRatio();

  @override
  void initState() {
    super.initState();
    _anime = widget.anime;
    // 如果没有收藏，则不允许进入
    if (widget.anime.animeId <= 0) {
      Navigator.of(context).pop();
      showToast("无法进入未收藏动漫");
    }

    if (widget.anime.animeId > 0) {
      currentStartEpisodeNumber = SPUtil.getInt(
          "${widget.anime.animeId}-currentStartEpisodeNumber",
          defaultValue: 1);
      _loadData();
    } else {
      _anime = widget.anime;
      // 爬取详细信息
      _climbAnimeInfo();
    }
  }

  void _loadData() async {
    animeController
        .setAnime(widget.anime); // 信息不完全，先提前展示封面和名字，否则展示的是上次进入的动漫封面和名字
    // await Future.delayed(const Duration(seconds: 2));
    await _loadAnime();
    // 等待加载好动漫后，就可以确定当前动漫存在，于是根据id加载集信息、评价数量、标签等
    animeController.setAnime(_anime);
    _loadRateNoteCnt();
    _loadLabels();
    // await Future.delayed(const Duration(seconds: 1));
    _loadEpisode();
  }

  Future<bool> _loadAnime() async {
    setState(() {});

    _anime = await SqliteUtil.getAnimeByAnimeId(
        widget.anime.animeId); // 一定要return，value才有值
    // 如果没有从数据库中找到，则直接退出该页面
    if (!_anime.isCollected()) {
      Navigator.of(context).pop();
      showToast("无法进入未收藏动漫");
    }
    setState(() {});
    return true;
  }

  void _loadEpisode() async {
    // await Future.delayed(const Duration(seconds: 1));
    _episodes = [];
    _notes = [];
    _loadEpisodeOk = false;
    setState(() {});

    if (_anime.animeEpisodeCnt == 0) {
      // 如果为0，则不修改currentStartEpisodeNumber
    } else if (currentStartEpisodeNumber > _anime.animeEpisodeCnt) {
      // 起始集编号>动漫集数，则从最后一个范围开始x
      // 修改后集数为260，则(260/50)=5.2=5, 5*50=250, 250+1=251
      // 修改后集数为250，则(250/50)=5，(5-1)*50=200, 200+1=201，也就是251-50
      currentStartEpisodeNumber =
          _anime.animeEpisodeCnt ~/ episodeRangeSize * episodeRangeSize + 1;
      if (_anime.animeEpisodeCnt % episodeRangeSize == 0) {
        currentStartEpisodeNumber -= episodeRangeSize;
      }
    }
    _episodes = await SqliteUtil.getEpisodeHistoryByAnimeIdAndRange(
        _anime,
        currentStartEpisodeNumber,
        currentStartEpisodeNumber + episodeRangeSize - 1);
    Log.info("削减后，集长度为${_episodes.length}");
    _sortEpisodes(SPUtil.getString("episodeSortMethod",
        defaultValue: sortMethods[0])); // 排序，默认升序，兼容旧版本

    for (var episode in _episodes) {
      Note episodeNote = Note(
          anime: _anime,
          episode: episode,
          relativeLocalImages: [],
          imgUrls: []);
      if (episode.isChecked()) {
        // 如果该集完成了，就去获取该集笔记（内容+图片）
        episodeNote = await NoteDao
            .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                episodeNote);
        // Log.info(
        //     "第${episodeNote.episode.number}集的图片数量: ${episodeNote.relativeLocalImages.length}");
      }
      _notes.add(episodeNote);
    }
    _loadEpisodeOk = true;
    // 等200ms后再更新界面，如果在路由动画播放过程中突然显示集信息，会造成卡顿
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {});
  }

  _loadRateNoteCnt() {
    NoteDao.getRateNoteCountByAnimeId(_anime.animeId).then((value) {
      setState(() {
        rateNoteCount = value;
      });
      Log.info("评价数量：$rateNoteCount");
    });
  }

  _loadLabels() async {
    Log.info("查询当前动漫(id=${_anime.animeId})的所有标签");
    labelsController.labelsInAnimeDetail.value =
        await AnimeLabelDao.getLabelsByAnimeId(_anime.animeId);
    labelsController.animeId = _anime.animeId;
  }

  // 用于传回到动漫列表页
  void _refreshAnime() {
    _anime.checkedEpisodeCnt = 0;
    for (var episode in _episodes) {
      if (episode.isChecked()) _anime.checkedEpisodeCnt++;
    }
    // SqliteUtil.updateDescByAnimeId(_anime.animeId, _anime.animeDesc);
    // SqliteUtil.updateAnimeNameByAnimeId(_anime.animeId, _anime.animeName);
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return WillPopScope(
      onWillPop: () async {
        Log.info("按返回键，返回anime");
        _refreshAnime();
        // 返回的_anime用到了id(列表页面和搜索页面)和name(爬取页面)
        // 完成集数因为切换到小的回顾号会导致不是最大回顾号完成的集数，所以那些页面会通过传回的id来获取最新动漫信息
        Navigator.pop(context, _anime);
        Log.info("返回true");
        return true;
      },
      child: Scaffold(
        body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: RefreshIndicator(
              onRefresh: () async {
                // 使用await后，只有当获取信息完成后，加载圈才会消失
                await _climbAnimeInfo();
              },
              child: Stack(children: [
                CustomScrollView(
                  slivers: [
                    // 封面背景
                    _buildSliverAppBar(context),
                    // 动漫信息
                    _buildAnimeInfo(context),
                    if (_loadEpisodeOk)
                      SliverToBoxAdapter(child: _buildButtonsAboutEpisode()),
                    // 集信息
                    if (_loadEpisodeOk) _buildSliverListBody()
                  ],
                ),
                _buildButtonsBarAboutEpisodeMulti()
              ]),
            )),
      ),
    );
  }

  // 构建动漫信息(名字、评分、其他信息)
  _buildAnimeInfo(BuildContext context) {
    const double smallIconSize = 14;
    const double textScaleFactor = 1;

    return SliverPadding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // 动漫名字
          SelectableText(_anime.animeName,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          // 评价
          _buildRatingStars(),
          const SizedBox(height: 15),
          // 动漫信息(左侧)和相关按钮(右侧)
          Row(
            children: [
              // 动漫信息
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_anime.getAnimeInfoFirstLine().isNotEmpty)
                    // 第一行信息
                    Text.rich(
                      TextSpan(children: [
                        WidgetSpan(
                          child: Text(_anime.getAnimeInfoFirstLine()),
                        ),
                      ]),
                      textScaleFactor: textScaleFactor,
                    ),
                  // 第二行信息
                  Text.rich(
                    TextSpan(children: [
                      WidgetSpan(
                          child: GestureDetector(
                        onTap: () {
                          if (_anime.animeUrl.isNotEmpty) {
                            LaunchUrlUtil.launch(
                                context: context, uriStr: _anime.animeUrl);
                          } else {
                            showToast("空网址无法打开");
                          }
                        },
                        child: Row(
                          children: [
                            Text(_anime.getAnimeSource()),
                            const Icon(EvaIcons.externalLink,
                                size: smallIconSize),
                          ],
                        ),
                      )),
                      // const WidgetSpan(child: Text(" • ")),
                      const WidgetSpan(child: Text(" ")),
                      WidgetSpan(
                          child: GestureDetector(
                        onTap: () {
                          showDialogSelectPlayStatus(context, animeController);
                        },
                        // 这里使用animeController里的anime，而不是_anime，否则修改状态后没有变化
                        child: Obx(() => Row(
                              children: [
                                Text(animeController.anime.value
                                    .getPlayStatus()
                                    .text),
                                Icon(
                                    animeController.anime.value
                                        .getPlayStatus()
                                        .iconData,
                                    size: smallIconSize),
                              ],
                            )),
                      )),
                      // const WidgetSpan(child: Text(" • ")),
                      const WidgetSpan(child: Text(" ")),
                      WidgetSpan(
                          child: GestureDetector(
                        onTap: showDialogmodifyEpisodeCnt,
                        child: Row(
                          children: [
                            Text("${_anime.animeEpisodeCnt}集"),
                            const Icon(EvaIcons.editOutline,
                                size: smallIconSize),
                          ],
                        ),
                      )),
                    ]),
                    textScaleFactor: textScaleFactor,
                  ),
                ],
              ),
              const Spacer(),
              _showInfoIcon(),
              _showRateIcon(),
              _showCollectIcon()
            ],
          ),
          // 简介
          if (_anime.animeDesc.isNotEmpty &&
              SpProfile.getShowDescInAnimeDetailPage())
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: ExpandText(_anime.animeDesc,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12),
                  arrowSize: 20),
            ),
          // 标签列表
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Obx(() => Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _getLabelChips(),
                )),
          )
        ]),
      ),
    );
  }

  // 构建标签chips，最后添加增加标签和管理删除chip
  _getLabelChips() {
    List<Widget> chips = labelsController.labelsInAnimeDetail
        .map((label) => GestureDetector(
              onTap: () async {
                Log.info("点按标签：$label");
                // 关闭当前详细页并打开本地动漫搜索页(因为如果不关闭当前详细页，则当前的animeController里的动漫会被后来打开的动漫所覆盖)
                // 使用pushReplacement而非先pop再push，这样不就会显示关闭详细页的路由动画了
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SearchDbAnime(incomingLabelId: label.id)),
                    result: _anime);
              },
              onLongPress: () {
                Log.info("长按标签：$label");
              },
              child: Chip(
                label: Text(label.name),
                backgroundColor: ThemeUtil.getCardColor(),
              ),
            ))
        .toList();

    chips.add(GestureDetector(
      onTap: () {
        Log.info("添加标签");
        // 弹出底部菜单，提供搜索和查询列表
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                const LabelManagePage(enableSelectLabelForAnime: true)));
        // 弹出软键盘时报错，尽管可以正常运行
        // showFlexibleBottomSheet(
        //     duration: const Duration(milliseconds: 200),
        //     minHeight: 0,
        //     initHeight: 0.5,
        //     maxHeight: 1,
        //     context: context,
        //     builder: (
        //       BuildContext context,
        //       ScrollController scrollController,
        //       double bottomSheetOffset,
        //     ) =>
        //         LabelManagePage(),
        //     isExpand: true);
      },
      child: Chip(
        label: const Text("  +  "),
        backgroundColor: ThemeUtil.getCardColor(),
      ),
    ));

    return chips;
  }

  // 构建主体(集信息页)
  _buildSliverListBody() {
    // 不能使用MyAnimatedSwitcher，因为父级是slivers: []
    if (_loadEpisodeOk) {
      return SliverPadding(
        padding: const EdgeInsets.all(0),
        sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, episodeIndex) {
          Log.info("$runtimeType: episodeIndex=$episodeIndex");

          List<Widget> episodeInfo = [];
          episodeInfo.add(
            _buildEpisodeTile(episodeIndex),
          );

          // 在每一集下面添加笔记
          if (!hideNoteInAnimeDetail && _episodes[episodeIndex].isChecked()) {
            episodeInfo.add(_buildNote(episodeIndex, context));
          }

          // 在最后一集下面添加空白
          if (episodeIndex == _episodes.length - 1) {
            episodeInfo.add(const ListTile());
          }

          return Column(
            children: episodeInfo,
          );
        }, childCount: _episodes.length)),
      );
    } else {
      // 还没加载完毕显示加载组件
      return SliverList(
          delegate: SliverChildListDelegate([loadingWidget(context)]));
    }
  }

  _buildSliverAppBar(BuildContext context) {
    double expandedHeight =
        MediaQuery.of(context).size.height * coverBgHeightRatio;

    return Obx(() => SliverAppBar(
          // floating: true,
          // snap: true,
          // pinned: true,
          // 收缩后仍显示AppBar
          expandedHeight: expandedHeight,
          flexibleSpace: FlexibleSpaceBar(
            // 标题，不指定无法对齐，指定padding后又因为下滑后，标题移动到最上面时会歪，所以不采用
            // titlePadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            // expandedTitleScale: 1.2,
            // title: SelectableText(_anime.animeName,
            //     style: const TextStyle(fontWeight: FontWeight.w600)),
            collapseMode: SpProfile.getEnableParallaxInAnimeDetailPage()
                ? CollapseMode.parallax // 下滑时添加视差
                : CollapseMode.pin, // 下滑时固定
            background: Stack(
              children: [
                // 底层背景
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  // 模糊
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: sigma,
                      sigmaY: sigma,
                    ),
                    child: CommonImage(
                        animeController.anime.value.getCommonCoverUrl(),
                        showIconWhenUrlIsEmptyOrError: false),
                  ),
                ),
                // 为底层背景添加渐变效果
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: SpProfile.getEnableCoverBgGradient()
                            ? [
                                // 最上面添加一点黑色，这样就能看清按钮了
                                Colors.black.withOpacity(0.2),
                                // 添加透明色，注意不要用Colors.transparent，否则白色主题会有些黑，过度不自然
                                ThemeUtil.getScaffoldBackgroundColor()
                                    .withOpacity(0),
                                // ThemeUtil.getScaffoldBackgroundColor()
                                //     .withOpacity(0),
                                // 过渡到主体颜色
                                ThemeUtil.getScaffoldBackgroundColor(),
                              ]
                            : [
                                Colors.black.withOpacity(0.2),
                                ThemeUtil.getScaffoldBackgroundColor()
                                    .withOpacity(0),
                                ThemeUtil.getScaffoldBackgroundColor()
                                    .withOpacity(0),
                                // 最后1个换成透明色，就取消渐变了，上面两个透明色仍要保留，否则黑色会直接过渡到下面透明色，中间会有一点黑色
                                Colors.transparent
                              ]),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AnimeCoverDetail()));
                  },
                )
              ],
            ),
          ),
          leading: IconButton(
              onPressed: () {
                Log.info("按返回按钮，返回anime");
                _refreshAnime();
                Navigator.pop(context, _anime);
              },
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              color: Colors.white),
          actions: _buildActions(),
          // bottom: _buildTabRow(),
        ));
  }

  List<Widget> _buildActions() {
    if (!_anime.isCollected()) return [];
    return [
      PopupMenuButton(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text("取消收藏"),
                onTap: () {
                  // 关闭下拉菜单
                  Navigator.pop(context);

                  _dialogDeleteAnime();
                },
              ),
            ),
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                leading: const Icon(Icons.move_down),
                title: const Text("迁移动漫"),
                onTap: () {
                  // 关闭下拉菜单
                  Navigator.pop(context);

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return AnimeClimbAllWebsite(
                          animeId: _anime.animeId,
                          keyword: _anime.animeName,
                        );
                      },
                    ),
                  ).then((value) {
                    _loadData();
                  });
                },
              ),
            ),
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                leading: const Icon(Entypo.layout),
                title: const Text("外观设置"),
                onTap: () {
                  // 关闭下拉菜单
                  Navigator.pop(context);
                  _showLayoutBottomSheet();
                },
              ),
            )
          ];
        },
      ),
    ];
  }

  // 弹出底部弹出菜单，用于外观设置
  _showLayoutBottomSheet() {
    showFlexibleBottomSheet(
      duration: const Duration(milliseconds: 200),
      minHeight: 0,
      initHeight: 0.3,
      maxHeight: 1,
      context: context,
      isExpand: true,
      builder: (
        BuildContext context,
        ScrollController scrollController,
        double bottomSheetOffset,
      ) =>
          StatefulBuilder(
              builder: (context, setBottomSheetState) => Scaffold(
                    body: ListView(
                      children: [
                        ToggleListTile(
                          title: const Text("背景模糊"),
                          toggleOn: sigma > 0, // >0说明开启了模糊
                          onTap: () {
                            sigma = sigma > 0 ? 0.0 : 10.0;
                            SpProfile.setCoverBgSigmaInAnimeDetailPage(sigma);
                            // 重新渲染开关
                            setBottomSheetState(() {});
                            // 重新渲染背景
                            setState(() {});
                          },
                        ),
                        ToggleListTile(
                          title: const Text("背景渐变"),
                          toggleOn: SpProfile.getEnableCoverBgGradient(),
                          onTap: () {
                            SpProfile.turnEnableCoverBgGradient();
                            setBottomSheetState(() {});
                            setState(() {});
                          },
                        ),
                        ToggleListTile(
                          title: const Text("显示简介"),
                          toggleOn: SpProfile.getShowDescInAnimeDetailPage(),
                          onTap: () {
                            SpProfile.turnShowDescInAnimeDetailPage();
                            setBottomSheetState(() {});
                            setState(() {});
                          },
                        ),
                        ToggleListTile(
                          title: const Text("滚动视差"),
                          toggleOn:
                              SpProfile.getEnableParallaxInAnimeDetailPage(),
                          onTap: () {
                            SpProfile.turnEnableParallaxInAnimeDetailPage();
                            setBottomSheetState(() {});
                            setState(() {});
                          },
                        ),
                        // 调节封面背景高度
                        ListTile(
                            title: const Text("背景高度"),
                            trailing: SizedBox(
                              width: 200,
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: 190,
                                    child: Slider(
                                      min: 0.1,
                                      max: 1,
                                      // 显示数字(只有指定divisions后才会显示)
                                      // label:
                                      // "${coverBgHeightRatio.toPrecision(2)}",
                                      divisions: 30,
                                      // 分成30个刻度
                                      value: coverBgHeightRatio,
                                      onChanged: (value) {
                                        Log.info("拖动中，value=$value");
                                        coverBgHeightRatio = value;

                                        setBottomSheetState(() {});
                                        setState(() {});
                                      },
                                      onChangeEnd: (value) {
                                        // 拖动结束后
                                        Log.info("拖动结束，value=$value");
                                        SpProfile.setCoverBgHeightRatio(value);
                                      },
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Text(
                                        "${coverBgHeightRatio.toPrecision(2)}",
                                        textScaleFactor: 0.8),
                                  )
                                ],
                              ),
                            ))
                      ],
                    ),
                  )),
    );
  }

  // 构建评分栏
  _buildRatingStars() {
    return AnimeRatingBar(
        rate: _anime.rate,
        onRatingUpdate: (v) {
          Log.info("评价分数：$v");
          _anime.rate = v.toInt();
          SqliteUtil.updateAnimeRate(_anime.animeId, _anime.rate);
        });
  }

  // 显示信息按钮，点击后进入动漫属性信息页
  _showInfoIcon() {
    return IconTextButton(
      iconData: EvaIcons.infoOutline,
      title: "信息",
      onTap: () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AnimePropertiesPage()));
      },
    );
  }

  // 显示评价按钮，点击后进入评价列表页
  _showRateIcon() {
    return IconTextButton(
      iconData: EvaIcons.messageCircleOutline,
      title: "$rateNoteCount条评价",
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (context) => AnimeRateListPage(_anime)))
            .then((value) {
          // 重新查询评价数量
          _loadRateNoteCnt();
        });
      },
    );
  }

  // 显示收藏按钮，点击后可以修改清单
  _showCollectIcon() {
    return IconTextButton(
      iconData: _anime.isCollected() ? EvaIcons.heart : EvaIcons.heartOutline,
      iconColor: _anime.isCollected() ? Colors.red : null,
      title: _anime.isCollected() ? _anime.tagName : "",
      onTap: () => _dialogSelectTag(),
    );
  }

  _buildEpisodeTile(int episodeIndex) {
    return ListTile(
      selectedTileColor: multiSelectedColor,
      selected: mapSelected.containsKey(episodeIndex),
      // visualDensity: const VisualDensity(vertical: -2),
      // contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      title: Text(
        "第${_episodes[episodeIndex].number}集",
        style: TextStyle(
          color:
              ThemeUtil.getEpisodeListTile(_episodes[episodeIndex].isChecked()),
        ),
        // textScaleFactor: ThemeUtil.smallScaleFactor,
      ),
      // 没有完成时不显示subtitle
      subtitle: _episodes[episodeIndex].isChecked()
          ? Text(
              _episodes[episodeIndex].getDate(),
              style: TextStyle(
                color: ThemeUtil.getEpisodeListTile(
                    _episodes[episodeIndex].isChecked()),
              ),
              textScaleFactor: ThemeUtil.smallScaleFactor,
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return SimpleDialog(
                  children: [
                    ListTile(
                      title: const Text("设置日期"),
                      leading: const Icon(Icons.edit_calendar_rounded),
                      style: ListTileStyle.drawer,
                      onTap: () {
                        mapSelected[episodeIndex] = true;
                        // 退出对话框
                        Navigator.of(dialogContext).pop();
                        multiPickDateTime();
                      },
                    )
                  ],
                );
              });
        },
      ),
      leading: IconButton(
        // iconSize: 20,
        visualDensity: VisualDensity.compact, // 缩小leading
        // hoverColor: Colors.transparent, // 悬停时的颜色
        // highlightColor: Colors.transparent, // 长按时的颜色
        // splashColor: Colors.transparent, // 点击时的颜色
        onPressed: () async {
          if (_episodes[episodeIndex].isChecked()) {
            _dialogRemoveDate(
              _episodes[episodeIndex].number,
              _episodes[episodeIndex].dateTime,
            ); // 这个函数执行完毕后，在执行下面的setState并不会更新页面，因此需要在该函数中使用setState
          } else {
            String date = DateTime.now().toString();
            SqliteUtil.insertHistoryItem(_anime.animeId,
                _episodes[episodeIndex].number, date, _anime.reviewNumber);
            _episodes[episodeIndex].dateTime = date;
            // 同时插入空笔记，记得获取最新插入的id，否则进入的是笔记0，会造成修改笔记无效
            Note episodeNote = Note(
                anime: _anime,
                episode: _episodes[episodeIndex],
                relativeLocalImages: [],
                imgUrls: []);

            // 一定要先添加笔记，否则episodeIndex会越界
            _notes.add(episodeNote);
            // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
            _notes[episodeIndex] = await NoteDao
                .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                    episodeNote);
            // 不存在，则添加新笔记。因为获取笔记的函数中也实现了没有则添加新笔记，因此就不需要这个了
            // episodeNote.episodeNoteId =
            //     await SqliteUtil.insertEpisodeNote(episodeNote);
            // episodeNotes[i] = episodeNote; // 更新
            setState(() {});

            // 如果完成了最后一集(完结+当前集号为最大集号)，则提示是否要修改清单
            if (_episodes[episodeIndex].number == _anime.animeEpisodeCnt &&
                _anime.playStatus.contains("完结")) {
              // 之前点击了不再提示
              bool showModifyChecklistDialog = SPUtil.getBool(
                  "showModifyChecklistDialog",
                  defaultValue: true);
              if (!showModifyChecklistDialog) return;

              // 获取之前选择的清单，如果是第一次则默认选中第一个清单，如果之前选的清单后来删除了，不在列表中，也要选中第一个清单
              String selectedFinishedTag =
                  SPUtil.getString("selectedFinishedTag");
              bool existSelectedFinishedTag = tags.indexWhere(
                      (element) => selectedFinishedTag == element) !=
                  -1;
              if (!existSelectedFinishedTag) {
                selectedFinishedTag = tags[0];
              }

              // 之前点击了总是。那么就修改清单而不需要弹出对话框了
              if (existSelectedFinishedTag &&
                  SPUtil.getBool("autoMoveToFinishedTag",
                      defaultValue: false)) {
                _anime.tagName = selectedFinishedTag;
                SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
                Log.info("修改清单为${_anime.tagName}");
                setState(() {});
                return;
              }

              // 弹出对话框
              showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return StatefulBuilder(builder: (context, dialogState) {
                      return AlertDialog(
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("已看完最后一集，\n是否需要移动清单？"),
                              DropdownButton<String>(
                                  dropdownColor: ThemeUtil.getCardColor(),
                                  value: selectedFinishedTag,
                                  items: tags
                                      .map((e) => DropdownMenuItem(
                                            child: Text(e),
                                            value: e,
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    selectedFinishedTag =
                                        value ?? selectedFinishedTag;
                                    dialogState(() {});
                                  })
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                SPUtil.setBool(
                                    "showModifyChecklistDialog", false);
                                Navigator.pop(dialogContext);
                              },
                              child: const Text("不再提醒")),
                          TextButton(
                              onPressed: () {
                                SPUtil.setBool("autoMoveToFinishedTag", true);

                                _anime.tagName = selectedFinishedTag;
                                SPUtil.setString(
                                    "selectedFinishedTag", selectedFinishedTag);
                                SqliteUtil.updateTagByAnimeId(
                                    _anime.animeId, _anime.tagName);
                                Log.info("修改清单为${_anime.tagName}");
                                setState(() {});
                                Navigator.pop(dialogContext);
                              },
                              child: const Text("总是")),
                          TextButton(
                            onPressed: () {
                              _anime.tagName = selectedFinishedTag;
                              SPUtil.setString(
                                  "selectedFinishedTag", selectedFinishedTag);
                              SqliteUtil.updateTagByAnimeId(
                                  _anime.animeId, _anime.tagName);
                              Log.info("修改清单为${_anime.tagName}");
                              setState(() {});
                              Navigator.pop(dialogContext);
                            },
                            child: const Text("仅本次"),
                          )
                        ],
                      );
                    });
                  });
            }
          }
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _episodes[episodeIndex].isChecked()
              ? Icon(
                  // Icons.check_box_outlined,
                  // EvaIcons.checkmarkSquare2Outline,
                  EvaIcons.checkmarkSquare,
                  key: Key("$episodeIndex"), // 不能用unique，否则同状态的按钮都会有动画
                  color: ThemeUtil.getEpisodeListTile(
                      _episodes[episodeIndex].isChecked()),
                )
              : Icon(
                  // Icons.check_box_outline_blank,
                  EvaIcons.square,
                  color: ThemeUtil.getEpisodeListTile(
                      _episodes[episodeIndex].isChecked()),
                ),
        ),
      ),
      onTap: () {
        onpressEpisode(episodeIndex);
      },
      onLongPress: () async {
        onLongPressEpisode(episodeIndex);
      },
    );
  }

  _buildNote(int episodeIndex, BuildContext context) {
    // 由于排序后集列表排了序，但笔记列表没有排序，会造成笔记混乱，因此显示笔记时，根据该集的编号来找到笔记
    int noteIdx = _notes.indexWhere(
        (element) => element.episode.number == _episodes[episodeIndex].number);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: _notes[noteIdx].relativeLocalImages.isEmpty &&
              _notes[noteIdx].noteContent.isEmpty
          ? Container()
          : Card(
              elevation: 0,
              color: ThemeUtil.getCardColor(),
              child: MaterialButton(
                padding: _notes[noteIdx].noteContent.isEmpty
                    ? const EdgeInsets.fromLTRB(0, 15, 0, 15)
                    : const EdgeInsets.fromLTRB(0, 5, 0, 15),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return NoteEdit(_notes[noteIdx]);
                      },
                    ),
                  ).then((value) {
                    _notes[noteIdx] = value; // 更新修改
                    setState(() {});
                  });
                },
                child: Column(
                  children: [
                    // 笔记内容
                    _notes[noteIdx].noteContent.isEmpty
                        ? Container()
                        : ListTile(
                            title: Text(
                              _notes[noteIdx].noteContent,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                              style: ThemeUtil.getNoteTextStyle(),
                            ),
                            style: ListTileStyle.drawer,
                          ),
                    // 没有图片时不显示，否则有固定高度
                    _notes[noteIdx].relativeLocalImages.isEmpty
                        ? Container()
                        :
                        // 图片横向排列
                        Container(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            height: 120, // 设置高度
                            // color: Colors.redAccent,
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    _notes[noteIdx].relativeLocalImages.length,
                                itemBuilder: (context, imgIdx) {
                                  return MaterialButton(
                                    padding: Platform.isAndroid
                                        ? const EdgeInsets.fromLTRB(5, 5, 5, 5)
                                        : const EdgeInsets.fromLTRB(
                                            15, 5, 15, 5),
                                    onPressed: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                        // 点击图片进入图片浏览页面
                                        return ImageViewer(
                                          relativeLocalImages: _notes[noteIdx]
                                              .relativeLocalImages,
                                          initialIndex: imgIdx,
                                        );
                                      }));
                                    },
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: CommonImage(ImageUtil
                                              .getAbsoluteNoteImagePath(_notes[
                                                      noteIdx]
                                                  .relativeLocalImages[imgIdx]
                                                  .path)),
                                        )),
                                  );
                                }),
                          )
                    // ImageGridView(
                    //     relativeLocalImages:
                    //         _episodeNotes[episodeNoteIndex].relativeLocalImages)
                  ],
                ),
              ),
            ),
    );
  }

  void onpressEpisode(int episodeIndex) {
    // 多选
    if (multiSelected) {
      if (mapSelected.containsKey(episodeIndex)) {
        mapSelected.remove(episodeIndex); // 选过，再选就会取消
        // 如果取消后一个都没选，就自动退出多选状态
        if (mapSelected.isEmpty) {
          multiSelected = false;
        }
      } else {
        mapSelected[episodeIndex] = true;
        // 选择后，更新最后一次多选时选择的集下标(不管是选择还是又取消了，因为如果是取消，无法获取上一次短按的集下标)
        lastMultiSelectedIndex = episodeIndex;
      }
      setState(() {});
    } else {
      FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
      if (_episodes[episodeIndex].isChecked()) {
        Navigator.of(context).push(
          // MaterialPageRoute(
          //     builder: (context) => EpisodeNoteSF(episodeNotes[i])),
          MaterialPageRoute(
            builder: (context) {
              return NoteEdit(_notes[episodeIndex]);
            },
          ),
        ).then((value) {
          _notes[episodeIndex] = value; // 更新修改
          setState(() {});
        });
      }
    }
  }

  void onLongPressEpisode(int index) {
    // 非多选状态下才需要进入多选状态
    if (multiSelected == false) {
      multiSelected = true;
      mapSelected[index] = true;
      lastMultiSelectedIndex = index; // 第一次也要设置最后一次多选的集下标
      setState(() {}); // 添加操作按钮
    } else {
      // 如果存在上一次多选集的下标，则将中间的所有集选择
      if (lastMultiSelectedIndex >= 0) {
        // 注意大小关系[lastMultiSelectedIndex, index]和[index, lastMultiSelectedIndex]
        int begin =
            lastMultiSelectedIndex < index ? lastMultiSelectedIndex : index;
        int end =
            lastMultiSelectedIndex > index ? lastMultiSelectedIndex : index;
        for (var i = begin; i <= end; i++) {
          mapSelected[i] = true;
        }
        setState(() {});
      }
    }
  }

  Future<String> _showDatePicker({DateTime? defaultDateTime}) async {
    DateTime? datePicker = await showDatePicker(
      context: context,
      initialDate: defaultDateTime ?? DateTime.now(),
      // 没有给默认时间时，设置为今天
      firstDate: DateTime(1986),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    // 如果没有选择日期，则直接返回
    if (datePicker == null) return "";
    TimeOfDay? timePicker = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    // 同理
    if (timePicker == null) return "";
    return DateTime(datePicker.year, datePicker.month, datePicker.day,
            timePicker.hour, timePicker.minute)
        .toString();
  }

  _buildButtonsBarAboutEpisodeMulti() {
    return !multiSelected
        ? Container()
        : Container(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 8,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50))),
              // 圆角
              clipBehavior: Clip.antiAlias,
              // 设置抗锯齿，实现圆角背景
              margin: const EdgeInsets.fromLTRB(80, 20, 80, 20),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        if (mapSelected.length == _episodes.length) {
                          // 全选了，点击则会取消全选
                          mapSelected.clear();
                        } else {
                          // 其他情况下，全选
                          for (int j = 0; j < _episodes.length; ++j) {
                            mapSelected[j] = true;
                          }
                        }
                        setState(() {});
                      },
                      icon: const Icon(Icons.select_all_rounded),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: multiPickDateTime,
                      icon: const Icon(Icons.edit_calendar_rounded),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.exit_to_app),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  // 多选后，选择日期，并更新数据库
  // 尾部的选择日期按钮也可以使用该方法，记得提前加入到多选中
  void multiPickDateTime() async {
    DateTime defaultDateTime = DateTime.now();
    String dateTime = await _showDatePicker(defaultDateTime: defaultDateTime);
    if (dateTime.isEmpty) return;

    // 遍历选中的下标
    mapSelected.forEach((episodeIndex, value) {
      int episodeNumber = _episodes[episodeIndex].number;
      if (_episodes[episodeIndex].isChecked()) {
        SqliteUtil.updateHistoryItem(
            _anime.animeId, episodeNumber, dateTime, _anime.reviewNumber);
      } else {
        SqliteUtil.insertHistoryItem(
            _anime.animeId, episodeNumber, dateTime, _anime.reviewNumber);
        // 同时插入空笔记，记得获取最新插入的id，否则进入的是笔记0，会造成修改笔记无效
        Note episodeNote = Note(
            anime: _anime,
            episode: _episodes[episodeIndex],
            relativeLocalImages: [],
            imgUrls: []);
        // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
        () async {
          _notes[episodeIndex] = await NoteDao
              .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                  episodeNote);
        }(); // 只让恢复笔记作为异步，如果让forEach中的函数作为异步，则可能会在改变所有时间前退出多选模式
      }
      _episodes[episodeIndex].dateTime = dateTime;
    });
    // 退出多选模式
    _quitMultiSelectState();
  }

  void _quitMultiSelectState() {
    // 清空选择的动漫(注意在修改数量之后)，并消除多选状态
    multiSelected = false;
    mapSelected.clear();
    setState(() {});
  }

  void _dialogRemoveDate(int episodeNumber, String? date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('是否撤销日期?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('否'),
            ),
            ElevatedButton(
              onPressed: () {
                SqliteUtil
                    .deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(
                        _anime.animeId, episodeNumber, _anime.reviewNumber);
                // 根据episodeNumber找到对应的下标
                int findIndex = _getEpisodeIndexByEpisodeNumber(episodeNumber);
                _episodes[findIndex].cancelDateTime();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('是'),
            ),
          ],
        );
      },
    );
  }

  void _dialogSelectTag() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < tags.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(tags[i]),
              leading: tags[i] == _anime.tagName
                  ? Icon(
                      Icons.radio_button_on_outlined,
                      color: ThemeUtil.getPrimaryColor(),
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                _anime.tagName = tags[i];
                SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
                Log.info("修改清单为${_anime.tagName}");
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('选择清单'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  List<String> sortMethods = [
    "sortByEpisodeNumberAsc",
    "sortByEpisodeNumberDesc",
    "sortByUnCheckedFront"
  ];

  List<String> sortMethodsName = ["集数升序", "集数倒序", "未完成在前"];

  void _dialogSelectSortMethod() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < sortMethods.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(sortMethodsName[i]),
              leading: sortMethods[i] == SPUtil.getString("episodeSortMethod")
                  ? Icon(
                      Icons.radio_button_on_outlined,
                      color: ThemeUtil.getPrimaryColor(),
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                Log.info("修改排序方式为${sortMethods[i]}");
                _sortEpisodes(sortMethods[i]);
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('排序方式'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  _dialogDeleteAnime() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("提示"),
            content: const Text("这将会删除所有相关记录，\n确认取消收藏吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消")),
              ElevatedButton(
                  onPressed: () {
                    SqliteUtil.deleteAnimeByAnimeId(_anime.animeId);
                    // 关闭当前对话框后，调用函数去关闭动漫详细页，注意两者的context是不同的
                    Navigator.of(context).pop();
                    _popAnimeDetailPage();
                  },
                  child: const Text("确认")),
            ],
          );
        });
  }

  // 获取当前集范围的字符串形式
  String _getEpisodeRangeStr(int startEpisodeNumber) {
    if (_anime.animeEpisodeCnt == 0) {
      return "00-00";
    }
    int endEpisodeNumber = startEpisodeNumber + episodeRangeSize - 1;
    if (endEpisodeNumber > _anime.animeEpisodeCnt) {
      endEpisodeNumber = _anime.animeEpisodeCnt;
    }

    return startEpisodeNumber.toString().padLeft(2, '0') +
        "-" +
        endEpisodeNumber.toString().padLeft(2, '0');
  }

  _buildEpisodeRangeChips(context) {
    List<Widget> chips = [];
    for (var startEpisodeNumber = 1;
        startEpisodeNumber <= _anime.animeEpisodeCnt;
        startEpisodeNumber += episodeRangeSize) {
      chips.add(GestureDetector(
        onTap: () {
          currentStartEpisodeNumber = startEpisodeNumber;
          SPUtil.setInt("${widget.anime.animeId}-currentStartEpisodeNumber",
              currentStartEpisodeNumber);
          Navigator.of(context).pop();
          // 获取集数据
          _loadEpisode();
        },
        child: Chip(
          label: Text(_getEpisodeRangeStr((startEpisodeNumber)),
              textScaleFactor: ThemeUtil.tinyScaleFactor),
          backgroundColor: currentStartEpisodeNumber == startEpisodeNumber
              ? Colors.grey
              : null,
        ),
      ));
    }
    return chips;
  }

  // 动漫信息下面的操作栏
  _buildButtonsAboutEpisode() {
    if (!_anime.isCollected()) return Container();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MaterialButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("选择范围"),
                    content: SingleChildScrollView(
                      child: Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: _buildEpisodeRangeChips(context),
                      ),
                    ),
                  );
                },
              );
            },
            child: Row(
              children: [
                const Icon(Icons.arrow_right_rounded),
                Text(_getEpisodeRangeStr(currentStartEpisodeNumber)),
              ],
            ),
          ),
          // _buildReviewNumberTextButton(),
          const SizedBox(width: 10),
          Expanded(child: Container()),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _dialogSelectReviewNumber,
                // 使用自带图标
                // icon: _showReviewNumberIcon()
                // 绘制圆角方块，中间添加数字
                icon: Container(
                  width: 18,
                  height: 18,
                  child: Center(
                      child: Text("${_anime.reviewNumber}",
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500))),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: ThemeUtil
                                  .themeController.themeColor.value.isDarkMode
                              ? Colors.grey
                              : Colors.black,
                          width: 2)),
                ),
              ),
              IconButton(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () {
                    _dialogSelectSortMethod();
                  },
                  tooltip: "排序方式",
                  icon: const Icon(Icons.filter_list)),
              IconButton(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () {
                    if (hideNoteInAnimeDetail) {
                      // 原先隐藏，则设置为false，表示显示
                      SPUtil.setBool("hideNoteInAnimeDetail", false);
                      hideNoteInAnimeDetail = false;
                      // showToast("已展开笔记");
                    } else {
                      SPUtil.setBool("hideNoteInAnimeDetail", true);
                      hideNoteInAnimeDetail = true;
                      // showToast("已隐藏笔记");
                    }
                    setState(() {});
                  },
                  tooltip: hideNoteInAnimeDetail ? "显示笔记" : "隐藏笔记",
                  icon: hideNoteInAnimeDetail
                      ? const Icon(EvaIcons.expandOutline)
                      : const Icon(EvaIcons.collapseOutline)),
              // ? const Icon(Icons.unfold_more)
              // : const Icon(Icons.unfold_less)),
            ],
          ),
        ],
      ),
    );
  }

  void _dialogSelectReviewNumber() {
    dialogSelectUint(context, "选择第几次观看",
            initialValue: _anime.reviewNumber, minValue: 1, maxValue: 9)
        .then((value) {
      if (value != null) {
        if (_anime.reviewNumber != value) {
          _anime.reviewNumber = value;
          // SqliteUtil.updateAnimeReviewNumberByAnimeId(
          //     _anime.animeId, _anime.reviewNumber);
          SqliteUtil.updateAnime(_anime, _anime);
          // 不相等才设置并重新加载数据
          _loadEpisode();
        }
      }
    });
  }

  _buildReviewNumberTextButton() {
    return GestureDetector(
      onTap: _dialogSelectReviewNumber,
      child: Row(
        children: [
          const Icon(Icons.arrow_right_rounded),
          Text("第${_anime.reviewNumber}次观看"),
        ],
      ),
    );
  }

  void _sortEpisodes(String sortMethod) {
    if (sortMethod == "sortByEpisodeNumberAsc") {
      _sortByEpisodeNumberAsc();
    } else if (sortMethod == "sortByEpisodeNumberDesc") {
      _sortByEpisodeNumberDesc();
    } else if (sortMethod == "sortByUnCheckedFront") {
      _sortByUnCheckedFront();
    } else {
      throw "不可能的排序方式";
    }
    SPUtil.setString("episodeSortMethod", sortMethod);
  }

  void _sortByEpisodeNumberAsc() {
    _episodes.sort((a, b) {
      return a.number.compareTo(b.number);
    });
    _notes.sort((a, b) {
      return a.episode.number.compareTo(b.episode.number);
    });
  }

  void _sortByEpisodeNumberDesc() {
    _episodes.sort((a, b) {
      return b.number.compareTo(a.number);
    });
    _notes.sort((a, b) {
      return b.episode.number.compareTo(a.episode.number);
    });
  }

  // 未完成的靠前，完成的按number升序排序
  void _sortByUnCheckedFront() {
    _sortByEpisodeNumberAsc(); // 先按number升序排序
    _episodes.sort((a, b) {
      int ac, bc;
      ac = a.isChecked() ? 1 : 0;
      bc = b.isChecked() ? 1 : 0;
      // 双方都没有完成或都完成(状态一致)时，按number升序排序
      if (a.isChecked() == b.isChecked()) {
        return a.number.compareTo(b.number);
      } else {
        // 否则未完成的靠前
        return ac.compareTo(bc);
      }
    });
    _notes.sort((a, b) {
      int ac, bc;
      ac = a.episode.isChecked() ? 1 : 0;
      bc = b.episode.isChecked() ? 1 : 0;
      // 双方都没有完成或都完成(状态一致)时，按number升序排序
      if (a.episode.isChecked() == b.episode.isChecked()) {
        return a.episode.number.compareTo(b.episode.number);
      } else {
        // 否则未完成的靠前
        return ac.compareTo(bc);
      }
    });
  }

  // 如果设置了未完成的靠前，则完成某集后移到最后面
  // 如果取消了日期，还需要移到最前面。好麻烦...还得插入到合适的位置
  // 不改变位置的好处：误点击完成了，不用翻到最下面取消
  // void _moveToLastIfSet(int index) {
  //   // 先不用移到最后面吧
  //   // // 先移除，再添加
  //   // if (SPUtil.getBool("sortByUnCheckedFront")) {
  //   //   Episode episode = _episodes[index];
  //   //   _episodes.removeAt(index);
  //   //   _episodes.add(episode); // 不应该直接在后面添加，而是根据number插入到合适的位置。但还要注意越界什么的
  //   // }
  // }

  int _getEpisodeIndexByEpisodeNumber(int episodeNumber) {
    return _episodes.indexWhere((element) => element.number == episodeNumber);
  }

  bool _climbing = false;

  Future<bool> _climbAnimeInfo() async {
    if (_anime.animeUrl.isEmpty) {
      if (_anime.isCollected()) showToast("不能更新自定义动漫");
      return false;
    }
    if (_climbing) {
      if (_anime.isCollected()) showToast("正在获取信息");
      return false;
    }
    if (_anime.isCollected()) showToast("更新中...");
    _climbing = true;
    // oldAnime、newAnime、_anime引用的是同一个对象，修改后无法比较，因此需要先让oldAnime引用深拷贝的_anime
    // 因为更新时会用到oldAnime的id、tagName、animeEpisodeCnt，所以只深拷贝这些成员
    Anime oldAnime = _anime.copyWith();
    // 需要传入_anime，然后会修改里面的值，newAnime也会引用该对象
    Log.info("_anime.animeEpisodeCnt = ${_anime.animeEpisodeCnt}");
    Anime newAnime = await ClimbAnimeUtil.climbAnimeInfoByUrl(_anime);
    // 如果更新后动漫集数比原来的集数小，则不更新集数
    // 目的是解决一个bug：东京喰种PINTO手动设置集数为2后，更新动漫，获取的集数为0，集数更新为0后，此时再次手动修改集数，因为传入的初始值为0，即使按了取消，由于会返回初始值0，因此会导致集数变成了0
    // 因此，只要用户设置了集数，即使更新的集数小，也会显示用户设置的集数，只有当更新集数大时，才会更新。
    // 另一种解决方式：点击修改集数按钮时，传入此时_episodes的长度，而不是_anime.animeEpisodeCnt，这样就保证了传入给修改集数对话框的初始值为原来的集数，而不是更新的集数。
    Log.info("_anime.animeEpisodeCnt = ${_anime.animeEpisodeCnt}");
    if (newAnime.animeEpisodeCnt < _anime.animeEpisodeCnt) {
      newAnime.animeEpisodeCnt = _anime.animeEpisodeCnt;
    }
    SqliteUtil.updateAnime(oldAnime, newAnime).then((value) {
      // 如果集数变大，则重新加载页面。且插入到更新记录表中，然后重新获取所有更新记录，便于在更新记录页展示
      if (newAnime.animeEpisodeCnt > oldAnime.animeEpisodeCnt) {
        _loadData();
        // 调用控制器，添加更新记录到数据库并更新内存数据
        final UpdateRecordController updateRecordController = Get.find();
        updateRecordController.updateSingaleAnimeData(oldAnime, newAnime);
      }
    });
    _anime = newAnime;
    _climbing = false;
    setState(() {});
    return true;
  }

  _showReviewNumberIcon() {
    switch (_anime.reviewNumber) {
      case 1:
        return const Icon(Icons.looks_one_outlined);
      case 2:
        return const Icon(Icons.looks_two_outlined);
      case 3:
        return const Icon(Icons.looks_3_outlined);
      case 4:
        return const Icon(Icons.looks_4_outlined);
      case 5:
        return const Icon(Icons.looks_5_outlined);
      case 6:
        return const Icon(Icons.looks_6_outlined);
      default:
        return const Icon(Icons.error_outline_outlined);
    }
  }

  void _popAnimeDetailPage() {
    // 置为0，用于在收藏页得知已取消收藏
    _anime.animeId = 0;
    // 退出动漫详细页面
    Navigator.of(context).pop(_anime);
  }

  void showDialogmodifyEpisodeCnt() {
    dialogSelectUint(context, "修改集数",
            initialValue: _anime.animeEpisodeCnt,
            // 传入已有的集长度而非_anime.animeEpisodeCnt，是为了避免更新动漫后，_anime.animeEpisodeCnt为0，然后点击修改集数按钮，弹出对话框，传入初始值0，如果点击了取消，就会返回初始值0，导致集数改变
            // initialValue: initialValue,
            // 添加选择集范围后，就不能传入已有的集长度了。
            // 最终解决方法就是当爬取的集数小于当前集数，则不进行修改，所以这里只管传入当前动漫的集数
            minValue: 0,
            maxValue: 2000)
        .then((value) {
      if (value == null) {
        Log.info("未选择，直接返回");
        return;
      }
      // if (value == _episodes.length) {
      if (value == _anime.animeEpisodeCnt) {
        Log.info("设置的集数等于初始值${_anime.animeEpisodeCnt}，直接返回");
        return;
      }
      int episodeCnt = value;
      SqliteUtil.updateEpisodeCntByAnimeId(_anime.animeId, episodeCnt)
          .then((value) {
        // 重新获取数据
        _anime.animeEpisodeCnt = episodeCnt;
        _loadEpisode();
      });
    });
  }
}

class IconTextButton extends StatelessWidget {
  const IconTextButton(
      {required this.iconData,
      this.iconColor,
      this.iconSize = 18,
      required this.title,
      this.titleSize = 12,
      this.onTap,
      Key? key})
      : super(key: key);

  final void Function()? onTap;
  final IconData iconData;
  final double iconSize;
  final Color? iconColor;
  final String title;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          // 必须添加颜色(透明色也可)，这样手势就能监测到Container，否则只能检测到Icon和Text
          color: Colors.transparent,
          child: Column(
            children: [
              Icon(iconData, color: iconColor, size: iconSize),
              Text(title, style: TextStyle(fontSize: titleSize))
            ],
          ),
        ));
  }
}
