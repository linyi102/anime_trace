import 'package:animetrace/pages/local_search/views/local_search_page.dart';
import 'package:expand_widget/expand_widget.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_rating_bar.dart';
import 'package:animetrace/components/dialog/dialog_select_checklist.dart';
import 'package:animetrace/components/dialog/dialog_select_play_status.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/pages/anime_collection/checklist_controller.dart';
import 'package:animetrace/pages/bangumi/subject_detail/view.dart';
import 'package:animetrace/pages/anime_detail/controllers/anime_controller.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/anime_detail/pages/anime_properties_page.dart';
import 'package:animetrace/pages/anime_detail/pages/anime_rate_list_page.dart';
import 'package:animetrace/pages/anime_detail/widgets/labels.dart';
import 'package:animetrace/pages/settings/series/manage/view.dart';
import 'package:animetrace/routes/get_route.dart';
import 'package:animetrace/utils/common_util.dart';
import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/widgets/bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../widgets/icon_text_button.dart';

class AnimeDetailInfo extends StatefulWidget {
  const AnimeDetailInfo({required this.animeController, super.key});

  final AnimeController animeController;

  @override
  State<AnimeDetailInfo> createState() => _AnimeDetailInfoState();
}

class _AnimeDetailInfoState extends State<AnimeDetailInfo> {
  int rateNoteCount = 0; // 最初的评价数量

  Anime get _anime => widget.animeController.anime;
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
      tag: widget.animeController.tag,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _genIcons,
                    ),
                    const SizedBox(height: 10),
                    _buildDesc(),
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: AnimeDetailLabels(
                            animeController: widget.animeController)),
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
          setState(() {
            _anime.rate = v.toInt();
          });
          AnimeDao.updateAnimeRate(_anime.animeId, _anime.rate);
        });
  }

  // 显示评价按钮，点击后进入评价列表页
  _buildRateIcon() {
    return GetBuilder<AnimeController>(
      id: widget.animeController.rateNoteCountId,
      tag: widget.animeController.tag,
      init: widget.animeController,
      initState: (_) {},
      builder: (_) {
        return _buildIconTextButton(
          iconData: MingCuteIcons.mgc_chat_4_line,
          text: widget.animeController.rateNoteCount == 0
              ? "评价"
              : "${widget.animeController.rateNoteCount} 条评价",
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
      // if (widget.animeController.isCollected) _buildInfoIcon(),
      if (widget.animeController.isCollected)
        _buildIconTextButton(
            iconData: MingCuteIcons.mgc_book_3_line,
            // icon: SvgAssetIcon(
            //   assetPath: Assets.iconsCollections24Regular,
            //   size: iconSize,
            // ),
            text: '系列',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeriesManagePage(
                      animeId: widget.animeController.anime.animeId,
                    ),
                  )).then((value) {
                widget.animeController.reloadAnime(_anime);
              });
            }),
      widget.animeController.isCollected
          ? _buildBangumiInfoBtn()
          : _buildSearchBtn(),
    ];
  }

  _buildIconTextButton({
    IconData? iconData,
    Color? iconColor,
    Widget? icon,
    required String text,
    required void Function() onTap,
  }) {
    return Expanded(
      child: IconTextButton(
        text: Text(text, style: const TextStyle(fontSize: 12)),
        iconData: iconData,
        iconColor: iconColor,
        icon: icon,
        onTap: onTap,
        radius: 99,
        iconSize: 20,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: EdgeInsets.zero,
      ),
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
              enableClimbDetailInfo: true, callback: (newAnime) {
            widget.animeController.updateAnime(newAnime);
            widget.animeController.loadEpisode();
          });
        }
      },
    );
  }

  Widget _buildBangumiInfoBtn() {
    return _buildIconTextButton(
      iconData: MingCuteIcons.mgc_profile_line,
      text: '角色',
      onTap: () {
        RouteUtil.materialTo(context, BangumiSubjectDetailPage(_anime));
      },
    );
  }

  _buildSearchBtn() {
    return _buildIconTextButton(
      iconData: MingCuteIcons.mgc_search_line,
      text: '搜索',
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DbAnimeSearchPage(kw: _anime.animeName),
            )).then((value) {
          widget.animeController.reloadAnime(_anime);
        });
      },
    );
  }

  _buildInfo() {
    // const double smallIconSize = 14;

    // 迁移后信息会变化，所以使用obx监听
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 因为动漫未收藏时显示的收藏按钮撑高整个Row
        // 而收藏后，三个按钮会撑高一些，导致收藏后信息行位置变了，所以在上下添加10高度box
        const SizedBox(height: 10),
        // 第一行信息
        if (_anime.isCollected())
          GestureDetector(
            onTap: _toPropertiesPage,
            child: Row(
              children: [
                Text(_anime.getAnimeInfoFirstLine()),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 2),
                //   child: Icon(Icons.edit, size: smallIconSize),
                //   // Icon(Icons.chevron_right_outlined,
                //   //     size: 16, color: Theme.of(context).hintColor),
                // ),
                const Spacer(),
                Text(
                  '编辑',
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor),
                ),
                Icon(Icons.chevron_right_outlined,
                    size: 16, color: Theme.of(context).hintColor),
              ],
            ),
          ),
        // 第二行信息
        Row(
          children: [
            GestureDetector(
              child: Row(
                children: [
                  Text(_anime.getAnimeSource()),
                  _buildDot(),
                  // const Padding(
                  //   padding: EdgeInsets.symmetric(horizontal: 2),
                  //   child: Icon(Icons.open_in_new_rounded, size: smallIconSize),
                  // ),
                ],
              ),
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
            ),
            GestureDetector(
              // 这里使用animeController里的anime，而不是_anime，否则修改状态后没有变化
              child: Row(
                children: [
                  Text(widget.animeController.anime.getPlayStatus().text),
                  _buildDot(),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 2),
                  //   child: Icon(
                  //       widget.animeController.anime.getPlayStatus().iconData,
                  //       size: smallIconSize),
                  // ),
                ],
              ),
              onTap: () {
                if (widget.animeController.isCollected) {
                  showDialogSelectPlayStatus(context, widget.animeController);
                }
              },
            ),
            GestureDetector(
              child: Row(
                children: [
                  Text("${_anime.animeEpisodeCnt} 集"),
                  // const Padding(
                  //   padding: EdgeInsets.symmetric(horizontal: 2),
                  //   child: Icon(MingCuteIcons.mgc_edit_2_line,
                  //       size: smallIconSize),
                  // ),
                ],
              ),
              onTap: () {
                widget.animeController
                    .showDialogModEpisodeCntAndStartNumber(context);
              },
            )
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _toPropertiesPage() {
    if (widget.animeController.isCollected) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              AnimePropertiesPage(animeController: widget.animeController)));
    }
  }

  Padding _buildDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.circle, size: 4),
    );
  }

  void _dialogSelectTag() {
    showCommonModalBottomSheet(
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
