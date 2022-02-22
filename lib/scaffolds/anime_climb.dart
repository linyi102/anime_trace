import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/clime_cover_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:oktoast/oktoast.dart';

class AnimeClimb extends StatefulWidget {
  final int animeId;
  final String keyword;
  const AnimeClimb({this.animeId = 0, this.keyword = "", Key? key})
      : super(key: key);

  @override
  _AnimeClimbState createState() => _AnimeClimbState();
}

class _AnimeClimbState extends State<AnimeClimb> {
  var animeNameController = TextEditingController();
  var endEpisodeController = TextEditingController();
  FocusNode blankFocusNode = FocusNode(); // 空白焦点

  List<Anime> searchAnimes = [];
  List<Anime> addedAnimes = [];
  bool searchOk = false;
  bool searching = false;
  String addDefaultTag = tags[0];
  String lastInputName = "";

  @override
  void initState() {
    super.initState();
    // 如果传入了关键字，说明是更新封面，此时需要直接爬取
    if (widget.keyword.isNotEmpty) {
      lastInputName = widget.keyword; // 搜索关键字第一次为传入的传健字，还可以进行修改
      _climbAnime(keyword: widget.keyword);
    }
  }

  _climbAnime({String keyword = ""}) {
    debugPrint("开始爬取动漫封面");
    searching = true;
    setState(() {}); // 显示加载圈，注意会暂时导致光标移到行首
    Future(() async {
      addedAnimes = await SqliteUtil.getAnimesBySearch(widget.keyword);
      return ClimeCoverUtil.climeAllCoverUrl(keyword); // 一定要return！！！
    }).then((value) {
      searchAnimes = value;
      debugPrint("爬取结束");
      FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
      // 若某个搜索的动漫存在，则更新它
      for (int i = 0; i < searchAnimes.length; ++i) {
        int findIndex = addedAnimes.lastIndexWhere(
            (element) => element.animeName == searchAnimes[i].animeName);
        if (findIndex != -1) {
          searchAnimes[i] = addedAnimes[findIndex];
        }
      }
      // 在开头添加一个没有封面的动漫，避免搜索不到相关动漫导致添加不了
      // 因为下面更新状态时使用了lastIndexWhere来匹配动漫是否已添加，所以后面同名的动漫会先匹配上，因此该数据不受影响
      searchAnimes.insert(
          0,
          Anime(
            animeName: keyword,
            animeEpisodeCnt: 0,
            animeCoverUrl: "",
          ));

      searchOk = true;
      searching = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus:
              widget.keyword.isEmpty ? true : false, // 自动弹出键盘，如果是修改封面，则为false
          controller: animeNameController..text = lastInputName,
          decoration: InputDecoration(
              hintText: "添加动漫",
              border: InputBorder.none,
              suffixIcon: IconButton(
                  onPressed: () {
                    animeNameController.clear();
                  },
                  icon: const Icon(Icons.close, color: Colors.black))),
          onEditingComplete: () async {
            String text = animeNameController.text;
            // 如果输入的名字为空，则不再爬取
            if (text.isEmpty) {
              return;
            }
            lastInputName = text; // 更新上一次输入的名字
            _climbAnime(keyword: text);
          },
          onChanged: (inputStr) {
            lastInputName = inputStr;
            // 避免输入好后切换搜索源后，清空了输入的内容
          },
        ),
      ),
      body: Column(
        children: [
          _displayWebsiteOption(),
          searchOk
              ? Expanded(child: _displayClimbAnime())
              : searching
                  ? const Center(
                      child: RefreshProgressIndicator(),
                    )
                  : Container()
        ],
      ),
    );
  }

  _displayClimbAnime() {
    return AnimatedSwitcher(
      key: UniqueKey(), // 不一样的搜索结果也需要过渡
      duration: const Duration(milliseconds: 5000),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              SPUtil.getInt("gridColumnCnt", defaultValue: 3), // 横轴数量
          crossAxisSpacing: 5, // 横轴距离
          mainAxisSpacing: 3, // 竖轴距离
          childAspectRatio: 31 / 56, // 每个网格的比例
        ),
        itemCount: searchAnimes.length,
        itemBuilder: (BuildContext context, int index) {
          Anime anime = searchAnimes[index];
          return MaterialButton(
            onPressed: () async {
              // 若传入了关键字，说明是修改封面，而非添加动漫
              if (widget.keyword.isNotEmpty) {
                SqliteUtil.updateAnimeCoverbyAnimeId(
                    widget.animeId, anime.animeCoverUrl);
                // 提示是否修改动漫名字
                String oldAnimeName = widget.keyword; // 旧动漫名字就是传入的关键字
                String newAnimeName = anime.animeName;
                if (oldAnimeName != newAnimeName) {
                  _dialogModifyAnimeName(oldAnimeName, newAnimeName);
                } else {
                  Navigator.of(context).pop(); // 名字没有变，直接退出
                }
              } else if (anime.animeId != 0) {
                // 不为0，说明已添加，点击进入动漫详细页面
                Navigator.of(context).push(
                  // MaterialPageRoute(
                  //   builder: (context) =>
                  //       AnimeDetailPlus(anime.animeId),
                  // ),
                  FadeRoute(
                    builder: (context) {
                      return AnimeDetailPlus(anime.animeId);
                    },
                  ),
                ).then((value) async {
                  Anime retAnime = value;
                  int findIndex = searchAnimes.lastIndexWhere(
                      (element) => element.animeName == retAnime.animeName);
                  searchAnimes[findIndex] =
                      await SqliteUtil.getAnimeByAnimeId(retAnime.animeId);
                  setState(() {});
                });
              } else {
                // 其他情况才是添加动漫
                bool standBy = false;
                // 如果是备用数据，则不要使用lastIndexWhere，而是IndexWhere
                if (index == 0) standBy = true;
                _dialogAddAnime(anime, standBy);
              }
            },
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5), // 设置按钮填充
            child: Flex(
              direction: Axis.vertical,
              children: [
                Stack(
                  children: [
                    AnimeGridCover(anime),
                    _displayEpisodeState(anime),
                    _displayReviewNumber(anime),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          anime.animeName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: Platform.isAndroid
                              ? const TextStyle(fontSize: 13)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String selectedWebsite =
      SPUtil.getString("selectedWebsite", defaultValue: "樱花动漫");
  List websites = ["樱花动漫", "OmoFun"];

  _displayWebsiteOption() {
    // return ListView(
    //   children: websites
    //       .map((website) => ListTile(
    //             title: Text(website),
    //             leading: selectedWebsite == website
    //                 ? const Icon(Icons.radio_button_checked, color: Colors.blue)
    //                 : const Icon(Icons.radio_button_off),
    //             onTap: () {
    //               setState(() {
    //                 selectedWebsite = website;
    //               });
    //               SPUtil.setString("selectedWebsite", website);
    //             },
    //           ))
    //       .toList(),
    // );
    return ListTile(
      leading: const Icon(Icons.expand_more_outlined),
      title: Text(selectedWebsite),
      onTap: () {
        _dialogSelectWebsite();
      },
    );
  }

  void _dialogSelectWebsite() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < websites.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(websites[i]),
              leading: websites[i] == selectedWebsite
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                selectedWebsite = websites[i];
                SPUtil.setString("selectedWebsite", websites[i]);
                // 如果输入的文本不为空，则再次搜索
                if (lastInputName.isNotEmpty) {
                  searchOk = false;
                  searching = true;
                  searchAnimes = []; // 清空查找的动漫
                  _climbAnime(keyword: lastInputName);
                }
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('选择搜索源'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  void _dialogAddAnime(Anime anime, bool standBy) {
    var inputNameController = TextEditingController();
    var inputEndEpisodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setTagStateOnAddAnime) {
          return AlertDialog(
            title: const Text('添加动漫'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    maxLines: null,
                    autofocus: false,
                    controller: inputNameController..text = anime.animeName,
                    decoration: const InputDecoration(
                      labelText: "动漫名称",
                      border: InputBorder.none,
                    ),
                    onChanged: (onChanged) {
                      anime.animeName = onChanged;
                    },
                  ),
                  TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    controller: inputEndEpisodeController
                      ..text =
                          "${anime.animeEpisodeCnt == 0 ? 12 : anime.animeEpisodeCnt}",
                    decoration: const InputDecoration(
                      labelText: "动漫集数",
                      border: InputBorder.none,
                    ),
                    onChanged: (onChanged) {
                      // 非法(比如为空时)，返回null，则赋值为12
                      anime.animeEpisodeCnt = int.tryParse(onChanged) ?? 12;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  _dialogSelectTag(setTagStateOnAddAnime);
                },
                icon: const Icon(
                  Icons.new_label,
                  size: 26,
                  color: Colors.blue,
                ),
                label: Text(
                  addDefaultTag,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  String name = inputNameController.text;
                  if (name.isEmpty) {
                    showToast("动漫名称不能为空");
                    return;
                  }
                  String endEpisodeStr = inputEndEpisodeController.text;
                  int endEpisode = 12;
                  if (endEpisodeStr.isNotEmpty) {
                    endEpisode = int.parse(inputEndEpisodeController.text);
                  }
                  if (endEpisode > 999) {
                    showToast("集数范围：[0, 999]");
                    return;
                  }
                  Anime newAnime = Anime(
                    animeName: name,
                    animeEpisodeCnt: endEpisode,
                    tagName: addDefaultTag,
                    animeCoverUrl: anime.animeCoverUrl,
                    coverSource: selectedWebsite,
                  );
                  SqliteUtil.insertAnime(newAnime).then((lastInsertId) {
                    showToast("添加成功！");
                    // 为新添加的动漫增加集数
                    int findIndex = 0;
                    if (!standBy) {
                      // 不是备用数据，才寻找最后一次出现的数据。否则只修改备用数据的状态
                      // 数据库字段通过''转义保存'，而获取时得到的是''，因此需要转为'
                      newAnime.animeName =
                          newAnime.animeName.replaceAll("''", "'");
                      findIndex = searchAnimes.lastIndexWhere(
                          (element) => element.animeName == newAnime.animeName);
                    }
                    debugPrint("找到的动漫下标：$findIndex");
                    if (findIndex != -1) {
                      searchAnimes[findIndex] = newAnime;
                      searchAnimes[findIndex].animeId = lastInsertId;
                    } else {
                      debugPrint("未找到符合的动漫名字：${newAnime.animeName}");
                    }
                    setState(() {});
                  });

                  Navigator.pop(context);
                },
                icon: const Icon(Icons.send),
                label: const Text(""),
              ),
            ],
          );
        });
      },
    );
  }

  // 传入动漫对话框的状态，选择好标签后，就会更新该状态
  void _dialogSelectTag(setTagStateOnAddAnime) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < tags.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(tags[i]),
              leading: tags[i] == addDefaultTag
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                addDefaultTag = tags[i];
                setTagStateOnAddAnime(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('选择标签'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  _dialogModifyAnimeName(String oldAnimeName, String newAnimeName) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("修改动漫名"),
            // content: Column(
            //   children: [
            //     // Text("$oldAnimeName\n↓\n$newAnimeName"),
            //     Text(oldAnimeName),
            //     const Icon(Icons.downloading_rounded),
            //     Text(newAnimeName),
            //   ],
            // ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    leading: const Text("旧："),
                    contentPadding: const EdgeInsets.all(0),
                    title: Text(oldAnimeName),
                  ),
                  ListTile(
                    leading: const Text("新："),
                    contentPadding: const EdgeInsets.all(0),
                    title: Text(newAnimeName),
                  ),
                ],
              ),
            ),
            // 动作集合
            actions: <Widget>[
              TextButton(
                child: const Text("不修改"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("修改"),
                onPressed: () {
                  SqliteUtil.updateAnimeNameByAnimeId(
                      widget.animeId, newAnimeName);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  // // 直接跳转到动漫详细页面，否则pop只会出栈对话框，而该爬取页面仍存在。
                  // // 注意：跳转到动漫详细页面后，因为栈中没有页面，所以无法直接返回到主页
                  // Navigator.of(context).pushAndRemoveUntil(
                  //     MaterialPageRoute(
                  //         builder: (context) =>
                  //             AnimeDetailPlus(widget.animeId)),
                  //     (route) => false); // 返回false就没有左上角的返回按钮了
                },
              ),
            ],
          );
        });
  }

  _displayEpisodeState(Anime anime) {
    if (anime.animeId == 0) return Container(); // 没有id，说明未添加

    return Positioned(
        left: 5,
        top: 5,
        child: Container(
          // height: 20,
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.blue,
          ),
          child: Text(
            "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ));
  }

  _displayReviewNumber(Anime anime) {
    if (anime.animeId == 0) return Container(); // 没有id，说明未添加

    return anime.reviewNumber == 1
        ? Container()
        : Positioned(
            right: 5,
            top: 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.blue,
              ),
              child: Text(
                "${anime.reviewNumber}",
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ));
  }
}
