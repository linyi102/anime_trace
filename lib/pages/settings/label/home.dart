import 'package:animetrace/modules/sortable/sortable.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/search_app_bar.dart';
import 'package:animetrace/pages/anime_detail/controllers/anime_controller.dart';
import 'package:animetrace/controllers/labels_controller.dart';
import 'package:animetrace/dao/anime_label_dao.dart';
import 'package:animetrace/dao/label_dao.dart';
import 'package:animetrace/models/label.dart';
import 'package:animetrace/pages/settings/label/form.dart';
import 'package:animetrace/pages/settings/label/recommend.dart';
import 'package:animetrace/utils/delay_util.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/bottom_sheet.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:reorderables/reorderables.dart';

class LabelManagePage extends StatefulWidget {
  const LabelManagePage(
      {this.enableSelectLabelForAnime = false, this.animeController, Key? key})
      : super(key: key);
  final bool enableSelectLabelForAnime;
  final AnimeController? animeController;

  static const int labelMaxLength = 30;

  @override
  State<LabelManagePage> createState() => _LabelManagePageState();
}

class _LabelManagePageState extends State<LabelManagePage> {
  bool searchAction = false;
  LabelsController labelsController = LabelsController.to;

  @override
  Widget build(BuildContext context) {
    if (labelsController.kw.isNotEmpty) {
      _enterSearchModeIfHasKeyword();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: searchAction
          ? _buildSearchBar()
          : AppBar(
              title: Text(widget.enableSelectLabelForAnime ? "选择标签" : "标签管理"),
              automaticallyImplyLeading:
                  widget.enableSelectLabelForAnime ? false : true,
              actions: [
                IconButton(
                    onPressed: () {
                      _showLayoutBottomSheet();
                    },
                    icon: const Icon(Icons.layers_outlined)),
                IconButton(
                    onPressed: () {
                      setState(() {
                        searchAction = !searchAction;
                      });
                    },
                    icon: const Icon(Icons.search))
              ],
            ),
      body: CommonScaffoldBody(
          child: ListView(
        children: [
          _buildRecommendedLabel(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Obx(() => _buildLabelWrap()),
          ),
          const SizedBox(height: 50),
        ],
      )),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  ListTile _buildRecommendedLabel() {
    return ListTile(
      title: const Text('推荐标签'),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        // RouteUtil.materialTo(context, const RecommendedLabelListView());
        showCommonModalBottomSheet(
          context: context,
          builder: (context) => const RecommendedLabelListView(),
        );
      },
    );
  }

  _buildLabelWrap() {
    return ReorderableWrap(
        spacing: AppTheme.wrapSacing,
        runSpacing: AppTheme.wrapRunSpacing,
        enableReorder: labelsController.sortController.curMode ==
            labelsController.customSortMode,
        onReorder: labelsController.reorder,
        buildDraggableFeedback: _buildDraggableLabel,
        children: labelsController.labels.map((label) {
          bool selected = false;
          if (widget.animeController != null) {
            selected = widget.animeController!.labels
                    .indexWhere((element) => element.id == label.id) >
                -1;
          }

          return GestureDetector(
            child: Chip(
              label: Text(label.name),
              backgroundColor: widget.enableSelectLabelForAnime && selected
                  ? Theme.of(context).chipTheme.selectedColor
                  : null,
            ),
            onTap: () async {
              if (widget.enableSelectLabelForAnime) {
                if (selected) {
                  // 为这个动漫移除该标签
                  if (await AnimeLabelDao.deleteAnimeLabel(
                      widget.animeController!.anime.animeId, label.id)) {
                    AppLog.info(
                        "移除动漫标签记录成功(animeId=${widget.animeController!.anime.animeId}, labelId=${label.id})");
                    // 从controller中移除
                    widget.animeController!.labels
                        .removeWhere((element) => element.id == label.id);
                  } else {
                    AppLog.info("移除动漫标签记录失败");
                  }
                } else {
                  // 为这个动漫添加该标签
                  int newId = await AnimeLabelDao.insertAnimeLabel(
                      widget.animeController!.anime.animeId, label.id);
                  if (newId > 0) {
                    AppLog.info("添加新动漫标签纪录成功：$newId");
                    // 添加到controller
                    widget.animeController!.labels.add(label);
                  } else {
                    AppLog.info("添加新动漫标签纪录失败");
                  }
                }
              } else {
                // 弹出对话框，提供重命名和删除操作
                _showOpMenuDialog(label);
              }
            },
          );
        }).toList());
  }

  Transform _buildDraggableLabel(
      BuildContext context, BoxConstraints constraints, Widget child) {
    return Transform(
      transform: Matrix4.rotationZ(0),
      alignment: FractionalOffset.topLeft,
      child: Container(
          constraints: constraints,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(24),
              offset: const Offset(0, 8),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ]),
          child: child),
    );
  }

  _buildSearchBar() {
    return SearchAppBar(
      isAppBar: true,
      autofocus: true,
      useModernStyle: false,
      showCancelButton: true,
      inputController: labelsController.inputKeywordController,
      automaticallyImplyLeading:
          widget.enableSelectLabelForAnime ? false : true,
      hintText: "搜索标签",
      onChanged: (kw) async {
        _search(kw);
      },
      onTapClear: () async {
        labelsController.inputKeywordController.clear();
        labelsController.kw = "";
        labelsController.getAllLabels();
      },
      onTapCancelButton: () {
        labelsController.inputKeywordController.clear();
        labelsController.kw = "";
        labelsController.getAllLabels();
        setState(() {
          searchAction = false;
        });
      },
    );
  }

  void _search(String kw) {
    AppLog.info("搜索标签关键字：$kw");

    // 必须要查询数据库，而不是从已查询的全部数据中删除不含关键字的记录，否则会越删越少
    DelayUtil.delaySearch(() async {
      labelsController.labels.value = await LabelDao.searchLabel(kw);
      labelsController.kw = kw; // 记录关键字
    });
  }

  _showOpMenuDialog(Label label) {
    return showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              children: [
                ListTile(
                  title: const Text("重命名"),
                  leading: const Icon(Icons.edit),
                  onTap: () {
                    AppLog.info("重命名标签：$label");
                    Navigator.of(context).pop();

                    int index = labelsController.labels
                        .indexWhere((element) => element == label);
                    _showDialogModifyLabel(index);
                  },
                ),
                ListTile(
                  title: const Text("删除"),
                  leading: const Icon(Icons.delete_outline),
                  onTap: () {
                    AppLog.info("删除标签：$label");
                    Navigator.of(context).pop();

                    int index = labelsController.labels
                        .indexWhere((element) => element == label);

                    _showDialogDeleteLable(label, index);
                  },
                )
              ],
            ));
  }

  Future<dynamic> _showDialogDeleteLable(Label label, int index) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("确定删除吗？"),
              content: Text("将要删除的标签：${label.name}"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("取消")),
                TextButton(
                    onPressed: () {
                      LabelDao.delete(label.id);
                      labelsController.labels.removeAt(index);
                      // 如果在动漫详细页打开的标签管理页中删除了标签，那么也需要移除下面的标签
                      if (widget.enableSelectLabelForAnime) {
                        widget.animeController!.labels
                            .removeWhere((element) => element.id == label.id);
                      }
                      Navigator.pop(context);
                    },
                    child: Text(
                      "删除",
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    )),
              ],
            ));
  }

  _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return const LabelForm();
            });
      },
      child: const Icon(MingCuteIcons.mgc_add_line),
    );
  }

  _showDialogModifyLabel(int index) {
    Label label = labelsController.labels[index];

    showDialog(
        context: context,
        builder: (context) {
          return LabelForm(
              label: label,
              onUpdate: (newLabelName) async {
                bool upadteSuccess =
                    await labelsController.updateLabel(label, newLabelName);
                Navigator.pop(context);

                if (!upadteSuccess) {
                  return;
                }

                if (widget.enableSelectLabelForAnime) {
                  int index = widget.animeController!.labels
                      .indexWhere((element) => element.id == label.id);
                  // 如果动漫添加了该标签，则更新动漫里的这个标签
                  if (index >= 0) {
                    widget.animeController!.labels[index] = label;
                  }
                }
              });
        });
  }

  void _enterSearchModeIfHasKeyword() async {
    if (labelsController.kw.isNotEmpty) {
      setState(() {
        searchAction = true;
      });
    }
  }

  void _showLayoutBottomSheet() {
    showCommonModalBottomSheet(
      context: context,
      builder: (context) => Scaffold(
        appBar:
            AppBar(title: const Text('排序'), automaticallyImplyLeading: false),
        body: SortOptionView(controller: labelsController.sortController),
      ),
    );
  }
}
