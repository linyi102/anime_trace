class ClimbWebstie {
  String name;
  String baseUrl;
  bool enable;
  String spkey; // shared_preferencens存储的key，用于获取是否开启

  ClimbWebstie({
    required this.name,
    required this.baseUrl,
    required this.enable,
    required this.spkey,
  });

  @override
  String toString() {
    return "[name=$name, enable=$enable]";
  }
}
