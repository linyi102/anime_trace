import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:webdav_client/webdav_client.dart';

class BackUpFileList extends StatefulWidget {
  const BackUpFileList({Key? key}) : super(key: key);

  @override
  State<BackUpFileList> createState() => _BackUpFileListState();
}

class _BackUpFileListState extends State<BackUpFileList> {
  List<File> files = [];

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "备份文件列表",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: files.isEmpty ? Container() : _buildFileList());
  }

  _buildFileList() {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text("${index + 1}: ${files[index].path!.split("/").last}"),
          subtitle: Text("${files[index].mTime}"),
          onTap: () {
            BackupUtil.restoreFromWebDav(files[index]);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
