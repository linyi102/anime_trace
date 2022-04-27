// List tags = ["拾", "途", "终", "搁", "弃"];
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/filter.dart';

List<String> tags = [];
List<int> animeCntPerTag = []; // 各个标签下的动漫数量
List<List<Anime>> animesInTag = []; // 各个标签下的动漫列表
List<Anime> directory = []; // 目录动漫
Filter filter = Filter(); // 目录页中的过滤条件
