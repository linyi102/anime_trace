import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/update_hint.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher.dart';

class AboutVersion extends StatefulWidget {
  const AboutVersion({Key? key}) : super(key: key);

  @override
  _AboutVersionState createState() => _AboutVersionState();
}

class _AboutVersionState extends State<AboutVersion> {
  late PackageInfo packageInfo;
  bool loadOk = false;
  bool checkLatestVersion = false;
  final List<Uri> _uris = [
    Uri.parse("https://github.com/linyi102/anime_trace"),
    Uri.parse("https://gitee.com/linyi517/anime_trace"),
    Uri.parse("https://www.wolai.com/6CcZSostD8Se5zuqfTNkAC")
  ];
  final List<String> _urisTitle = ["GitHub 地址", "Gitee 地址", "更新进度"];

  @override
  void initState() {
    super.initState();
    Future(() {
      return PackageInfo.fromPlatform();
    }).then((value) {
      packageInfo = value;
      loadOk = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "关于版本",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            children: _showLVC(),
          ),
          // 改变checkLatestVersion后setState，并无法重新渲染该组件
          // UpdateHint(
          //   checkLatestVersion: checkLatestVersion, // 不先检查，知道点击检查更新后，进行检查
          //   forceShowUpdateDialog: true,
          // )
          // 改用以下方式
          checkLatestVersion
              ? const UpdateHint(
                  checkLatestVersion: true, forceShowUpdateDialog: true)
              : Container()
        ],
      ),
    );
  }

  _showLVC() {
    List<Widget> lvc = [];
    lvc.add(ListTile(
      title: const Text("检查更新"),
      subtitle: loadOk ? Text("当前版本: ${packageInfo.version}") : const Text(""),
      onTap: () {
        if (checkLatestVersion) {
          // 如果已经点击了一次检查更新，则下次点击不再获取最新版本
          return;
          // 下面方法不行，可能是因为合并了setState
          // // 如果已经点击了一次检查更新，则需要重新渲染没有隐藏更新对话框的页面
          // checkLatestVersion = false;
          // setState(() {});
          // // 然后再渲染有更新对话框的页面
        }
        checkLatestVersion = true;
        setState(() {});
      },
    ));
    for (var i = 0; i < _uris.length; i++) {
      lvc.add(
        ListTile(
          title: Text(_urisTitle[i]),
          subtitle: const Text(
            "点击打开链接",
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: () async {
            if (!await launchUrl(_uris[i],
                mode: LaunchMode.externalApplication)) {
              throw "Could not launch $_uris[i]";
            }
            // Clipboard.setData(const ClipboardData(
            //         text: _uris[i]))
            //     .then((value) => showToast("已复制地址"));
          },
        ),
      );
    }
    return lvc;
  }
}
