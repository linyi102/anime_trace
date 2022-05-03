import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_climb_all_website.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  bool _searchOk = false;
  late List<Anime> _resAnimes;
  String lastInputText = ""; // 必须作为类成员，否则setstate会重新调用build，然后又赋值为""
  FocusNode blankFocusNode = FocusNode(); // 空白焦点

  void searchDbAnimesByKeyword(String text) {
    Future(() {
      debugPrint("search: $text");
      return SqliteUtil.getAnimesBySearch(text);
    }).then((value) {
      _resAnimes = value;
      _searchOk = true;
      debugPrint("_resAnimes.length=${_resAnimes.length}");
      // for (var item in _resAnimes) {
      //   debugPrint(item.toString());
      // }
      lastInputText = text;
      FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // var inputController = TextEditingController();
    var inputController = TextEditingController.fromValue(TextEditingValue(
        // 设置内容
        text: lastInputText,
        // 保持光标在最后
        selection: TextSelection.fromPosition(TextPosition(
            affinity: TextAffinity.downstream, offset: lastInputText.length))));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true, // 自动弹出键盘
          controller: inputController,
          decoration: InputDecoration(
              hintText: "搜索已收藏的动漫",
              border: InputBorder.none,
              suffixIcon: IconButton(
                  onPressed: () {
                    inputController.clear();
                  },
                  icon: const Icon(Icons.close, color: Colors.black))),
          onEditingComplete: () async {
            String text = inputController.text;
            if (text.isEmpty) {
              return;
            }
            searchDbAnimesByKeyword(text);
          },
        ),
      ),
      body: !_searchOk ? Container() : _showSearchPage(),
    );
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
        trailing: Text(
          "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
          textScaleFactor: 0.9,
          style: const TextStyle(
            color: Colors.black,
            // fontWeight: FontWeight.w400,
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            // MaterialPageRoute(
            //   builder: (context) => AnimeDetailPlus(widget.anime.animeId),
            // ),
            FadeRoute(
              builder: (context) {
                return AnimeDetailPlus(anime.animeId);
              },
            ),
          ).then((value) async {
            // anime = value; // 无效，因为不是数据成员
            int findIndex = _resAnimes.indexWhere(
                (element) => element.animeId == (value as Anime).animeId);
            if (findIndex != -1) {
              // _resAnimes[findIndex] = value;
              // 直接从数据库中得到最新信息
              _resAnimes[findIndex] = await SqliteUtil.getAnimeByAnimeId(
                  _resAnimes[findIndex].animeId);
              setState(() {});
            } else {
              debugPrint("未找到动漫：$value");
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
          children: const [
            Text("网络搜索更多 ", style: TextStyle(color: Colors.blue)),
            Icon(Icons.manage_search_outlined, color: Colors.blue)
          ],
        ),
        onTap: () {
          Navigator.of(context).push(FadeRoute(builder: (context) {
            return AnimeClimbAllWebsite(keyword: lastInputText);
          })).then((value) {
            searchDbAnimesByKeyword(lastInputText);
          });
        }));

    return Scrollbar(
      child: ListView(children: listWidget),
    );
  }
}
