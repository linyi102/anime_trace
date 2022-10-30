main(List<String> args) {
  String url = "https%3A%2F%2Fbook.douban.com%2Fsubject%2F35972849%2F&query=%E4%BB%A3%E7%A0%81%E5%A4%A7%E5%85%A8&cat_id=1001&type=search&pos=0";
  print(Uri.decodeComponent(url));
  print(url);
}
