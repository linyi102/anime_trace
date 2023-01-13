import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';

import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';

import '../../models/label.dart';
import 'toggleListTile.dart';

/// 搜索已添加的动漫
class SearchDbAnime extends StatefulWidget {
  const SearchDbAnime({Key? key}) : super(key: key);

  @override
  _SearchDbAnimeState createState() => _SearchDbAnimeState();
}

class _SearchDbAnimeState extends State<SearchDbAnime> {
  bool searchOk = false;
  List<Anime> _animes = [];
  String _lastInputText = ""; // 必须作为类成员，否则setstate会重新调用build，然后又赋值为""
  FocusNode blankFocusNode = FocusNode(); // 空白焦点

  final _scrollController = ScrollController();

  bool showLabelPage = true;
  LabelsController labelsController = Get.find();
  List<Label> selectedLabels = [];

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

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
                hintText: "按关键字搜索",
                border: InputBorder.none,
                suffixIcon: IconButton(
                    onPressed: () {
                      inputController.clear();
                      _lastInputText = "";
                      // 清空搜索的动漫，并显示标签页
                      _animes.clear();
                      showLabelPage = true;
                      setState(() {});
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
              if (value.isEmpty) {
                // 删除了搜索关键字，那么就清空搜索的动漫，展示所有标签
                _animes.clear();
                showLabelPage = true;
                _lastInputText = "";
                setState(() {});
                return;
              }

              // 按关键字搜索动漫时，不显示label页面，并且清空选中的label
              showLabelPage = false;
              selectedLabels.clear();
              _searchDbAnimesByKeyword(value);
            },
          ),
        ),
        body: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            children: [
              if (showLabelPage)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ToggleListTile(
                        title: const Text("按标签搜索"),
                        subtitle: const Text("开启多标签搜索"),
                        toggleOn: SpProfile.getEnableMultiLabelQuery(),
                        onTap: () {
                          SpProfile.turnEnableMultiLabelQuery();
                          if (SpProfile.getEnableMultiLabelQuery()) {
                            // 开启多标签后，不需要清空已选中的标签和搜索结果
                          } else {
                            // 关闭多标签后，需要清空已选中的标签，以及搜索结果
                            selectedLabels.clear();
                            _animes.clear();
                          }

                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      _showLabelPage()
                    ],
                  ),
                ),
              if (searchOk) _showSearchPage()
            ],
          ),
        ));
  }

  // 取消键盘聚焦
  _cancelFocus() {
    FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
  }

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
      _animes = value;
      searchOk = true;
      Log.info("_resAnimes.length=${_animes.length}");
      setState(() {});
    });
  }

  _showLabelPage() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: labelsController.labels.map((e) {
        bool checked = selectedLabels.contains(e);
        return GestureDetector(
          onTap: () async {
            // 点击标签后，取消搜索输入框的聚焦
            _cancelFocus();

            // 查询数据库
            if (SpProfile.getEnableMultiLabelQuery()) {
              // 多标签查询
              if (checked) {
                selectedLabels.remove(e);
              } else {
                selectedLabels.add(e);
              }
            } else {
              // 单标签查询，需要先清空选中的标签
              selectedLabels.clear();
              selectedLabels.add(e);
            }

            _animes = await AnimeLabelDao.getAnimesByLabelIds(
                selectedLabels.map((e) => e.id).toList());
            searchOk = true;
            setState(() {});
          },
          child: Chip(
            label: Text(e.name),
            backgroundColor: checked ? Colors.grey : ThemeUtil.getCardColor(),
          ),
        );
      }).toList(),
    );
  }

  _showSearchPage() {
    List<Widget> listWidget = [];
    for (var anime in _animes) {
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
            MaterialPageRoute(
              builder: (context) {
                return AnimeDetailPlus(anime);
              },
            ),
          ).then((value) async {
            Anime newAnime = value;
            if (!newAnime.isCollected()) {
              // 取消收藏
              int findIndex = _animes
                  .indexWhere((element) => element.animeId == anime.animeId);
              _animes.removeAt(findIndex);
              setState(() {});
              return;
            }
            // anime = value; // 无效，因为不是数据成员
            int findIndex = _animes
                .indexWhere((element) => element.animeId == newAnime.animeId);
            if (findIndex != -1) {
              // _resAnimes[findIndex] = value;
              // 直接从数据库中得到最新信息
              _animes[findIndex] = await SqliteUtil.getAnimeByAnimeId(
                  _animes[findIndex].animeId);
              setState(() {});
            } else {
              Log.info("未找到动漫：$value");
            }
          });
        },
      ));
    }

    // 如果是按关键字搜索的话，则显示网络搜索更多提示
    if (_lastInputText.isNotEmpty) {
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
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return AnimeClimbAllWebsite(keyword: _lastInputText);
            })).then((value) {
              _searchDbAnimesByKeyword(_lastInputText);
            });
          }));
    }

    return ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: listWidget);
  }
}
