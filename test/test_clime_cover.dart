import 'package:dio/dio.dart';
import 'package:html/parser.dart';

main(List<String> args) async {
  String keyword = "此花亭奇谭"; // 少了个空格，没搜索到...
  // String url = "https://search.bilibili.com/all?keyword=$keyword";
  String url = "https://www.yhdmp.cc/s_all?ex=1&kw=$keyword";
  try {
    var response = await Dio().get(url);
    var document = parse(response.data);
    yhdm(document);
    // var elements = document.querySelectorAll("img");
    // print(document.outerHtml);

  } catch (e) {
    print(e);
  }
}

void yhdm(document) {
  var elements = document.getElementsByClassName("lpic");
  print(elements[0]
      .children[0]
      .children[0]
      .children[0]
      .children[0]
      .attributes["src"]);
}
