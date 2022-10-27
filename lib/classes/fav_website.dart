// 喜爱的网页
class FavWebsite {
  int id;
  int orderIdx; // 顺序
  String url;
  String icoUrl;
  String name;

  FavWebsite({this.id = 0, this.orderIdx = 0, required this.url, required this.icoUrl, required this.name});
}