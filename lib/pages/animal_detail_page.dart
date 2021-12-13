import 'package:flutter/cupertino.dart';
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
    anime.setEndEpisode(6);
    // debugPrint(episodes.toString());
  }

  List<Widget> _getEpisodesListTile() {
    var tmpList = anime.episodes.map((e) {
      return Card(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        shadowColor: Colors.transparent,
        child: AspectRatio(
          aspectRatio: 9 / 1,
          child: Stack(
            children: [
              Container(
                color: Colors.white,
              ),
              Positioned(
                left: 10,
                top: 1,
                child: Text(
                  "第${e.number}话",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 1,
                child: Text(
                  anime.getEpisodeDate(e.number),
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
              Positioned(
                right: 10,
                child: ElevatedButton(
                  onPressed: () {
                    if (anime.getEpisodeDate(e.number) == "") {
                      setState(() {
                        anime.setEpisodeDateTimeNow(e.number);
                      });
                    } else {
                      showCancelDate(e.number);
                    }
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
        const SizedBox(
          height: 30,
        ),
        Row(
          children: [
            Expanded(
              child: AnimalPageButton(Icons.label_important_outline_rounded,
                  onPressed: () {}),
            ),
            Expanded(
              child: AnimalPageButton(Icons.star_border, onPressed: () {}),
            ),
            Expanded(
              child: AnimalPageButton(Icons.add_box_outlined, onPressed: () {
                showInputEpisode();
              }),
            ),
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

  void showInputEpisode() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('最终话'),
            content: AspectRatio(
              aspectRatio: 3 / 1,
              child: Card(
                elevation: 0.0,
                child: Column(
                  children: const [
                    TextField(
                      decoration: InputDecoration(
                          filled: true, fillColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
            ],
          );
        });
  }

  void showCancelDate(int episodeNumber) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text('是否撤销日期?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  setState(() {
                    anime.cancelEpisodeDateTime(episodeNumber);
                  });
                  Navigator.pop(context);
                },
                child: const Text('是'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('否'),
              ),
            ],
          );
        });
  }
}

class AnimalPageButton extends StatefulWidget {
  VoidCallback onPressed;
  IconData iconData;
  AnimalPageButton(this.iconData, {required this.onPressed, Key? key})
      : super(key: key);

  @override
  AnimalPageButtonState createState() => AnimalPageButtonState();
}

class AnimalPageButtonState extends State<AnimalPageButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onPressed,
      child: Icon(widget.iconData),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.white),
        foregroundColor: MaterialStateProperty.all(Colors.black),
        shadowColor: MaterialStateProperty.all(Colors.transparent),
      ),
    );
  }
}
