import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/anime.dart';

class AnimalDetail extends StatefulWidget {
  const AnimalDetail({Key? key}) : super(key: key);

  @override
  _AnimalDetailState createState() => _AnimalDetailState();
}

class _AnimalDetailState extends State<AnimalDetail> {
  Anime anime = Anime("JOJO的奇妙冒险第六部 石之海");

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
                top: 3,
                child: Text(
                  "第${e.number}话",
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        anime.isChecked(e.number) ? Colors.grey : Colors.black,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 3,
                child: Text(
                  // 没有完成日期时，返回空字符串""
                  anime.getEpisodeDate(e.number),
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        anime.isChecked(e.number) ? Colors.grey : Colors.black,
                  ),
                ),
              ),
              Positioned(
                right: 10,
                child: ElevatedButton(
                  onPressed: () {
                    if (!anime.isChecked(e.number)) {
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
                    minimumSize: MaterialStateProperty.all(
                      const Size(0, 0),
                    ),
                    maximumSize: MaterialStateProperty.all(
                      const Size(20, 20),
                    ),
                  ),
                  child: anime.isChecked(e.number)
                      ? const Icon(
                          Icons.check_box_outlined,
                          color: Colors.grey,
                        )
                      : const Icon(Icons.check_box_outline_blank_rounded),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
              ),
              Expanded(
                flex: 10,
                child: Text(
                  anime.name,
                  style: const TextStyle(
                    fontSize: 20,
                    // Row溢出部分省略号...表示，需要外套Expanded
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
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
                child:
                    AnimalPageButton(Icons.add_circle_outline, onPressed: () {
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
      ),
    );
  }

  void showInputEpisode() {
    const int maxAllowedEpisode = 200;
    var endEpisodeController = TextEditingController();
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
                children: [
                  TextField(
                    // 只允许输入整数
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    // 把TextEditingController对象应用到TextField上，便于获取输入内容
                    controller: endEpisodeController,
                    decoration: const InputDecoration(
                      hintText: "0-$maxAllowedEpisode",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              // 修改动漫集数
              onPressed: () {
                // controller.text获取输入的文本
                // 处理「没有输入就按确定」的情况
                if (endEpisodeController.text == "") return;
                int endEpisode = int.parse(endEpisodeController.text);
                if (endEpisode > maxAllowedEpisode) {
                  return;
                }
                setState(() {
                  anime.setEndEpisode(endEpisode);
                });
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
      },
    );
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
      },
    );
  }
}

class AnimalPageButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData iconData;
  const AnimalPageButton(this.iconData, {required this.onPressed, Key? key})
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
