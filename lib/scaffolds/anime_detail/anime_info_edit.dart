import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../classes/anime.dart';
import '../../components/anime_grid_cover.dart';

class AnimeInfoEdit extends StatefulWidget {
  final Anime anime;

  const AnimeInfoEdit(this.anime, {Key? key}) : super(key: key);

  @override
  State<AnimeInfoEdit> createState() => _AnimeInfoEditState();
}

class _AnimeInfoEditState extends State<AnimeInfoEdit> {
  late Anime _anime;
  bool loadOk = false;

  @override
  void initState() {
    super.initState();
    _anime = widget.anime.copy(); // 一定要拷贝，否则修改后不提交而直接返回到详细页面也会看到有变化
    loadOk = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = Image.network(_anime.animeCoverUrl).image;
    var nameController = TextEditingController();
    var nameAnotherController = TextEditingController();
    var nameOriController = TextEditingController();
    var authorOriController = TextEditingController();
    var animeUrlController = TextEditingController();
    var descController = TextEditingController();
    var officialSiteController = TextEditingController();
    var productionCompanyController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "编辑信息",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: loadOk
          ? ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      padding: const EdgeInsets.only(left: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: MaterialButton(
                          padding: const EdgeInsets.all(0),
                          onPressed: () {
                            // 没有封面时，直接返回
                            if (_anime.animeCoverUrl.isEmpty) return;

                            showImageViewer(context, imageProvider,
                                immersive: false);
                          },
                          child: AnimeGridCover(_anime),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 地区、类型、播放状态 提供选择
                        Row(
                          children: [
                            const Text("类别："),
                            DropdownButton(
                                items: _getCategoryDropdownMenuItems(),
                                onChanged: (val) {},
                                hint: Text(_anime.category)),
                            const Text("播放状态："),
                            DropdownButton(
                                items: _getPlayStatusDropdownMenuItems(),
                                onChanged: (val) {},
                                hint: Text(_anime.playStatus)),
                          ],
                        ),

                        Row(
                          children: [
                            const Text("地区："),
                            DropdownButton(
                                items: _getAreaDropdownMenuItems(),
                                onChanged: (val) {},
                                hint: Text(_anime.area)),
                            const Text("首播时间："),
                            TextButton(
                                onPressed: () async {
                                  DateTime dateTime;
                                  try {
                                    dateTime =
                                        DateTime.parse(_anime.premiereTime);
                                  } catch (e) {
                                    dateTime = DateTime.now();
                                  }

                                  var picker = await showDatePicker(
                                      context: context,
                                      initialDate: dateTime,
                                      // 没有给默认时间时，设置为今天
                                      firstDate: DateTime(1986),
                                      lastDate:
                                          DateTime(DateTime.now().year + 100),
                                      locale: const Locale("zh"));
                                  if (picker != null) {
                                    _anime.premiereTime = picker.toString();
                                    setState(() {});
                                  }
                                },
                                child: Text(_anime.premiereTime.isEmpty
                                    ? "未知"
                                    : TimeShowUtil.getShowDateStr(
                                        _anime.premiereTime,
                                        isSlash: false))),
                          ],
                        ),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: TextField(
                        //         controller: animeUrlController..text = _anime.animeUrl,
                        //         decoration: const InputDecoration(labelText: "封面地址"),
                        //       ),
                        //     )
                        //   ],
                        // )
                        Row(
                          children: [
                            const Text("封面修改："),
                            ElevatedButton(
                                onPressed: () {},
                                child: const Text("从本地图库中选择")),
                            const SizedBox(width: 10),
                            ElevatedButton(
                                onPressed: () {}, child: const Text("提供封面链接"))
                          ],
                        )
                      ],
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TextField(
                    controller: nameController..text = _anime.animeName,
                    decoration: const InputDecoration(labelText: "动漫名"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TextField(
                    controller: nameAnotherController
                      ..text = _anime.nameAnother,
                    decoration: const InputDecoration(labelText: "别名"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TextField(
                    controller: nameOriController..text = _anime.nameOri,
                    decoration: const InputDecoration(labelText: "原作名"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TextField(
                    controller: authorOriController..text = _anime.authorOri,
                    decoration: const InputDecoration(labelText: "原作者"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TextField(
                    controller: descController..text = _anime.animeDesc,
                    decoration: const InputDecoration(labelText: "描述"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TextField(
                    controller: officialSiteController
                      ..text = _anime.officialSite,
                    decoration: const InputDecoration(labelText: "官网"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TextField(
                    controller: productionCompanyController
                      ..text = _anime.productionCompany,
                    decoration: const InputDecoration(labelText: "制作公司"),
                  ),
                ),
              ],
            )
          : Container(),
    );
  }

  _getAreaDropdownMenuItems() {
    List<String> areas = ["中国", "日本", "欧美"];
    // List<DropdownMenuItem<Object>> items = [];
    // for (int i = 0; i < areas.length; ++i) {
    //   items.add(DropdownMenuItem(
    //       child: Text(areas[i]),
    //       value: i, // 必须要有val
    //       onTap: () {
    //         _anime.area = areas[i];
    //         setState(() {});
    //       }));
    // }
    // return items;
    return areas
        .map((e) => DropdownMenuItem(
            child: Text(e),
            value: 0, // 必须要加上value，但因为没用到这个值，所以可以设置一样的
            onTap: () {
              _anime.area = e;
              setState(() {});
            }))
        .toList();
  }

  List<DropdownMenuItem<Object>> _getPlayStatusDropdownMenuItems() {
    List<String> playStatuses = ["未播放", "连载中", "已完结"];
    return playStatuses
        .map((e) => DropdownMenuItem<Object>(
            child: Text(e),
            value: 0,
            onTap: () {
              _anime.playStatus = e;
              setState(() {});
            }))
        .toList();
  }

  List<DropdownMenuItem<Object>> _getCategoryDropdownMenuItems() {
    List<String> categories = ["TV", "OVA", "剧场版"];
    return categories
        .map((e) => DropdownMenuItem<Object>(
            child: Text(e),
            value: 0,
            onTap: () {
              _anime.category = e;
              setState(() {});
            }))
        .toList();
  }
}
