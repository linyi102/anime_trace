import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/anime.dart';
import 'package:flutter_test_future/utils/anime_list_util.dart';
import 'package:flutter_test_future/utils/history_util.dart';
import 'package:flutter_test_future/utils/tags.dart';

void main() {
  AnimeListUtil animeListUtil = AnimeListUtil.getInstance();

  animeListUtil.addAnime(Anime("进击的巨人第一季", tag: tags[0]));
  animeListUtil.addAnime(Anime("JOJO的奇妙冒险第六季 石之海", tag: tags[0]));
  animeListUtil.addAnime(Anime("刀剑神域第一季", tag: tags[1]));
  animeListUtil.addAnime(Anime("进击的巨人第二季", tag: tags[1]));
  animeListUtil.addAnime(Anime("在下坂本，有何贵干？", tag: tags[1]));
  Anime anime = Anime("在下坂本，有何贵干？？？", tag: tags[1]);
  HistoryUtil historyUtil = HistoryUtil.getInstance();
  historyUtil.addRecord("2021/4/7", anime, 1);

  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHome(),
    );
  }
}

class MyHome extends StatelessWidget {
  const MyHome({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Tabs();
  }
}
