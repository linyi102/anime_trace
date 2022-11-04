import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:webdav_client/webdav_client.dart';

class BackUpFileList extends StatefulWidget {
  const BackUpFileList({Key? key}) : super(key: key);

  @override
  State<BackUpFileList> createState() => _BackUpFileListState();
}

class _BackUpFileListState extends State<BackUpFileList> {
  List<File> files = [];
  bool loadOk = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    debugPrint("获取备份文件ing...");
    files.addAll(await WebDavUtil.client.readDir("/animetrace"));
    files.addAll(await WebDavUtil.client.readDir("/animetrace/automatic"));
    // 去除目录
    for (var i = 0; i < files.length; i++) {
      if (files[i].isDir ?? false) files.removeAt(i);
    }
    debugPrint("获取完毕，共${files.length}个文件");
    files.sort((a, b) {
      return b.mTime.toString().compareTo(a.mTime.toString());
    });
    loadOk = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "备份文件列表 (${files.length})",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: FadeAnimatedSwitcher(
          loadOk: loadOk,
          destWidget: _buildFileList(),
          specifiedLoadingWidget:
              const Center(child: RefreshProgressIndicator()),
        ));
  }

  _buildFileList() {
    if (files.isEmpty) return emptyDataHint("没有找到备份文件");
    return Scrollbar(
      child: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          String fileName = "";
          File file = files[index];
          // 获取文件名
          if (file.path != null) {
            fileName = file.path!.split("/").last;
          }
          // 去除秒后面的.000
          String createdTime = file.mTime.toString().split(".")[0];

          // KB
          // ignore: non_constant_identifier_names
          num KBSize = (file.size ?? 0) / 1024;
          String backupWay = file.path!.contains("automatic") ? "自动备份" : "手动备份";

          return ListTile(
            title: Text("[${index + 1}]. $fileName"),
            subtitle: Text(
                "$createdTime ${KBSize.toStringAsFixed(3)}KB $backupWay"), // 保留3位小数
            trailing: IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text("确认删除该备份吗？"),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                child: const Text("取消")),
                            ElevatedButton(
                                onPressed: () {
                                  if (file.path != null) {
                                    BackupUtil.deleteRemoteFile(file.path!);
                                  }
                                  Navigator.of(dialogContext).pop();
                                  // 从列表中删除
                                  files.removeAt(index);
                                  setState(() {});
                                },
                                child: const Text("确认")),
                          ],
                        );
                      });
                },
                icon: const Icon(Icons.delete_outline)),
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text("还原数据"),
                    content: const Text("这会覆盖已有的数据\n确认还原指定文件吗？"),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text("取消")),
                      ElevatedButton(
                          onPressed: () {
                            showToast("还原数据中...");
                            BackupUtil.restoreFromWebDav(file);
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text("确认")),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
