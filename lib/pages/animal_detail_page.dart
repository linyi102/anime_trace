import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/anime.dart';
import 'package:flutter_test_future/utils/episode.dart';

class AnimalDetail extends StatefulWidget {
  AnimalDetail({Key? key}) : super(key: key);

  @override
  _AnimalDetailState createState() => _AnimalDetailState();
}

class _AnimalDetailState extends State<AnimalDetail> {
  Anime anime = Anime("动漫");

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 12; ++i) {
      anime.addEpisode();
    }
    // debugPrint(episodes.toString());
  }

  List<Widget> _getEpisodesListTile() {
    var tmpList = anime.episodes.map((e) {
      // debugPrint("e: $e");
      return Card(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: AspectRatio(
          aspectRatio: 9 / 1,
          child: Stack(
            children: [
              Container(
                color: Colors.white,
              ),
              Positioned(
                left: 10,
                top: 5,
                child: Text("第${e.number}话"),
              ),
              Positioned(
                left: 10,
                bottom: 5,
                child: Text(anime.episodes[e.number].getDate()),
              ),
              Positioned(
                right: 10,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      anime.setEpisodeDateTimeNow(e.number);
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    shadowColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  child: const Icon(Icons.check),
                ),
              ),
            ],
          ),
        ),
      );
    });
    // debugPrint("tmpList: ${tmpList.toString()}");
    return tmpList.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            const SizedBox(
              width: 20,
            ),
            Text(
              anime.name,
              style: const TextStyle(fontSize: 20),
            )
          ],
        ),
        Expanded(
          child: ListView(
            children: _getEpisodesListTile(),
          ),
        )
      ],
    );
  }
}
