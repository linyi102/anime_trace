import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:expand_widget/expand_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_rating_bar.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_checklist.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_play_status.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/anime_detail/pages/anime_properties_page.dart';
import 'package:flutter_test_future/pages/anime_detail/pages/anime_rate_list_page.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/labels.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

class AnimeDetailInfo extends StatefulWidget {
  const AnimeDetailInfo({required this.animeController, super.key});

  final AnimeController animeController;

  @override
  State<AnimeDetailInfo> createState() => _AnimeDetailInfoState();
}

class _AnimeDetailInfoState extends State<AnimeDetailInfo> {
  Anime get _anime => widget.animeController.anime.value;
  int rateNoteCount = 0; // 最初的评价数量

  @override
  void initState() {
    super.initState();
    widget.animeController.acqRateNoteCount();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // 动漫名字
          Obx(
            () => SelectableText(widget.animeController.anime.value.animeName,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          ),
          // 评价
          _buildRatingStars(),
          // 动漫信息(左侧)和相关按钮(右侧)
          Obx(() => _buildInfoAndIconRow()),
          // 简介
          Obx(() => _buildDesc()),
          // 标签列表
          AnimeDetailLabels(animeController: widget.animeController)
        ]),
      ),
    );
  }

  _buildDesc() {
    if (widget.animeController.anime.value.animeDesc.isNotEmpty &&
        widget.animeController.showDescInAnimeDetailPage.value) {
      return widget.animeController.isCollected
          ? ExpandText(widget.animeController.anime.value.animeDesc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 12, color: ThemeUtil.getCommentColor()),
              arrowSize: 20)
          // 如果没有收藏，这不折叠简介
          : Text(
              widget.animeController.anime.value.animeDesc,
              style:
                  TextStyle(fontSize: 12, color: ThemeUtil.getCommentColor()),
            );
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
          SqliteUtil.updateAnimeRate(_anime.animeId, _anime.rate);
        });
  }

  // 显示信息按钮，点击后进入动漫属性信息页
  _showInfoIcon() {
    return IconTextButton(
      iconData: EvaIcons.infoOutline,
      title: "信息",
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                AnimePropertiesPage(animeController: widget.animeController)));
      },
    );
  }

  // 显示评价按钮，点击后进入评价列表页
  _showRateIcon() {
    return Obx(() => IconTextButton(
          iconData: EvaIcons.messageCircleOutline,
          title: "${widget.animeController.rateNoteCount}条评价",
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) => AnimeRateListPage(_anime)))
                .then((value) async {
              // 更新评价数量
              widget.animeController.acqRateNoteCount();
            });
          },
        ));
  }

  // 显示收藏按钮，点击后可以修改清单
  _showCollectIcon() {
    return Obx(() => IconTextButton(
          iconData:
              _anime.isCollected() ? EvaIcons.heart : EvaIcons.heartOutline,
          iconColor: _anime.isCollected() ? Colors.red : null,
          title: _anime.isCollected() ? _anime.tagName : "",
          onTap: () => _dialogSelectTag(),
        ));
  }

  _buildInfoAndIconRow() {
    if (widget.animeController.isCollected) {
      return Row(
        children: [
          // 动漫信息
          _buildInfo(),
          const Spacer(),
          // 相关按钮
          _showInfoIcon(), _showRateIcon(), _showCollectIcon()
        ],
      );
    } else {
      return Row(children: [
        _buildInfo(),
        const Spacer(),
        SizedBox(
          height: 40,
          width: 100,
          child: MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              onPressed: () {
                dialogSelectChecklist(setState, context, _anime,
                    onlyShowChecklist: true,
                    enableClimbDetailInfo: false, callback: (newAnime) {
                  widget.animeController.setAnime(newAnime);
                  widget.animeController.loadEpisode();
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite_border, size: 18),
                  SizedBox(width: 5),
                  Text("收藏"),
                ],
              )),
        )
      ]);
    }
  }

  _buildInfo() {
    const double smallIconSize = 14;
    const double textScaleFactor = 1;

    // 迁移后信息会变化，所以使用obx监听
    return Obx(() => Column(
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
                  onTap: () {
                    if (_anime.animeUrl.isNotEmpty) {
                      LaunchUrlUtil.launch(
                          context: context, uriStr: _anime.animeUrl);
                    } else {
                      showToast("空网址无法打开");
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
                  child: Obx(() => Row(
                        children: [
                          Text(widget.animeController.anime.value
                              .getPlayStatus()
                              .text),
                          Icon(
                              widget.animeController.anime.value
                                  .getPlayStatus()
                                  .iconData,
                              size: smallIconSize),
                        ],
                      )),
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
                      const Icon(EvaIcons.editOutline, size: smallIconSize),
                    ],
                  ),
                )),
              ]),
              textScaleFactor: textScaleFactor,
            ),
            const SizedBox(height: 10),
          ],
        ));
  }

  void showDialogmodifyEpisodeCnt() {
    dialogSelectUint(context, "修改集数",
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
      SqliteUtil.updateEpisodeCntByAnimeId(_anime.animeId, episodeCnt)
          .then((value) {
        // 重新获取集信息，改用obx监听
        // _anime.animeEpisodeCnt = episodeCnt;
        widget.animeController.updateAnimeEpisodeCnt(episodeCnt);
        widget.animeController.loadEpisode();
      });
    });
  }

  void _dialogSelectTag() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < tags.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(tags[i]),
              leading: tags[i] == _anime.tagName
                  ? Icon(
                      Icons.radio_button_on_outlined,
                      color: ThemeUtil.getPrimaryColor(),
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                _anime.tagName = tags[i];
                SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
                Log.info("修改清单为${_anime.tagName}");
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('选择清单'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }
}

class IconTextButton extends StatelessWidget {
  const IconTextButton(
      {required this.iconData,
      this.iconColor,
      this.iconSize = 18,
      required this.title,
      this.titleSize = 12,
      this.onTap,
      Key? key})
      : super(key: key);

  final void Function()? onTap;
  final IconData iconData;
  final double iconSize;
  final Color? iconColor;
  final String title;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          // 必须添加颜色(透明色也可)，这样手势就能监测到Container，否则只能检测到Icon和Text
          color: Colors.transparent,
          child: Column(
            children: [
              Icon(iconData, color: iconColor, size: iconSize),
              Text(title, style: TextStyle(fontSize: titleSize))
            ],
          ),
        ));
  }
}
