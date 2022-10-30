import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/components/anime_horizontal_cover.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/modules/website_icon.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_one_website.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class AnimeClimbAllWebsite extends StatefulWidget {
  final int animeId;
  final String keyword;

  const AnimeClimbAllWebsite({this.animeId = 0, this.keyword = "", Key? key})
      : super(key: key);

  @override
  _AnimeClimbAllWebsiteState createState() => _AnimeClimbAllWebsiteState();
}

class _AnimeClimbAllWebsiteState extends State<AnimeClimbAllWebsite> {
  var inputKeywordController = TextEditingController();
  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  bool ismigrate = false;

  String addDefaultTag = tags[0];
  String lastInputKeyword = "";
  Map<String, List<Anime>> websiteClimbAnimes = {}; // 爬取的动漫
  Map<String, List<Anime>> mixedAnimes = {}; // 先赋值为爬取的动漫，后如果已收藏，则赋值为数据库动漫
  Map<String, bool> websiteClimbSearchOk = {}; // true时显示搜索结果
  Map<String, bool> websiteClimbSearching = {}; // true时显示进度圈
  List<Anime> customAnimes = []; // 自定义动漫
  bool customSearchOK = false;
  bool customSearching = false;

  @override
  void initState() {
    super.initState();
    ismigrate = widget.animeId > 0 ? true : false;
    lastInputKeyword = widget.keyword;
    inputKeywordController.text = lastInputKeyword;

    for (var climbWebsite in climbWebsites) {
      websiteClimbSearchOk[climbWebsite.name] = false;
      websiteClimbSearching[climbWebsite.name] = false;
    }

    // TODO：去除delay报错
    Future.delayed(Duration.zero).then((value) {
      // 迁移或者网络搜索更多
      if (ismigrate || widget.keyword.isNotEmpty) {
        _climbAnime(keyword: widget.keyword);
      }
    });
  }

