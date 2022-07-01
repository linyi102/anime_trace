import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/update_hint.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutVersion extends StatefulWidget {
  const AboutVersion({Key? key}) : super(key: key);

  @override
  _AboutVersionState createState() => _AboutVersionState();
}

class _AboutVersionState extends State<AboutVersion> {
  late PackageInfo packageInfo;
  bool loadOk = false;
  bool checkLatestVersion = false;

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
    final List<Uri> _uris = [
      Uri.parse("https://www.wolai.com/6CcZSostD8Se5zuqfTNkAC"),
      Uri.parse("https://github.com/linyi102/anime_trace"),
      Uri.parse("https://gitee.com/linyi517/anime_trace")
    ];
    final List<String> _urisTitle = ["更新进度", "GitHub 地址", "Gitee 地址"];
    final List<IconData> _urisIcon = [
      const IconData(0),
      const IconData(0),
      const IconData(0),
      // SimpleIcons.github,
      // SimpleIcons.gitee,
    ];
    final List<Color> _urisIconColor = [
      Colors.transparent,
      Colors.black,
      const Color.fromRGBO(187, 33, 36, 1),
    ];

    lvc.add(ListTile(
      title: const Text("检查更新"),
      subtitle: loadOk ? Text("当前版本: ${packageInfo.version}") : const Text(""),
      onTap: () {
        if (checkLatestVersion) {
          checkLatestVersion = false;
          setState(() {});
        }
        // 必须推迟，否则可能会合并setState
        // 然后再渲染有更新对话框的页面
        Future.delayed(const Duration(milliseconds: 200)).then((value) {
          showToast("正在获取最新版本...");
          checkLatestVersion = true;
          setState(() {});
        });
      },
    ));
    for (var i = 0; i < _uris.length; i++) {
      lvc.add(
        ListTile(
          title: Text(_urisTitle[i]),
          trailing: Icon(
            _urisIcon[i],
            color: _urisIconColor[i],
          ),
          // subtitle: const Text(
          //   "点击打开链接",
          //   style: TextStyle(
          //     overflow: TextOverflow.ellipsis,
          //   ),
          // ),
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
