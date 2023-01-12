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
  LabelManagePage({this.selectLabel = false, this.animeId = 0, Key? key})
      : super(key: key);
  static const int labelMaxLength = 30;

  // 在动漫详细页点击添加标签按钮，会传入select(true)和已添加的标签列表，此时点击标签会进行添加
  final bool selectLabel;
  final int animeId;

  LabelsController labelsController = Get.find();
  final inputKeywordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Log.info("$runtimeType: build");
    _renewAllLabels();

    return Scaffold(
      appBar: selectLabel
          ? null
          : AppBar(
              title: const Text("标签管理",
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
      // 如果没有标签，那么就单独显示输入框(因为可能是搜索关键字后，没有相关的标签)
      // 如果有标签，则放到第0个上面，这样就能保证仍然可以懒加载
      // BUG：因为会重新构建搜索栏，所以聚焦会失效(表现是输着输着不能输了，因为查询结果为空，会重新构建搜索栏)
      // 所以暂时放弃懒加载，后期改用sliverlist
      body: ListView(
        children: [
          _buildSearchBar(),
          Obx(() => ListView.builder(
              // reverse: true, // 倒序显示，保证新添加的在前
              // shrinkWrap: true, // 保证当数量不足以填满屏幕时，顶部不会有空白。bug：刚进入页面，会自动滚动到底部
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: labelsController.labels.length,
              itemBuilder: (context, index) {
                Log.info("index=$index");
                Label label = labelsController.labels[index];
                return _buildLabelListTile(context, label, index);
              })),
          // 底部空白，避免加号悬浮按钮遮挡删除按钮
          const ListTile(),
          const ListTile(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  _buildSearchBar() {
    Log.info("_buildSearchBar");
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: TextField(
        controller: inputKeywordController..text = labelsController.kw,
        decoration: const InputDecoration(
            hintText: "搜索标签", suffixIcon: Icon(Icons.search)),
        onChanged: (kw) async {
          Log.info("搜索标签关键字：$kw");
          // 必须要查询数据库，而不是从已查询的全部数据中删除不含关键字的记录，否则会越删越少
          labelsController.labels.value = await LabelDao.searchLabel(kw);
          labelsController.kw = kw; // 记录关键字
        },
      ),
    );
  }

  ListTile _buildLabelListTile(BuildContext context, Label label, int index) {
    return ListTile(
      title: Text(label.name),
      leading: selectLabel ? _buildCheckbox(label) : null,
      onTap: () {
        Log.info("修改标签");
        _showDialogModifyLabel(context, index);
      },
      trailing: _buildDeleteButton(context, label, index),
    );
  }

  _buildCheckbox(Label label) {
    // 必须再次使用obx，否则无法看到check实时变化
    // 猜测：最外层obx监听的是labelsController.labels，和这个无关
    return Obx(() => labelsController.labelsInAnimeDetail
                .indexWhere((element) => element.id == label.id) >
            -1
        ? IconButton(
            onPressed: () async {
              // 为这个动漫移除该标签
              if (await AnimeLabelDao.deleteAnimeLabel(animeId, label.id)) {
                Log.info("移除动漫标签记录成功(animeId=$animeId, labelId=${label.id})");
                // 从controller中移除
                labelsController.labelsInAnimeDetail
                    .removeWhere((element) => element.id == label.id);
              } else {
                Log.info("移除动漫标签记录失败");
              }
            },
            icon: const Icon(EvaIcons.checkmarkSquare),
            color: ThemeUtil.getPrimaryIconColor())
        : IconButton(
            onPressed: () async {
              // 为这个动漫添加该标签
              int newId =
                  await AnimeLabelDao.insertAnimeLabel(animeId, label.id);
              if (newId > 0) {
                Log.info("添加新动漫标签纪录成功：$newId");
                // 添加到controller
                labelsController.labelsInAnimeDetail.add(label);
              } else {
                Log.info("添加新动漫标签纪录失败");
              }
            },
            icon: const Icon(EvaIcons.squareOutline)));
  }

  IconButton _buildDeleteButton(BuildContext context, Label label, int index) {
    return IconButton(
      onPressed: () {
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
                          if (selectLabel) {
                            labelsController.labelsInAnimeDetail.removeWhere(
                                (element) => element.id == label.id);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text("确定")),
                  ],
                ));
      },
      icon: const Icon(Icons.delete_forever),
    );
  }

  _buildFloatingActionButton(BuildContext context) {
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

  _showDialogModifyLabel(BuildContext context, int index) {
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

                    int newId = await LabelDao.update(label.id, newLabelName);
                    if (newId > 0) {
                      Log.info("修改标签成功");
                      // 修改controller里的该标签的名字
                      // labelsController.labels[index].name = newLabelName; // 无效
                      label.name = newLabelName;
                      labelsController.labels[index] = label; // 必须要重新赋值，才能看到变化
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

  void _renewAllLabels() async {
    if (labelsController.kw.isNotEmpty) {
      // 之前搜索了关键字后，退出了该页面，那么重新进入该页面时，需要重新获取所有标签
      labelsController.kw = "";
      labelsController.labels.value = await LabelDao.getAllLabels();
    }
  }
}
