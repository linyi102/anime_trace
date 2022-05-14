import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:oktoast/oktoast.dart';

class AnimesDisplaySetting extends StatefulWidget {
  const AnimesDisplaySetting({Key? key}) : super(key: key);

  @override
  _AnimesDisplaySettingState createState() => _AnimesDisplaySettingState();
}

class _AnimesDisplaySettingState extends State<AnimesDisplaySetting> {
  int gridColumnCnt = SPUtil.getInt("gridColumnCnt", defaultValue: 3);
  bool hideGridAnimeName = SPUtil.getBool("hideGridAnimeName");
  bool hideGridAnimeProgress = SPUtil.getBool("hideGridAnimeProgress");
  bool hideReviewNumber = SPUtil.getBool("hideReviewNumber");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "动漫界面",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: SPUtil.getBool("display_list")
                ? const Text("列表样式")
                : const Text("网格样式"),
            subtitle: const Text("单击切换列表样式/网格样式"),
            onTap: () {
              if (SPUtil.getBool("display_list")) {
                SPUtil.setBool("display_list", false);
                showToast("已设置为网格样式");
              } else {
                SPUtil.setBool("display_list", true);
                showToast("已设置为列表样式");
              }
              setState(() {});
            },
          ),
          SPUtil.getBool("display_list")
              ? Container()
              : ListTile(
                  title: const Text("修改动漫列数"),
                  subtitle: Text("$gridColumnCnt"),
                  onTap: () {
                    dialogSelectUint(context, "选择列数",
                            initialValue: gridColumnCnt,
                            minValue: 1,
                            maxValue: 10)
                        .then((value) {
                      if (value == null) {
                        debugPrint("未选择，直接返回");
                        return;
                      }
                      gridColumnCnt = value;
                      SPUtil.setInt("gridColumnCnt", gridColumnCnt);
                      setState(() {});
                    });
                  },
                ),
          SPUtil.getBool("display_list")
              ? Container()
              : ListTile(
                  title: const Text("是否显示动漫名称"),
                  subtitle: Text(hideGridAnimeName ? "隐藏" : "显示"),
                  onTap: () {
                    if (hideGridAnimeName) {
                      SPUtil.setBool("hideGridAnimeName", false);
                    } else {
                      SPUtil.setBool("hideGridAnimeName", true);
                    }
                    hideGridAnimeName = SPUtil.getBool("hideGridAnimeName");
                    setState(() {});
                  },
                ),
          SPUtil.getBool("display_list")
              ? Container()
              : ListTile(
                  title: const Text("是否显示动漫进度"),
                  subtitle: Text(hideGridAnimeProgress ? "隐藏" : "显示"),
                  onTap: () {
                    if (hideGridAnimeProgress) {
                      SPUtil.setBool("hideGridAnimeProgress", false);
                    } else {
                      SPUtil.setBool("hideGridAnimeProgress", true);
                    }
                    hideGridAnimeProgress =
                        SPUtil.getBool("hideGridAnimeProgress");
                    setState(() {});
                  },
                ),
          ListTile(
            title: const Text("是否显示动漫第几次观看"),
            subtitle: Text(hideReviewNumber ? "隐藏" : "显示"),
            onTap: () {
              if (hideReviewNumber) {
                SPUtil.setBool("hideReviewNumber", false);
              } else {
                SPUtil.setBool("hideReviewNumber", true);
              }
              hideReviewNumber = SPUtil.getBool("hideReviewNumber");
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
