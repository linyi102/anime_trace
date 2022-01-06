import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:oktoast/oktoast.dart';
import 'dart:io';

class BackupAndRestore extends StatefulWidget {
  const BackupAndRestore({Key? key}) : super(key: key);

  @override
  _BackupAndRestoreState createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<BackupAndRestore> {
  String autoBackupWebDav = SPUtil.getBool("auto_backup_webdav") ? "开启" : "关闭";
  String autoBackupLocal = SPUtil.getBool("auto_backup_local") ? "开启" : "关闭";

  @override
  void initState() {
    super.initState();
    // SPUtil.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "备份与还原",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("还原备份"),
            subtitle: const Text("还原动漫记录"),
            onTap: () async {
              // 获取备份文件
              String? selectedFilePath = await selectFile();
              if (selectedFilePath != null) {
                if (selectedFilePath.endsWith(".zip")) {
                  // 如果是压缩包，则使用restore函数还原
                  BackupUtil.restore(localZipPath: selectedFilePath);
                  showToast("还原成功");
                } else if ((selectedFilePath.endsWith(".db"))) {
                  // 对于手机：将该文件拷贝到新路径SqliteUtil.dbPath下，可以直接拷贝
                  // await File(selectedFilePath).copy(SqliteUtil.dbPath);
                  // window需要手动代码删除，否则：(OS Error: 当文件已存在时，无法创建该文件。
                  // 然而并不能删除：(OS Error: 另一个程序正在使用此文件，进程无法访问。
                  // await File(SqliteUtil.dbPath).delete();
                  // 可以直接在里面写入即可，writeAsBytes会清空原先内容
                  var content = await File(selectedFilePath).readAsBytes();
                  await File(SqliteUtil.dbPath).writeAsBytes(content);
                  showToast("还原成功");
                } else {
                  showToast("还原文件必须以.zip或.db结尾");
                }
              }
            },
          ),

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
                    // DateTime dateTime = DateTime.now();
                    // String time =
                    //     "${dateTime.year}-${dateTime.month}-${dateTime.day}_${dateTime.hour}-${dateTime.minute}-${dateTime.second}";
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
          // 注意！！！！！share插件window会打不开应用
          // Platform.isAndroid
          //     ? ListTile(
          //         title: const Text("发送数据"),
          //         subtitle: const Text("发送动漫记录文件"),
          //         // subtitle: Text(getDuration()),
          //         onTap: () async {
          //           // 名字太长会导致备份不到坚果云
          //           DateTime dateTime = DateTime.now();
          //           String time =
          //               "${dateTime.year}-${dateTime.month}-${dateTime.day}_${dateTime.hour}-${dateTime.minute}-${dateTime.second}";
          //           String? dir = await selectDirectory();
          //           if (dir != null) {
          //             String path = "$dir/animetrace_$time.db";
          //             File(SqliteUtil.dbPath).copy(path);
          //           }
          //           // 点击分享弹出界面后，就会返回Future<void>，而即使删除文件也能发送，因此不用担心
          //           // final sharedFilePath =
          //           //     "${(await get())!.path}/animetrace_$time.db";
          //           // final sharedFilePath =
          //           //     "${(await getExternalStorageDirectory())!.path}/animetrace_$time.db";
          //           // // 拷贝一份
          //           // File sharedFile =
          //           //     await File(SqliteUtil.dbPath).copy(sharedFilePath);
          //           // // 点击分享弹出界面后，就会返回Future<void>，而即使删除文件也能发送，因此不用担心
          //           // // await Share.shareFiles([sharedFilePath]);
          //           // sharedFile.delete();
          //           // SPUtil.setString("lastSharedTime", dateTime.toString());
          //           // // setState(() {});
          //           // // showToast("分享成功"); // 找不到合适的时间
          //         },
          //       )
          //     : Container(),

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
              _loginWebDav(context);
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
              BackupUtil.backup(
                  remoteBackupDirPath: await WebDavUtil.getRemoteDirPath());
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
        ],
      ),
    );
  }

  void _loginWebDav(context) {
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
          // obscureText: labelTexts[i] == "密码" ? true : false, // true会隐藏输入内容，没使用主要是因为开启后不能直接粘贴密码了，
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
