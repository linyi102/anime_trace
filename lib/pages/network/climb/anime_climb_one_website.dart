import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_confirm_migrate.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_checklist.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/get_anime_grid_delegate.dart';
import 'package:flutter_test_future/components/search_app_bar.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class AnimeClimbOneWebsite extends StatefulWidget {
  final int animeId;
  final String keyword;
  final ClimbWebsite climbWebStie;

  const AnimeClimbOneWebsite(
      {this.animeId = 0,
      this.keyword = "",
      required this.climbWebStie,
      Key? key})
      : super(key: key);

  @override
  _AnimeClimbOneWebsiteState createState() => _AnimeClimbOneWebsiteState();
}

class _AnimeClimbOneWebsiteState extends State<AnimeClimbOneWebsite> {
  var animeNameController = TextEditingController();
  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  late bool ismigrate;
  late ClimbWebsite curWebsite;

  List<Anime> websiteClimbAnimes = []; // 爬取的动漫列表
  List<Anime> mixedAnimes = []; // 混合的动漫列表(数据库若已有该动漫，则覆盖爬取的动漫)
  bool searchOk = false;
  bool searching = false;
  String addDefaultTag = tags[0];
  String lastInputName = "";

  @override
  void initState() {
    super.initState();
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
      Log.info("搜索数据库前id=${websiteClimbAnimes[i].animeId}");
      mixedAnimes[i] =
          await SqliteUtil.getAnimeByAnimeUrl(websiteClimbAnimes[i]);
      Log.info("搜索数据库后id=${mixedAnimes[i].animeId}");
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
      body: Column(
        children: [
          ListTile(
            title: Text(curWebsite.name),
            leading: WebSiteLogo(url: curWebsite.iconUrl, size: 25),
            trailing: const Icon(Icons.keyboard_arrow_down),
            onTap: () => _showDialogSelectWebsite(context),
          ),
          // ListTile(
          //   title: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       WebSiteLogo(url: curWebsite.iconUrl, size: 25),
          //       const SizedBox(width: 10),
          //       Text(curWebsite.name)
          //     ],
          //   ),
          //   onTap: () => _showDialogSelectWebsite(context),
          // ),
          searchOk
              ? Expanded(child: _displayClimbAnime())
              : searching
                  ? const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                  : Container(),
        ],
      ),
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
      gridDelegate: getAnimeGridDelegate(context),
      itemCount: mixedAnimes.length,
      itemBuilder: (BuildContext context, int index) {
        Anime anime = mixedAnimes[index];
        return MaterialButton(
            padding: const EdgeInsets.all(0),
            child: AnimeGridCover(anime),
            onPressed: () {
              // 迁移动漫
              if (ismigrate) {
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
