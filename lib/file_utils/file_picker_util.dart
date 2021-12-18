import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

selectFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result != null) {
    // File file = File(result.files.single.path as String);
    PlatformFile file = result.files.first;
    debugPrint(file.name);
  }
  return result;
}

Future<String> selectDirectory() async {
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  if (selectedDirectory != null) {
    debugPrint(selectedDirectory);
    return selectedDirectory;
  }
  return "";
}
