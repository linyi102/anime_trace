import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:flutter/material.dart';

import 'package:animetrace/components/anime_grid_cover.dart';
import 'package:animetrace/components/dialog/dialog_confirm_migrate.dart';
import 'package:animetrace/components/dialog/dialog_select_checklist.dart';
import 'package:animetrace/components/empty_data_hint.dart';
import 'package:animetrace/components/get_anime_grid_delegate.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/components/search_app_bar.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/pages/anime_collection/checklist_controller.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/components/website_logo.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/global_data.dart';
import 'package:animetrace/utils/sqlite_util.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';

class AnimeClimbOneWebsite extends StatefulWidget {
  final int animeId;
  final String keyword;
  final ClimbWebsite climbWebStie;
  final bool enableSourceSelector;
  final void Function(Anime anime)? onTap;

  const AnimeClimbOneWebsite({
    this.animeId = 0,
    this.keyword = "",
    required this.climbWebStie,
    this.enableSourceSelector = true,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  _AnimeClimbOneWebsiteState createState() => _AnimeClimbOneWebsiteState();
}

class _AnimeClimbOneWebsiteState extends State<AnimeClimbOneWebsite> {
  var animeNameController = TextEditingController();
  List<String> get tags => ChecklistController.to.tags;
  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  late bool ismigrate;
  late ClimbWebsite curWebsite;

  List<Anime> websiteClimbAnimes = []; // 爬取的动漫列表
  List<Anime> mixedAnimes = []; // 混合的动漫列表(数据库若已有该动漫，则覆盖爬取的动漫)
  bool searchOk = false;
  bool searching = false;
  late String addDefaultTag;
  String lastInputName = "";

  @override
  void initState() {
    super.initState();
    addDefaultTag = tags[0];
    curWebsite = widget.climbWebStie;
    ismigrate = widget.animeId > 0 ? true : false;

    // 如果传入了关键字，说明是更新封面，此时需要直接爬取
    if (widget.keyword.isNotEmpty) {
      lastInputName = widget.keyword; // 搜索关键字第一次为传入的传健字，还可以进行修改
      animeNameController.text = lastInputName;
      _climbAnime(keyword: widget.keyword);
    }
  }

  _climbAnime({String keyword = ""}) {
    Log.info("开始爬取动漫封面");
    searchOk = false;
    searching = true;
    setState(() {}); // 显示加载圈，注意会暂时导致光标移到行首

    Future(() async {
      return ClimbAnimeUtil.climbAnimesByKeywordAndWebSite(keyword, curWebsite);
    }).then((value) async {
      websiteClimbAnimes = value;
      Log.info("爬取结束");
      FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点

      // 对爬取的动漫找数据库中是否已经添加了，若已添加则覆盖
      _generateMixedAnimes().then((value) {
        searchOk = true;
        searching = false;
        setState(() {});
      });
    });
  }

  Future<void> _generateMixedAnimes() async {
    await Future.delayed(Duration.zero);
    // 不能直接赋值，如果直接赋值，则mixedAnimes和websiteClimbAnimes其实都指向同一个数组，修改mixedAnimes也会导致websiteClimbAnimes指向的数组变化
    // 第一个取消收藏后仍然有进度，而其他的却不会，为什么？下面那个copy也是
    // 解决方法：等待0秒
    mixedAnimes = websiteClimbAnimes;
    // mixedAnimes.clear();
    // for (var i = 0; i < websiteClimbAnimes.length; i++) {
    //   mixedAnimes.add(websiteClimbAnimes[i].copy());
    // }

    // 若数据库已存在该动漫，则覆盖掉
    for (var i = 0; i < websiteClimbAnimes.length; i++) {
      mixedAnimes[i] =
          await SqliteUtil.getAnimeByAnimeUrl(websiteClimbAnimes[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        hintText: "搜索动漫",
        useModernStyle: false,
        // 自动弹出键盘，如果是修改封面，则为false
        autofocus: widget.keyword.isEmpty ? true : false,
        inputController: animeNameController..text,
        onEditingComplete: () => _onEditingComplete(),
        onChanged: (inputStr) {
          lastInputName = inputStr;
        },
        onTapClear: () {
          animeNameController.clear();
        },
      ),
      body: CommonScaffoldBody(
          child: Column(
        children: [
          if (widget.enableSourceSelector)
            ListTile(
              title: Text(curWebsite.name),
              leading: WebSiteLogo(url: curWebsite.iconUrl, size: 25),
              trailing: const Icon(Icons.keyboard_arrow_down),
              onTap: () => _showDialogSelectWebsite(context),
            ),
          searchOk
              ? Expanded(child: _displayClimbAnime())
              : searching
                  ? const Expanded(child: LoadingWidget(center: true))
                  : Container(),
        ],
      )),
    );
  }

  _showDialogSelectWebsite(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: climbWebsites.map((e) {
          if (e.discard) return Container();

          return ListTile(
            title: Text(e.name),
            leading: WebSiteLogo(url: e.iconUrl, size: 25),
            trailing:
                e.name == curWebsite.name ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                curWebsite = e;
              });
              _onEditingComplete();
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  _displayClimbAnime() {
    if (mixedAnimes.isEmpty) return emptyDataHint();

    return RefreshIndicator(
      onRefresh: () async {
        _onEditingComplete();
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
        gridDelegate: getAnimeGridDelegate(context),
        itemCount: mixedAnimes.length,
        itemBuilder: (BuildContext context, int index) {
          Anime anime = mixedAnimes[index];
          return InkWell(
              child: AnimeGridCover(anime),
              onLongPress: () {
                LaunchUrlUtil.launch(context: context, uriStr: anime.animeUrl);
              },
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!(anime);
                }
                // 迁移动漫
                else if (ismigrate) {
                  showDialogOfConfirmMigrate(context, widget.animeId, anime);
                } else if (anime.isCollected()) {
                  Log.info("进入动漫详细页面${anime.animeId}");
                  // 不为0，说明已添加，点击进入动漫详细页面
                  Navigator.of(context).push(
                    // MaterialPageRoute(
                    //   builder: (context) =>
                    //       AnimeDetailPlus(anime.animeId),
                    // ),
                    MaterialPageRoute(
                      builder: (context) {
                        return AnimeDetailPage(anime);
                      },
                    ),
                  ).then((value) {
                    // 可能迁移到了其他搜索源，因此需要从数据库中全部重新查找
                    _generateMixedAnimes().then((value) {
                      setState(() {});
                    });
                  });
                } else {
                  dialogSelectChecklist(setState, context, anime);
                }
              });
        },
      ),
    );
  }

  _onEditingComplete() async {
    String text = animeNameController.text;
    // 如果输入的名字为空，则不再爬取
    if (text.isEmpty) return;

    lastInputName = text; // 更新上一次输入的名字
    searchOk = false;
    searching = true;
    _climbAnime(keyword: text);
  }
}
