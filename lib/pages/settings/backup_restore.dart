import 'dart:async';
import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';

import 'package:flutter_test_future/pages/settings/backup_file_list.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

import '../../components/loading_dialog.dart';
import '../../dao/anime_dao.dart';
import '../../models/params/result.dart';
import '../../utils/file_util.dart';
import '../../utils/log.dart';
import '../../utils/sqlite_util.dart';

class BackupAndRestorePage extends StatefulWidget {
  const BackupAndRestorePage({Key? key}) : super(key: key);

  @override
  _BackupAndRestorePageState createState() => _BackupAndRestorePageState();
}

class _BackupAndRestorePageState extends State<BackupAndRestorePage> {
  String autoBackupWebDav = SPUtil.getBool("auto_backup_webdav") ? "开启" : "关闭";
  String autoBackupLocal = SPUtil.getBool("auto_backup_local") ? "开启" : "关闭";
  int autoBackupWebDavNumber =
      SPUtil.getInt("autoBackupWebDavNumber", defaultValue: 20);
  int autoBackupLocalNumber =
      SPUtil.getInt("autoBackupLocalNumber", defaultValue: 20);
  bool loadOk = false;
  bool canManualBackup = true;

  @override
  void initState() {
    super.initState();
    // SPUtil.clear();
    // 获取最新情况，更新SP中的online
    WebDavUtil.pingWebDav().then((pingOk) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("备份还原"),
      ),
      body: ListView(
        children: [
          _buildClearAnimeDescTile(),
          const Divider(),
          _buildLocalBackup(),
          const Divider(),
          _buildRemoteBackUp(),
        ],
      ),
    );
  }

  ListTile _buildClearAnimeDescTile() {
    File dbFile = File(SqliteUtil.dbPath);

    return ListTile(
      title: const Text("减小数据文件"),
      subtitle:
          Text("当前大小：${FileUtil.getReadableFileSize(dbFile.lengthSync())}"),
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("确定这么做吗？"),
                content: const Text("这会清除已收藏动漫的简介信息！"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);

                        int oldSize = dbFile.lengthSync();
                        AnimeDao.clearAllAnimeDesc().then((value) {
                          setState(() {});
                          int newSize = dbFile.lengthSync();
                          Log.info("$oldSize->$newSize");
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text("清空完毕"),
                                    content: Text(
                                        "清空前大小：${FileUtil.getReadableFileSize(oldSize)}\n"
                                        "清空后大小：${FileUtil.getReadableFileSize(newSize)}\n"
                                        "节省了${FileUtil.getReadableFileSize(oldSize - newSize)}"),
                                  ));
                        });
                      },
                      child: const Text("确定")),
                ],
              );
            });
      },
    );
  }

  _buildRemoteBackUp() {
    return Column(
      children: [
        ListTile(
          title: Text("WebDav备份",
              style: TextStyle(color: Theme.of(context).primaryColor)),
          // trailing: IconButton(onPressed: () {}, icon: Icon(Icons.)),
          subtitle: const Text("点击查看教程"),
          onTap: () {
            LaunchUrlUtil.launch(
                context: context,
                uriStr: "https://help.jianguoyun.com/?p=2064");
          },
        ),
        ListTile(
          title: const Text("账号配置"),
          trailing: Icon(
            Icons.circle,
            size: 12,
            color: SPUtil.getBool("online")
                ? AppTheme.connectableColor
                : Colors.grey,
          ),
          onTap: () {
            _loginWebDav();
          },
        ),
        ListTile(
          title: const Text("立即备份"),
          subtitle: const Text("单击进行备份，备份目录为 /animetrace"),
          onTap: () async {
            if (!SPUtil.getBool("login")) {
              ToastUtil.showText("请先配置账号，再进行备份！");
              return;
            }

            if (!canManualBackup) {
              ToastUtil.showText("备份间隔为10s");
              return;
            }

            canManualBackup = false;
            Future.delayed(const Duration(seconds: 10))
                .then((value) => canManualBackup = true);

            ToastUtil.showText("正在备份");
            String remoteBackupDirPath = await WebDavUtil.getRemoteDirPath();
            if (remoteBackupDirPath.isNotEmpty) {
              BackupUtil.backup(remoteBackupDirPath: remoteBackupDirPath);
            }
          },
        ),
        SwitchListTile(
          title: const Text("自动备份"),
          subtitle: const Text("每次进入应用后会自动备份"),
          value: SPUtil.getBool("auto_backup_webdav"),
          onChanged: (bool value) async {
            if (!SPUtil.getBool("login")) {
              ToastUtil.showText("请先配置账号，再进行备份！");
              return;
            }
            if (SPUtil.getBool("auto_backup_webdav")) {
              // 如果是开启，点击后则关闭
              SPUtil.setBool("auto_backup_webdav", false);
              autoBackupWebDav = "关闭";
            } else {
              SPUtil.setBool("auto_backup_webdav", true);
              // 开启后先备份一次，防止因为用户没有点击过手动备份，而无法得到上一次备份时间，从而无法求出备份间隔
              // WebDavUtil.backupData(true);
              autoBackupWebDav = "开启";
            }
            setState(() {});
          },
        ),
        ListTile(
          title: const Text("自动备份数量"),
          subtitle: Text("$autoBackupWebDavNumber"),
          onTap: () async {
            int? number = await dialogSelectUint(context, "自动备份数量",
                initialValue: autoBackupWebDavNumber,
                minValue: 10,
                maxValue: 20);
            if (number != null) {
              autoBackupWebDavNumber = number;
              SPUtil.setInt("autoBackupWebDavNumber", number);
              setState(() {});
            }
          },
        ),
        ListTile(
          title: const Text("还原远程备份"),
          subtitle: const Text("点击查看所有备份文件"),
          onTap: () async {
            if (SPUtil.getBool("online")) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return const BackUpFileListPage();
                },
              )).then((value) {
                // 可能还原了数据，此时需要重新显示文件数据大小
                setState(() {});
              });
            } else {
              ToastUtil.showText("配置账号后才可以进行还原");
            }
          },
        ),
      ],
    );
  }

  _buildLocalBackup() {
    return Column(
      children: [
        ListTile(
          title: Text(
            "本地备份",
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
        if (Platform.isAndroid)
          ListTile(
            title: const Text("立即备份"),
            onTap: () async {
              String zipName = await BackupUtil.generateZipName();
              File tmpZipFile = await BackupUtil.createTempBackUpFile(zipName);
              await FileSaver.instance.saveAs(
                  zipName, tmpZipFile.readAsBytesSync(), "", MimeType.ZIP);
              tmpZipFile.delete();
            },
          ),
        if (Platform.isWindows)
          ListTile(
            title: const Text("立即备份"),
            subtitle: const Text("单击进行备份，备份目录为设置的本地目录"),
            // subtitle: Text(getDuration()),
            onTap: () {
              // 注意这里是本地手动备份
              ToastUtil.showText("正在备份");
              BackupUtil.backup(
                  localBackupDirPath: SPUtil.getString("backup_local_dir",
                      defaultValue: "unset"));
            },
          ),
        if (Platform.isWindows)
          ListTile(
            title: const Text("本地备份目录"),
            subtitle: Text(SPUtil.getString("backup_local_dir")),
            onTap: () async {
              String? selectedDirectory = await selectDirectory();
              if (selectedDirectory != null) {
                SPUtil.setString("backup_local_dir", selectedDirectory);
                setState(() {});
              }
            },
          ),
        if (Platform.isWindows)
          SwitchListTile(
            title: const Text("自动备份"),
            subtitle: const Text("每次进入应用后会自动备份"),
            value: SPUtil.getBool("auto_backup_local"),
            onChanged: (bool value) {
              if (SPUtil.getString("backup_local_dir", defaultValue: "unset") ==
                  "unset") {
                ToastUtil.showText("请先设置本地备份目录，再进行备份！");
                return;
              }
              if (SPUtil.getBool("auto_backup_local")) {
                // 如果是开启，点击后则关闭
                SPUtil.setBool("auto_backup_local", false);
                autoBackupLocal = "关闭";
              } else {
                SPUtil.setBool("auto_backup_local", true);
                // 开启后先备份一次，防止因为用户没有点击过手动备份，而无法得到上一次备份时间，从而无法求出备份间隔
                // WebDavUtil.backupData(true);
                autoBackupLocal = "开启";
              }
              setState(() {});
            },
          ),
        ListTile(
          title: const Text("还原本地备份"),
          subtitle: const Text("还原动漫记录"),
          onTap: () async {
            // 获取备份文件
            String? selectedFilePath = await selectFile();
            if (selectedFilePath != null) {
              ToastUtil.showLoading(
                msg: "还原数据中",
                task: () {
                  return BackupUtil.restoreFromLocal(selectedFilePath);
                },
                onTaskComplete: (taskValue) {
                  taskValue as Result;
                  ToastUtil.showText(taskValue.msg);
                },
              );
            }
          },
        ),
      ],
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
    List<String> defaultContent = ["https://dav.jianguoyun.com/dav/", "", ""];
    // List<List<String>> autofillHintsList = [
    //   [],
    //   [AutofillHints.username],
    //   [AutofillHints.password]
    // ];

    List<Widget> listTextFields = [];
    for (int i = 0; i < keys.length; ++i) {
      listTextFields.add(TextField(
        obscureText: labelTexts[i] == "密码"
            ? true
            : false, // true会隐藏输入内容，没使用主要是因为开启后不能直接粘贴密码了，
        controller: controllers[i]
          ..text = SPUtil.getString(keys[i], defaultValue: defaultContent[i]),
        decoration: InputDecoration(labelText: labelTexts[i]),
        // autofillHints: autofillHintsList[i],
      ));
    }
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("取消")),
            TextButton(
                onPressed: () async {
                  String uri = inputUriController.text;
                  String user = inputUserController.text;
                  String password = inputPasswordController.text;
                  if (uri.isEmpty || user.isEmpty || password.isEmpty) {
                    // TODO 想要将消息显示在对话框上层，可是为什么指定了dialogContext就不会显示消息了？
                    // ToastUtil.showText("请将信息填入完整！", context: dialogContext);
                    ToastUtil.showText("请将信息填入完整！");
                    return;
                  }
                  SPUtil.setString("webdav_uri", uri);
                  SPUtil.setString("webdav_user", user);
                  SPUtil.setString("webdav_password", password);
                  if (await WebDavUtil.initWebDav(uri, user, password)) {
                    ToastUtil.showText("连接成功");
                    setState(() {});
                    Navigator.of(dialogContext).pop();
                  } else {
                    // 无法观察到弹出消息，因为对话框遮住了弹出消息，因此需要移动到最下面
                    ToastUtil.showText("无法连接，请确保输入正确和网络正常！");
                    // 连接正确后，修改账号后连接失败，需要重新更新显示状态。init里的ping会通过SPUtil记录状态
                    setState(() {});
                  }
                },
                child: const Text("连接"))
          ],
        );
      },
    );
  }
}
