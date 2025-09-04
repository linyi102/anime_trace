import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_list_tile.dart';
import 'package:animetrace/components/search_app_bar.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/label.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/pages/local_search/controllers/local_search_controller.dart';
import 'package:animetrace/pages/local_search/widgets/local_filter_chip.dart';
import 'package:animetrace/pages/network/climb/anime_climb_all_website.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:get/get.dart';

/// 搜索已添加的动漫
class DbAnimeSearchPage extends StatefulWidget {
  const DbAnimeSearchPage(
      {this.label,
      this.kw,
      this.onSelectOk,
      this.hasSelectedAnimeIds = const [],
      Key? key})
      : super(key: key);

  /// 需要搜索的标签
  final Label? label;

  /// 需要搜索的关键字
  final String? kw;

  /// 已选择的初始动漫id列表
  final List<int> hasSelectedAnimeIds;

  /// 选择成功后的回调，返回已选择的动漫id列表
  /// 函数不为null时显示选择视图
  final void Function(List<int> selectedAnimeIds)? onSelectOk;

  @override
  _DbAnimeSearchPageState createState() => _DbAnimeSearchPageState();
}

class _DbAnimeSearchPageState extends State<DbAnimeSearchPage> {
  final _scrollController = ScrollController();
  late TextEditingController _inputController;
  FocusNode blankFocusNode = FocusNode();

  final localSearchControllerTag = DateTime.now().toString();
  late final localSearchController = Get.put<LocalSearchController>(
    LocalSearchController(localSearchControllerTag),
    tag: localSearchControllerTag,
  );
  bool get searchOk => localSearchController.searchOk;
  List<Anime> get _animes => localSearchController.animes;

  bool get selectAction => widget.onSelectOk != null;
  List<int> selectedAnimeIds = [];

  bool autofocusSearchInput = true;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.kw ?? '');
    _searchInitialFilter();
  }

  Future<void> _searchInitialFilter() async {
    if (widget.label != null) {
      autofocusSearchInput = false;
      AppLog.info("动漫详细页点击了${widget.label}，进入搜索页");
      await Future.delayed(const Duration(milliseconds: 200));
      localSearchController.setLabels([widget.label!]);
    } else if (widget.kw != null) {
      autofocusSearchInput = false;
      // 等待200ms再去搜索，避免导致页面切换动画卡顿
      await Future.delayed(const Duration(milliseconds: 200));
      localSearchController.setKeyword(widget.kw);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    Get.delete<LocalSearchController>(tag: localSearchControllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: localSearchController,
      tag: localSearchControllerTag,
      builder: (_) => Scaffold(
        appBar: _buildSearchBar(),
        floatingActionButton: _buildFAB(),
        body: CommonScaffoldBody(
            child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (searchOk)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // AppLog.info("$runtimeType: index=$index");
                    var anime = _animes[index];
                    return _buildAnimeTile(anime, context, index);
                  },
                  childCount: _animes.length,
                ),
              ),
            // 搜索关键字后，显示网络搜索更多，点击后会进入聚合搜索页搜索关键字
            if (searchOk && _inputController.text.isNotEmpty && !selectAction)
              SliverToBoxAdapter(child: _buildNetworkSearchHint(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 60))
          ],
        )),
      ),
    );
  }

  SingleChildScrollView _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          ...localSearchController.filters.map((filter) => LocalFilterChip(
              localSearchController: localSearchController, filter: filter))
        ],
      ),
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
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? Theme.of(context).colorScheme.primary : null,
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
      autofocus: autofocusSearchInput,
      inputController: _inputController,
      onTapClear: () {
        _inputController.clear();
        localSearchController.setKeyword(null);
      },
      onChanged: (value) {
        localSearchController.setKeyword(value);
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
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            Icon(Icons.manage_search_outlined,
                color: Theme.of(context).colorScheme.primary)
          ],
        ),
        onTap: () {
          _cancelFocus();
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return AnimeClimbAllWebsite(keyword: _inputController.text);
          }));
        });
  }

  // 取消键盘聚焦
  _cancelFocus() {
    FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
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
    ).then((popAnime) {
      _animes[index] = popAnime;
    });
  }
}
