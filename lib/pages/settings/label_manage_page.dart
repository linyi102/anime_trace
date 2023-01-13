import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/dao/label_dao.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';

import '../../utils/theme_util.dart';

class LabelManagePage extends StatelessWidget {
  // 必须是const，外部创建时也要加上const，否则会多次build
  const LabelManagePage({this.animeId = 0, Key? key}) : super(key: key);

  // 在动漫详细页点击添加标签按钮，会传入动漫id，此时点击标签会进行添加
  final int animeId;

  bool get enableSelectLabelForAnime => animeId > 0;

  static const int labelMaxLength = 30;

  @override
  Widget build(BuildContext context) {
    Log.info("$runtimeType: build");
    LabelsController labelsController = Get.find();

    _renewAllLabels(labelsController);

    return Scaffold(
      appBar: AppBar(
        title: Text(enableSelectLabelForAnime ? "选择标签" : "标签管理",
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      // 如果没有标签，那么就单独显示输入框(因为可能是搜索关键字后，没有相关的标签)
      // 如果有标签，则放到第0个上面，这样就能保证仍然可以懒加载
      // BUG：因为会重新构建搜索栏，所以聚焦会失效(表现是输着输着不能输了，因为查询结果为空，会重新构建搜索栏)
      // 所以暂时放弃懒加载，后期改用sliverlist
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
        children: [
          _buildSearchBar(labelsController),
          const SizedBox(height: 20),
          Obx(() => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: labelsController.labels.reversed.map((label) {
                bool selected = labelsController.labelsInAnimeDetail
                        .indexWhere((element) => element.id == label.id) >
                    -1;

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
                            animeId, label.id)) {
                          Log.info(
                              "移除动漫标签记录成功(animeId=$animeId, labelId=${label.id})");
                          // 从controller中移除
                          labelsController.labelsInAnimeDetail
                              .removeWhere((element) => element.id == label.id);
                        } else {
                          Log.info("移除动漫标签记录失败");
                        }
                      } else {
                        // 为这个动漫添加该标签
                        int newId = await AnimeLabelDao.insertAnimeLabel(
                            animeId, label.id);
                        if (newId > 0) {
                          Log.info("添加新动漫标签纪录成功：$newId");
                          // 添加到controller
                          labelsController.labelsInAnimeDetail.add(label);
                        } else {
                          Log.info("添加新动漫标签纪录失败");
                        }
                      }
                    }
                  },
                  onLongPress: () {
                    // 弹出对话框，提供重命名和删除操作
                    showDialog(
                        context: context,
                        builder: (context) => SimpleDialog(
                              children: [
                                SimpleDialogOption(
                                  child: const Text("重命名"),
                                  onPressed: () {
                                    Log.info("重命名标签：$label");
                                    Navigator.of(context).pop();

                                    int index = labelsController.labels
                                        .indexWhere(
                                            (element) => element == label);
                                    _showDialogModifyLabel(
                                        context, index, labelsController);
                                  },
                                ),
                                SimpleDialogOption(
                                  child: const Text("删除"),
                                  onPressed: () {
                                    Log.info("删除标签：$label");
                                    Navigator.of(context).pop();

                                    int index = labelsController.labels
                                        .indexWhere(
                                            (element) => element == label);

                                    _showDeleteDialog(context, label,
                                        labelsController, index);
                                  },
                                )
                              ],
                            ));
                  },
                );
              }).toList())),
          // 底部空白，避免加号悬浮按钮遮挡删除按钮
          const ListTile(),
          const ListTile(),
        ],
      ),
      floatingActionButton:
          _buildFloatingActionButton(context, labelsController),
    );
  }

  _buildSearchBar(LabelsController labelsController) {
    Log.info("_buildSearchBar");
    var inputKeywordController = TextEditingController();

    return TextField(
      controller: inputKeywordController..text = labelsController.kw,
      decoration: const InputDecoration(
        hintText: "搜索标签",
        prefixIcon: Icon(Icons.search),
        // isDense: true,
        // border: OutlineInputBorder(
        //     borderSide: const BorderSide(width: 2),
        //     borderRadius: BorderRadius.circular(50)),
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

  _showDeleteDialog(BuildContext context, Label label,
      LabelsController labelsController, int index) {
    return showDialog(
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
                        labelsController.labelsInAnimeDetail
                            .removeWhere((element) => element.id == label.id);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text("确定")),
              ],
            ));
  }

  _buildFloatingActionButton(
      BuildContext context, LabelsController labelsController) {
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
                            labelsController.labels.add(newLabel);
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
                        // 更新动漫详细页中的标签
                        int index = labelsController.labelsInAnimeDetail
                            .indexWhere((element) => element.id == label.id);
                        labelsController.labelsInAnimeDetail[index] = label;
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
