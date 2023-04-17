import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/file_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class RBRPage extends StatefulWidget {
  const RBRPage({super.key});

  @override
  State<RBRPage> createState() => _RBRPageState();
}

class _RBRPageState extends State<RBRPage> {
  List<File> files = [];
  bool loadOk = false;
  final scrollController = ScrollController();

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("还原前记录 (${files.length})"),
        automaticallyImplyLeading: false,
      ),
      body: FadeAnimatedSwitcher(
        loadOk: loadOk,
        destWidget:
            files.isEmpty ? emptyDataHint(msg: "没有数据。") : _buildListView(),
      ),
    );
  }

  _buildListView() {
    return Scrollbar(
      controller: scrollController,
      child: ListView.builder(
        controller: scrollController,
        itemCount: files.length,
        itemBuilder: (context, index) {
          var file = files[index];
          var stat = file.statSync();
          String name = file.path.substring(file.path.lastIndexOf("record-"));

          return ListTile(
            title: Text("${index + 1}. $name"),
            subtitle: Text(FileUtil.getFileSizeString(bytes: stat.size)),
            onTap: () => _showDialogConfirmRestore(context, file),
            onLongPress: () => _showDialogOperation(context, file),
          );
        },
      ),
    );
  }

  _showDialogOperation(BuildContext context, File file) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text("恢复"),
            onTap: () {
              Navigator.pop(context);
              _showDialogConfirmRestore(context, file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text("删除"),
            onTap: () {
              Navigator.pop(context);
              _showDialogDelete(context, file);
            },
          ),
        ],
      ),
    );
  }

  _showDialogDelete(BuildContext context, File file) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确定删除吗？"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                files.remove(file);
                file.delete();
                setState(() {});
              },
              child: Text(
                "确定",
                style: TextStyle(color: Theme.of(context).errorColor),
              )),
        ],
      ),
    );
  }

  _showDialogConfirmRestore(BuildContext context, File file) {
    bool recordBeforeRestore = true;

    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("恢复"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("确定要恢复吗？"),
                    StatefulBuilder(
                      builder: (context, setState) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text("恢复前记录当前数据到此处"),
                        value: recordBeforeRestore,
                        onChanged: (value) {
                          setState(() {
                            recordBeforeRestore = value;
                          });
                        },
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("取消")),
                TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // 等待提示对话框关闭后再恢复，避免卡顿
                      // await Future.delayed(const Duration(milliseconds: 200));

                      ToastUtil.showLoading(
                        msg: "正在还原数据",
                        task: () {
                          //  还原
                          return BackupUtil.restoreFromLocal(
                            file.path,
                            recordBeforeRestore: recordBeforeRestore,
                          );
                        },
                        onTaskComplete: (taskValue) {
                          taskValue as Result;
                          ToastUtil.showText(taskValue.msg);
                          ChecklistController.to.restore();

                          if (recordBeforeRestore) {
                            // 重新获取所有记录文件
                            loadData();
                          }
                        },
                      );
                    },
                    child: const Text("确定")),
              ],
            ));
  }

  void loadData() async {
    files.clear();

    String dir = await BackupUtil.getRBRPath();
    var stream = Directory(dir).list();
    await for (var fse in stream) {
      files.add(File(fse.path));
    }
    files.sort((a, b) => -a.path.compareTo(b.path));
    loadOk = true;
    setState(() {});
  }
}
