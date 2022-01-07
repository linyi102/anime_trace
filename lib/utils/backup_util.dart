// ignore_for_file: avoid_print
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BackupUtil {
  static Future<String> getLocalRootDirPath() async {
    String localRootDirPath;
    if (Platform.isAndroid) {
      localRootDirPath = ((await getExternalStorageDirectory())!.path);
    } else if (Platform.isWindows) {
      localRootDirPath = ((await getApplicationSupportDirectory()).path);
      // rootImageDirPath =
      //     join((await getApplicationSupportDirectory()).path, "images");
    } else {
      throw ("未适配平台：${Platform.environment}");
    }
    return localRootDirPath;
  }

  static void backup({
    String localBackupDirPath = "",
    String remoteBackupDirPath = "",
    bool showToastFlag = true,
    bool automatic = false,
  }) async {
    DateTime dateTime = DateTime.now();
    String time =
        "${dateTime.year}-${dateTime.month}-${dateTime.day}-${dateTime.hour}-${dateTime.minute}-${dateTime.second}";

    var encoder = ZipFileEncoder();
    String localRootDirPath = await getLocalRootDirPath();
    String zipName = "";
    if (Platform.isAndroid) {
      zipName = "animetrace-backup-$time-android.zip";
    } else if (Platform.isWindows) {
      zipName = "animetrace-backup-$time-windows.zip";
    } else {
      throw ("未适配平台：${Platform.environment}");
    }
    String tempZipFilePath = "$localRootDirPath/$zipName";
    encoder.create(tempZipFilePath);
    Directory directory = Directory(localRootDirPath);
    // 其他方法：获取上一级目录，直接压缩
    directory.list().forEach((element) {
      switch (element.statSync().type) {
        case FileSystemEntityType.directory:
          encoder.addDirectory(Directory(element.path)); // 添加目录
          print("添加目录：${element.path}");
          break;
        case FileSystemEntityType.file:
          if (element.path.endsWith(".zip")) break; // 避免备份压缩包
          encoder.addFile(File(element.path));
          print("添加文件：${element.path}");
          break;
        default:
          print("非目录和文件，不压缩：${element.path}");
          break;
      }
    }).then((value) async {
      encoder.close();
      if (localBackupDirPath.isNotEmpty) {
        // 已设置路径，直接备份
        if (localBackupDirPath != "unset") {
          // 不管是否都会先创建文件夹，确保存在，否则不能拷贝
          Directory("$localBackupDirPath/automatic").create().then((value) {
            String localBackupFilePath;
            if (automatic) {
              localBackupFilePath = "$localBackupDirPath/automatic/$zipName";
            } else {
              localBackupFilePath = "$localBackupDirPath/$zipName";
            }
            File(tempZipFilePath).copy(localBackupFilePath).then((value) {
              if (showToastFlag) showToast("备份成功：$localBackupFilePath");
              // 如果还要备份到webdav，则先不删除
              if (remoteBackupDirPath.isEmpty) File(tempZipFilePath).delete();
            });
          });
        } else {
          if (showToastFlag) showToast("请先设置本地备份目录");
        }
      }
      if (remoteBackupDirPath.isNotEmpty) {
        String remoteBackupFilePath;
        if (automatic) {
          remoteBackupFilePath = "$remoteBackupDirPath/automatic/$zipName";
        } else {
          remoteBackupFilePath = "$remoteBackupDirPath/$zipName";
        }
        WebDavUtil.upload(tempZipFilePath, remoteBackupFilePath).then((value) {
          if (showToastFlag) showToast("备份成功：$remoteBackupFilePath");
          // 因为之前upload里的上传没有await，导致还没有上传完毕就删除了文件。从而导致上传失败
          File(tempZipFilePath).delete();
        });
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
    });
  }

  static Future<void> restoreFromLocal(String localBackupFilePath) async {
    if (localBackupFilePath.endsWith(".db")) {
      // 对于手机：将该文件拷贝到新路径SqliteUtil.dbPath下，可以直接拷贝：await File(selectedFilePath).copy(SqliteUtil.dbPath);
      // 而window需要手动代码删除，否则：(OS Error: 当文件已存在时，无法创建该文件。
      // 然而并不能删除：(OS Error: 另一个程序正在使用此文件，进程无法访问：await File(SqliteUtil.dbPath).delete();
      // 可以直接在里面写入即可，writeAsBytes会清空原先内容
      var content = await File(localBackupFilePath).readAsBytes();
      File(SqliteUtil.dbPath)
          .writeAsBytes(content)
          .then((value) => showToast("还原成功"));
    } else if (localBackupFilePath.endsWith(".zip")) {
      unzip(localBackupFilePath).then((value) {
        showToast("还原成功");
        File(localBackupFilePath).delete();
      });
    } else {
      showToast("还原文件必须以.zip或.db结尾");
    }
  }

  static void restoreFromWebDav() async {
    String localRootDirPath = await getLocalRootDirPath();

    var files = await WebDavUtil.client.readDir("/animetrace");
    files.addAll(await WebDavUtil.client.readDir("/animetrace/automatic"));
    files.sort((a, b) {
      return a.mTime.toString().compareTo(b.mTime.toString());
    });
    // for (var file in files) {
    //   debugPrint(
    //       "${file.path} created time: ${file.mTime.toString()}"); // cTime都是null
    // }
    var latestFile = files.last;
    if (latestFile.path == null) {
      showToast("还原失败");
      return;
    }
    debugPrint("latestFilePath: ${latestFile.path}");
    String localBackupFilePath = "$localRootDirPath/${latestFile.name}";
    await WebDavUtil.client
        .read2File(latestFile.path as String, localBackupFilePath);

    debugPrint(
        "localRootDirPath: $localRootDirPath\nlocalZipPath: $localBackupFilePath");
    // 下载到本地后，使用本地还原，还原结束后删除下载的文件
    restoreFromLocal(localBackupFilePath); // 这里使用.then里删除，会导致android还原失败
  }

  static Future<void> unzip(String localZipPath) async {
    String localRootDirPath = await getLocalRootDirPath();

    // Read the Zip file from disk.
    final bytes = File(localZipPath).readAsBytesSync();
    // final bytes = localZip.readAsBytesSync();

    // Decode the Zip file
    final archive = ZipDecoder().decodeBytes(bytes);

    debugPrint("开始解压");
    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      debugPrint("filename: $filename");
      if (file.isFile) {
        // 先判断该图片是否存在，如果不存在再解压出来。否则会闪退
        String filePath = "$localRootDirPath/$filename";
        if (filename.startsWith("images") && File(filePath).existsSync()) {
          debugPrint("已存在图片：$filePath");
          continue;
        }
        debugPrint("解压文件：$localRootDirPath/$filename");
        final data = file.content as List<int>;
        File("$localRootDirPath/$filename")
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        debugPrint("非文件：$localRootDirPath/$filename");
        Directory("$localRootDirPath/$filename").createSync(recursive: true);
      }
    }
  }
}