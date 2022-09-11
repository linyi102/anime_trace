import 'package:flutter/material.dart';

import '../classes/anime.dart';
import '../components/anime_list_cover.dart';

class RateListPage extends StatefulWidget {
  final Anime anime;

  const RateListPage(this.anime, {Key? key}) : super(key: key);

  @override
  State<RateListPage> createState() => _RateListPageState();
}

class _RateListPageState extends State<RateListPage> {
  late Anime anime;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    anime = widget.anime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "动漫评价",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              debugPrint("添加评价");
            },
            child: const Icon(Icons.edit)),
        body: Column(
          children: [
            ListTile(
              style: ListTileStyle.drawer,
              leading: AnimeListCover(anime),
              title: Text(
                widget.anime.animeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: ListView(
                children: _buildRateNoteList(),
              ),
            )
          ],
        ));
  }

  _buildRateNoteList() {
    List<Widget> list = [];

    return list;
  }
}
