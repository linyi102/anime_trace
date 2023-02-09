import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/dao/label_dao.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';

import '../../utils/theme_util.dart';

class LabelManagePage extends StatelessWidget {
  const LabelManagePage(
      {this.enableSelectLabelForAnime = false, this.animeController, Key? key})
      : super(key: key);
  final bool enableSelectLabelForAnime;
  final AnimeController? animeController;

  static const int labelMaxLength = 30;

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    // 把不能使用final的数据放在方法里，好处是可以使用const
    // 缺点是要想提取子组件时，需要传递很多参数
    LabelsController labelsController = Get.find();
    var inputKeywordController = TextEditingController();
    _renewAllLabels(labelsController);

    return Scaffold(
      appBar: AppBar(
        title: Text(enableSelectLabelForAnime ? "选择标签" : "标签管理",
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
        children: [
          _buildSearchBar(inputKeywordController, labelsController),
          const SizedBox(height: 20),
          Obx(() => _buildLabelWrap(labelsController, context)),
          // 底部空白，避免加号悬浮按钮遮挡删除按钮
          const ListTile(),
          const ListTile(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(
          context, labelsController, inputKeywordController),
    );
  }

  _buildLabelWrap(LabelsController labelsController, BuildContext context) {
    return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: labelsController.labels.reversed.map((label) {
          bool selected = false;
          if (animeController != null) {
            selected = animeController!.labels
                    .indexWhere((element) => element.id == label.id) >
                -1;
          }

          return GestureDetector(
            child: Chip(
              label: Text(label.name),
              backgroundColor: enableSelectLabelForAnime && selected
                  ? Colors.grey
                  : ThemeUtil.getCardColor(),
            ),
            onTap: () async {
              if (enableSelectLabelForAnime) {
                if (selected) {
                  // 为这个动漫移除该标签
                  if (await AnimeLabelDao.deleteAnimeLabel(
                      animeController!.anime.value.animeId, label.id)) {
                    Log.info(
                        "移除动漫标签记录成功(animeId=${animeController!.anime.value.animeId}, labelId=${label.id})");
                    // 从controller中移除
                    animeController!.labels
                        .removeWhere((element) => element.id == label.id);
                  } else {
                    Log.info("移除动漫标签记录失败");
                  }
                } else {
                  // 为这个动漫添加该标签
                  int newId = await AnimeLabelDao.insertAnimeLabel(
                      animeController!.anime.value.animeId, label.id);
                  if (newId > 0) {
                    Log.info("添加新动漫标签纪录成功：$newId");
                    // 添加到controller
                    animeController!.labels.add(label);
                  } else {
                    Log.info("添加新动漫标签纪录失败");
                  }
                }
              } else {
                // 弹出对话框，提供重命名和删除操作
                _showOpMenuDialog(context, label, labelsController);
              }
            },
            onLongPress: () {
              // 长按时也要弹出操作菜单，这样为动漫选择标签时也能重命名和删除了
              _showOpMenuDialog(context, label, labelsController);
            },
          );
        }).toList());
  }

  _buildSearchBar(TextEditingController inputKeywordController,
      LabelsController labelsController) {
    return TextField(
      controller: inputKeywordController,
      decoration: const InputDecoration(
        hintText: "搜索标签",
        prefixIcon: Icon(Icons.search),
        contentPadding: EdgeInsets.all(0),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
      ),
      onChanged: (kw) async {
        Log.info("搜索标签关键字：$kw");
        // 必须要查询数据库，而不是从已查询的全部数据中删除不含关键字的记录，否则会越删越少
        labelsController.labels.value = await LabelDao.searchLabel(kw);
        labelsController.kw = kw; // 记录关键字
      },
      onEditingComplete: () {},
    );
  }

  Future<dynamic> _showOpMenuDialog(
      BuildContext context, Label label, LabelsController labelsController) {
    return showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              children: [
                SimpleDialogOption(
                  child: const Text("重命名"),
                  onPressed: () {
                    Log.info("重命名标签：$label");
                    Navigator.of(context).pop();

                    int index = labelsController.labels
                        .indexWhere((element) => element == label);
                    _showDialogModifyLabel(context, index, labelsController);
                  },
                ),
                SimpleDialogOption(
                  child: const Text("删除"),
                  onPressed: () {
                    Log.info("删除标签：$label");
                    Navigator.of(context).pop();

                    int index = labelsController.labels
                        .indexWhere((element) => element == label);

                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text("确定删除吗？"),
                              content: Text("要删除的标签：${label.name}"),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("取消")),
                                ElevatedButton(
                                    onPressed: () {
                                      LabelDao.delete(label.id);
                                      labelsController.labels.removeAt(index);
                                      // 如果在动漫详细页打开的标签管理页中删除了标签，那么也需要移除下面的标签
                                      if (enableSelectLabelForAnime) {
                                        animeController!.labels.removeWhere(
                                            (element) =>
                                                element.id == label.id);
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: const Text("确定")),
                              ],
                            ));
                  },
                )
              ],
            ));
  }

  _buildFloatingActionButton(BuildContext context,
      LabelsController labelsController, var inputKeywordController) {
    Log.info("_buildFloatingActionButton");

    return FloatingActionButton(
      backgroundColor: ThemeUtil.getPrimaryColor(),
      foregroundColor: Colors.white,
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              var inputLabelNameController = TextEditingController();
              String helperText = "";

              return StatefulBuilder(
                builder: (context, dialogState) => AlertDialog(
                  title: const Text("添加标签"),
                  content: TextField(
                    controller: inputLabelNameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "标签名称",
                      helperText: helperText,
                    ),
                    maxLength: labelMaxLength,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("取消")),
                    ElevatedButton(
                        onPressed: () async {
                          String labelName = inputLabelNameController.text;
                          // 禁止空
                          if (labelName.isEmpty) {
                            helperText = "不能添加空标签";
                            dialogState(() {});
                            return;
                          }

                          // 禁止重名
                          if (await LabelDao.existLabelName(labelName)) {
                            helperText = "已有该标签";
                            dialogState(() {});
                            return;
                          }

                          Label newLabel = Label(0, labelName);
                          int newId = await LabelDao.insert(newLabel);
                          if (newId > 0) {
                            Log.info("添加标签成功，新插入的id=$newId");
                            // 指定新id，并添加到controller中
                            newLabel.id = newId;
                            if (inputKeywordController.text.isEmpty) {
                              // 没在搜索，直接添加
                              labelsController.labels.add(newLabel);
                            } else {
                              // 如果在搜索后添加，则看是否存在关键字，如果有，则添加到labels里(此时controller里的labels存放的是搜索结果)
                              if (labelName
                                  .contains(inputKeywordController.text)) {
                                labelsController.labels.add(newLabel);
                              }
                            }
                            Navigator.of(context).pop();
                          } else {
                            Log.info("添加失败");
                          }
                        },
                        child: const Text("确定")),
                  ],
                ),
              );
            });
      },
      child: const Icon(Icons.add),
    );
  }

  _showDialogModifyLabel(
      BuildContext context, int index, LabelsController labelsController) {
    Label label = labelsController.labels[index];
    var inputLabelNameController = TextEditingController();
    inputLabelNameController.text = label.name;

    showDialog(
      context: context,
      builder: (context) {
        String helperText = "";

        return StatefulBuilder(
          builder: (context, dialogState) => AlertDialog(
            title: const Text("修改标签"),
            content: TextField(
              controller: inputLabelNameController..text,
              autofocus: true,
              maxLength: labelMaxLength,
              decoration: InputDecoration(
                labelText: "标签名称",
                helperText: helperText,
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("取消")),
              ElevatedButton(
                  onPressed: () async {
                    String newLabelName = inputLabelNameController.text;
                    // 禁止空
                    if (newLabelName.isEmpty) {
                      helperText = "不能添加空标签";
                      dialogState(() {});
                      return;
                    }

                    // 没有修改
                    if (label.name == newLabelName) {
                      Navigator.of(context).pop();
                      return;
                    }

                    // 禁止重名
                    if (await LabelDao.existLabelName(newLabelName)) {
                      helperText = "已有该标签";
                      dialogState(() {});
                      return;
                    }

                    int updateCnt =
                        await LabelDao.update(label.id, newLabelName);
                    if (updateCnt > 0) {
                      Log.info("修改标签成功");
                      // 修改controller里的该标签的名字
                      // labelsController.labels[index].name = newLabelName; // 无效
                      label.name = newLabelName;
                      labelsController.labels[index] = label; // 必须要重新赋值，才能看到变化
                      if (enableSelectLabelForAnime) {
                        int index = animeController!.labels
                            .indexWhere((element) => element.id == label.id);
                        // 如果动漫添加了该标签，则更新动漫里的这个标签
                        if (index >= 0) {
                          animeController!.labels[index] = label;
                        }
                      }
                      Navigator.of(context).pop();
                    } else {
                      Log.info("修改失败");
                    }
                  },
                  child: const Text("确定")),
            ],
          ),
        );
      },
    );
  }

  void _renewAllLabels(LabelsController labelsController) async {
    if (labelsController.kw.isNotEmpty) {
      // 之前搜索了关键字后，退出了该页面，那么重新进入该页面时，需要重新获取所有标签
      labelsController.kw = "";
      labelsController.labels.value = await LabelDao.getAllLabels();
    }
  }
}
