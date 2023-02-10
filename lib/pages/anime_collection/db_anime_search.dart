import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/models/anime.dart';

import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';

import '../../models/label.dart';
import '../../components/anime_list_view.dart';

/// 搜索已添加的动漫
class DbAnimeSearchPage extends StatefulWidget {
  const DbAnimeSearchPage({this.incomingLabelId, this.kw, Key? key})
      : super(key: key);
  final int? incomingLabelId;
  final String? kw;

  @override
  _DbAnimeSearchPageState createState() => _DbAnimeSearchPageState();
}

class _DbAnimeSearchPageState extends State<DbAnimeSearchPage> {
  bool searchOk = false;
  List<Anime> _animes = [];
  String _lastInputText = ""; // 必须作为类成员，否则setstate会重新调用build，然后又赋值为""
  FocusNode blankFocusNode = FocusNode(); // 空白焦点

  final _scrollController = ScrollController();

  bool showLabelPage = true;
  LabelsController labelsController = Get.find();
  List<Label> selectedLabels = [];

  bool autofocus = true;

  @override
  void initState() {
    super.initState();
    Log.info("$runtimeType: initState");

    // 动漫详细页点击某个标签后，会进入该搜索页，此时不需要显示顶部搜索框，还需要把传入的标签添加进来
    if (widget.incomingLabelId != null) {
      Log.info("动漫详细页点击了${widget.incomingLabelId}，进入搜索页");
      // 从controller中根据id找到label对象，再添加到选中的labels中
      // 之所以不直接传入label对象，是因为这个对象和controller中的labels里的同id对象不是同一个对象
      selectedLabels.add(labelsController.labels
          .singleWhere((element) => element.id == widget.incomingLabelId));
      _searchAnimesByLabels();
    }

    // 周表中点击某个动漫会进入该搜索页，来查找已收藏的动漫
    if (widget.kw != null) {
      // 不显示标签
      showLabelPage = false;
      // 取消输入框聚焦
      autofocus = false;
      // 等待200ms再去搜索，避免导致页面切换动画卡顿
      Future.delayed(const Duration(milliseconds: 200))
          .then((value) => _searchDbAnimesByKeyword(widget.kw!));
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);
    var inputController = TextEditingController.fromValue(TextEditingValue(
        // 设置内容
        text: _lastInputText,
        // 保持光标在最后
        selection: TextSelection.fromPosition(TextPosition(
            affinity: TextAffinity.downstream,
            offset: _lastInputText.length))));

    return Scaffold(
      appBar: AppBar(
        title: widget.incomingLabelId == null
            ? _buildSearchBar(inputController)
            : null, // 如果传入了标签id，则说明是从动漫详细页进来的，此时不显示搜索栏
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (showLabelPage)
            SliverToBoxAdapter(
              child: _buildLabelsCard(),
            ),
          if (searchOk)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  Log.info("$runtimeType: index=$index");
                  return AnimeListTile(
                    anime: _animes[index],
                    index: index,
                    animeTileSubTitle: AnimeTileSubTitle.nameAnother,
                    showReviewNumber: true,
                    showTrailingProgress: true,
                    onClick: (index) {
                      _enterAnimeDetail(index);
                    },
                  );
                },
                childCount: _animes.length,
              ),
            ),
          // 搜索关键字后，显示网络搜索更多，点击后会进入聚合搜索页搜索关键字
          if (searchOk && inputController.text.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildNetworkSearchHint(context),
            )
        ],
      ),
    );
  }

  TextField _buildSearchBar(TextEditingController inputController) {
    return TextField(
      // 自动弹出键盘
      autofocus: autofocus,
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
    );
  }

  _buildNetworkSearchHint(BuildContext context) {
    return ListTile(
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
        });
  }

  _buildLabelsCard() {
    return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("按标签搜索"),
                const Spacer(),
                TextButton(
                  onPressed: () {
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
                  child: Text(
                    SpProfile.getEnableMultiLabelQuery() ? "关闭多标签" : "开启多标签",
                    textScaleFactor: ThemeUtil.tinyScaleFactor,
                    style: TextStyle(color: ThemeUtil.getCommentColor()),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    selectedLabels.clear();
                    _animes.clear();
                    setState(() {});
                  },
                  child: Text(
                    "清空选中",
                    textScaleFactor: ThemeUtil.tinyScaleFactor,
                    style: TextStyle(color: ThemeUtil.getCommentColor()),
                  ),
                )
              ],
            ),
            const SizedBox(height: 5),
            _buildLabelWrap()
          ],
        ));
  }

  // 取消键盘聚焦
  _cancelFocus() {
    FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
  }

  void _searchDbAnimesByKeyword(String text) {
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

  _searchAnimesByLabels() async {
    if (selectedLabels.isNotEmpty) {
      _animes = await AnimeLabelDao.getAnimesByLabelIds(
          selectedLabels.map((e) => e.id).toList());
    } else {
      // 没有标签时不查询数据库，直接清空
      _animes.clear();
    }
    searchOk = true;
    setState(() {});
  }

  _buildLabelWrap() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: labelsController.labels.reversed.map((e) {
        bool checked = selectedLabels.contains(e);

        return GestureDetector(
          onTap: () async {
            // 点击标签后，取消搜索输入框的聚焦
            _cancelFocus();

            // 查询数据库
            if (SpProfile.getEnableMultiLabelQuery()) {
              // 多标签查询
              if (checked) {
                Log.info("移除$e");
                selectedLabels.remove(e);
              } else {
                selectedLabels.add(e);
              }
            } else {
              // 单标签查询，需要先清空选中的标签
              selectedLabels.clear();
              selectedLabels.add(e);
            }

            _searchAnimesByLabels();
          },
          child: Chip(
            label: Text(e.name),
            backgroundColor: checked ? Colors.grey : ThemeUtil.getCardColor(),
          ),
        );
      }).toList(),
    );
  }

  _enterAnimeDetail(int index) {
    Anime anime = _animes[index];

    _cancelFocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return AnimeDetailPage(anime);
        },
      ),
    ).then((value) async {
      Anime newAnime = value;
      if (!newAnime.isCollected()) {
        // 取消收藏
        int findIndex =
            _animes.indexWhere((element) => element.animeId == anime.animeId);
        _animes.removeAt(findIndex);
        setState(() {});
        return;
      }
      // anime = value; // 无效，因为不是数据成员
      int findIndex =
          _animes.indexWhere((element) => element.animeId == newAnime.animeId);
      if (findIndex != -1) {
        // _resAnimes[findIndex] = value;
        // 直接从数据库中得到最新信息
        _animes[findIndex] =
            await SqliteUtil.getAnimeByAnimeId(_animes[findIndex].animeId);
        setState(() {});
      } else {
        Log.info("未找到动漫：$value");
      }
    });
  }
}
