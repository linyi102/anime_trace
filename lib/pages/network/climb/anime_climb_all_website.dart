import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/anime_horizontal_cover.dart';
import 'package:flutter_test_future/components/search_app_bar.dart';
import 'package:flutter_test_future/controllers/anime_display_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_one_website.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';

import '../../../dao/anime_dao.dart';

class AnimeClimbAllWebsite extends StatefulWidget {
  final int animeId; // 需要迁移的动漫id
  final String keyword; // 搜索关键字

  const AnimeClimbAllWebsite({this.animeId = 0, this.keyword = "", Key? key})
      : super(key: key);

  @override
  _AnimeClimbAllWebsiteState createState() => _AnimeClimbAllWebsiteState();
}

class _AnimeClimbAllWebsiteState extends State<AnimeClimbAllWebsite> {
  var inputKeywordController = TextEditingController();
  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  bool ismigrate = false;

  List<String> get tags => ChecklistController.to.tags;
  late String addDefaultTag;
  String lastInputKeyword = "";
  Map<String, List<Anime>> websiteClimbAnimes = {}; // 爬取的动漫
  Map<String, List<Anime>> mixedAnimes = {}; // 先赋值为爬取的动漫，后如果已收藏，则赋值为数据库动漫
  Map<String, bool> websiteClimbSearchOk = {}; // true时显示搜索结果
  Map<String, bool> websiteClimbSearching = {}; // true时显示进度圈
  List<Anime> localAnimes = []; // 本地动漫
  List<Anime> customAnimes = []; // 自定义动漫

  @override
  void initState() {
    super.initState();
    addDefaultTag = tags[0];
    ismigrate = widget.animeId > 0 ? true : false;
    lastInputKeyword = widget.keyword;
    inputKeywordController.text = lastInputKeyword;

    for (var climbWebsite in climbWebsites) {
      websiteClimbSearchOk[climbWebsite.name] = false;
      websiteClimbSearching[climbWebsite.name] = false;
    }

    // 去除delay报错
    Future.delayed(Duration.zero).then((value) {
      // 迁移或者网络搜索更多
      if (ismigrate || widget.keyword.isNotEmpty) {
        _climbAnime(keyword: widget.keyword);
      }
    });
  }

  _climbAnime({String keyword = ""}) async {
    if (keyword.isEmpty) return;
    FocusScope.of(context).requestFocus(blankFocusNode);
    // 先全部清除数据
    for (var climbWebsite in climbWebsites) {
      websiteClimbSearchOk[climbWebsite.name] = false;
      websiteClimbSearching[climbWebsite.name] = false;
    }

    // _generateCustomAnimes();

    Log.info("开始爬取动漫封面");
    // 遍历所有搜索源
    for (var climbWebsite in climbWebsites) {
      Log.info(climbWebsite.toString());
      // 如果关闭了，则直接跳过该搜索源
      if (!climbWebsite.enable) continue; // 不是break啊...

      Future(() async {
        // 正在搜索，用于显示加载圈
        websiteClimbSearching[climbWebsite.name] = true;
        setState(() {});

        return ClimbAnimeUtil.climbAnimesByKeywordAndWebSite(
            keyword, climbWebsite);
      }).then((value) async {
        websiteClimbAnimes[climbWebsite.name] = value;
        websiteClimbSearchOk[climbWebsite.name] = true;
        // 根据动漫网址查询是否已经添加了该动漫
        // 需要等更新为数据库动漫完毕后才显示，否则提前显示时，可以迁移到已添加的动漫
        _generateMixedAnimes(climbWebsite).then((value) {
          if (mounted) {
            setState(() {});
          }
        });
      });
    }
  }

  _generateCustomAnimes() async {
    // 迁移时不准备自定义动漫数据
    if (!ismigrate) {
      // 先重置数据
      customAnimes.clear();
      setState(() {});
      // 添加以关键字为名字的自定义动漫
      // 从数据库中找同名的没有动漫地址的动漫，并赋值给该动漫(可能之前添加过以关键字为名字的自定义动漫)
      Anime customAnime =
          await SqliteUtil.getCustomAnimeByAnimeName(lastInputKeyword);
      customAnimes.add(customAnime);
      // 并在数据库中查找包含该名字的且没有动漫地址的动漫
      customAnimes.addAll(await SqliteUtil.getCustomAnimesIfContainAnimeName(
          customAnime.animeName));

      if (mounted) setState(() {});
    }
  }

