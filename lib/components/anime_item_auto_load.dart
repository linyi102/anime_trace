import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_checklist.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_view/photo_view.dart';

/// 自动根据动漫详细地址来获取封面和信息
class AnimeItemAutoLoad extends StatefulWidget {
  const AnimeItemAutoLoad(
      {required this.anime,
      required this.onChanged,
      required this.style,
      this.subtitles = const [],
      this.showAnimeInfo = false,
      super.key});
  final Anime anime;
  final void Function(Anime newAnime) onChanged;
  final List<String> subtitles;
  final AnimeItemStyle style;
  final bool showAnimeInfo; // 显示与动漫相关的两行信息

  @override
  State<AnimeItemAutoLoad> createState() => _AnimeItemAutoLoadState();
}

class _AnimeItemAutoLoadState extends State<AnimeItemAutoLoad> {
  late Anime anime;
  bool loading = true;

  var itemHeight = 120.0;
  var coverWidth = 80.0;

  @override
  void initState() {
    super.initState();
    anime = widget.anime;

    // 如果没有收藏，则从数据库中根据动漫链接查询是否已添加
    // 在查询过程中显示加载圈，不允许进入详情页
    // 如果数据库中没有，则根据动漫链接爬取动漫信息
    if (anime.isCollected()) {
      setState(() {
        loading = false;
      });
    } else {
      _load();
    }
  }

  void _load() async {
    // dbAnime指向一个对象，而anime和widget.anime指向一个对象。所以会导致出现很多奇怪现象
    // 解决方法就是当anime变化时，widget.anime也跟着anime指向最新对象
    Anime dbAnime = await SqliteUtil.getAnimeByAnimeUrl(anime);
    if (dbAnime.isCollected()) {
      // 数据库中找到了
      anime = dbAnime;
    } else {
      // 数据库中没有找到，则爬取信息
      // 如果之前爬取过信息，就不再爬取了
      if (!anime.climbFinished) {
        anime =
            await ClimbAnimeUtil.climbAnimeInfoByUrl(anime, showMessage: false);
        anime.climbFinished = true;
      }
    }

    // 返回给最新anime
    widget.onChanged(anime);

    // 加载完毕
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == AnimeItemStyle.grid) {
      return _buildGridItem();
    } else {
      return _buildListItem();
    }
  }

  _buildListItem() {
    return Card(
      child: SizedBox(
        height: itemHeight,
        child: MaterialButton(
          onPressed: _enterDetailPage,
          child: Row(
            children: [
              // 封面
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 10, 0),
                child: SizedBox(
                  width: coverWidth,
                  child: AnimeGridCover(
                    anime,
                    loading: loading,
                    showName: false,
                    showProgress: anime.isCollected() ? true : false,
                    showReviewNumber: anime.isCollected() ? true : false,
                    onPressed: _openImage,
                  ),
                ),
              ),
              // 信息
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _showAnimeName(anime.animeName),
                    for (var subtitle in widget.subtitles)
                      _showAnimeSubtitle(subtitle),
                    if (widget.showAnimeInfo)
                      _showAnimeSubtitle(anime.getAnimeInfoFirstLine()),
                    if (widget.showAnimeInfo)
                      _showAnimeSubtitle(anime.getAnimeInfoSecondLine()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AnimeGridCover _buildGridItem() {
    return AnimeGridCover(
      anime,
      onPressed: _enterDetailPage,
      loading: loading,
      showProgress: anime.isCollected() ? true : false,
      showReviewNumber: anime.isCollected() ? true : false,
    );
  }

  _showAnimeName(String name) {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.fromLTRB(0, 5, 15, 5),
      child: Text(
        name,
        style: TextStyle(
            fontWeight: FontWeight.w600, color: ThemeUtil.getFontColor()),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  _showAnimeSubtitle(String info) {
    return info.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.fromLTRB(0, 5, 15, 0),
            child: Text(
              info,
              style: TextStyle(color: ThemeUtil.getCommentColor(), height: 1.1),
              overflow: TextOverflow.ellipsis,
              textScaleFactor: ThemeUtil.smallScaleFactor,
            ),
          );
  }

  // 不展示收藏按钮，因为可能已经收藏了，但没有显示，只有进入详情页后才会看到
  _showCollectIcon(Anime anime) {
    return SizedBox(
      height: itemHeight,
      child: MaterialButton(
        padding: EdgeInsets.zero,
        visualDensity:
            const VisualDensity(horizontal: VisualDensity.minimumDensity),
        onPressed: () {
          dialogSelectChecklist(setState, context, anime);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            anime.isCollected()
                ? const Icon(Icons.favorite, color: Colors.red, size: 18)
                : const Icon(Icons.favorite_border, size: 18),
            anime.isCollected()
                ? Text(anime.tagName,
                    textScaleFactor: ThemeUtil.tinyScaleFactor)
                : Container()
          ],
        ),
      ),
    );
  }

  _openImage() {
    if (loading) return;

    // 查看图片
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PhotoView(
                imageProvider: Image.network(anime.animeCoverUrl).image,
                onTapDown: (_, __, ___) => Navigator.of(context).pop())));
  }

  void _enterDetailPage() {
    // 加载时不允许进入详情页
    if (loading) {
      showToast("加载中，请稍后进入");
      return;
    }

    // 一定要在内部进入详情页，因为widget.anime和这里的anime不一样，这里的anime是最新的
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimeDetailPage(anime),
      ),
    ).then((value) {
      // 退出动漫详情页后，更新为最新动漫信息
      setState(() {
        anime = value;
      });
      widget.onChanged(anime);
    });
  }
}

enum AnimeItemStyle {
  list,
  grid;
}