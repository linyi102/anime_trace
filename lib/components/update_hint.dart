import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/latest_version_info.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 更新对话框组件，用于Stack最高层
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
  LatestVersionInfo latestVersionInfo = LatestVersionInfo("");

  @override
  void initState() {
    super.initState();
    debugPrint(widget.checkLatestVersion.toString());
    if (widget.checkLatestVersion) {
      // _checkNewVersion();
      _getLatestVersionInfo();
    }
  }

  _getLatestVersionInfo() async {
    currentVersion = (await PackageInfo.fromPlatform()).version;
    // 获取最新版本信息
    try {
      debugPrint("正在获取最新版本信息...");
      var response =
          await Dio().get("https://gitee.com/linyi517/anime_trace/tags");
      var document = parse(response.data);
      latestVersionInfo.version = document
              .getElementsByClassName("tag-item-action tag-name")[0]
              .getElementsByTagName("a")[0]
              .attributes["title"] ??
          "";
      if (latestVersionInfo.version.isEmpty) {
        debugPrint("获取新版本为空，直接返回");
        return;
      }
      // 去除前面的v
      if (latestVersionInfo.version.startsWith("v")) {
        latestVersionInfo.version = latestVersionInfo.version.substring(1);
      }

      latestVersionInfo.desc = document
          .getElementsByClassName("tag-item-action tag-message")[0]
          .innerHtml;
      // 格式化：将"- "转为有序列表
      for (var i = 1; latestVersionInfo.desc.contains("- "); ++i) {
        latestVersionInfo.desc =
            latestVersionInfo.desc.replaceFirst("- ", "\n$i. ");
        if (i == 10) break;
      }
      // 去除两边的空白符
      latestVersionInfo.desc = latestVersionInfo.desc.trim();
      debugPrint("获取到最新版本：$latestVersionInfo");
    } catch (e) {
      debugPrint(e.toString());
    }

    // latestVersionInfo.version = "9.99";
    // compareTo：如果当前版本排在最新版本前面(当前版本<最新版本)，则会返回负数
    if (currentVersion.compareTo(latestVersionInfo.version) < 0) {
      foundNewVersion = true;
      // 如果忽略了该最新版本，则不进行更新提示
      if (SPUtil.getBool("ignore${latestVersionInfo.version}") == true) {
        showUpdateDialog = false;
        debugPrint("已忽略更新版本：${latestVersionInfo.version}");
      } else {
        showUpdateDialog = true;
      }
      // 如果是点击了关于版本中的检查更新，则如果有新版本，就显示更新对话框(及时之前忽略了新版本的更新)
      if (widget.forceShowUpdateDialog) {
        showUpdateDialog = true;
      }
      debugPrint("当前版本：$currentVersion，最新版本：${latestVersionInfo.version}");
      // 显示对话框
      setState(() {});
    } else {
      // 在关于版本页面中点击检查更新后，如果版本一致，则进行提示
      if (widget.forceShowUpdateDialog) {
        showToast("当前已是最新版本");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: showUpdateDialog
          ? WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: Material(
                // 透明
                color: const Color.fromRGBO(100, 100, 100, 0.3),
                child: Container(
                  color: Colors.transparent, // 必须要有颜色(透明色也可)，否则无法点击
                  // 不需要设置宽高
                  // height: MediaQuery.of(context).size.height,
                  // width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AlertDialog(
                        title: const Text("更新"),
                        content: Text(
                            "检测到新版本：${latestVersionInfo.version}\n当前版本：$currentVersion\n更新内容：\n${latestVersionInfo.desc}"),
                        actions: [
                          // 手动检查更新时，不显示忽略当前版本
                          widget.forceShowUpdateDialog
                              ? const SizedBox.shrink()
                              : TextButton(
                                  onPressed: () {
                                    showUpdateDialog = false;
                                    SPUtil.setBool(
                                        "ignore${latestVersionInfo.version}",
                                        true);
                                    setState(() {});
                                  },
                                  child: const Text("忽略"),
                                ),
                          TextButton(
                            onPressed: () {
                              // 不是退出，因为并不是压入了更新对话框页面，而是作为子组件
                              // Navigator.of(context).pop();
                              // 不显示对话框
                              showUpdateDialog = false;
                              setState(() {});
                            },
                            child: const Text("关闭"),
                          ),

                          ElevatedButton(
                            onPressed: () async {
                              showUpdateDialog = false;
                              setState(() {});

                              // 打开下载页面
                              LaunchUrlUtil.launch(
                                  "https://gitee.com/linyi517/anime_trace");
                            },
                            child: const Text("手动更新"),
                          ),
                          // TextButton(
                          //   onPressed: () {
                          //     showUpdateDialog = false;
                          //     setState(() {});
                          //   },
                          //   child: const Text("自动更新"),
                          // ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          : const Material(
              color: Colors.transparent,
            ),
    );
  }
}
