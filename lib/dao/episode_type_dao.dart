enum EpisodeType {
  normal("正常"),
  // 1 2 3 --为1指定13后-->13 14 15
  start("起始集"),
  // 1 2 3 --为2指定1.5后-->1 1.5 2
  middle("中间集"),
  // 1 2 3 --为1指定PV后--> PV1 1 2
  // 1 2 3 --为1 2指定为PV1和PV2后--> PV1 PV2 1
  // 缺点：比如先出了两个pv，如果把前两个设置为pv后后出了两集，由于集数还是2，所以不会更新
  pv("PV"),
  // 1 2 3 --> 为2指定OVA后--> 1 OVA1 OVA2
  ova("OVA"),
  // 同上
  oad("OAD"),
  // 同上
  sp("SP");

  final String title;
  const EpisodeType(this.title);
}
