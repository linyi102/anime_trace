import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/anime_list.dart';

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({Key? key}) : super(key: key);

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage> {
  AnimeList animeList = AnimeList.getInstance();

  @override
  void initState() {
    super.initState();
    animeList.addAnime("动漫1");
    animeList.addAnime("动漫2");
    animeList.addAnime("动漫3");
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        AspectRatio(
          aspectRatio: 6 / 1,
          child: Text(""),
        ),
      ],
    );
  }
}
