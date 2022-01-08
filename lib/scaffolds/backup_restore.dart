import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:oktoast/oktoast.dart';
import 'dart:io';

import 'package:webdav_client/webdav_client.dart';

class BackupAndRestore extends StatefulWidget {
  const BackupAndRestore({Key? key}) : super(key: key);

  @override
  _BackupAndRestoreState createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<BackupAndRestore> {
  String autoBackupWebDav = SPUtil.getBool("auto_backup_webdav") ? "开启" : "关闭";
  String autoBackupLocal = SPUtil.getBool("auto_backup_local") ? "开启" : "关闭";
  late File latestFile;
  bool loadOk = false;

  @override
  void initState() {
    super.initState();
    // SPUtil.clear();
    _showLatestFile();
  }

  _showLatestFile() async {
    var files = await WebDavUtil.client.readDir("/animetrace");
    files.addAll(await WebDavUtil.client.readDir("/animetrace/automatic"));
    files.sort((a, b) {
      return a.mTime.toString().compareTo(b.mTime.toString());
    });
    latestFile = files.last;
    loadOk = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "备份还原",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          Platform.isWindows
              ? const ListTile(
                  title: Text(
                    "本地备份",
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              : Container(),
          Platform.isWindows
              ? ListTile(
                  title: const Text("点击进行备份"),
                  subtitle: const Text(""),
                  // subtitle: Text(getDuration()),
                  onTap: () {
                    BackupUtil.backup(
                        localBackupDirPath: SPUtil.getString("backup_local_dir",
                            defaultValue: "unset"));

                    // String dir = SPUtil.getString("backup_local_dir");
                    // String path;
                    // // 已设置路径，直接备份
                    // if (dir.isNotEmpty) {
                    //   // 不管是否都会先创建文件夹，确保存在，否则不能拷贝
                    //   await Directory(dir).create();
                    //   path = "$dir/animetrace_$time.db";
                    //   File(SqliteUtil.dbPath).copy(path);
                    //   showToast("备份成功");
                    // } else {
                    //   showToast("请先设置本地备份目录");
                    // }
                  },
                )
              : Container(),
          Platform.isWindows
              ? ListTile(
                  title: const Text("本地备份目录"),
                  subtitle: Text(SPUtil.getString("backup_local_dir")),
                  onTap: () async {
                    String? selectedDirectory = await selectDirectory();
                    if (selectedDirectory != null) {
                      SPUtil.setString("backup_local_dir", selectedDirectory);
                      setState(() {});
                    }
                  },
                )
              : Container(),
          Platform.isWindows
              ? ListTile(
                  title: const Text("自动备份"),
                  subtitle: const Text("每次进入应用后会自动备份"),
                  trailing: SPUtil.getBool("auto_backup_local")
                      ? const Icon(
                          Icons.toggle_on,
                          color: Colors.blue,
                        )
                      : const Icon(Icons.toggle_off),
                  onTap: () {
                    if (SPUtil.getString("backup_local_dir",
                            defaultValue: "unset") ==
                        "unset") {
                      showToast("请先设置本地备份目录，再进行备份！");
                      return;
                    }
                    if (SPUtil.getBool("auto_backup_local")) {
                      // 如果是开启，点击后则关闭
                      SPUtil.setBool("auto_backup_local", false);
                      autoBackupLocal = "关闭";
                      showToast("关闭自动备份");
                    } else {
                      SPUtil.setBool("auto_backup_local", true);
                      // 开启后先备份一次，防止因为用户没有点击过手动备份，而无法得到上一次备份时间，从而无法求出备份间隔
                      // WebDavUtil.backupData(true);
                      autoBackupLocal = "开启";
                      showToast("开启自动备份");
                    }
                    setState(() {});
                  },
                )
              : Container(),
          ListTile(
            title: const Text("还原本地备份"),
            subtitle: const Text("还原动漫记录"),
            onTap: () async {
              // 获取备份文件
              String? selectedFilePath = await selectFile();
              if (selectedFilePath != null) {
                BackupUtil.restoreFromLocal(selectedFilePath);
              }
            },
          ),
          const ListTile(
            title: Text(
              "WebDav 备份",
              style: TextStyle(color: Colors.blue),
            ),
          ),
          ListTile(
            title: const Text("账号配置"),
            trailing: Icon(
              Icons.circle,
              size: 12,
              color: SPUtil.getBool("login") ? Colors.greenAccent : Colors.grey,
            ),
            onTap: () {
              _loginWebDav();
            },
          ),
          ListTile(
            title: const Text("手动备份"),
            subtitle: const Text("单击进行备份，备份目录为 /animetrace"),
            onTap: () async {
              if (!SPUtil.getBool("login")) {
                showToast("请先配置账号，再进行备份！");
                return;
              }
              latestFile.path = await BackupUtil.backup(
                  remoteBackupDirPath: await WebDavUtil.getRemoteDirPath());
              setState(() {});
              // String remotePath = await WebDavUtil.backupData(false);
            },
          ),
          ListTile(
            title: const Text("自动备份"),
            subtitle: const Text("每次进入应用后会自动备份"),
            trailing: SPUtil.getBool("auto_backup_webdav")
                ? const Icon(
                    Icons.toggle_on,
                    color: Colors.blue,
                  )
                : const Icon(Icons.toggle_off),
            onTap: () async {
              if (!SPUtil.getBool("login")) {
                showToast("请先配置账号，再进行备份！");
                return;
              }
              if (SPUtil.getBool("auto_backup_webdav")) {
                // 如果是开启，点击后则关闭
                SPUtil.setBool("auto_backup_webdav", false);
                autoBackupWebDav = "关闭";
                showToast("关闭自动备份");
              } else {
                SPUtil.setBool("auto_backup_webdav", true);
                // 开启后先备份一次，防止因为用户没有点击过手动备份，而无法得到上一次备份时间，从而无法求出备份间隔
                // WebDavUtil.backupData(true);
                autoBackupWebDav = "开启";
                showToast("开启自动备份");
              }
              setState(() {});
            },
          ),
          ListTile(
            title: const Text("还原最新数据"),
            subtitle: loadOk
                ? Text(latestFile.path!.split("/").last)
                : const Text(""),
            onTap: () async {
              if (SPUtil.getBool("login")) {
                BackupUtil.restoreFromWebDav(latestFile);
              } else {
                showToast("配置账号后才可以进行还原");
              }
            },
          ),
        ],
      ),
    );
  }

