import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../controllers/update_record_controller.dart';

class BackupUtil {
  static String backupZipNamePrefix = "backup";

  static Future<String> getLocalRootDirPath() async {
    String localRootDirPath;
    if (Platform.isAndroid) {
      // localRootDirPath = ((await getExternalStorageDirectory())!.path);
      localRootDirPath = ((await getApplicationSupportDirectory()).path);
    } else if (Platform.isWindows) {
      localRootDirPath = ((await getApplicationSupportDirectory()).path);
      // rootImageDirPath =
      //     join((await getApplicationSupportDirectory()).path, "images");
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    return localRootDirPath;
  }

  // 应该返回webdav包中的File，可惜加上后会和io中的File冲突
  static Future<String> backup({
    String localBackupDirPath = "",
    String remoteBackupDirPath = "",
    bool showToastFlag = true,
    bool automatic = false,
  }) async {
    // DateTime dateTime = DateTime.now();
    // String time =
    //     "${dateTime.year}-${dateTime.month}-${dateTime.day}-${dateTime.hour}-${dateTime.minute}-${dateTime.second}"; // 不足：没有用两位数显示<10的数
    // 2020-02-22 01:01:01.182096取到秒
    String time = DateTime.now().toString().split(".")[0];
    // :和空格转为-
    time = time.replaceAll(":", "-");
    time = time.replaceAll(" ", "-");

    var encoder = ZipFileEncoder();
    String localRootDirPath = await getLocalRootDirPath();
    String zipName = "";
    if (Platform.isAndroid) {
      zipName = "$backupZipNamePrefix-$time-android.zip";
    } else if (Platform.isWindows) {
      zipName = "$backupZipNamePrefix-$time-windows.zip";
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    String tempZipFilePath = "$localRootDirPath/$zipName";
    encoder.create(tempZipFilePath);
    Directory directory = Directory(localRootDirPath);
    // 其他方法：获取上一级目录，直接压缩
    await directory.list().forEach((element) {
      switch (element.statSync().type) {
        case FileSystemEntityType.directory:
          encoder.addDirectory(Directory(element.path)); // 添加目录
          // Log.info("添加目录：${element.path}");
          break;
        case FileSystemEntityType.file:
          if (element.path.endsWith(".zip")) break; // 避免备份压缩包
          // 只备份my.db
          if (element.path.endsWith(SqliteUtil.sqlFileName)) {
            encoder.addFile(File(element.path));
            Log.info("添加文件：${element.path}");
          }
          break;
        default:
          // Log.info("非目录和文件，不压缩：${element.path}");
          break;
      }
    });
    encoder.close();
    if (localBackupDirPath.isNotEmpty) {
      // 已设置路径，直接备份
      if (localBackupDirPath != "unset") {
        // 不管是否都会先创建文件夹，确保存在，否则不能拷贝
        await Directory("$localBackupDirPath/automatic").create();
        String localBackupFilePath;
        if (automatic) {
          localBackupFilePath = "$localBackupDirPath/automatic/$zipName";
        } else {
          localBackupFilePath = "$localBackupDirPath/$zipName";
        }
        await File(tempZipFilePath).copy(localBackupFilePath);
        if (showToastFlag) showToast("备份成功：$localBackupFilePath");
        // 如果还要备份到webdav，则先不删除
        if (remoteBackupDirPath.isEmpty) {
          File(tempZipFilePath).delete();
          return localBackupFilePath;
        }
      } else {
        if (showToastFlag) {
          showToast("请先设置本地备份目录");
          return "";
        }
      }
    }
    if (remoteBackupDirPath.isNotEmpty) {
      if (!SPUtil.getBool("online")) {
        Log.info("WebDav 备份失败，请检查网络状态");
        showToast("WebDav 备份失败，请检查网络状态");
        File(tempZipFilePath).delete(); // 备份失败后需要删掉临时备份文件
        return "";
      }
      String remoteBackupFilePath;
      if (automatic) {
        remoteBackupFilePath = "$remoteBackupDirPath/automatic/$zipName";
      } else {
        remoteBackupFilePath = "$remoteBackupDirPath/$zipName";
      }
      await WebDavUtil.upload(tempZipFilePath, remoteBackupFilePath);
      if (showToastFlag) showToast("WebDav 备份成功：$remoteBackupFilePath");
      // 因为之前upload里的上传没有await，导致还没有上传完毕就删除了文件。从而导致上传失败
      File(tempZipFilePath).delete();
      deleteOldAutoBackupFileFromRemote(
          remoteBackupDirPath); // 删除自动备份中超过用户备份数量的文件
      return remoteBackupFilePath;
      // 可以备份，但不是增量备份。
      // ！无法还原：Unhandled Exception: FormatException: Could not find End of Central Directory Record
      // Uint8List uint8list = File(tempZipFilePath).readAsBytesSync();
      // WebDavUtil.client.write(remoteBackupFilePath, uint8list).then((value) {
      //   if (showToastFlag) showToast("备份成功：$remoteBackupFilePath");
      //   File(tempZipFilePath).delete();
      // });
      // 移动。会导致无法连接，第一次还没有效果
      // WebDavUtil.client
      //     .copy(tempZipFilePath, remoteBackupFilePath, false)
      //     .then((value) {
      //   showToast("备份成功：$remoteBackupFilePath");
      //   File(tempZipFilePath).delete();
      // });
      // 报错
      // WebDavUtil.upload("$dirPath/mydb.db", remoteBackupFilePath)
      //     .then((value) {
      //   showToast("备份成功：$remoteBackupFilePath");
      //   File(tempZipFilePath).delete();
      // });
    }
    return "";
  }

  static deleteOldAutoBackupFileFromRemote(String autoBackupDirPath) async {
    var files = await WebDavUtil.client.readDir("/animetrace/automatic");
    files.sort((a, b) {
      return a.mTime.toString().compareTo(b.mTime.toString());
    });
    int totalNumber = files.length;
    int autoBackupWebDavNumber =
        SPUtil.getInt("autoBackupWebDavNumber", defaultValue: 20);
    for (int i = 0; i < totalNumber - autoBackupWebDavNumber; ++i) {
      String? path = files[i].path;
      if (path != null &&
          path.contains('backup') && // 包含backup
          // && path.startsWith(
          // "/animetrace/automatic/animetrace-backup") && // 以animetrace-backup开头
          // "/animetrace/automatic/$backupZipNamePrefix") && // 以$backupZipNamePrefix开头
          path.endsWith(".zip")) {
        Log.info("删除文件：$path");
        WebDavUtil.client.remove(path);
      }
    }
  }

  static deleteRemoteFile(String filePath) {
    WebDavUtil.client.remove(filePath);
  }

  // static deleteOldAutoBackupFileFromLocal(String autoBackupDirPath) async {
  //   Stream<FileSystemEntity> files = Directory(autoBackupDirPath).list();
  //   await for (FileSystemEntity file in files) {}
  // }

  static Future<void> restoreFromLocal(String localBackupFilePath,
      {bool delete = false}) async {
    final UpdateRecordController updateRecordController = Get.find();
    if (localBackupFilePath.endsWith(".db")) {
      // 对于手机：将该文件拷贝到新路径SqliteUtil.dbPath下，可以直接拷贝：await File(selectedFilePath).copy(SqliteUtil.dbPath);
      // 而window需要手动代码删除，否则：(OS Error: 当文件已存在时，无法创建该文件。
      // 然而并不能删除：(OS Error: 另一个程序正在使用此文件，进程无法访问：await File(SqliteUtil.dbPath).delete();
      // 可以直接在里面写入即可，writeAsBytes会清空原先内容
      var content = await File(localBackupFilePath).readAsBytes();
      File(SqliteUtil.dbPath).writeAsBytes(content).then((value) async {
        // tags = await SqliteUtil.getAllTags(); // 重新更新标签
        await SqliteUtil.ensureDBTable();
        // 重新获取动漫更新记录
        updateRecordController.updateData();
        showToast("还原成功");
      });
    } else if (localBackupFilePath.endsWith(".zip")) {
      unzip(localBackupFilePath).then((value) async {
        // tags = await SqliteUtil.getAllTags(); // 重新更新标签
        await SqliteUtil.ensureDBTable();
        // 重新获取动漫更新记录
        updateRecordController.updateData();
        showToast("还原成功");
        if (delete) File(localBackupFilePath).delete(); // Windows端还原本地备份时不删除
      });
    } else {
      showToast("还原文件必须以.zip或.db结尾");
    }
  }

  static Future<void> restoreFromWebDav(file) async {
    String localRootDirPath = await getLocalRootDirPath();

    if (file.path == null) {
      showToast("还原失败");
      return;
    }
    Log.info("latestFilePath: ${file.path}");
    String localBackupFilePath = "$localRootDirPath/${file.name}";
    await WebDavUtil.client.read2File(file.path as String, localBackupFilePath);

    Log.info(
        "localRootDirPath: $localRootDirPath\nlocalZipPath: $localBackupFilePath");
    // 下载到本地后，使用本地还原，还原结束后删除下载的文件
    restoreFromLocal(localBackupFilePath,
        delete: true); // 这里使用.then里删除，会导致android还原失败
  }

  static Future<void> unzip(String localZipPath) async {
    String localRootDirPath = await getLocalRootDirPath();

    // Read the Zip file from disk.
    final bytes = File(localZipPath).readAsBytesSync();
    // final bytes = localZip.readAsBytesSync();

    // Decode the Zip file
    final archive = ZipDecoder().decodeBytes(bytes);

    Log.info("开始解压");
    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      Log.info("filename: $filename");
      if (file.isFile) {
        // 先判断该图片是否存在，如果不存在再解压出来。否则会闪退
        String filePath = "$localRootDirPath/$filename";
        if (filename.startsWith("images") && File(filePath).existsSync()) {
          Log.info("已存在图片：$filePath");
          continue;
        }
        Log.info("解压文件：$localRootDirPath/$filename");
        final data = file.content as List<int>;
        File("$localRootDirPath/$filename")
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Log.info("非文件：$localRootDirPath/$filename");
        Directory("$localRootDirPath/$filename").createSync(recursive: true);
      }
    }
  }
}
