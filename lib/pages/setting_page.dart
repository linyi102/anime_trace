import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/scaffolds/tag_manage.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ListTile(
            title: const Text("创建备份"),
            onTap: () async {
              // 首先判断备份目录是否存在
              String backupDir = SPUtil.getString("backup_path");
              if (!(await Directory(backupDir).exists())) {
                showToast("备份之前请先设置备份目录！");
                return;
              }
              // 拷贝数据库文件到备份目录下
              // final backupFilePath =
              //     "${(await getExternalStorageDirectory())!.path}/anime_trace_${DateTime.now()}.db";
              final backupFilePath =
                  "$backupDir/anime_trace_${DateTime.now()}.db";
              // final backupFilePath =
              //     "/storage/emulated/0/Download/anime_trace_${DateTime.now().toString().split(".")[0]}.db";
              File result = await File(SqliteUtil.dbPath).copy(backupFilePath);
              if (await result.exists()) {
                showToast("备份成功");
              } else {
                showToast("备份失败");
              }
            },
          ),
          ListTile(
            title: const Text("还原备份"),
            onTap: () async {
              // 获取备份文件
              String? selectedFilePath = await selectFile();
              if (selectedFilePath != null) {
                // 将该文件拷贝到新路径SqliteUtil.dbPath下，此时会先删除原数据库文件，然后再拷贝
                // 注：点击时，手机会弹出提示：读取设备上的照片及文件。不用在src\main\AndroidManifest.xml读权限也可以
                await File(selectedFilePath).copy(SqliteUtil.dbPath);
                showToast("还原成功");
              }
            },
          ),
          ListTile(
            title: const Text("分享数据"),
            onTap: () {
              Share.shareFiles([SqliteUtil.dbPath], subject: "132");
            },
          ),
          ListTile(
            title: const Text("备份路径"),
            subtitle: Text(SPUtil.getString("backup_path")),
            onTap: () async {
              String? selectedDirectory = await selectDirectory();
              if (selectedDirectory != null) {
                SPUtil.setString("backup_path", selectedDirectory);
                setState(() {});
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.new_label_outlined,
              color: Colors.blue,
            ),
            title: const Text("标签管理"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => const TagManage()));
            },
          )
        ],
      ),
    );
  }
}
