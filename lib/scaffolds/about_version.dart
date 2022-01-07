import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:url_launcher/url_launcher.dart';

class AboutVersion extends StatefulWidget {
  const AboutVersion({Key? key}) : super(key: key);

  @override
  _AboutVersionState createState() => _AboutVersionState();
}

class _AboutVersionState extends State<AboutVersion> {
  late PackageInfo packageInfo;
  bool loadOk = false;
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("当前版本"),
            subtitle: loadOk ? Text(packageInfo.version) : const Text(""),
          ),
          ListTile(
            title: const Text("Github 地址"),
            subtitle: const Text("https://github.com/linyi102/anime_trace"),
            onTap: () {
              Clipboard.setData(const ClipboardData(
                      text: "https://github.com/linyi102/anime_trace"))
                  .then((value) => showToast("已复制地址"));
            },
          ),
          ListTile(
            title: const Text("Gitee 地址"),
            subtitle: const Text("https://gitee.com/linyi517/anime_trace"),
            onTap: () {
              Clipboard.setData(const ClipboardData(
                      text: "https://gitee.com/linyi517/anime_trace"))
                  .then((value) => showToast("已复制地址"));
            },
          ),
          ListTile(
            title: const Text("更新进度"),
            subtitle:
                const Text("https://www.wolai.com/6CcZSostD8Se5zuqfTNkAC"),
            onTap: () {
              Clipboard.setData(const ClipboardData(
                      text: "https://www.wolai.com/6CcZSostD8Se5zuqfTNkAC"))
                  .then((value) => showToast("已复制地址"));
            },
          ),
        ],
      ),
    );
  }

  // void _launchURL(String urlStr) async {
  //   if (!await launch(urlStr)) throw 'Could not launch $urlStr';
  // }
}
