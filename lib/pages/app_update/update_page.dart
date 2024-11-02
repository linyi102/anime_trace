import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/enum/github_mirror.dart';
import 'package:flutter_test_future/models/release_arch.dart';
import 'package:flutter_test_future/services/update_service.dart';
import 'package:flutter_test_future/utils/installer.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/system.dart';
import 'package:flutter_test_future/utils/version.dart';

class AppUpdateView extends StatefulWidget {
  const AppUpdateView({super.key, required this.service});
  final AppUpdateService service;

  @override
  State<AppUpdateView> createState() => _AppUpdateViewState();
}

class _AppUpdateViewState extends State<AppUpdateView>
    with SingleTickerProviderStateMixin {
  AppUpdateService get service => widget.service;
  final androidArches = [
    AndroidReleaseArch('arm', match: (url) => url.endsWith('-android.apk')),
    AndroidReleaseArch('arm64', match: (url) => url.endsWith('-arm64-v8a.apk')),
    AndroidReleaseArch('x86_64', match: (url) => url.endsWith('-x86_64.apk')),
  ];
  final windowsArches = [
    ReleaseArch(
      'exe',
      match: (url) => url.endsWith('-win-install.exe'),
      install: installWindowsExe,
    ),
    ReleaseArch(
      'zip',
      match: (url) => url.endsWith('-windows.zip'),
      install: installWindowsZip,
    ),
  ];
  late final arches = systemWhen(
        android: () => androidArches,
        windows: () => windowsArches,
        macos: () => windowsArches,
      ) ??
      [];
  late ReleaseArch? selectedArch = arches.firstOrNull;
  GithubMirror selectedMirror = GithubMirror.github;
  EdgeInsets get viewPadding =>
      const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  bool get disableSelect => [DownloadStatus.downloading, DownloadStatus.success]
      .contains(service.downloadStatus.value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  padding: viewPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 12),
                      Expanded(
                          child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(service.releaseInfo?.releaseNotes ?? ''),
                            const SizedBox(height: 10),
                            _buildLinks(),
                          ],
                        ),
                      ))
                    ],
                  ),
                ),
              ),
              const Divider(),
              Container(
                padding: viewPadding,
                child: ValueListenableBuilder(
                  valueListenable: service.downloadStatus,
                  builder: (context, downloadStatus, child) => Column(
                    children: [
                      if (downloadStatus != DownloadStatus.success) ...[
                        _buildSelectArch(),
                        const SizedBox(height: 12),
                        _buildMirror(),
                        const SizedBox(height: 16)
                      ],
                      _buildBottomAction(downloadStatus),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Column _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '发现新版本！',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          children: [
            Text(
                '${formatVersion(service.curVersion)} -> ${formatVersion(service.releaseInfo?.version ?? '')}'),
            const Spacer(),
            TextButton(
                onPressed: () => service.toChanglog(context),
                child: const Text('更新日志')),
          ],
        ),
      ],
    );
  }

  Wrap _buildLinks() {
    return Wrap(
      children: [
        TextButton(onPressed: () {}, child: const Text('GitHub')),
        TextButton(onPressed: () {}, child: const Text('Gitee')),
        TextButton(onPressed: () {}, child: const Text('QQ')),
        TextButton(onPressed: () {}, child: const Text('蓝奏云 (0517)')),
      ],
    );
  }

  Widget _buildFieldRow({required String name, required Widget child}) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(name)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: child,
          ),
        )
      ],
    );
  }

  Widget _buildMirror() {
    return _buildFieldRow(
      name: '镜像',
      child: Row(
        children: [
          for (final mirror in GithubMirror.values)
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: FilterChip(
                label: Text(mirror.name),
                selected: selectedMirror == mirror,
                onSelected: disableSelect
                    ? null
                    : (bool value) {
                        if (!value) return;
                        setState(() {
                          selectedMirror = mirror;
                        });
                      },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildSelectArch() {
    if (arches.isEmpty) return const SizedBox();

    return _buildFieldRow(
      name: '架构',
      child: Row(
        children: [
          for (final arch in arches)
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: FilterChip(
                label: Text(arch.label),
                selected: selectedArch == arch,
                onSelected: disableSelect
                    ? null
                    : (bool value) {
                        if (!value) return;
                        setState(() {
                          selectedArch = arch;
                        });
                      },
              ),
            )
        ],
      ),
    );
  }

  Row _buildBottomAction(DownloadStatus downloadStatus) {
    List<Widget> actions = [];
    switch (downloadStatus) {
      case DownloadStatus.initial:
      case DownloadStatus.error:
        actions = [
          TextButton(
            onPressed: () => service.ignore(context),
            child: const Text('忽略'),
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('取消'),
          ),
          Expanded(
            child: FilledButton(
              onPressed: () {
                if (selectedArch == null) return;
                logger.info('arch: ${selectedArch!.label}');
                logger.info('mirror: ${selectedMirror.name}');
                service.download(arch: selectedArch!, mirror: selectedMirror);
              },
              child: const Text('下载'),
            ),
          ),
        ];
        break;
      case DownloadStatus.downloading:
        actions = [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('后台下载'),
          ),
          TextButton(
            onPressed: () {
              service.stopDownload();
            },
            child: const Text('停止'),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: service.downloadPercent,
              builder: (context, percent, child) => FilledButton(
                onPressed: null,
                child: Text('下载中... (${percent * 100}%)'),
              ),
            ),
          ),
        ];
        break;
      case DownloadStatus.success:
        actions = [
          TextButton(
            onPressed: service.reSelect,
            child: const Text('重新选择'),
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('取消'),
          ),
          Expanded(
            child: FilledButton(
              onPressed: () {
                if (selectedArch == null) return;
                service.install(selectedArch!);
              },
              child: const Text('安装'),
            ),
          ),
        ];
        break;
      default:
    }
    return Row(children: actions);
  }
}
