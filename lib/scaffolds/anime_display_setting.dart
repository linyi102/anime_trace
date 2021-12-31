import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:oktoast/oktoast.dart';

class AnimesDisplaySetting extends StatefulWidget {
  const AnimesDisplaySetting({Key? key}) : super(key: key);

  @override
  _AnimesDisplaySettingState createState() => _AnimesDisplaySettingState();
}

class _AnimesDisplaySettingState extends State<AnimesDisplaySetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "动漫界面",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
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
          )
        ],
      ),
    );
  }
}
