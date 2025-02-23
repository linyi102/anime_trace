import 'package:flutter/material.dart';
import 'package:animetrace/animation/fade_animated_switcher.dart';
import 'package:animetrace/components/empty_data_hint.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/models/params/result.dart';
import 'package:animetrace/pages/anime_collection/checklist_controller.dart';
import 'package:animetrace/utils/backup_util.dart';
import 'package:animetrace/utils/file_util.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:webdav_client/webdav_client.dart';
import 'package:animetrace/utils/log.dart';

class BackUpFileListPage extends StatefulWidget {
  const BackUpFileListPage({Key? key}) : super(key: key);

  @override
  State<BackUpFileListPage> createState() => _BackUpFileListPageState();
}

class _BackUpFileListPageState extends State<BackUpFileListPage> {
  List<File> files = [];
  bool _loadOk = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _initData() async {
    Log.info("获取备份文件中");
    files = await BackupUtil.getAllBackupFiles();
    _loadOk = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("远程备份 (${files.length})"),
        ),
        body: FadeAnimatedSwitcher(
          loadOk: _loadOk,
          destWidget: _buildFileList(),
          specifiedLoadingWidget: const LoadingWidget(center: true),
        ));
  }

  _buildFileList() {
    if (files.isEmpty) return emptyDataHint(msg: "没有备份。");
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: files.length,
        itemBuilder: (context, index) {
          return _buildFileItem(context, index);
        },
      ),
    );
  }

  _buildFileItem(BuildContext context, int index) {
    // Log.info("index=$index");
    String fileName = "";
    File file = files[index];
    // 获取文件名
    if (file.path != null) {
      fileName = file.path!.split("/").last;
    }

    // KB
    // ignore: non_constant_identifier_names
    String KBSize = FileUtil.getReadableFileSize(file.size ?? 0);
    String backupWay = file.path!.contains("automatic") ? "自动备份" : "手动备份";

    return ListTile(
      title: Text("${index + 1}. $fileName"),
      subtitle:
          Text("${file.mTime == null ? '' : TimeUtil.getTimeAgo(file.mTime!)} "
              "$KBSize $backupWay"),
      onTap: () => _showRestoreDialog(context, file),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            children: [
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text("还原"),
                onTap: () {
                  Navigator.pop(context);
                  _showRestoreDialog(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("删除"),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, file, index);
                },
              )
            ],
          ),
        );
      },
    );
  }

  Future<dynamic> _showDeleteDialog(
      BuildContext context, File file, int index) {
    return showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("删除"),
            content: const Text("确定删除该备份吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("取消")),
              TextButton(
                  onPressed: () {
                    if (file.path != null) {
                      BackupUtil.deleteRemoteFile(file.path!);
                    }
                    Navigator.of(dialogContext).pop();
                    // 从列表中删除
                    files.removeAt(index);
                    setState(() {});
                  },
                  child: Text(
                    "删除",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  )),
            ],
          );
        });
  }

  _showRestoreDialog(BuildContext context, File file) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("还原"),
          content: const Text("这会覆盖已有的数据，确定还原吗？"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("取消")),
            TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // 开始还原
                  ToastUtil.showLoading(
                    msg: "还原数据中",
                    task: () {
                      return BackupUtil.restoreFromWebDav(file);
                    },
                    onTaskComplete: (taskValue) {
                      taskValue as Result;
                      ToastUtil.showText(taskValue.msg);
                      // 重新获取动漫
                      ChecklistController.to.restore();
                    },
                  );
                },
                child: const Text("确定")),
          ],
        );
      },
    );
  }
}