  Future<bool> _generateMixedAnimes(ClimbWebsite climbWebsite) async {
    mixedAnimes[climbWebsite.name] =
        websiteClimbAnimes[climbWebsite.name] as List<Anime>;

    if (websiteClimbAnimes.containsKey(climbWebsite.name)) {
      for (var i = 0; i < websiteClimbAnimes[climbWebsite.name]!.length; i++) {
        mixedAnimes[climbWebsite.name]![i] =
            await SqliteUtil.getAnimeByAnimeUrl(
                mixedAnimes[climbWebsite.name]![i]);
      }
    }
    return true;
  }

  // 用于从动漫详细页和详细搜索页返回时调用，从数据库中重新获取所有网站的已收藏的动漫
  Future<bool> _generateMixedAnimesAllWebsite() async {
    await Future.delayed(Duration.zero); // 必须等待，否则第一个动漫取消收藏后返回时数据库中仍然是存在的

    // 进入聚合搜索页后，直接进入详细搜索页，返回后，关键字一直是空的，所以不生产，直接退出
    if (lastInputKeyword.isEmpty) return true;
    _generateCustomAnimes(); // 也可能会迁移自定义动漫

    Log.info("mixing...");
    mixedAnimes = websiteClimbAnimes;

    for (var climbWebsite in climbWebsites) {
      // 如果没有开启，直接跳过，否则映射的是null
      if (!climbWebsite.enable) continue;
      // 直接进入了单个搜索页，返回后此时没有key，所以需要跳过
      if (!websiteClimbAnimes.containsKey(climbWebsite.name)) {
        continue;
      }

      for (var i = 0; i < websiteClimbAnimes[climbWebsite.name]!.length; i++) {
        mixedAnimes[climbWebsite.name]![i] =
            await SqliteUtil.getAnimeByAnimeUrl(
                mixedAnimes[climbWebsite.name]![i]);
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildSearchAppBar(),
      body: CommonScaffoldBody(
          child: RefreshIndicator(
        onRefresh: () async {
          _climbAnime(keyword: lastInputKeyword);
        },
        child: ListView(
          children: [
            _buildLocalAnimes(),
            // 自定义动漫
            _buildCustomItem(),
            // 所有搜索源
            _buildAllSource(),
            // 最下面(最后一个搜索源)填充空白
            const SizedBox(height: 50)
          ],
        ),
      )),
    );
  }

  _buildLocalAnimes() {
    if (ismigrate) return const SizedBox.shrink();
    return Column(
      children: [
        const ListTile(title: Text("已收藏")),
        if (localAnimes.isNotEmpty)
          AnimeHorizontalCover(
            animes: localAnimes,
            callback: () async {
              return true;
            },
          ),
      ],
    );
  }

  ListView _buildAllSource() {
    bool isFirstEnableSource = false;
    return ListView.builder(
      shrinkWrap: true, //解决无限高度问题
      physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
      itemCount: climbWebsites
          .length, // 应该始终显示这么多个，即使关闭了(要返回Container())，也要统计在内，因为要判断所有搜索源
      itemBuilder: (context, index) {
        ClimbWebsite webstie = climbWebsites[index];
        // 如果关闭了，则不显示
        if (!climbWebsites[index].enable) return Container();
        // 遍历时，第一次(isFirstEnableSource为false)到达这里，则说明是第一个启动了的搜索源，需要在上面添加自定义
        if (!isFirstEnableSource) {
          isFirstEnableSource = true;
        }

        // 搜索源行+搜索结果
        return Column(
          children: [
            // const CommonDivider(),
            // 搜索源行
            ListTile(
              title: Text(webstie.name),
              leading: WebSiteLogo(url: webstie.iconUrl, size: 25),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () => _enterAnimeDetailPage(index),
            ),
            // 搜索结果
            websiteClimbSearchOk[webstie.name] ?? false
                // 查询好后显示结果
                ? AnimeHorizontalCover(
                    animes: mixedAnimes[webstie.name] ?? [],
                    animeId: widget.animeId,
                    callback: _generateMixedAnimesAllWebsite,
                  )
                : websiteClimbSearching[webstie.name] ?? false
                    ?
                    // 搜索时显示加载圈
                    _buildLoadingWidget()
                    // 还没搜索时，什么都不显示
                    : Container(),
          ],
        );
      },
    );
  }

  void _enterAnimeDetailPage(int websiteIndex) {
    // 进入详细搜索页
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return AnimeClimbOneWebsite(
        animeId: widget.animeId, // 进入详细搜索页迁移动漫，也需要传入动漫id
        keyword: lastInputKeyword,
        climbWebStie: climbWebsites[websiteIndex],
      );
    })).then((value) {
      // 如果是进入详细页迁移后，则直接返回到动漫详细页
      if (ismigrate) {
        Navigator.of(context).pop();
      } else {
        // 可能进入详细搜索页后修改了数据库动漫，因此也需要重新搜索数据库(只搜索该搜索源下爬取的动漫网址)
        // 小问题：进入动漫详细页后，迁移到了其他搜索源的动漫，animeUrl发生变化，此时该函数会通过animeUrl从数据库找到相应的动漫，并赋值，因此会出现原搜索源下面出现了一个其它搜索源的动漫
        // 2022.05.01无法修复，因为迁移到其他搜索源后，animeUrl发生了变化，不再是原搜索源
        // _generateMixedAnimes(climbWebsites[index])
        //     .then((value) => setState(() {}));

        // 2022.05.03修复
        _generateMixedAnimesAllWebsite().then((value) => setState(() {}));
      }
    });
  }

  SearchAppBar _buildSearchAppBar() {
    return SearchAppBar(
      hintText: ismigrate ? "迁移动漫" : "搜索动漫",
      useModernStyle: false,
      inputController: inputKeywordController..text,
      onTapClear: () => inputKeywordController.clear(),
      onEditingComplete: () {
        String text = inputKeywordController.text;
        // 如果输入的名字为空，则不再爬取
        if (text.isEmpty) return;

        lastInputKeyword = text; // 更新上一次输入的名字
        _climbAnime(keyword: text);
      },
      onChanged: (inputStr) async {
        // 如果使用输入法，回车后该方法会执行两次，导致已收藏和自定义出现重复，因此判断如果和上一个关键一样，则直接返回
        if (lastInputKeyword == inputStr) {
          return;
        }

        // 避免输入好后切换搜索源后，清空了输入的内容
        lastInputKeyword = inputStr;
        // 输入时就查询本地和自定义
        if (inputStr.isNotEmpty) {
          localAnimes = await AnimeDao.getAnimesBySearch(inputStr);
          _generateCustomAnimes();
          if (mounted) setState(() {});
        } else {
          // 清空
          customAnimes.clear();
          localAnimes.clear();
          if (mounted) setState(() {});
        }
      },
    );
  }

  _buildCustomItem() {
    // 迁移时不显示自定义
    if (ismigrate) return const SizedBox.shrink();
    return Column(
      children: [
        // 自定义添加的动漫
        ListTile(
            title: Row(
          children: [
            const Text("自定义"),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('帮助'),
                    content: Text('如果在搜索源中没有找到想要的动漫，可以在此处添加自定义动漫'),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline, size: 16),
            )
          ],
        )),
        if (customAnimes.isNotEmpty)
          AnimeHorizontalCover(
            animes: customAnimes,
            animeId: widget.animeId,
            callback: _generateMixedAnimesAllWebsite,
          )
      ],
    );
  }

  SizedBox _buildLoadingWidget() {
    final AnimeDisplayController adc = AnimeDisplayController.to;
    double height = 137.0;
    bool nameBelowCover = false; // 名字在封面下面，就增加高度
    if (adc.showGridAnimeName.value && !adc.showNameInCover.value) {
      nameBelowCover = true;
    }
    if (nameBelowCover) {
      if (adc.nameMaxLines.value == 2) {
        height += 60;
      } else {
        height += 30;
      }
    }

    return SizedBox(
      // 每个搜索结果的显示高度(封面+名字高度)
      height: height,
      child: const Center(
        // 固定宽高的指示器
        child: SizedBox(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
