import 'package:animetrace/models/anime.dart';

class UserCollection {
  int totalCnt; // 收藏总数
  List<Anime> animes; // 收藏列表

  UserCollection({
    required this.totalCnt,
    required this.animes,
  });

  @override
  String toString() => 'UserCollection(totalCnt: $totalCnt, animes: $animes)';
}
