// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
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
  }) async {
    var encoder = ZipFileEncoder();
    String localRootDirPath = await getLocalRootDirPath();
    String zipName = "manji_backup.zip";
    String tempZipFilePath = "$localRootDirPath/$zipName";
    encoder.create(tempZipFilePath);
    Directory directory = Directory(localRootDirPath);
    directory.list().forEach((element) {
      switch (element.statSync().type) {
        case FileSystemEntityType.directory:
          encoder.addDirectory(Directory(element.path));
          print("添加目录：${element.path}");
          break;
        case FileSystemEntityType.file:
          if (basename(element.path) == zipName) break; // 跳过备份的压缩包
          encoder.addFile(File(element.path));
          print("添加文件：${element.path}");
          break;
        default:
          print("非目录和文件，不压缩：${element.path}");
          break;
      }
    }).then((value) async {
      if (localBackupDirPath.isNotEmpty) {
        // 已设置路径，直接备份
        if (localBackupDirPath != "unset") {
          // 不管是否都会先创建文件夹，确保存在，否则不能拷贝
          Directory(localBackupDirPath).create().then((value) {
            String localBackupFilePath = "$localBackupDirPath/$zipName";
            File(tempZipFilePath).copy(localBackupFilePath).then((value) {
              if (showToastFlag) showToast("备份成功：$localBackupFilePath");
              File(tempZipFilePath).delete();
            });
          });
        } else {
          if (showToastFlag) showToast("请先设置本地备份目录");
        }
      }
      if (remoteBackupDirPath.isNotEmpty) {
        String remoteBackupFilePath = "$remoteBackupDirPath/$zipName";
        // WebDavUtil.upload(tempZipFilePath, remoteBackupFilePath).then((value) {
        //   if (showToastFlag) showToast("备份成功：$remoteBackupFilePath");
        //   // File(tempZipFilePath).delete();
        // });
        // 可以备份，但不是增量备份
        Uint8List uint8list = File(tempZipFilePath).readAsBytesSync();
        WebDavUtil.client.write(remoteBackupFilePath, uint8list).then((value) {
          showToast("备份成功：$remoteBackupFilePath");
          File(tempZipFilePath).delete();
        });
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
      encoder.close();
      // 删除临时的压缩包
    });
  }

  static void restore({
    String localZipPath = "",
    String remoteZipPath = "",
  }) async {
    String localRootDirPath = await getLocalRootDirPath();
    // 如果图片目录中的图片都不存在，则可以正常还原。如果存在则会退出
    // 解决方法：先删除掉图片目录中的所有图片，然后再还原
    // 或者直接递归删除图片目录(不行，会闪退，但删除单个图片却可以)
    // 当前的解决办法：存在该图片就不解压出来
    // Directory directory = Directory(localRootDirPath);
    // directory.list().forEach((element) {
    //   element.deleteSync(recursive: true);
    // });
    // localRootDirPath = "C:/Users/11580/Desktop";
    // Directory("$localRootDirPath/images").deleteSync(recursive: true);
    // debugPrint("图片目录删除成功");
    // File("C:/Users/11580/AppData/Roaming/com.example/anime_footmark_windows/images/26/1/20210225_190939.jpg")
    //     .deleteSync();
    // debugPrint("图片删除成功");
    debugPrint(localRootDirPath);
    if (localZipPath.isNotEmpty) {
      // Read the Zip file from disk.
      final bytes = File(localZipPath).readAsBytesSync();

      // Decode the Zip file
      final archive = ZipDecoder().decodeBytes(bytes);

      debugPrint("开始解压");
      // Extract the contents of the Zip archive to disk.
      for (final file in archive) {
        final filename = file.name;
        debugPrint("filename: $filename");
        if (file.isFile) {
          // 先判断该图片是否存在，如果不存在再解压出来
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
}
