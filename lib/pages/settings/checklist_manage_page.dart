import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_app_bar.dart';
import 'package:flutter_test_future/components/my_icon_button.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

class ChecklistManagePage extends StatefulWidget {
  const ChecklistManagePage({Key? key}) : super(key: key);

  @override
  _ChecklistManagePageState createState() => _ChecklistManagePageState();
}

// 在全局变量tags拖拽、修改、添加的基础上，改变数据库tag表信息
class _ChecklistManagePageState extends State<ChecklistManagePage> {
  // 来自ReorderableListView里的默认proxyDecorator
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          color: ThemeUtil.getCardColor(), // 改变颜色
          elevation: elevation,
          child: child,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        caption: "清单管理",
      ),
      body: ReorderableListView(
        proxyDecorator: _proxyDecorator,
        children: _getTagListWidget(),
        onReorder: (int oldIndex, int newIndex) async {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var child = tags.removeAt(oldIndex);
          tags.insert(newIndex, child);
          SqliteUtil.updateTagOrder(tags);
          setState(() {});
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeUtil.getPrimaryColor(),
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                var inputTagNameController = TextEditingController();
                return AlertDialog(
                  title: const Text("添加清单"),
                  content: TextField(
                    controller: inputTagNameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: "清单名称"),
                    maxLength: 10,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("取消")),
                    ElevatedButton(
                        onPressed: () async {
                          String tagName = inputTagNameController.text;
                          if (tagName.isEmpty) return;

                          // 重名
                          if (tags.contains(tagName)) {
                            showToast("重名，无法添加！");
                            return;
                          }
                          SqliteUtil.insertTagName(tagName, tags.length);
                          // 更新tag表后，不需要重新全部获取，只需要在全局变量中添加即可
                          // tags = await SqliteUtil.getAllTags();
                          tags.add(tagName);
                          setState(() {}); // FutureBuilder会重新build
                          Navigator.of(context).pop();
                        },
                        child: const Text("确认")),
                  ],
                );
              });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  _getDeleteButton(int i) {
    return MyIconButton(
        onPressed: () {
          _dialogDeleteTag(i + 1, tags[i]);
        },
        icon: const Icon(Icons.delete_outline));
  }

  _getTagListWidget() {
    List<Widget> tagListWidget = [];
    for (int i = 0; i < tags.length; ++i) {
      tagListWidget.add(
        ListTile(
          key: ValueKey(i),
          title: Text(tags[i]),
          // win端会默认提供拖拽按钮在trailing，所以把删除按钮移到leading
          leading: Platform.isWindows
              ? _getDeleteButton(i)
              : const Icon(Icons.drag_handle),
          // : const Icon(Icons.list),
          trailing: Platform.isWindows ? null : _getDeleteButton(i),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                var inputTagNameController = TextEditingController();
                return AlertDialog(
                  title: const Text("修改清单"),
                  content: TextField(
                    controller: inputTagNameController..text = tags[i],
                    autofocus: true,
                    maxLength: 10,
                    decoration: const InputDecoration(labelText: "清单名称"),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("取消")),
                    ElevatedButton(
                        onPressed: () async {
                          String newTagName = inputTagNameController.text;
                          if (newTagName.isEmpty) return;

                          // 重名
                          if (tags.contains(newTagName)) {
                            showToast("已存在该清单，无法修改！");
                            return;
                          }
                          SqliteUtil.updateTagName(tags[i], newTagName);
                          // 更新tag表后，不需要重新全部获取，只需要修改全局变量即可
                          // tags = await SqliteUtil.getAllTags();
                          tags[i] = newTagName;
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                        child: const Text("确认")),
                  ],
                );
              },
            );
          },
        ),
      );
    }
    return tagListWidget;
  }

  _dialogDeleteTag(int tagId, String tagName) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("确认删除吗？"),
            content: Text("将要删除的清单：$tagName"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("取消")),
              TextButton(
                  onPressed: () async {
                    if (await SqliteUtil.getAnimesCntBytagName(tagName) > 0) {
                      showToast("当前清单存在动漫，无法删除");
                    } else {
                      SqliteUtil.deleteTagByTagName(tagName);
                      tags.remove(tagName);
                      setState(() {});
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "删除",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }
}
