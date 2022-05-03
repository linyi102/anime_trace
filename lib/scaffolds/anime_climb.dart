import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_confirm_migrate.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_tag.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';

class AnimeClimb extends StatefulWidget {
  final int animeId;
  final String keyword;
  final ClimbWebstie climbWebStie;
  const AnimeClimb(
      {this.animeId = 0,
      this.keyword = "",
      required this.climbWebStie,
      Key? key})
      : super(key: key);

  @override
  _AnimeClimbState createState() => _AnimeClimbState();
}

class _AnimeClimbState extends State<AnimeClimb> {
  var animeNameController = TextEditingController();
  var endEpisodeController = TextEditingController();
  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  late bool ismigrate;

  List<Anime> websiteClimbAnimes = [];
  List<Anime> mixedAnimes = [];
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
      _climbAnime(keyword: widget.keyword);
    }
  }

  _climbAnime({String keyword = ""}) {
    debugPrint("开始爬取动漫封面");
    searchOk = false;
    searching = true;
    setState(() {}); // 显示加载圈，注意会暂时导致光标移到行首

    Future(() async {
      return ClimbAnimeUtil.climbAnimesByKeyword(keyword, widget.climbWebStie);
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

  Future<bool> _generateMixedAnimes() async {
    mixedAnimes = websiteClimbAnimes;
    for (var i = 0; i < websiteClimbAnimes.length; i++) {
      mixedAnimes[i] = await SqliteUtil.getAnimeByAnimeUrl(mixedAnimes[i]);
    }
    return true;
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
            title: Text(widget.climbWebStie.name),
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
    return AnimatedSwitcher(
      key: UniqueKey(), // 不一样的搜索结果也需要过渡
      duration: const Duration(milliseconds: 200),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              SPUtil.getInt("gridColumnCnt", defaultValue: 3), // 横轴数量
          crossAxisSpacing: 5, // 横轴距离
          mainAxisSpacing: 3, // 竖轴距离
          childAspectRatio: 31 / 56, // 每个网格的比例
        ),
        itemCount: mixedAnimes.length,
        itemBuilder: (BuildContext context, int index) {
          Anime anime = mixedAnimes[index];
          return MaterialButton(
            onPressed: () async {
              // 迁移动漫
              if (ismigrate) {
                showDialogOfConfirmMigrate(context, widget.animeId, anime);
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
