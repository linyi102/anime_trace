import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateHint extends StatefulWidget {
  final bool checkLatestVersion; // 刚进入关于版本页面，不检查更新
  final bool forceShowUpdateDialog; // 在关于版本页面中，点击检查更新时，即使取消了忽略新版本，也会提示更新对话框
  const UpdateHint(
      {Key? key,
      this.checkLatestVersion = false,
      this.forceShowUpdateDialog = false})
      : super(key: key);

  @override
  State<UpdateHint> createState() => _UpdateHintState();
}

class _UpdateHintState extends State<UpdateHint> {
  bool foundNewVersion = false;
  bool showUpdateDialog = false;
  String currentVersion = "";
  String latestVersion = "";

  @override
  void initState() {
    super.initState();
    debugPrint(widget.checkLatestVersion.toString());
    if (widget.checkLatestVersion) {
      _checkNewVersion();
    }
  }

  _checkNewVersion() async {
    currentVersion = (await PackageInfo.fromPlatform()).version;
    latestVersion = await _getLatestVersion();
    if (currentVersion != latestVersion) {
      foundNewVersion = true;
      // 如果忽略了该最新版本，则不进行更新提示
      if (SPUtil.getBool("ignore$latestVersion") == true) {
        showUpdateDialog = false;
        debugPrint("已忽略更新版本：$latestVersion");
      } else {
        showUpdateDialog = true;
      }
      // 如果是点击了关于版本中的检查更新，则如果有新版本，就显示更新对话框(及时之前忽略了新版本的更新)
      if (widget.forceShowUpdateDialog) {
        showUpdateDialog = true;
      }
      debugPrint("当前版本：$currentVersion，最新版本：$latestVersion");
      // 显示对话框
      setState(() {});
    } else {
      // 在关于版本页面中点击检查更新后，如果版本一致，则进行提示
      if (widget.forceShowUpdateDialog) {
        showToast("当前已是最新版本");
      }
    }
  }

  Future<String> _getLatestVersion() async {
    try {
      debugPrint("正在获取最新版本...");
      var response = await Dio().get("https://gitee.com/linyi517/anime_trace");
      var document = parse(response.data);
      var elements = document.getElementsByClassName("tab scrolling menu")[1];
      String newVersion =
          elements.getElementsByClassName("item")[0].attributes["data-value"] ??
              "";
      // 去除前面的v
      if (newVersion.startsWith("v")) {
        newVersion = newVersion.substring(1);
      }
      debugPrint("获取到最新版本：$newVersion");
      return newVersion;
    } catch (e) {
      debugPrint(e.toString());
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return showUpdateDialog
        ? Material(
            // 透明
            color: const Color.fromRGBO(255, 255, 255, 0.5),
            child: GestureDetector(
              onTap: () {
                // 不是退出，因为并不是压入了更新对话框页面，而是作为子组件
                // Navigator.of(context).pop();
                // 不显示对话框
                showUpdateDialog = false;
                setState(() {});
              },
              child: Container(
                color: Colors.transparent, // 必须要有颜色(透明色也可)，否则无法点击
                // 不需要设置宽高
                // height: MediaQuery.of(context).size.height,
                // width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: AlertDialog(
                        title: const Text("版本更新"),
                        content:
                            Text("检测到新版本：$latestVersion\n当前版本：$currentVersion"),
                        actions: [
                          // 如果是检查更新，则不显示忽略当前版本
                          widget.forceShowUpdateDialog
                              ? Container()
                              : MaterialButton(
                                  onPressed: () {
                                    showUpdateDialog = false;
                                    SPUtil.setBool(
                                        "ignore$latestVersion", true);
                                    setState(() {});
                                  },
                                  child: const Text("忽略当前版本"),
                                ),
                          MaterialButton(
                            onPressed: () async {
                              showUpdateDialog = false;
                              setState(() {});

                              // 打开下载页面
                              Uri uri = Uri.parse(
                                  "https://gitee.com/linyi517/anime_trace");
                              if (!await launchUrl(uri,
                                  mode: LaunchMode.externalApplication)) {
                                throw "Could not launch $uri";
                              }
                            },
                            child: const Text("手动更新"),
                          ),
                          // MaterialButton(
                          //   onPressed: () {
                          //     showUpdateDialog = false;
                          //     setState(() {});
                          //   },
                          //   child: const Text("自动更新"),
                          // ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        : const Material(
            color: Colors.transparent,
          );
  }
}
