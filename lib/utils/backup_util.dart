import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/pages/network/sources/pages/dedup/dedup_controller.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:webdav_client/webdav_client.dart' as dav_client;

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

  /// 备份时，用于生成文件名
  static Future<String> generateZipName() async {
    // 2020-02-22 01:01:01.182096取到秒
    String time = DateTime.now().toString().split(".")[0];
    // :和空格转为-
    time = time.replaceAll(":", "-");
    time = time.replaceAll(" ", "-");

    String zipName = "";
    if (Platform.isAndroid) {
      zipName = "$backupZipNamePrefix-$time-android.zip";
    } else if (Platform.isWindows) {
      zipName = "$backupZipNamePrefix-$time-windows.zip";
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }

    return zipName;
  }

  /// 创建临时备份文件
  static Future<File> createTempBackUpFile(String zipName) async {
    var encoder = ZipFileEncoder();
    String localRootDirPath = await getLocalRootDirPath();

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

    return File(tempZipFilePath);
  }

  static Future<Result> autoBackupRemote() async {
    await BackupUtil.backup(
      remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
      showToastFlag: false,
      automatic: true,
    );

    return Result.success("", msg: "远程备份成功");
  }

  // 应该返回webdav包中的File，可惜加上后会和io中的File冲突
  static Future<String> backup({
    String localBackupDirPath = "",
    String remoteBackupDirPath = "",
    bool showToastFlag = true,
    bool automatic = false,
  }) async {
    String zipName = await generateZipName();
    File tempZipFile = await createTempBackUpFile(zipName);

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
        await tempZipFile.copy(localBackupFilePath);
        if (showToastFlag) ToastUtil.showText("本地备份成功");
        // 如果还要备份到webdav，则先不删除
        if (remoteBackupDirPath.isEmpty) {
          tempZipFile.delete();
          return localBackupFilePath;
        }
      } else {
        if (showToastFlag) {
          ToastUtil.showText("请先设置本地备份目录");
          return "";
        }
      }
    }
    if (remoteBackupDirPath.isNotEmpty) {
      if (!SPUtil.getBool("online")) {
        Log.info("远程备份失败，请检查网络状态");
        ToastUtil.showText("远程备份失败，请检查网络状态");
        tempZipFile.delete(); // 备份失败后需要删掉临时备份文件
        return "";
      }
      String remoteBackupFilePath;
      if (automatic) {
        // 即使不存在automatic目录，上传文件到坚果云、TeraCloud时也会成功
        remoteBackupFilePath = "$remoteBackupDirPath/automatic/$zipName";
      } else {
        remoteBackupFilePath = "$remoteBackupDirPath/$zipName";
      }
      await WebDavUtil.upload(tempZipFile.path, remoteBackupFilePath);
      SPUtil.setString(latestDavBackupFilePath, remoteBackupFilePath);
      if (showToastFlag) {
        ToastUtil.showText("远程备份成功");
      }
      // 因为之前upload里的上传没有await，导致还没有上传完毕就删除了文件。从而导致上传失败
      tempZipFile.delete();
      deleteOldAutoBackupFileFromRemote(
          remoteBackupDirPath); // 删除自动备份中超过用户备份数量的文件
      return remoteBackupFilePath;
      // 可以备份，但不是增量备份。
      // ！无法还原：Unhandled Exception: FormatException: Could not find End of Central Directory Record
      // Uint8List uint8list = File(tempZipFilePath).readAsBytesSync();
      // WebDavUtil.client.write(remoteBackupFilePath, uint8list).then((value) {
      //   if (showToastFlag) ToastUtil.showText("备份成功：$remoteBackupFilePath");
      //   File(tempZipFilePath).delete();
      // });
      // 移动。会导致无法连接，第一次还没有效果
      // WebDavUtil.client
      //     .copy(tempZipFilePath, remoteBackupFilePath, false)
      //     .then((value) {
      //   ToastUtil.showText("备份成功：$remoteBackupFilePath");
      //   File(tempZipFilePath).delete();
      // });
      // 报错
      // WebDavUtil.upload("$dirPath/mydb.db", remoteBackupFilePath)
      //     .then((value) {
      //   ToastUtil.showText("备份成功：$remoteBackupFilePath");
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

  static Future<Result> restoreFromLocal(String localBackupFilePath,
      {bool delete = false}) async {
    final UpdateRecordController updateRecordController = Get.find();
    final LabelsController labelsController = Get.find();
    bool restoreOk = false;

    if (localBackupFilePath.endsWith(".db")) {
      // 对于手机：将该文件拷贝到新路径SqliteUtil.dbPath下，可以直接拷贝：await File(selectedFilePath).copy(SqliteUtil.dbPath);
      // 而window需要手动代码删除，否则：(OS Error: 当文件已存在时，无法创建该文件。
      // 然而并不能删除：(OS Error: 另一个程序正在使用此文件，进程无法访问：await File(SqliteUtil.dbPath).delete();
      // 可以直接在里面写入即可，writeAsBytes会清空原先内容
      var content = await File(localBackupFilePath).readAsBytes();
      await File(SqliteUtil.dbPath).writeAsBytes(content);
      await SqliteUtil.ensureDBTable();
      restoreOk = true;
    } else if (localBackupFilePath.endsWith(".zip")) {
      await unzip(localBackupFilePath);
      await SqliteUtil.ensureDBTable();
      if (delete) File(localBackupFilePath).delete(); // Windows端还原本地备份时不删除
      restoreOk = true;
    }

    if (restoreOk) {
      // 重新获取动漫更新记录
      updateRecordController.updateData();
      // 重新获取标签信息
      labelsController.getAllLabels();
      // 直接删除相关控制器(注意有些控制器不能删除，因为是在Global.init里put的，不过应该可以再次调用它就好，待测试)
      Get.delete<DedupController>();

      return Result.success("", msg: "还原成功");
    } else {
      return Result.failure(404, "备份文件不正确，无法还原");
    }
  }

  static Future<Result> restoreFromWebDav(dav_client.File file) async {
    String localRootDirPath = await getLocalRootDirPath();

    if (file.path == null) {
      return Result.failure(404, "空文件路径，无法还原");
    }
    Log.info("latestFilePath: ${file.path}");
    String localBackupFilePath = "$localRootDirPath/${file.name}";
    await WebDavUtil.client.read2File(file.path as String, localBackupFilePath);

    Log.info(
        "localRootDirPath: $localRootDirPath\nlocalZipPath: $localBackupFilePath");
    // 下载到本地后，使用本地还原，还原结束后删除下载的文件
    return restoreFromLocal(localBackupFilePath, delete: true);
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

  /// 获取远程所有备份文件列表，包括手动和自动
  static Future<List<dav_client.File>> getAllBackupFiles() async {
    List<dav_client.File> files = [];

    String backupDir = await WebDavUtil.getRemoteDirPath();
    if (backupDir.isEmpty) {
      Log.info("远程备份路径为空");
      return [];
    }

    String autoDir = await WebDavUtil.getRemoteAutoDirPath(backupDir);
    files.addAll(await WebDavUtil.client.readDir(backupDir));
    files.addAll(await WebDavUtil.client.readDir(autoDir));

    // 去除目录
    files.removeWhere(
        (element) => element.isDir ?? element.path?.endsWith("/") ?? false);

    Log.info("获取完毕，共${files.length}个文件");
    files.sort((a, b) => b.mTime.toString().compareTo(a.mTime.toString()));
    return files;
  }

  /// 获取最新远程备份文件
  static Future<dav_client.File?> getLatestBackupFile() async {
    var files = await getAllBackupFiles();
    if (files.isEmpty) {
      return null;
    } else {
      return files.first;
    }
  }
}
