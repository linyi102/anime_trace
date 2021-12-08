import 'package:flutter/material.dart';

class AnimalDetail extends StatefulWidget {
  AnimalDetail({Key? key}) : super(key: key);

  @override
  _AnimalDetailState createState() => _AnimalDetailState();
}

class _AnimalDetailState extends State<AnimalDetail> {
  String animalName = "东京喰种";
  List<String> episodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 12; ++i) {
      if (i < 10) {
        episodes.add("EP0$i");
      } else {
        episodes.add("EP$i");
      }
    }

    // debugPrint(episodes.toString());
  }

  List<Widget> _getEpisodesListTile() {
    var tmpList = episodes.map((e) {
      // debugPrint("e: $e");
      return Column(
        children: [
          Card(
            child: Text(e),
          )
        ],
      );
    });
    debugPrint("tmpList: ${tmpList.toString()}");
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
              animalName,
              style: const TextStyle(fontSize: 20),
            )
          ],
        ),
        Column(
          children: _getEpisodesListTile(),
        )
      ],
    );
  }
}
