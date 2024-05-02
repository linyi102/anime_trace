import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_list_tile.dart';
import 'package:flutter_test_future/components/search_app_bar.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/widgets/local_filter_chip.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/utils/log.dart';
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
  late TextEditingController _inputController;
  FocusNode blankFocusNode = FocusNode();
  bool autofocus = false;

  final _scrollController = ScrollController();

  final localSearchControllerTag = DateTime.now().toString();
  late final localSearchController = Get.put<LocalSearchController>(
    LocalSearchController(),
    tag: localSearchControllerTag,
  );
  bool get searchOk => localSearchController.searchOk;
  List<Anime> get _animes => localSearchController.animes;

  bool get selectAction => widget.onSelectOk != null;
  List<int> selectedAnimeIds = [];

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.kw ?? '');

    // 动漫详细页点击某个标签后，会进入该搜索页，此时不需要显示顶部搜索框，还需要把传入的标签添加进来
    if (widget.incomingLabelId != null) {
      Log.info("动漫详细页点击了${widget.incomingLabelId}，进入搜索页");
      // 从controller中根据id找到label对象，再添加到选中的labels中
      // 之所以不直接传入label对象，是因为这个对象和controller中的labels里的同id对象不是同一个对象
      // TODO
      // selectedLabels.add(labelsController.labels
      //     .singleWhere((element) => element.id == widget.incomingLabelId));
      // _searchAnimesByLabels();
    }

    // 周表中点击某个动漫会进入该搜索页，来查找已收藏的动漫
    if (widget.kw != null) {
      // 取消输入框聚焦
      autofocus = false;
      // 等待200ms再去搜索，避免导致页面切换动画卡顿
      Future.delayed(const Duration(milliseconds: 200)).then((value) {
        localSearchController.searchKeyword(widget.kw);
      });
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
    // 如果传入了标签id，则说明是从动漫详细页进来的，此时不显示搜索栏
    bool showSearchBar = widget.incomingLabelId == null;

    Log.build(runtimeType);

    return GetBuilder(
      init: localSearchController,
      builder: (_) => Scaffold(
        appBar: showSearchBar ? _buildSearchBar() : AppBar(),
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
                    // Log.info("$runtimeType: index=$index");
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
      child: GetBuilder(
        init: localSearchController,
        builder: (_) => Row(
          children: [
            ...localSearchController.filters.map((filter) => LocalFilterChip(
                localSearchController: localSearchController, filter: filter))
          ],
        ),
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
        localSearchController.searchKeyword(null);
      },
      onChanged: (value) {
        localSearchController.searchKeyword(value);
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
    );
  }
}
