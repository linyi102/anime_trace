class ClimbWebStie {
  String name;
  String baseUrl;
  bool enable;
  String spkey; // shared_preferencens存储的key，用于获取是否开启

  ClimbWebStie({
    required this.name,
    required this.baseUrl,
    required this.enable,
    required this.spkey,
  });
}
