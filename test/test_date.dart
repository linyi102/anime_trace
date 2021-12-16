// ignore_for_file: avoid_print

main(List<String> args) {
  String date = DateTime.now().toString();
  print(date); // 2021-12-15 20:53:33.916433
  date = date.split('.')[0];
  print(date); // 2021-12-15 20:53:33
}
