import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/select_tag_dialog.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';

class AnimeClimb extends StatefulWidget {
  final int animeId;
  final String keyword;
  final bool ismigrate;
  const AnimeClimb(
      {this.animeId = 0, this.keyword = "", this.ismigrate = false, Key? key})
      : super(key: key);

  @override
  _AnimeClimbState createState() => _AnimeClimbState();
}

class _AnimeClimbState extends State<AnimeClimb> {
  var animeNameController = TextEditingController();
  var endEpisodeController = TextEditingController();
  FocusNode blankFocusNode = FocusNode(); // 空白焦点

  List<Anime> searchedAnimes = [];
  List<Anime> addedAnimes = [];
  bool searchOk = false;
  bool searching = false;
  String addDefaultTag = tags[0];
  String lastInputName = "";

  @override
  void initState() {
    super.initState();
    // 如果传入了关键字，说明是更新封面，此时需要直接爬取
    if (widget.keyword.isNotEmpty) {
      lastInputName = widget.keyword; // 搜索关键字第一次为传入的传健字，还可以进行修改
      _climbAnime(keyword: widget.keyword);
    }
  }

  _climbAnime({String keyword = ""}) {
    debugPrint("开始爬取动漫封面");
    searching = true;
    setState(() {}); // 显示加载圈，注意会暂时导致光标移到行首
    Future(() async {
      return ClimbAnimeUtil.climbAnimesByKeyword(keyword); // 一定要return！！！
    }).then((value) async {
      searchedAnimes = value;
      debugPrint("爬取结束");
      FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
      // 若某个搜索的动漫存在，则更新它
      // 对爬取的动漫找数据库中是否已经添加了，若已添加则覆盖
      for (var i = 0; i < searchedAnimes.length; i++) {
        searchedAnimes[i] =
            await SqliteUtil.getAnimeByAnimeUrl(searchedAnimes[i]);
      }
      // 在开头添加一个没有封面的动漫，避免搜索不到相关动漫导致添加不了
      // 迁移时不添加
      if (widget.keyword.isEmpty) {
        searchedAnimes.insert(
            0,
            Anime(
              animeName: keyword,
              animeEpisodeCnt: 0,
              animeCoverUrl: "",
            ));
      }

      searchOk = true;
      searching = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus:
              widget.keyword.isEmpty ? true : false, // 自动弹出键盘，如果是修改封面，则为false
          controller: animeNameController..text = lastInputName,
          decoration: InputDecoration(
              hintText: "添加动漫",
              border: InputBorder.none,
              suffixIcon: IconButton(
                  onPressed: () {
                    animeNameController.clear();
                  },
                  icon: const Icon(Icons.close, color: Colors.black))),
          onEditingComplete: () async {
            String text = animeNameController.text;
            // 如果输入的名字为空，则不再爬取
            if (text.isEmpty) {
              return;
            }
            lastInputName = text; // 更新上一次输入的名字
            _climbAnime(keyword: text);
          },
          onChanged: (inputStr) {
            lastInputName = inputStr;
            // 避免输入好后切换搜索源后，清空了输入的内容
          },
        ),
      ),
      body: Column(
        children: [
          _displayWebsiteOption(),
          searchOk
              ? Expanded(child: _displayClimbAnime())
              : searching
                  ? const Center(
                      child: RefreshProgressIndicator(),
                    )
                  : Container()
        ],
      ),
    );
  }

  _displayClimbAnime() {
    return AnimatedSwitcher(
      key: UniqueKey(), // 不一样的搜索结果也需要过渡
      duration: const Duration(milliseconds: 5000),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              SPUtil.getInt("gridColumnCnt", defaultValue: 3), // 横轴数量
          crossAxisSpacing: 5, // 横轴距离
          mainAxisSpacing: 3, // 竖轴距离
          childAspectRatio: 31 / 56, // 每个网格的比例
        ),
        itemCount: searchedAnimes.length,
        itemBuilder: (BuildContext context, int index) {
          Anime anime = searchedAnimes[index];
          return MaterialButton(
            onPressed: () async {
              // 迁移动漫
              if (widget.ismigrate) {
                debugPrint("迁移动漫${anime.animeId}");
                // SqliteUtil.updateAnimeCoverbyAnimeId(
                //     widget.animeId, anime.animeCoverUrl);
                SqliteUtil.updateAnime(
                        await SqliteUtil.getAnimeByAnimeId(widget.animeId),
                        anime)
                    .then((value) {
                  // 更新完毕(then)后，退回到详细页，然后重新加载数据才会看到更新
                  Navigator.pop(context);
                });
              } else if (anime.animeId != 0) {
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
                ).then((value) async {
                  Anime retAnime = value;
                  int findIndex = searchedAnimes.lastIndexWhere(
                      (element) => element.animeName == retAnime.animeName);
                  searchedAnimes[findIndex] =
                      await SqliteUtil.getAnimeByAnimeId(retAnime.animeId);
                  setState(() {});
                });
              } else {
                debugPrint("添加动漫");
                // 其他情况才是添加动漫
                bool standBy = false;
                // 如果是备用数据，则不要使用lastIndexWhere，而是IndexWhere
                if (index == 0) standBy = true;
                dialogSelectTag(setState, context, anime);
              }
            },
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5), // 设置按钮填充
            child: Flex(
              direction: Axis.vertical,
              children: [
                Stack(
                  children: [
                    AnimeGridCover(anime),
                    _displayEpisodeState(anime),
                    _displayReviewNumber(anime),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          anime.animeName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textScaleFactor: 0.9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String selectedWebsite =
      SPUtil.getString("selectedWebsite", defaultValue: "樱花动漫");
  List websites = ["樱花动漫", "OmoFun"];

  _displayWebsiteOption() {
    return ListTile(
      leading: const Icon(Icons.expand_more_outlined),
      title: Text(selectedWebsite),
      onTap: () {
        _dialogSelectWebsite();
      },
    );
  }

  void _dialogSelectWebsite() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < websites.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(websites[i]),
              leading: websites[i] == selectedWebsite
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                selectedWebsite = websites[i];
                SPUtil.setString("selectedWebsite", websites[i]);
                // 如果输入的文本不为空，则再次搜索
                if (lastInputName.isNotEmpty) {
                  searchOk = false;
                  searching = true;
                  searchedAnimes = []; // 清空查找的动漫
                  _climbAnime(keyword: lastInputName);
                }
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('选择搜索源'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  _displayEpisodeState(Anime anime) {
    if (anime.animeId == 0) return Container(); // 没有id，说明未添加

    return Positioned(
        left: 5,
        top: 5,
        child: Container(
          // height: 20,
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.blue,
          ),
          child: Text(
            "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
            textScaleFactor: 0.9,
            style: const TextStyle(color: Colors.white),
          ),
        ));
  }

  _displayReviewNumber(Anime anime) {
    if (anime.animeId == 0) return Container(); // 没有id，说明未添加

    return anime.reviewNumber == 1
        ? Container()
        : Positioned(
            right: 5,
            top: 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.orange,
              ),
              child: Text(
                " ${anime.reviewNumber} ",
                textScaleFactor: 0.9,
                style: const TextStyle(color: Colors.white),
              ),
            ));
  }
}
