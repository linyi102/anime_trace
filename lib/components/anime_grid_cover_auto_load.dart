import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

/// 自动根据动漫详细地址来获取封面
class AnimeGridCoverAutoLoad extends StatefulWidget {
  const AnimeGridCoverAutoLoad(
      {required this.anime, required this.onChanged, super.key});
  final Anime anime;
  final void Function(Anime newAnime) onChanged;

  @override
  State<AnimeGridCoverAutoLoad> createState() => _AnimeGridCoverAutoLoadState();
}

class _AnimeGridCoverAutoLoadState extends State<AnimeGridCoverAutoLoad> {
  late Anime anime;
  late bool loading;

  @override
  void initState() {
    super.initState();
    anime = widget.anime;

    // 如果没有收藏，则从数据库中根据动漫链接查询是否已添加
    // 在查询过程中显示加载圈，不允许进入详情页
    // 如果数据库中没有，则根据动漫链接爬取动漫信息
    if (anime.isCollected()) {
      loading = false;
    } else {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimeGridCover(
      anime,
      onPressed: () {
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
      },
      loading: loading,
      showProgress: anime.isCollected() ? true : false,
      showReviewNumber: anime.isCollected() ? true : false,
    );
  }

  void _load() async {
    // 加载中
    setState(() {
      loading = true;
    });

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
}
