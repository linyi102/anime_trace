import 'package:flutter/material.dart';
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
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: _showLVC(),
      ),
    );
  }

  _showLVC() {
    List<Widget> lvc = [];
    lvc.add(ListTile(
      title: const Text("当前版本"),
      subtitle: loadOk ? Text(packageInfo.version) : const Text(""),
    ));
    for (var i = 0; i < _uris.length; i++) {
      lvc.add(
        ListTile(
          title: Text(_urisTitle[i]),
          // trailing: IconButton(
          //     onPressed: () async {
          //       if (!await launchUrl(_uris[i])) {
          //         throw "Could not launch $_uris[i]";
          //       }
          //     },
          //     icon: const Icon(Icons.open_in_browser)),
          subtitle: const Text(
            "点击打开链接",
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: () async {
            if (!await launchUrl(_uris[i])) {
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
