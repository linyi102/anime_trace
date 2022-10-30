import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_confirm_migrate.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_tag.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/home_tabs/anime_list_page.dart';
import 'package:flutter_test_future/pages/modules/website_icon.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

import '../../../components/common/common_function.dart';

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
  var endEpisodeController = TextEditingController();
  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  late bool ismigrate;

  List<Anime> websiteClimbAnimes = []; // 爬取的动漫列表
  List<Anime> mixedAnimes = []; // 混合的动漫列表(数据库若已有该动漫，则覆盖爬取的动漫)
  bool searchOk = false;
  bool searching = false;
  String addDefaultTag = tags[0];
  String lastInputName = "";

  @override
  void initState() {
    super.initState();
    ismigrate = widget.animeId > 0 ? true : false;

    // 如果传入了关键字，说明是更新封面，此时需要直接爬取
    if (widget.keyword.isNotEmpty) {
      lastInputName = widget.keyword; // 搜索关键字第一次为传入的传健字，还可以进行修改
      animeNameController.text = lastInputName;
      _climbAnime(keyword: widget.keyword);
    }
  }

  _climbAnime({String keyword = ""}) {
    debugPrint("开始爬取动漫封面");
    searchOk = false;
    searching = true;
    setState(() {}); // 显示加载圈，注意会暂时导致光标移到行首

    Future(() async {
      return ClimbAnimeUtil.climbAnimesByKeywordAndWebSite(
          keyword, widget.climbWebStie);
    }).then((value) async {
      websiteClimbAnimes = value;
      debugPrint("爬取结束");
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
      debugPrint("搜索数据库前id=${websiteClimbAnimes[i].animeId}");
      mixedAnimes[i] =
          await SqliteUtil.getAnimeByAnimeUrl(websiteClimbAnimes[i]);
      debugPrint("搜索数据库后id=${mixedAnimes[i].animeId}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: widget.keyword.isEmpty ? true : false,
          // 自动弹出键盘，如果是修改封面，则为false
          controller: animeNameController..text,
          decoration: InputDecoration(
              hintText: "搜索动漫",
              border: InputBorder.none,
              suffixIcon: IconButton(
                  onPressed: () {
                    animeNameController.clear();
                  },
                  icon: const Icon(Icons.close))),
          onEditingComplete: () async {
            String text = animeNameController.text;
            // 如果输入的名字为空，则不再爬取
            if (text.isEmpty) {
              return;
            }
            lastInputName = text; // 更新上一次输入的名字
            searchOk = false;
            searching = true;
            _climbAnime(keyword: text);
          },
          onChanged: (inputStr) {
            lastInputName = inputStr;
          },
        ),
      ),
      body: Column(
        children: [
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: buildWebSiteIcon(url: widget.climbWebStie.iconUrl, size: 25),
                ),
                const SizedBox(width: 10),
                Text(widget.climbWebStie.name)
              ],
            ),
          ),
          searchOk
              ? Expanded(child: _displayClimbAnime())
              : searching
                  ? const Center(
                      child: RefreshProgressIndicator(),
                    )
                  : Container(),
        ],
      ),
    );
  }

  _displayClimbAnime() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
      gridDelegate: getAnimeGridDelegate(),
      itemCount: mixedAnimes.length,
      itemBuilder: (BuildContext context, int index) {
        Anime anime = mixedAnimes[index];
        return MaterialButton(
          onPressed: () {
            // 迁移动漫
            if (ismigrate) {
              showDialogOfConfirmMigrate(context, widget.animeId, anime);
            } else if (anime.isCollected()) {
              debugPrint("进入动漫详细页面${anime.animeId}");
              // 不为0，说明已添加，点击进入动漫详细页面
              Navigator.of(context).push(
                // MaterialPageRoute(
                //   builder: (context) =>
                //       AnimeDetailPlus(anime.animeId),
                // ),
                FadeRoute(
                  builder: (context) {
                    return AnimeDetailPlus(anime.animeId);
                  },
                ),
              ).then((value) {
                // 可能迁移到了其他搜索源，因此需要从数据库中全部重新查找
                _generateMixedAnimes().then((value) {
                  setState(() {});
                });
              });
            } else {
              debugPrint("添加动漫");
              dialogSelectTag(setState, context, anime);
            }
          },
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5), // 设置按钮填充
          child: AnimeGridCover(anime),
        );
      },
    );
  }
}
