import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:oktoast/oktoast.dart';

class TagManage extends StatefulWidget {
  const TagManage({Key? key}) : super(key: key);

  @override
  _TagManageState createState() => _TagManageState();
}

// 在全局变量tags拖拽、修改、添加的基础上，改变数据库tag表信息
class _TagManageState extends State<TagManage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "标签管理",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      var inputTagNameController = TextEditingController();
                      return AlertDialog(
                        title: const Text("添加标签"),
                        content: TextField(
                          controller: inputTagNameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: "标签名称",
                            border: InputBorder.none,
                          ),
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
              icon: const Icon(Icons.add))
        ],
      ),
      body: ReorderableListView(
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
    );
  }

  _getDeleteButton(int i) {
    return IconButton(
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
          trailing: Platform.isWindows ? null : _getDeleteButton(i),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                var inputTagNameController = TextEditingController();
                return AlertDialog(
                  title: const Text("修改标签"),
                  content: TextField(
                    controller: inputTagNameController..text = tags[i],
                    autofocus: true,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: "标签名称",
                      border: InputBorder.none,
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
                          String newTagName = inputTagNameController.text;
                          if (newTagName.isEmpty) return;

                          // 重名
                          if (tags.contains(newTagName)) {
                            showToast("重名，无法修改！");
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
            title: const Text("删除标签"),
            content: Text("确认删除「$tagName」标签吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("取消")),
              ElevatedButton(
                  onPressed: () async {
                    if (await SqliteUtil.getAnimesCntBytagName(tagName) > 0) {
                      showToast("当前标签存在动漫，无法删除");
                    } else {
                      SqliteUtil.deleteTagByTagName(tagName);
                      tags.remove(tagName);
                      setState(() {});
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text("确认")),
            ],
          );
        });
  }
}
