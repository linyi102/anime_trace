class PingStatus {
  bool pinging; // 正在ping
  bool notPing; // 为true表示一次都还没ping过，例如刚进入程序，此时显示未知
  bool connectable; // 可以连接
  int time;

  PingStatus(
      {this.connectable = false,
      this.time = -1,
      this.pinging = false,
      this.notPing = true});

  @override
  String toString() {
    return "PingStatus[ok=$connectable, time=$time]";
  }
}
