// ignore_for_file: avoid_print
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 获取文档目录文件
Future<File> _getLocalDocumentFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/str.txt');
}

/// 获取临时目录文件
Future<File> _getLocalTemporaryFile() async {
  final dir = await getTemporaryDirectory();
  return File('${dir.path}/str.txt');
}

/// 获取应用程序目录文件
Future<File> _getLocalSupportFile() async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}/str.txt');
}

String name = "Jimi";

/// 写入数据
Future<void> writeString() async {
  final file = await _getLocalDocumentFile();
  // await file.writeAsString(name);
  print(file.path);

  final file1 = await _getLocalTemporaryFile();
  // await file1.writeAsString(name);
  print(file1.path);

  final file2 = await _getLocalSupportFile();
  // await file2.writeAsString(name);
  print(file2.path);

  // print("写入成功");
}
