import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';

/// 自动根据动漫详细地址来获取封面
class AnimeGridCoverAutoLoad extends StatefulWidget {
  const AnimeGridCoverAutoLoad(
      {required this.anime, this.onPressed, super.key});
  final Anime anime;
  final void Function()? onPressed;

  @override
  State<AnimeGridCoverAutoLoad> createState() => _AnimeGridCoverAutoLoadState();
}

class _AnimeGridCoverAutoLoadState extends State<AnimeGridCoverAutoLoad> {
  late Anime anime;
  late bool loadingCover;

  @override
  void initState() {
    super.initState();
    anime = widget.anime;
    if (anime.animeCoverUrl.isEmpty) {
      loadingCover = true;
      _loadCover();
    } else {
      setState(() {
        loadingCover = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimeGridCover(
      anime,
      onPressed: widget.onPressed,
      loadingCover: loadingCover,
    );
  }

  void _loadCover() async {
    anime = await ClimbAnimeUtil.climbAnimeInfoByUrl(widget.anime,
        showMessage: false);
    setState(() {
      loadingCover = false;
    });
  }
}
