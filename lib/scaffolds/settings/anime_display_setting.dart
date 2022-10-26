import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/controllers/anime_display_controller.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

class AnimesDisplaySetting extends StatelessWidget {
  final showAppBar;

  const AnimesDisplaySetting({Key? key, this.showAppBar = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AnimeDisplayController animeDisplayController = Get.find();

    return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: const Text("动漫界面",
                    style: TextStyle(fontWeight: FontWeight.w600)))
            : null,
        body: Obx(
          () => ListView(
            children: [
              ListTile(
                title: animeDisplayController.displayList.value
                    ? const Text("列表样式")
                    : const Text("网格样式"),
                subtitle: const Text("单击切换列表样式/网格样式"),
                onTap: () {
                  animeDisplayController.turnDisplayList();
                },
              ),
              SPUtil.getBool("display_list")
                  ? Container()
                  : ListTile(
                      title: const Text("修改动漫列数"),
                      subtitle: Text("${animeDisplayController.gridColumnCnt}"),
                      onTap: () {
                        dialogSelectUint(context, "选择列数",
                                initialValue:
                                    animeDisplayController.gridColumnCnt.value,
                                minValue: 1,
                                maxValue: 10)
                            .then((value) {
                          if (value == null) {
                            debugPrint("未选择，直接返回");
                            return;
                          }
                          animeDisplayController.setGridColumnCnt(value);
                        });
                      },
                    ),
              SPUtil.getBool("display_list")
                  ? Container()
                  : ListTile(
                      title: const Text("是否显示动漫名称"),
                      subtitle: Text(
                          animeDisplayController.hideGridAnimeName.value
                              ? "隐藏"
                              : "显示"),
                      onTap: () {
                        animeDisplayController.turnHideGridAnimeName();
                      },
                    ),
              SPUtil.getBool("display_list")
                  ? Container()
                  : ListTile(
                      title: const Text("是否显示动漫进度"),
                      subtitle: Text(
                          animeDisplayController.hideGridAnimeProgress.value
                              ? "隐藏"
                              : "显示"),
                      onTap: () {
                        animeDisplayController.turnHideGridAnimeProgress();
                      },
                    ),
              ListTile(
                title: const Text("是否显示动漫第几次观看"),
                subtitle: Text(animeDisplayController.hideReviewNumber.value
                    ? "隐藏"
                    : "显示"),
                onTap: () {
                  animeDisplayController.turnHideReviewNumber();
                },
              ),
            ],
          ),
        ));
  }
}
