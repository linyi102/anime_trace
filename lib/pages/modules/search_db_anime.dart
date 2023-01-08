import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class SearchDbAnime extends StatefulWidget {
  const SearchDbAnime({Key? key}) : super(key: key);

  @override
  _SearchDbAnimeState createState() => _SearchDbAnimeState();
}

class _SearchDbAnimeState extends State<SearchDbAnime> {
  bool _searchOk = false;
  late List<Anime> _resAnimes;
  String _lastInputText = ""; // 必须作为类成员，否则setstate会重新调用build，然后又赋值为""
  FocusNode blankFocusNode = FocusNode(); // 空白焦点

  final _scrollController = ScrollController();

  void _searchDbAnimesByKeyword(String text) {
    Log.info(
        "Localizations.localeOf(context)=${Localizations.localeOf(context)}");

    if (_lastInputText == text) {
      Log.info("相同内容，不进行搜索");
      return;
    }
    _lastInputText = text;
    Future(() {
      Log.info("search: $text");
      return SqliteUtil.getAnimesBySearch(text);
    }).then((value) {
      _resAnimes = value;
      _searchOk = true;
      Log.info("_resAnimes.length=${_resAnimes.length}");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // var inputController = TextEditingController();
    var inputController = TextEditingController.fromValue(TextEditingValue(
        // 设置内容
        text: _lastInputText,
        // 保持光标在最后
        selection: TextSelection.fromPosition(TextPosition(
            affinity: TextAffinity.downstream,
            offset: _lastInputText.length))));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          // 自动弹出键盘
          autofocus: true,
          controller: inputController,
          decoration: InputDecoration(
              hintText: "搜索已收藏的动漫",
              border: InputBorder.none,
              suffixIcon: IconButton(
                  onPressed: () {
                    inputController.clear();
                  },
                  icon: const Icon(Icons.close))),
          onEditingComplete: () async {
            String text = inputController.text;
            if (text.isEmpty) {
              return;
            }
            _searchDbAnimesByKeyword(text);
            _cancelFocus();
          },
          onChanged: (value) async {
            Log.info("value=$value");
            if (value.isEmpty) return;
            _searchDbAnimesByKeyword(value);
          },
        ),
      ),
      body: !_searchOk ? Container() : _showSearchPage(),
    );
  }

  // 取消键盘聚焦
  _cancelFocus() {
    FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
  }

  _showSearchPage() {
    List<Widget> listWidget = [];
    for (var anime in _resAnimes) {
      // listWidget.add(AnimeItem(anime));
      listWidget.add(ListTile(
        leading: AnimeListCover(
          anime,
          showReviewNumber: !SPUtil.getBool("hideReviewNumber"),
          reviewNumber: anime.reviewNumber,
        ),
        title: Text(
          anime.animeName,
          textScaleFactor: 0.9,
          overflow: TextOverflow.ellipsis, // 避免名字过长，导致显示多行
        ),
        subtitle: anime.nameAnother.isNotEmpty
            ? Text(
                anime.nameAnother,
                textScaleFactor: 0.8,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Text(
          "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
          textScaleFactor: 0.9,
        ),
        onTap: () {
          _cancelFocus();
          Navigator.of(context).push(
            // MaterialPageRoute(
            //   builder: (context) => AnimeDetailPlus(widget.anime.animeId),
            // ),
            FadeRoute(
              builder: (context) {
                return AnimeDetailPlus(anime);
              },
            ),
          ).then((value) async {
            Anime newAnime = value;
            if (!newAnime.isCollected()) {
              // 取消收藏
              int findIndex = _resAnimes
                  .indexWhere((element) => element.animeId == anime.animeId);
              _resAnimes.removeAt(findIndex);
              setState(() {});
              return;
            }
            // anime = value; // 无效，因为不是数据成员
            int findIndex = _resAnimes
                .indexWhere((element) => element.animeId == newAnime.animeId);
            if (findIndex != -1) {
              // _resAnimes[findIndex] = value;
              // 直接从数据库中得到最新信息
              _resAnimes[findIndex] = await SqliteUtil.getAnimeByAnimeId(
                  _resAnimes[findIndex].animeId);
              setState(() {});
            } else {
              Log.info("未找到动漫：$value");
            }
          });
        },
      ));
    }

    // 添加搜索网络动漫提示
    listWidget.add(ListTile(
        // leading: Icon(Icons.search),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("网络搜索更多 ",
                style: TextStyle(color: ThemeUtil.getPrimaryColor())),
            Icon(Icons.manage_search_outlined,
                color: ThemeUtil.getPrimaryColor())
          ],
        ),
        onTap: () {
          _cancelFocus();
          Navigator.of(context).push(FadeRoute(builder: (context) {
            return AnimeClimbAllWebsite(keyword: _lastInputText);
          })).then((value) {
            _searchDbAnimesByKeyword(_lastInputText);
          });
        }));

    return Scrollbar(
      controller: _scrollController,
      child: ListView(controller: _scrollController, children: listWidget),
    );
  }
}