  _climbAnime({String keyword = ""}) async {
    FocusScope.of(context).requestFocus(blankFocusNode);
    // 先全部清除数据
    for (var climbWebsite in climbWebsites) {
      websiteClimbSearchOk[climbWebsite.name] = false;
      websiteClimbSearching[climbWebsite.name] = false;
    }

    _generateCustomAnimes();

    debugPrint("开始爬取动漫封面");
    // 遍历所有搜素源
    for (var climbWebsite in climbWebsites) {
      debugPrint(climbWebsite.toString());
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
        _generateMixedAnimes(climbWebsite).then((value) => setState(() {}));
      });
    }
  }

  _generateCustomAnimes() async {
    // 迁移时不准备自定义动漫数据
    if (!ismigrate) {
      // 先重置数据
      customAnimes.clear();
      customSearchOK = false;
      customSearching = true;
      setState(() {});
      // 添加以关键字为名字的自定义动漫
      // 从数据库中找同名的没有动漫地址的动漫，并赋值给该动漫(可能之前添加过以关键字为名字的自定义动漫)
      Anime customAnime =
          await SqliteUtil.getCustomAnimeByAnimeName(lastInputKeyword);
      customAnimes.add(customAnime);
      // 并在数据库中查找包含该名字的且没有动漫地址的动漫
      customAnimes.addAll(await SqliteUtil.getCustomAnimesIfContainAnimeName(
          customAnime.animeName));

      customSearchOK = true;
      customSearching = false;
      setState(() {});
    }
  }

  Future<bool> _generateMixedAnimes(ClimbWebsite climbWebsite) async {
    mixedAnimes[climbWebsite.name] =
        websiteClimbAnimes[climbWebsite.name] as List<Anime>;

    for (var i = 0; i < websiteClimbAnimes[climbWebsite.name]!.length; i++) {
      mixedAnimes[climbWebsite.name]![i] = await SqliteUtil.getAnimeByAnimeUrl(
          mixedAnimes[climbWebsite.name]![i]);
    }
    return true;
  }

  // 用于从动漫详细页和详细搜索页返回时调用，从数据库中重新获取所有网站的已收藏的动漫
  Future<bool> _generateMixedAnimesAllWebsite() async {
    await Future.delayed(Duration.zero); // 必须等待，否则第一个动漫取消收藏后返回时数据库中仍然是存在的

    // 进入聚合搜索页后，直接进入详细搜索页，返回后，关键字一直是空的，所以不生产，直接退出
    if (lastInputKeyword.isEmpty) return true;
    _generateCustomAnimes(); // 也可能会迁移自定义动漫

    debugPrint("mixing...");
    mixedAnimes = websiteClimbAnimes;

    for (var climbWebsite in climbWebsites) {
      if (!climbWebsite.enable) continue; // 如果没有开启，直接跳过，否则映射的是null

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
    bool isFirstEnableSource = false;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: widget.keyword.isEmpty ? true : false,
          // 自动弹出键盘，如果是修改封面，则为false
          controller: inputKeywordController..text,
          decoration: InputDecoration(
              hintText: ismigrate ? "迁移动漫" : "搜索动漫",
              border: InputBorder.none,
              suffixIcon: IconButton(
                  onPressed: () {
                    inputKeywordController.clear();
                  },
                  icon: const Icon(Icons.close))),
          onEditingComplete: () async {
            String text = inputKeywordController.text;
            // 如果输入的名字为空，则不再爬取
            if (text.isEmpty) {
              return;
            }
            lastInputKeyword = text; // 更新上一次输入的名字
            _climbAnime(keyword: text);
          },
          onChanged: (inputStr) {
            lastInputKeyword = inputStr;
            // 避免输入好后切换搜索源后，清空了输入的内容
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _climbAnime(keyword: lastInputKeyword);
        },
        child: ListView(
          children: [
            // 自定义添加的动漫
            ismigrate
                ? Container() // 迁移时不显示自定义
                : const ListTile(
                    title: Text("自定义"),
                  ),
            ismigrate
                ? Container()
                : customSearchOK // 搜索完毕后显示动漫
                    ? AnimeHorizontalCover(
                        animes: customAnimes,
                        animeId: widget.animeId,
                        callback: _generateMixedAnimesAllWebsite,
                      )
                    : customSearching // 正在搜索时显示加载圈
                        ? const SizedBox(
                            height: 137 + 60,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                        : Container(),
            // 搜索源
            ListView.builder(
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

                return ListView(
                  shrinkWrap: true, //解决无限高度问题
                  physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
                  children: [
                    // 搜索源行
                    ListTile(
                      title: Text(webstie.name),
                      leading: buildWebSiteIcon(url: webstie.iconUrl, size: 25),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // 进入详细搜索页
                        Navigator.of(context)
                            .push(FadeRoute(builder: (context) {
                          return AnimeClimbOneWebsite(
                            animeId: widget.animeId, // 进入详细搜索页迁移动漫，也需要传入动漫id
                            keyword: lastInputKeyword,
                            climbWebStie: climbWebsites[index],
                          );
                        })).then((value) {
                          // 如果是进入详细页迁移后，则直接返回到动漫详细页
                          if (ismigrate) {
                            Navigator.of(context).pop();
                          } else {
                            // 可能进入详细搜索页后修改了数据库动漫，因此也需要重新搜索数据库(只搜索该搜索源下爬取的动漫网址)
                            // 小问题：进入动漫详细页后，迁移到了其他搜索源的动漫，animeUrl发生变化，此时该函数会通过animeUrl从数据库找到相应的动漫，并赋值，因此会出现原搜索源下面出现了一个其它搜索源的动漫
                            // 2022.05.01无法修复，因为迁移到其他搜索源后，animeUrl发生了变化，不再是原搜素源
                            // _generateMixedAnimes(climbWebsites[index])
                            //     .then((value) => setState(() {}));

                            // 2022.05.03修复
                            _generateMixedAnimesAllWebsite()
                                .then((value) => setState(() {}));
                          }
                        });
                      },
                    ),
                    // 搜索结果
                    websiteClimbSearchOk[webstie.name] ?? false
                        ? AnimeHorizontalCover(
                            animes: mixedAnimes[webstie.name] ?? [],
                            animeId: widget.animeId,
                            callback: _generateMixedAnimesAllWebsite,
                          ) // 查询好后显示结果
                        : websiteClimbSearching[webstie.name] ?? false
                            ? const SizedBox(
                                // 每个搜索结果的显示高度(封面+名字高度)
                                height: 137 + 60,
                                child: Center(
                                  // 固定宽高的指示器
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ) // 搜索时显示加载圈
                            : Container(), // 没有搜索则什么都不显示
                  ],
                );
              },
            ),
            // 最下面(最后一个搜索源)填充空白
            const SizedBox(height: 50)
          ],
        ),
      ),
    );
  }
}
