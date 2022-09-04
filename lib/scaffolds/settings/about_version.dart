import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/update_hint.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_icons/simple_icons.dart';
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
      Uri.parse("https://jq.qq.com/?_wv=1027&k=qOpUIx7x")
    ];
    final List<String> _urisTitle = ["更新进度", "QQ 交流群"];
    final List<IconData> _urisIcon = [
      Icons.open_in_new_outlined,
      Icons.open_in_new_outlined,
    ];
    final List<Color> _urisIconColor = [
      Colors.grey,
      Colors.grey
    ];

    lvc.add(Column(
      children: [
        Container(
          height: 100,
          width: 100,
          margin: const EdgeInsets.fromLTRB(10, 20, 0, 10),
          alignment: Alignment.center,
          child: Image.asset('assets/images/logo.png'),
        ),
        loadOk ? Text("当前版本: ${packageInfo.version}") : const Text(""),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () {
                  _launchUrl("https://gitee.com/linyi517/anime_trace");
                },
                icon: Icon(
                  SimpleIcons.github,
                  color: SPUtil.getBool("enableDark")
                      ? Colors.white
                      : Colors.black,
                )),
            IconButton(
              onPressed: () {
                _launchUrl("https://github.com/linyi102/anime_trace");
              },
              icon: const Icon(SimpleIcons.gitee),
              color: Color.fromRGBO(187, 33, 36, 1),
            )
          ],
        ),
      ],
    ));
    lvc.add(ListTile(
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
        title: const Text("检查更新")));
    lvc.add(ListTile(
        title: const Text("更新进度"),
        trailing: const Icon(Icons.open_in_new_outlined),
        onTap: () {
          _launchUrl("https://www.wolai.com/6CcZSostD8Se5zuqfTNkAC");
        }));
    lvc.add(ListTile(
        title: const Text("QQ 交流群"),
        subtitle: const Text("414226908"),
        trailing: const Icon(Icons.open_in_new_outlined),
        onTap: ()  {
          _launchUrl("https://jq.qq.com/?_wv=1027&k=qOpUIx7x");
        }));
    return lvc;
  }

  _launchUrl(String uriStr, {bool inApp = false}) async {
    Uri uri = Uri.parse(uriStr);
    if (!await launchUrl(uri, mode: inApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication)) {
      throw "无法打开链接：$uri";
    }
  }
}
