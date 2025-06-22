import 'dart:io';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DevicePreviewScreenshotSection extends StatelessWidget {
  const DevicePreviewScreenshotSection({
    super.key,
    this.outputDirPath,
  });
  final String? outputDirPath;

  @override
  Widget build(BuildContext context) {
    return ToolPanelSection(
      title: 'Device Screenshot',
      children: [
        DevicePreviewScreenshot(
          outputDirPath: outputDirPath,
        ),
      ],
    );
  }
}

class DevicePreviewScreenshot extends StatefulWidget {
  const DevicePreviewScreenshot({
    super.key,
    required this.outputDirPath,
  });
  final String? outputDirPath;

  @override
  State<DevicePreviewScreenshot> createState() =>
      _DevicePreviewScreenshotState();
}

class _DevicePreviewScreenshotState extends State<DevicePreviewScreenshot> {
  String? description;
  late String outputDirPath;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    outputDirPath =
        widget.outputDirPath ?? (await getDownloadsDirectory())!.path;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Take a screenshot'),
      subtitle: description != null
          ? Text(description!)
          : const Text(
              'Take a screenshot',
            ),
      onTap: () => _takeScreenshot(
        context: context,
        outputDirPath: outputDirPath,
        onUpdate: (value) {
          if (mounted) setState(() => description = value);
        },
      ),
      trailing: IconButton(
          onPressed: () {
            Process.run('start', [outputDirPath], runInShell: true);
          },
          icon: const Icon(Icons.folder_open)),
    );
  }

  Future<void> _takeScreenshot({
    required BuildContext context,
    required void Function(String value) onUpdate,
    required String outputDirPath,
  }) async {
    onUpdate('Start taking screenshots.');
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (!context.mounted) {
      return;
    }
    final screenshot = await DevicePreview.screenshot(context);
    final file = await File(
      '$outputDirPath/$timestamp.png',
    ).create();
    await file.writeAsBytes(screenshot.bytes);

    onUpdate('Screenshot saved! 🎉');
    await Future.delayed(const Duration(seconds: 3));
    onUpdate('Complete taking screenshots.');
  }
}
