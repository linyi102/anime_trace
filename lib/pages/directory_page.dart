import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/select_tag_dialog.dart';
import 'package:flutter_test_future/components/select_uint_dialog.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_climb_all_website.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/climb_anime_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({Key? key}) : super(key: key);

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  bool _loadOk = false;

  @override
  void initState() {
    super.initState();
    if (directory.isEmpty) {
      _loadData();
    } else {
      // 如果已有数据，则直接显示，但也要根据重新查询数据库中的动漫来替换
      _replaceDbAnimes();
    }
  }

  void _replaceDbAnimes() async {
    // 即使查询过了，也需要查询数据库中的动漫，因为可能会已经取消收藏了
    for (int i = 0; i < directory.length; ++i) {
      directory[i] = await SqliteUtil.getAnimeByAnimeUrl(directory[i]);
    }
    _loadOk = true;
    setState(() {});
  }

  void _loadData() {
    setState(() {
      _loadOk = false;
    });
    Future(() async {
      directory = await ClimbAnimeUtil.climbDirectory(filter);
    }).then((value) async {
      debugPrint("目录页：数据获取完毕");
      // 根据动漫名和来源查询动漫，如果存在
      // 则获取到id(用于进入详细页)和tagName(用于修改tag)
      // 下面两种方式修改了anime，都不能修改数组中的值
      // 1. for (var anime in directory) {
      // 2. for (int i = 0; i < directory.length; ++i) {
      //   Anime anime = directory[i];
      for (int i = 0; i < directory.length; ++i) {
        directory[i] = await SqliteUtil.getAnimeByAnimeUrl(directory[i]);
      }
      _loadOk = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "目录",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(FadeRoute(
                builder: (context) {
                  return const AnimeClimbAllWebsite();
                },
              )).then((value) {
                // 搜索后添加了动漫，可能就在目录里
                _replaceDbAnimes();
              });
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    // 多加一个StatefulBuilder，然后调用其中的setState才能更新对话框
                    return StatefulBuilder(
                        builder: (BuildContext context, setState) {
                      // map方式
                      List<Widget> buildListTiles = climbWebsites.map((e) {
                        return ListTile(
                          title: Text(e.name),
                          trailing: e.enable
                              ? const Icon(Icons.check_box, color: Colors.blue)
                              : const Icon(Icons.check_box_outline_blank),
                          // 带缩放动画的开关图标
                          // trailing: AnimatedSwitcher(
                          //   duration: const Duration(milliseconds: 200),
                          //   transitionBuilder:
                          //       (Widget child, Animation<double> animation) {
                          //     return ScaleTransition(
                          //         child: child, scale: animation); // 缩放
                          //   },
                          //   child: e.enable
                          //       ? Icon(Icons.check_box,
                          //           key: Key(e.enable.toString()), // 不能用Unique()，否则会影响其他ListTile中的图标
                          //           color: Colors.blue)
                          //       : Icon(Icons.check_box_outline_blank,
                          //           key: Key(e.enable.toString())),
                          // ),
                          onTap: () {
                            e.enable = !e.enable;
                            setState(() {}); // 使用的是StatefulBuilder的setState
                            // 保存
                            SPUtil.setBool(e.spkey, e.enable);
                          },
                        );
                      }).toList();

                      return AlertDialog(
                          title: const Text("启用搜索源"),
                          content: SingleChildScrollView(
                            child: Column(
                              children: buildListTiles,
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("关闭"))
                          ]);
                    });
                  } // for方式

                  );
            },
            icon: const Icon(Icons.extension_outlined),
          ),
        ],
      ),
      body: _showBody(),
    );
  }

  _showBody() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: Scrollbar(
        child: ListView(
          children: [
            _showFilter(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _loadOk
                  ? _showAnimeList()
                  : Container(
                      // padding和_showAnimeList()里的暂无数据保持一致，否则没有数据时，「暂无数据」会突然往上移动
                      padding: const EdgeInsets.only(top: 25),
                      child: Center(
                        key: UniqueKey(),
                        child: const RefreshProgressIndicator(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _expandFilter = false;
  _showFilter() {
    return ExpansionPanelList(
        elevation: 1,
        expansionCallback: (panelIndex, isExpanded) {
          setState(() {
            _expandFilter = !isExpanded;
          });
        },
        animationDuration: kThemeAnimationDuration,
        children: <ExpansionPanel>[
          ExpansionPanel(
            headerBuilder: (context, isExpanded) {
              return ListTile(
                title: _expandFilter ? const Text("隐藏过滤") : const Text("展开过滤"),
                visualDensity: const VisualDensity(vertical: -4),
              );
            },
            isExpanded: _expandFilter,
            canTapOnHeader: true,
            body: ListView(
              shrinkWrap: true, //解决无限高度问题
              physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  child: SizedBox(
                    // 给出高度才可以横向排列
                    height: 30,
                    child: Row(
                      children: [
                        GestureDetector(
                          child: const Text("年份："),
                          onTap: () {
                            int defaultYear = filter.year.isEmpty
                                ? DateTime.now().year
                                : int.parse(filter.year);
                            dialogSelectUint(context, "选择年份",
                                    minValue: 2000,
                                    maxValue: DateTime.now().year + 2,
                                    initialValue: defaultYear)
                                .then((value) {
                              if (value == null ||
                                  value == 0 ||
                                  value == defaultYear) {
                                debugPrint("未选择，直接返回");
                                return;
                              }
                              debugPrint("选择了$value");
                              filter.year = value.toString();
                              _loadData();
                            });
                          },
                        ),
                        // Row嵌套ListView，需要使用Expanded嵌套ListView
                        Expanded(
                          child: ListView(
                            // 横向滚动
                            scrollDirection: Axis.horizontal,
                            children: _showRadioYear(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        const Text("季度："),
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _showRadioSeason(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        const Text("地区："),
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _showRadioRegion(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        const Text("状态："),
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _showRadioStatus(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        const Text("类型："),
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _showRadioCategory(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                )
              ],
            ),
          )
        ]);
  }

  _showRadioYear() {
    List<Widget> children = [];

    List<String> years = [""]; // 空字符串对应全部
    // groupValue(filter.year)对应选中的value
    int endYear = DateTime.now().year + 2;
    for (int year = endYear; year >= 2000; --year) {
      years.add("$year"); // 转为字符串
    }

    for (var i = 0; i < years.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: years[i],
              groupValue: filter.year,
              onChanged: (value) {
                filter.year = value.toString();

                // debugPrint(filter.year);
                _loadData();
              }),
          Text(i == 0 ? "全部" : (i == years.length - 1 ? "2000以前" : years[i]))
        ],
      ));
    }
    return children;
  }

  _showRadioSeason() {
    List<Widget> children = [];

    var seasons = ["", "1", "4", "7", "10"];
    for (var i = 0; i < seasons.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: seasons[i],
              groupValue: filter.season,
              onChanged: (value) {
                filter.season = value.toString();
                // debugPrint(filter.season);
                _loadData();
              }),
          Text(i == 0 ? "全部" : "${seasons[i]} 月")
        ],
      ));
    }
    return children;
  }

  _showRadioRegion() {
    List<Widget> children = [];

    var regions = ["", "日本", "中国", "欧美"];
    for (var i = 0; i < regions.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: regions[i],
              groupValue: filter.region,
              onChanged: (value) {
                filter.region = value.toString();
                _loadData();
              }),
          Text(i == 0 ? "全部" : regions[i])
        ],
      ));
    }
    return children;
  }

  _showRadioStatus() {
    List<Widget> children = [];

    var statuss = ["", "连载", "完结", "未播放"];
    for (var i = 0; i < statuss.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: statuss[i],
              groupValue: filter.status,
              onChanged: (value) {
                filter.status = value.toString();
                _loadData();
              }),
          Text(i == 0 ? "全部" : statuss[i])
        ],
      ));
    }
    return children;
  }

  _showRadioCategory() {
    List<Widget> children = [];

    var categorys = ["", "TV", "剧场版", "OVA"];
    for (var i = 0; i < categorys.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: categorys[i],
              groupValue: filter.category,
              onChanged: (value) {
                filter.category = value.toString();
                _loadData();
              }),
          Text(i == 0 ? "全部" : categorys[i])
        ],
      ));
    }
    return children;
  }

  _showAnimeList() {
    return directory.isEmpty
        ? Container(
            padding: const EdgeInsets.only(top: 25),
            child: const Text("暂无数据"),
          )
        : ListView.builder(
            shrinkWrap: true, //解决无限高度问题
            physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
            itemCount: directory.length,
            itemBuilder: (BuildContext context, int index) {
              Anime anime = directory[index];
              final imageProvider = Image.network(anime.animeCoverUrl).image;
              return MaterialButton(
                padding: const EdgeInsets.all(0),
                onPressed: () {
                  debugPrint("单击");
                  // 如果收藏了，则单击进入详细页面
                  if (anime.isCollected()) {
                    Navigator.of(context).push(FadeRoute(builder: (context) {
                      return AnimeDetailPlus(anime.animeId);
                    })).then((value) {
                      setState(() {
                        // anime = value;
                        directory[index] = value;
                      });
                    });
                  }
                },
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
                      child: SizedBox(
                        width: 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: MaterialButton(
                            padding: const EdgeInsets.all(0),
                            onPressed: () {
                              showImageViewer(context, imageProvider,
                                  immersive: false);
                            },
                            child: AnimeGridCover(anime),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          // 不要和动漫详细页里的复用，因为这里的不应该可以复制文字
                          _showAnimeName(anime.animeName),
                          _showNameAnother(anime.nameAnother),
                          _showAnimeInfo(anime.getAnimeInfoFirstLine()),
                          _showAnimeInfo(anime.getAnimeInfoSecondLine()),
                          // _showSource(
                          //     ClimbAnimeUtil.getSourceByAnimeUrl(anime.animeUrl)),
                          // _displayDesc(),
                        ],
                      ),
                    ),
                    _showCollectIcon(anime)
                  ],
                ),
              );
            },
          );
  }

  _showAnimeName(animeName) {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      child: Text(
        animeName,
        textScaleFactor: 1.1,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  _showNameAnother(String nameAnother) {
    return nameAnother.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
            child: Text(
              nameAnother,
              style: const TextStyle(color: Colors.black54, height: 1.1),
              overflow: TextOverflow.ellipsis,
            ),
          );
  }

  _showAnimeInfo(String animeInfo) {
    return animeInfo.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
            child: Text(
              animeInfo,
              style: const TextStyle(color: Colors.black54, height: 1.1),
              overflow: TextOverflow.ellipsis,
            ),
          );
  }

  _showSource(coverSource) {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
      child: Text(
        coverSource,
        style: const TextStyle(color: Colors.black54, height: 1.1),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  _showCollectIcon(Anime anime) {
    return Container(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          IconButton(
              onPressed: () {
                dialogSelectTag(setState, context, anime);
              },
              icon: anime.isCollected()
                  ? const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    )
                  : const Icon(Icons.favorite_border)),
          anime.isCollected() ? Text(anime.tagName) : Container()
        ],
      ),
    );
  }
}
