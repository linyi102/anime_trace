import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:expand_widget/expand_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_rating_bar.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_checklist.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_play_status.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/pages/anime_collection/db_anime_search.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/pages/anime_properties_page.dart';
import 'package:flutter_test_future/pages/anime_detail/pages/anime_rate_list_page.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/labels.dart';
import 'package:flutter_test_future/utils/common_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../widgets/icon_text_button.dart';

class AnimeDetailInfo extends StatefulWidget {
  const AnimeDetailInfo({required this.animeController, super.key});

  final AnimeController animeController;

  @override
  State<AnimeDetailInfo> createState() => _AnimeDetailInfoState();
}

class _AnimeDetailInfoState extends State<AnimeDetailInfo> {
  Anime get _anime => widget.animeController.anime;
  int rateNoteCount = 0; // 最初的评价数量
  List<String> get tags => ChecklistController.to.tags;

  @override
  void initState() {
    super.initState();
    widget.animeController.loadRateNoteCount();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AnimeController>(
      id: widget.animeController.infoId,
      init: widget.animeController,
      initState: (_) {},
      builder: (_) {
        Log.info("build ${widget.animeController.infoId}");

        return SliverPadding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SelectableText(widget.animeController.anime.animeName,
                    style: Theme.of(context).textTheme.titleLarge),
                _buildRatingStars(),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfo(),
                    _buildDesc(),
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: AnimeDetailLabels(
                            animeController: widget.animeController)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _genIcons,
                      ),
                    )
                  ],
                ),
              ]),
            ));
      },
    );
  }

  _buildDesc() {
    if (widget.animeController.anime.animeDesc.isNotEmpty &&
        widget.animeController.showDescInAnimeDetailPage.value) {
      var desc = widget.animeController.anime.animeDesc;
      var textStyle = Theme.of(context).textTheme.bodySmall;

      return widget.animeController.isCollected
          ? ExpandText(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              expandWidth: true, // 为false时，若简介每行(换行符分隔)都不足一行，则会居中。则只会true则不会
              // indicatorIconSize: 20,
              // indicatorExpandedHint: "展开",
              // indicatorCollapsedHint: "收缩",
              indicatorIconSize: 20,
              indicatorCollapsedHint: "展开",
              indicatorExpandedHint: "收缩",
            )
          // 如果没有收藏，这不折叠简介
          : Text(desc, style: textStyle);
    } else {
      return Container();
    }
  }

  // 构建评分栏
  _buildRatingStars() {
    return AnimeRatingBar(
        enableRate: widget.animeController.isCollected, // 未收藏时不能评分
        rate: _anime.rate,
        onRatingUpdate: (v) {
          Log.info("评价分数：$v");
          _anime.rate = v.toInt();
          AnimeDao.updateAnimeRate(_anime.animeId, _anime.rate);
        });
  }

  // 显示信息按钮，点击后进入动漫属性信息页
  _buildInfoIcon() {
    return _buildIconTextButton(
      iconData: MingCuteIcons.mgc_information_line,
      text: '信息',
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                AnimePropertiesPage(animeController: widget.animeController)));
      },
    );
  }

  // 显示评价按钮，点击后进入评价列表页
  _buildRateIcon() {
    return GetBuilder<AnimeController>(
      id: widget.animeController.rateNoteCountId,
      init: widget.animeController,
      initState: (_) {},
      builder: (_) {
        return _buildIconTextButton(
          iconData: MingCuteIcons.mgc_chat_1_line,
          text: "${widget.animeController.rateNoteCount}条评价",
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) => AnimeRateListPage(_anime)))
                .then((value) async {
              // 更新评价数量
              widget.animeController.loadRateNoteCount();
            });
          },
        );
      },
    );
  }

  List<Widget> get _genIcons {
    return [
      _buildCollectIcon(),
      if (widget.animeController.isCollected) _buildRateIcon(),
      if (widget.animeController.isCollected) _buildInfoIcon(),
      _buildSearchBtn(),
      // if (widget.animeController.isCollected)
      //   _buildIconTextButton(
      //       iconData: Icons.checklist, text: '系列', onTap: () {})
    ];
  }

  _buildIconTextButton({
    required IconData iconData,
    Color? iconColor,
    required String text,
    required void Function() onTap,
  }) {
    return IconTextButton(
      text: Text(text, style: const TextStyle(fontSize: 12)),
      iconData: iconData,
      iconColor: iconColor,
      onTap: onTap,
      radius: 99,
      iconSize: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      margin: EdgeInsets.zero,
    );
  }

  // 显示收藏按钮，点击后可以修改清单
  _buildCollectIcon() {
    return _buildIconTextButton(
      iconData: _anime.isCollected()
          ? MingCuteIcons.mgc_heart_fill
          : MingCuteIcons.mgc_heart_line,
      iconColor: _anime.isCollected() ? Colors.red : null,
      text: _anime.isCollected() ? _anime.tagName : "收藏",
      onTap: () {
        if (_anime.isCollected()) {
          // 修改清单
          _dialogSelectTag();
        } else {
          // 添加清单
          dialogSelectChecklist(setState, context, _anime,
              onlyShowChecklist: true,
              enableClimbDetailInfo: false, callback: (newAnime) {
            widget.animeController.updateAnime(newAnime);
            widget.animeController.loadEpisode();
          });
        }
      },
    );
  }

  _buildSearchBtn() {
    return _buildIconTextButton(
      iconData: MingCuteIcons.mgc_search_line,
      text: '搜索',
      onTap: () {
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => SearchDbAnime(
        //         kw: _anime.animeName,
        //       ),
        //     )).then((value) {
        //   // 可能在搜索内部添加该动漫了，因此需要重新获取动漫信息
        //   // 当前仍存在问题，所以改用pushreplacement
        //   // widget.animeController.loadAnime(_anime);
        // });

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => DbAnimeSearchPage(kw: _anime.animeName)),
            result: _anime);
      },
    );
  }

  // SizedBox _buildAddBtn() {
  //   return SizedBox(
  //     height: 40,
  //     width: 80,
  //     child: MaterialButton(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(50),
  //         ),
  //         onPressed: () {
  //           dialogSelectChecklist(setState, context, _anime,
  //               onlyShowChecklist: true,
  //               enableClimbDetailInfo: false, callback: (newAnime) {
  //             widget.animeController.updateAnime(newAnime);
  //             widget.animeController.loadEpisode();
  //           });
  //         },
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: const [
  //             Icon(Icons.favorite_border, size: 18),
  //             SizedBox(width: 5),
  //             Text("收藏"),
  //           ],
  //         )),
  //   );
  // }

  _buildInfo() {
    const double smallIconSize = 14;
    const double textScaleFactor = 1;

    // 迁移后信息会变化，所以使用obx监听
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 因为动漫未收藏时显示的收藏按钮撑高整个Row
            // 而收藏后，三个按钮会撑高一些，导致收藏后信息行位置变了，所以在上下添加10高度box
            const SizedBox(height: 10),
            if (_anime.getAnimeInfoFirstLine().isNotEmpty)
              // 第一行信息
              Text.rich(
                TextSpan(children: [
                  WidgetSpan(
                    child: Text(_anime.getAnimeInfoFirstLine()),
                  ),
                ]),
                textScaleFactor: textScaleFactor,
              ),
            // 第二行信息
            Text.rich(
              TextSpan(children: [
                WidgetSpan(
                    child: GestureDetector(
                  // 短按打开网址，长按复制到剪切板
                  onTap: () {
                    if (_anime.animeUrl.isNotEmpty) {
                      LaunchUrlUtil.launch(
                          context: context, uriStr: _anime.animeUrl);
                    } else {
                      ToastUtil.showText("无法打开空的链接");
                    }
                  },
                  onLongPress: () {
                    if (_anime.animeUrl.isNotEmpty) {
                      CommonUtil.copyContent(_anime.animeUrl,
                          successMsg: "链接已复制到剪切板");
                    }
                  },
                  child: Row(
                    children: [
                      Text(_anime.getAnimeSource()),
                      const Icon(EvaIcons.externalLink, size: smallIconSize),
                    ],
                  ),
                )),
                // const WidgetSpan(child: Text(" • ")),
                const WidgetSpan(child: Text(" ")),
                WidgetSpan(
                    child: GestureDetector(
                  onTap: () {
                    if (widget.animeController.isCollected) {
                      showDialogSelectPlayStatus(
                          context, widget.animeController);
                    }
                  },
                  // 这里使用animeController里的anime，而不是_anime，否则修改状态后没有变化
                  child: Row(
                    children: [
                      Text(widget.animeController.anime.getPlayStatus().text),
                      Icon(
                          widget.animeController.anime.getPlayStatus().iconData,
                          size: smallIconSize),
                    ],
                  ),
                )),
                // const WidgetSpan(child: Text(" • ")),
                const WidgetSpan(child: Text(" ")),
                WidgetSpan(
                    child: GestureDetector(
                  onTap: () {
                    if (widget.animeController.isCollected) {
                      showDialogmodifyEpisodeCnt();
                    }
                  },
                  child: Row(
                    children: [
                      Text("${_anime.animeEpisodeCnt}集"),
                      const Icon(MingCuteIcons.mgc_edit_3_line,
                          size: smallIconSize),
                    ],
                  ),
                )),
              ]),
              textScaleFactor: textScaleFactor,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ],
    );
  }

  void showDialogmodifyEpisodeCnt() {
    dialogSelectUint(context, "集数",
            initialValue: _anime.animeEpisodeCnt,
            // 传入已有的集长度而非_anime.animeEpisodeCnt，是为了避免更新动漫后，_anime.animeEpisodeCnt为0，然后点击修改集数按钮，弹出对话框，传入初始值0，如果点击了取消，就会返回初始值0，导致集数改变
            // initialValue: initialValue,
            // 添加选择集范围后，就不能传入已有的集长度了。
            // 最终解决方法就是当爬取的集数小于当前集数，则不进行修改，所以这里只管传入当前动漫的集数
            minValue: 0,
            maxValue: 2000)
        .then((value) {
      if (value == null) {
        Log.info("未选择，直接返回");
        return;
      }
      // if (value == _episodes.length) {
      if (value == _anime.animeEpisodeCnt) {
        Log.info("设置的集数等于初始值${_anime.animeEpisodeCnt}，直接返回");
        return;
      }
      int episodeCnt = value;
      AnimeDao.updateEpisodeCntByAnimeId(_anime.animeId, episodeCnt)
          .then((value) {
        // 修改数据
        _anime.animeEpisodeCnt = episodeCnt;
        // 重绘
        widget.animeController.updateAnimeInfo(); // 重绘信息行中显示的集数
        widget.animeController.loadEpisode(); // 重绘集信息
      });
    });
  }

  void _dialogSelectTag() {
    showModalBottomSheet(
        context: context,
        builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text("选择清单"),
                centerTitle: true,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              body: ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(tags[index]),
                    leading: tags[index] == _anime.tagName
                        ? Icon(
                            Icons.radio_button_on_outlined,
                            color: Theme.of(context).primaryColor,
                          )
                        : const Icon(
                            Icons.radio_button_off_outlined,
                          ),
                    onTap: () {
                      _anime.tagName = tags[index];
                      AnimeDao.updateTagByAnimeId(
                          _anime.animeId, _anime.tagName);
                      Log.info("修改清单为${_anime.tagName}");
                      setState(() {});
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ));
  }
}
