import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tab_indicator_styler/flutter_tab_indicator_styler.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_climb_all_website.dart';
import 'package:flutter_test_future/scaffolds/anime_detail/anime_cover_detail.dart';
import 'package:flutter_test_future/scaffolds/anime_detail/controller/anime_controller.dart';
import 'package:flutter_test_future/scaffolds/note_edit.dart';
import 'package:flutter_test_future/scaffolds/image_viewer.dart';
import 'package:flutter_test_future/scaffolds/anime_detail/rate_list_page.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'anime_properties_page.dart';

// ignore: must_be_immutable
class AnimeDetailPlus extends StatefulWidget {
  final int animeId;
  Anime?
      parentAnime; // 用于传入动漫，目的是为了传入还没有收藏的动漫。目前没用到，点击未收藏的动漫时是直接显示添加清单对话框，而不是进入详细页
  AnimeDetailPlus(
    this.animeId, {
    Key? key,
    this.parentAnime,
  }) : super(key: key);

  @override
  _AnimeDetailPlusState createState() => _AnimeDetailPlusState();
}

class _AnimeDetailPlusState extends State<AnimeDetailPlus>
    with SingleTickerProviderStateMixin {
  late Anime _anime;
  List<Episode> _episodes = [];
  bool _loadAnimeOk = false;
  bool _loadEpisodeOk = false;
  List<EpisodeNote> _episodeNotes = [];
  late int lastMultiSelectedIndex; // 记住最后一次多选的集下标

  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  FocusNode animeNameFocusNode = FocusNode(); // 动漫名字输入框焦点
  // FocusNode descFocusNode = FocusNode(); // 描述输入框焦点

  // 多选
  Map<int, bool> mapSelected = {};
  bool multiSelected = false;
  Color multiSelectedColor = ThemeUtil.getThemePrimaryColor().withOpacity(0.25);

  bool hideNoteInAnimeDetail =
      SPUtil.getBool("hideNoteInAnimeDetail", defaultValue: false);

  // 选择显示的集范围
  int currentStartEpisodeNumber = 1;
  final int episodeRangeSize = 50;

  late TabController _tabController; // 创建tab控制器
  final List<String> _tabNames = ["选集", "评价", "详情"];

  final AnimeController animeController = Get.put(AnimeController());

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _tabNames.length, vsync: this, initialIndex: 0);
    // 添加监听器，更换tab时显示不同的页面
    _tabController.addListener(() {
      debugPrint("_tabController.index=${_tabController.index}");
      // 只有当tab变化时，才进行状态更新
      if (selectedTabIdx != _tabController.index) {
        debugPrint("切换页面");
        setState(() {
          selectedTabIdx = _tabController.index;
        });
      }
    });

    // 如果没有收藏，则不允许进入
    if (widget.animeId <= 0) {
      Navigator.of(context).pop();
      showToast("无法进入未收藏动漫");
    }

    if (widget.animeId > 0) {
      currentStartEpisodeNumber = SPUtil.getInt(
          "${widget.animeId}-currentStartEpisodeNumber",
          defaultValue: 1);
      _loadData();
    } else {
      // widget.parentAnime肯定不为null，因为已经用isCollected判断过了
      _anime = widget.parentAnime ?? Anime(animeName: "", animeEpisodeCnt: 0);
      // 爬取详细信息
      _climbAnimeInfo();
      _loadAnimeOk = true;
    }
  }

  void _loadData() async {
    await _loadAnime();
    animeController.setAnime(_anime);
    _loadEpisode();
  }

  Future<bool> _loadAnime() async {
    _loadAnimeOk = false;
    setState(() {});

    _anime = await SqliteUtil.getAnimeByAnimeId(
        widget.animeId); // 一定要return，value才有值
    // 如果没有从数据库中找到，则直接退出该页面
    if (!_anime.isCollected()) {
      Navigator.of(context).pop();
      showToast("无法进入未收藏动漫");
    }
    _loadAnimeOk = true;
    setState(() {});
    return true;
  }

  void _loadEpisode() async {
    _episodes = [];
    _episodeNotes = [];
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
    debugPrint("削减后，集长度为${_episodes.length}");
    _sortEpisodes(SPUtil.getString("episodeSortMethod",
        defaultValue: sortMethods[0])); // 排序，默认升序，兼容旧版本

    for (var episode in _episodes) {
      EpisodeNote episodeNote = EpisodeNote(
          anime: _anime,
          episode: episode,
          relativeLocalImages: [],
          imgUrls: []);
      if (episode.isChecked()) {
        // 如果该集完成了，就去获取该集笔记（内容+图片）
        episodeNote = await SqliteUtil
            .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                episodeNote);
        // debugPrint(
        //     "第${episodeNote.episode.number}集的图片数量: ${episodeNote.relativeLocalImages.length}");
      }
      _episodeNotes.add(episodeNote);
    }
    _loadEpisodeOk = true;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
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
    return WillPopScope(
      onWillPop: () async {
        debugPrint("按返回键，返回anime");
        _refreshAnime();
        // 返回的_anime用到了id(列表页面和搜索页面)和name(爬取页面)
        // 完成集数因为切换到小的回顾号会导致不是最大回顾号完成的集数，所以那些页面会通过传回的id来获取最新动漫信息
        Navigator.pop(context, _anime);
        debugPrint("返回true");
        return true;
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !_loadAnimeOk
              ? Container(key: UniqueKey())
              : RefreshIndicator(
                  onRefresh: () async {
                    // 使用await后，只有当获取信息完成后，加载圈才会消失
                    await _climbAnimeInfo();
                  },
                  child: Stack(children: [
                    CustomScrollView(
                      slivers: [
                        _buildSliverAppBar(context),
                        _buildSliverListBody()
                      ],
                    ),
                    _buildButtonsBarAboutEpisodeMulti()
                  ]),
                ),
        ),
      ),
    );
  }

  _buildSliverListBody() {
    return SliverPadding(
      padding: const EdgeInsets.all(0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildTabRow(),
          GestureDetector(
            // onHorizontalDragEnd: _swipeFunction,
            child: _buildTabBody(),
          )
        ]),
      ),
    );
  }

  int selectedTabIdx = 0;

  // 左右滑动切换tab
  // 注意如果body没有元素，则无法切换，可以试着填充
  // 不采用该方式，原因：有些元素不整齐，所以滑动时有时正常有时不行
  void _swipeFunction(DragEndDetails dragEndDetails) {
    // 切换到右边tab
    if (dragEndDetails.primaryVelocity! < 0 &&
        selectedTabIdx + 1 < _tabNames.length) {
      selectedTabIdx++;
      _tabController.index = selectedTabIdx;
      setState(() {});
    }
    // 切换到左边tab
    if (dragEndDetails.primaryVelocity! > 0 && selectedTabIdx - 1 >= 0) {
      selectedTabIdx--;
      _tabController.index = selectedTabIdx;
      setState(() {});
    }
  }

  _buildTabRow() {
    return PreferredSize(
      // 默认情况下，要将标签栏与相同的标题栏高度对齐，可以使用常量kToolbarHeight
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Material(
        color: ThemeUtil.getScaffoldBackgroundColor(),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            tabs: _buildTabs(),
            controller: _tabController,
            // 居中，而不是靠左下
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            // 标签可以滑动，避免拥挤
            isScrollable: true,
            labelPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            // 指示器长短和标签一样
            indicatorSize: TabBarIndicatorSize.label,
            // 第三方指示器样式
            indicator: MaterialIndicator(
              color: ThemeUtil.getThemePrimaryColor(),
              paintingStyle: PaintingStyle.fill,
            ),
          ),
        ),
      ),
    );
  }

  _buildTabBody() {
    // 可以嵌套Column，不能嵌套ListView(指定physics: NeverScrollableScrollPhysics(),也不行)、Scaffold。
    // 因为要和SliverAppBar作用在一块，移动Column是作为和AppBar整体滑动的
    switch (selectedTabIdx) {
      case 0:
        return _buildEpisodePage();
      case 1:
        return _buildRatePage();
      case 2:
        return _buildProfile();
      default:
      // nothing
    }
  }

  _buildTabs() {
    List<Widget> tabs = [];
    for (String tabName in _tabNames) {
      tabs.add(Tab(
        text: tabName,
      ));
    }
    return tabs;
  }

  _buildRatePage() {
    return RateListPage(_anime);
  }

  _buildProfile() {
    return AnimePropertiesPage();
  }

  _buildSliverAppBar(BuildContext context) {
    // 状态栏高度
    // double statusBarHeight = MediaQueryData.fromWindow(window).padding.top;
    // AppBar的toolbar高度(状态栏下面紧接着的一行)
    // double toolbarHeight = kToolbarHeight;
    // AppBar总高度
    // double appBarHeight = 280;

    return Obx(() => SliverAppBar(
          // floating: true,
          // snap: true,
          pinned: true,
          expandedHeight: 260,
          // stretch: true,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              children: [
                // 底层背景
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  // 模糊
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 10,
                      sigmaY: 10,
                    ),
                    child: _buildBgCover(),
                  ),
                ),
                // 为底层背景添加渐变效果
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: ThemeUtil.getGradientColors()),
                  ),
                ),
                // 动漫信息
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _showAnimeRow(),
                    ],
                  ),
                ),
                // 遮住背景封面细线
                // Positioned(
                //     bottom: -5,
                //     child: Container(
                //       height: 10,
                //       width: MediaQuery.of(context).size.width,
                //       color: ThemeUtil.getColorBelowGradientAnimeCover(),
                //     ))
              ],
            ),
          ),
          leading: IconButton(
              onPressed: () {
                debugPrint("按返回按钮，返回anime");
                _refreshAnime();
                Navigator.pop(context, _anime);
              },
              tooltip: "返回上一级",
              icon: const Icon(Icons.arrow_back_rounded)),
          title: _buildAppBarTitle(),
          actions: _buildActions(),
        ));
  }

  _buildBgCover() {
    String coverUrl = animeController.anime.value.animeCoverUrl;
    if (coverUrl.isEmpty) {
      return Image.memory(kTransparentImage);
    }
    // 网络封面
    if (coverUrl.startsWith("http")) {
      return CachedNetworkImage(
        imageUrl: coverUrl,
        errorWidget: (context, url, error) {
          return Container(
            color: const Color.fromRGBO(250, 250, 250, 1.0),
          );
        },
        fit: BoxFit.cover,
        // 设置透明度，防止背景太黑或太白看不到顶部栏
        color: ThemeUtil.getModulateColor(),
        colorBlendMode: BlendMode.modulate,
      );
    }
    //  本地封面
    return Image.file(
      File(ImageUtil.getAbsoluteCoverImagePath(_anime.animeCoverUrl)),
      fit: BoxFit.cover,
      // 设置透明度，防止背景太黑或太白看不到顶部栏
      color: ThemeUtil.getModulateColor(),
      colorBlendMode: BlendMode.modulate,
      errorBuilder: (buildContext, object, stackTrace) {
        return Container();
      },
    );
  }

  List<Widget> _buildActions() {
    if (!_anime.isCollected()) return [];
    return [
      IconButton(
          onPressed: () {
            _climbAnimeInfo();
          },
          tooltip: "更新信息",
          icon: const Icon(Icons.refresh_rounded)),
      PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        offset: const Offset(0, 50),
        itemBuilder: (BuildContext popMenuContext) {
          return [
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                title: const Text("取消收藏"),
                leading: const Icon(Icons.cancel_outlined),
                style: ListTileStyle.drawer,
                onTap: () {
                  _dialogDeleteAnime();
                },
              ),
            ),
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                title: const Text("访问网址"),
                style: ListTileStyle.drawer,
                leading: const Icon(Icons.open_in_new),
                onTap: () {
                  if (_anime.animeUrl.isNotEmpty) {
                    LaunchUrlUtil.launch(_anime.animeUrl);
                  } else {
                    showToast("网址为空，请先迁移动漫");
                  }
                  Navigator.pop(popMenuContext);
                },
              ),
            ),
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                title: const Text("迁移动漫"),
                style: ListTileStyle.drawer,
                leading: const Icon(Icons.change_circle_outlined),
                onTap: () {
                  Navigator.of(popMenuContext).push(
                    FadeRoute(
                      builder: (context) {
                        return AnimeClimbAllWebsite(
                          animeId: _anime.animeId,
                          keyword: _anime.animeName,
                        );
                      },
                    ),
                  ).then((value) {
                    _loadData();
                    Navigator.pop(popMenuContext);
                  });
                },
              ),
            ),
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                title: const Text("修改名字"),
                leading: const Icon(Icons.edit),
                style: ListTileStyle.drawer,
                onTap: () {
                  // // 先关闭下拉菜单
                  // Navigator.of(popMenuContext).pop();
                  // // 再进入编辑页面
                  // Navigator.of(context).push(
                  //   FadeRoute(
                  //     builder: (context) => AnimeInfoEdit(_anime),
                  //   ),
                  // );
                  // 编辑动漫名
                  _dialogUpdateAnimeName(popMenuContext);
                },
              ),
            ),
          ];
        },
      ),
    ];
  }

  // 使用obx来实现监听其它页面修改controller中的动漫信息变化
  _showAnimeRow() {
    return Obx(() => Row(
          children: [
            // 动漫封面
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: MaterialButton(
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          Navigator.of(context).push(FadeRoute(
                              builder: (context) => AnimeCoverDetail()));
                        },
                        child: AnimeGridCover(animeController.anime.value),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 动漫信息
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _showAnimeName(animeController.anime.value.animeName),
                  _showNameAnother(animeController.anime.value.nameAnother),
                  _showAnimeInfo(
                      animeController.anime.value.getAnimeInfoFirstLine()),
                  _showAnimeInfo(
                      animeController.anime.value.getAnimeInfoSecondLine()),
                  // Container(
                  //   alignment: Alignment.centerLeft,
                  //   padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  //   child: Row(
                  //     children: [
                  //
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            // Column(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [_showCollectIcon(animeController.anime.value)],
            // ),
          ],
        ));
  }

  _showAnimeName(animeName) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      child: SelectableText(
        animeName,
        textScaleFactor: 1.1,
        // maxLines: 1,
        style: TextStyle(
            fontWeight: FontWeight.w600, color: ThemeUtil.getFontColor()),
      ),
    );
  }

  _showNameAnother(String nameAnother) {
    return nameAnother.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(15, 5, 35, 0),
            child: SelectableText(
              nameAnother,
              style: TextStyle(color: ThemeUtil.getCommentColor(), height: 1.1),
              maxLines: 1,
            ),
          );
  }

  _showAnimeInfo(String animeInfo) {
    return animeInfo.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
            child: SelectableText(
              animeInfo,
              style: TextStyle(color: ThemeUtil.getCommentColor(), height: 1.1),
              maxLines: 1,
            ),
          );
  }

  _showCollectIcon() {
    return Container(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          IconButton(
              onPressed: () {
                // 不能使用，因为里面的删除动漫后找不到方法直接返回主页
                // dialogSelectTag(setState, context, anime);
                // _dialogSelectTag();
                debugPrint(_anime.animeCoverUrl);
              },
              icon: _anime.isCollected()
                  ? const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    )
                  : const Icon(Icons.favorite_border)),
          _anime.isCollected() ? Text(_anime.tagName) : Container()
        ],
      ),
    );
  }

  _buildEpisodePage() {
    if (!_loadEpisodeOk) {
      return SizedBox(
        key: UniqueKey(),
      );
    }

    List<Widget> columnChildren = [];
    columnChildren.add(_buildButtonsAboutEpisode());
    for (int episodeIndex = 0;
        episodeIndex < _episodes.length;
        ++episodeIndex) {
      // debugPrint("$episodeIndex");
      // 添加每集
      columnChildren.add(
        ListTile(
          selectedTileColor: multiSelectedColor,
          selected: mapSelected.containsKey(episodeIndex),
          // visualDensity: const VisualDensity(vertical: -2),
          // contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          title: Text(
            "第 ${_episodes[episodeIndex].number} 集",
            style: TextStyle(
              color: ThemeUtil.getEpisodeListTile(
                  _episodes[episodeIndex].isChecked()),
            ),
          ),
          // 没有完成时不显示subtitle
          subtitle: _episodes[episodeIndex].isChecked()
              ? Text(
                  _episodes[episodeIndex].getDate(),
                  style: TextStyle(
                      color: ThemeUtil.getEpisodeListTile(
                          _episodes[episodeIndex].isChecked())),
                )
              : null,
          trailing: PopupMenuButton(
              icon: const Icon(Icons.more_horiz),
              offset: const Offset(0, 50),
              itemBuilder: (BuildContext popMenuContext) {
                return [
                  PopupMenuItem(
                    padding: const EdgeInsets.all(0),
                    child: ListTile(
                      title: const Text("设置日期"),
                      leading: const Icon(Icons.calendar_today_outlined),
                      style: ListTileStyle.drawer,
                      onTap: () {
                        mapSelected[episodeIndex] = true;
                        multiPickDateTime();
                        // 退出下拉菜单
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ];
              }),
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
                EpisodeNote episodeNote = EpisodeNote(
                    anime: _anime,
                    episode: _episodes[episodeIndex],
                    relativeLocalImages: [],
                    imgUrls: []);

                // 一定要先添加笔记，否则episodeIndex会越界
                _episodeNotes.add(episodeNote);
                // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
                _episodeNotes[episodeIndex] = await SqliteUtil
                    .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                        episodeNote);
                // 不存在，则添加新笔记。因为获取笔记的函数中也实现了没有则添加新笔记，因此就不需要这个了
                // episodeNote.episodeNoteId =
                //     await SqliteUtil.insertEpisodeNote(episodeNote);
                // episodeNotes[i] = episodeNote; // 更新
                setState(() {});
              }
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _episodes[episodeIndex].isChecked()
                  ? Icon(
                      Icons.check_box_outlined,
                      key: Key("$episodeIndex"), // 不能用unique，否则同状态的按钮都会有动画
                      color: ThemeUtil.getEpisodeListTile(
                          _episodes[episodeIndex].isChecked()),
                    )
                  : Icon(
                      Icons.check_box_outline_blank_rounded,
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
        ),
      );

      // 在每一集下面添加笔记
      if (!hideNoteInAnimeDetail && _episodes[episodeIndex].isChecked()) {
        columnChildren.add(_buildNote(episodeIndex, context));
      }

      // 在最后一集下面添加空白
      if (episodeIndex == _episodes.length - 1) {
        columnChildren.add(const ListTile());
        columnChildren.add(const ListTile());
      }
    }
    return Column(
      children: columnChildren,
    );
  }

  _buildNote(int episodeIndex, BuildContext context) {
    // 由于排序后集列表排了序，但笔记列表没有排序，会造成笔记混乱，因此显示笔记时，根据该集的编号来找到笔记
    int episodeNoteIndex = _episodeNotes.indexWhere(
        (element) => element.episode.number == _episodes[episodeIndex].number);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: _episodeNotes[episodeNoteIndex].relativeLocalImages.isEmpty &&
              _episodeNotes[episodeNoteIndex].noteContent.isEmpty
          ? Container()
          : Card(
              elevation: 0,
              color: ThemeUtil.getNoteListBackgroundColor(),
              child: MaterialButton(
                padding: _episodeNotes[episodeNoteIndex].noteContent.isEmpty
                    ? const EdgeInsets.fromLTRB(0, 0, 0, 0)
                    : const EdgeInsets.fromLTRB(0, 5, 0, 0), // 5是笔记内容和上边界之间的距离
                onPressed: () {
                  Navigator.of(context).push(
                    // MaterialPageRoute(
                    //     builder: (context) =>
                    //         EpisodeNoteSF(episodeNotes[episodeIndex])),
                    FadeRoute(
                      builder: (context) {
                        return NoteEdit(_episodeNotes[episodeNoteIndex]);
                      },
                    ),
                  ).then((value) {
                    _episodeNotes[episodeNoteIndex] = value; // 更新修改
                    setState(() {});
                  });
                },
                child: Column(
                  children: [
                    // 笔记内容
                    _episodeNotes[episodeNoteIndex].noteContent.isEmpty
                        ? Container()
                        : ListTile(
                            title: Text(
                              _episodeNotes[episodeNoteIndex].noteContent,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ListTileStyle.drawer,
                          ),
                    // 没有图片时不显示，否则有固定高度
                    _episodeNotes[episodeNoteIndex].relativeLocalImages.isEmpty
                        ? Container()
                        :
                        // 图片横向排列
                        Container(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            height: 120, // 设置高度
                            // color: Colors.redAccent,
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _episodeNotes[episodeNoteIndex]
                                    .relativeLocalImages
                                    .length,
                                itemBuilder: (context, imageIndex) {
                                  return MaterialButton(
                                    padding: Platform.isAndroid
                                        ? const EdgeInsets.fromLTRB(5, 5, 5, 5)
                                        : const EdgeInsets.fromLTRB(
                                            15, 5, 15, 5),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          FadeRoute(
                                              // 因为里面的浏览器切换图片时自带了过渡效果，所以取消这个过渡
                                              transitionDuration: Duration.zero,
                                              reverseTransitionDuration:
                                                  Duration.zero,
                                              builder: (context) {
                                                // 点击图片进入图片浏览页面
                                                return ImageViewer(
                                                  relativeLocalImages:
                                                      _episodeNotes[
                                                              episodeNoteIndex]
                                                          .relativeLocalImages,
                                                  initialIndex: imageIndex,
                                                );
                                              }));
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: Image.file(
                                        File(
                                          ImageUtil.getAbsoluteNoteImagePath(
                                              _episodeNotes[episodeNoteIndex]
                                                  .relativeLocalImages[
                                                      imageIndex]
                                                  .path),
                                        ),
                                        errorBuilder: errorImageBuilder(
                                          _episodeNotes[episodeNoteIndex]
                                              .relativeLocalImages[imageIndex]
                                              .path,
                                          fallbackHeight: 100,
                                          fallbackWidth: 100,
                                        ),
                                        // errorBuilder:
                                        //     (context, error, stackTrace) =>
                                        //         const Placeholder(
                                        //   fallbackHeight: 100,
                                        //   fallbackWidth: 100,
                                        // ),
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
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
          FadeRoute(
            builder: (context) {
              return NoteEdit(_episodeNotes[episodeIndex]);
            },
          ),
        ).then((value) {
          _episodeNotes[episodeIndex] = value; // 更新修改
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
        locale: const Locale("zh"));
    // 如果没有选择日期，则直接返回
    if (datePicker == null) return "";
    TimeOfDay? timePicker = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      // 中文
      builder: (BuildContext context, Widget? child) {
        return Localizations(
          locale: const Locale('zh'),
          child: child,
          delegates: const <LocalizationsDelegate>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
        );
      },
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
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.exit_to_app_outlined),
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
        EpisodeNote episodeNote = EpisodeNote(
            anime: _anime,
            episode: _episodes[episodeIndex],
            relativeLocalImages: [],
            imgUrls: []);
        // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
        () async {
          _episodeNotes[episodeIndex] = await SqliteUtil
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
                      color: ThemeUtil.getThemePrimaryColor(),
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                _anime.tagName = tags[i];
                SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
                debugPrint("修改清单为${_anime.tagName}");
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
                      color: ThemeUtil.getThemePrimaryColor(),
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                debugPrint("修改排序方式为${sortMethods[i]}");
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
                    // 返回两次，跳过动漫详细页(然而并不能)
                    // Navigator.of(context).pop();
                    // Navigator.of(context).pop();
                    // 关闭当前对话框后，调用函数去关闭动漫详细页，注意两者的context是不同的
                    Navigator.of(context).pop();
                    _popAnimeDetailPage();
                    // Navigator.of(context).popUntil(
                    //     (route) => ModalRoute.withName("AnimeListPage"));
                    // 直接使用pushAndRemoveUntil跳转到MyHome会导致备份等操作，直接跳转到Tabs会导致主题失效
                    // Navigator.of(context).pushAndRemoveUntil(
                    //   // MaterialPageRoute(builder: (context) => const Tabs()),
                    //   FadeRoute(
                    //     builder: (context) {
                    //       return const MyHome();
                    //     },
                    //   ),
                    //   (route) => false,
                    // );
                    // 直接返回到主页
                    // Navigator.of(context).pushAndRemoveUntil(
                    //   // MaterialPageRoute(builder: (context) => const Tabs()),
                    //   FadeRoute(
                    //     builder: (context) {
                    //       return const Tabs();
                    //     },
                    //   ),
                    //   (route) => false,
                    // ); // 返回false就没有左上角的返回按钮了
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

  List<ListTile> _buildEpisodeRangeListTiles(dialogContext) {
    List<ListTile> listTiles = [];
    for (var startEpisodeNumber = 1;
        startEpisodeNumber <= _anime.animeEpisodeCnt;
        startEpisodeNumber += episodeRangeSize) {
      listTiles.add(ListTile(
        title: Text(_getEpisodeRangeStr((startEpisodeNumber))),
        leading: currentStartEpisodeNumber == startEpisodeNumber
            ? Icon(Icons.radio_button_on,
                color: ThemeUtil.getThemePrimaryColor())
            : const Icon(Icons.radio_button_off),
        onTap: () {
          currentStartEpisodeNumber = startEpisodeNumber;
          SPUtil.setInt("${widget.animeId}-currentStartEpisodeNumber",
              currentStartEpisodeNumber);
          Navigator.of(dialogContext).pop();
          // 获取集数据
          _loadEpisode();
        },
      ));
    }
    return listTiles;
  }

  // 动漫信息下面的操作栏
  _buildButtonsAboutEpisode() {
    if (!_anime.isCollected()) return Container();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // _anime.animeEpisodeCnt > episodeRangeSize ?
          MaterialButton(
            padding: const EdgeInsets.all(0),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("选择范围"),
                    content: SingleChildScrollView(
                      child: Column(
                        children: _buildEpisodeRangeListTiles(context),
                      ),
                    ),
                  );
                },
              );
            },
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_right_rounded,
                  size: 28,
                ),
                const Text(" "),
                Text(_getEpisodeRangeStr(currentStartEpisodeNumber)),
              ],
            ),
          ),
          // : Container(),
          Expanded(child: Container()),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  dialogSelectUint(context, "选择第 n 次观看",
                          initialValue: _anime.reviewNumber,
                          minValue: 1,
                          maxValue: 6)
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
                },
                icon: showReviewNumberIcon(),
              ),
              IconButton(
                  onPressed: () {
                    _dialogSelectSortMethod();
                  },
                  tooltip: "排序方式",
                  icon: const Icon(Icons.sort)),
              IconButton(
                  onPressed: () {
                    if (hideNoteInAnimeDetail) {
                      // 原先隐藏，则设置为false，表示显示
                      SPUtil.setBool("hideNoteInAnimeDetail", false);
                      hideNoteInAnimeDetail = false;
                    } else {
                      SPUtil.setBool("hideNoteInAnimeDetail", true);
                      hideNoteInAnimeDetail = true;
                    }
                    setState(() {});
                  },
                  tooltip: hideNoteInAnimeDetail ? "显示笔记" : "隐藏笔记",
                  icon: hideNoteInAnimeDetail
                      ? const Icon(Icons.unfold_more)
                      : const Icon(Icons.unfold_less)),
              IconButton(
                  onPressed: () {
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
                        debugPrint("未选择，直接返回");
                        return;
                      }
                      // if (value == _episodes.length) {
                      if (value == _anime.animeEpisodeCnt) {
                        debugPrint("设置的集数等于初始值${_anime.animeEpisodeCnt}，直接返回");
                        return;
                      }
                      int episodeCnt = value;
                      SqliteUtil.updateEpisodeCntByAnimeId(
                              _anime.animeId, episodeCnt)
                          .then((value) {
                        // 重新获取数据
                        _anime.animeEpisodeCnt = episodeCnt;
                        _loadEpisode();
                      });
                    });
                  },
                  icon: const Icon(Icons.add)),
            ],
          ),
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
    _episodeNotes.sort((a, b) {
      return a.episode.number.compareTo(b.episode.number);
    });
  }

  void _sortByEpisodeNumberDesc() {
    _episodes.sort((a, b) {
      return b.number.compareTo(a.number);
    });
    _episodeNotes.sort((a, b) {
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
    _episodeNotes.sort((a, b) {
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
      if (_anime.isCollected()) showToast("当前动漫没有来源，请先进行迁移");
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
    Anime oldAnime = _anime.copy();
    // Anime oldAnime = Anime(
    //     animeId: _anime.animeId,
    //     animeName: _anime.animeName,
    //     animeEpisodeCnt: _anime.animeEpisodeCnt,
    //     tagName: _anime.tagName);
    // 需要传入_anime，然后会修改里面的值，newAnime也会引用该对象
    debugPrint("_anime.animeEpisodeCnt = ${_anime.animeEpisodeCnt}");
    Anime newAnime = await ClimbAnimeUtil.climbAnimeInfoByUrl(_anime);
    // 如果更新后动漫集数比原来的集数小，则不更新集数
    // 目的是解决一个bug：东京喰种PINTO手动设置集数为2后，更新动漫，获取的集数为0，集数更新为0后，此时再次手动修改集数，因为传入的初始值为0，即使按了取消，由于会返回初始值0，因此会导致集数变成了0
    // 因此，只要用户设置了集数，即使更新的集数小，也会显示用户设置的集数，只有当更新集数大时，才会更新。
    // 另一种解决方式：点击修改集数按钮时，传入此时_episodes的长度，而不是_anime.animeEpisodeCnt，这样就保证了传入给修改集数对话框的初始值为原来的集数，而不是更新的集数。
    debugPrint("_anime.animeEpisodeCnt = ${_anime.animeEpisodeCnt}");
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

  showReviewNumberIcon() {
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
        return const Icon(Icons.error_outline);
    }
  }

  _buildAppBarTitle() {
    if (!_anime.isCollected()) return Container();
    return !_loadAnimeOk
        ? Container()
        : ListTile(
            title: Row(
              children: [
                Text(
                  _anime.tagName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  width: 10,
                ),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
            onTap: () {
              _dialogSelectTag();
              // 不能复用该对话框，如果选择了取消收藏，则需要退回到主页，但无法实现。
              // dialogSelectTag(setState, context, _anime);
            },
          );
  }

  void _dialogUpdateAnimeName(popMenuContext) {
    var animeNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编辑信息'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  autofocus: true, // 自动弹出输入法
                  // 把TextEditingController对象应用到TextField上，便于获取输入内容
                  controller: animeNameController..text = _anime.animeName,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  maxLength: 50,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              // 修改动漫集数
              onPressed: () {
                if (animeNameController.text.isEmpty) {
                  showToast("名字不能为空");
                  return;
                }
                SqliteUtil.updateAnimeNameByAnimeId(
                    _anime.animeId, animeNameController.text);
                _anime.animeName = animeNameController.text;
                setState(() {});
                Navigator.pop(context);
                Navigator.pop(popMenuContext);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _popAnimeDetailPage() {
    // 置为0，用于在收藏页得知已取消收藏
    _anime.animeId = 0;
    // 第一个是退出下拉菜单，第二个是退出动漫详细页面
    // Navigator.of(context).pop();
    // Navigator.of(context).pop();
    // 也可
    Navigator.of(context)
      ..pop()
      ..pop(_anime);
  }
}
