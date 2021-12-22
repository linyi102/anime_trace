// ignore_for_file: avoid_print

import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:webdav_client/webdav_client.dart';

class WebDavUtil {
  static WebDavUtil? _webDavUtil;
  WebDavUtil._();
  static WebDavUtil getInstance() {
    return _webDavUtil ??= WebDavUtil._();
  }

  static late Client client;

  static Future<bool> initWebDav(
      String uri, String user, String password) async {
    client = newClient(
      uri,
      user: user,
      password: password,
      debug: false,
    );
    if (!(await pingWebDav())) {
      print("WebDav初始化失败！");
      return false;
    }
    // Set the public request headers
    client.setHeaders({'accept-charset': 'utf-8'});

    // Set the connection server timeout time in milliseconds.
    client.setConnectTimeout(8000);

    // Set send data timeout time in milliseconds.
    client.setSendTimeout(8000);

    // Set transfer data time in milliseconds.
    client.setReceiveTimeout(8000);
    print("WebDav初始化成功！");
    return true;
  }

  static Future<bool> pingWebDav() async {
    try {
      await client.ping();
    } catch (e) {
      SPUtil.setBool("login", false); // 如果之前成功，但现在失败了，所以需要覆盖
      print("ping false");
      return false;
    }
    SPUtil.setBool("login", true);
    print("ping ok");
    return true;
  }

  static void upload(String localPath, String remotePath) async {
    await client.writeFromFile(
      localPath,
      remotePath,
    );
  }

  static Future<String> backupData() async {
    // 先判断是否有animetrace目录，没有则创建
    String backupDir = "/animetrace";
    var list = await client.readDir('/');
    bool existBackupDir = false;
    for (var file in list) {
      if (file.name == "animetrace") {
        existBackupDir = true;
        break;
      }
    }
    if (!existBackupDir) {
      await client.mkdir(backupDir);
    }

    DateTime dateTime = DateTime.now();
    String time =
        "${dateTime.year}-${dateTime.month}-${dateTime.day}_${dateTime.hour}-${dateTime.minute}-${dateTime.second}";
    String remotePath = '$backupDir/animetrace_$time.db';

    upload(SqliteUtil.dbPath, remotePath);
    print("备份成功：$remotePath");
    // 更新最后一次备份的时间
    SPUtil.setString("last_time_backup", dateTime.toString());
    return remotePath;
  }
}