  void _loginWebDav() {
    var inputUriController = TextEditingController();
    var inputUserController = TextEditingController();
    var inputPasswordController = TextEditingController();
    List<TextEditingController> controllers = [];
    controllers.addAll(
        [inputUriController, inputUserController, inputPasswordController]);
    List<String> keys = ["webdav_uri", "webdav_user", "webdav_password"];
    List<String> labelTexts = ["服务器地址", "账号", "密码"];
    List<Widget> listTextFields = [];
    for (int i = 0; i < keys.length; ++i) {
      listTextFields.add(
        TextField(
          obscureText: labelTexts[i] == "密码"
              ? true
              : false, // true会隐藏输入内容，没使用主要是因为开启后不能直接粘贴密码了，
          controller: controllers[i]
            ..text = SPUtil.getString(keys[i], defaultValue: ""),
          decoration: InputDecoration(
            labelText: labelTexts[i],
            border: InputBorder.none,
          ),
        ),
      );
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("账号配置"),
          content: SingleChildScrollView(
            child: Column(
              children: listTextFields,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("取消")),
            TextButton(
                onPressed: () async {
                  String uri = inputUriController.text;
                  String user = inputUserController.text;
                  String password = inputPasswordController.text;
                  if (uri.isEmpty || user.isEmpty || password.isEmpty) {
                    showToast("请将信息填入完整！");
                    return;
                  }
                  SPUtil.setString("webdav_uri", uri);
                  SPUtil.setString("webdav_user", user);
                  SPUtil.setString("webdav_password", password);
                  if (!(await WebDavUtil.initWebDav(uri, user, password))) {
                    showToast("无法连接，请确认是否输入正确！");
                    // 连接正确后，修改账号后连接失败，需要重新更新显示状态。init里的ping会通过SPUtil记录状态
                    setState(() {});
                    return;
                  }
                  showToast("连接成功！");
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: const Text("确认"))
          ],
        );
      },
    );
  }
}
