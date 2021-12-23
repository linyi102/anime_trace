import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/pages/anime_list_page.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  bool _searchOk = false;
  late List<Anime> _resAnimes;
  String lastInputText = ""; // 必须作为类成员，否则setstate会重新调用build，然后又赋值为""

  @override
  Widget build(BuildContext context) {
    // var inputController = TextEditingController();
    var inputController = TextEditingController.fromValue(TextEditingValue(
        // 设置内容
        text: lastInputText,
        // 保持光标在最后
        selection: TextSelection.fromPosition(TextPosition(
            affinity: TextAffinity.downstream, offset: lastInputText.length))));
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          autofocus: true, // 自动弹出键盘
          controller: inputController,
          decoration: InputDecoration(
              hintText: "根据名称搜索动漫",
              border: InputBorder.none,
              suffixIcon: IconButton(
                  onPressed: () {
                    inputController.clear();
                  },
                  icon: const Icon(Icons.close, color: Colors.black))),
          onEditingComplete: () async {
            String text = inputController.text;
            if (text.isEmpty) {
              return;
            }
            Future(() {
              debugPrint("search: $text");
              return SqliteUtil.getAnimesBySearch(text);
            }).then((value) {
              _resAnimes = value;
              _searchOk = true;
              debugPrint("_resAnimes.length=${_resAnimes.length}");
              for (var item in _resAnimes) {
                debugPrint(item.toString());
              }
              lastInputText = text;
              SystemChannels.textInput.invokeMethod(
                  'TextInput.hide'); // 回车后执行onEditingComplete，执行到这里会自动隐藏键盘
              setState(() {});
            });
          },
        ),
      ),
      body: !_searchOk ? Container() : _showSearchPage(),
    );
  }

  _showSearchPage() {
    List<Widget> listWidget = [];
    for (var anime in _resAnimes) {
      listWidget.add(AnimeItem(anime));
    }
    return Scrollbar(
      thickness: 5,
      radius: const Radius.circular(10),
      child: ListView(
        children: listWidget,
      ),
    );
  }
}
