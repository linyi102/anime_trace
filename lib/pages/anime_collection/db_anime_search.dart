import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_list_tile.dart';
import 'package:flutter_test_future/components/search_app_bar.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/label.dart';

import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/delay_util.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:get/get.dart';

/// 搜索已添加的动漫
class DbAnimeSearchPage extends StatefulWidget {
  const DbAnimeSearchPage(
      {this.incomingLabelId,
      this.kw,
      this.onSelectOk,
      this.hasSelectedAnimeIds = const [],
      Key? key})
      : super(key: key);
  final int? incomingLabelId;
  final List<int> hasSelectedAnimeIds;
  final void Function(List<int> selectedAnimeIds)? onSelectOk;
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

  bool get selectAction => widget.onSelectOk != null;
  List<int> selectedAnimeIds = [];

  late TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    Log.info("$runtimeType: initState");
    _inputController = TextEditingController(text: widget.kw ?? '');

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
    _inputController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果传入了标签id，则说明是从动漫详细页进来的，此时不显示搜索栏
    bool showSearchBar = widget.incomingLabelId == null;

    Log.build(runtimeType);

    return Scaffold(
      appBar: showSearchBar ? _buildSearchBar() : AppBar(),
      floatingActionButton: _buildFAB(),
      body: CommonScaffoldBody(
          child: CustomScrollView(
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
                  // Log.info("$runtimeType: index=$index");
                  var anime = _animes[index];
                  return _buildAnimeTile(anime, context, index);
                },
                childCount: _animes.length,
              ),
            ),
          // 搜索关键字后，显示网络搜索更多，点击后会进入聚合搜索页搜索关键字
          if (searchOk && _inputController.text.isNotEmpty && !selectAction)
            SliverToBoxAdapter(
              child: _buildNetworkSearchHint(context),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 60),
          )
        ],
      )),
    );
  }

  FloatingActionButton? _buildFAB() {
    return selectAction
        ? FloatingActionButton(
            onPressed: () {
              widget.onSelectOk?.call(selectedAnimeIds);
              Navigator.pop(context);
            },
            child: const Icon(Icons.check),
          )
        : null;
  }

  AnimeListTile _buildAnimeTile(Anime anime, BuildContext context, int index) {
    // 已添加，不允许修改为未选择状态(避免用户误认为可以从系列中删除)
    bool hasSelected = widget.hasSelectedAnimeIds.contains(anime.animeId);
    // 本次添加动作中新选择的
    bool selected = selectedAnimeIds.contains(anime.animeId);
    return AnimeListTile(
      anime: anime,
      animeTileSubTitle: AnimeTileSubTitle.nameAnother,
      showReviewNumber: true,
      showTrailingProgress: selectAction ? false : true,
      trailing: selectAction
          ? hasSelected
              ? Icon(Icons.check, color: Theme.of(context).primaryColor)
              : Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? Theme.of(context).primaryColor : null,
                )
          : null,
      onTap: () {
        if (selectAction) {
          if (selected) {
            selectedAnimeIds.remove(anime.animeId);
          } else {
            selectedAnimeIds.add(anime.animeId);
          }
          setState(() {});
          return;
        }
        _enterAnimeDetail(index);
      },
    );
  }

  _buildSearchBar() {
    return SearchAppBar(
      hintText: "搜索已收藏动漫",
      useModernStyle: false,
      autofocus: autofocus,
      inputController: _inputController,
      onTapClear: () {
        _inputController.clear();
        _lastInputText = "";
        // 清空搜索的动漫，并显示标签页
        _animes.clear();
        showLabelPage = true;
        setState(() {});
      },
      onEditingComplete: () {
        String text = _inputController.text;
        if (text.isEmpty) return;

        _searchDbAnimesByKeyword(text);
      },
      onChanged: (value) {
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

        // 延时搜索
        DelayUtil.delaySearch(() {
          _searchDbAnimesByKeyword(value);
        });
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
                style: TextStyle(color: Theme.of(context).primaryColor)),
            Icon(Icons.manage_search_outlined,
                color: Theme.of(context).primaryColor)
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
                    style: Theme.of(context).textTheme.bodySmall,
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
                    style: Theme.of(context).textTheme.bodySmall,
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

  void _searchDbAnimesByKeyword(String text, {bool forceSearch = false}) {
    if (text.isEmpty) {
      Log.info('输入内容为空，不进行搜索');
      return;
    }
    if (!forceSearch && _lastInputText == text) {
      Log.info("相同内容，不进行搜索");
      return;
    }
    _lastInputText = text;
    Future(() {
      Log.info("search: $text");
      return AnimeDao.getAnimesBySearch(text);
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
    // 使用obx监听，否则labelController懒加载，打开app后进入本地搜索页看不到标签
    return Obx(() => Wrap(
          spacing: AppTheme.wrapSacing,
          runSpacing: AppTheme.wrapRunSpacing,
          children: labelsController.labels.reversed.map((e) {
            bool checked = selectedLabels.contains(e);

            return FilterChip(
              showCheckmark: false,
              pressElevation: 0,
              selected: checked,
              label: Text(e.name),
              onSelected: (value) {
                // 点击标签后，取消搜索输入框的聚焦
                _cancelFocus();

                // 查询数据库
                if (SpProfile.getEnableMultiLabelQuery()) {
                  // 多标签查询
                  if (checked) {
                    Log.info("移除");
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

              // backgroundColor:checked ? Theme.of(context).
              // backgroundColor: checked
              //     ? Theme.of(context).chipTheme.selectedColor
              //     : Theme.of(context).chipTheme.disabledColor,
            );
          }).toList(),
        ));
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
      // 选择的标签不为空时，说明是点击标签后进入的动漫详情页，返回后要重新根据标签查询动漫
      if (selectedLabels.isNotEmpty) {
        _searchAnimesByLabels();
      } else {
        _searchDbAnimesByKeyword(_lastInputText, forceSearch: true);
      }
    });
  }
}
